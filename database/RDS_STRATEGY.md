# GA Novelist - RDS データベース戦略

## 概要
GA Novelistは、遺伝的アルゴリズムを用いた小説生成システムで、複数のルームで並行してテキストが進化します。
当初はメモリベースで開発し、必要に応じてRDSに移行する段階的アプローチを採用します。

## データベース選択
- **PostgreSQL 15.x** を選択
  - JSONBサポートが充実（ゲノムデータの保存に最適）
  - 全文検索機能（生成テキストの検索・分析）
  - パフォーマンスと安定性
  - Julia言語からの接続サポート（LibPQ.jl）

## RDSインスタンス構成（超最小）
- **インスタンスクラス**: db.t3.micro
- **ストレージ**: 20GB gp2（最安）
- **マルチAZ**: 無効
- **バックアップ**: 無効（コスト削減）
- **暗号化**: 無効（コスト削減）
- **監視**: 無効（コスト削減）

## データモデル設計

### 1. rooms（ルーム）
- ルームの基本情報と現在の状態を管理
- 4つの固定ルーム + 将来的な拡張に対応

### 2. genomes（ゲノム）
- テキストゲノムの詳細データ
- JSONBで柔軟なゲノム構造を保存

### 3. texts（生成テキスト）
- 各世代で生成されたテキストの履歴
- パフォーマンスとコンテンツの追跡

### 4. mutations（変異履歴）
- 適用された変異操作の記録
- どの操作がどのような効果をもたらしたかの分析

### 5. room_snapshots（スナップショット）
- 特定時点のルーム状態の完全な記録
- 興味深い状態の保存と復元

### 6. user_interactions（ユーザーインタラクション）
- ユーザーの操作履歴
- 使用パターンの分析

## パフォーマンス最適化戦略

### インデックス設計
- rooms.id（主キー）
- mutations.room_id, created_at（複合インデックス）
- texts.room_id, generation（複合インデックス）
- user_interactions.session_id, created_at（複合インデックス）

### キャッシング戦略
- 現在の世代のテキストはアプリケーションレベルでキャッシュ
- 頻繁にアクセスされるゲノムデータはRedis（将来的な実装）

### データ保持ポリシー
- テキスト履歴: 最新1000世代を保持
- 変異履歴: 30日間保持
- スナップショット: ユーザー作成のものは無期限保持
- インタラクションログ: 90日間保持

## セキュリティ考慮事項

### 接続セキュリティ
- SSL/TLS接続を強制
- VPC内からのみアクセス可能
- セキュリティグループで適切なポート制限

### データセキュリティ
- RDS暗号化（AWS KMS使用）
- 定期的な自動バックアップ
- ポイントインタイムリカバリの有効化

### アクセス制御
- アプリケーション用の専用ユーザー
- 読み取り専用ユーザーの作成（分析用）
- 管理者権限の最小化

## マイグレーション戦略

### Phase 1: 基本実装（現在）
- コアテーブルの作成
- 基本的なCRUD操作の実装
- 既存のメモリベースシステムとの並行運用

### Phase 2: データ移行
- 現在のルーム状態をDBに保存
- 履歴データの段階的な移行
- パフォーマンステスト

### Phase 3: 完全移行
- メモリベースシステムの廃止
- DB駆動のシステムへの完全移行
- バックアップ・リストア手順の確立

## 監視とメンテナンス

### 監視項目
- 接続数
- クエリレスポンスタイム
- ストレージ使用量
- CPU/メモリ使用率

### メンテナンス作業
- 週次: パフォーマンス統計の分析
- 月次: インデックスの最適化
- 四半期: データ保持ポリシーの実行

## コスト見積もり（東京リージョン）

- db.t3.micro: 約$12.41/月
- ストレージ(20GB gp2): 約$2.30/月
- バックアップ: $0（無効）
- 監視: $0（無効）
- **合計: 約$15/月（約2,250円）**

## デプロイ手順

### 1. ワンコマンドデプロイ
```bash
cd database
./deploy-rds.sh
```

### 2. 手動デプロイ
```bash
aws cloudformation create-stack \
  --stack-name ga-novelist-rds \
  --template-body file://rds-ultra-minimal.yaml \
  --parameters ParameterKey=DBMasterPassword,ParameterValue=YourPassword123!
```

### 3. データベース初期化
```bash
psql -h <endpoint> -U postgres -d ga_novelist -f 01_create_schema.sql
psql -h <endpoint> -U postgres -d ga_novelist -f 02_migration_functions.sql
psql -h <endpoint> -U postgres -d ga_novelist -f 03_corpus_schema.sql
psql -h <endpoint> -U postgres -d ga_novelist -f 04_import_initial_corpus.sql
```

### 4. 削除方法
```bash
aws cloudformation delete-stack --stack-name ga-novelist-rds
```

## 注意事項
- **開発専用構成**（バックアップなし、監視なし）
- データ消失リスクあり
- 本番環境では適切なバックアップ設定を追加すること