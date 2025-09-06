using Oxygen
using HTTP
using JSON3
using Dates

include("ga_hybrid.jl")
include("ga_population.jl")

# CORSヘッダーを追加する関数
function add_cors_headers(response::HTTP.Response)
    HTTP.setheader(response, "Access-Control-Allow-Origin" => "*")
    HTTP.setheader(response, "Access-Control-Allow-Methods" => "GET, POST, OPTIONS")
    HTTP.setheader(response, "Access-Control-Allow-Headers" => "Content-Type")
    return response
end

# 初期テキストと現在のgenomeを保持
mutable struct TestState
    current_genome::TextGenome
    history::Vector{Dict}
end

const test_state = TestState(
    create_initial_genome(),
    Vector{Dict}()
)

# 全てのリクエストにCORSヘッダーを追加するミドルウェア
function cors_middleware(handler)
    return function(req::HTTP.Request)
        # OPTIONSリクエストの処理
        if req.method == "OPTIONS"
            response = HTTP.Response(204)
            return add_cors_headers(response)
        end
        
        # 通常のリクエスト処理
        response = handler(req)
        return add_cors_headers(response)
    end
end

# 初期テキストを取得
@get "/api/test/initial" function(req::HTTP.Request)
    response = HTTP.Response(200, JSON3.write(Dict(
        "text" => render_text(test_state.current_genome),
        "genome" => Dict(
            "genre_weights" => test_state.current_genome.genre_weights,
            "style_params" => test_state.current_genome.style_params
        )
    )))
    return add_cors_headers(response)
end

# 変換を適用
@post "/api/test/mutate" function(req::HTTP.Request)
    body = JSON3.read(String(req.body))
    operator = get(body, :operator, "")
    
    if operator == ""
        response = HTTP.Response(400, JSON3.write(Dict("error" => "operator is required")))
        return add_cors_headers(response)
    end
    
    # 変換を適用
    new_genome = apply_mutation(test_state.current_genome, String(operator))
    test_state.current_genome = new_genome
    
    # 履歴に追加
    push!(test_state.history, Dict(
        "operator" => operator,
        "text" => render_text(new_genome),
        "timestamp" => string(now())
    ))
    
    response = HTTP.Response(200, JSON3.write(Dict(
        "text" => render_text(new_genome),
        "operator" => operator,
        "genome" => Dict(
            "genre_weights" => new_genome.genre_weights,
            "style_params" => new_genome.style_params
        ),
        "history_length" => length(test_state.history)
    )))
    return add_cors_headers(response)
end

# リセット
@post "/api/test/reset" function(req::HTTP.Request)
    test_state.current_genome = create_initial_genome()
    test_state.history = Vector{Dict}()
    
    response = HTTP.Response(200, JSON3.write(Dict(
        "text" => render_text(test_state.current_genome),
        "message" => "Reset to initial state"
    )))
    return add_cors_headers(response)
end

# 履歴を取得
@get "/api/test/history" function(req::HTTP.Request)
    response = HTTP.Response(200, JSON3.write(Dict(
        "history" => test_state.history,
        "current_text" => render_text(test_state.current_genome)
    )))
    return add_cors_headers(response)
end

# 集団進化を実行
@post "/api/test/evolve" function(req::HTTP.Request)
    body = JSON3.read(String(req.body))
    
    # パラメータを取得（デフォルト値付き）
    operator = get(body, :operator, "もっとホラー")
    population_size = get(body, :population_size, 5)
    generations = get(body, :generations, 3)
    
    # 進化を実行
    result = evolve_with_diversity(String(operator), Int(population_size), Int(generations))
    
    # 各世代の最良個体のテキストを取得
    generation_texts = []
    for hist in result["history"]
        # 各世代の全テキストから最初の3個体を取得
        texts = hist["texts"][1:min(3, length(hist["texts"]))]
        push!(generation_texts, Dict(
            "generation" => hist["generation"],
            "texts" => [length(t) > 200 ? first(t, 200) * "..." : t for t in texts],
            "stats" => hist["stats"]
        ))
    end
    
    response = HTTP.Response(200, JSON3.write(Dict(
        "operator" => operator,
        "population_size" => population_size,
        "generations" => generations,
        "evolution" => generation_texts,
        "final_best" => result["final_best"]
    )))
    return add_cors_headers(response)
end

# 並列進化を実行
@post "/api/test/parallel" function(req::HTTP.Request)
    body = JSON3.read(String(req.body))
    
    # パラメータを取得
    operators = get(body, :operators, ["もっとホラー", "もっとロマンス", "もっとSF"])
    population_size = get(body, :population_size, 4)
    generations = get(body, :generations, 3)
    
    # 並列進化を実行
    results = parallel_evolution(
        [String(op) for op in operators],
        Int(population_size),
        Int(generations)
    )
    
    # 結果を整形
    formatted_results = Dict()
    for (op, result) in results
        formatted_results[op] = Dict(
            "text" => length(result["best_text"]) > 500 ? 
                     first(result["best_text"], 500) * "..." : result["best_text"],
            "stats" => result["stats"]
        )
    end
    
    response = HTTP.Response(200, JSON3.write(Dict(
        "operators" => operators,
        "results" => formatted_results
    )))
    return add_cors_headers(response)
end

# 静的ファイルの提供（test.html）
@get "/test" function(req::HTTP.Request)
    html_path = joinpath(dirname(@__FILE__), "..", "frontend", "test.html")
    if isfile(html_path)
        html_content = read(html_path, String)
        response = HTTP.Response(200, html_content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        return HTTP.Response(404, "Test page not found")
    end
end

# ルートパスでもtest.htmlを表示
@get "/" function(req::HTTP.Request)
    html_path = joinpath(dirname(@__FILE__), "..", "frontend", "test.html")
    if isfile(html_path)
        html_content = read(html_path, String)
        response = HTTP.Response(200, html_content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        return HTTP.Response(404, "Test page not found")
    end
end

@get "/evolution" function(req::HTTP.Request)
    html_path = joinpath(dirname(@__FILE__), "..", "frontend", "evolution.html")
    if isfile(html_path)
        html_content = read(html_path, String)
        response = HTTP.Response(200, html_content)
        HTTP.setheader(response, "Content-Type" => "text/html; charset=utf-8")
        return add_cors_headers(response)
    else
        return HTTP.Response(404, "Evolution page not found")
    end
end

println("Starting test server on http://localhost:8081")
println("Available endpoints:")
println("  GET  /test            - Test page (UI)")
println("  GET  /evolution       - Evolution Lab (集団進化)")
println("  GET  /                - Test page (UI)")
println("  GET  /api/test/initial - Get initial text")
println("  POST /api/test/mutate  - Apply mutation")
println("  POST /api/test/evolve  - Evolve population")
println("  POST /api/test/parallel - Parallel evolution")
println("  POST /api/test/reset   - Reset to initial state")
println("  GET  /api/test/history - Get mutation history")

serve(host="0.0.0.0", port=8081, middleware=[cors_middleware])