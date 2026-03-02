---
name: logo-gen
description: 「ロゴを作成して」「ロゴを作って」「ロゴを生成して」など、ロゴ画像の生成依頼時に、GrouMapのブランドカラーとデザインスタイルを適用してロゴを自動生成する。
---

# GrouMap ロゴ生成スキル

## 目的

ユーザーからロゴ生成を依頼されたときに、GrouMapのブランドイメージに合ったロゴを自動生成する。

## 生成手順の参照

具体的な画像生成の手順（コマンド実行方法・保存先・アスペクト比の決定方法）は、以下のファイルを Read ツールで読み込んでから実行してください：

`/Users/kanekohiroki/Desktop/groumapapp/.claude/skills/nano-banana-image-gen/HOW_TO_GENERATE.md`

## GrouMap ブランドカラー

| 用途 | カラーコード | 説明 |
|------|-------------|------|
| プライマリオレンジ | `#FF6B35` | メインのブランドカラー、ボタン・アイコン等に使用 |
| 背景色 | `#FBF6F2` | 画面背景色（温かみのあるベージュ） |

ロゴ生成時は **`#FF6B35`（オレンジ）** を主軸カラーとして使用すること。

## デザインスタイル（必須）

以下の参照画像のスタイルに **厳密に** 準じてロゴを生成すること：

**参照画像**: `.claude/skills/logo-gen/reference/logo_style_reference.png`

ロゴ生成前に必ず Read ツールでこの参照画像を確認し、同じスタイルで生成すること。

### 参照画像の分析結果（厳守事項）

参照画像は「ソリッド塗りつぶしUIアイコンセット」であり、以下の特徴を持つ：

1. **塗りつぶし（solid fill）**: アイコンはベタ塗りのシルエットで表現。内部のディテールは白い切り抜き（cutout）で表現する
2. **太く力強いシェイプ**: 細い線ではなく、塗りつぶされた太い形状で構成
3. **単色**: オレンジ（#FF6B35）の1色のみ。グラデーション・マルチカラーなし
4. **角丸（rounded corners）**: シェイプの角が丸め処理されている
5. **最小限のディテール**: 対象物を識別できる最小限の形で構成。余計な装飾なし
6. **均等な余白**: アイコン周囲に十分な余白。詰め込みすぎない
7. **白背景**: 背景は純白。影・グロー・テクスチャなし
8. **統一されたサイズ感**: すべてのアイコンが同じ見た目のサイズ・重量感

### プロンプトテンプレート（必須）

**重要: このスキルで生成するものはすべてオレンジ色（#FF6B35）を使用すること。ダークグレーやその他の色は使用しない。**

```
Single solid filled [icon/logo] of [対象物], bold solid shape, filled silhouette style with white cutout details for inner elements, orange color #FF6B35 on white background, rounded corners, simple and clean with minimal detail, no outlines no strokes, no shadows no gradients no textures no 3D effects, flat 2D solid icon, professional and modern, centered with equal padding, isolated single [icon/logo]
```

- `[icon/logo]`: 依頼内容に応じて `icon` または `logo` を選択
- `[対象物]`: シンプルな英語で対象物を記述（例: `a coin`, `a medal badge with a star`）

### プロンプト作成の必須ルール

1. **必ず含めるキーワード**:
   - `solid filled` （塗りつぶし）
   - `bold solid shape` （太く力強い形状）
   - `filled silhouette style with white cutout details` （シルエット塗りつぶし＋白切り抜きでディテール表現）
   - `no outlines no strokes` （輪郭線なし）
   - `no shadows no gradients no textures no 3D effects` （装飾禁止）
   - `flat 2D solid icon` （フラットな2Dソリッドアイコン）
   - `single icon` or `single logo` （1つだけ生成）
   - `centered with equal padding` （中央配置・均等余白）

2. **絶対に含めないキーワード**:
   - `outline`, `stroke`, `line art`, `thin` （アウトライン・線画系）
   - `colorful`, `vibrant`, `gradient` （多色・グラデーション）
   - `3D`, `realistic`, `photorealistic` （立体・写実）
   - `shadow`, `glow`, `reflection` （影・光沢）
   - `detailed`, `complex`, `intricate` （詳細・複雑）
   - `icon set`, `multiple icons` （複数アイコン）

3. **対象物の記述**:
   - シンプルな英語で対象物を記述する
   - 例: `a coin`, `a medal badge with a star`, `a stamp card`
   - 過度な修飾語を避け、対象物の本質だけを伝える

## デフォルト設定

- **アスペクト比**: `1:1`（正方形）
- **画像サイズ**: `2K`
- **保存先**: `/Users/kanekohiroki/Desktop/groumapapp/generated_images/`
- **ファイル名**: 内容を表す名前（例: `logo_main.png`, `logo_icon.png`）

## 生成後の品質チェック

生成された画像を Read ツールで表示し、以下を確認する：

- [ ] ソリッド塗りつぶしのシルエットスタイルか（アウトライン線画になっていないか）
- [ ] 内部ディテールが白い切り抜きで表現されているか
- [ ] オレンジ色（#FF6B35）の単色か（多色やダークグレーになっていないか）
- [ ] 背景が白か
- [ ] 影・グラデーション・3D効果がないか
- [ ] 1つのアイコン/ロゴだけが表示されているか（複数生成されていないか）
- [ ] 参照画像のスタイルと一致しているか

**品質基準を満たさない場合**: プロンプトを調整して再生成する。特に「アウトライン線画」になりやすいため、`solid filled` と `no outlines no strokes` を強調する。

## 背景透明化（必須・自動実行）

**ロゴ生成後は必ずオレンジ以外のすべてのピクセルを透明化すること。** `remove-background` スキル（rembg）は使用しない。rembgはコインの内側の白を残してしまうため、色ベースの透明化を行う。

### 重要: オレンジ色のみ残し、それ以外はすべて透明にする

生成されるロゴはオレンジ色（#FF6B35）の線のみで構成されるため、白やその他の非オレンジ色ピクセルはすべて背景として透明化する。

### 透明化コマンド（必須）

以下のPythonコマンドを使って透明化を実行すること：

```bash
source ~/.zshrc 2>/dev/null && python3 -c "
from PIL import Image
import numpy as np

img = Image.open('INPUT_PATH').convert('RGBA')
data = np.array(img)

# 白〜薄い色のピクセルを透明化（オレンジの線だけ残す）
# R,G,B すべてが200以上のピクセルは背景とみなす
mask = (data[:,:,0] > 200) & (data[:,:,1] > 200) & (data[:,:,2] > 200)
data[mask, 3] = 0

Image.fromarray(data).save('OUTPUT_PATH')
print('透明化完了')
"
```

- `INPUT_PATH` / `OUTPUT_PATH`: 実際のファイルパスに置き換える（同じパスでもOK）

### 手順

1. ロゴ画像を生成する
2. 生成された画像を Read ツールで確認し、品質チェックを行う
3. **上記の透明化コマンドを実行して、オレンジ以外をすべて透明化する**
4. 透明化された画像をユーザーに提示する

> **注意**: 白い部分が残った状態で納品しないでください。コインの内側も外側もすべて透明にし、オレンジの線だけが残る状態にすること。

## 注意事項

- `GOOGLE_API_KEY` 環境変数が設定されている必要がある（HOW_TO_GENERATE.md 参照）。
- 生成に失敗した場合は、プロンプトを変えて再試行する。
- 生成された画像は必ず Read ツールで表示し、ユーザーに確認してもらう。
- ユーザーが修正を希望する場合は、プロンプトを調整して再生成する。
