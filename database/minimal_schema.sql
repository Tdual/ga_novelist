-- GA Novelist 最小限のデータベーススキーマ
-- PostgreSQL 15.x
-- 現在のソースコードで実際に必要なテーブルのみ

-- データベース作成
-- CREATE DATABASE ga_novelist;

-- 拡張機能
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================================
-- 1. ルームテーブル（必須）
-- ========================================
CREATE TABLE IF NOT EXISTS rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    current_generation INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rooms_name ON rooms(name);

-- ========================================
-- 2. ゲノムテーブル（世代ごとの状態保存）
-- ========================================
CREATE TABLE IF NOT EXISTS genomes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    generation INTEGER NOT NULL,
    
    -- TextGenomeの内容をJSONBで保存
    genome_data JSONB NOT NULL, -- genre_weights, style_params, character_traits, setting_elements, text_segments
    mutation_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(room_id, generation)
);

CREATE INDEX idx_genomes_room_generation ON genomes(room_id, generation DESC);

-- ========================================
-- 3. テキスト履歴テーブル（生成されたテキスト）
-- ========================================
CREATE TABLE IF NOT EXISTS texts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    generation INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(room_id, generation)
);

CREATE INDEX idx_texts_room_generation ON texts(room_id, generation DESC);

-- ========================================
-- 4. 変更履歴テーブル（nudge_history相当）
-- ========================================
CREATE TABLE IF NOT EXISTS mutations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    operator VARCHAR(50) NOT NULL, -- 'horror', 'romance', 'scifi', etc.
    actor VARCHAR(100) DEFAULT 'anonymous',
    generation_before INTEGER NOT NULL,
    generation_after INTEGER NOT NULL,
    text_preview TEXT, -- 変更後のテキストプレビュー（最初の100文字）
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mutations_room ON mutations(room_id, created_at DESC);

-- ========================================
-- 5. コーパステーブル（単語辞書）
-- ========================================
CREATE TABLE IF NOT EXISTS corpus_words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    genre VARCHAR(20) NOT NULL, -- 'neutral', 'horror', 'romance', 'scifi', 'comedy'
    slot_type VARCHAR(50) NOT NULL, -- '主体', '場所', '発見物', '動作', '感情', etc.
    word TEXT NOT NULL,
    weight DECIMAL(3,2) DEFAULT 1.0,
    
    UNIQUE(genre, slot_type, word)
);

CREATE INDEX idx_corpus_words_lookup ON corpus_words(genre, slot_type);

-- ========================================
-- 6. 文テンプレートテーブル
-- ========================================
CREATE TABLE IF NOT EXISTS sentence_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_type VARCHAR(50) NOT NULL, -- '発見', '感情', '行動', '描写'
    template TEXT NOT NULL, -- '{主体}は{場所}で{発見物}を見つけた。'
    genre VARCHAR(20), -- オプショナル：特定ジャンル用
    
    UNIQUE(template_type, template)
);

-- ========================================
-- 7. フレーズパターンテーブル
-- ========================================
CREATE TABLE IF NOT EXISTS phrase_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    genre VARCHAR(20) NOT NULL,
    phrase TEXT NOT NULL,
    
    UNIQUE(genre, phrase)
);

-- ========================================
-- ビュー：最新状態の取得
-- ========================================
CREATE OR REPLACE VIEW current_room_states AS
SELECT 
    r.id,
    r.name,
    r.current_generation,
    t.content as current_text,
    g.genome_data,
    g.mutation_count,
    r.updated_at
FROM rooms r
LEFT JOIN LATERAL (
    SELECT * FROM texts 
    WHERE room_id = r.id 
    ORDER BY generation DESC 
    LIMIT 1
) t ON true
LEFT JOIN LATERAL (
    SELECT * FROM genomes 
    WHERE room_id = r.id 
    ORDER BY generation DESC 
    LIMIT 1
) g ON true;

-- ========================================
-- 初期ルームの作成
-- ========================================
INSERT INTO rooms (name) VALUES 
    ('Room A'),
    ('Room B'),
    ('Room C'),
    ('Room D')
ON CONFLICT DO NOTHING;