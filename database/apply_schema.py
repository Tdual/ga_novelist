#!/usr/bin/env python3
"""
RDS PostgreSQL にスキーマを適用
"""
import psycopg2
import json

def apply_schema():
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
    
    # 自動コミットを有効化
    conn.autocommit = True
    cur = conn.cursor()
    
    print(f"🔗 Connected to {conn_info['endpoint']}")
    
    # スキーマファイルを読み込み
    with open('minimal_schema.sql', 'r') as f:
        schema_sql = f.read()
    
    # SQLを実行（個別のステートメントに分割）
    statements = [s.strip() for s in schema_sql.split(';') if s.strip()]
    
    for i, statement in enumerate(statements, 1):
        if statement:
            try:
                print(f"  Executing statement {i}/{len(statements)}...")
                cur.execute(statement)
            except psycopg2.errors.DuplicateTable as e:
                print(f"    ⚠️ Table already exists (skipping)")
            except psycopg2.errors.DuplicateObject as e:
                print(f"    ⚠️ Object already exists (skipping)")
            except Exception as e:
                print(f"    ❌ Error: {e}")
    
    print("\n✅ Schema applied successfully!")
    
    # テーブル一覧を確認
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
        ORDER BY table_name;
    """)
    
    tables = cur.fetchall()
    print(f"\n📊 Created tables ({len(tables)}):")
    for table in tables:
        print(f"  - {table[0]}")
    
    # ビュー一覧を確認
    cur.execute("""
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'public'
        ORDER BY table_name;
    """)
    
    views = cur.fetchall()
    if views:
        print(f"\n👁️ Created views ({len(views)}):")
        for view in views:
            print(f"  - {view[0]}")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    apply_schema()