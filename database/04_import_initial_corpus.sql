-- 初期コーパスデータのインポート
-- corpus.jlの内容をデータベースに移行

-- アクティブなコーパスバージョンを取得（なければ作成）
DO $$
DECLARE
    v_corpus_id UUID;
    v_genre_id INTEGER;
BEGIN
    -- バージョン1.0.0を取得または作成
    SELECT id INTO v_corpus_id FROM corpus_versions WHERE version = '1.0.0';
    IF v_corpus_id IS NULL THEN
        INSERT INTO corpus_versions (version, description, is_active) 
        VALUES ('1.0.0', '初期コーパス（corpus.jlから移行）', true)
        RETURNING id INTO v_corpus_id;
    END IF;

    -- ========================================
    -- NEUTRAL（中立）ジャンルの単語
    -- ========================================
    SELECT id INTO v_genre_id FROM genres WHERE code = 'neutral';
    
    -- 主語
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '主語', '私'),
        (v_corpus_id, v_genre_id, '主語', '彼'),
        (v_corpus_id, v_genre_id, '主語', '彼女'),
        (v_corpus_id, v_genre_id, '主語', 'それ'),
        (v_corpus_id, v_genre_id, '主語', '誰か')
    ON CONFLICT DO NOTHING;
    
    -- 動詞
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '動詞', '歩く'),
        (v_corpus_id, v_genre_id, '動詞', '見る'),
        (v_corpus_id, v_genre_id, '動詞', '聞く'),
        (v_corpus_id, v_genre_id, '動詞', '話す'),
        (v_corpus_id, v_genre_id, '動詞', '考える')
    ON CONFLICT DO NOTHING;
    
    -- 目的語
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '目的語', '何か'),
        (v_corpus_id, v_genre_id, '目的語', 'それ'),
        (v_corpus_id, v_genre_id, '目的語', '言葉'),
        (v_corpus_id, v_genre_id, '目的語', '物'),
        (v_corpus_id, v_genre_id, '目的語', '音')
    ON CONFLICT DO NOTHING;
    
    -- 形容
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '形容', '大きな'),
        (v_corpus_id, v_genre_id, '形容', '小さな'),
        (v_corpus_id, v_genre_id, '形容', '新しい'),
        (v_corpus_id, v_genre_id, '形容', '古い'),
        (v_corpus_id, v_genre_id, '形容', '静かな')
    ON CONFLICT DO NOTHING;
    
    -- 場所
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '場所', '部屋'),
        (v_corpus_id, v_genre_id, '場所', '道'),
        (v_corpus_id, v_genre_id, '場所', '家'),
        (v_corpus_id, v_genre_id, '場所', '街'),
        (v_corpus_id, v_genre_id, '場所', '森')
    ON CONFLICT DO NOTHING;
    
    -- 時間
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '時間', '朝'),
        (v_corpus_id, v_genre_id, '時間', '昼'),
        (v_corpus_id, v_genre_id, '時間', '夜'),
        (v_corpus_id, v_genre_id, '時間', '今'),
        (v_corpus_id, v_genre_id, '時間', 'いつか')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- HORROR（ホラー）ジャンルの単語
    -- ========================================
    SELECT id INTO v_genre_id FROM genres WHERE code = 'horror';
    
    -- 主語
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '主語', '影', -0.6),
        (v_corpus_id, v_genre_id, '主語', '亡霊', -0.8),
        (v_corpus_id, v_genre_id, '主語', '何者か', -0.5),
        (v_corpus_id, v_genre_id, '主語', '闇', -0.7),
        (v_corpus_id, v_genre_id, '主語', '死者', -0.9)
    ON CONFLICT DO NOTHING;
    
    -- 動詞
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '動詞', '這い寄る', -0.7),
        (v_corpus_id, v_genre_id, '動詞', '潜む', -0.6),
        (v_corpus_id, v_genre_id, '動詞', '襲う', -0.9),
        (v_corpus_id, v_genre_id, '動詞', '囁く', -0.5),
        (v_corpus_id, v_genre_id, '動詞', '消える', -0.4)
    ON CONFLICT DO NOTHING;
    
    -- 形容
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '形容', '不気味な', -0.7),
        (v_corpus_id, v_genre_id, '形容', '恐ろしい', -0.8),
        (v_corpus_id, v_genre_id, '形容', '血まみれの', -0.9),
        (v_corpus_id, v_genre_id, '形容', '呪われた', -0.8),
        (v_corpus_id, v_genre_id, '形容', '薄暗い', -0.5)
    ON CONFLICT DO NOTHING;
    
    -- 場所
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '場所', '廃墟', -0.6),
        (v_corpus_id, v_genre_id, '場所', '墓地', -0.7),
        (v_corpus_id, v_genre_id, '場所', '地下室', -0.5),
        (v_corpus_id, v_genre_id, '場所', '病院', -0.4),
        (v_corpus_id, v_genre_id, '場所', '暗い森', -0.6)
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- ROMANCE（ロマンス）ジャンルの単語
    -- ========================================
    SELECT id INTO v_genre_id FROM genres WHERE code = 'romance';
    
    -- 主語
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '主語', '恋人', 0.8),
        (v_corpus_id, v_genre_id, '主語', '君', 0.7),
        (v_corpus_id, v_genre_id, '主語', 'あなた', 0.7),
        (v_corpus_id, v_genre_id, '主語', '二人', 0.6),
        (v_corpus_id, v_genre_id, '主語', '心', 0.5)
    ON CONFLICT DO NOTHING;
    
    -- 動詞
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '動詞', '愛する', 0.9),
        (v_corpus_id, v_genre_id, '動詞', '抱きしめる', 0.8),
        (v_corpus_id, v_genre_id, '動詞', '見つめる', 0.6),
        (v_corpus_id, v_genre_id, '動詞', '微笑む', 0.7),
        (v_corpus_id, v_genre_id, '動詞', 'ときめく', 0.8)
    ON CONFLICT DO NOTHING;
    
    -- 形容
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '形容', '美しい', 0.8),
        (v_corpus_id, v_genre_id, '形容', '優しい', 0.7),
        (v_corpus_id, v_genre_id, '形容', '甘い', 0.6),
        (v_corpus_id, v_genre_id, '形容', '温かい', 0.7),
        (v_corpus_id, v_genre_id, '形容', '輝く', 0.8)
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- SCIFI（SF）ジャンルの単語
    -- ========================================
    SELECT id INTO v_genre_id FROM genres WHERE code = 'scifi';
    
    -- 主語
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '主語', 'AI'),
        (v_corpus_id, v_genre_id, '主語', 'ロボット'),
        (v_corpus_id, v_genre_id, '主語', 'システム'),
        (v_corpus_id, v_genre_id, '主語', '宇宙船'),
        (v_corpus_id, v_genre_id, '主語', 'サイボーグ')
    ON CONFLICT DO NOTHING;
    
    -- 動詞
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '動詞', '計算する'),
        (v_corpus_id, v_genre_id, '動詞', '分析する'),
        (v_corpus_id, v_genre_id, '動詞', '接続する'),
        (v_corpus_id, v_genre_id, '動詞', 'ワープする'),
        (v_corpus_id, v_genre_id, '動詞', 'スキャンする')
    ON CONFLICT DO NOTHING;
    
    -- 場所
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word) VALUES
        (v_corpus_id, v_genre_id, '場所', '宇宙ステーション'),
        (v_corpus_id, v_genre_id, '場所', '研究所'),
        (v_corpus_id, v_genre_id, '場所', '未来都市'),
        (v_corpus_id, v_genre_id, '場所', '火星基地'),
        (v_corpus_id, v_genre_id, '場所', 'サイバー空間')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- COMEDY（コメディ）ジャンルの単語
    -- ========================================
    SELECT id INTO v_genre_id FROM genres WHERE code = 'comedy';
    
    -- 主語
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '主語', 'おじさん', 0.5),
        (v_corpus_id, v_genre_id, '主語', 'ペンギン', 0.6),
        (v_corpus_id, v_genre_id, '主語', '変な人', 0.5),
        (v_corpus_id, v_genre_id, '主語', 'ネコ', 0.6),
        (v_corpus_id, v_genre_id, '主語', '先生', 0.4)
    ON CONFLICT DO NOTHING;
    
    -- 動詞
    INSERT INTO word_slots (corpus_version_id, genre_id, slot_type, word, sentiment_score) VALUES
        (v_corpus_id, v_genre_id, '動詞', 'すっ転ぶ', 0.6),
        (v_corpus_id, v_genre_id, '動詞', 'ボケる', 0.5),
        (v_corpus_id, v_genre_id, '動詞', 'ツッコむ', 0.5),
        (v_corpus_id, v_genre_id, '動詞', 'ずっこける', 0.6),
        (v_corpus_id, v_genre_id, '動詞', '爆笑する', 0.8)
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- 文テンプレート
    -- ========================================
    
    -- 中立テンプレート
    SELECT id INTO v_genre_id FROM genres WHERE code = 'neutral';
    INSERT INTO sentence_templates (corpus_version_id, genre_id, template_type, template) VALUES
        (v_corpus_id, v_genre_id, 'opening', '{時間}、{主語}は{場所}にいた。'),
        (v_corpus_id, v_genre_id, 'action', '{主語}は{形容}{目的語}を{動詞}。'),
        (v_corpus_id, v_genre_id, 'dialogue', '「{目的語}を{動詞}のか？」と{主語}は言った。'),
        (v_corpus_id, v_genre_id, 'closing', 'そして{主語}は{動詞}のだった。')
    ON CONFLICT DO NOTHING;
    
    -- ホラーテンプレート
    SELECT id INTO v_genre_id FROM genres WHERE code = 'horror';
    INSERT INTO sentence_templates (corpus_version_id, genre_id, template_type, template) VALUES
        (v_corpus_id, v_genre_id, 'opening', '{形容}{場所}で、{主語}が{動詞}。'),
        (v_corpus_id, v_genre_id, 'action', '突然、{形容}{主語}が{動詞}始めた。'),
        (v_corpus_id, v_genre_id, 'dialogue', '「助けて...」{主語}の声が{場所}に響いた。'),
        (v_corpus_id, v_genre_id, 'closing', 'そして、すべてが{形容}闇に包まれた。')
    ON CONFLICT DO NOTHING;
    
    -- ロマンステンプレート
    SELECT id INTO v_genre_id FROM genres WHERE code = 'romance';
    INSERT INTO sentence_templates (corpus_version_id, genre_id, template_type, template) VALUES
        (v_corpus_id, v_genre_id, 'opening', '{形容}{時間}、{主語}は{動詞}。'),
        (v_corpus_id, v_genre_id, 'action', '{主語}の{形容}瞳が{動詞}。'),
        (v_corpus_id, v_genre_id, 'dialogue', '「{主語}、愛してる」'),
        (v_corpus_id, v_genre_id, 'closing', '二人は永遠に{動詞}のだった。')
    ON CONFLICT DO NOTHING;
    
    -- SFテンプレート
    SELECT id INTO v_genre_id FROM genres WHERE code = 'scifi';
    INSERT INTO sentence_templates (corpus_version_id, genre_id, template_type, template) VALUES
        (v_corpus_id, v_genre_id, 'opening', '西暦3000年、{場所}で{主語}が{動詞}。'),
        (v_corpus_id, v_genre_id, 'action', '{主語}のシステムが{目的語}を{動詞}。'),
        (v_corpus_id, v_genre_id, 'dialogue', '「エラー：{目的語}が検出されました」'),
        (v_corpus_id, v_genre_id, 'closing', 'ミッション完了。{主語}は{動詞}。')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- フレーズパターン
    -- ========================================
    
    -- ホラーフレーズ
    SELECT id INTO v_genre_id FROM genres WHERE code = 'horror';
    INSERT INTO phrase_patterns (corpus_version_id, genre_id, pattern_type, phrase) VALUES
        (v_corpus_id, v_genre_id, 'emotion', '背筋が凍るような'),
        (v_corpus_id, v_genre_id, 'emotion', '血の気が引く'),
        (v_corpus_id, v_genre_id, 'description', '腐敗した臭いが漂う'),
        (v_corpus_id, v_genre_id, 'metaphor', '死の影が忍び寄る')
    ON CONFLICT DO NOTHING;
    
    -- ロマンスフレーズ
    SELECT id INTO v_genre_id FROM genres WHERE code = 'romance';
    INSERT INTO phrase_patterns (corpus_version_id, genre_id, pattern_type, phrase) VALUES
        (v_corpus_id, v_genre_id, 'emotion', '胸がときめく'),
        (v_corpus_id, v_genre_id, 'emotion', '心が温かくなる'),
        (v_corpus_id, v_genre_id, 'description', 'バラの香りが漂う'),
        (v_corpus_id, v_genre_id, 'metaphor', '愛の炎が燃える')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- スタイル変換マトリックス
    -- ========================================
    
    -- 詩的変換
    INSERT INTO style_matrices (corpus_version_id, from_style, to_style, transformation_rules) VALUES
        (v_corpus_id, 'neutral', 'poetic', 
         '{"word_replacements": [
            {"from": "歩く", "to": "彷徨う", "probability": 0.7},
            {"from": "見る", "to": "見つめる", "probability": 0.6},
            {"from": "空", "to": "蒼穹", "probability": 0.5},
            {"from": "花", "to": "花びら", "probability": 0.4}
          ],
          "sentence_modifiers": [
            {"type": "add_metaphor", "templates": ["まるで{名詞}のような", "{名詞}のように"]}
          ]}'::jsonb)
    ON CONFLICT DO NOTHING;
    
    -- ホラー変換
    INSERT INTO style_matrices (corpus_version_id, from_style, to_style, transformation_rules) VALUES
        (v_corpus_id, 'neutral', 'horror',
         '{"word_replacements": [
            {"from": "森", "to": "不気味な森", "probability": 0.8},
            {"from": "家", "to": "廃屋", "probability": 0.6},
            {"from": "音", "to": "不吉な音", "probability": 0.7}
          ],
          "sentence_modifiers": [
            {"type": "add_adjective", "words": ["不気味な", "恐ろしい", "薄暗い"]}
          ]}'::jsonb)
    ON CONFLICT DO NOTHING;

    -- 訓練ログを記録
    INSERT INTO corpus_training_logs (
        corpus_version_id, 
        training_type, 
        source_description,
        words_added,
        templates_added,
        patterns_added,
        trained_by
    ) VALUES (
        v_corpus_id,
        'imported',
        'Initial import from corpus.jl',
        (SELECT COUNT(*) FROM word_slots WHERE corpus_version_id = v_corpus_id),
        (SELECT COUNT(*) FROM sentence_templates WHERE corpus_version_id = v_corpus_id),
        (SELECT COUNT(*) FROM phrase_patterns WHERE corpus_version_id = v_corpus_id),
        'system'
    );

END $$;