#!/usr/bin/env python3
"""
青空文庫からコーパスデータを抽出してRDS PostgreSQLに投入
"""
import re
import json
import uuid
import psycopg2
import requests
import zipfile
import io
from collections import Counter, defaultdict
from typing import Dict, List, Tuple

# 青空文庫の作品情報
# 作品番号: (タイトル, 作者, ジャンル)
AOZORA_WORKS = {
    # horror
    '482': ('人間椅子', '江戸川乱歩', 'horror'),
    '427': ('芠虫', '江戸川乱步', 'horror'),
    '235': ('ドグラ・マグラ', '夢野久作', 'horror'),
    '4308': ('瓶詰地獄', '夢野久作', 'horror'),
    
    # romance  
    '756': ('みだれ髪', '与謝野晶子', 'romance'),
    '1569': ('たけくらべ', '樋口一葉', 'romance'),
    '1147': ('にごりえ', '樋口一葉', 'romance'),
    '1206': ('婦系図', '泉鏡花', 'romance'),
    
    # scifi
    '46897': ('地球盗難', '海野十三', 'scifi'),
    '456': ('銀河鉄道の夜', '宮沢賢治', 'scifi'),
    '461': ('風の又三郎', '宮沢賢治', 'scifi'),
    
    # comedy
    '275': ('走れメロス', '太宰治', 'comedy'),
    '312': ('山椒魚', '井伏鰒二', 'comedy'),
    
    # neutral
    '789': ('後少年', '夏目漱石', 'neutral'),
    '773': ('吾輩は猫である', '夏目漱石', 'neutral'),
    '879': ('羅生門', '芥川龍之介', 'neutral'),
    '74': ('蜜蛛の糸', '芥川龍之介', 'neutral'),
}

def download_aozora_text(work_id: str) -> str:
    """青空文庫からテキストをダウンロード"""
    # 青空文庫のGitHubからテキストを取得
    base_url = "https://www.aozora.gr.jp/cards/{author_id}/files/{work_id}_ruby.zip"
    
    # 作品IDから作者IDを推定（簡略化のため固定マッピング）
    author_map = {
        '482': '001779', '427': '001779',  # 江戸川乱歩
        '235': '000096', '4308': '000096',  # 夢野久作
        '756': '000885',  # 与謝野晶子
        '1569': '000064', '1147': '000064',  # 樋口一葉
        '1206': '001029',  # 泉鏡花
        '46897': '000160',  # 海野十三
        '456': '000081', '461': '000081',  # 宮沢賢治
        '275': '000035',  # 太宰治
        '312': '000058',  # 井伏鰒二
        '789': '000148', '773': '000148',  # 夏目漱石
        '879': '000879', '74': '000879',  # 芥川龍之介
    }
    
    author_id = author_map.get(work_id)
    if not author_id:
        print(f"⚠️ Work ID {work_id} not mapped to author")
        return ""
    
    url = base_url.format(author_id=author_id, work_id=work_id)
    
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        # ZIPファイルを展開
        with zipfile.ZipFile(io.BytesIO(response.content)) as z:
            # テキストファイルを探す
            for filename in z.namelist():
                if filename.endswith('.txt'):
                    with z.open(filename) as f:
                        # Shift-JISでデコード
                        content = f.read().decode('shift-jis', errors='ignore')
                        return content
    except Exception as e:
        print(f"❌ Failed to download work {work_id}: {e}")
        # フォールバック：テキスト直接取得を試みる
        try:
            txt_url = f"https://www.aozora.gr.jp/cards/{author_id}/files/{work_id}.txt"
            response = requests.get(txt_url, timeout=30)
            response.encoding = 'shift-jis'
            return response.text
        except:
            return ""
    
    return ""

def preprocess_aozora(raw_text: str) -> str:
    """青空文庫テキストの前処理"""
    # ヘッダー情報を除去（-------以降が本文）
    if '-------' in raw_text:
        parts = raw_text.split('-------')
        if len(parts) >= 2:
            raw_text = parts[-1]
    
    # ルビを除去: ｜漢字《かんじ》 → 漢字
    text = re.sub(r'｜([^《]+)《[^》]+》', r'\1', raw_text)
    text = re.sub(r'([^｜])《[^》]+》', r'\1', text)
    
    # 注記を除去: ［＃...］
    text = re.sub(r'［＃[^］]+］', '', text)
    
    # 空白行を整理
    text = re.sub(r'\n\s*\n+', '\n', text)
    
    # 前後の空白を除去
    text = text.strip()
    
    return text

def extract_words_by_genre(text: str, genre: str) -> Dict[str, List[str]]:
    """ジャンル別に単語を抽出（簡易版）"""
    # MeCabを使わずに正規表現で簡易抽出
    slots = {
        '主体': [],
        '場所': [],
        '発見物': [],
        '動作': [],
        '感情': [],
    }
    
    # ジャンル別のキーワードパターン
    patterns = {
        'horror': {
            '主体': ['幽霊', '影', '何者', '怪物', '黒い', '死者', '亡霊', '悪魔'],
            '場所': ['墓', '墓地', '墓場', '廃屋', '暗闇', '地下', '洞窟', '森'],
            '発見物': ['血', 'ナイフ', '刀', '骸', '死体', '日記', '手紙'],
            '動作': ['震え', '叫び', '叫ん', '逃げ', '襲い', 'うめき', '怖'],
            '感情': ['恐怖', '恐ろし', '不安', '不気味', '怖い', '怯え', '恐怖']
        },
        'romance': {
            '主体': ['君', 'あなた', '恋人', '彼', '彼女', '二人', '私たち'],
            '場所': ['公園', 'カフェ', '海', '橋', '駅', 'ベンチ', '教会'],
            '発見物': ['花', '手紙', '指輪', 'プレゼント', '写真', '日記'],
            '動作': ['抱き', 'キス', '手を', '微笑', '見つめ', '笑っ'],
            '感情': ['愛', '恋', '幸せ', '優し', '切な', '悲し', '嬉し']
        },
        'scifi': {
            '主体': ['ロボット', '機械', '宇宙', '科学者', '研究者', '博士'],
            '場所': ['宇宙', '研究所', '実験室', '火星', '月', '基地', '船'],
            '発見物': ['機械', '装置', 'データ', '電波', '信号', 'エネルギー'],
            '動作': ['分析', '計算', '観測', '実験', '発射', '探査'],
            '感情': ['驚き', '発見', '進歩', '未来', '科学的']
        },
        'comedy': {
            '主体': ['変な', 'おかしな', 'ドジ', 'マヌケ', 'おっちょこちょい'],
            '場所': ['舞台', 'サーカス', '祭', '広場', '市場'],
            '発見物': ['バナナ', 'パイ', '変な', 'おかしな'],
            '動作': ['転び', '転ん', '滑っ', 'ぶつか', '倒れ'],
            '感情': ['楽し', 'おかし', '笑', '面白', '愉快']
        },
        'neutral': {
            '主体': ['人', '彼', '彼女', '私', 'みんな', '先生', '子供'],
            '場所': ['部屋', '家', '学校', '公園', '街', '駅', '店'],
            '発見物': ['本', '手紙', '新聞', '時計', 'カバン', '写真'],
            '動作': ['歩く', '話す', '見る', '考える', '読む', '書く'],
            '感情': ['嬉し', '悲し', '驚', '不思議', '穏やか']
        }
    }
    
    # パターンマッチング
    genre_patterns = patterns.get(genre, patterns['neutral'])
    
    for slot_type, keywords in genre_patterns.items():
        for keyword in keywords:
            count = text.count(keyword)
            if count > 0:
                slots[slot_type].extend([keyword] * min(count, 3))  # 最大３回まで
    
    return slots

def extract_sentence_patterns(text: str, genre: str) -> List[str]:
    """文テンプレートを抽出"""
    templates = []
    
    # ジャンル別の文パターン
    if genre == 'horror':
        patterns = [
            r'(.+)が(.+)で(.+)を見つけた',
            r'(.+)は恐怖に(.+)',
            r'(.+)から(.+)が(.+)',
            r'暗闇の中(.+)',
        ]
    elif genre == 'romance':
        patterns = [
            r'(.+)は(.+)を愛して',
            r'(.+)が(.+)に微笑ん',
            r'(.+)と(.+)は',
            r'二人は(.+)',
        ]
    elif genre == 'scifi':
        patterns = [
            r'(.+)を分析(.+)',
            r'(.+)のデータ(.+)',
            r'システムが(.+)',
            r'(.+)を観測(.+)',
        ]
    else:
        patterns = [
            r'(.+)は(.+)である',
            r'(.+)が(.+)した',
            r'(.+)を(.+)して',
        ]
    
    # 文を抽出
    sentences = text.split('。')
    for sentence in sentences[:100]:  # 最初の100文のみ
        for pattern in patterns:
            if re.search(pattern, sentence):
                # スロット化
                template = re.sub(pattern, r'{主体}が{場所}で{発見物}を見つけた', sentence)
                if template not in templates:
                    templates.append(template)
                    if len(templates) >= 5:  # ジャンルごと５テンプレートまで
                        break
    
    return templates

def extract_phrases(text: str, genre: str) -> List[str]:
    """フレーズパターンを抽出"""
    phrases = []
    
    # ジャンル特有のフレーズ
    if genre == 'horror':
        phrase_patterns = ['背筋が凍', '血の気が', '闇の中', '怖いほど', '不気味な']
    elif genre == 'romance':
        phrase_patterns = ['愛して', '心が', '二人の', '永遠に', '優しく']
    elif genre == 'scifi':
        phrase_patterns = ['データに', 'システム', '分析', '未来', '科学']
    elif genre == 'comedy':
        phrase_patterns = ['ドタバタ', 'うっかり', 'たまたま', 'おっちょこちょい']
    else:
        phrase_patterns = ['それは', 'しかし', 'そして', 'だが', 'やがて']
    
    for pattern in phrase_patterns:
        if pattern in text:
            phrases.append(pattern)
    
    return phrases

def process_and_insert_to_db(conn_info: dict):
    """青空文庫データを処理してDBに投入"""
    # PostgreSQL接続
    conn = psycopg2.connect(
        host=conn_info['endpoint'],
        port=conn_info['port'],
        database=conn_info['database'],
        user=conn_info['username'],
        password=conn_info['password']
    )
    cur = conn.cursor()
    
    print("📚 青空文庫からコーパスデータを抽出中...")
    print("=" * 60)
    
    # ジャンル別に集計
    genre_data = defaultdict(lambda: {
        'words': defaultdict(list),
        'templates': [],
        'phrases': []
    })
    
    # 各作品を処理
    for work_id, (title, author, genre) in AOZORA_WORKS.items():
        print(f"\n📖 Processing: {title} by {author} ({genre})...")
        
        # テキストダウンロード
        text = download_aozora_text(work_id)
        if not text:
            print(f"  ⚠️ Skipped (download failed)")
            continue
        
        # 前処理
        text = preprocess_aozora(text)
        print(f"  ✅ Text length: {len(text)} chars")
        
        # 単語抽出
        words = extract_words_by_genre(text, genre)
        for slot_type, word_list in words.items():
            genre_data[genre]['words'][slot_type].extend(word_list)
        
        # 文テンプレート抽出
        templates = extract_sentence_patterns(text, genre)
        genre_data[genre]['templates'].extend(templates)
        
        # フレーズ抽出
        phrases = extract_phrases(text, genre)
        genre_data[genre]['phrases'].extend(phrases)
    
    print("\n" + "=" * 60)
    print("📦 データベースに投入中...")
    
    # DBに投入
    for genre, data in genre_data.items():
        print(f"\n🎨 Genre: {genre}")
        
        # 1. corpus_wordsに投入
        for slot_type, word_list in data['words'].items():
            if word_list:
                word_freq = Counter(word_list)
                for word, count in word_freq.most_common(20):  # 各スロット上位20語
                    weight = min(1.0, count / 10.0)
                    cur.execute("""
                        INSERT INTO corpus_words (id, genre, slot_type, word, weight)
                        VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT (genre, slot_type, word) 
                        DO UPDATE SET weight = GREATEST(corpus_words.weight, EXCLUDED.weight)
                    """, (str(uuid.uuid4()), genre, slot_type, word, weight))
        
        print(f"  ✅ Words inserted")
        
        # 2. sentence_templatesに投入
        unique_templates = list(set(data['templates']))[:5]  # 重複除去して上位5個
        for template in unique_templates:
            if template:
                cur.execute("""
                    INSERT INTO sentence_templates (id, template_type, template, genre)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (template_type, template) DO NOTHING
                """, (str(uuid.uuid4()), 'auto_extracted', template, genre))
        
        print(f"  ✅ Templates inserted")
        
        # 3. phrase_patternsに投入
        unique_phrases = list(set(data['phrases']))[:10]  # 重複除去して上位10個
        for phrase in unique_phrases:
            if phrase:
                cur.execute("""
                    INSERT INTO phrase_patterns (id, genre, phrase)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (genre, phrase) DO NOTHING
                """, (str(uuid.uuid4()), genre, phrase))
        
        print(f"  ✅ Phrases inserted")
    
    # コミット
    conn.commit()
    
    # 統計表示
    print("\n" + "=" * 60)
    print("📊 投入結果:")
    
    cur.execute("SELECT genre, COUNT(*) FROM corpus_words GROUP BY genre")
    for row in cur.fetchall():
        print(f"  corpus_words ({row[0]}): {row[1]} entries")
    
    cur.execute("SELECT genre, COUNT(*) FROM sentence_templates WHERE genre IS NOT NULL GROUP BY genre")
    for row in cur.fetchall():
        print(f"  templates ({row[0]}): {row[1]} entries")
    
    cur.execute("SELECT genre, COUNT(*) FROM phrase_patterns GROUP BY genre")
    for row in cur.fetchall():
        print(f"  phrases ({row[0]}): {row[1]} entries")
    
    print("\n✅ 青空文庫コーパスデータの投入完了！")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    # 接続情報を読み込み
    with open('rds_connection_info.json', 'r') as f:
        conn_info = json.load(f)
    
    # 処理実行
    process_and_insert_to_db(conn_info)