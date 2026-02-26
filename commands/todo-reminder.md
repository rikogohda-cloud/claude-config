---
description: Todo期限リマインダー（非対話・Slack DM通知）
allowed-tools:
  - Read
  - Glob
  - Grep
  - mcp__slack__slack_post_message
---

# /todo-reminder - Todo Deadline Reminder (Non-interactive)

todo.md を読み取り、期限が迫っているタスクがあれば Slack DM で通知する。
軽量な非対話コマンド。

## Slack DM Channel
- UPSIDER本体WS 自分DM: `UD44KMYCB`

## 手順

### Step 1: todo.md を読む
```
Read ~/.claude/private/todo.md
```

### Step 2: Active セクションから未完了タスク（`- [ ]`）を抽出

各タスクの「期限:」フィールドを解析する。日付フォーマット例:
- `期限: 2026-02-14` → 明確な期限
- `期限: 2026-02末` → 月末として解釈（2026-02-28）
- `期限: なし` → 期限なし（スキップ）
- `期限: Taro反応後` → 条件付き期限（スキップ）

また、タスク行頭の日付（`YYYY-MM-DD`）が登録日。期限がなくても登録から5日以上経過していたら「放置タスク」として警告する。

### Step 3: 分類

| カテゴリ | 条件 |
|---|---|
| :red_circle: 期限切れ | 期限 < 今日 |
| :large_yellow_circle: 本日期限 | 期限 = 今日 |
| :white_circle: 明日期限 | 期限 = 明日 |
| :hourglass: 放置 | 期限なし & 登録から5日以上 |

### Step 4: Slack DM 通知

該当タスクが **1件以上** ある場合のみ通知する。該当なしなら何もしない。

UPSIDER本体WSの自分DM (`UD44KMYCB`) に投稿:

```
:bell: *Todo リマインダー*  [日付]

:red_circle: *期限切れ*
• [タスク内容] (期限: YYYY-MM-DD)

:large_yellow_circle: *本日期限*
• [タスク内容]

:white_circle: *明日期限*
• [タスク内容]

:hourglass: *放置タスク (5日以上)*
• [タスク内容] (登録: YYYY-MM-DD)
```

該当カテゴリがゼロのセクションは省略する。

## 注意事項
- 非対話コマンド。AskUserQuestion は使わない
- todo.md の編集は行わない（読み取りのみ）
- 通知対象がゼロの場合はSlack投稿もしない（静かに終了）
- メッセージにAI由来プレフィックスを付けない
