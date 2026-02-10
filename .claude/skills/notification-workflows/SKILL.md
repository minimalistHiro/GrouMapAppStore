---
name: notification-workflows
description: 「通知を作成して」「お知らせを送って」「通知を配信して」など、通知/お知らせの作成・保存先選定・type整合・配信トリガー確認を行うときに使う。未承認店舗通知、友達紹介通知、新規お知らせ作成などの通知処理を統一する場面で必ず使用する。
---

# Notification Workflows

## 目的
通知/お知らせの保存先・type・スキーマを統一し、ユーザー用/店舗用の両アプリで表示・配信が一致するように整理する。

## 保存先の決定ルール（必須）
- **全ユーザー向け**のお知らせ → `notifications`（トップレベル）
- **特定ユーザー向け**の通知 → `users/{userId}/notifications`

## typeの固定リスト（10個）
- `ranking`
- `badge`
- `level_up`
- `point_earned`
- `social`
- `marketing`
- `system`
- `store_announcement`
- `coupon_update`
- `customer_visit`

### typeの選択指針
- 未承認店舗通知 → `store_announcement`
- 友達紹介通知 → `social`
- 新規お知らせ作成（全体） → `system`

### typeが当てはまらない場合の対応
- 「新規お知らせを作成したい」依頼で上記10個に当てはまらない場合、**新しいtypeを提案**する。
- 提案時は「用途」「表示名」「想定アイコン/色」「保存先」を一緒に提示する。

## 代表ユースケース
1. 未承認店舗作成通知（オーナーのみ） → users配下
2. 友達紹介通知（紹介者/被紹介者） → users配下
3. 新規お知らせ作成（全体） → トップレベル

## 必須フィールド（共通）
- `id`, `userId`, `title`, `body`, `type`, `createdAt`, `isRead`, `isDelivered`, `data`, `tags`

### createdAtの統一方針
- **ISO文字列**で保存する（アプリ側は `DateTime.parse` 前提）。
- Timestampが混入する場合は取得側でISOに正規化する。

## 作業手順（共通）
1. 依頼内容から対象（全体/特定）を判定する
2. 保存先を決定する（トップレベル or users配下）
3. typeを固定リストから選ぶ（合わなければ新typeを提案する）
4. 通知作成処理の場所を特定する（Functions/アプリ）
5. 画面取得・パース・既読処理の整合を確認する
6. 配信トリガー（FCM）との整合を確認する

## 参照先
- Functions: `/Users/kanekohiroki/Desktop/groumapapp/backend/functions/src/index.ts`
- スキーマ: `/Users/kanekohiroki/Desktop/groumapapp/FIRESTORE.md`
- 通知モデル: `lib/models/notification_model.dart`
- 取得プロバイダー: `lib/providers/notification_provider.dart`
