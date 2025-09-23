-- GA Novelist コーパスデータベーススキーマ
-- コーパス（語彙・文型データ）の永続化

-- ========================================
-- コーパス管理テーブル
-- ========================================
CREATE TABLE IF NOT EXISTS corpus_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMP WITH TIME ZONE
);

-- ========================================
-- ジャンル定義テーブル
-- ========================================
CREATE TABLE IF NOT EXISTS genres (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,  -- 'neutral', 'horror', 'romance', 'scifi', 'comedy'
    name_ja VARCHAR(50) NOT NULL,
    name_en VARCHAR(50) NOT NULL,
    description TEXT,
    color_code VARCHAR(7),  -- UI表示用の色
    sort_order INTEGER DEFAULT 0
);

-- ========================================
-- 単語スロット（word_slots）テーブル
-- ========================================
CREATE TABLE IF NOT EXISTS word_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    corpus_version_id UUID NOT NULL REFERENCES corpus_versions(id) ON DELETE CASCADE,
    genre_id INTEGER NOT NULL REFERENCES genres(id),
    slot_type VARCHAR(50) NOT NULL,  -- '主語', '動詞', '目的語', '形容', '場所', '時間'
    word TEXT NOT NULL,
    weight DECIMAL(3,2) DEFAULT 1.0,  -- 選択確率の重み
    
    -- メタデータ
    part_of_speech VARCHAR(20),  -- 品詞
    reading VARCHAR(100),  -- 読み仮名
    sentiment_score DECIMAL(3,2),  -- 感情スコア (-1.0 ~ 1.0)
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(corpus_version_id, genre_id, slot_type, word)
);

-- インデックス
CREATE INDEX idx_word_slots_lookup ON word_slots(corpus_version_id, genre_id, slot_type);
CREATE INDEX idx_word_slots_word ON word_slots(word);

-- ========================================
-- 文テンプレート（sentence_templates）テーブル
-- ========================================
CREATE TABLE IF NOT EXISTS sentence_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    corpus_version_id UUID NOT NULL REFERENCES corpus_versions(id) ON DELETE CASCADE,
    genre_id INTEGER NOT NULL REFERENCES genres(id),
    template_type VARCHAR(50) NOT NULL,  -- 'opening', 'action', 'dialogue', 'closing'
    
    -- テンプレート（プレースホルダー付き）
    template TEXT NOT NULL,  -- 例: '{主語}は{場所}で{動詞}。'
    
    -- 使用条件
    min_generation INTEGER DEFAULT 0,
    max_generation INTEGER,
    required_slots TEXT[],  -- 必須スロット
    
    weight DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(corpus_version_id, genre_id, template)
);

-- インデックス
CREATE INDEX idx_sentence_templates_lookup ON sentence_templates(corpus_version_id, genre_id, template_type);

-- ========================================
-- フレーズパターン（phrase_patterns）テーブル
-- ========================================
CREATE TABLE IF NOT EXISTS phrase_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    corpus_version_id UUID NOT NULL REFERENCES corpus_versions(id) ON DELETE CASCADE,
    genre_id INTEGER NOT NULL REFERENCES genres(id),
    pattern_type VARCHAR(50) NOT NULL,  -- 'metaphor', 'description', 'emotion'
    
    phrase TEXT NOT NULL,
    context_tags TEXT[],  -- 使用可能な文脈タグ
    
    weight DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_phrase_patterns_lookup ON phrase_patterns(corpus_version_id, genre_id, pattern_type);

-- ========================================
-- スタイル変換マトリックス（style_matrices）テーブル
-- ========================================
CREATE TABLE IF NOT EXISTS style_matrices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    corpus_version_id UUID NOT NULL REFERENCES corpus_versions(id) ON DELETE CASCADE,
    
    from_style VARCHAR(50) NOT NULL,
    to_style VARCHAR(50) NOT NULL,
    
    -- 変換ルール（JSONB形式）
    transformation_rules JSONB NOT NULL,
    /* 例:
    {
        "word_replacements": [
            {"from": "歩く", "to": "彷徨う", "probability": 0.7},
            {"from": "見る", "to": "凝視する", "probability": 0.5}
        ],
        "sentence_modifiers": [
            {"type": "add_adjective", "words": ["不気味な", "薄暗い"]},
            {"type": "change_ending", "pattern": "...だった"}
        ]
    }
    */
    
    strength DECIMAL(3,2) DEFAULT 1.0,  -- 変換の強度
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(corpus_version_id, from_style, to_style)
);

-- ========================================
-- キャラクター名プール
-- ========================================
CREATE TABLE IF NOT EXISTS character_names (
    id SERIAL PRIMARY KEY,
    corpus_version_id UUID NOT NULL REFERENCES corpus_versions(id) ON DELETE CASCADE,
    genre_id INTEGER REFERENCES genres(id),
    
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    full_name VARCHAR(100),
    
    gender VARCHAR(10),  -- 'male', 'female', 'neutral'
    name_type VARCHAR(20),  -- 'japanese', 'western', 'fantasy'
    
    weight DECIMAL(3,2) DEFAULT 1.0,
    
    UNIQUE(corpus_version_id, full_name)
);

-- ========================================
-- 場所・設定要素プール
-- ========================================
CREATE TABLE IF NOT EXISTS setting_elements (
    id SERIAL PRIMARY KEY,
    corpus_version_id UUID NOT NULL REFERENCES corpus_versions(id) ON DELETE CASCADE,
    genre_id INTEGER REFERENCES genres(id),
    
    element_type VARCHAR(50) NOT NULL,  -- 'location', 'time_period', 'weather', 'atmosphere'
    element_value TEXT NOT NULL,
    element_value_detail JSONB,  -- 追加の詳細情報
    
    weight DECIMAL(3,2) DEFAULT 1.0,
    
    UNIQUE(corpus_version_id, element_type, element_value)
);

-- ========================================
-- コーパス学習履歴
-- ========================================
CREATE TABLE IF NOT EXISTS corpus_training_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    corpus_version_id UUID NOT NULL REFERENCES corpus_versions(id) ON DELETE CASCADE,
    
    training_type VARCHAR(50) NOT NULL,  -- 'manual', 'generated', 'imported'
    source_description TEXT,
    
    -- 統計情報
    words_added INTEGER DEFAULT 0,
    templates_added INTEGER DEFAULT 0,
    patterns_added INTEGER DEFAULT 0,
    
    trained_by VARCHAR(100),
    trained_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- 初期データ投入
-- ========================================

-- ジャンルマスタ
INSERT INTO genres (code, name_ja, name_en, description, color_code, sort_order) VALUES
    ('neutral', '中立', 'Neutral', '基本的な語彙', '#808080', 0),
    ('horror', 'ホラー', 'Horror', '恐怖・サスペンス要素', '#8B0000', 1),
    ('romance', 'ロマンス', 'Romance', '恋愛・感動要素', '#FF69B4', 2),
    ('scifi', 'SF', 'Sci-Fi', 'SF・未来要素', '#4169E1', 3),
    ('comedy', 'コメディ', 'Comedy', 'ユーモア・笑い要素', '#FF8C00', 4),
    ('mystery', 'ミステリー', 'Mystery', '推理・謎解き要素', '#4B0082', 5),
    ('fantasy', 'ファンタジー', 'Fantasy', '魔法・幻想要素', '#9370DB', 6)
ON CONFLICT (code) DO NOTHING;

-- 初期コーパスバージョン
INSERT INTO corpus_versions (version, description, is_active) VALUES
    ('1.0.0', '初期コーパス', true)
ON CONFLICT (version) DO NOTHING;

-- ========================================
-- コーパスインポート用関数
-- ========================================
CREATE OR REPLACE FUNCTION import_corpus_from_json(
    corpus_data JSONB,
    version_name VARCHAR DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    new_version_id UUID;
    genre_record RECORD;
    word_slot JSONB;
BEGIN
    -- 新しいバージョンを作成
    INSERT INTO corpus_versions (version, description, is_active)
    VALUES (
        COALESCE(version_name, 'import_' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISS')),
        'Imported from JSON at ' || CURRENT_TIMESTAMP,
        false
    )
    RETURNING id INTO new_version_id;
    
    -- word_slotsをインポート
    IF corpus_data ? 'word_slots' THEN
        FOR genre_record IN SELECT * FROM genres LOOP
            IF corpus_data->'word_slots' ? genre_record.code THEN
                FOR word_slot IN SELECT * FROM jsonb_each(corpus_data->'word_slots'->genre_record.code) LOOP
                    -- 各スロットタイプの単語を挿入
                    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word)
                    SELECT 
                        new_version_id,
                        genre_record.id,
                        word_slot.key,
                        jsonb_array_elements_text(word_slot.value)
                    ON CONFLICT DO NOTHING;
                END LOOP;
            END IF;
        END LOOP;
    END IF;
    
    -- sentence_templatesをインポート
    IF corpus_data ? 'sentence_templates' THEN
        FOR genre_record IN SELECT * FROM genres LOOP
            IF corpus_data->'sentence_templates' ? genre_record.code THEN
                INSERT INTO sentence_templates (corpus_version_id, genre_id, template_type, template)
                SELECT
                    new_version_id,
                    genre_record.id,
                    'general',
                    jsonb_array_elements_text(corpus_data->'sentence_templates'->genre_record.code)
                ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
    END IF;
    
    RETURN new_version_id;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- コーパス活性化関数
-- ========================================
CREATE OR REPLACE FUNCTION activate_corpus_version(version_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- 現在のアクティブバージョンを非活性化
    UPDATE corpus_versions SET is_active = false WHERE is_active = true;
    
    -- 指定バージョンを活性化
    UPDATE corpus_versions 
    SET is_active = true, activated_at = CURRENT_TIMESTAMP
    WHERE id = version_id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- コーパス検索関数
-- ========================================
CREATE OR REPLACE FUNCTION get_random_words(
    p_genre VARCHAR,
    p_slot_type VARCHAR,
    p_count INTEGER DEFAULT 1
) RETURNS TABLE(word TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT ws.word
    FROM word_slots ws
    JOIN genres g ON ws.genre_id = g.id
    JOIN corpus_versions cv ON ws.corpus_version_id = cv.id
    WHERE cv.is_active = true
    AND g.code = p_genre
    AND ws.slot_type = p_slot_type
    ORDER BY RANDOM() * ws.weight DESC
    LIMIT p_count;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- ビュー：アクティブコーパス
-- ========================================
CREATE OR REPLACE VIEW active_corpus AS
SELECT 
    g.code as genre,
    ws.slot_type,
    ws.word,
    ws.weight,
    ws.sentiment_score
FROM word_slots ws
JOIN genres g ON ws.genre_id = g.id
JOIN corpus_versions cv ON ws.corpus_version_id = cv.id
WHERE cv.is_active = true;

-- ========================================
-- ビュー：コーパス統計
-- ========================================
CREATE OR REPLACE VIEW corpus_statistics AS
SELECT 
    cv.version,
    cv.is_active,
    COUNT(DISTINCT ws.id) as total_words,
    COUNT(DISTINCT st.id) as total_templates,
    COUNT(DISTINCT pp.id) as total_patterns,
    cv.created_at,
    cv.activated_at
FROM corpus_versions cv
LEFT JOIN word_slots ws ON cv.id = ws.corpus_version_id
LEFT JOIN sentence_templates st ON cv.id = st.corpus_version_id
LEFT JOIN phrase_patterns pp ON cv.id = pp.corpus_version_id
GROUP BY cv.id, cv.version, cv.is_active, cv.created_at, cv.activated_at;