using Random

function render_text(genome::Genome)
    base_text = generate_base_narrative(genome)
    styled_text = apply_style(base_text, genome.style_params)
    return styled_text
end

function generate_base_narrative(genome::Genome)
    elements = String[]
    
    dominant_genre = get_dominant_genre(genome.genre_weights)
    
    if dominant_genre == "horror"
        push!(elements, generate_horror_element(genome))
    elseif dominant_genre == "romance"
        push!(elements, generate_romance_element(genome))
    elseif dominant_genre == "scifi"
        push!(elements, generate_scifi_element(genome))
    elseif dominant_genre == "comedy"
        push!(elements, generate_comedy_element(genome))
    else
        push!(elements, generate_mystery_element(genome))
    end
    
    if !isempty(genome.setting_elements)
        setting = rand(genome.setting_elements)
        push!(elements, "場所は$(translate_setting(setting))へと移った。")
    end
    
    if !isempty(genome.character_traits)
        trait = rand(genome.character_traits)
        push!(elements, "$(translate_trait(trait))な人物が現れた。")
    end
    
    return join(elements, " ")
end

function get_dominant_genre(weights::Dict{String, Float64})
    max_weight = 0.0
    dominant = "mystery"
    for (genre, weight) in weights
        if weight > max_weight
            max_weight = weight
            dominant = genre
        end
    end
    return dominant
end

function generate_horror_element(genome::Genome)
    elements = [
        "闇が深まり、不気味な気配が漂い始めた。",
        "冷たい風が吹き抜け、何かが囁いているようだった。",
        "影が蠢き、恐怖が心を支配し始めた。",
        "静寂の中、不吉な予感が募っていく。"
    ]
    return rand(elements)
end

function generate_romance_element(genome::Genome)
    elements = [
        "二人の視線が交わり、時が止まったようだった。",
        "心が震え、言葉にできない感情が溢れ出した。",
        "運命的な出会いが、物語を新たな方向へ導いた。",
        "優しい微笑みが、すべてを変えていく。"
    ]
    return rand(elements)
end

function generate_scifi_element(genome::Genome)
    elements = [
        "異次元への扉が開き、未知の世界が広がった。",
        "テクノロジーが現実を超越し始めた。",
        "時空の歪みが、新たな可能性を示していた。",
        "人工知能が、予期せぬ答えを導き出した。"
    ]
    return rand(elements)
end

function generate_comedy_element(genome::Genome)
    elements = [
        "思わぬハプニングが、笑いを誘った。",
        "ドタバタとした展開に、皆が巻き込まれていく。",
        "予想外の出来事が、場を和ませた。",
        "コミカルな仕草が、緊張を解きほぐした。"
    ]
    return rand(elements)
end

function generate_mystery_element(genome::Genome)
    elements = [
        "謎が深まり、真実への道は霧に包まれていた。",
        "手がかりが現れ、パズルのピースが揃い始めた。",
        "隠された秘密が、徐々に明らかになっていく。",
        "疑問が疑問を呼び、迷宮は深まるばかりだった。"
    ]
    return rand(elements)
end

function translate_setting(setting::String)
    translations = Dict(
        "forest" => "森",
        "light" => "光のある場所",
        "darkness" => "闇",
        "castle" => "城",
        "ocean" => "海",
        "city" => "都市",
        "mountain" => "山",
        "space" => "宇宙",
        "underground" => "地下",
        "shadow" => "影",
        "whisper" => "囁きの聞こえる場所",
        "cold" => "寒い場所",
        "fear" => "恐怖の場所",
        "technology" => "技術施設",
        "portal" => "ポータル",
        "dimension" => "異次元",
        "alien" => "異星"
    )
    return get(translations, setting, setting)
end

function translate_trait(trait::String)
    translations = Dict(
        "curious" => "好奇心旺盛",
        "brave" => "勇敢",
        "gentle" => "優しい",
        "passionate" => "情熱的",
        "mysterious" => "神秘的",
        "clumsy" => "ドジ",
        "witty" => "機知に富んだ",
        "cheerful" => "陽気",
        "wise" => "賢明",
        "young" => "若い",
        "old" => "年老いた",
        "strong" => "強い",
        "magical" => "魔法の力を持つ",
        "ordinary" => "普通の"
    )
    return get(translations, trait, trait)
end

function apply_style(text::String, style_params::Dict{String, Float64})
    if style_params["dialogue_ratio"] > 0.6
        text = add_dialogue(text)
    end
    
    if style_params["poetic_level"] > 0.6
        text = make_poetic(text)
    end
    
    if style_params["description_density"] > 0.7
        text = add_description(text)
    end
    
    if style_params["pace"] > 0.7
        text = increase_pace(text)
    end
    
    return text
end

function add_dialogue(text::String)
    dialogues = [
        "「これは一体...」と誰かが呟いた。",
        "「待って、何か聞こえる」",
        "「大丈夫、きっとうまくいく」",
        "「信じられない...」"
    ]
    return text * " " * rand(dialogues)
end

function make_poetic(text::String)
    poetic_additions = [
        "まるで夢と現実の境界が溶けていくように。",
        "言葉にできない美しさが、そこにはあった。",
        "時は流れ、永遠は一瞬に宿る。",
        "静寂が歌い、闇が踊る。"
    ]
    return text * " " * rand(poetic_additions)
end

function add_description(text::String)
    descriptions = [
        "空気は重く、湿気を帯びていた。",
        "遠くで何かが動く音がした。",
        "光と影が複雑な模様を描いていた。",
        "風景は息を呑むほど美しかった。"
    ]
    return text * " " * rand(descriptions)
end

function increase_pace(text::String)
    pace_additions = [
        "突然！",
        "次の瞬間、",
        "あっという間に、",
        "息つく暇もなく、"
    ]
    return rand(pace_additions) * " " * text
end