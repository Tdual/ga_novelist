using Random
using LibPQ
include("corpus_postgres.jl")
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
            "horror" => 0.2,
            "romance" => 0.2,
            "scifi" => 0.2,
            "comedy" => 0.2,
            "neutral" => 0.2
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

# テキストを生成
function generate_text(genome::TextGenome)
    return join(genome.text_segments, "\n\n")
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

# 変異操作のマッピング
const MUTATION_MAP = Dict(
    "horror" => genome -> mutate_with_genre!(genome, "horror"),
    "romance" => genome -> mutate_with_genre!(genome, "romance"),
    "scifi" => genome -> mutate_with_genre!(genome, "scifi"),
    "comedy" => genome -> mutate_with_genre!(genome, "comedy"),
    "neutral" => genome -> mutate_with_genre!(genome, "neutral")
)