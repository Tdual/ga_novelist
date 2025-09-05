# 遺伝的アルゴリズムによる小説進化システム

## 概要

本システムは、遺伝的アルゴリズム（GA: Genetic Algorithm）を応用して、小説を動的に進化させるシステムです。ユーザーのインタラクション（「もっと〇〇っぽく」ボタンのクリック）を通じて、文章が即座に変化・進化します。

## アルゴリズムの基本構造

### 1. 遺伝子表現（Genome）

文章の特性を以下の要素で表現します：

```julia
struct Genome
    genre_weights::Dict{String, Float64}      # ジャンルの重み
    style_params::Dict{String, Float64}       # 文体パラメータ
    character_traits::Vector{String}          # キャラクター特性
    setting_elements::Vector{String}          # 舞台設定要素
end
```

#### genre_weights（ジャンルの重み）
- `horror`: ホラー要素の強さ（0.0〜1.0）
- `romance`: ロマンス要素の強さ（0.0〜1.0）
- `scifi`: SF要素の強さ（0.0〜1.0）
- `comedy`: コメディ要素の強さ（0.0〜1.0）
- `mystery`: ミステリー要素の強さ（0.0〜1.0）

#### style_params（文体パラメータ）
- `dialogue_ratio`: セリフの比率（0.0〜1.0）
- `description_density`: 描写の密度（0.0〜1.0）
- `pace`: 物語のペース（0.0〜1.0）
- `poetic_level`: 詩的表現のレベル（0.0〜1.0）
- `complexity`: 文章の複雑さ（0.0〜1.0）

#### character_traits（キャラクター特性）
動的に追加される特性のリスト：
- 例：`["curious", "brave", "gentle", "mysterious"]`

#### setting_elements（舞台設定要素）
動的に追加される舞台要素のリスト：
- 例：`["forest", "light", "darkness", "castle"]`

### 2. 突然変異演算子（Mutation Operators）

ユーザーが選択できる10種類の変換オペレーター：

#### 「もっとホラー」
```julia
function mutate_horror(genome)
    # ホラー要素の重みを増加
    genome.genre_weights["horror"] += 0.3
    # 描写密度を増加（詳細な恐怖描写）
    genome.style_params["description_density"] += 0.2
    # 恐怖要素を設定に追加
    push!(genome.setting_elements, rand(["shadow", "whisper", "cold", "fear"]))
end
```

#### 「もっとロマンス」
```julia
function mutate_romance(genome)
    # ロマンス要素の重みを増加
    genome.genre_weights["romance"] += 0.3
    # セリフ比率を増加（感情的な対話）
    genome.style_params["dialogue_ratio"] += 0.2
    # ロマンチックな特性を追加
    push!(genome.character_traits, rand(["gentle", "passionate", "mysterious"]))
end
```

#### 「もっとSF」
```julia
function mutate_scifi(genome)
    # SF要素の重みを増加
    genome.genre_weights["scifi"] += 0.3
    # 複雑さを増加（技術的な説明）
    genome.style_params["complexity"] += 0.2
    # SF要素を設定に追加
    push!(genome.setting_elements, rand(["technology", "portal", "dimension"]))
end
```

### 3. テキストレンダリング

遺伝子情報から実際の文章を生成するプロセス：

```julia
function render_text(genome)
    # 1. 基本ナラティブの生成
    base_text = generate_base_narrative(genome)
    
    # 2. スタイルの適用
    styled_text = apply_style(base_text, genome.style_params)
    
    return styled_text
end
```

#### レンダリングの詳細プロセス

1. **ジャンル判定**
   - 最も重みの高いジャンルを特定
   - そのジャンルに応じた文章要素を生成

2. **文章変換**
   - 単語・フレーズの置換
   - 新しい文の挿入
   - 文体の調整

3. **スタイル適用**
   - `dialogue_ratio > 0.6` → セリフを追加
   - `poetic_level > 0.6` → 詩的表現を追加
   - `pace > 0.7` → 文を短縮、スピード感を演出

## 進化のメカニズム

### 1. 初期状態
```julia
initial_genome = Genome(
    genre_weights = Dict(全ジャンル => 0.2),  # 均等な重み
    style_params = Dict(全パラメータ => 0.5),  # 中間的な値
    character_traits = ["少年"],
    setting_elements = ["森", "光"]
)
```

### 2. ユーザーインタラクション
1. ユーザーが「もっと〇〇っぽく」ボタンをクリック
2. 対応する突然変異演算子が適用される
3. 新しい遺伝子が生成される
4. テキストが再レンダリングされる
5. 画面が即座に更新される

### 3. 複合進化
複数の変換を連続適用することで、複雑な文章が生成される：

```
初期状態 → ホラー変換 → SF変換 → スピード感変換
= ホラーSFアクション小説
```

## 特徴的な実装詳細

### 1. 即時性
- 投票や集計なし
- クリック即座に反映
- リアルタイム更新

### 2. 非破壊的変換
- 元の文章構造を保持
- 要素の追加・強化が中心
- 過去の変換履歴を保持

### 3. 確率的要素
```julia
# ランダムな要素選択で多様性を確保
push!(setting_elements, rand(["castle", "ocean", "city", "mountain"]))
```

### 4. 境界値管理
```julia
# パラメータが0.0〜1.0の範囲に収まるように制御
new_weight = min(1.0, current_weight + 0.3)
```

## データ構造

### 状態管理
```julia
mutable struct TestState
    current_genome::TextGenome  # 現在の遺伝子
    history::Vector{Dict}        # 変換履歴
end
```

### 履歴記録
各変換操作を記録：
```julia
Dict(
    "operator" => "もっとホラー",
    "text" => "変換後のテキスト",
    "timestamp" => "2025-09-06T12:00:00"
)
```

## 拡張性

### 新しい演算子の追加
```julia
MUTATION_OPERATORS["もっと哲学的"] = function(g::Genome)
    g_new = deepcopy(g)
    g_new.style_params["complexity"] += 0.4
    g_new.style_params["poetic_level"] += 0.3
    push!(g_new.setting_elements, "existential")
    return g_new
end
```

### パラメータのカスタマイズ
- 変化量の調整（0.3 → 0.1〜0.5）
- 新しいジャンル追加
- スタイルパラメータの拡張

## 技術的な利点

1. **Julia言語の活用**
   - 高速な数値計算
   - 型安全性
   - 関数型プログラミングのサポート

2. **Evolutionary.jlとの統合可能性**
   - より高度な進化戦略の実装
   - 多目的最適化
   - 並列進化

3. **リアルタイム性**
   - 低レイテンシ
   - 効率的なメモリ管理
   - 軽量なHTTPサーバー（Oxygen.jl）

## まとめ

本システムは、遺伝的アルゴリズムの概念を創造的に応用し、インタラクティブな小説生成を実現しています。各要素（ジャンル、文体、キャラクター、舞台）を遺伝子として表現し、ユーザーの選択を突然変異として適用することで、文章が有機的に進化していきます。

これにより、従来の静的な小説とは異なり、読者が積極的に物語の方向性に関与できる、新しい形の文学体験を提供しています。