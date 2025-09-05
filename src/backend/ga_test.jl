using Random

# 文章の遺伝子表現
mutable struct TextGenome
    genre_weights::Dict{String, Float64}
    style_params::Dict{String, Float64}
    character_traits::Vector{String}
    setting_elements::Vector{String}
    text_segments::Vector{String}  # 文章を分割して保持
end

# サンプル文章を分割して初期遺伝子を作成
function create_initial_genome()
    sample_text = """
    森の中の小道を、少年はとことこと歩いていた。昼間のはずなのに、頭の上の木々が光をさえぎっていて、足元はほとんど夕方みたいに暗い。鳥の声も聞こえないし、風も止んでいる。さっきまで普通に賑やかだったのに、この場所だけぽっかり切り取られたような静けさに包まれていた。
    
    そんなとき、少年は足元に小さな光を見つけた。落ち葉の隙間から、ビー玉くらいの大きさで、青白くチカチカしている。最初はガラス片かと思ったけれど、どうやら違う。光は呼吸みたいにふくらんだり縮んだりして、まるで生き物みたいに動いていた。
    
    「なんだこれ？」
    少年はしゃがみこんで、手で落ち葉を払いのけた。すると、丸い透明な殻の中に小さな粒が浮かんでいて、星を閉じ込めたようにキラキラしていた。思わず触れてみたくなって、そっと指先でつついてみる。殻は意外にもひんやり冷たくて、ビリッと静電気のような刺激が走った。
    
    その瞬間、森がざわっと揺れたような気がした。枝葉が一斉に震え、どこか遠くで木のきしむ音が響いた。光の玉は少年の手の中で震えながら、じわじわ形を変えていく。丸かったはずなのに、少しだけ尖ったり、なめらかに伸びたり。少年の手に合わせてフィットしようとしているみたいだ。
    
    心臓がドクンと大きく鳴った。怖いような、でもワクワクするような、複雑な気持ちが押し寄せてくる。手を離すべきか、それとももっと確かめるべきか。頭の中では警鐘が鳴っているのに、体は逆に光を手のひらで包み込んでしまっていた。
    
    「これは……いったいなんだろう。」
    声に出してみると、答えるように光がひときわ強く瞬いた。
    """
    
    # 段落ごとに分割
    segments = split(strip(sample_text), "\n\n")
    
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
        [String(s) for s in segments]
    )
end

# ホラー変換
function mutate_horror(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["horror"] = min(1.0, genome.genre_weights["horror"] + 0.3 + rand() * 0.2)
    
    # ランダムな変換パターンを定義
    horror_patterns = Dict(
        "小道" => ["不気味な小道", "呪われた小道", "血に染まった小道", "亡霊が彷徨う小道"],
        "静けさ" => ["死んだような静けさ", "墓場のような静けさ", "不吉な静寂", "凍りつくような静けさ"],
        "光" => ["不吉な光", "死者の光", "呪いの光", "魂を吸い取る光", "地獄の光"],
        "青白く" => ["死者の魂のように青白く", "幽霊のように青白く", "病的に青白く", "骸骨のように青白く"],
        "生き物みたい" => ["悪意を持った生き物みたい", "化け物みたい", "悪魔みたい", "怨霊みたい"],
        "ワクワクする" => ["背筋が凍る", "恐怖で震える", "血の気が引く", "悪寒が走る"],
        "答えるように" => ["脅すように", "呪うように", "嘲笑うように", "警告するように"]
    )
    
    # ランダムな追加描写
    horror_additions = [
        "何か見えない存在が近づいてくる気配がした。",
        "どこからか低い唸り声が聞こえてきた。",
        "冷たい手が肩に触れたような感覚があった。",
        "腐敗臭が漂ってきた。",
        "影が不自然に蠢いているのが見えた。"
    ]
    
    # 文章の変換
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # ランダムにホラー要素を適用
        for (key, values) in horror_patterns
            if contains(segment, key)
                segment = replace(segment, key => rand(values))
            end
        end
        
        # ランダムに追加描写を挿入（30%の確率）
        if rand() < 0.3 && length(segment) > 50
            segment = segment * " " * rand(horror_additions)
        end
        
        new_genome.text_segments[i] = segment
    end
    
    # ランダムな要素を追加
    horror_elements = ["闇", "影", "恐怖", "悪夢", "亡霊", "呪い", "血", "叫び声"]
    for _ in 1:rand(1:3)
        elem = rand(horror_elements)
        if !(elem in new_genome.setting_elements)
            push!(new_genome.setting_elements, elem)
        end
    end
    
    return new_genome
end

# ロマンス変換
function mutate_romance(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["romance"] = min(1.0, genome.genre_weights["romance"] + 0.3 + rand() * 0.2)
    
    # ランダムな名前
    names = ["レオ", "アキラ", "ユウト", "ハルト", "ソウタ"]
    chosen_name = rand(names)
    
    # ランダムな変換パターン
    romance_patterns = Dict(
        "少年" => ["少年の$(chosen_name)", chosen_name, "若き$(chosen_name)"],
        "光" => ["運命の光", "愛の光", "奇跡の光", "希望の光", "永遠の光"],
        "青白く" => ["優しく温かく", "愛おしく", "柔らかく", "甘く", "優美に"],
        "静電気のような刺激" => ["恋に落ちたような感覚", "運命を感じる衝撃", "心が震える感覚", "初恋のような衝動"],
        "心臓" => ["恋する心臓", "高鳴る心臓", "ときめく心臓", "愛に震える心臓"],
        "森" => ["運命の森", "愛の森", "奇跡の森", "約束の森"]
    )
    
    # ロマンチックな追加セリフ
    romantic_dialogues = [
        "「まるで、誰かが僕を待っていたみたいだ。」",
        "「この光は...きっと運命なんだ。」",
        "「心が、何かを伝えようとしている。」",
        "「これは愛の始まりかもしれない。」",
        "「誰かの温もりを感じる。」"
    ]
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # ランダムにロマンス要素を適用
        for (key, values) in romance_patterns
            if contains(segment, key)
                segment = replace(segment, key => rand(values), count=1)
            end
        end
        
        # ランダムにロマンチックなセリフを追加（25%の確率）
        if rand() < 0.25 && contains(segment, "？」)
            segment = segment * "\n" * rand(romantic_dialogues)
        end
        
        new_genome.text_segments[i] = segment
    end
    
    # キャラクター特性をランダムに追加
    traits = ["優しい", "情熱的", "ミステリアス", "純粋", "一途"]
    push!(new_genome.character_traits, chosen_name, rand(traits))
    
    return new_genome
end
        end
        
        new_genome.text_segments[i] = segment
    end
    
    push!(new_genome.character_traits, "レオ", "運命の相手")
    
    return new_genome
end

# SF変換
function mutate_scifi(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["scifi"] = min(1.0, genome.genre_weights["scifi"] + 0.4)
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        segment = replace(segment, "森" => "人工森林バイオドーム")
        segment = replace(segment, "光" => "異次元エネルギー体")
        segment = replace(segment, "青白く" => "量子的に振動しながら青白く")
        segment = replace(segment, "透明な殻" => "ナノマテリアルの殻")
        segment = replace(segment, "静電気" => "電磁パルス")
        segment = replace(segment, "生き物みたい" => "AI制御された生体デバイスみたい")
        
        if contains(segment, "いったいなんだろう")
            segment = replace(segment, "いったいなんだろう" => "いったいなんだろう。地球外の技術か？")
        end
        
        new_genome.text_segments[i] = segment
    end
    
    push!(new_genome.setting_elements, "テクノロジー", "異次元", "未来")
    
    return new_genome
end

# コメディ変換
function mutate_comedy(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.genre_weights["comedy"] = min(1.0, genome.genre_weights["comedy"] + 0.4)
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        segment = replace(segment, "とことこと" => "ドタバタと")
        segment = replace(segment, "少年" => "ドジな少年")
        segment = replace(segment, "しゃがみこんで" => "派手に転んでから慌ててしゃがみこんで")
        segment = replace(segment, "ビー玉くらい" => "タピオカくらい")
        
        if contains(segment, "なんだこれ？")
            segment = replace(segment, "なんだこれ？" => "なんだこれ？食べられるのかな？")
        end
        
        if contains(segment, "静電気")
            segment = segment * "\n「いたっ！」少年は大げさに飛び上がった。"
        end
        
        new_genome.text_segments[i] = segment
    end
    
    return new_genome
end

# 詩的変換
function mutate_poetic(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["poetic_level"] = min(1.0, genome.style_params["poetic_level"] + 0.4)
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        segment = replace(segment, "森の中の小道" => "緑の迷宮、永遠に続く小道")
        segment = replace(segment, "光をさえぎって" => "光を飲み込んで")
        segment = replace(segment, "静けさに包まれていた" => "静寂という名の繭に包まれていた")
        segment = replace(segment, "呼吸みたいに" => "命の鼓動のように")
        segment = replace(segment, "キラキラ" => "千の星が瞬くように煌めいて")
        
        new_genome.text_segments[i] = segment
    end
    
    return new_genome
end

# スピード感変換
function mutate_speed(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["pace"] = min(1.0, genome.style_params["pace"] + 0.4)
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # 文を短く
        segment = replace(segment, "昼間のはずなのに、頭の上の木々が光をさえぎっていて、足元はほとんど夕方みたいに暗い。" => "昼間なのに暗い。木々が光を遮る。")
        segment = replace(segment, "さっきまで普通に賑やかだったのに、この場所だけぽっかり切り取られたような静けさに包まれていた。" => "急に静かになった。不自然な静寂。")
        segment = replace(segment, "思わず触れてみたくなって、そっと指先でつついてみる。" => "触った。")
        
        new_genome.text_segments[i] = segment
    end
    
    return new_genome
end

# セリフ増加変換
function mutate_dialogue(genome::TextGenome)
    new_genome = deepcopy(genome)
    new_genome.style_params["dialogue_ratio"] = min(1.0, genome.style_params["dialogue_ratio"] + 0.4)
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        if contains(segment, "森の中")
            segment = "「こんな暗い森、初めてだ」\n" * segment
        end
        
        if contains(segment, "鳥の声も聞こえない")
            segment = segment * "\n「おかしいな、さっきまで鳥がいたのに」"
        end
        
        if contains(segment, "光の玉は")
            segment = segment * "\n「まるで生きているみたいだ」と少年はつぶやいた。"
        end
        
        new_genome.text_segments[i] = segment
    end
    
    return new_genome
end

# キャラ増加変換
function mutate_characters(genome::TextGenome)
    new_genome = deepcopy(genome)
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        segment = replace(segment, "少年" => "タクミ")
        
        if contains(segment, "心臓がドクン")
            segment = segment * "\n\n「タクミ！」遠くから幼馴染のユイの声が聞こえた。「そこで何してるの？」"
        end
        
        new_genome.text_segments[i] = segment
    end
    
    push!(new_genome.character_traits, "タクミ", "ユイ")
    
    return new_genome
end

# 舞台変更変換
function mutate_setting(genome::TextGenome)
    new_genome = deepcopy(genome)
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        segment = replace(segment, "森の中の小道" => "廃墟と化した都市の路地")
        segment = replace(segment, "木々" => "崩れかけたビル")
        segment = replace(segment, "落ち葉" => "瓦礫")
        segment = replace(segment, "枝葉" => "建物の残骸")
        
        new_genome.text_segments[i] = segment
    end
    
    new_genome.setting_elements = ["廃墟", "都市", "瓦礫"]
    
    return new_genome
end

# 混沌変換
function mutate_chaos(genome::TextGenome)
    new_genome = deepcopy(genome)
    
    for i in 1:length(new_genome.text_segments)
        segment = new_genome.text_segments[i]
        
        # ランダムな文体変更
        if rand() > 0.5
            segment = replace(segment, "。" => "！" , count=1)
        end
        
        # 突然の視点変更
        if contains(segment, "少年は")
            if rand() > 0.6
                segment = segment * "\n\n突然、私は少年ではなくなった。いや、最初から少年だったのか？"
            end
        end
        
        # ランダムな要素挿入
        if rand() > 0.7
            chaos_elements = ["時間が歪んだ。", "現実が溶けた。", "誰かが笑った。", "世界が反転した。"]
            segment = segment * "\n" * rand(chaos_elements)
        end
        
        new_genome.text_segments[i] = segment
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

# テスト実行
function test_mutations()
    println("=== 遺伝的アルゴリズムによる文章変換テスト ===\n")
    
    # 初期遺伝子を作成
    initial_genome = create_initial_genome()
    println("【オリジナル】")
    println(render_text(initial_genome))
    println("\n" * "="^50 * "\n")
    
    # 各変換をテスト
    operators = [
        "もっとホラー",
        "もっとロマンス",
        "もっとSF",
        "もっとコメディ",
        "もっと詩的に",
        "もっとスピード感",
        "もっとセリフを",
        "もっとキャラを増やす",
        "もっと舞台を変える",
        "もっと混沌"
    ]
    
    for operator in operators
        println("【$operator】")
        mutated_genome = apply_mutation(initial_genome, operator)
        println(render_text(mutated_genome))
        println("\n" * "="^50 * "\n")
    end
    
    # 複数の変換を連続適用
    println("【複合変換: ホラー → SF → スピード感】")
    genome = initial_genome
    genome = apply_mutation(genome, "もっとホラー")
    genome = apply_mutation(genome, "もっとSF")
    genome = apply_mutation(genome, "もっとスピード感")
    println(render_text(genome))
end

# テスト実行
test_mutations()