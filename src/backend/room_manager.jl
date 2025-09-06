using Dates
using UUIDs
include("ga_hybrid.jl")
include("corpus.jl")

# ルーム構造体
mutable struct Room
    id::String
    name::String
    current_genome::TextGenome
    current_text::String
    generation::Int
    created_at::DateTime
    updated_at::DateTime
    nudge_history::Vector{Dict{String, Any}}
end

# グローバルルーム管理
const ROOMS = Dict{String, Room}()

# 初期の4ルームを作成
function initialize_rooms()
    room_names = ["Room A", "Room B", "Room C", "Room D"]
    
    for name in room_names
        room_id = string(uuid4())
        initial_genome = create_initial_genome()
        initial_text = render_text(initial_genome)
        
        room = Room(
            room_id,
            name,
            initial_genome,
            initial_text,
            0,
            now(),
            now(),
            Vector{Dict{String, Any}}()
        )
        
        ROOMS[room_id] = room
    end
    
    return ROOMS
end

# ルーム取得
function get_room(room_id::String)
    return get(ROOMS, room_id, nothing)
end

# 全ルーム取得
function get_all_rooms()
    return values(ROOMS)
end

# ルームの状態を更新（nudge操作）
function nudge_room(room_id::String, operator::String, actor::String="anonymous")
    room = get_room(room_id)
    if room === nothing
        return nothing
    end
    
    # 突然変異を適用
    new_genome = apply_mutation(room.current_genome, operator)
    new_text = render_text(new_genome)
    
    # ルームを更新
    room.current_genome = new_genome
    room.current_text = new_text
    room.generation += 1
    room.updated_at = now()
    
    # 履歴に追加
    push!(room.nudge_history, Dict(
        "operator" => operator,
        "actor" => actor,
        "generation" => room.generation,
        "timestamp" => room.updated_at,
        "text_preview" => length(new_text) > 100 ? first(new_text, 100) * "..." : new_text
    ))
    
    # 履歴が100件を超えたら古いものを削除
    if length(room.nudge_history) > 100
        room.nudge_history = room.nudge_history[end-99:end]
    end
    
    return room
end

# ルームのスナップショットを作成
function create_snapshot(room_id::String)
    room = get_room(room_id)
    if room === nothing
        return nothing
    end
    
    return Dict(
        "room_id" => room.id,
        "room_name" => room.name,
        "generation" => room.generation,
        "text" => room.current_text,
        "genome" => Dict(
            "genre_weights" => room.current_genome.genre_weights,
            "style_params" => room.current_genome.style_params,
            "character_traits" => room.current_genome.character_traits,
            "setting_elements" => room.current_genome.setting_elements
        ),
        "timestamp" => now(),
        "recent_history" => room.nudge_history[max(1, end-9):end]
    )
end

# ルームの統計情報を取得
function get_room_stats(room_id::String)
    room = get_room(room_id)
    if room === nothing
        return nothing
    end
    
    # 最も使用されたオペレーターを集計
    operator_counts = Dict{String, Int}()
    for nudge in room.nudge_history
        op = nudge["operator"]
        operator_counts[op] = get(operator_counts, op, 0) + 1
    end
    
    # 最近のアクティビティ
    recent_activity = if length(room.nudge_history) > 0
        last_nudge = room.nudge_history[end]
        time_since_last = now() - last_nudge["timestamp"]
        minutes_ago = round(Int, time_since_last.value / (1000 * 60))
        minutes_ago
    else
        -1
    end
    
    return Dict(
        "room_id" => room.id,
        "room_name" => room.name,
        "generation" => room.generation,
        "total_nudges" => length(room.nudge_history),
        "most_used_operators" => operator_counts,
        "dominant_genre" => findmax(room.current_genome.genre_weights)[2],
        "minutes_since_last_activity" => recent_activity,
        "created_at" => room.created_at,
        "updated_at" => room.updated_at
    )
end

# 全ルームの比較データを取得
function compare_rooms()
    comparisons = []
    
    for room in values(ROOMS)
        push!(comparisons, Dict(
            "room_id" => room.id,
            "room_name" => room.name,
            "generation" => room.generation,
            "dominant_genre" => findmax(room.current_genome.genre_weights)[2],
            "text_preview" => length(room.current_text) > 200 ? 
                             first(room.current_text, 200) * "..." : room.current_text,
            "last_operator" => length(room.nudge_history) > 0 ? 
                              room.nudge_history[end]["operator"] : "none"
        ))
    end
    
    return comparisons
end