using LibPQ
using JSON3
using Dates
using UUIDs

include("db_config.jl")
include("ga_corpus.jl")

mutable struct Room
    id::String
    current_genome::TextGenome
    current_text::String
    generation::Int
    created_at::DateTime
    updated_at::DateTime
end

struct Nudge
    id::String
    room_id::String
    operator::String
    actor::String
    new_genome::TextGenome
    created_at::DateTime
end

struct Snapshot
    id::String
    room_id::String
    generation::Int
    text::String
    genome::TextGenome
    created_at::DateTime
end

# データベース接続を取得（毎回新規作成）
function get_db_connection()
    try
        return LibPQ.Connection(get_connection_string())
    catch e
        println("Error connecting to DB: $e")
        throw(e)
    end
end

function genome_to_json(genome::TextGenome)
    return JSON3.write(Dict(
        "genre_weights" => genome.genre_weights,
        "style_params" => genome.style_params,
        "character_traits" => genome.character_traits,
        "setting_elements" => genome.setting_elements,
        "text_segments" => genome.text_segments,
        "seed_value" => genome.seed_value
    ))
end

function json_to_genome(json_str::String)
    data = JSON3.read(json_str)
    return TextGenome(
        Dict(String(k) => v for (k, v) in data.genre_weights),
        Dict(String(k) => v for (k, v) in data.style_params),
        [String(s) for s in data.character_traits],
        [String(s) for s in data.setting_elements],
        [String(s) for s in get(data, :text_segments, String[])],
        get(data, :seed_value, rand(1:10000))
    )
end

function save_room(room::Room)
    conn = get_db_connection()
    
    # 既存のルームをチェック
    result = LibPQ.execute(conn, 
        "SELECT id FROM rooms WHERE name = \$1",
        [room.id]
    )
    
    if isempty(result)
        # 新規作成
        LibPQ.execute(conn,
            """INSERT INTO rooms (id, name, current_generation, created_at, updated_at)
               VALUES (\$1, \$2, \$3, \$4, \$5)""",
            [string(uuid4()), room.id, room.generation, room.created_at, room.updated_at]
        )
    else
        # 更新
        room_uuid = result[1,1]
        LibPQ.execute(conn,
            """UPDATE rooms 
               SET current_generation = \$1, updated_at = \$2
               WHERE id = \$3""",
            [room.generation, room.updated_at, room_uuid]
        )
    end
    
    # ゲノムを保存
    save_genome(conn, room)
    
    # テキストを保存
    save_text(conn, room)
end

function save_genome(conn, room::Room)
    # room.idをroom名として使用
    result = LibPQ.execute(conn, "SELECT id FROM rooms WHERE name = \$1", [room.id])
    if !isempty(result)
        room_uuid = result[1,1]
        
        # 既存の同じgenerationのゲノムをチェック
        existing = LibPQ.execute(conn,
            "SELECT id FROM genomes WHERE room_id = \$1 AND generation = \$2",
            [room_uuid, room.generation]
        )
        
        if isempty(existing)
            LibPQ.execute(conn,
                """INSERT INTO genomes (id, room_id, generation, genome_data, mutation_count, created_at)
                   VALUES (\$1, \$2, \$3, \$4, \$5, \$6)""",
                [string(uuid4()), room_uuid, room.generation, genome_to_json(room.current_genome), 0, room.updated_at]
            )
        end
    end
end

function save_text(conn, room::Room)
    result = LibPQ.execute(conn, "SELECT id FROM rooms WHERE name = \$1", [room.id])
    if !isempty(result)
        room_uuid = result[1,1]
        
        # 既存の同じgenerationのテキストをチェック
        existing = LibPQ.execute(conn,
            "SELECT id FROM texts WHERE room_id = \$1 AND generation = \$2",
            [room_uuid, room.generation]
        )
        
        if isempty(existing)
            LibPQ.execute(conn,
                """INSERT INTO texts (id, room_id, generation, content, created_at)
                   VALUES (\$1, \$2, \$3, \$4, \$5)""",
                [string(uuid4()), room_uuid, room.generation, room.current_text, room.updated_at]
            )
        end
    end
end

function load_room(room_name::String)
    conn = get_db_connection()
    
    # ルーム情報を取得
    result = LibPQ.execute(conn,
        """SELECT r.id, r.current_generation, r.created_at, r.updated_at,
                  t.content, g.genome_data
           FROM rooms r
           LEFT JOIN texts t ON r.id = t.room_id AND r.current_generation = t.generation
           LEFT JOIN genomes g ON r.id = g.room_id AND r.current_generation = g.generation
           WHERE r.name = \$1""",
        [room_name]
    )
    
    if isempty(result)
        return nothing
    end
    
    # 最初の行のデータを取得
    room_uuid = result[1, 1]
    generation = result[1, 2]
    created_at = DateTime(result[1, 3])  # Convert ZonedDateTime to DateTime
    updated_at = DateTime(result[1, 4])  # Convert ZonedDateTime to DateTime
    text_content = result[1, 5]
    genome_data = result[1, 6]
    
    # ゲノムデータがない場合はデフォルトを使用
    genome = if !ismissing(genome_data) && genome_data !== nothing
        json_to_genome(genome_data)
    else
        create_initial_genome()
    end
    
    # テキストがない場合は空文字列
    text = if !ismissing(text_content) && text_content !== nothing
        text_content
    else
        ""
    end
    
    return Room(
        room_name,
        genome,
        text,
        generation,
        created_at,
        updated_at
    )
end

function save_mutation(room_name::String, operator::String, actor::String, generation_before::Int, generation_after::Int, text_preview::String)
    conn = get_db_connection()
    
    # room_nameからroom_idを取得
    result = LibPQ.execute(conn, "SELECT id FROM rooms WHERE name = \$1", [room_name])
    if !isempty(result)
        room_uuid = result[1,1]
        
        LibPQ.execute(conn,
            """INSERT INTO mutations (id, room_id, operator, actor, generation_before, generation_after, text_preview, created_at)
               VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)""",
            [string(uuid4()), room_uuid, operator, actor, generation_before, generation_after, 
             first(text_preview, 100), now()]
        )
    end
end

# create_initial_genome is defined in ga_corpus_postgres.jl

# ルームが存在しない場合は作成
function ensure_room_exists(room_name::String)
    conn = get_db_connection()
    
    result = LibPQ.execute(conn, "SELECT id FROM rooms WHERE name = \$1", [room_name])
    
    if isempty(result)
        # 新しいルームを作成
        LibPQ.execute(conn,
            """INSERT INTO rooms (id, name, current_generation, created_at, updated_at)
               VALUES (\$1, \$2, \$3, \$4, \$5)""",
            [string(uuid4()), room_name, 0, now(), now()]
        )
        
        # 初期ゲノムとテキストを作成
        room = Room(
            room_name,
            create_initial_genome(),
            "GA Novelist - Room $room_name",
            0,
            now(),
            now()
        )
        save_room(room)
        
        return room
    else
        return load_room(room_name)
    end
end