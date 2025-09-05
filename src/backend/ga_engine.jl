using Evolutionary
using Random

struct Genome
    genre_weights::Dict{String, Float64}
    style_params::Dict{String, Float64}
    character_traits::Vector{String}
    setting_elements::Vector{String}
end

function initialize_genome()
    return Genome(
        Dict(
            "horror" => 0.2,
            "romance" => 0.2,
            "scifi" => 0.2,
            "comedy" => 0.2,
            "mystery" => 0.2
        ),
        Dict(
            "dialogue_ratio" => 0.3,
            "description_density" => 0.5,
            "pace" => 0.5,
            "poetic_level" => 0.3,
            "complexity" => 0.5
        ),
        ["curious", "brave"],
        ["forest", "light", "darkness"]
    )
end

const MUTATION_OPERATORS = Dict(
    "もっとホラー" => function(g::Genome)
        g_new = deepcopy(g)
        g_new.genre_weights["horror"] = min(1.0, g.genre_weights["horror"] + 0.3)
        g_new.style_params["description_density"] = min(1.0, g.style_params["description_density"] + 0.2)
        push!(g_new.setting_elements, rand(["shadow", "whisper", "cold", "fear"]))
        return g_new
    end,
    
    "もっとロマンス" => function(g::Genome)
        g_new = deepcopy(g)
        g_new.genre_weights["romance"] = min(1.0, g.genre_weights["romance"] + 0.3)
        g_new.style_params["dialogue_ratio"] = min(1.0, g.style_params["dialogue_ratio"] + 0.2)
        push!(g_new.character_traits, rand(["gentle", "passionate", "mysterious"]))
        return g_new
    end,
    
    "もっとSF" => function(g::Genome)
        g_new = deepcopy(g)
        g_new.genre_weights["scifi"] = min(1.0, g.genre_weights["scifi"] + 0.3)
        g_new.style_params["complexity"] = min(1.0, g.style_params["complexity"] + 0.2)
        push!(g_new.setting_elements, rand(["technology", "portal", "dimension", "alien"]))
        return g_new
    end,
    
    "もっとコメディ" => function(g::Genome)
        g_new = deepcopy(g)
        g_new.genre_weights["comedy"] = min(1.0, g.genre_weights["comedy"] + 0.3)
        g_new.style_params["pace"] = min(1.0, g.style_params["pace"] + 0.2)
        push!(g_new.character_traits, rand(["clumsy", "witty", "cheerful"]))
        return g_new
    end,
    
    "もっと詩的に" => function(g::Genome)
        g_new = deepcopy(g)
        g_new.style_params["poetic_level"] = min(1.0, g.style_params["poetic_level"] + 0.3)
        g_new.style_params["description_density"] = min(1.0, g.style_params["description_density"] + 0.2)
        return g_new
    end,
    
    "もっとセリフを" => function(g::Genome)
        g_new = deepcopy(g)
        g_new.style_params["dialogue_ratio"] = min(1.0, g.style_params["dialogue_ratio"] + 0.3)
        return g_new
    end,
    
    "もっと舞台を変える" => function(g::Genome)
        g_new = deepcopy(g)
        new_settings = ["castle", "ocean", "city", "mountain", "space", "underground"]
        push!(g_new.setting_elements, rand(new_settings))
        return g_new
    end,
    
    "もっとキャラを増やす" => function(g::Genome)
        g_new = deepcopy(g)
        new_traits = ["wise", "young", "old", "strong", "magical", "ordinary"]
        push!(g_new.character_traits, rand(new_traits))
        return g_new
    end,
    
    "もっと混沌" => function(g::Genome)
        g_new = deepcopy(g)
        for key in keys(g_new.genre_weights)
            g_new.genre_weights[key] = 0.2 + rand() * 0.3
        end
        g_new.style_params["complexity"] = min(1.0, g.style_params["complexity"] + 0.3)
        return g_new
    end,
    
    "もっとスピード感を" => function(g::Genome)
        g_new = deepcopy(g)
        g_new.style_params["pace"] = min(1.0, g.style_params["pace"] + 0.3)
        g_new.style_params["dialogue_ratio"] = min(1.0, g.style_params["dialogue_ratio"] + 0.2)
        return g_new
    end
)

function apply_mutation(genome::Genome, operator::String)
    if haskey(MUTATION_OPERATORS, operator)
        return MUTATION_OPERATORS[operator](genome)
    else
        return genome
    end
end