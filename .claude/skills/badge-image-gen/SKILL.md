---
name: badge-image-gen
description: 「バッジを生成して」「バッジ画像を作って」「バッジアイコンを生成して」など、バッジ画像の生成依頼時に、統一されたバッジデザインテンプレートを使って画像を自動生成する。
---

# バッジ画像生成スキル

## 目的

ユーザーからバッジ画像の生成を依頼されたときに、統一されたデザインテンプレートを使って一貫性のあるバッジ画像を自動生成する。

## 前提

- 画像生成自体は Nano Banana Pro（Gemini 3 Pro Image）API を使用する。
- 生成スクリプト: `/Users/kanekohiroki/Desktop/groumapapp/scripts/generate_image.py`
- バッジ定義一覧: `/Users/kanekohiroki/Desktop/groumapapp/BADGE_LIST.md`
- 参考画像（デザイン基準）: `/Users/kanekohiroki/Desktop/groumapapp/assets/images/badges/stamps_total_1.png`

## 手順

1. `BADGE_LIST.md` を読み取り、生成対象のバッジ情報を確認する。
   - バッジID、名前、獲得条件、レア度を特定する。

2. レア度に応じたカラーを決定する:

   | レア度 | カラー指定（プロンプト用） |
   |--------|--------------------------|
   | common | `silver and gray (#9CA3AF)` |
   | rare | `blue (#3B82F6)` |
   | epic | `purple (#8B5CF6)` |
   | legendary | `gold (#F59E0B)` |

3. バッジの内容に応じた中央アイコンの説明を英語で作成する。
   - 例: スタンプ系 → `a shield with a checkmark and a small star`
   - 例: ラーメン系 → `a steaming ramen bowl with chopsticks`
   - 例: マップ系 → `a map with a location pin`

4. 以下の**固定テンプレート**を使ってプロンプトを組み立てる:

   ```
   Generate a badge image matching the style of the attached reference image. A circular metallic coin-style badge icon for a mobile app achievement system. The badge has a brushed metal texture with a raised outer ring border and an inner recessed circular area. 3D metallic look with subtle shadows and highlights. Center icon: [アイコンの説明]. The icon is embossed on the metal surface in the same metallic tone. Color scheme: [レア度カラー] metallic finish. Japanese text curved along the bottom of the badge reads: '[バッジ名（日本語）]'. White background (#FFFFFF), no drop shadow, no background elements. Clean and consistent style, suitable for a mobile app UI at 512x512px.
   ```

   **変更する箇所は3つだけ**:
   - `[アイコンの説明]` → バッジ内容に応じた英語のアイコン説明
   - `[レア度カラー]` → 上記テーブルのカラー指定
   - `[バッジ名（日本語）]` → BADGE_LIST.md に記載されたバッジの「名前」

5. 以下のコマンドで画像を生成する（**必ず参考画像を第5引数に指定する**）:

   ```bash
   source ~/.zshrc 2>/dev/null && python3 /Users/kanekohiroki/Desktop/groumapapp/scripts/generate_image.py "プロンプト" "出力パス" "1:1" "1K" "/Users/kanekohiroki/Desktop/groumapapp/assets/images/badges/stamps_total_1.png"
   ```

   - アスペクト比: 常に `1:1`
   - 画像サイズ: 常に `1K`
   - 参考画像: 常に `assets/images/badges/stamps_total_1.png` を指定（デザイン統一のため必須）

6. 保存先:
   - パス: `assets/images/badges/{badgeId}.png`
   - 例: `assets/images/badges/stamps_total_1.png`

7. **背景透過処理**（rembg / ローカル実行）:
   生成された画像は白背景のため、rembgで背景を透過する。

   ```python
   python3 -c "
   from rembg import remove
   input_path = 'assets/images/badges/{badgeId}.png'
   with open(input_path, 'rb') as f:
       data = f.read()
   with open(input_path, 'wb') as f:
       f.write(remove(data))
   print('Done')
   "
   ```

   - `pip install "rembg[cpu]"` が事前にインストールされている必要がある。
   - ローカル実行のため、APIキー不要・回数制限なし。
   - 出力先は元ファイルと同じパス（上書き）。

8. 生成された画像を Read ツールで表示し、ユーザーに確認してもらう。

9. ユーザーが修正を希望する場合は、アイコン説明のみ調整して再生成する（テンプレートの他の部分は変更しない）。再生成後は再度手順7の背景透過を実行する。

## プロンプト具体例

### common（グレー系）の例

```
Generate a badge image matching the style of the attached reference image. A circular metallic coin-style badge icon for a mobile app achievement system. The badge has a brushed metal texture with a raised outer ring border and an inner recessed circular area. 3D metallic look with subtle shadows and highlights. Center icon: a shield with a checkmark and a small star at the bottom. The icon is embossed on the metal surface in the same metallic tone. Color scheme: silver and gray (#9CA3AF) metallic finish. Japanese text curved along the bottom of the badge reads: 'はじめてのスタンプ'. White background (#FFFFFF), no drop shadow, no background elements. Clean and consistent style, suitable for a mobile app UI at 512x512px.
```

### rare（ブルー系）の例

```
Generate a badge image matching the style of the attached reference image. A circular metallic coin-style badge icon for a mobile app achievement system. The badge has a brushed metal texture with a raised outer ring border and an inner recessed circular area. 3D metallic look with subtle shadows and highlights. Center icon: a collection of multiple stamps arranged together. The icon is embossed on the metal surface in the same metallic tone. Color scheme: blue (#3B82F6) metallic finish. Japanese text curved along the bottom of the badge reads: 'スタンプハンター'. White background (#FFFFFF), no drop shadow, no background elements. Clean and consistent style, suitable for a mobile app UI at 512x512px.
```

### legendary（ゴールド系）の例

```
Generate a badge image matching the style of the attached reference image. A circular metallic coin-style badge icon for a mobile app achievement system. The badge has a brushed metal texture with a raised outer ring border and an inner recessed circular area. 3D metallic look with subtle shadows and highlights. Center icon: a grand crown with radiating light rays. The icon is embossed on the metal surface in the same metallic tone. Color scheme: gold (#F59E0B) metallic finish. Japanese text curved along the bottom of the badge reads: 'スタンプレジェンド'. White background (#FFFFFF), no drop shadow, no background elements. Clean and consistent style, suitable for a mobile app UI at 512x512px.
```

## 一括生成時の注意

- 複数バッジを一括生成する場合は、1つずつ順番に生成する。
- 同じカテゴリのバッジはアイコンを統一し、レア度のカラーだけ変える。
- 生成済みのバッジは上書きしない（ユーザーが明示的に再生成を依頼した場合を除く）。

## 注意事項

- `GOOGLE_API_KEY` 環境変数が設定されている必要がある。
- テンプレートの固定部分は絶対に変更しない（統一感を保つため）。
- 参考画像（`stamps_total_1.png`）は常にコマンドの第5引数に指定すること。
- 生成に失敗した場合は、アイコン説明を簡素化して再試行する。
- 背景透過にはrembg（ローカル実行・無料・無制限）を使用する。`pip install "rembg[cpu]"` が必要。

## 背景一括透過スクリプト

既存バッジの背景を一括で透過処理するスクリプトが用意されている:

```bash
python3 /Users/kanekohiroki/Desktop/groumapapp/scripts/rembg_batch.py
```

- 処理済みファイルは元ファイルを上書きする。
- ローカル実行のため回数制限なし。
