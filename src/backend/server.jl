using Oxygen
using HTTP
using JSON3
using Dates
using UUIDs

include("ga_engine.jl")
include("database.jl")
include("renderer.jl")

const rooms = Dict{String, Room}()

# CORS middleware
function cors_middleware(handler)
    return function(req::HTTP.Request)
        response = handler(req)
        
        # CORSヘッダーを追加
        HTTP.setheader(response, "Access-Control-Allow-Origin" => "*")
        HTTP.setheader(response, "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS")
        HTTP.setheader(response, "Access-Control-Allow-Headers" => "Content-Type")
        
        return response
    end
end

# OPTIONS リクエストの処理
@options "/*" function(req::HTTP.Request)
    response = HTTP.Response(204)
    HTTP.setheader(response, "Access-Control-Allow-Origin" => "*")
    HTTP.setheader(response, "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS")
    HTTP.setheader(response, "Access-Control-Allow-Headers" => "Content-Type")
    return response
end

@post "/api/rooms" function(req::HTTP.Request)
    room_id = string(uuid4())
    initial_text = "暗い森の奥で、少年は小さな光を見つけた。"
    
    room = Room(
        id = room_id,
        current_genome = initialize_genome(),
        current_text = initial_text,
        generation = 0,
        created_at = now(),
        updated_at = now()
    )
    
    rooms[room_id] = room
    save_room(room)
    
    return json(room)
end

@get "/api/rooms/{room_id}" function(req::HTTP.Request, room_id::String)
    if !haskey(rooms, room_id)
        room = load_room(room_id)
        if isnothing(room)
            return HTTP.Response(404, "Room not found")
        end
        rooms[room_id] = room
    end
    
    return json(rooms[room_id])
end

@post "/api/rooms/{room_id}/nudge" function(req::HTTP.Request, room_id::String)
    if !haskey(rooms, room_id)
        return HTTP.Response(404, "Room not found")
    end
    
    body = JSON3.read(String(req.body))
    operator = body.operator
    actor = get(body, :actor, "anonymous")
    
    room = rooms[room_id]
    
    new_genome = apply_mutation(room.current_genome, operator)
    new_text = render_text(new_genome)
    
    room.current_genome = new_genome
    room.current_text = new_text
    room.generation += 1
    room.updated_at = now()
    
    nudge = Nudge(
        id = string(uuid4()),
        room_id = room_id,
        operator = operator,
        actor = actor,
        new_genome = new_genome,
        created_at = now()
    )
    
    save_room(room)
    save_nudge(nudge)
    
    broadcast_update(room_id, room)
    
    return json(Dict(
        "room" => room,
        "nudge" => nudge
    ))
end

@get "/api/rooms/{room_id}/events" function(req::HTTP.Request, room_id::String)
    response = HTTP.Response(200)
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Connection"] = "keep-alive"
    
    return response
end

function broadcast_update(room_id::String, room::Room)
    # SSE/WebSocket実装は後で追加
    println("Broadcasting update for room $room_id")
end

# Oxygenサーバーの設定とCORS対応
serve(host="0.0.0.0", port=8080, middleware=[cors_middleware])