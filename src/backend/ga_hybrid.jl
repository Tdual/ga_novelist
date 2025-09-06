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

# 舞台要素の定義
mutable struct StageElement
    name::String
    description::String
    atmosphere::String
    transitions::Vector{String}  # 進化可能な舞台
end

# 舞台進化の定義
const STAGE_EVOLUTION = Dict(
    "森" => StageElement("森", "自然豊かな森林", "静寂", ["暗い森", "魔法の森", "廃墟"]),
    "暗い森" => StageElement("暗い森", "不気味な森", "恐怖", ["呪われた森", "廃墟", "洞窟"]),
    "魔法の森" => StageElement("魔法の森", "神秘的な森", "幻想", ["妖精の国", "空中庭園", "水晶洞窟"]),
    "廃墟" => StageElement("廃墟", "朽ち果てた建物", "荒廃", ["地下遺跡", "工場廃墟", "古城"]),
    "洞窟" => StageElement("洞窟", "暗い地下空間", "神秘", ["水晶洞窟", "地下遺跡", "溶岩洞"]),
    "古城" => StageElement("古城", "中世の城", "重厚", ["幽霊城", "空中城", "水中城"]),
    "工場廃墟" => StageElement("工場廃墟", "産業遺跡", "機械的", ["宇宙ステーション", "サイバー空間", "未来都市"]),
    "宇宙ステーション" => StageElement("宇宙ステーション", "宇宙の基地", "SF", ["異星基地", "時空間", "次元の狭間"]),
    "妖精の国" => StageElement("妖精の国", "ファンタジー世界", "幻想", ["雲の上", "夢の世界", "鏡の世界"])
)

# 舞台変更の遺伝的アルゴリズム実装
function mutate_setting(genome::TextGenome)
    # 複数の舞台変更候補を生成（集団）
    population_size = 5
    candidates = []
    
    for _ in 1:population_size
        candidate = deepcopy(genome)
        candidate.mutation_count += 1
        candidate = apply_stage_evolution(candidate)
        push!(candidates, candidate)
    end
    
    # 各候補の適応度を評価
    fitnesses = [evaluate_stage_fitness(candidate, genome) for candidate in candidates]
    
    # トーナメント選択で最良候補を選択
    best_idx = tournament_select_stage(fitnesses)
    selected = candidates[best_idx]
    
    # 選択された候補に交叉と突然変異を適用
    final_genome = apply_stage_crossover_mutation(selected, genome)
    
    return final_genome
end

# 舞台の進化を適用
function apply_stage_evolution(genome::TextGenome)
    new_genome = deepcopy(genome)
    
    # 現在の舞台要素を特定
    current_stages = extract_current_stages(new_genome)
    
    for stage in current_stages
        if haskey(STAGE_EVOLUTION, stage) && rand() < 0.4
            evolution = STAGE_EVOLUTION[stage]
            new_stage = rand(evolution.transitions)
            
            # テキスト内で舞台を進化
            for i in 1:length(new_genome.text_segments)
                segment = new_genome.text_segments[i]
                if contains(segment, stage)
                    # 進化した舞台に置換
                    segment = replace(segment, stage => new_stage, count=1)
                    # 雰囲気に応じた修飾を追加
                    if haskey(STAGE_EVOLUTION, new_stage)
                        new_evolution = STAGE_EVOLUTION[new_stage]
                        if new_evolution.atmosphere == "恐怖"
                            segment = add_horror_atmosphere(segment)
                        elseif new_evolution.atmosphere == "幻想"
                            segment = add_fantasy_atmosphere(segment)
                        elseif new_evolution.atmosphere == "SF"
                            segment = add_scifi_atmosphere(segment)
                        end
                    end
                    new_genome.text_segments[i] = segment
                end
            end
            
            # 設定要素を更新
            if new_stage ∉ new_genome.setting_elements
                push!(new_genome.setting_elements, new_stage)
            end
        end
    end
    
    return new_genome
end

# 現在のテキストから舞台要素を抽出
function extract_current_stages(genome::TextGenome)
    stages = []
    full_text = join(genome.text_segments, " ")
    
    for stage_name in keys(STAGE_EVOLUTION)
        if contains(full_text, stage_name)
            push!(stages, stage_name)
        end
    end
    
    # デフォルト舞台
    if isempty(stages)
        push!(stages, "森")
    end
    
    return unique(stages)
end

# 舞台変更の適応度評価
function evaluate_stage_fitness(candidate::TextGenome, original::TextGenome)
    fitness = 0.0
    
    # 舞台の多様性を評価
    stage_count = length(candidate.setting_elements)
    fitness += stage_count * 0.3
    
    # テキストの変化度を評価
    original_text = join(original.text_segments, " ")
    candidate_text = join(candidate.text_segments, " ")
    
    # 文字レベルでの差異
    diff_ratio = 1.0 - (length(intersect(original_text, candidate_text)) / max(length(original_text), length(candidate_text)))
    fitness += diff_ratio * 0.5
    
    # 舞台の雰囲気統一性を評価
    atmospheres = []
    for element in candidate.setting_elements
        if haskey(STAGE_EVOLUTION, element)
            push!(atmospheres, STAGE_EVOLUTION[element].atmosphere)
        end
    end
    
    # 統一感があるほど高い適応度
    if length(unique(atmospheres)) <= 2
        fitness += 0.2
    end
    
    return fitness
end

# トーナメント選択
function tournament_select_stage(fitnesses::Vector{Float64}, tournament_size::Int=3)
    candidates = rand(1:length(fitnesses), tournament_size)
    tournament_fitnesses = [fitnesses[i] for i in candidates]
    best_local_idx = argmax(tournament_fitnesses)
    return candidates[best_local_idx]
end

# 舞台要素の交叉と突然変異
function apply_stage_crossover_mutation(selected::TextGenome, original::TextGenome)
    result = deepcopy(selected)
    
    # 交叉: 元のゲノムの設定要素の一部を継承
    if rand() < 0.3
        inherited_elements = rand(original.setting_elements, min(2, length(original.setting_elements)))
        for element in inherited_elements
            if element ∉ result.setting_elements
                push!(result.setting_elements, element)
            end
        end
    end
    
    # 突然変異: 新しい舞台要素をランダム追加
    if rand() < 0.2
        all_stages = collect(keys(STAGE_EVOLUTION))
        new_stage = rand(all_stages)
        if new_stage ∉ result.setting_elements
            push!(result.setting_elements, new_stage)
        end
    end
    
    return result
end

# 雰囲気修飾の追加関数
function add_horror_atmosphere(text::String)
    horror_modifiers = ["不気味な", "薄暗い", "ざわめく", "冷たい風が吹く"]
    modifier = rand(horror_modifiers)
    return modifier * text
end

function add_fantasy_atmosphere(text::String)
    fantasy_modifiers = ["輝く", "神秘的な", "魔法に満ちた", "幻想的な"]
    modifier = rand(fantasy_modifiers)
    return modifier * text
end

function add_scifi_atmosphere(text::String)
    scifi_modifiers = ["メタリックな", "電子的な", "未来的な", "人工的な"]
    modifier = rand(scifi_modifiers)
    return modifier * text
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