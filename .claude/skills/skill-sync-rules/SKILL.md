---
name: skill-sync-rules
description: 「スキルを追加して」「スキルを修正して」「スキルを作成して」「スキルを更新して」「スキルを削除して」など、スキルの追加・修正・作成・削除を依頼されたときに、.claude と .codex の両方、かつユーザー用・店舗用リポジトリの両方に同じ内容を反映するためのルール。
---

# Skill Sync Rules

## 概要

GrouMapプロジェクトでは、スキルを以下の **4箇所** で管理している。スキルの追加・修正・作成・削除を行う際は、必ず4箇所すべてに同じ内容を反映し、同期を保つ。

## スキルの配置先（4箇所）

| # | パス |
|---|------|
| 1 | `/Users/kanekohiroki/Desktop/groumapapp/.claude/skills/{skill-name}/SKILL.md` |
| 2 | `/Users/kanekohiroki/Desktop/groumapapp/.codex/skills/{skill-name}/SKILL.md` |
| 3 | `/Users/kanekohiroki/Desktop/groumapapp_store/.claude/skills/{skill-name}/SKILL.md` |
| 4 | `/Users/kanekohiroki/Desktop/groumapapp_store/.codex/skills/{skill-name}/SKILL.md` |

## 手順

ユーザーから「スキルを追加して」「スキルを修正して」「スキルを作成して」「スキルを更新して」「スキルを削除して」などの依頼があったら、以下の手順を順に実行する。

### スキルの新規作成

1. 上記4箇所すべてにディレクトリ `{skill-name}/` を作成する。
2. 4箇所すべてに同一内容の `SKILL.md` を作成する。
3. 4箇所すべてのファイル内容が完全に一致していることを確認する。

### スキルの修正・更新

1. 対象スキルの `SKILL.md` を上記4箇所すべてで修正する。
2. 4箇所すべてに同じ変更を適用する（1箇所だけの更新は不可）。
3. 修正後、4箇所すべてのファイル内容が一致していることを確認する。

### スキルの削除

1. 対象スキルのディレクトリと `SKILL.md` を上記4箇所すべてから削除する。
2. 1箇所だけの削除は不可。4箇所すべてから削除する。

## 注意事項

- **片方だけの更新は禁止**: `.claude` のみ、`.codex` のみ、ユーザー用のみ、店舗用のみの更新は行わない。必ず4箇所すべてに同じ内容を反映する。
- **SKILL.md のフォーマット**: YAML frontmatter（`name` と `description`）+ マークダウン本文の形式を使用する。
- **既存スキルとの整合性**: 新規作成時は、既存スキルの命名規則（ケバブケース: `skill-name-rules`）に従う。
- **作業完了後の報告**: 4箇所すべてへの反映が完了したことを報告する。
