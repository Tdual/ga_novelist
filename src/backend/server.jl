using Oxygen
using HTTP
using JSON3
using Dates

include("room_manager.jl")

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
initialize_rooms()

# ルーム一覧を取得
@get "/api/rooms" function(req::HTTP.Request)
    rooms_data = []
    for room in get_all_rooms()
        push!(rooms_data, Dict(
            "id" => room.id,
            "name" => room.name,
            "generation" => room.generation,
            "text_preview" => length(room.current_text) > 200 ? 
                            first(room.current_text, 200) * "..." : room.current_text,
            "updated_at" => string(room.updated_at)
        ))
    end
    
    response = HTTP.Response(200, JSON3.write(Dict("rooms" => rooms_data)))
    return add_cors_headers(response)
end

# 特定のルーム情報を取得
@get "/api/rooms/{room_id}" function(req::HTTP.Request, room_id::String)
    room = get_room(room_id)
    if room === nothing
        response = HTTP.Response(404, JSON3.write(Dict("error" => "Room not found")))
        return add_cors_headers(response)
    end
    
    room_data = Dict(
        "id" => room.id,
        "name" => room.name,
        "generation" => room.generation,
        "text" => room.current_text,
        "genome" => Dict(
            "genre_weights" => room.current_genome.genre_weights,
            "style_params" => room.current_genome.style_params,
            "character_traits" => room.current_genome.character_traits,
            "setting_elements" => room.current_genome.setting_elements
        ),
        "updated_at" => string(room.updated_at),
        "recent_history" => length(room.nudge_history) > 10 ? 
                           room.nudge_history[end-9:end] : room.nudge_history
    )
    
    response = HTTP.Response(200, JSON3.write(room_data))
    return add_cors_headers(response)
end

# ルームにnudge操作を適用
@post "/api/rooms/{room_id}/nudge" function(req::HTTP.Request, room_id::String)
    body = JSON3.read(String(req.body))
    operator = get(body, :operator, "")
    actor = get(body, :actor, "anonymous")
    
    if operator == ""
        response = HTTP.Response(400, JSON3.write(Dict("error" => "operator is required")))
        return add_cors_headers(response)
    end
    
    room = nudge_room(room_id, String(operator), String(actor))
    if room === nothing
        response = HTTP.Response(404, JSON3.write(Dict("error" => "Room not found")))
        return add_cors_headers(response)
    end
    
    response_data = Dict(
        "room_id" => room.id,
        "generation" => room.generation,
        "text" => room.current_text,
        "operator" => operator,
        "actor" => actor,
        "genome" => Dict(
            "genre_weights" => room.current_genome.genre_weights,
            "style_params" => room.current_genome.style_params
        )
    )
    
    response = HTTP.Response(200, JSON3.write(response_data))
    return add_cors_headers(response)
end

# ルームのスナップショットを作成
@post "/api/rooms/{room_id}/snapshot" function(req::HTTP.Request, room_id::String)
    snapshot = create_snapshot(room_id)
    if snapshot === nothing
        response = HTTP.Response(404, JSON3.write(Dict("error" => "Room not found")))
        return add_cors_headers(response)
    end
    
    response = HTTP.Response(200, JSON3.write(snapshot))
    return add_cors_headers(response)
end

# ルームの統計情報を取得
@get "/api/rooms/{room_id}/stats" function(req::HTTP.Request, room_id::String)
    stats = get_room_stats(room_id)
    if stats === nothing
        response = HTTP.Response(404, JSON3.write(Dict("error" => "Room not found")))
        return add_cors_headers(response)
    end
    
    response = HTTP.Response(200, JSON3.write(stats))
    return add_cors_headers(response)
end

# 全ルームの比較データを取得
@get "/api/rooms/compare" function(req::HTTP.Request)
    comparisons = compare_rooms()
    response = HTTP.Response(200, JSON3.write(Dict("comparisons" => comparisons)))
    return add_cors_headers(response)
end

# メインページのHTML
@get "/" function(req::HTTP.Request)
    html_path = joinpath(dirname(@__FILE__), "..", "frontend", "index.html")
    if isfile(html_path)
        html_content = read(html_path, String)
        response = HTTP.Response(200, html_content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        # HTMLファイルがない場合は簡易版を返す
        html_content = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>GA Novelist - 4 Rooms</title>
            <meta charset="utf-8">
        </head>
        <body>
            <h1>GA Novelist - 4 Rooms</h1>
            <p>Frontend not found. API is running.</p>
            <p>Available endpoints:</p>
            <ul>
                <li>GET /api/rooms - Get all rooms</li>
                <li>GET /api/rooms/{id} - Get room details</li>
                <li>POST /api/rooms/{id}/nudge - Apply mutation</li>
                <li>POST /api/rooms/{id}/snapshot - Create snapshot</li>
                <li>GET /api/rooms/{id}/stats - Get room stats</li>
                <li>GET /api/rooms/compare - Compare all rooms</li>
            </ul>
        </body>
        </html>
        """
        response = HTTP.Response(200, html_content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    end
end

# ルームページのHTML
@get "/room.html" function(req::HTTP.Request)
    html_path = joinpath(dirname(@__FILE__), "..", "frontend", "room.html")
    if isfile(html_path)
        html_content = read(html_path, String)
        response = HTTP.Response(200, html_content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        response = HTTP.Response(404, "Room page not found")
        return add_cors_headers(response)
    end
end

println("Starting GA Novelist server on http://localhost:8082")
println("Available endpoints:")
println("  GET  /                      - Main page (4 rooms)")
println("  GET  /room.html            - Individual room page")
println("  GET  /api/rooms            - Get all rooms")
println("  GET  /api/rooms/{id}       - Get room details")
println("  POST /api/rooms/{id}/nudge - Apply mutation")
println("  GET  /api/rooms/{id}/stats - Get room stats")
println("  GET  /api/rooms/compare    - Compare all rooms")

serve(host="0.0.0.0", port=8082, middleware=[cors_middleware])