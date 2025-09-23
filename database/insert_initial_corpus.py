#!/usr/bin/env python3
"""
初期コーパスデータをRDS PostgreSQLに投入
"""
import psycopg2
import json
import uuid

def insert_initial_corpus():
    # 接続情報を読み込み
    with open('rds_connection_info.json', 'r') as f:
        conn_info = json.load(f)
    
    # PostgreSQLに接続
    conn = psycopg2.connect(
        host=conn_info['endpoint'],
        port=conn_info['port'],
        database=conn_info['database'],
        user=conn_info['username'],
        password=conn_info['password']
    )
    
    cur = conn.cursor()
    print(f"🔗 Connected to {conn_info['endpoint']}")
    
    # 1. corpus_words の初期データ
    corpus_words = [
        # neutral
        ('neutral', '主体', '人', 1.0),
        ('neutral', '主体', '彼', 0.9),
        ('neutral', '主体', '彼女', 0.9),
        ('neutral', '主体', '私', 0.8),
        ('neutral', '主体', 'みんな', 0.7),
        
        ('neutral', '場所', '部屋', 0.9),
        ('neutral', '場所', '公園', 0.8),
        ('neutral', '場所', '街', 0.8),
        ('neutral', '場所', '駅', 0.7),
        ('neutral', '場所', '家', 0.9),
        
        ('neutral', '発見物', '本', 0.8),
        ('neutral', '発見物', '手紙', 0.7),
        ('neutral', '発見物', 'カバン', 0.6),
        ('neutral', '発見物', '時計', 0.6),
        ('neutral', '発見物', '写真', 0.7),
        
        ('neutral', '動作', '歩く', 0.9),
        ('neutral', '動作', '見る', 0.9),
        ('neutral', '動作', '話す', 0.8),
        ('neutral', '動作', '考える', 0.7),
        ('neutral', '動作', '座る', 0.6),
        
        ('neutral', '感情', '嬉しい', 0.7),
        ('neutral', '感情', '悲しい', 0.7),
        ('neutral', '感情', '驚く', 0.6),
        ('neutral', '感情', '不思議', 0.6),
        ('neutral', '感情', '穏やか', 0.5),
        
        # horror
        ('horror', '主体', '影', 1.0),
        ('horror', '主体', '何者か', 0.9),
        ('horror', '主体', '幽霊', 0.8),
        ('horror', '主体', '怪物', 0.7),
        ('horror', '主体', '黒い男', 0.8),
        
        ('horror', '場所', '墓地', 1.0),
        ('horror', '場所', '廃屋', 0.9),
        ('horror', '場所', '暗闇', 0.9),
        ('horror', '場所', '地下室', 0.8),
        ('horror', '場所', '森の奥', 0.7),
        
        ('horror', '発見物', '血', 1.0),
        ('horror', '発見物', 'ナイフ', 0.8),
        ('horror', '発見物', '骸骨', 0.9),
        ('horror', '発見物', '人形', 0.7),
        ('horror', '発見物', '日記', 0.6),
        
        ('horror', '動作', '震える', 0.9),
        ('horror', '動作', '叫ぶ', 0.8),
        ('horror', '動作', '逃げる', 0.9),
        ('horror', '動作', '襲う', 0.7),
        ('horror', '動作', '心臓が凍る', 0.8),
        
        ('horror', '感情', '恐怖', 1.0),
        ('horror', '感情', '不安', 0.9),
        ('horror', '感情', '絶望', 0.8),
        ('horror', '感情', '恐ろしい', 0.9),
        ('horror', '感情', '不気味', 0.7),
        
        # romance
        ('romance', '主体', '恋人', 1.0),
        ('romance', '主体', '君', 0.9),
        ('romance', '主体', 'あなた', 0.9),
        ('romance', '主体', '二人', 0.8),
        ('romance', '主体', '彼氏', 0.7),
        
        ('romance', '場所', 'カフェ', 0.9),
        ('romance', '場所', '海辺', 0.8),
        ('romance', '場所', '公園のベンチ', 0.8),
        ('romance', '場所', '夜景', 0.7),
        ('romance', '場所', '橋の上', 0.7),
        
        ('romance', '発見物', '花束', 0.9),
        ('romance', '発見物', '指輪', 0.8),
        ('romance', '発見物', 'ラブレター', 0.7),
        ('romance', '発見物', 'プレゼント', 0.7),
        ('romance', '発見物', '写真', 0.6),
        
        ('romance', '動作', '抱きしめる', 0.9),
        ('romance', '動作', 'キスする', 0.8),
        ('romance', '動作', '手を繋ぐ', 0.8),
        ('romance', '動作', '微笑む', 0.7),
        ('romance', '動作', '見つめる', 0.7),
        
        ('romance', '感情', '愛', 1.0),
        ('romance', '感情', '幸せ', 0.9),
        ('romance', '感情', 'ときめき', 0.8),
        ('romance', '感情', '切ない', 0.7),
        ('romance', '感情', '優しい', 0.6),
        
        # scifi
        ('scifi', '主体', 'ロボット', 1.0),
        ('scifi', '主体', '宇宙人', 0.9),
        ('scifi', '主体', 'AI', 0.9),
        ('scifi', '主体', '科学者', 0.8),
        ('scifi', '主体', 'サイボーグ', 0.7),
        
        ('scifi', '場所', '宇宙船', 1.0),
        ('scifi', '場所', '研究所', 0.8),
        ('scifi', '場所', '火星', 0.9),
        ('scifi', '場所', 'コロニー', 0.7),
        ('scifi', '場所', '仮想空間', 0.8),
        
        ('scifi', '発見物', 'レーザー銃', 0.8),
        ('scifi', '発見物', 'チップ', 0.7),
        ('scifi', '発見物', 'ワームホール', 0.9),
        ('scifi', '発見物', 'データ', 0.7),
        ('scifi', '発見物', 'ホログラム', 0.6),
        
        ('scifi', '動作', 'スキャンする', 0.8),
        ('scifi', '動作', 'テレポートする', 0.9),
        ('scifi', '動作', 'ハッキングする', 0.7),
        ('scifi', '動作', '分析する', 0.7),
        ('scifi', '動作', '起動する', 0.6),
        
        ('scifi', '感情', '進歩的', 0.7),
        ('scifi', '感情', '論理的', 0.8),
        ('scifi', '感情', '未来的', 0.9),
        ('scifi', '感情', '革新的', 0.7),
        ('scifi', '感情', '冷静', 0.6),
        
        # comedy
        ('comedy', '主体', 'お笑い芸人', 0.9),
        ('comedy', '主体', 'ピエロ', 0.8),
        ('comedy', '主体', '変なオジサン', 0.7),
        ('comedy', '主体', 'マヌケ君', 0.8),
        ('comedy', '主体', 'ドジな子', 0.7),
        
        ('comedy', '場所', '舞台', 0.8),
        ('comedy', '場所', 'サーカス', 0.7),
        ('comedy', '場所', 'お祭り', 0.7),
        ('comedy', '場所', 'ゲームセンター', 0.6),
        ('comedy', '場所', 'バナナの皮', 0.9),
        
        ('comedy', '発見物', 'パイ', 0.8),
        ('comedy', '発見物', 'バナナ', 0.9),
        ('comedy', '発見物', 'ラッパ', 0.7),
        ('comedy', '発見物', '変な帽子', 0.6),
        ('comedy', '発見物', 'クッション', 0.6),
        
        ('comedy', '動作', '転ぶ', 0.9),
        ('comedy', '動作', '滑る', 0.8),
        ('comedy', '動作', 'コケる', 0.7),
        ('comedy', '動作', 'ボケる', 0.8),
        ('comedy', '動作', 'すっとぼける', 0.7),
        
        ('comedy', '感情', '楽しい', 1.0),
        ('comedy', '感情', 'おかしい', 0.9),
        ('comedy', '感情', 'ばかばかしい', 0.8),
        ('comedy', '感情', 'のんき', 0.7),
        ('comedy', '感情', 'ハッピー', 0.6),
    ]
    
    print("\n📦 Inserting corpus_words...")
    for genre, slot_type, word, weight in corpus_words:
        cur.execute("""
            INSERT INTO corpus_words (id, genre, slot_type, word, weight)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (genre, slot_type, word) DO NOTHING
        """, (str(uuid.uuid4()), genre, slot_type, word, weight))
    print(f"  ✅ Inserted {len(corpus_words)} words")
    
    # 2. sentence_templates の初期データ
    sentence_templates = [
        ('発見', '{主体}が{場所}で{発見物}を見つけた。', None),
        ('発見', '{場所}にあった{発見物}を{主体}が発見した。', None),
        ('感情', '{主体}は{感情}を感じた。', None),
        ('感情', 'それはとても{感情}だった。', None),
        ('行動', '{主体}は{場所}で{動作}。', None),
        ('行動', '{動作}。それが{主体}の選択だった。', None),
        ('描写', '{場所}は{感情}雰囲気に包まれていた。', None),
        ('描写', 'そこには{発見物}があった。', None),
        
        # ジャンル特化
        ('発見', '{主体}は{場所}で恐ろしい{発見物}を見つけてしまった。', 'horror'),
        ('感情', '{主体}の心臓は恐怖で凍りついた。', 'horror'),
        ('発見', '{主体}は{場所}で美しい{発見物}を受け取った。', 'romance'),
        ('感情', '{主体}の心は{感情}で満たされた。', 'romance'),
        ('発見', '{主体}は{場所}で高度な{発見物}を分析した。', 'scifi'),
        ('行動', '{主体}はシステムを{動作}。', 'scifi'),
        ('発見', '{主体}は{場所}でおかしな{発見物}を見つけて笑った。', 'comedy'),
        ('行動', '{主体}は{場所}で盛大に{動作}。', 'comedy'),
    ]
    
    print("\n📑 Inserting sentence_templates...")
    for template_type, template, genre in sentence_templates:
        cur.execute("""
            INSERT INTO sentence_templates (id, template_type, template, genre)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (template_type, template) DO NOTHING
        """, (str(uuid.uuid4()), template_type, template, genre))
    print(f"  ✅ Inserted {len(sentence_templates)} templates")
    
    # 3. phrase_patterns の初期データ
    phrase_patterns = [
        ('neutral', 'それは'),
        ('neutral', 'しかし'),
        ('neutral', 'そして'),
        ('neutral', 'だが'),
        ('neutral', 'やがて'),
        
        ('horror', '闇の中から'),
        ('horror', '血の匂いが'),
        ('horror', '背筋が凍るような'),
        ('horror', '不気味な音が'),
        ('horror', '恐怖に震えながら'),
        
        ('romance', '優しく'),
        ('romance', '愛おしく'),
        ('romance', '心がときめいて'),
        ('romance', '二人の時間は'),
        ('romance', '永遠に'),
        
        ('scifi', 'データによると'),
        ('scifi', 'システムが'),
        ('scifi', '量子的に'),
        ('scifi', 'AIの判断では'),
        ('scifi', '未来からの'),
        
        ('comedy', 'うっかり'),
        ('comedy', 'ドタバタと'),
        ('comedy', 'おっちょこちょい'),
        ('comedy', 'たまたま'),
        ('comedy', 'なぜか'),
    ]
    
    print("\n🎨 Inserting phrase_patterns...")
    for genre, phrase in phrase_patterns:
        cur.execute("""
            INSERT INTO phrase_patterns (id, genre, phrase)
            VALUES (%s, %s, %s)
            ON CONFLICT (genre, phrase) DO NOTHING
        """, (str(uuid.uuid4()), genre, phrase))
    print(f"  ✅ Inserted {len(phrase_patterns)} patterns")
    
    # 4. 初期ルームの作成（既存コードと互換性を保つため）
    initial_rooms = [
        ('Room A'),
        ('Room B'),
        ('Room C'),
        ('Room D')
    ]
    
    print("\n🏠 Inserting initial rooms...")
    for room_name in initial_rooms:
        # Check if room already exists
        cur.execute("SELECT id FROM rooms WHERE name = %s", (room_name,))
        if not cur.fetchone():
            cur.execute("""
                INSERT INTO rooms (id, name, current_generation)
                VALUES (%s, %s, %s)
            """, (str(uuid.uuid4()), room_name, 0))
    print(f"  ✅ Inserted {len(initial_rooms)} rooms")
    
    # コミット
    conn.commit()
    
    # 統計情報を表示
    print("\n📊 Database statistics:")
    
    cur.execute("SELECT COUNT(*) FROM corpus_words")
    word_count = cur.fetchone()[0]
    print(f"  - corpus_words: {word_count} entries")
    
    cur.execute("SELECT COUNT(*) FROM sentence_templates")
    template_count = cur.fetchone()[0]
    print(f"  - sentence_templates: {template_count} entries")
    
    cur.execute("SELECT COUNT(*) FROM phrase_patterns")
    phrase_count = cur.fetchone()[0]
    print(f"  - phrase_patterns: {phrase_count} entries")
    
    cur.execute("SELECT COUNT(*) FROM rooms")
    room_count = cur.fetchone()[0]
    print(f"  - rooms: {room_count} entries")
    
    print("\n✅ Initial corpus data inserted successfully!")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    insert_initial_corpus()