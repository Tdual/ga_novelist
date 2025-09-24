# GA Novelist - 遺伝的アルゴリズムによる小説進化システム

インタラクティブな小説生成システム。遺伝的アルゴリズム（GA）を使用して、ユーザーの選択圧に応じて文章をリアルタイムで進化させます。

## 概要

本システムは、文章を「遺伝子型」として表現し、ユーザーによる選択圧（「もっと〇〇っぽく」ボタン）を通じて遺伝子発現を動的に変化させます。従来の静的な小説とは異なり、読者が進化の選択圧として積極的に物語の方向性に関与できる新しい文学体験を提供します。

## 特徴

- 🧬 **遺伝的アルゴリズムベース**: 文章の特性を遺伝子型として表現
- 🎯 **10種類の変異オペレーター**: ホラー、ロマンス、SF、コメディなど各ジャンル遺伝子への選択圧
- 🔄 **段階的な進化**: 遺伝子発現を保持しながら世代ごとに変異を蓄積
- 🎲 **多様性の確保**: コーパスベースの突然変異で同じ選択圧でも異なる表現型
- ⚡ **リアルタイム進化**: クリック即座に遺伝子発現が変化し文章が進化
- 🌐 **Webインターフェース**: ブラウザから簡単にアクセス可能
- 📊 **進化分析機能**: 遺伝子発現プロファイルと時系列変化を可視化

## 技術スタック

### バックエンド
- **言語**: Julia 1.9+
- **Webフレームワーク**: Oxygen.jl
- **データベース**: AWS RDS PostgreSQL
- **遺伝的アルゴリズム**: カスタム実装（TextGenome）

### フロントエンド
- **UI**: HTML5/CSS3/JavaScript (Vanilla)
- **可視化**: Canvas API（グラフ描画）
- **リアルタイム更新**: Fetch API + ポーリング

### インフラストラクチャ
- **データベース**: Amazon RDS (PostgreSQL 15)
- **リージョン**: ap-northeast-1 (東京)
- **接続**: LibPQ.jl

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

3. 選択圧をかけて文章を進化させる
   - 🎃 ホラー遺伝子を増強
   - 💕 ロマンス遺伝子を増強
   - 🚀 SF遺伝子を増強
   - 😂 コメディ遺伝子を増強
   - 🌸 詩的表現遺伝子を活性化
   - ⚡ テンポ遺伝子を促進
   - 💬 対話遺伝子を発現
   - 👥 キャラクター多様性を増加
   - 🏙️ 環境変異を導入
   - 🌀 カオス変異を誘発

4. 分析画面で進化を観察
   - 遺伝子発現プロファイルの確認
   - 時系列での遺伝子発現変化を追跡
   - 世代間の表現型比較

## システム構成

```
ga_novelist/
├── src/
│   ├── backend/
│   │   ├── server.jl          # HTTPサーバー（Oxygen.jl）
│   │   ├── database.jl        # RDS PostgreSQL接続管理
│   │   ├── ga_corpus.jl       # 遺伝的アルゴリズム実装
│   │   ├── db_config.jl       # データベース設定
│   │   └── corpus.jl          # コーパス管理
│   └── frontend/
│       ├── index.html         # メインページ（4つの進化実験室）
│       ├── room.html          # 個別進化実験室インターフェース
│       └── analysis.html      # 進化分析ダッシュボード
├── database/                  # SQLiteデータベース（開発用）
├── docs/
│   └── algorithm.md           # アルゴリズム詳細説明
└── ALGORITHM.md              # 技術仕様書
```

## アルゴリズムの仕組み

### 遺伝子型表現 (TextGenome)
```julia
mutable struct TextGenome
    genre_weights::Dict{String, Float64}      # ジャンル遺伝子の発現量
    style_params::Dict{String, Float64}       # 文体遺伝子パラメータ
    character_traits::Vector{String}          # キャラクター形質
    setting_elements::Vector{String}          # 環境要因
    text_segments::Vector{String}            # 表現型セグメント
    mutation_count::Int                       # 世代数（変異蓄積回数）
end
```

### 進化プロセス
1. **初期遺伝子型**: ベースとなる遺伝子型から開始
2. **選択圧**: ユーザーが選択圧（オペレーター）を適用
3. **変異**: 選択された遺伝子座に突然変異を導入
4. **遺伝子発現**: 変異が蓄積され表現型（文章）に反映
5. **適応度評価**: ユーザーの継続的な選択が暗黙的な適応度関数として機能

### 進化メカニズム
- **遺伝子型の保存**: 基本的な遺伝子構造を維持
- **突然変異**: コーパスベースのランダム変異で多様性を創出
- **世代効果**: 世代を重ねるごとに変異が蓄積し形質が強化
- **選択圧の累積**: 同一方向への継続的な選択で特定形質が固定化

## API エンドポイント

- `GET /` - メインページ（4つの進化実験室）
- `GET /room.html` - 個別進化実験室
- `GET /analysis.html` - 進化分析画面
- `GET /api/rooms` - 全実験室の状態取得
- `GET /api/rooms/{id}` - 実験室の詳細情報
- `POST /api/rooms/{id}/nudge` - 選択圧の適用（変異導入）
- `GET /api/rooms/{id}/generations` - 世代履歴と遺伝子発現データ
- `GET /api/rooms/{id}/stats` - 進化統計情報
- `GET /api/health` - システムヘルスチェック

## 開発

### データベース構成
- **rooms**: 進化実験室の管理
- **texts**: 各世代の表現型（文章）保存
- **genomes**: 遺伝子型データ（JSON形式）
- **mutations**: 選択圧の適用履歴

### 新しい選択圧オペレーターの追加

1. `ga_corpus.jl`に変異関数を定義:
```julia
function mutate_new_style(genome::TextGenome)
    new_genome = deepcopy(genome)
    # 遺伝子発現の調整
    new_genome.genre_weights["new_genre"] =
        min(1.0, new_genome.genre_weights["new_genre"] + 0.1)
    # 突然変異の導入
    apply_random_mutation!(new_genome)
    return new_genome
end
```

2. `server.jl`のMUTATION_MAPに登録:
```julia
const MUTATION_MAP = Dict(
    "new_style" => mutate_new_style,
    # ...
)
```

## ライセンス

MIT License

## 作者

[Your Name]

## 進化の観察ポイント

### 遺伝子発現の特徴
- **収束**: 特定の遺伝子が優勢になる過程
- **多様性**: 複数の遺伝子がバランスを保つ状態
- **急激な変化**: 強い選択圧による劇的な進化
- **漸進的変化**: 緩やかな選択による段階的進化

### 興味深い現象
- **遺伝的浮動**: ランダムな変異による予期せぬ進化
- **適応放散**: 異なる選択圧による多様な表現型の出現
- **収斂進化**: 異なる実験室で似た表現型が独立に進化
- **遺伝的ボトルネック**: 特定方向への過度な選択による多様性の喪失

## 謝辞

- Julia言語コミュニティ
- Oxygen.jl開発者
- 遺伝的アルゴリズム研究者の皆様
- AWS RDSチーム