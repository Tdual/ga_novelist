using Random

# コーパス構造体
struct TextCorpus
    # 単語レベルのコーパス
    word_slots::Dict{String, Dict{String, Vector{String}}}
    
    # 文テンプレート
    sentence_templates::Dict{String, Vector{String}}
    
    # フレーズパターン
    phrase_patterns::Dict{String, Vector{String}}
    
    # 文体変換マトリクス
    style_matrix::Dict{String, Dict{String, String}}
end

# コーパスの初期化
function initialize_corpus()
    # 単語スロット（ジャンル別）
    word_slots = Dict(
        "neutral" => Dict(
            "主体" => ["少年", "青年", "旅人", "子供", "若者", "少女", "冒険者"],
            "場所" => ["森", "小道", "広場", "丘", "谷間", "草原", "岩場"],
            "発見物" => ["光", "石", "花", "実", "羽根", "結晶", "雫"],
            "動作" => ["歩く", "進む", "立ち止まる", "振り返る", "見つめる", "触れる", "拾う"],
            "感情" => ["驚き", "好奇心", "不安", "期待", "興奮", "戸惑い", "安堵"],
            "時間" => ["朝", "昼", "夕方", "黄昏時", "日暮れ", "薄暮", "黎明"],
            "天候" => ["晴れ", "曇り", "霧", "風", "静寂", "薄日", "陽射し"]
        ),
        
        "horror" => Dict(
            "主体" => ["怯えた少年", "震える子供", "蒼白な若者", "恐怖に凍る旅人"],
            "場所" => ["暗い森", "不気味な小道", "呪われた場所", "死の谷", "亡霊の森", "血塗られた地"],
            "発見物" => ["不吉な光", "呪いの石", "血の痕", "骸骨", "悪霊の影", "死者の遺品"],
            "動作" => ["逃げる", "震える", "凍りつく", "叫ぶ", "怯える", "後ずさる"],
            "感情" => ["恐怖", "絶望", "恐慌", "戦慄", "悪寒", "狂気"],
            "雰囲気" => ["不気味な", "呪われた", "恐ろしい", "邪悪な", "不吉な", "死の"],
            "音" => ["悲鳴", "呻き声", "囁き", "叫び", "泣き声", "軋み"]
        ),
        
        "romance" => Dict(
            "主体" => ["優しい青年", "美しい少女", "恋する若者", "運命の人"],
            "場所" => ["美しい森", "ロマンチックな小道", "愛の園", "約束の場所", "思い出の地"],
            "発見物" => ["運命の光", "愛の証", "約束の花", "奇跡の石", "永遠の結晶"],
            "動作" => ["見つめる", "微笑む", "触れる", "抱きしめる", "囁く", "寄り添う"],
            "感情" => ["愛", "憧れ", "ときめき", "切なさ", "幸福", "恋心"],
            "形容" => ["美しい", "優しい", "温かい", "甘い", "永遠の", "運命の"]
        ),
        
        "scifi" => Dict(
            "主体" => ["探査員", "科学者", "アンドロイド", "時空旅行者", "データ収集体"],
            "場所" => ["人工森林", "バイオドーム", "実験場", "異次元空間", "量子フィールド"],
            "発見物" => ["エネルギー体", "未知の物質", "データクリスタル", "量子コア", "AIノード"],
            "動作" => ["スキャン", "分析", "データ収集", "転送", "同期", "演算"],
            "技術" => ["量子", "ナノ", "バイオ", "ニューラル", "ホログラム", "プラズマ"],
            "現象" => ["時空歪曲", "次元断裂", "量子もつれ", "特異点", "波動干渉"]
        ),
        
        "comedy" => Dict(
            "主体" => ["ドジな少年", "おっちょこちょいな子", "天然ボケの青年", "お調子者"],
            "場所" => ["ヘンテコな森", "おかしな小道", "不思議な広場", "変な場所"],
            "発見物" => ["変な光", "謎の物体", "妙なもの", "ヘンな石", "おかしなやつ"],
            "動作" => ["転ぶ", "ずっこける", "慌てる", "びっくりする", "ドタバタする"],
            "効果音" => ["ドカーン", "ズコー", "ガビーン", "ぎゃー", "わー"],
            "形容" => ["おかしな", "変な", "妙な", "ヘンテコな", "奇妙な"]
        )
    )
    
    # 文テンプレート（スロットを埋める形式）
    sentence_templates = Dict(
        "発見" => [
            "{主体}は{場所}で{発見物}を見つけた。",
            "{時間}、{主体}が{場所}を{動作}していると、{発見物}が目に入った。",
            "ふと見ると、{発見物}が{場所}に落ちていた。",
            "{主体}の前に、突然{発見物}が現れた。"
        ],
        
        "感情" => [
            "{主体}は{感情}を感じた。",
            "{感情}が{主体}の心を支配した。",
            "それは{形容}もので、{主体}は{感情}に包まれた。",
            "{主体}の心に{感情}が湧き上がった。"
        ],
        
        "行動" => [
            "{主体}は{動作}した。",
            "思わず{主体}は{動作}してしまった。",
            "{主体}はゆっくりと{動作}した。",
            "恐る恐る{主体}は{動作}した。"
        ],
        
        "描写" => [
            "{場所}は{雰囲気}雰囲気に包まれていた。",
            "{時間}の{場所}は{形容}。",
            "辺りは{雰囲気}空気が漂っていた。",
            "{天候}の中、{場所}は静まり返っていた。"
        ]
    )
    
    # フレーズパターン（文の一部として挿入）
    phrase_patterns = Dict(
        "horror" => [
            "背筋が凍るような",
            "血も凍る",
            "悪寒が走る",
            "闇に潜む何かが",
            "死の気配を感じながら"
        ],
        
        "romance" => [
            "心がときめく",
            "運命を感じる",
            "愛おしさが込み上げる",
            "永遠を約束するような",
            "二人だけの世界で"
        ],
        
        "scifi" => [
            "量子レベルで",
            "ナノ秒の間に",
            "データストリームを通じて",
            "異次元からの",
            "未知のエネルギーが"
        ],
        
        "comedy" => [
            "なぜかわからないけど",
            "どういうわけか",
            "まさかの展開で",
            "予想外に",
            "ありえないことに"
        ]
    )
    
    # 文体変換マトリクス
    style_matrix = Dict(
        "formal" => Dict(
            "言う" => "申し上げる",
            "見る" => "拝見する",
            "行く" => "参る",
            "来る" => "いらっしゃる",
            "する" => "いたす"
        ),
        
        "casual" => Dict(
            "言う" => "話す",
            "見る" => "見てる",
            "行く" => "行っちゃう",
            "来る" => "来ちゃう",
            "する" => "やる"
        ),
        
        "poetic" => Dict(
            "歩く" => "歩みを進める",
            "見る" => "瞳に映す",
            "光る" => "煌めく",
            "動く" => "揺らめく",
            "感じる" => "心に宿す"
        )
    )
    
    return TextCorpus(word_slots, sentence_templates, phrase_patterns, style_matrix)
end

# スロットを埋めて文を生成
function fill_template(template::String, corpus::TextCorpus, genre::String="neutral")
    filled = template
    
    # {スロット名}を見つけて置換
    slot_pattern = r"\{([^}]+)\}"
    
    while occursin(slot_pattern, filled)
        m = match(slot_pattern, filled)
        slot_name = m.captures[1]
        
        # まずジャンル固有の単語を探す
        words = nothing
        if haskey(corpus.word_slots, genre) && haskey(corpus.word_slots[genre], slot_name)
            words = corpus.word_slots[genre][slot_name]
        end
        
        # なければneutralから探す
        if words === nothing && haskey(corpus.word_slots["neutral"], slot_name)
            words = corpus.word_slots["neutral"][slot_name]
        end
        
        # 全ジャンルから探す（形容や雰囲気など）
        if words === nothing
            for (g, slots) in corpus.word_slots
                if haskey(slots, slot_name)
                    words = slots[slot_name]
                    break
                end
            end
        end
        
        if words !== nothing
            replacement = rand(words)
            filled = replace(filled, "{$slot_name}" => replacement, count=1)
        else
            # スロットが見つからない場合は空文字に
            filled = replace(filled, "{$slot_name}" => "", count=1)
        end
    end
    
    return filled
end

# ジャンルに応じた文を生成
function generate_sentence(corpus::TextCorpus, genre::String, sentence_type::String="発見")
    templates = get(corpus.sentence_templates, sentence_type, corpus.sentence_templates["発見"])
    template = rand(templates)
    
    return fill_template(template, corpus, genre)
end

# 段落を生成（複数の文を組み合わせ）
function generate_paragraph(corpus::TextCorpus, genre::String, num_sentences::Int=3)
    sentences = String[]
    sentence_types = ["発見", "感情", "行動", "描写"]
    
    for i in 1:num_sentences
        sentence_type = rand(sentence_types)
        sentence = generate_sentence(corpus, genre, sentence_type)
        
        # ジャンル固有のフレーズを時々挿入（30%の確率）
        if rand() < 0.3 && haskey(corpus.phrase_patterns, genre)
            phrase = rand(corpus.phrase_patterns[genre])
            sentence = phrase * sentence
        end
        
        push!(sentences, sentence)
    end
    
    return join(sentences, "")
end

# 文体を変換
function apply_style(text::String, corpus::TextCorpus, style::String)
    if !haskey(corpus.style_matrix, style)
        return text
    end
    
    result = text
    for (original, replacement) in corpus.style_matrix[style]
        result = replace(result, original => replacement)
    end
    
    return result
end