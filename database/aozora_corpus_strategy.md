# 青空文庫からコーパステーブルへのデータ投入戦略

## 1. データソースとジャンル分類

### ジャンル別作家選定
```yaml
horror:
  authors:
    - 江戸川乱歩: ["人間椅子", "芋虫", "押絵と旅する男"]
    - 夢野久作: ["ドグラ・マグラ", "瓶詰地獄"]
    - 岡本綺堂: ["半七捕物帳"]
    - 小泉八雲: ["怪談"]

romance:
  authors:
    - 与謝野晶子: ["みだれ髪"]
    - 樋口一葉: ["たけくらべ", "にごりえ"]
    - 泉鏡花: ["婦系図", "高野聖"]
    - 有島武郎: ["或る女"]

scifi:
  authors:
    - 海野十三: ["地球盗難", "火星兵団"]
    - 宮沢賢治: ["銀河鉄道の夜"]
    - 寺田寅彦: 科学エッセイ

comedy:
  authors:
    - 太宰治: ["走れメロス", "人間失格"] # 皮肉やユーモア要素
    - 井伏鱒二: ["山椒魚"]

neutral:
  authors:
    - 夏目漱石: ["坊っちゃん", "吾輩は猫である"]
    - 芥川龍之介: ["羅生門", "蜘蛛の糸"]
```

## 2. データ取得方法

### 方法1: 青空文庫GitHub（推奨）
```bash
# 青空文庫のGitHubリポジトリ
git clone https://github.com/aozorabunko/aozorabunko.git

# テキストファイルは cards/[作者ID]/files/[作品ID]_ruby.zip
```

### 方法2: 青空文庫APIサービス
```python
# 非公式APIサービスを利用
import requests

def fetch_aozora_text(work_id):
    # 青空文庫テキストの取得
    url = f"https://www.aozora.gr.jp/cards/{author_id}/files/{work_id}_ruby.zip"
    # または bunko.jp のAPI
    return text
```

## 3. テキスト処理パイプライン

### Step 1: テキスト前処理
```python
import re
import zipfile
import mojimoji  # 全角半角変換

def preprocess_aozora(raw_text):
    # ルビを除去: ｜漢字《かんじ》 → 漢字
    text = re.sub(r'｜([^《]+)《[^》]+》', r'\1', raw_text)
    text = re.sub(r'([^｜])《[^》]+》', r'\1', text)
    
    # 注記を除去: ［＃...］
    text = re.sub(r'［＃[^］]+］', '', text)
    
    # 全角英数を半角に
    text = mojimoji.zen_to_han(text, kana=False)
    
    return text
```

### Step 2: 形態素解析
```python
import MeCab
import pandas as pd

def analyze_text(text):
    mecab = MeCab.Tagger()
    
    words_by_pos = {
        '名詞': [],
        '動詞': [],
        '形容詞': [],
        '副詞': []
    }
    
    parsed = mecab.parse(text)
    for line in parsed.split('\n'):
        if '\t' in line:
            word, features = line.split('\t')
            pos = features.split(',')[0]
            
            if pos in words_by_pos:
                words_by_pos[pos].append(word)
    
    return words_by_pos
```

### Step 3: スロット分類
```python
def classify_words_to_slots(words_by_pos, genre):
    slots = {
        '主体': [],      # 名詞-固有名詞、名詞-一般（人物）
        '場所': [],      # 名詞-場所
        '発見物': [],    # 名詞-一般（物体）
        '動作': [],      # 動詞
        '感情': [],      # 形容詞、感情を表す名詞
        '時間': [],      # 時間を表す名詞
        '形容': []       # 形容詞、形容動詞
    }
    
    # ジャンル別の重み付け
    if genre == 'horror':
        # ホラー特有の単語を優先
        horror_keywords = ['闇', '血', '死', '恐怖', '影', '呪い']
        # フィルタリングと重み付け
    
    return slots
```

### Step 4: 文テンプレート抽出
```python
def extract_sentence_patterns(sentences):
    templates = []
    
    for sentence in sentences:
        # 文を形態素解析
        parsed = mecab.parse(sentence)
        
        # パターン化（名詞→{名詞}、動詞→{動詞}）
        pattern = sentence
        pattern = re.sub(r'名詞部分', '{主体}', pattern)
        pattern = re.sub(r'動詞部分', '{動作}', pattern)
        
        templates.append(pattern)
    
    return templates
```

### Step 5: フレーズパターン抽出
```python
def extract_phrases(text, genre):
    # ジャンル特有の表現を抽出
    phrases = []
    
    if genre == 'horror':
        # ホラー特有のフレーズパターン
        patterns = [
            r'.*が.*凍る',
            r'.*の影が.*',
            r'不気味な.*'
        ]
    
    for pattern in patterns:
        matches = re.findall(pattern, text)
        phrases.extend(matches[:5])  # 上位5個
    
    return phrases
```

## 4. データベース投入

### PostgreSQLへの投入
```python
import psycopg2
import json

def insert_corpus_data(conn, genre, slots, templates, phrases):
    cur = conn.cursor()
    
    # 1. corpus_words への投入
    for slot_type, words in slots.items():
        word_freq = Counter(words)
        for word, count in word_freq.most_common(100):  # 上位100語
            weight = min(1.0, count / 100)  # 頻度を重みに変換
            
            cur.execute("""
                INSERT INTO corpus_words (genre, slot_type, word, weight)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (genre, slot_type, word) 
                DO UPDATE SET weight = GREATEST(corpus_words.weight, EXCLUDED.weight)
            """, (genre, slot_type, word, weight))
    
    # 2. sentence_templates への投入
    for template in templates[:50]:  # 上位50テンプレート
        cur.execute("""
            INSERT INTO sentence_templates (template_type, template, genre)
            VALUES (%s, %s, %s)
            ON CONFLICT DO NOTHING
        """, ('auto_extracted', template, genre))
    
    # 3. phrase_patterns への投入
    for phrase in phrases[:30]:  # 上位30フレーズ
        cur.execute("""
            INSERT INTO phrase_patterns (genre, phrase)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
        """, (genre, phrase))
    
    conn.commit()
```

## 5. 実行計画

### Phase 1: 初期データ（1週間）
1. 各ジャンル2-3作品を選定
2. 基本的な単語辞書を構築
3. 手動で調整

### Phase 2: 拡張（1ヶ月）
1. 全作品を処理
2. 機械学習による最適化
3. ユーザーフィードバックの反映

### Phase 3: 自動化（継続的）
1. 定期的な更新
2. 新作品の追加
3. 動的な重み調整

## 6. 実装スクリプト例

```python
# main.py
def process_aozora_to_db():
    # 1. 作品リストの取得
    works = {
        'horror': ['ranpo_001.txt', 'yumeno_001.txt'],
        'romance': ['akiko_001.txt', 'ichiyo_001.txt'],
        # ...
    }
    
    # 2. DB接続
    conn = psycopg2.connect(
        host='rds-endpoint.amazonaws.com',
        database='ga_novelist',
        user='admin',
        password='password'
    )
    
    # 3. ジャンル別処理
    for genre, files in works.items():
        all_slots = defaultdict(list)
        all_templates = []
        all_phrases = []
        
        for file in files:
            # テキスト読み込み
            text = load_aozora_text(file)
            text = preprocess_aozora(text)
            
            # 解析
            words = analyze_text(text)
            slots = classify_words_to_slots(words, genre)
            templates = extract_sentence_patterns(text)
            phrases = extract_phrases(text, genre)
            
            # 集計
            for slot_type, words in slots.items():
                all_slots[slot_type].extend(words)
            all_templates.extend(templates)
            all_phrases.extend(phrases)
        
        # DB投入
        insert_corpus_data(conn, genre, all_slots, all_templates, all_phrases)
    
    conn.close()
```

## 7. 品質管理

### データクレンジング
- 不適切な単語の除外
- 現代語への変換オプション
- 重複の除去

### バランス調整
- ジャンル間の単語数バランス
- 頻度による重み付け
- 希少語の保護

### 評価指標
- 生成文の自然さ
- ジャンル特徴の再現度
- 語彙の多様性

## 8. 必要なツール

```bash
# Python環境
pip install mecab-python3
pip install mojimoji
pip install psycopg2-binary
pip install pandas numpy

# MeCabのインストール
brew install mecab
brew install mecab-ipadic  # 辞書

# または
apt-get install mecab libmecab-dev mecab-ipadic-utf8
```