---
description: Gmail unread triage (skip/info_only/meeting_info/action_required) with auto-archive and draft replies
argument-hint: <triage|check|edit>
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Edit
  - Write
  - AskUserQuestion
---

# /check-mail - Gmail assistant

Args: $ARGUMENTS

## Overview
- Fetch unread mail
- Classify into skip / info_only / meeting_info / action_required
- Auto-archive skip
- For action_required, draft a reply (do not send without approval)

## Identity
- riko.gohda@up-sider.com / 合田莉子 / UPSIDER

## Accounts
| Alias | Email | GOG_ACCOUNT |
|---|---|---|
| sider | riko.gohda@up-sider.com | riko.gohda@up-sider.com |

## Step 1: Fetch unread mail (both accounts)
Run in parallel:
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog gmail messages search "newer_than:7d -from:info@bank.gmo-aozora.com -from:noreply@mfkessai.co.jp -from:noreply@google.com -from:support@digital.hokkokubank.co.jp" --max 50 --include-body --json
```
```bash
```
- Merge results, prefix each mail with [sider] or [cap] to indicate source account
- sider側で除外した通知系（GMOあおぞら振込/ペイジー、MFケッサイ、北國銀行等）は別途一括アーカイブする:
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog gmail messages search "newer_than:1d from:info@bank.gmo-aozora.com OR from:noreply@mfkessai.co.jp OR from:support@digital.hokkokubank.co.jp" --max 50 --json
```
- 上記の結果のthreadIdを重複排除して即時一括アーカイブ:
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog gmail thread modify "<threadId1>" "<threadId2>" ... --remove "INBOX,UNREAD" --force
```

## Step 2: Classification rules

| Category | Condition | Action |
|---|---|---|
| skip | noreply / notification / alert / GitHub / Slack / Jira / promo / marketing / auto-send / Google Docs・Slides 共有リクエスト | auto-archive |
| info_only | CC/ML受信のみ, internal updates, receipts, お礼メール | summary + archive |
| meeting_info | meeting invites / confirmed schedule / location info | calendar lookup & update |
| action_required | 私に直接アクションを求めるもの / 期限付き依頼 / 質問 / scheduling | draft reply |

## Step 2.5: skip / info_only の即時アーカイブ
分類完了後、**表示ステップ（Step 5）に進む前に** skip と info_only のスレッドを即時アーカイブする。
action_required / meeting_info の有無に関わらず、必ず実行すること。

```bash
GOG_ACCOUNT=<source_account> gog gmail thread modify "<threadId1>" "<threadId2>" ... --remove "INBOX,UNREAD" --force
```
- 同一アカウントのスレッドをまとめて1コマンドで処理（1回50件まで）
- sider / cap それぞれ別コマンドで実行
- アーカイブ完了後、件数をユーザーに報告（例: 「skip 12件 + info_only 5件 をアーカイブしました」）

## Step 3: meeting_info handling
- Extract date/time, link, location, title
- Match existing event, add missing info
- Use the same account (GOG_ACCOUNT) as the source mail's account

```bash
ZONEINFO="C:/Users/rikogohda/.local/lib/zoneinfo.zip" GOG_ACCOUNT=<source_account> gog calendar events --from <date> --to <date+1> --all --max 30
```

```bash
GOG_ACCOUNT=<source_account> gog calendar update <calendarId> <eventId> --location "<place>" --description "<meeting link>"
```

## Step 4: action_required handling
- Detect scheduling keywords
- Draft reply in the correct tone (business Japanese, role-appropriate)

## Step 5: Present to user
- 出力は簡潔な表形式で、action_required / meeting_info を先に表示
- skip は件名のみ箇条書き（同種の通知はまとめる）
- 全 action_required 項目を番号付きで一覧表示:

```
## 要返信メール一覧

### #1 [sider] From: 田中太郎 - Re: 契約書確認
> [要約 2-3行]
**返信案:**
> [下書き]

### #2 [cap] From: 山田花子 - 融資案件の件
> [要約 2-3行]
**返信案:**
> [下書き]

...
```

## Step 6: 一括承認
AskUserQuestion で全 action_required 項目について一括で確認:
- 各項目のオプション: 送信 / 編集 / スキップ
- 例: 「#1: 送信、#2: 編集、#3: スキップ」のように一度に指示を受ける
- 「全部送信」も受け付ける

編集が必要な項目がある場合:
- 編集対象の返信案を提示し、修正指示を受ける
- 修正後、再度確認

## Step 7: 一括送信
承認された全メールを順次送信:
```bash
GOG_ACCOUNT=<source_account> gog gmail send \
  --reply-to-message-id "<messageId>" \
  --to "<to>" \
  --body "<reply>"
```
- 各送信の成功/失敗を記録
- 送信結果サマリーを表示

## Step 8: After-send checklist
1) Calendar update/create if needed
2) Archive: action_required（送信済み・スキップ済み）と meeting_info のスレッドをアーカイブ（skip / info_only は Step 2.5 で済み）:
```bash
GOG_ACCOUNT=<source_account> gog gmail thread modify "<threadId1>" "<threadId2>" ... --remove "INBOX,UNREAD" --force
```
- action_required が0件の場合でも、meeting_info があればこのステップを実行する
- **Step 5 で表示した全メールがアーカイブ済みになっていることを確認する**
3) relationships.md / todo.md の更新が必要な場合は自動追記
4) todo.md クリーンアップ:
   - Active セクション内の `- [x]` 行をすべて Done セクションに移動
   - 各行に完了日が未記載の場合は `(done: YYYY-MM-DD)` を行末に追加（今日の日付）
   - Done セクションの `<!-- 完了したタスクはここに移動 -->` コメント直後に挿入
   - 該当が0件なら何もしない
