using Random
using LibPQ
include("corpus.jl")
include("db_config.jl")

# 文章の遺伝子表現（改良版）
mutable struct TextGenome
    genre_weights::Dict{String, Float64}
    style_params::Dict{String, Float64}
    character_traits::Vector{String}
    setting_elements::Vector{String}
    text_segments::Vector{String}
    seed_value::Int  # 再現性のためのシード値
end

# RDSからパラグラフを生成
function generate_paragraph_from_db(genre::String, num_sentences::Int)
    # コーパスを取得
    corpus = get_genre_corpus(genre)
    templates = get_templates_from_db(genre)
    phrases = get_phrases_from_db(genre)
    
    sentences = String[]
    
    for i in 1:num_sentences
        # テンプレートを選択
        template = if !isempty(templates)
            templates[rand(1:length(templates))]
        else
            "{主体}は{場所}で{発見物}を見つけた。"
        end
        
        # スロットを埋める
        sentence = template
        for (slot_type, words) in corpus
            if !isempty(words)
                word = words[rand(1:length(words))]
                sentence = replace(sentence, "{$slot_type}" => word)
            end
        end
        
        # フレーズを追加
        if !isempty(phrases) && rand() < 0.3
            phrase = phrases[rand(1:length(phrases))]
            sentence = phrase * "、" * sentence
        end
        
        push!(sentences, sentence)
    end
    
    return join(sentences, "")
end

# 初期遺伝子を作成（RDSベース）
function create_initial_genome()
    # 初期段落を生成
    segments = String[]
    
    # 導入部
    intro = generate_paragraph_from_db("neutral", 4)
    push!(segments, intro)
    
    # 発見シーン
    discovery = generate_paragraph_from_db("neutral", 3)
    push!(segments, discovery)
    
    # 反応シーン
    reaction = generate_paragraph_from_db("neutral", 3)
    push!(segments, reaction)
    
    # 展開シーン
    development = generate_paragraph_from_db("neutral", 4)
    push!(segments, development)
    
    # 結末への布石
    conclusion = generate_paragraph_from_db("neutral", 3)
    push!(segments, conclusion)
    
    return TextGenome(
        Dict(
            "horror" => 0.09,
            "romance" => 0.09,
            "scifi" => 0.09,
            "comedy" => 0.09,
            "poetic" => 0.09,
            "tempo" => 0.09,
            "dialogue" => 0.09,
            "characters" => 0.09,
            "setting" => 0.09,
            "chaos" => 0.09,
            "neutral" => 0.10
        ),
        Dict(
            "complexity" => 0.5,
            "coherence" => 0.7,
            "creativity" => 0.3
        ),
        String[],
        String[],
        segments,
        rand(1:10000)
    )
end

# テキストを生成（style_paramsを考慮）
function generate_text(genome::TextGenome)
    # 基本テキスト
    base_text = join(genome.text_segments, "\n\n")

    # style_paramsに基づいて修飾を追加
    if get(genome.style_params, "dialogue_ratio", 0.0) > 0.5
        # 対話が多い場合、セリフっぽい要素を追加
        base_text = replace(base_text, "。" => "」\n「", count=2)
        base_text = "「" * base_text
    end

    if get(genome.style_params, "metaphor", 0.0) > 0.5
        # 詩的な場合、改行を増やす
        base_text = replace(base_text, "。" => "。\n", count=3)
    end

    if get(genome.style_params, "urgency", 0.0) > 0.5
        # テンポが速い場合、短文を追加
        base_text = base_text * "\n\n時間がない。急げ。今すぐに。"
    end

    # character_traitsを文章に反映
    if !isempty(genome.character_traits)
        traits_text = join(genome.character_traits[1:min(3, end)], "、")
        base_text = base_text * "\n\n登場人物は" * traits_text * "だった。"
    end

    # setting_elementsを文章に反映
    if !isempty(genome.setting_elements)
        settings_text = join(genome.setting_elements[1:min(2, end)], "と")
        base_text = "舞台は" * settings_text * "。\n\n" * base_text
    end

    return base_text
end

# 変異操作（ジャンル別）
function mutate_with_genre!(genome::TextGenome, genre::String)
    # ジャンルの重みを調整
    current = genome.genre_weights[genre]
    genome.genre_weights[genre] = min(1.0, current + 0.2)
    
    # 他のジャンルを正規化
    total = sum(values(genome.genre_weights))
    for (g, w) in genome.genre_weights
        genome.genre_weights[g] = w / total
    end
    
    # ランダムに1-2つのセグメントを再生成
    num_segments_to_regenerate = rand(1:2)
    indices = randperm(length(genome.text_segments))[1:num_segments_to_regenerate]
    
    for idx in indices
        # ジャンルの重みに基づいて段落を再生成
        mixed_corpus = get_mixed_corpus(genome.genre_weights)
        new_segment = generate_paragraph_with_corpus(mixed_corpus, genre, rand(3:5))
        genome.text_segments[idx] = new_segment
    end
    
    # シード値を更新（再現性のため）
    genome.seed_value = rand(1:10000)
    
    return genome
end

function generate_paragraph_with_corpus(corpus::Dict, genre::String, num_sentences::Int)
    templates = get_templates_from_db(genre)
    phrases = get_phrases_from_db(genre)
    
    sentences = String[]
    
    for i in 1:num_sentences
        # テンプレートを選択
        template = if !isempty(templates)
            templates[rand(1:length(templates))]
        else
            "{主体}は{場所}で{発見物}を見つけた。"
        end
        
        # スロットを埋める
        sentence = template
        for (slot_type, words) in corpus
            if !isempty(words)
                word = words[rand(1:length(words))]
                sentence = replace(sentence, "{$slot_type}" => word)
            end
        end
        
        # フレーズを追加
        if !isempty(phrases) && rand() < 0.3
            phrase = phrases[rand(1:length(phrases))]
            sentence = phrase * "、" * sentence
        end
        
        push!(sentences, sentence)
    end
    
    return join(sentences, "")
end

# 詩的表現を強化する変異
function mutate_poetic!(genome::TextGenome)
    # 詩的要素のパラメータを増強
    genome.style_params["metaphor"] = min(1.0, get(genome.style_params, "metaphor", 0.2) + 0.15)
    genome.style_params["imagery"] = min(1.0, get(genome.style_params, "imagery", 0.2) + 0.15)
    genome.style_params["rhythm"] = min(1.0, get(genome.style_params, "rhythm", 0.2) + 0.1)

    # 詩的な単語を追加
    push!(genome.setting_elements, rand(["黄昏", "蒼穹", "刹那", "永遠", "煌めき", "静寂"]))
    return genome
end

# テンポを速める変異
function mutate_tempo!(genome::TextGenome)
    # 短い文を増やし、アクションを増加
    genome.style_params["sentence_length"] = max(0.1, get(genome.style_params, "sentence_length", 0.5) - 0.15)
    genome.style_params["action_density"] = min(1.0, get(genome.style_params, "action_density", 0.3) + 0.2)
    genome.style_params["urgency"] = min(1.0, get(genome.style_params, "urgency", 0.2) + 0.15)

    # アクション要素を追加
    push!(genome.character_traits, rand(["素早い", "機敏な", "電光石火の", "一瞬の"]))
    return genome
end

# 対話を増やす変異
function mutate_dialogue!(genome::TextGenome)
    # 対話比率を増加
    genome.style_params["dialogue_ratio"] = min(1.0, get(genome.style_params, "dialogue_ratio", 0.2) + 0.25)
    genome.style_params["quotation_marks"] = min(1.0, get(genome.style_params, "quotation_marks", 0.2) + 0.2)

    # 話者を追加
    push!(genome.character_traits, rand(["話好きな", "雄弁な", "饒舌な", "口数の多い"]))
    return genome
end

# キャラクターの多様性を増やす変異
function mutate_characters!(genome::TextGenome)
    # 新しいキャラクター特性を複数追加
    new_traits = ["賢い", "勇敢な", "神秘的な", "陽気な", "冷静な", "情熱的な", "狡猾な", "純真な"]
    for _ in 1:2  # 2つの特性を追加
        push!(genome.character_traits, rand(new_traits))
    end

    # キャラクター密度を増加
    genome.style_params["character_density"] = min(1.0, get(genome.style_params, "character_density", 0.3) + 0.2)
    return genome
end

# 環境・舞台を変化させる変異
function mutate_setting!(genome::TextGenome)
    # 新しい舞台要素を追加
    new_settings = ["未来都市", "深い森", "宇宙ステーション", "海底都市", "異世界", "古代遺跡", "雲の上", "地下迷宮"]
    push!(genome.setting_elements, rand(new_settings))

    # 環境描写を増加
    genome.style_params["environment_detail"] = min(1.0, get(genome.style_params, "environment_detail", 0.3) + 0.2)
    genome.style_params["sensory_description"] = min(1.0, get(genome.style_params, "sensory_description", 0.2) + 0.15)
    return genome
end

# カオス的な変異（ランダム性を強化）
function mutate_chaos!(genome::TextGenome)
    # 全ジャンルの重みをランダムに再配分
    genres = collect(keys(genome.genre_weights))
    for genre in genres
        genome.genre_weights[genre] = rand() * 0.4 + 0.1  # 0.1～0.5の範囲
    end

    # 正規化
    total = sum(values(genome.genre_weights))
    for genre in genres
        genome.genre_weights[genre] /= total
    end

    # スタイルパラメータもランダムに変更
    for key in keys(genome.style_params)
        genome.style_params[key] = rand()
    end

    # ランダムな要素を追加
    push!(genome.setting_elements, "混沌")
    push!(genome.character_traits, "予測不能な")

    return genome
end

# 変異操作のマッピング
const MUTATION_MAP = Dict(
    "horror" => genome -> mutate_with_genre!(genome, "horror"),
    "romance" => genome -> mutate_with_genre!(genome, "romance"),
    "scifi" => genome -> mutate_with_genre!(genome, "scifi"),
    "comedy" => genome -> mutate_with_genre!(genome, "comedy"),
    "neutral" => genome -> mutate_with_genre!(genome, "neutral"),
    "poetic" => mutate_poetic!,
    "tempo" => mutate_tempo!,
    "dialogue" => mutate_dialogue!,
    "characters" => mutate_characters!,
    "setting" => mutate_setting!,
    "chaos" => mutate_chaos!
)