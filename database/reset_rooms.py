import boto3
import psycopg2
from datetime import datetime
import json
import uuid

# Database configuration
DB_CONFIG = {
    'host': 'ga-novelist-minimal.cknnl9s6ewvd.ap-northeast-1.rds.amazonaws.com',
    'port': 5432,
    'database': 'ga_novelist',
    'user': 'postgres',
    'password': 'GaNovelist2024!'
}

# 初期テキスト（全ルーム共通）
INITIAL_TEXT = """暗い森の奥で、少年は小さな光を見つけた。
それは不思議な輝きを放っていた。
手を伸ばすと、光は優しく脈動した。
その瞬間、物語が始まる予感がした。
運命の歯車が、静かに回り始めた。"""

# 初期ゲノム（全ルーム共通）
INITIAL_GENOME = {
    "genre_weights": {
        "neutral": 0.2,
        "horror": 0.2,
        "romance": 0.2,
        "scifi": 0.2,
        "comedy": 0.2
    },
    "style_params": {
        "complexity": 0.5,
        "coherence": 0.7,
        "creativity": 0.3
    },
    "character_traits": [],
    "setting_elements": [],
    "text_segments": [
        "暗い森の奥で、少年は小さな光を見つけた。",
        "それは不思議な輝きを放っていた。",
        "手を伸ばすと、光は優しく脈動した。",
        "その瞬間、物語が始まる予感がした。",
        "運命の歯車が、静かに回り始めた。"
    ],
    "seed_value": 42
}

def reset_all_rooms():
    """全てのルームをリセットして同じ初期状態にする"""
    
    try:
        # Connect to database
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # ルーム名リスト
        room_names = ['Room A', 'Room B', 'Room C', 'Room D']
        
        print("🔄 Resetting all rooms to initial state...")
        
        for room_name in room_names:
            # Check if room exists
            cursor.execute("SELECT id FROM rooms WHERE name = %s", (room_name,))
            result = cursor.fetchone()
            
            if result:
                room_id = result[0]
                
                # Delete existing texts and genomes for this room
                cursor.execute("DELETE FROM texts WHERE room_id = %s", (room_id,))
                cursor.execute("DELETE FROM genomes WHERE room_id = %s", (room_id,))
                cursor.execute("DELETE FROM mutations WHERE room_id = %s", (room_id,))
                
                # Update room to generation 0
                cursor.execute("""
                    UPDATE rooms 
                    SET current_generation = 0, updated_at = %s
                    WHERE id = %s
                """, (datetime.utcnow(), room_id))
                
                # Insert initial genome
                genome_id = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO genomes (id, room_id, generation, genome_data, mutation_count, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (genome_id, room_id, 0, json.dumps(INITIAL_GENOME), 0, datetime.utcnow()))
                
                # Insert initial text
                text_id = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO texts (id, room_id, generation, content, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                """, (text_id, room_id, 0, INITIAL_TEXT, datetime.utcnow()))
                
                print(f"  ✅ Reset {room_name}")
            else:
                print(f"  ❌ {room_name} not found")
        
        # Commit changes
        conn.commit()
        print("\n🎉 All rooms reset successfully!")
        print(f"📝 Initial text: '{INITIAL_TEXT[:50]}...'")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        if conn:
            conn.rollback()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    reset_all_rooms()