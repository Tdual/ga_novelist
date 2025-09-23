using Oxygen
using HTTP
using JSON3
using Dates
using LibPQ
using UUIDs

include("db_config.jl")
include("database_postgres.jl")
include("ga_corpus_postgres.jl")

# CORSヘッダーを追加する関数
function add_cors_headers(response::HTTP.Response)
    HTTP.setheader(response, "Access-Control-Allow-Origin" => "*")
    HTTP.setheader(response, "Access-Control-Allow-Methods" => "GET, POST, OPTIONS")
    HTTP.setheader(response, "Access-Control-Allow-Headers" => "Content-Type")
    return response
end

# 全てのリクエストにCORSヘッダーを追加するミドルウェア
function cors_middleware(handler)
    return function(req::HTTP.Request)
        # OPTIONSリクエストの処理
        if req.method == "OPTIONS"
            response = HTTP.Response(204)
            return add_cors_headers(response)
        end
        
        # 通常のリクエスト処理
        response = handler(req)
        return add_cors_headers(response)
    end
end

# サーバー起動時にルームを初期化
function initialize_rooms()
    println("🚀 Initializing rooms from RDS...")
    room_names = ["Room A", "Room B", "Room C", "Room D"]
    
    for name in room_names
        room = ensure_room_exists(name)
        if room !== nothing
            println("✅ Initialized: $name (Generation: $(room.generation))")
        end
    end
end

# 初期化実行
try
    initialize_rooms()
    println("🎉 All rooms initialized successfully!")
catch e
    println("❌ Error initializing rooms: $e")
end

# ルーム一覧を取得
@get "/api/rooms" function(req::HTTP.Request)
    conn = get_db_connection()
    
    result = LibPQ.execute(conn,
        """SELECT r.id, r.name, r.current_generation, r.updated_at, t.content
           FROM rooms r
           LEFT JOIN texts t ON r.id = t.room_id AND r.current_generation = t.generation
           ORDER BY r.name"""
    )
    
    rooms_data = []
    for row in result
        text = if !ismissing(row[5]) && row[5] !== nothing
            row[5]
        else
            "GA Novelist"
        end
        
        push!(rooms_data, Dict(
            "id" => row[2],  # nameをidとして使用
            "name" => row[2],
            "generation" => row[3],
            "text_preview" => length(text) > 200 ? first(text, 200) * "..." : text,
            "updated_at" => string(row[4])
        ))
    end
    
    response = HTTP.Response(200, JSON3.write(Dict("rooms" => rooms_data)))
    return add_cors_headers(response)
end

# 特定のルーム情報を取得
@get "/api/rooms/{room_id}" function(req::HTTP.Request, room_id::String)
    room = load_room(room_id)
    
    if room === nothing
        response = HTTP.Response(404, JSON3.write(Dict("error" => "Room not found")))
        return add_cors_headers(response)
    end
    
    # 最近の変更履歴を取得
    conn = get_db_connection()
    result = LibPQ.execute(conn, "SELECT id FROM rooms WHERE name = \$1", [room_id])
    
    nudge_history = []
    if !isempty(result)
        room_uuid = result[1,1]
        history_result = LibPQ.execute(conn,
            """SELECT operator, actor, generation_after, created_at
               FROM mutations
               WHERE room_id = \$1
               ORDER BY created_at DESC
               LIMIT 10""",
            [room_uuid]
        )
        
        for row in history_result
            push!(nudge_history, Dict(
                "operator" => row[1],
                "actor" => row[2],
                "generation" => row[3],
                "timestamp" => string(row[4])
            ))
        end
    end
    
    room_data = Dict(
        "id" => room.id,
        "name" => room.id,
        "generation" => room.generation,
        "text" => room.current_text,
        "genome" => Dict(
            "genre_weights" => room.current_genome.genre_weights,
            "style_params" => room.current_genome.style_params,
            "character_traits" => room.current_genome.character_traits,
            "setting_elements" => room.current_genome.setting_elements
        ),
        "updated_at" => string(room.updated_at),
        "recent_history" => reverse(nudge_history)
    )
    
    response = HTTP.Response(200, JSON3.write(room_data))
    return add_cors_headers(response)
end

# ルームにnudge操作を適用
@post "/api/rooms/{room_id}/nudge" function(req::HTTP.Request, room_id::String)
    try
        body = JSON3.read(String(req.body))
        operator = get(body, "operator", "unknown")
        actor = get(body, "actor", "anonymous")
        
        # ルームを読み込み
        room = load_room(room_id)
        if room === nothing
            response = HTTP.Response(404, JSON3.write(Dict("error" => "Room not found")))
            return add_cors_headers(response)
        end
        
        # 変異操作を適用
        if haskey(MUTATION_MAP, operator)
            generation_before = room.generation
            
            # ゲノムを変異
            mutate_func = MUTATION_MAP[operator]
            mutate_func(room.current_genome)
            
            # テキストを再生成
            try
                room.current_text = generate_text(room.current_genome)
                room.generation += 1
                room.updated_at = now()
                
                # DBに保存
                save_room(room)
                
                # 変更履歴を記録
                save_mutation(room_id, operator, actor, generation_before, room.generation, room.current_text)
            catch e
                println("❌ Error generating text: $e")
                response = HTTP.Response(500, JSON3.write(Dict("error" => "Text generation failed: $(string(e))")))
                return add_cors_headers(response)
            end
            
            response_data = Dict(
                "success" => true,
                "generation" => room.generation,
                "text" => room.current_text,
                "genome" => Dict(
                    "genre_weights" => room.current_genome.genre_weights,
                    "style_params" => room.current_genome.style_params
                )
            )
            
            response = HTTP.Response(200, JSON3.write(response_data))
        else
            response = HTTP.Response(400, JSON3.write(Dict("error" => "Invalid operator: $operator")))
        end
        
        return add_cors_headers(response)
    catch e
        response = HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
        return add_cors_headers(response)
    end
end

# ルームの統計情報を取得
@get "/api/rooms/{room_id}/stats" function(req::HTTP.Request, room_id::String)
    conn = get_db_connection()
    
    # room_nameからroom_idを取得
    result = LibPQ.execute(conn, "SELECT id FROM rooms WHERE name = \$1", [room_id])
    if isempty(result)
        response = HTTP.Response(404, JSON3.write(Dict("error" => "Room not found")))
        return add_cors_headers(response)
    end
    
    room_uuid = result[1,1]
    
    # 統計情報を集計
    # 最も使用されたオペレーター
    operator_result = LibPQ.execute(conn,
        """SELECT operator, COUNT(*) as count
           FROM mutations
           WHERE room_id = \$1
           GROUP BY operator
           ORDER BY count DESC""",
        [room_uuid]
    )
    
    operator_counts = Dict{String, Int}()
    for row in operator_result
        operator_counts[row[1]] = row[2]
    end
    
    # 全変更数
    total_result = LibPQ.execute(conn,
        "SELECT COUNT(*) FROM mutations WHERE room_id = \$1",
        [room_uuid]
    )
    total_nudges = isempty(total_result) ? 0 : total_result[1,1]
    
    # 最終更新からの経過時間
    last_update_result = LibPQ.execute(conn,
        """SELECT updated_at FROM rooms WHERE id = \$1""",
        [room_uuid]
    )
    
    minutes_since_last = if !isempty(last_update_result)
        updated_at = DateTime(last_update_result[1,1])
        round(Int, (now() - updated_at).value / (1000 * 60))
    else
        -1
    end
    
    stats_data = Dict(
        "room_id" => room_id,
        "total_nudges" => total_nudges,
        "most_used_operators" => operator_counts,
        "minutes_since_last_activity" => minutes_since_last
    )
    
    response = HTTP.Response(200, JSON3.write(stats_data))
    return add_cors_headers(response)
end

# OPTIONSリクエストの処理
@route ["OPTIONS"] "/api/rooms" req -> add_cors_headers(HTTP.Response(204))
@route ["OPTIONS"] "/api/rooms/{room_id}" (req, room_id) -> add_cors_headers(HTTP.Response(204))
@route ["OPTIONS"] "/api/rooms/{room_id}/nudge" (req, room_id) -> add_cors_headers(HTTP.Response(204))
@route ["OPTIONS"] "/api/rooms/{room_id}/stats" (req, room_id) -> add_cors_headers(HTTP.Response(204))

# ヘルスチェック
@get "/health" function(req::HTTP.Request)
    # DB接続チェック
    db_status = try
        conn = get_db_connection()
        result = LibPQ.execute(conn, "SELECT 1")
        "connected"
    catch
        "disconnected"
    end
    
    response = HTTP.Response(200, JSON3.write(Dict(
        "status" => "healthy",
        "database" => db_status,
        "timestamp" => string(now())
    )))
    return add_cors_headers(response)
end

# 静的ファイルの配信
@get "/" function(req::HTTP.Request)
    html_path = joinpath(@__DIR__, "..", "frontend", "index.html")
    if isfile(html_path)
        content = read(html_path, String)
        response = HTTP.Response(200, content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        response = HTTP.Response(404, "Not Found")
        return add_cors_headers(response)
    end
end

@get "/room" function(req::HTTP.Request)
    html_path = joinpath(@__DIR__, "..", "frontend", "room.html")
    if isfile(html_path)
        content = read(html_path, String)
        response = HTTP.Response(200, content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        response = HTTP.Response(404, "Not Found")
        return add_cors_headers(response)
    end
end

@get "/debug" function(req::HTTP.Request)
    html_path = joinpath(@__DIR__, "..", "frontend", "debug.html")
    if isfile(html_path)
        content = read(html_path, String)
        response = HTTP.Response(200, content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        response = HTTP.Response(404, "Debug page not found")
        return add_cors_headers(response)
    end
end

@get "/test" function(req::HTTP.Request)
    html_path = joinpath(@__DIR__, "..", "frontend", "test.html")
    if isfile(html_path)
        content = read(html_path, String)
        response = HTTP.Response(200, content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        response = HTTP.Response(404, "Test page not found")
        return add_cors_headers(response)
    end
end

# サーバー起動
println("🚀 Starting GA Novelist Server with RDS PostgreSQL...")
println("🔗 Database: $(DB_CONFIG["host"])")
println("🌐 Listening on http://localhost:8082")
println("📁 Frontend: http://localhost:8082/")

serve(host="0.0.0.0", port=8082)