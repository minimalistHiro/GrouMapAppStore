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

参照画像は「UI用アウトラインアイコンセット」であり、以下の特徴を持つ：

1. **線のみ（stroke only）**: 塗りつぶし（fill）は一切なし。すべてアウトライン（輪郭線）だけで表現
2. **均一な線幅**: すべてのアイコンで同じ太さの線を使用（約2px相当の細い線）
3. **単色**: ダークグレー〜黒の1色のみ。グラデーション・マルチカラーなし
4. **角丸（rounded corners/caps）**: 線の端と角が丸め処理されている
5. **最小限のディテール**: 対象物を識別できる最小限の線で構成。余計な装飾なし
6. **均等な余白**: アイコン周囲に十分な余白。詰め込みすぎない
7. **白背景**: 背景は純白。影・グロー・テクスチャなし
8. **統一されたサイズ感**: すべてのアイコンが同じ見た目のサイズ・重量感

### プロンプトテンプレート（必須）

**アプリ内アイコン生成時（icon_coin, icon_badge 等）:**

```
Single minimal outline icon of [対象物], thin uniform stroke weight, stroke only with no fill, dark gray color on white background, rounded line caps and corners, simple and clean with minimal detail, consistent line thickness throughout, no shadows no gradients no textures no 3D effects, flat 2D line art, professional UI icon style, centered with equal padding, isolated single icon
```

**ロゴ生成時:**

```
Single minimal outline logo for "GrouMap", [ユーザーの依頼内容], thin uniform stroke weight, stroke only with no fill, orange color #FF6B35 on white background, rounded line caps and corners, simple and clean with minimal detail, consistent line thickness throughout, no shadows no gradients no textures no 3D effects, flat 2D line art, professional and modern, centered with equal padding
```

### プロンプト作成の必須ルール

1. **必ず含めるキーワード**:
   - `thin uniform stroke weight` （均一な細い線幅）
   - `stroke only with no fill` （線のみ、塗りなし）
   - `rounded line caps and corners` （角丸）
   - `no shadows no gradients no textures no 3D effects` （装飾禁止）
   - `flat 2D line art` （フラットな2D線画）
   - `single icon` or `single logo` （1つだけ生成）
   - `centered with equal padding` （中央配置・均等余白）

2. **絶対に含めないキーワード**:
   - `colorful`, `vibrant`, `gradient` （多色・グラデーション）
   - `3D`, `realistic`, `photorealistic` （立体・写実）
   - `shadow`, `glow`, `reflection` （影・光沢）
   - `filled`, `solid` （塗りつぶし）
   - `detailed`, `complex`, `intricate` （詳細・複雑）
   - `icon set`, `multiple icons` （複数アイコン）

3. **対象物の記述**:
   - シンプルな英語で対象物を記述する
   - 例: `a coin with a dollar sign`, `a medal badge with a star`, `a stamp card`
   - 過度な修飾語を避け、対象物の本質だけを伝える

## デフォルト設定

- **アスペクト比**: `1:1`（正方形）
- **画像サイズ**: `2K`
- **保存先**: `/Users/kanekohiroki/Desktop/groumapapp/generated_images/`
- **ファイル名**: 内容を表す名前（例: `logo_main.png`, `logo_icon.png`）

## 生成後の品質チェック

生成された画像を Read ツールで表示し、以下を確認する：

- [ ] 線のみで表現されているか（塗りつぶしがないか）
- [ ] 線幅が均一か
- [ ] 単色か（多色になっていないか）
- [ ] 背景が白か
- [ ] 影・グラデーション・3D効果がないか
- [ ] 1つのアイコン/ロゴだけが表示されているか（複数生成されていないか）
- [ ] 参照画像のスタイルと一致しているか

**品質基準を満たさない場合**: プロンプトを調整して再生成する。特に「塗りつぶし」や「複数アイコン」が出やすいため、`stroke only with no fill` と `single icon` を強調する。

## 背景透明化（必須・自動実行）

**ロゴ生成後は必ず `remove-background` スキルを使って背景を透明化すること。** ユーザーからの個別依頼を待たずに、ロゴ生成フローの一部として自動的に実行する。

### 手順

1. ロゴ画像を生成する
2. 生成された画像を Read ツールで確認し、品質チェックを行う
3. **自動的に `remove-background` スキルを発動して背景を透明化する**
4. 透明化された画像をユーザーに提示する

> **注意**: 背景透明化はロゴ生成の必須ステップです。白背景のまま納品しないでください。

## 注意事項

- `GOOGLE_API_KEY` 環境変数が設定されている必要がある（HOW_TO_GENERATE.md 参照）。
- 生成に失敗した場合は、プロンプトを変えて再試行する。
- 生成された画像は必ず Read ツールで表示し、ユーザーに確認してもらう。
- ユーザーが修正を希望する場合は、プロンプトを調整して再生成する。
