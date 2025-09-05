using Oxygen
using HTTP
using JSON3
using Dates

include("ga_hybrid.jl")

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

println("Starting test server on http://localhost:8081")
println("Available endpoints:")
println("  GET  /test            - Test page (UI)")
println("  GET  /                - Test page (UI)")
println("  GET  /api/test/initial - Get initial text")
println("  POST /api/test/mutate  - Apply mutation")
println("  POST /api/test/reset   - Reset to initial state")
println("  GET  /api/test/history - Get mutation history")

serve(host="0.0.0.0", port=8081, middleware=[cors_middleware])