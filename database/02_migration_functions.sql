-- GA Novelist マイグレーション関数
-- データクリーンアップとメンテナンス用の関数

-- ========================================
-- 古いデータのクリーンアップ関数
-- ========================================
CREATE OR REPLACE FUNCTION cleanup_old_data(days_to_keep INTEGER DEFAULT 30)
RETURNS TABLE(
    table_name TEXT,
    deleted_count BIGINT
) AS $$
DECLARE
    cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    cutoff_date := CURRENT_TIMESTAMP - (days_to_keep || ' days')::INTERVAL;
    
    -- 古い変異履歴を削除
    DELETE FROM mutations WHERE created_at < cutoff_date;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    table_name := 'mutations';
    RETURN NEXT;
    
    -- 古いインタラクションログを削除（90日以上）
    DELETE FROM user_interactions WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    table_name := 'user_interactions';
    RETURN NEXT;
    
    -- 古い世代のテキストを間引き（1000世代以上前は10世代ごとに保持）
    DELETE FROM texts t
    WHERE t.room_id IN (SELECT id FROM rooms WHERE is_active = true)
    AND t.generation < (
        SELECT MAX(generation) - 1000 
        FROM texts 
        WHERE room_id = t.room_id
    )
    AND t.generation % 10 != 0;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    table_name := 'texts (thinning)';
    RETURN NEXT;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- ルームのアーカイブ関数
-- ========================================
CREATE OR REPLACE FUNCTION archive_room(room_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- ルームを非アクティブ化
    UPDATE rooms SET is_active = false WHERE id = room_uuid;
    
    -- 最新状態のスナップショットを作成
    INSERT INTO room_snapshots (room_id, name, generation, genome_data, text_content, is_milestone)
    SELECT 
        r.id,
        'Archive - ' || r.name,
        r.current_generation,
        row_to_json(g.*),
        t.content,
        true
    FROM rooms r
    LEFT JOIN genomes g ON r.id = g.room_id AND r.current_generation = g.generation
    LEFT JOIN texts t ON r.id = t.room_id AND r.current_generation = t.generation
    WHERE r.id = room_uuid;
    
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 統計情報の集計関数
-- ========================================
CREATE OR REPLACE FUNCTION get_room_statistics(room_uuid UUID)
RETURNS TABLE(
    total_generations INTEGER,
    total_mutations BIGINT,
    avg_text_length NUMERIC,
    most_used_operator TEXT,
    unique_users BIGINT,
    activity_last_24h BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT current_generation FROM rooms WHERE id = room_uuid),
        (SELECT COUNT(*) FROM mutations WHERE room_id = room_uuid),
        (SELECT AVG(content_length)::NUMERIC FROM texts WHERE room_id = room_uuid),
        (SELECT operator FROM mutations WHERE room_id = room_uuid GROUP BY operator ORDER BY COUNT(*) DESC LIMIT 1),
        (SELECT COUNT(DISTINCT actor_id) FROM mutations WHERE room_id = room_uuid),
        (SELECT COUNT(*) FROM mutations WHERE room_id = room_uuid AND created_at > CURRENT_TIMESTAMP - INTERVAL '24 hours');
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- データ整合性チェック関数
-- ========================================
CREATE OR REPLACE FUNCTION check_data_integrity()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- ルームとテキストの整合性チェック
    check_name := 'Room-Text Consistency';
    IF EXISTS (
        SELECT 1 FROM rooms r
        LEFT JOIN texts t ON r.id = t.room_id AND r.current_generation = t.generation
        WHERE r.is_active = true AND t.id IS NULL AND r.current_generation > 0
    ) THEN
        status := 'WARNING';
        details := 'Some active rooms are missing current generation text';
    ELSE
        status := 'OK';
        details := 'All active rooms have current text';
    END IF;
    RETURN NEXT;
    
    -- ゲノムの整合性チェック
    check_name := 'Genome Consistency';
    IF EXISTS (
        SELECT 1 FROM texts t
        LEFT JOIN genomes g ON t.room_id = g.room_id AND t.generation = g.generation
        WHERE g.id IS NULL
    ) THEN
        status := 'WARNING';
        details := 'Some texts are missing corresponding genomes';
    ELSE
        status := 'OK';
        details := 'All texts have corresponding genomes';
    END IF;
    RETURN NEXT;
    
    -- ストレージ使用量チェック
    check_name := 'Storage Usage';
    SELECT 
        CASE 
            WHEN pg_database_size(current_database()) > 10737418240 THEN 'WARNING'
            ELSE 'OK'
        END,
        pg_size_pretty(pg_database_size(current_database()))
    INTO status, details;
    RETURN NEXT;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- バックアップ用のエクスポート関数
-- ========================================
CREATE OR REPLACE FUNCTION export_room_data(room_uuid UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'room', row_to_json(r.*),
        'current_genome', row_to_json(g.*),
        'current_text', t.content,
        'recent_mutations', (
            SELECT jsonb_agg(row_to_json(m.*))
            FROM (
                SELECT * FROM mutations 
                WHERE room_id = room_uuid 
                ORDER BY created_at DESC 
                LIMIT 100
            ) m
        ),
        'snapshots', (
            SELECT jsonb_agg(row_to_json(s.*))
            FROM room_snapshots s
            WHERE room_id = room_uuid
        )
    ) INTO result
    FROM rooms r
    LEFT JOIN genomes g ON r.id = g.room_id AND r.current_generation = g.generation
    LEFT JOIN texts t ON r.id = t.room_id AND r.current_generation = t.generation
    WHERE r.id = room_uuid;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- パフォーマンス最適化関数
-- ========================================
CREATE OR REPLACE FUNCTION optimize_tables()
RETURNS VOID AS $$
BEGIN
    -- 統計情報を更新
    ANALYZE rooms;
    ANALYZE genomes;
    ANALYZE texts;
    ANALYZE mutations;
    ANALYZE room_snapshots;
    ANALYZE user_interactions;
    
    -- インデックスの再構築（必要に応じて）
    REINDEX TABLE rooms;
    REINDEX TABLE genomes;
    REINDEX TABLE texts;
    REINDEX TABLE mutations;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 定期実行用のメンテナンスジョブ
-- ========================================
-- pg_cronが利用可能な場合のスケジュール設定例
-- SELECT cron.schedule('cleanup-old-data', '0 2 * * *', $$SELECT cleanup_old_data(30)$$);
-- SELECT cron.schedule('optimize-tables', '0 3 * * 0', $$SELECT optimize_tables()$$);
-- SELECT cron.schedule('check-integrity', '0 1 * * *', $$SELECT check_data_integrity()$$);