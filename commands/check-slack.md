---
description: Slack未読トリアージ（両ワークスペース対応）- 返信が必要なメッセージを抽出・分類
argument-hint: <check|reply>
allowed-tools:
  - mcp__slack__slack_search_messages
  - mcp__slack__slack_get_channel_history
  - mcp__slack__slack_get_thread_replies
  - mcp__slack__slack_list_channels
  - mcp__slack__slack_get_users
  - mcp__slack__slack_get_user_profile
  - mcp__slack__slack_post_message
  - mcp__slack__slack_reply_to_thread
  - mcp__slack-capital__slack_search_messages
  - mcp__slack-capital__slack_get_channel_history
  - mcp__slack-capital__slack_get_thread_replies
  - mcp__slack-capital__slack_list_channels
  - mcp__slack-capital__slack_get_users
  - mcp__slack-capital__slack_get_user_profile
  - mcp__slack-capital__slack_post_message
  - mcp__slack-capital__slack_reply_to_thread
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# /check-slack - Slack message triage assistant

Args: $ARGUMENTS

## Overview
- 2つのSlackワークスペース（UPSIDER本体 / UPSIDER Capital）を検索
- 自分宛のメンション・DMを取得し、返信が必要なものを分類
- action_required のメッセージについて返信案を提示
- ユーザー承認後に返信を送信

## Identity
- riko.gohda / 合田莉子 / UPSIDER
- Slack display name: Nao(Naoki Ishigami)

## Workspaces
| Name | MCP prefix | Description |
|---|---|---|
| UPSIDER本体 | mcp__slack__ | メインワークスペース |
| UPSIDER Capital | mcp__slack-capital__ | Capital事業ワークスペース |

## Step 1: Fetch recent messages addressed to me

Both workspaces in parallel:

```
mcp__slack__slack_search_messages({ query: "to:me after:<3日前の日付>", sort: "timestamp", sort_dir: "desc", count: 30 })
mcp__slack-capital__slack_search_messages({ query: "to:me after:<3日前の日付>", sort: "timestamp", sort_dir: "desc", count: 30 })
```

If $ARGUMENTS contains a specific channel name or keyword, add it to the search query.

## Step 2: For action_required candidates, fetch thread context

Use `slack_get_thread_replies` to get full thread context for messages that appear to need a reply.
This helps determine if someone else already replied or if the conversation is resolved.

## Step 2.5: DM返信検証

action_required候補のうち、チャネルIDが `D`（DM）またはグループDM（`mpdm-`等）の場合:

1. `slack_get_channel_history({ channel_id, limit: 20 })` で最近の履歴を取得
2. 対象メッセージのtimestamp以降に自分のuser_id（`UD44KMYCB` / `U0693N2SFS8`）の発言があるか確認
3. あれば → `info_only` にダウングレード（返信済み）
4. なければ → `action_required` のまま

**注意**:
- 同一チャネルの複数メッセージは1回のAPI呼び出しで検証（重複回避）
- スレッド返信の場合は `slack_get_thread_replies` も使用

## Step 3: Classification rules

| Category | Condition | Action |
|---|---|---|
| skip | Bot通知 / 自動投稿 / Workflow通知 / 自分の投稿 / 既に自分がリアクション済み | skip |
| info_only | 情報共有のみ / 自分がCCレベル / お礼・了解の返信 / 雑談 | summary only |
| action_required | 直接メンション(@Nao) / 質問 / 期限付き依頼 / 承認依頼 / 意見を求められている / 未返信のDM（※Step 2.5で検証済み） | draft reply |

### action_required の判定ポイント
- 自分に直接質問や依頼がある
- 「確認お願いします」「ご意見ください」「いかがでしょうか」等のフレーズ
- スレッドで自分の返信がまだない
- 期限やデッドラインが明示されている

## Step 4: Present to user

出力フォーマット:

### 要返信（action_required）
優先度順に表示:

```
### 優先度：高
**1. [送信者名] ([ワークスペース], [日時]) - [チャンネル名]**
> [メッセージ要約（2-3行）]
- → **要アクション**: [何をすべきか]
```

### 情報のみ（info_only）
簡潔な箇条書き:
```
- **[送信者名]** ([チャンネル]): [1行要約]
```

### スキップ（skip）
件数のみ表示: `Bot通知・自動投稿: N件スキップ`

## Step 5: Draft reply (action_required items)

- ユーザーに返信下書きを提示する前に、AskUserQuestion で返信するかどうか確認
- ビジネス日本語、役職に応じたトーン
- 簡潔で的確な返信（冗長にしない）
- スレッドの文脈を踏まえた返信

## Step 6: Send reply (only after explicit approval)

スレッド返信の場合:
```
slack_reply_to_thread({ channel_id: "<channel>", thread_ts: "<ts>", text: "<reply>" })
```

チャンネル投稿の場合:
```
slack_post_message({ channel_id: "<channel>", text: "<reply>" })
```

**重要**: 送信は必ずユーザーの明示的な承認を得てから行う。

## Step 7: After processing

- relationships.md / todo.md の更新が必要な場合は自動で追記
- todo.md クリーンアップ:
  - Active セクション内の `- [x]` 行をすべて Done セクションに移動
  - 各行に完了日が未記載の場合は `(done: YYYY-MM-DD)` を行末に追加（今日の日付）
  - Done セクションの `<!-- 完了したタスクはここに移動 -->` コメント直後に挿入
  - 該当が0件なら何もしない
- 処理結果のサマリーを表示

## Notes
- **DM返信検証（重要）**: `search.messages` はDM内の自分の返信を返さないことがある。検索結果だけで「未返信」と断定しないこと。必ず Step 2.5 で `slack_get_channel_history` / `slack_get_thread_replies` を使って返信有無を確認する
- DM（im）のスコープが無い場合がある。その場合は `to:me` 検索結果のみで判断
- Capital WSの `limit` パラメータは number 型で渡す（文字列不可）
- 大量のメッセージがある場合は直近24時間に絞る
