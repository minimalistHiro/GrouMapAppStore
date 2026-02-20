---
name: remove-background
description: 「背景を透明化して」「背景を透過して」「背景を削除して」「背景を除去して」「画像の背景を消して」など、画像の背景透明化・透過処理を依頼されたときに、rembgを使って背景を自動除去する。
---

# 背景透明化スキル

## 目的

ユーザーから画像の背景透明化を依頼されたときに、rembg（ローカル実行）を使って背景を透過処理する。

## 前提

- `rembg` がインストールされている必要がある（`pip install "rembg[cpu]"`）
- ローカル実行のため、APIキー不要・回数制限なし
- 処理済みファイルは元ファイルを上書きする

## 対応パターン

### 1. 単一ファイルの背景透過

ユーザーが特定の画像ファイルを指定した場合:

```python
python3 -c "
from rembg import remove
input_path = '指定されたファイルパス'
with open(input_path, 'rb') as f:
    data = f.read()
with open(input_path, 'wb') as f:
    f.write(remove(data))
print('Done:', input_path)
"
```

### 2. バッジ画像の一括背景透過

バッジ画像を一括で透過処理する場合は、専用スクリプトを使用する:

```bash
python3 /Users/kanekohiroki/Desktop/groumapapp/scripts/rembg_batch.py
```

- 対象ディレクトリ: `assets/images/badges/`
- 処理済みファイルはスキップされる
- 元ファイルを上書きする

### 3. 指定ディレクトリの一括背景透過

バッジ以外のディレクトリを指定された場合は、以下のようにインラインで処理する:

```python
python3 -c "
import os
from rembg import remove

target_dir = '指定されたディレクトリパス'
files = sorted(f for f in os.listdir(target_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')))
total = len(files)
print(f'=== 背景透過処理 ===')
print(f'対象: {total}枚')
print()

success = 0
fail = 0

for i, filename in enumerate(files, 1):
    filepath = os.path.join(target_dir, filename)
    print(f'[{i}/{total}] {filename} ... ', end='', flush=True)
    try:
        with open(filepath, 'rb') as f:
            input_data = f.read()
        output_data = remove(input_data)
        # PNGとして保存（透過対応）
        out_path = os.path.splitext(filepath)[0] + '.png'
        with open(out_path, 'wb') as f:
            f.write(output_data)
        print('OK')
        success += 1
    except Exception as e:
        print(f'FAIL ({e})')
        fail += 1

print()
print(f'=== 処理完了 ===')
print(f'成功: {success}枚 / 失敗: {fail}枚 / 合計: {total}枚')
"
```

## 手順

1. ユーザーの依頼内容を確認し、対象ファイル/ディレクトリを特定する。
   - 特定のファイルが指定されている → **単一ファイル処理**
   - 「バッジ」「バッジ画像」と言われた場合 → **バッジ一括処理**（専用スクリプト）
   - ディレクトリが指定されている → **ディレクトリ一括処理**
   - 何も指定がない場合 → ユーザーに対象を確認する

2. 上記の対応パターンに従ってコマンドを実行する。

3. 処理結果を報告する（成功/失敗の枚数）。

4. 処理後の画像を Read ツールで表示し、ユーザーに確認してもらう。

## 注意事項

- 元ファイルを上書きするため、必要に応じて事前にバックアップの確認を行う。
- JPG/JPEG/WebP形式の入力も対応するが、出力は常にPNG（透過対応のため）。
- 大量のファイル処理は時間がかかる場合がある（1枚あたり数秒〜十数秒）。
- rembgが未インストールの場合は `pip install "rembg[cpu]"` を実行してからリトライする。
