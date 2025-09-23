# GA Novelist データベース ER図

## 全体構成

```mermaid
erDiagram
    %% ルーム管理
    rooms ||--o{ genomes : "has"
    rooms ||--o{ texts : "generates"
    rooms ||--o{ mutations : "records"
    rooms ||--o{ sessions : "hosts"
    
    %% ゲノムと関連
    genomes ||--o| texts : "produces"
    genomes ||--o{ mutations : "from/to"
    
    %% 変異履歴
    mutations }o--|| users : "performed_by"
    
    %% セッションとユーザー
    sessions }o--|| users : "belongs_to"
    sessions ||--o{ user_actions : "tracks"
    
    %% コーパス管理
    corpus_versions ||--o{ word_slots : "contains"
    corpus_versions ||--o{ sentence_templates : "contains"
    corpus_versions ||--o{ phrase_patterns : "contains"
    corpus_versions ||--o{ style_matrices : "contains"
    
    %% ジャンル
    genres ||--o{ word_slots : "categorizes"
    genres ||--o{ sentence_templates : "categorizes"
    genres ||--o{ phrase_patterns : "categorizes"
    
    %% 統計と分析
    rooms ||--o{ statistics : "analyzed"
```

## 主要テーブル構造

```mermaid
erDiagram
    rooms {
        UUID id PK
        varchar name
        text description
        integer current_generation
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }
    
    genomes {
        UUID id PK
        UUID room_id FK
        integer generation
        jsonb genre_weights
        jsonb style_params
        jsonb character_traits
        jsonb setting_elements
        integer mutation_count
        decimal fitness_score
        timestamp created_at
    }
    
    texts {
        UUID id PK
        UUID room_id FK
        UUID genome_id FK
        integer generation
        text content
        integer content_length
        integer word_count
        integer unique_words
        decimal sentiment_score
        timestamp created_at
    }
    
    mutations {
        UUID id PK
        UUID room_id FK
        UUID from_genome_id FK
        UUID to_genome_id FK
        varchar operator
        varchar actor_type
        UUID actor_id FK
        integer from_generation
        integer to_generation
        jsonb mutation_details
        timestamp created_at
    }
```

## コーパステーブル構造

```mermaid
erDiagram
    corpus_versions {
        UUID id PK
        varchar version
        text description
        boolean is_active
        timestamp created_at
        timestamp activated_at
    }
    
    genres {
        serial id PK
        varchar code UK
        varchar name_ja
        varchar name_en
        text description
        varchar color_code
        integer sort_order
    }
    
    word_slots {
        UUID id PK
        UUID corpus_version_id FK
        integer genre_id FK
        varchar slot_type
        text word
        decimal weight
        varchar part_of_speech
        varchar reading
        decimal sentiment_score
        timestamp created_at
    }
    
    sentence_templates {
        UUID id PK
        UUID corpus_version_id FK
        integer genre_id FK
        varchar template_type
        text template
        integer min_generation
        integer max_generation
        text_array required_slots
        decimal weight
        timestamp created_at
    }
    
    phrase_patterns {
        UUID id PK
        UUID corpus_version_id FK
        integer genre_id FK
        varchar pattern_type
        text pattern
        text description
        jsonb usage_conditions
        decimal weight
        timestamp created_at
    }
```

## ユーザー管理テーブル

```mermaid
erDiagram
    users {
        UUID id PK
        varchar username UK
        varchar email UK
        varchar display_name
        varchar avatar_url
        jsonb preferences
        timestamp created_at
        timestamp last_active_at
    }
    
    sessions {
        UUID id PK
        UUID room_id FK
        UUID user_id FK
        varchar session_token UK
        inet ip_address
        text user_agent
        timestamp started_at
        timestamp ended_at
        boolean is_active
    }
    
    user_actions {
        UUID id PK
        UUID session_id FK
        UUID room_id FK
        varchar action_type
        jsonb action_data
        integer generation_before
        integer generation_after
        timestamp created_at
    }
```

## 統計テーブル

```mermaid
erDiagram
    statistics {
        UUID id PK
        UUID room_id FK
        date stat_date
        integer total_mutations
        integer unique_users
        decimal avg_session_duration
        jsonb operator_usage
        jsonb genre_distribution
        jsonb hourly_activity
        timestamp calculated_at
    }
    
    room_snapshots {
        UUID id PK
        UUID room_id FK
        integer generation
        UUID genome_id FK
        UUID text_id FK
        jsonb metadata
        timestamp created_at
    }
```

## 特徴

1. **完全な履歴管理**: 全ての変更が記録される
2. **コーパスのバージョン管理**: 語彙データの世代管理
3. **JSONB活用**: 柔軟なデータ構造
4. **インデックス最適化**: 高速検索
5. **外部キー制約**: データ整合性保証

## 必要な要件

- PostgreSQL 15.x以上
- 拡張機能:
  - `uuid-ossp` (UUID生成)
  - `pg_trgm` (日本語全文検索)