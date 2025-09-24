# GA Novelist - 遺伝的アルゴリズムによる小説進化システム

インタラクティブな小説生成システム。遺伝的アルゴリズム（GA）を使用して、ユーザーの選択に応じて文章をリアルタイムで進化させます。

## 概要

本システムは、文章を「遺伝子」として表現し、ユーザーのインタラクション（「もっと〇〇っぽく」ボタン）を通じて文章を動的に変化させます。従来の静的な小説とは異なり、読者が積極的に物語の方向性に関与できる新しい文学体験を提供します。

## 特徴

- 🧬 **遺伝的アルゴリズムベース**: 文章の特性を遺伝子として表現
- 🎯 **10種類の変換オペレーター**: ホラー、ロマンス、SF、コメディなど
- 🔄 **段階的な進化**: 元の文章を保持しながら徐々に変化
- 🎲 **多様性の確保**: コーパスベースのランダム生成で同じボタンでも異なる結果
- ⚡ **リアルタイム変換**: クリック即座に文章が進化
- 🌐 **Webインターフェース**: ブラウザから簡単にアクセス可能

## 技術スタック

- **言語**: Julia 1.9+
- **Webフレームワーク**: Oxygen.jl
- **フロントエンド**: HTML/CSS/JavaScript (Vanilla)
- **アルゴリズム**: 遺伝的アルゴリズム + コーパスベース文章生成

## インストール

### 必要要件
- Julia 1.9以降
- Git

### セットアップ

1. リポジトリをクローン
```bash
git clone https://github.com/yourusername/ga_novelist.git
cd ga_novelist
```

2. Juliaパッケージをインストール
```bash
cd src/backend
julia
```

Julia REPLで:
```julia
using Pkg
Pkg.add("Oxygen")
Pkg.add("HTTP")
Pkg.add("JSON3")
Pkg.add("Dates")
Pkg.add("Random")
Pkg.add("LibPQ")
Pkg.add("UUIDs")
```

## 使い方

1. サーバーを起動
```bash
cd src/backend
julia server.jl
```

2. ブラウザでアクセス
```
http://localhost:8082
```

3. ボタンをクリックして文章を進化させる
   - 🎃 もっとホラー
   - 💕 もっとロマンス
   - 🚀 もっとSF
   - 😂 もっとコメディ
   - 🌸 もっと詩的に
   - ⚡ もっとスピード感
   - 💬 もっとセリフを
   - 👥 もっとキャラを増やす
   - 🏙️ もっと舞台を変える
   - 🌀 もっと混沌

## システム構成

```
ga_novelist/
├── src/
│   ├── backend/
│   │   ├── server.jl          # HTTPサーバー（RDS PostgreSQL使用）
│   │   ├── database_postgres.jl # データベース接続管理
│   │   ├── ga_corpus_postgres.jl # PostgreSQL対応GA実装
│   │   ├── db_config.jl      # DB設定
│   │   └── corpus.jl         # コーパス管理
│   └── frontend/
│       ├── index.html         # メインページ（4ルーム）
│       ├── room.html          # 個別ルームページ
│       └── evolution.html     # 集団進化実験
└── docs/
    └── algorithm.md           # アルゴリズム詳細説明
```

## アルゴリズムの仕組み

### 遺伝子表現 (TextGenome)
```julia
mutable struct TextGenome
    genre_weights::Dict{String, Float64}      # ジャンルの重み
    style_params::Dict{String, Float64}       # 文体パラメータ
    character_traits::Vector{String}          # キャラクター特性
    setting_elements::Vector{String}          # 舞台設定要素
    text_segments::Vector{String}            # 文章セグメント
    mutation_count::Int                       # 変異回数
end
```

### 進化プロセス
1. **初期状態**: 固定のベーステキストから開始
2. **変異適用**: ユーザーが選択したオペレーターに応じて変換
3. **段階的変化**: 変異回数に応じて変化の強度が増加
4. **多様性確保**: コーパスからランダムに単語・フレーズを選択

### ハイブリッドアプローチ
- **固定テキスト**: 基本構造を保持
- **コーパスベース**: 単語やフレーズをランダムに選択
- **累積効果**: 複数回の変異で効果が蓄積

## API エンドポイント

- `GET /` - メインページ（4ルーム）
- `GET /room.html` - 個別ルームページ
- `GET /api/rooms` - 全ルーム取得
- `GET /api/rooms/{id}` - ルーム詳細
- `POST /api/rooms/{id}/nudge` - 変異適用
- `GET /api/rooms/{id}/stats` - 統計情報取得
- `GET /api/rooms/compare` - 全ルーム比較

## 開発

### テスト実行
```bash
julia ga_test.jl
```

### 新しい変換オペレーターの追加
`ga_hybrid.jl`に新しい変異関数を追加:
```julia
function mutate_new_style(genome::TextGenome)
    new_genome = deepcopy(genome)
    # 変換ロジックを実装
    return new_genome
end
```

## ライセンス

MIT License

## 作者

[Your Name]

## 謝辞

- Julia言語コミュニティ
- Oxygen.jl開発者
- 遺伝的アルゴリズム研究者の皆様