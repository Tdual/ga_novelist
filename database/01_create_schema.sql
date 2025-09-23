-- GA Novelist Database Schema
-- PostgreSQL 15.x
-- 
-- このスクリプトはデータベースの初期セットアップ用です
-- 実行前にデータベースを作成してください：
-- CREATE DATABASE ga_novelist;

-- 既存のスキーマをクリーンアップ（開発環境のみ）
-- DROP SCHEMA IF EXISTS public CASCADE;
-- CREATE SCHEMA public;

-- 拡張機能の有効化
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- UUID生成
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- テキスト類似度検索

-- ========================================
-- 1. ルームテーブル
-- ========================================
CREATE TABLE IF NOT EXISTS rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    current_generation INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_rooms_name ON rooms(name);
CREATE INDEX idx_rooms_active ON rooms(is_active) WHERE is_active = true;

-- ========================================
-- 2. ゲノムテーブル
-- ========================================
CREATE TABLE IF NOT EXISTS genomes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    generation INTEGER NOT NULL,
    
    -- ゲノムデータ（JSONB形式）
    genre_weights JSONB NOT NULL DEFAULT '{}',
    style_params JSONB NOT NULL DEFAULT '{}',
    character_traits JSONB NOT NULL DEFAULT '{}',
    setting_elements JSONB NOT NULL DEFAULT '{}',
    
    -- メタデータ
    mutation_count INTEGER DEFAULT 0,
    fitness_score DECIMAL(10,4),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- 同一ルーム・世代の重複を防ぐ
    UNIQUE(room_id, generation)
);

-- インデックス
CREATE INDEX idx_genomes_room_generation ON genomes(room_id, generation DESC);
CREATE INDEX idx_genomes_genre_weights ON genomes USING GIN (genre_weights);
CREATE INDEX idx_genomes_created_at ON genomes(created_at DESC);

-- ========================================
-- 3. 生成テキストテーブル
-- ========================================
CREATE TABLE IF NOT EXISTS texts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    genome_id UUID REFERENCES genomes(id) ON DELETE SET NULL,
    generation INTEGER NOT NULL,
    
    -- テキストコンテンツ
    content TEXT NOT NULL,
    content_length INTEGER GENERATED ALWAYS AS (LENGTH(content)) STORED,
    
    -- テキスト分析データ
    word_count INTEGER,
    unique_words INTEGER,
    sentiment_score DECIMAL(5,4),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- 同一ルーム・世代の重複を防ぐ
    UNIQUE(room_id, generation)
);

-- インデックス
CREATE INDEX idx_texts_room_generation ON texts(room_id, generation DESC);
CREATE INDEX idx_texts_created_at ON texts(created_at DESC);
-- 全文検索用インデックス（日本語対応）
CREATE INDEX idx_texts_content_trgm ON texts USING GIN (content gin_trgm_ops);

-- ========================================
-- 4. 変異履歴テーブル
-- ========================================
CREATE TABLE IF NOT EXISTS mutations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    from_genome_id UUID REFERENCES genomes(id) ON DELETE SET NULL,
    to_genome_id UUID REFERENCES genomes(id) ON DELETE SET NULL,
    
    -- 変異情報
    operator VARCHAR(50) NOT NULL,
    operator_params JSONB DEFAULT '{}',
    
    -- 変異前後の世代
    from_generation INTEGER NOT NULL,
    to_generation INTEGER NOT NULL,
    
    -- アクター情報
    actor_type VARCHAR(20) DEFAULT 'user', -- 'user', 'system', 'ai'
    actor_id VARCHAR(100),
    actor_ip INET,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_mutations_room_created ON mutations(room_id, created_at DESC);
CREATE INDEX idx_mutations_operator ON mutations(operator);
CREATE INDEX idx_mutations_actor ON mutations(actor_type, actor_id);

-- ========================================
-- 5. ルームスナップショットテーブル
-- ========================================
CREATE TABLE IF NOT EXISTS room_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    
    -- スナップショット情報
    name VARCHAR(200),
    description TEXT,
    generation INTEGER NOT NULL,
    
    -- 完全な状態を保存
    genome_data JSONB NOT NULL,
    text_content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    
    -- フラグ
    is_favorite BOOLEAN DEFAULT false,
    is_milestone BOOLEAN DEFAULT false,
    
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_snapshots_room ON room_snapshots(room_id);
CREATE INDEX idx_snapshots_favorite ON room_snapshots(is_favorite) WHERE is_favorite = true;
CREATE INDEX idx_snapshots_created_at ON room_snapshots(created_at DESC);

-- ========================================
-- 6. ユーザーインタラクションテーブル
-- ========================================
CREATE TABLE IF NOT EXISTS user_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(100) NOT NULL,
    room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
    
    -- インタラクション詳細
    action_type VARCHAR(50) NOT NULL, -- 'nudge', 'view', 'share', 'snapshot'
    action_params JSONB DEFAULT '{}',
    
    -- クライアント情報
    user_agent TEXT,
    ip_address INET,
    referrer TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_interactions_session ON user_interactions(session_id, created_at DESC);
CREATE INDEX idx_interactions_room ON user_interactions(room_id) WHERE room_id IS NOT NULL;
CREATE INDEX idx_interactions_action ON user_interactions(action_type);
CREATE INDEX idx_interactions_created_at ON user_interactions(created_at DESC);

-- ========================================
-- 7. システム設定テーブル
-- ========================================
CREATE TABLE IF NOT EXISTS system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- ビューの作成
-- ========================================

-- 現在のルーム状態ビュー
CREATE OR REPLACE VIEW current_room_states AS
SELECT 
    r.id,
    r.name,
    r.current_generation,
    r.is_active,
    t.content as current_text,
    g.genre_weights,
    g.style_params,
    g.mutation_count,
    r.updated_at
FROM rooms r
LEFT JOIN texts t ON r.id = t.room_id AND r.current_generation = t.generation
LEFT JOIN genomes g ON r.id = g.room_id AND r.current_generation = g.generation
WHERE r.is_active = true;

-- 変異統計ビュー
CREATE OR REPLACE VIEW mutation_statistics AS
SELECT 
    room_id,
    operator,
    COUNT(*) as usage_count,
    MAX(created_at) as last_used,
    COUNT(DISTINCT actor_id) as unique_users
FROM mutations
WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY room_id, operator;

-- ========================================
-- 関数の作成
-- ========================================

-- updated_atを自動更新するトリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ルームテーブルのトリガー
CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- パーティショニング設定（将来の拡張用）
-- ========================================
-- textsテーブルとmutationsテーブルは将来的に
-- 月次パーティショニングを検討

-- ========================================
-- 初期データ投入
-- ========================================

-- システム設定の初期値
INSERT INTO system_settings (key, value, description) VALUES
    ('max_generation_per_room', '10000', '各ルームの最大世代数'),
    ('auto_cleanup_days', '30', '自動クリーンアップまでの日数'),
    ('max_snapshots_per_room', '100', 'ルームあたりの最大スナップショット数'),
    ('click_limit_per_minute', '3', '1分あたりのクリック制限')
ON CONFLICT (key) DO NOTHING;

-- 初期4ルームの作成
INSERT INTO rooms (name, description) VALUES
    ('Room A', '最初の実験ルーム'),
    ('Room B', '2番目の実験ルーム'),
    ('Room C', '3番目の実験ルーム'),
    ('Room D', '4番目の実験ルーム')
ON CONFLICT DO NOTHING;

-- ========================================
-- 権限設定
-- ========================================

-- アプリケーション用ユーザーの作成（実行時に設定）
-- CREATE USER ga_novelist_app WITH PASSWORD 'your_secure_password';
-- GRANT CONNECT ON DATABASE ga_novelist TO ga_novelist_app;
-- GRANT USAGE ON SCHEMA public TO ga_novelist_app;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ga_novelist_app;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ga_novelist_app;

-- 読み取り専用ユーザーの作成（分析用）
-- CREATE USER ga_novelist_readonly WITH PASSWORD 'your_readonly_password';
-- GRANT CONNECT ON DATABASE ga_novelist TO ga_novelist_readonly;
-- GRANT USAGE ON SCHEMA public TO ga_novelist_readonly;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO ga_novelist_readonly;