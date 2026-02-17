---
name: nano-banana-image-gen
description: 「画像を生成して」「画像を作って」「アイコンを作って」「バナーを作って」など、画像生成の依頼時に、Nano Banana Pro（Gemini 3 Pro Image）APIを使って画像を自動生成する。
---

# Nano Banana Pro 画像生成スキル

## 目的

ユーザーから画像生成を依頼されたときに、Nano Banana Pro（Gemini 3 Pro Image）APIを使って自動的に画像を生成する。

## 手順

1. ユーザーの依頼内容を分析し、**英語の詳細なプロンプト**を作成する。
   - 日本語の依頼であっても、APIに渡すプロンプトは英語にする（生成品質が向上するため）。
   - 色、スタイル、構図、テキストなどの指示をできるだけ具体的に含める。

2. 保存先パスを決定する:
   - デフォルト: `/Users/kanekohiroki/Desktop/groumapapp/generated_images/` ディレクトリ
   - ファイル名は内容を表す分かりやすい名前にする（例: `app_logo.png`, `store_banner.png`）

3. アスペクト比と画像サイズを決定する:
   - `IMAGE_RATIOS.md` がある場合は参照する。
   - ユーザーから指定がない場合はデフォルト（1:1, 2K）を使用する。
   - 選択肢:
     - アスペクト比: `1:1`, `16:9`, `9:16`, `4:3`, `3:4`
     - 画像サイズ: `1K`, `2K`, `4K`

4. 以下のコマンドで画像生成スクリプトを実行する:

   ```bash
   source ~/.zshrc 2>/dev/null && python3 /Users/kanekohiroki/Desktop/groumapapp/scripts/generate_image.py "英語プロンプト" "出力パス" "アスペクト比" "画像サイズ"
   ```

5. 生成された画像のパスをユーザーに伝え、Read ツールで画像を表示して確認してもらう。

6. ユーザーが修正を希望する場合は、プロンプトを調整して再生成する。

## 「画像を生成して」のデフォルトスタイル

ユーザーが「画像を生成して」「画像を作って」と依頼した場合（ロゴ・アイコン・バナーなどの具体的な種別指定がない場合）、以下のスタイルをプロンプトに必ず含める：

- **スタイル**: ビジネス系フラットベクターイラスト（clean flat vector business illustration）
- **線画**: クリーンでシンプルな線（clean simple outlines）
- **配色**: 落ち着いたブルー、グレー、ホワイト基調（muted blue, gray, and white color palette）
- **人物**: 適度にデフォルメされたビジネスパーソン（stylized business people）
- **背景**: 白またはシンプルな背景（white or simple clean background）
- **全体の雰囲気**: プロフェッショナルで清潔感のあるビジネスイラスト

プロンプト例:
`"Clean flat vector business illustration of [シーンの内容], stylized business people, muted blue gray and white color palette, simple clean outlines, white background, professional corporate style, no gradients, minimal shading"`

**適用条件**:
- 適用する: 「画像を生成して」「画像を作って」「〇〇の画像を生成して」など、画像の種別指定がない汎用的な依頼
- 適用しない: 「ロゴを作って」「アイコンを作って」「バナーを作って」「写真風に」「水彩画で」など、具体的な種別やスタイル指定がある依頼

## プロンプト作成のコツ

- スタイルを明示する（例: "flat design", "minimalist", "photorealistic", "watercolor"）
- 色を指定する（例: "blue and white color scheme"）
- 背景を指定する（例: "on a transparent background", "white background"）
- テキストを含める場合は引用符で囲む（例: 'with the text "GrouMap"'）

## 注意事項

- `GOOGLE_API_KEY` 環境変数が設定されている必要がある。
- 生成に失敗した場合は、プロンプトを変えて再試行する。
- 生成された画像は必ずユーザーに確認してもらう。
