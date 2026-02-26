---
description: ミーティング準備自動化 - 会議前の情報収集・アジェンダ案生成
argument-hint: <会議名 or "next">
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - AskUserQuestion
  - mcp__slack__slack_search_messages
  - mcp__slack__slack_get_channel_history
  - mcp__slack__slack_get_thread_replies
  - mcp__slack__slack_list_channels
  - mcp__slack__slack_get_users
  - mcp__slack-capital__slack_search_messages
  - mcp__slack-capital__slack_get_channel_history
  - mcp__slack-capital__slack_get_thread_replies
  - mcp__slack-capital__slack_list_channels
  - mcp__slack-capital__slack_get_users
  - mcp__notion__notion-search
  - mcp__notion__notion-fetch
---

# /prep - Meeting Preparation Assistant

Args: $ARGUMENTS

## Overview
指定された会議（またはnextで次の会議）の準備を自動化する。
前回の議事録・関連Slackスレッド・参加者情報を収集し、アジェンダ案を生成する。

## Identity
- naoki.ishigami / 石神直樹 / UPSIDER執行役員・公認会計士

## 定例会議マッピング

| 会議名キーワード | 正式名 | 頻度 | 主な参加者 | Slackチャンネル候補 |
|---|---|---|---|---|
| capital-daily / daily | Capital Daily | 毎日 | 村松、太田、丸山、牧、和田、安池、Oh | capital系チャンネル |
| capital-board / 役員会 | Capital 役員会 | 定期 | 村松、丸山、牧、和田、安池、田辺(みずほ)、奈良(みずほ) | capital系チャンネル |
| 本部長定例 | 本部長定例 | 定期 | 辻本、泉、米田 | 該当チャンネル |
| sco / online-lending | SCO/OnlineLending | 定期 | 鈴木透也、伊藤礼司 | 該当チャンネル |
| 1on1 | 1on1 | 各メンバー | 個別 | DM |

## Step 1: 会議の特定

If $ARGUMENTS == "next" or empty:
```bash
GOG_ACCOUNT=naoki.ishigami@up-sider.com gog.exe calendar events --from now --to tomorrow --all --max 10
```
```bash
GOG_ACCOUNT=naoki.ishigami@upsidercap.com gog.exe calendar events --from now --to tomorrow --all --max 10
```
→ 直近の会議を特定し、ユーザーに確認

If $ARGUMENTS に会議名が指定されている:
→ 上記のマッピングからマッチする会議を特定
→ カレンダーから該当イベントの詳細を取得

## Step 2: 情報収集（並行実行）

**2a. 参加者情報**
- relationships.md から参加者の Role / Tone を取得
- 外部参加者がいる場合はハイライト

**2b. 前回の会議メモ/議事録**
- Notion で会議名を検索:
```
mcp__notion__notion-search({ query: "<会議名>", filter: { property: "object", value: "page" } })
```
- 見つかった場合は最新のページを取得:
```
mcp__notion__notion-fetch({ resource_uri: "notion://page/<pageId>" })
```

**2c. 関連Slackスレッド（直近1週間）**
- 会議名・関連キーワードで検索:
```
mcp__slack__slack_search_messages({ query: "<会議名 or 関連キーワード> after:<1週間前>", count: 10 })
mcp__slack-capital__slack_search_messages({ query: "<会議名 or 関連キーワード> after:<1週間前>", count: 10 })
```
- action_required のままのスレッドがあればハイライト

**2d. 関連todo**
- todo.md から会議参加者に関連するタスクを抽出

**2e. 前回のアクションアイテム**
- 前回議事録からアクションアイテムを抽出（未完了のもの）

## Step 3: ブリーフィング生成

```
## 🗓️ [会議名] 準備メモ
**日時**: YYYY-MM-DD HH:MM
**参加者**: [名前 (役割)] ...

### 📋 前回のアクションアイテム（未完了）
- [ ] [アイテム] (担当: [名前])

### 💬 直近の関連トピック（Slack）
1. [チャンネル] [トピック要約] - [ステータス]

### 📝 アジェンダ案
1. 前回アクションアイテムの進捗確認
2. [Slackで話題になっている未解決事項]
3. [todo.mdの関連タスク]
4. その他

### 👥 参加者メモ
- [外部参加者がいる場合の注意点]
- [特定の参加者に確認すべき事項]
```

## Step 4: ユーザー確認

AskUserQuestion で:
- アジェンダの追加・修正があるか
- 特に確認したいトピックがあるか
- Notionにメモページを作成するか

## Notes
- 1on1の場合は、そのメンバーとの直近のやり取り（Slack・メール）を重点的に収集
- 外部参加者（みずほ等）がいる会議は、フォーマルなアジェンダを生成
- Notion検索が空の場合はSlack情報のみでアジェンダを構成
