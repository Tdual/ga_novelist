using SQLite
using JSON3
using Dates
using UUIDs

mutable struct Room
    id::String
    current_genome::Genome
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
    new_genome::Genome
    created_at::DateTime
end

struct Snapshot
    id::String
    room_id::String
    generation::Int
    text::String
    genome::Genome
    created_at::DateTime
end

const DB_PATH = "../../db/ga_novelist.db"
let db = nothing
    global function get_db()
        if isnothing(db)
            db = SQLite.DB(DB_PATH)
            init_database(db)
        end
        return db
    end
end

function init_database(db)
    SQLite.execute(db, """
        CREATE TABLE IF NOT EXISTS rooms (
            id TEXT PRIMARY KEY,
            current_genome TEXT NOT NULL,
            current_text TEXT NOT NULL,
            generation INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    """)
    
    SQLite.execute(db, """
        CREATE TABLE IF NOT EXISTS nudges (
            id TEXT PRIMARY KEY,
            room_id TEXT NOT NULL,
            operator TEXT NOT NULL,
            actor TEXT NOT NULL,
            new_genome TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (room_id) REFERENCES rooms(id)
        )
    """)
    
    SQLite.execute(db, """
        CREATE TABLE IF NOT EXISTS snapshots (
            id TEXT PRIMARY KEY,
            room_id TEXT NOT NULL,
            generation INTEGER NOT NULL,
            text TEXT NOT NULL,
            genome TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (room_id) REFERENCES rooms(id)
        )
    """)
    
    SQLite.execute(db, """
        CREATE INDEX IF NOT EXISTS idx_nudges_room_id ON nudges(room_id)
    """)
    
    SQLite.execute(db, """
        CREATE INDEX IF NOT EXISTS idx_snapshots_room_id ON snapshots(room_id)
    """)
end

function genome_to_json(genome::Genome)
    return JSON3.write(Dict(
        "genre_weights" => genome.genre_weights,
        "style_params" => genome.style_params,
        "character_traits" => genome.character_traits,
        "setting_elements" => genome.setting_elements
    ))
end

function json_to_genome(json_str::String)
    data = JSON3.read(json_str)
    return Genome(
        Dict(String(k) => v for (k, v) in data.genre_weights),
        Dict(String(k) => v for (k, v) in data.style_params),
        [String(s) for s in data.character_traits],
        [String(s) for s in data.setting_elements]
    )
end

function save_room(room::Room)
    db = get_db()
    SQLite.execute(db, """
        INSERT OR REPLACE INTO rooms (id, current_genome, current_text, generation, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        room.id,
        genome_to_json(room.current_genome),
        room.current_text,
        room.generation,
        string(room.created_at),
        string(room.updated_at)
    ))
end

function load_room(room_id::String)
    db = get_db()
    result = SQLite.Query(db, """
        SELECT * FROM rooms WHERE id = ?
    """, (room_id,)) |> collect
    
    if isempty(result)
        return nothing
    end
    
    row = result[1]
    return Room(
        row.id,
        json_to_genome(row.current_genome),
        row.current_text,
        row.generation,
        DateTime(row.created_at),
        DateTime(row.updated_at)
    )
end

function save_nudge(nudge::Nudge)
    db = get_db()
    SQLite.execute(db, """
        INSERT INTO nudges (id, room_id, operator, actor, new_genome, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        nudge.id,
        nudge.room_id,
        nudge.operator,
        nudge.actor,
        genome_to_json(nudge.new_genome),
        string(nudge.created_at)
    ))
end

function save_snapshot(snapshot::Snapshot)
    db = get_db()
    SQLite.execute(db, """
        INSERT INTO snapshots (id, room_id, generation, text, genome, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        snapshot.id,
        snapshot.room_id,
        snapshot.generation,
        snapshot.text,
        genome_to_json(snapshot.genome),
        string(snapshot.created_at)
    ))
end