# Email Response Standard Flow

## Principle: Minimize User Questions

質問は**最小限**に。proactiveに複数の方法を試してから、どうしても必要な場合のみ質問する。

## Step 1: Email Search (NO questions before trying all methods)

人名・会社名で検索する場合、以下を**並列実行**：

```bash
# Method 1: 名前検索
GOG_ACCOUNT=<account> gog gmail messages search "from:<name> OR to:<name> newer_than:14d" --json

# Method 2: ドメイン検索（推測）
GOG_ACCOUNT=<account> gog gmail messages search "from:@<domain> newer_than:14d" --json

# Method 3: 未返信メール一覧
GOG_ACCOUNT=<account> gog gmail messages search "is:inbox -from:me newer_than:7d" --json
```

→ 3つとも失敗した場合のみ、具体的な質問（ドメイン、件名など）をする

## Step 2: Email Body Retrieval (NO trial-and-error)

**常に以下の方法を使用**（文字化けしない）：

```bash
# 標準ツール使用
~/.claude/bin/gmail_get_body.py <message_id> <account>
```

または

```bash
# snippet取得（常に正しくデコード済み）
GOG_ACCOUNT=<account> gog gmail get <message_id> --format=metadata --json | jq -r '.message.snippet'
```

→ snippetで十分な情報が得られる場合はそれで進める

## Step 3: Draft Reply (NO unnecessary confirmations)

### 3-1: 標準パターン

- 挨拶
- （必要に応じて）謝罪・お礼
- 本文
- 締めの挨拶
- 署名

### 3-2: 確認タイミング

**確認が必要な場合**（これ以外は確認不要）：
- 金額・数字の変更
- 重要な日程の設定
- 法的拘束力のある内容
- 社外への機密情報送信

**確認不要な場合**：
- 定型的な返信（確認OK、承知しました等）
- リストの単純確認
- 追加資料の送付

### 3-3: 提示方法

❌ Bad: 「この内容で送信してよろしいですか？」
✅ Good: 「送信しますか？（修正があれば教えてください）」

## Step 4: Send Email

**全返信（Reply All）がデフォルト**
- ビジネスメールは基本的に全返信
- 個人的な内容のみ個別返信

## Step 5: Post-send Actions

自動実行（質問不要）：
1. relationships.md更新（新規連絡先のみ）
2. todo.md更新（明確なタスクがある場合のみ）
3. git commit & push

## Examples

### Good Example (Minimal Questions)

```
User: 「田中さんへの返信お願い」
Assistant: [並列検索実行] → メール発見 → 本文取得 → 返信ドラフト作成
Assistant: 「以下の内容で送信します：[ドラフト]」
User: 「OK」
Assistant: [送信 & Post-send完了]
```

### Bad Example (Too Many Questions)

```
User: 「田中さんへの返信お願い」
Assistant: 「田中さんのメールアドレスを教えてください」 ❌
Assistant: 「メールが文字化けしています。どうしますか？」 ❌
Assistant: 「この内容で送信してよろしいですか？」 ❌
```

## Implementation Checklist

- [x] gmail_get_body.py 作成（文字化け対策）
- [ ] 検索の並列実行を常に実施
- [ ] 確認フローの見直し（必要最小限に）
- [ ] デフォルトで全返信
- [ ] Post-send自動化
