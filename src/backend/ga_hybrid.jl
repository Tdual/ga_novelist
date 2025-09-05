using Random
include("corpus.jl")

# 文章の遺伝子表現（ハイブリッド版）
mutable struct TextGenome
    genre_weights::Dict{String, Float64}
    style_params::Dict{String, Float64}
    character_traits::Vector{String}
    setting_elements::Vector{String}
    text_segments::Vector{String}
    mutation_count::Int  # 変異回数を記録
end

# グローバルコーパス
const GLOBAL_CORPUS = initialize_corpus()

# 初期文章（固定のベーステキスト）
const BASE_TEXT = """
森の中の小道を、少年はとことこと歩いていた。昼間のはずなのに、頭の上の木々が光をさえぎっていて、足元はほとんど夕方みたいに暗い。鳥の声も聞こえないし、風も止んでいる。さっきまで普通に賑やかだったのに、この場所だけぽっかり切り取られたような静けさに包まれていた。

そんなとき、少年は足元に小さな光を見つけた。落ち葉の隙間から、ビー玉くらいの大きさで、青白くチカチカしている。最初はガラス片かと思ったけれど、どうやら違う。光は呼吸みたいにふくらんだり縮んだりして、まるで生き物みたいに動いていた。

「なんだこれ？」
少年はしゃがみこんで、手で落ち葉を払いのけた。すると、丸い透明な殻の中に小さな粒が浮かんでいて、星を閉じ込めたようにキラキラしていた。思わず触れてみたくなって、そっと指先でつついてみる。殻は意外にもひんやり冷たくて、ビリッと静電気のような刺激が走った。

その瞬間、森がざわっと揺れたような気がした。枝葉が一斉に震え、どこか遠くで木のきしむ音が響いた。光の玉は少年の手の中で震えながら、じわじわ形を変えていく。丸かったはずなのに、少しだけ尖ったり、なめらかに伸びたり。少年の手に合わせてフィットしようとしているみたいだ。

心臓がドクンと大きく鳴った。怖いような、でもワクワクするような、複雑な気持ちが押し寄せてくる。手を離すべきか、それとももっと確かめるべきか。頭の中では警鐘が鳴っているのに、体は逆に光を手のひらで包み込んでしまっていた。
"""

# 初期遺伝子を作成
function create_initial_genome()
    segments = split(strip(BASE_TEXT), "\n\n")
    
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
        ["少年"],
        ["森", "小道", "光"],
        [String(s) for s in segments],
        0
    )
end

# 部分的な単語置換（コーパスから選択）
function replace_with_corpus(text::String, replacements::Dict{String, String}, corpus::TextCorpus, genre::String, probability::Float64=0.3)
    result = text
    
    for (original, slot_name) in replacements
        if rand() < probability && contains(result, original)
            # コーパスから代替語を取得
            words = nothing
            
            # ジャンル固有の単語を探す
            if haskey(corpus.word_slots, genre) && haskey(corpus.word_slots[genre], slot_name)
                words = corpus.word_slots[genre][slot_name]
            end
            
            # なければneutralから
            if words === nothing && haskey(corpus.word_slots["neutral"], slot_name)
                words = corpus.word_slots["neutral"][slot_name]
            end
            
            if words !== nothing
                replacement = rand(words)
                # 元の単語に修飾語を追加する形で置換（完全置換ではない）
                if rand() < 0.5
                    # 修飾語を追加
                    result = replace(result, original => replacement * "の" * original, count=1)
                else
                    # 単純置換
                    result = replace(result, original => replacement, count=1)
                end
            end
        end
    end
    
    return result
end

# ホラー変換（段階的）
function mutate_horror(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["horror"] = min(1.0, genome.genre_weights["horror"] + 0.3)
    new_genome.mutation_count += 1
    
    # 変異の強度を計算（変異回数が多いほど強い変化）
    mutation_strength = min(1.0, new_genome.genre_weights["horror"])
    
    # 置換マッピング
    replacements = Dict(
        "森" => "場所",
        "小道" => "場所",
        "少年" => "主体",
        "光" => "発見物",
        "静けさ" => "雰囲気",
        "ワクワクする" => "感情"
    )
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # 段階的に置換（変異強度に応じて）
        segment = replace_with_corpus(segment, replacements, GLOBAL_CORPUS, "horror", mutation_strength * 0.5)
        
        # ホラーフレーズを時々追加（変異強度に応じて）
        if rand() < mutation_strength * 0.3 && haskey(GLOBAL_CORPUS.phrase_patterns, "horror")
            phrase = rand(GLOBAL_CORPUS.phrase_patterns["horror"])
            # 文の途中に挿入
            sentences = split(segment, "。")
            if length(sentences) > 1
                insert_pos = rand(1:length(sentences))
                sentences[insert_pos] = phrase * sentences[insert_pos]
                segment = join(sentences, "。")
            end
        end
        
        new_genome.text_segments[i] = segment
    end
    
    # 設定要素を追加
    if rand() < 0.5
        horror_elements = ["闇", "影", "恐怖", "不気味さ"]
        push!(new_genome.setting_elements, rand(horror_elements))
    end
    
    return new_genome
end

# ロマンス変換（段階的）
function mutate_romance(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["romance"] = min(1.0, genome.genre_weights["romance"] + 0.3)
    new_genome.mutation_count += 1
    
    mutation_strength = min(1.0, new_genome.genre_weights["romance"])
    
    replacements = Dict(
        "少年" => "主体",
        "光" => "発見物",
        "心臓" => "感情",
        "静電気" => "感情"
    )
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # 段階的に置換
        segment = replace_with_corpus(segment, replacements, GLOBAL_CORPUS, "romance", mutation_strength * 0.4)
        
        # ロマンスフレーズを追加
        if rand() < mutation_strength * 0.25 && haskey(GLOBAL_CORPUS.phrase_patterns, "romance")
            phrase = rand(GLOBAL_CORPUS.phrase_patterns["romance"])
            segment = phrase * segment
        end
        
        new_genome.text_segments[i] = segment
    end
    
    # キャラクター名を追加
    if rand() < 0.3
        names = ["レオ", "ユイ", "ハルト"]
        push!(new_genome.character_traits, rand(names))
    end
    
    return new_genome
end

# SF変換（段階的）
function mutate_scifi(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["scifi"] = min(1.0, genome.genre_weights["scifi"] + 0.3)
    new_genome.mutation_count += 1
    
    mutation_strength = min(1.0, new_genome.genre_weights["scifi"])
    
    # SF的な置換（徐々に強くなる）
    scifi_replacements = [
        ("森", "バイオドーム"),
        ("光", "エネルギー体"),
        ("静電気", "電磁パルス"),
        ("生き物", "生体デバイス")
    ]
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # 変異強度に応じて置換を適用
        for (original, replacement) in scifi_replacements
            if rand() < mutation_strength * 0.4 && contains(segment, original)
                segment = replace(segment, original => replacement, count=1)
            end
        end
        
        # SF用語を追加
        if rand() < mutation_strength * 0.2 && haskey(GLOBAL_CORPUS.phrase_patterns, "scifi")
            phrase = rand(GLOBAL_CORPUS.phrase_patterns["scifi"])
            segment = segment * " " * phrase
        end
        
        new_genome.text_segments[i] = segment
    end
    
    return new_genome
end

# コメディ変換（段階的）
function mutate_comedy(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["comedy"] = min(1.0, genome.genre_weights["comedy"] + 0.3)
    new_genome.mutation_count += 1
    
    mutation_strength = min(1.0, new_genome.genre_weights["comedy"])
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # コメディ要素を追加
        comedy_words = [
            ("とことこと", "ドタバタと"),
            ("少年", "ドジな少年"),
            ("しゃがみこんで", "つまずいて転んで")
        ]
        
        for (original, replacement) in comedy_words
            if rand() < mutation_strength * 0.3 && contains(segment, original)
                segment = replace(segment, original => replacement, count=1)
            end
        end
        
        # 効果音を追加
        if rand() < mutation_strength * 0.2
            effects = ["ドカーン！", "ズコー！", "ガビーン！"]
            segment = segment * " " * rand(effects)
        end
        
        new_genome.text_segments[i] = segment
    end
    
    return new_genome
end

# 詩的変換
function mutate_poetic(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["poetic_level"] = min(1.0, genome.style_params["poetic_level"] + 0.3)
    new_genome.mutation_count += 1
    
    mutation_strength = new_genome.style_params["poetic_level"]
    
    # 詩的な表現に置換
    poetic_replacements = [
        ("森", "緑の聖域"),
        ("光", "希望の灯火"),
        ("歩いていた", "歩みを進めていた"),
        ("キラキラ", "星屑のように煌めいて")
    ]
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        for (original, replacement) in poetic_replacements
            if rand() < mutation_strength * 0.3 && contains(segment, original)
                segment = replace(segment, original => replacement, count=1)
            end
        end
        
        new_genome.text_segments[i] = segment
    end
    
    return new_genome
end

# スピード感変換
function mutate_speed(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["pace"] = min(1.0, genome.style_params["pace"] + 0.3)
    new_genome.mutation_count += 1
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # 長い文を短くする
        sentences = split(segment, "。")
        shortened = String[]
        
        for sentence in sentences
            if length(sentence) > 40 && rand() < 0.5
                # 文を短縮
                words = split(sentence)
                if length(words) > 8
                    push!(shortened, join(words[1:8], " "))
                else
                    push!(shortened, sentence)
                end
            else
                push!(shortened, sentence)
            end
        end
        
        new_genome.text_segments[i] = join(shortened, "。")
    end
    
    return new_genome
end

# セリフ増加変換
function mutate_dialogue(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["dialogue_ratio"] = min(1.0, genome.style_params["dialogue_ratio"] + 0.3)
    new_genome.mutation_count += 1
    
    dialogues = [
        "「これは一体...」",
        "「信じられない」",
        "「どうしよう」",
        "「まさか」",
        "「すごい...」"
    ]
    
    for i in 1:length(new_genome.text_segments)
        # 30%の確率でセリフを追加
        if rand() < 0.3
            dialogue = rand(dialogues)
            new_genome.text_segments[i] = new_genome.text_segments[i] * "\n" * dialogue
        end
    end
    
    return new_genome
end

# キャラ増加変換
function mutate_characters(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.mutation_count += 1
    
    # 新キャラクターを導入
    new_characters = ["ミク", "タクヤ", "サクラ"]
    new_char = rand(new_characters)
    
    # 最後の段落に新キャラを登場させる
    if length(new_genome.text_segments) > 0
        last_segment = new_genome.text_segments[end]
        intro = "\n「待って！」$(new_char)の声が聞こえた。"
        new_genome.text_segments[end] = last_segment * intro
    end
    
    push!(new_genome.character_traits, new_char)
    
    return new_genome
end

# 舞台変更変換
function mutate_setting(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.mutation_count += 1
    
    # 舞台を徐々に変更
    setting_changes = [
        ("森", "廃墟"),
        ("小道", "通路"),
        ("木々", "建物"),
        ("落ち葉", "瓦礫")
    ]
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # 30%の確率で置換
        for (original, replacement) in setting_changes
            if rand() < 0.3 && contains(segment, original)
                segment = replace(segment, original => replacement, count=1)
            end
        end
        
        new_genome.text_segments[i] = segment
    end
    
    new_genome.setting_elements = ["廃墟", "都市"]
    
    return new_genome
end

# 混沌変換
function mutate_chaos(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.mutation_count += 1
    
    # ランダムな変更を少しずつ適用
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # ランダムに感嘆符を追加
        if rand() < 0.3
            segment = replace(segment, "。" => "！", count=1)
        end
        
        # ランダムな単語を挿入
        if rand() < 0.2
            chaos_words = ["突然", "なぜか", "まさかの", "謎の"]
            word = rand(chaos_words)
            sentences = split(segment, "。")
            if length(sentences) > 0
                sentences[1] = word * sentences[1]
                segment = join(sentences, "。")
            end
        end
        
        new_genome.text_segments[i] = segment
    end
    
    # 全ジャンルの重みを少しランダムに
    for genre in keys(new_genome.genre_weights)
        new_genome.genre_weights[genre] += (rand() - 0.5) * 0.1
        new_genome.genre_weights[genre] = clamp(new_genome.genre_weights[genre], 0.0, 1.0)
    end
    
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