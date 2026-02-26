---
description: 朝の一括ブリーフィング（カレンダー + メール + Slack + Todo）
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Edit
  - Write
  - AskUserQuestion
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
  - mcp__notion__notion-search
  - mcp__notion__notion-fetch
---

# /morning - Daily Briefing

朝の一括ブリーフィングを実行する。以下を一度にまとめて確認・報告する。

## Identity
- naoki.ishigami@up-sider.com / 石神直樹 / UPSIDER執行役員・公認会計士
- naoki.ishigami@upsidercap.com / 石神直樹 / UPSIDER Capital

## 実行順序

### Phase 1: データ収集（すべて並行実行）

**1a. 今日のカレンダー予定**
```bash
ZONEINFO="C:/Users/NaokiIshigami/.local/lib/zoneinfo.zip" GOG_ACCOUNT=naoki.ishigami@up-sider.com gog.exe calendar events --from today --to tomorrow --all --max 30
```
```bash
ZONEINFO="C:/Users/NaokiIshigami/.local/lib/zoneinfo.zip" GOG_ACCOUNT=naoki.ishigami@upsidercap.com gog.exe calendar events --from today --to tomorrow --all --max 30
```

**1b. 未読メール（両アカウント）**
```bash
GOG_ACCOUNT=naoki.ishigami@up-sider.com gog.exe gmail messages search "is:unread in:inbox" --max 100 --json
```
```bash
GOG_ACCOUNT=naoki.ishigami@upsidercap.com gog.exe gmail messages search "is:unread in:inbox" --max 100 --json
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
- 未完了の Active タスク

### Phase 2: 分類・統合

#### カレンダー予定
- 時系列順にタイムラインとして表示
- 準備が必要な会議にマーク（初回の会議、外部参加者あり、等）
- 空き時間帯も表示

#### メール分類（/check-mail のルールに従う）
| Category | Condition | Action |
|---|---|---|
| skip | noreply / notification / alert / GitHub / Slack / promo / Google Docs共有 | auto-archive |
| info_only | CC/ML受信のみ, 内部アップデート, お礼 | summary only |
| meeting_info | 会議招待 / スケジュール確認 / 場所情報 | calendar更新 |
| action_required | 直接アクション要求 / 期限付き依頼 / 質問 | draft reply |

#### Slack分類（/check-slack のルールに従う）
| Category | Condition | Action |
|---|---|---|
| skip | Bot通知 / 自動投稿 / 自分の投稿 | skip |
| info_only | 情報共有のみ / CCレベル | summary only |
| action_required | 直接メンション / 質問 / 依頼 / 未返信DM | draft reply |

**DM返信検証**: action_required候補のうちDM/グループDMの場合、`slack_get_channel_history` で対象メッセージ以降に自分（`UD44KMYCB` / `U0693N2SFS8`）の発信があるか確認。あれば info_only にダウングレード。スレッドの場合は `slack_get_thread_replies` も使用。同一チャネルは1回のAPI呼び出しで検証。

#### Todo警告
- 🔴 期限切れタスク
- 🟡 本日期限のタスク
- 📋 Active タスク一覧（直近5件）

### Phase 3: ブリーフィング出力

以下のフォーマットで統合レポートを出力:

```
## 📅 今日のスケジュール
| 時間 | 予定 | 備考 |
|---|---|---|

## ⚡ 要アクション
### メール (N件)
1. **[From]** - [Subject] → [要アクション内容]
### Slack (N件)
1. **[From]** ([Channel]) → [要アクション内容]

## 🔴 Todo警告
- 期限切れ: ...
- 本日期限: ...

## 📬 情報のみ
### メール (N件)
- [From]: [1行要約]
### Slack (N件)
- [From] ([Channel]): [1行要約]

## 🗑️ スキップ
- メール: N件 auto-archived
- Slack: N件 skipped
```

### Phase 4: アクション実行

1. skip メールの auto-archive を実行
2. meeting_info のカレンダー更新を実行
3. action_required 項目について返信案を提示
4. AskUserQuestion で一括承認を求める:
   - 各 action_required 項目に対して「送信 / 編集 / スキップ」
5. 承認されたものだけ送信

### Phase 5: 後処理

1. relationships.md / todo.md の更新が必要な場合は自動追記
2. todo.md クリーンアップ:
   - Active セクション内の `- [x]` 行をすべて Done セクションに移動
   - 各行に完了日が未記載の場合は `(done: YYYY-MM-DD)` を行末に追加（今日の日付）
   - Done セクションの `<!-- 完了したタスクはここに移動 -->` コメント直後に挿入
   - 該当が0件なら何もしない
3. 処理結果サマリーを表示
