#!/usr/bin/env julia

# 舞台進化機能のテスト
include("src/backend/ga_hybrid.jl")

println("=== 舞台進化機能テスト ===\n")

# 初期ゲノムを作成
test_genome = create_initial_genome()
println("初期テキスト:")
println(render_text(test_genome))
println("\n初期設定要素: ", test_genome.setting_elements)

println("\n" * "="^50 * "\n")

# 「舞台を変える」を5回適用してテスト
for i in 1:5
    println("【第$(i)回進化】")
    global test_genome = mutate_setting(test_genome)
    
    println("進化後テキスト:")
    evolved_text = render_text(test_genome)
    println(evolved_text)
    
    println("設定要素: ", test_genome.setting_elements)
    println("世代: ", test_genome.mutation_count)
    println()
end

println("=== テスト完了 ===")