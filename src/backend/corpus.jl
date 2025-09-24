using LibPQ
include("db_config.jl")

# RDSからコーパスデータを取得
function get_corpus_from_db(genre::String, slot_type::String)
    conn = LibPQ.Connection(get_connection_string())
    
    result = LibPQ.execute(conn,
        """SELECT word, weight 
           FROM corpus_words 
           WHERE genre = \$1 AND slot_type = \$2
           ORDER BY weight DESC""",
        [genre, slot_type]
    )
    
    words = String[]
    for row in result
        push!(words, row[1])
    end
    
    close(conn)
    return words
end

# 文テンプレートを取得
function get_templates_from_db(genre::Union{String, Nothing} = nothing)
    conn = LibPQ.Connection(get_connection_string())
    
    if genre === nothing
        result = LibPQ.execute(conn,
            """SELECT template FROM sentence_templates
               WHERE genre IS NULL OR genre = 'neutral'
               ORDER BY RANDOM() LIMIT 10"""
        )
    else
        result = LibPQ.execute(conn,
            """SELECT template FROM sentence_templates
               WHERE genre = \$1 OR genre IS NULL
               ORDER BY RANDOM() LIMIT 10""",
            [genre]
        )
    end
    
    templates = String[]
    for row in result
        push!(templates, row[1])
    end
    
    close(conn)
    return templates
end

# フレーズパターンを取得
function get_phrases_from_db(genre::String)
    conn = LibPQ.Connection(get_connection_string())
    
    result = LibPQ.execute(conn,
        """SELECT phrase FROM phrase_patterns
           WHERE genre = \$1
           ORDER BY RANDOM() LIMIT 10""",
        [genre]
    )
    
    phrases = String[]
    for row in result
        push!(phrases, row[1])
    end
    
    close(conn)
    return phrases
end

# ジャンル別コーパスを取得
function get_genre_corpus(genre::String)
    slots = Dict(
        "主体" => get_corpus_from_db(genre, "主体"),
        "場所" => get_corpus_from_db(genre, "場所"),
        "発見物" => get_corpus_from_db(genre, "発見物"),
        "動作" => get_corpus_from_db(genre, "動作"),
        "感情" => get_corpus_from_db(genre, "感情")
    )
    
    # 空のスロットにはneutralから補充
    for (slot_type, words) in slots
        if isempty(words)
            slots[slot_type] = get_corpus_from_db("neutral", slot_type)
        end
    end
    
    return slots
end

# ミックスコーパスを生成（ジャンルの重み付けに基づく）
function get_mixed_corpus(genre_weights::Dict{String, Float64})
    mixed_slots = Dict(
        "主体" => String[],
        "場所" => String[],
        "発見物" => String[],
        "動作" => String[],
        "感情" => String[]
    )
    
    # 各ジャンルから重みに応じて単語を取得
    for (genre, weight) in genre_weights
        if weight > 0.1  # 10%以上の重みがあるジャンルのみ
            genre_corpus = get_genre_corpus(genre)
            
            for (slot_type, words) in genre_corpus
                # 重みに応じた数の単語を追加
                num_words = max(1, Int(round(length(words) * weight)))
                append!(mixed_slots[slot_type], words[1:min(num_words, length(words))])
            end
        end
    end
    
    # 重複を除去
    for (slot_type, words) in mixed_slots
        mixed_slots[slot_type] = unique(words)
    end
    
    return mixed_slots
end