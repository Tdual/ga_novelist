using Random
using Statistics
include("ga_hybrid.jl")

# 集団（Population）の定義
mutable struct Population
    individuals::Vector{TextGenome}
    generation::Int
    population_size::Int
    mutation_operator::String
end

# 集団の初期化
function create_population(size::Int=5, operator::String="もっとホラー")
    individuals = [create_initial_genome() for _ in 1:size]
    return Population(individuals, 0, size, operator)
end

# 適応度の計算（目標ジャンルへの近さ）
function calculate_fitness(genome::TextGenome, target_genre::String)
    # 目標ジャンルの重みが高いほど適応度が高い
    base_fitness = get(genome.genre_weights, target_genre, 0.0)
    
    # 変異回数も考慮（進化が進んでいる個体を優遇）
    evolution_bonus = genome.mutation_count * 0.05
    
    # 多様性ボーナス（設定要素やキャラクターが多いほど高い）
    diversity_bonus = (length(genome.setting_elements) + length(genome.character_traits)) * 0.02
    
    return base_fitness + evolution_bonus + diversity_bonus
end

# トーナメント選択
function tournament_selection(population::Population, target_genre::String, tournament_size::Int=3)
    candidates = rand(population.individuals, tournament_size)
    fitnesses = [calculate_fitness(ind, target_genre) for ind in candidates]
    best_idx = argmax(fitnesses)
    return deepcopy(candidates[best_idx])
end

# 交叉（Crossover）- 2つの個体から新しい個体を生成
function crossover(parent1::TextGenome, parent2::TextGenome)
    child = deepcopy(parent1)
    
    # ジャンル重みの平均を取る（確率的に片親から選択）
    for genre in keys(child.genre_weights)
        if rand() < 0.5
            child.genre_weights[genre] = parent2.genre_weights[genre]
        end
    end
    
    # スタイルパラメータも同様
    for param in keys(child.style_params)
        if rand() < 0.5
            child.style_params[param] = parent2.style_params[param]
        end
    end
    
    # テキストセグメントは交互に選択
    for i in 1:length(child.text_segments)
        if rand() < 0.5 && i <= length(parent2.text_segments)
            child.text_segments[i] = parent2.text_segments[i]
        end
    end
    
    # 特性や要素は両親から混合
    child.character_traits = unique(vcat(
        rand(parent1.character_traits, min(2, length(parent1.character_traits))),
        rand(parent2.character_traits, min(1, length(parent2.character_traits)))
    ))
    
    child.setting_elements = unique(vcat(
        rand(parent1.setting_elements, min(2, length(parent1.setting_elements))),
        rand(parent2.setting_elements, min(1, length(parent2.setting_elements)))
    ))
    
    return child
end

# 一世代の進化
function evolve_generation(population::Population)
    new_individuals = TextGenome[]
    target_genre = get_target_genre(population.mutation_operator)
    
    # エリート保存（最良個体を保持）
    fitnesses = [calculate_fitness(ind, target_genre) for ind in population.individuals]
    elite_idx = argmax(fitnesses)
    push!(new_individuals, deepcopy(population.individuals[elite_idx]))
    
    # 残りの個体を生成
    while length(new_individuals) < population.population_size
        # 親選択
        parent1 = tournament_selection(population, target_genre)
        parent2 = tournament_selection(population, target_genre)
        
        # 交叉
        child = crossover(parent1, parent2)
        
        # 突然変異（80%の確率）
        if rand() < 0.8
            child = apply_mutation(child, population.mutation_operator)
        end
        
        push!(new_individuals, child)
    end
    
    population.individuals = new_individuals[1:population.population_size]
    population.generation += 1
    
    return population
end

# 複数世代を一度に進化
function evolve_multiple_generations(population::Population, num_generations::Int)
    for _ in 1:num_generations
        evolve_generation(population)
    end
    return population
end

# 目標ジャンルの取得
function get_target_genre(operator::String)
    genre_map = Dict(
        "もっとホラー" => "horror",
        "もっとロマンス" => "romance",
        "もっとSF" => "scifi",
        "もっとコメディ" => "comedy",
        "もっとミステリー" => "mystery"
    )
    return get(genre_map, operator, "horror")
end

# 集団の統計情報を取得
function get_population_stats(population::Population)
    target_genre = get_target_genre(population.mutation_operator)
    fitnesses = [calculate_fitness(ind, target_genre) for ind in population.individuals]
    
    return Dict(
        "generation" => population.generation,
        "population_size" => population.population_size,
        "best_fitness" => maximum(fitnesses),
        "average_fitness" => sum(fitnesses) / length(fitnesses),
        "worst_fitness" => minimum(fitnesses),
        "fitness_variance" => var(fitnesses)
    )
end

# 集団から最良個体を取得
function get_best_individual(population::Population)
    target_genre = get_target_genre(population.mutation_operator)
    fitnesses = [calculate_fitness(ind, target_genre) for ind in population.individuals]
    best_idx = argmax(fitnesses)
    return population.individuals[best_idx]
end

# 複数の独立した集団を並列進化（異なる戦略）
function parallel_evolution(operators::Vector{String}, population_size::Int=5, generations::Int=5)
    populations = Dict{String, Population}()
    results = Dict{String, Any}()
    
    # 各オペレーターで独立した集団を作成
    for operator in operators
        pop = create_population(population_size, operator)
        populations[operator] = evolve_multiple_generations(pop, generations)
        
        # 結果を収集
        best = get_best_individual(populations[operator])
        stats = get_population_stats(populations[operator])
        
        results[operator] = Dict(
            "best_text" => render_text(best),
            "stats" => stats,
            "best_genome" => best
        )
    end
    
    return results
end

# 単一オペレーターで複数個体の進化を可視化
function evolve_with_diversity(operator::String="もっとホラー", population_size::Int=5, generations::Int=3)
    population = create_population(population_size, operator)
    history = []
    
    # 初期状態を記録
    push!(history, Dict(
        "generation" => 0,
        "texts" => [render_text(ind) for ind in population.individuals],
        "stats" => get_population_stats(population)
    ))
    
    # 各世代を進化させて記録
    for gen in 1:generations
        evolve_generation(population)
        push!(history, Dict(
            "generation" => gen,
            "texts" => [render_text(ind) for ind in population.individuals],
            "stats" => get_population_stats(population)
        ))
    end
    
    return Dict(
        "operator" => operator,
        "history" => history,
        "final_best" => render_text(get_best_individual(population))
    )
end

# テスト実行
function test_population_evolution()
    println("=== 集団進化テスト ===\n")
    
    # 1. 単一オペレーターでの集団進化
    println("【ホラー進化 - 5個体、3世代】")
    result = evolve_with_diversity("もっとホラー", 5, 3)
    
    println("初期個体（第0世代）:")
    for (i, text) in enumerate(result["history"][1]["texts"])
        preview = length(text) > 50 ? first(text, 50) * "..." : text
        println("個体$i: ", preview)
    end
    
    println("\n最終世代（第3世代）:")
    for (i, text) in enumerate(result["history"][end]["texts"])
        preview = length(text) > 50 ? first(text, 50) * "..." : text
        println("個体$i: ", preview)
    end
    
    println("\n適応度の推移:")
    for hist in result["history"]
        stats = hist["stats"]
        println("世代$(stats["generation"]): 最高=$(round(stats["best_fitness"], digits=3)), 平均=$(round(stats["average_fitness"], digits=3))")
    end
    
    println("\n" * "="^50 * "\n")
    
    # 2. 並列進化（複数の異なる方向）
    println("【並列進化 - 3つの異なる方向】")
    operators = ["もっとホラー", "もっとロマンス", "もっとSF"]
    parallel_results = parallel_evolution(operators, 4, 3)
    
    for (operator, result) in parallel_results
        println("\n$operator:")
        println("  最高適応度: $(round(result["stats"]["best_fitness"], digits=3))")
        println("  最良個体（最初の100文字）:")
        preview = length(result["best_text"]) > 100 ? first(result["best_text"], 100) * "..." : result["best_text"]
        println("  ", preview)
    end
end