---
description: 週次メンバーレポートのネクストアクションを月曜朝にSlack投稿（非対話）
allowed-tools:
  - Read
  - Bash
  - mcp__slack-capital__slack_post_message
---

# /weekly-reminder - Weekly Next Actions Reminder

金曜日の `/weekly-members` で生成されたネクストアクション・重要期限を、月曜朝に Capital WS の `biz_ubdf` チャネルに投稿する。

## 投稿先
- **Workspace**: Capital WS (`mcp__slack-capital__*`)
- **Channel**: `C069192C2HY` (biz_ubdf)

## 実行手順

### Step 1: データ読み込み

```
Read ~/.claude/private/weekly-next-actions.md
```

ファイルが存在しない場合、またはデータが古い（7日以上前）場合は投稿せずに終了する。

### Step 2: Slack メッセージ組み立て

以下のフォーマットで投稿メッセージを組み立てる:

```
今週のフォーカス（MM/DD週）

:calendar: 重要期限
・MM/DD（曜日） 内容（担当）
・...

:clipboard: 各自のネクストアクション
・メンバー名: アクション内容（〜期限）
・...

:handshake: 連携テーマ
・テーマ: メンバー → アクション
・...

詳細→ NotionページURL
```

**注意**:
- 簡潔にまとめる（Slackで読みやすい長さ）
- 各メンバーのアクションは1行に収める
- 連携テーマは3件以内
- 絵文字はSlack標準の `:calendar:` `:clipboard:` `:handshake:` 形式を使用

### Step 3: Slack 投稿

```
mcp__slack-capital__slack_post_message({
  channel_id: "C069192C2HY",
  text: <組み立てたメッセージ>
})
```

### Step 4: 完了

投稿成功を確認して終了。エラーが出た場合はログに記録する。

## Notes

- このコマンドは非対話で実行される（スケジュールタスクから呼び出し）
- `weekly-next-actions.md` は `/weekly-members` の Phase 4 で毎週上書きされる
- 投稿内容に「Claude:」等のAIプレフィックスは付けない
- ファイルが存在しない = 金曜日のレポートが未実行。その場合はサイレントに終了
