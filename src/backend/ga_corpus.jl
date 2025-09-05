using Random
include("corpus.jl")

# 文章の遺伝子表現（改良版）
mutable struct TextGenome
    genre_weights::Dict{String, Float64}
    style_params::Dict{String, Float64}
    character_traits::Vector{String}
    setting_elements::Vector{String}
    text_segments::Vector{String}
    seed_value::Int  # 再現性のためのシード値
end

# グローバルコーパス
const GLOBAL_CORPUS = initialize_corpus()

# 初期遺伝子を作成（コーパスベース）
function create_initial_genome()
    # 初期段落を生成
    segments = String[]
    
    # 導入部
    intro = generate_paragraph(GLOBAL_CORPUS, "neutral", 4)
    push!(segments, intro)
    
    # 発見シーン
    discovery = generate_paragraph(GLOBAL_CORPUS, "neutral", 3)
    push!(segments, discovery)
    
    # 反応シーン
    reaction = generate_paragraph(GLOBAL_CORPUS, "neutral", 3)
    push!(segments, reaction)
    
    # 展開シーン
    development = generate_paragraph(GLOBAL_CORPUS, "neutral", 4)
    push!(segments, development)
    
    # 結末への布石
    conclusion = generate_paragraph(GLOBAL_CORPUS, "neutral", 3)
    push!(segments, conclusion)
    
    return TextGenome(
        Dict(
            "horror" => 0.2,
            "romance" => 0.2,
            "scifi" => 0.2,
            "comedy" => 0.2,
            "mystery" => 0.2
        ),
        Dict(
            "dialogue_ratio" => 0.2,
            "description_density" => 0.5,
            "pace" => 0.5,
            "poetic_level" => 0.3,
            "complexity" => 0.5
        ),
        ["探索者"],
        ["未知の場所"],
        segments,
        rand(1:10000)
    )
end

# ホラー変換（コーパスベース）
function mutate_horror(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["horror"] = min(1.0, genome.genre_weights["horror"] + 0.3 + rand() * 0.2)
    new_genome.seed_value = rand(1:10000)
    
    # 各段落をホラー風に再生成
    for i in 1:length(new_genome.text_segments)
        # 既存のテキストを参考にしつつ、新しいホラーテキストを生成
        horror_paragraph = generate_paragraph(GLOBAL_CORPUS, "horror", 3 + rand(0:2))
        
        # 時々既存テキストの一部を保持（連続性のため）
        if rand() < 0.3
            original_words = split(new_genome.text_segments[i])[1:min(5, end)]
            horror_paragraph = join(original_words, " ") * "。" * horror_paragraph
        end
        
        new_genome.text_segments[i] = horror_paragraph
    end
    
    # ホラー要素を追加
    horror_traits = ["恐怖に怯える", "震える", "蒼白な"]
    push!(new_genome.character_traits, rand(horror_traits))
    
    horror_settings = ["闇", "影", "呪い", "亡霊", "血"]
    for _ in 1:rand(1:3)
        push!(new_genome.setting_elements, rand(horror_settings))
    end
    
    return new_genome
end

# ロマンス変換（コーパスベース）
function mutate_romance(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["romance"] = min(1.0, genome.genre_weights["romance"] + 0.3 + rand() * 0.2)
    new_genome.seed_value = rand(1:10000)
    
    for i in 1:length(new_genome.text_segments)
        romance_paragraph = generate_paragraph(GLOBAL_CORPUS, "romance", 3 + rand(0:2))
        
        if rand() < 0.3
            original_words = split(new_genome.text_segments[i])[1:min(5, end)]
            romance_paragraph = join(original_words, " ") * "。" * romance_paragraph
        end
        
        new_genome.text_segments[i] = romance_paragraph
    end
    
    # ロマンス要素を追加
    names = ["レオ", "ユイ", "アキラ", "ミサキ", "ハルト"]
    push!(new_genome.character_traits, rand(names))
    
    romance_settings = ["運命", "約束", "永遠", "愛", "奇跡"]
    for _ in 1:rand(1:2)
        push!(new_genome.setting_elements, rand(romance_settings))
    end
    
    return new_genome
end

# SF変換（コーパスベース）
function mutate_scifi(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["scifi"] = min(1.0, genome.genre_weights["scifi"] + 0.3 + rand() * 0.2)
    new_genome.seed_value = rand(1:10000)
    
    for i in 1:length(new_genome.text_segments)
        scifi_paragraph = generate_paragraph(GLOBAL_CORPUS, "scifi", 3 + rand(0:2))
        
        if rand() < 0.3
            original_words = split(new_genome.text_segments[i])[1:min(5, end)]
            scifi_paragraph = join(original_words, " ") * "。" * scifi_paragraph
        end
        
        new_genome.text_segments[i] = scifi_paragraph
    end
    
    # SF要素を追加
    scifi_traits = ["データアナリスト", "量子物理学者", "AIエンジニア"]
    push!(new_genome.character_traits, rand(scifi_traits))
    
    scifi_settings = ["量子空間", "バイオドーム", "データストリーム", "特異点"]
    for _ in 1:rand(1:3)
        push!(new_genome.setting_elements, rand(scifi_settings))
    end
    
    return new_genome
end

# コメディ変換（コーパスベース）
function mutate_comedy(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["comedy"] = min(1.0, genome.genre_weights["comedy"] + 0.3 + rand() * 0.2)
    new_genome.seed_value = rand(1:10000)
    
    for i in 1:length(new_genome.text_segments)
        comedy_paragraph = generate_paragraph(GLOBAL_CORPUS, "comedy", 3 + rand(0:2))
        
        # コメディは効果音を追加
        effects = ["ドカーン！", "ズコー！", "ガビーン！", "えぇぇ！？"]
        if rand() < 0.4
            comedy_paragraph = rand(effects) * comedy_paragraph
        end
        
        new_genome.text_segments[i] = comedy_paragraph
    end
    
    push!(new_genome.character_traits, "ドジっ子")
    push!(new_genome.setting_elements, "カオス")
    
    return new_genome
end

# 詩的変換（文体調整）
function mutate_poetic(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["poetic_level"] = min(1.0, genome.style_params["poetic_level"] + 0.4)
    new_genome.seed_value = rand(1:10000)
    
    for i in 1:length(new_genome.text_segments)
        # 既存のテキストを詩的に変換
        poetic_text = apply_style(new_genome.text_segments[i], GLOBAL_CORPUS, "poetic")
        
        # 詩的なフレーズを追加
        poetic_phrases = [
            "まるで夢のように、",
            "永遠の時が流れるように、",
            "静寂の中で、",
            "運命の糸に導かれて、"
        ]
        
        if rand() < 0.5
            poetic_text = rand(poetic_phrases) * poetic_text
        end
        
        new_genome.text_segments[i] = poetic_text
    end
    
    return new_genome
end

# スピード感変換（短文化）
function mutate_speed(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["pace"] = min(1.0, genome.style_params["pace"] + 0.4)
    new_genome.seed_value = rand(1:10000)
    
    for i in 1:length(new_genome.text_segments)
        # 短い文を生成
        sentences = split(new_genome.text_segments[i], "。")
        short_sentences = String[]
        
        for sentence in sentences
            if length(sentence) > 20
                # 長い文を短く
                words = split(sentence)
                if length(words) > 5
                    push!(short_sentences, join(words[1:5], " "))
                else
                    push!(short_sentences, sentence)
                end
            else
                push!(short_sentences, sentence)
            end
        end
        
        new_genome.text_segments[i] = join(short_sentences, "。") * "。"
    end
    
    return new_genome
end

# セリフ増加変換
function mutate_dialogue(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["dialogue_ratio"] = min(1.0, genome.style_params["dialogue_ratio"] + 0.4)
    new_genome.seed_value = rand(1:10000)
    
    dialogues = [
        "「これは一体...」",
        "「信じられない」",
        "「どうしよう」",
        "「まさか、こんなことが」",
        "「助けて！」",
        "「大丈夫？」",
        "「見て、あれ！」"
    ]
    
    for i in 1:length(new_genome.text_segments)
        # セリフを挿入
        if rand() < 0.6
            new_genome.text_segments[i] = rand(dialogues) * "\n" * new_genome.text_segments[i]
        end
        
        if rand() < 0.4
            new_genome.text_segments[i] = new_genome.text_segments[i] * "\n" * rand(dialogues)
        end
    end
    
    return new_genome
end

# キャラ増加変換
function mutate_characters(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.seed_value = rand(1:10000)
    
    # 新しいキャラクターを追加
    new_characters = ["ミク", "タクヤ", "サクラ", "リョウ", "ユキ"]
    new_char = rand(new_characters)
    
    for i in 1:length(new_genome.text_segments)
        if rand() < 0.3
            # 新キャラクターの登場シーン
            intro_phrases = [
                "そこへ$(new_char)がやってきた。",
                "「待って！」$(new_char)の声が響いた。",
                "突然、$(new_char)が現れた。",
                "$(new_char)が駆け寄ってきた。"
            ]
            
            new_genome.text_segments[i] = new_genome.text_segments[i] * rand(intro_phrases)
        end
    end
    
    push!(new_genome.character_traits, new_char)
    
    return new_genome
end

# 舞台変更変換
function mutate_setting(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.seed_value = rand(1:10000)
    
    # 新しい舞台設定
    settings = ["都市", "海辺", "山頂", "地下", "宇宙", "異世界"]
    new_setting = rand(settings)
    
    # 舞台に応じた新しい段落を生成
    for i in 1:length(new_genome.text_segments)
        if rand() < 0.5
            # 舞台説明を追加
            setting_descriptions = Dict(
                "都市" => "ビルが立ち並ぶ都市の中、",
                "海辺" => "波の音が響く海辺で、",
                "山頂" => "雲を見下ろす山頂から、",
                "地下" => "薄暗い地下の通路を進みながら、",
                "宇宙" => "無重力の空間を漂いながら、",
                "異世界" => "見たこともない風景の中で、"
            )
            
            prefix = get(setting_descriptions, new_setting, "")
            new_genome.text_segments[i] = prefix * new_genome.text_segments[i]
        end
    end
    
    new_genome.setting_elements = [new_setting]
    
    return new_genome
end

# 混沌変換
function mutate_chaos(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.seed_value = rand(1:10000)
    
    # 全ジャンルをランダムに混ぜる
    genres = ["horror", "romance", "scifi", "comedy"]
    
    for i in 1:length(new_genome.text_segments)
        # ランダムなジャンルから段落を生成
        random_genre = rand(genres)
        chaos_paragraph = generate_paragraph(GLOBAL_CORPUS, random_genre, rand(2:5))
        
        # 時々元のテキストと混ぜる
        if rand() < 0.5
            new_genome.text_segments[i] = new_genome.text_segments[i] * chaos_paragraph
        else
            new_genome.text_segments[i] = chaos_paragraph
        end
        
        # ランダムな効果音や感嘆符を追加
        if rand() < 0.3
            exclamations = ["！？", "...!!", "ーーー！", "???"]
            new_genome.text_segments[i] = new_genome.text_segments[i] * rand(exclamations)
        end
    end
    
    # 全ジャンルの重みをランダムに
    for genre in keys(new_genome.genre_weights)
        new_genome.genre_weights[genre] = rand()
    end
    
    push!(new_genome.setting_elements, "混沌")
    
    return new_genome
end

# 変換を適用する関数
function apply_mutation(genome::TextGenome, operator::String)
    mutations = Dict(
        "もっとホラー" => mutate_horror,
        "もっとロマンス" => mutate_romance,
        "もっとSF" => mutate_scifi,
        "もっとコメディ" => mutate_comedy,
        "もっと詩的に" => mutate_poetic,
        "もっとスピード感" => mutate_speed,
        "もっとセリフを" => mutate_dialogue,
        "もっとキャラを増やす" => mutate_characters,
        "もっと舞台を変える" => mutate_setting,
        "もっと混沌" => mutate_chaos
    )
    
    if haskey(mutations, operator)
        return mutations[operator](genome)
    else
        return genome
    end
end

# テキストの出力
function render_text(genome::TextGenome)
    return join(genome.text_segments, "\n\n")
end