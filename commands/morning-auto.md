---
description: 朝の自動ブリーフィング（非対話・Slack DM通知）
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - mcp__slack__slack_search_messages
  - mcp__slack__slack_get_channel_history
  - mcp__slack__slack_get_thread_replies
  - mcp__slack__slack_list_channels
  - mcp__slack__slack_get_users
  - mcp__slack__slack_get_user_profile
  - mcp__slack__slack_post_message
  - mcp__slack-capital__slack_search_messages
  - mcp__slack-capital__slack_get_channel_history
  - mcp__slack-capital__slack_get_thread_replies
  - mcp__slack-capital__slack_list_channels
  - mcp__slack-capital__slack_get_users
  - mcp__slack-capital__slack_get_user_profile
  - mcp__slack-capital__slack_post_message
---

# /morning-auto - Automated Daily Briefing (Non-interactive)

非対話版の朝ブリーフィング。データ収集→レポート生成→Slack DM通知まで自動で行う。
返信の送信やアーカイブは行わない（それは手動で /morning または /check-mail を使う）。

## Identity
- naoki.ishigami@up-sider.com / 石神直樹 / UPSIDER執行役員・公認会計士
- naoki.ishigami@upsidercap.com / 石神直樹 / UPSIDER Capital

## Slack DM Channel (self)
- UPSIDER本体: `UD44KMYCB`
- Capital: `U0693N2SFS8`
→ ブリーフィングは **UPSIDER本体WS** の自分DM (`UD44KMYCB`) に投稿する

## Phase 1: データ収集（すべて並行実行）

**1a. 今日のカレンダー予定**
```bash
ZONEINFO="C:/Users/NaokiIshigami/.local/lib/zoneinfo.zip" GOG_ACCOUNT=naoki.ishigami@up-sider.com gog.exe calendar events --from today --to tomorrow --all --max 30
```
```bash
ZONEINFO="C:/Users/NaokiIshigami/.local/lib/zoneinfo.zip" GOG_ACCOUNT=naoki.ishigami@upsidercap.com gog.exe calendar events --from today --to tomorrow --all --max 30
```

**1b. 未読メール（両アカウント）**
```bash
GOG_ACCOUNT=naoki.ishigami@up-sider.com gog.exe gmail messages search "is:unread in:inbox" --max 50 --json
```
```bash
GOG_ACCOUNT=naoki.ishigami@upsidercap.com gog.exe gmail messages search "is:unread in:inbox" --max 50 --json
```

**1c. Slack未読（両ワークスペース）**
```
mcp__slack__slack_search_messages({ query: "to:me after:<yesterday>", sort: "timestamp", sort_dir: "desc", count: 20 })
mcp__slack-capital__slack_search_messages({ query: "to:me after:<yesterday>", sort: "timestamp", sort_dir: "desc", count: 20 })
```

**1d. Todo期限チェック**
Read `~/.claude/private/todo.md` and check for:
- 期限切れタスク（期限 < 今日）
- 本日期限のタスク
- 明日期限のタスク
- 未完了の Active タスク

## Phase 2: 分類・統合

### カレンダー予定
- 時系列順にタイムラインとして整理
- 準備が必要な会議にマーク（初回の会議、外部参加者あり、等）

### メール分類
| Category | Condition | Action |
|---|---|---|
| skip | noreply / notification / alert / GitHub / Slack / promo / Google Docs共有 | count only |
| info_only | CC/ML受信のみ, 内部アップデート, お礼 | summary only |
| meeting_info | 会議招待 / スケジュール確認 / 場所情報 | flag |
| action_required | 直接アクション要求 / 期限付き依頼 / 質問 | highlight |

### Slack分類
| Category | Condition | Action |
|---|---|---|
| skip | Bot通知 / 自動投稿 / 自分の投稿 | count only |
| info_only | 情報共有のみ / CCレベル | summary only |
| action_required | 直接メンション / 質問 / 依頼 / 未返信DM | highlight |

**DM返信検証**: action_required候補のうちDM/グループDMの場合、`slack_get_channel_history` で対象メッセージ以降に自分（`UD44KMYCB` / `U0693N2SFS8`）の発信があるか確認。あれば info_only にダウングレード。スレッドの場合は `slack_get_thread_replies` も使用。同一チャネルは1回のAPI呼び出しで検証。

### Todo警告
- 期限切れタスク
- 本日期限のタスク
- 明日期限のタスク

## Phase 3: Slack DM投稿

以下のフォーマットでUPSIDER本体WSの自分DM (`UD44KMYCB`) に投稿する。
Slackのmrkdwn記法を使う（Markdownではない）。

投稿は **1つのメッセージ** にまとめる（長すぎる場合は要約して収める）。

```
:sunrise: *朝ブリーフィング*  [日付]

*:calendar: 今日のスケジュール*
• `09:00-10:00` 会議名 (場所)
• `11:00-12:00` 会議名 ← 準備必要
• _空き: 13:00-15:00_

*:rotating_light: 要アクション*
メール (N件):
• *[From]* - [Subject] → [要アクション内容]
Slack (N件):
• *[From]* ([Channel]) → [要アクション内容]

*:warning: Todo期限*
• :red_circle: 期限切れ: [タスク]
• :large_yellow_circle: 本日: [タスク]
• :white_circle: 明日: [タスク]

*:mailbox: 情報のみ*
メール N件 / Slack N件 (省略)

*:wastebasket: スキップ*
メール N件 / Slack N件
```

**重要**:
- action_required がゼロの場合は「要アクション」セクションを「なし :tada:」にする
- Todo期限が該当なしの場合は「期限切れ・期限間近のタスクなし :white_check_mark:」にする
- メッセージにAI由来プレフィックスを付けない

## Phase 4: ログ保存

ブリーフィング内容を以下に保存:
```
~/.claude/private/logs/morning-briefing-YYYY-MM-DD.md
```

## Phase 4.5: todo.mdクリーンアップ

- Active セクション内の `- [x]` 行をすべて Done セクションに移動
- 各行に完了日が未記載の場合は `(done: YYYY-MM-DD)` を行末に追加（今日の日付）
- Done セクションの `<!-- 完了したタスクはここに移動 -->` コメント直後に挿入
- 該当が0件なら何もしない

## 注意事項
- このコマンドは非対話。AskUserQuestion は使わない
- メールのアーカイブ、返信の送信は一切行わない
- 情報の収集と通知のみを行う
- エラーが発生した場合もDMで通知する（「カレンダー取得エラー」等）
