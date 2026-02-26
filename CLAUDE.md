# Global Instructions

## 言語
- 回答は常に日本語で行うこと（コード・コマンド・ファイル名は英語のまま）
- コミットメッセージ・PR説明文は英語

## スタイル
- 簡潔に回答する。過剰な説明は不要
- コードにはエラーハンドリングを必ず含める
- 型安全性を重視（any/interface{} を避ける）
- 関数・メソッドには戻り値の型を明示する

## 技術スタック別ルール
- Go: エラーは明示的に処理、errors.Is/errors.As を使用
- Rust: unwrap() は避け、? 演算子・anyhow/thiserror を使用
- TypeScript: strict モード前提、as キャストは最小限に
- Python: type hints 必須、mypy 互換のコードを書く
- PowerShell/Shell: Windows 環境（PowerShell がデフォルト）

## ワークフロー
- テストを書いてから実装（TDD を推奨）
- 変更後は該当テストを実行して検証
- git commit は Conventional Commits 形式（英語）

## 検証コマンド
- Go: go vet ./... && go test ./...
- Rust: cargo clippy && cargo test
- TypeScript: npx tsc --noEmit && テスト実行
- Python: mypy . && pytest

## Private データの自動記録
以下の作業中に該当情報が得られた場合、対応するファイルに追記すること。

### ~/.claude/private/relationships.md
- メール対応・議事録・Slack やりとり等で、新しい人物や関係性の情報が判明した場合
- 既存エントリのトーンや役職に変更があった場合は更新
- Format: `| Name | Email | Role / Company | Relationship | Tone |`

### ~/.claude/private/todo.md
- メール・議事録・会話から新しいタスクや期限付き依頼が発生した場合
- 完了したタスクは Active から Done に移動
- Format: `- [ ] \`YYYY-MM-DD\` タスク内容 (from: 誰 / 期限: いつ)`

### ~/.claude/private/agent-work.md
- AI自身の継続タスク（調査中・次回チェック予定等）を記録
- ユーザーの todo.md とは別管理。セッション跨ぎの作業引き継ぎ用
- 完了タスクは Done に移動し、1週間後に削除可

### 対象となる作業
- /check-mail の実行
- 議事録の作成・要約
- Slack メッセージの確認・返信
- ミーティングノートの処理
- その他、人物情報やタスクが含まれるあらゆる作業

## Slack 投稿ルール
- メッセージに「Claude:」等の AI 由来プレフィックスを絶対に付けない
- ユーザー本人が書いたかのように自然な文面で投稿する
- 署名・免責・AI生成である旨の注記を入れない
- **文体は `~/.claude/private/voice-guide.md` に従うこと**（一人称・文末・敬語レベル・口癖を相手に合わせて使い分ける）

### Slack送信前の必須チェック
**重要: 以下を確認せずに送信してはならない**

1. **スレッド返信の場合**
   - スレッドの**冒頭メッセージを必ず表示**してユーザーに確認
   - 「このスレッドでよろしいですか？」と明示的に確認
   - スレッドIDだけでなく、実際のメッセージ内容を見せる

2. **メンション構文の確認**
   - ユーザーメンション: `<@USER_ID>` 形式（例: `<@U05E7AGC3U0>`）
   - 単なる `USER_ID` や `U05E7AGC3U0 Name` は機能しない
   - チャンネルメンション: `<#CHANNEL_ID>` 形式

   **よくある間違い例:**
   ```
   ❌ U05E7AGC3U0
   ❌ @U05E7AGC3U0
   ❌ U05E7AGC3U0 山田太郎
   ✅ <@U05E7AGC3U0>
   ```

3. **送信前の最終確認プロセス**
   - ユーザーから「送信して」と言われても、必ず送信内容を再提示
   - メンション、絵文字、リンクなどの構文が正しいか確認
   - 「以下の内容で送信します。よろしいですか？」と確認を取る

4. **不確実な構文への対処**
   - Slackの構文が不確かな場合は、送信前に過去のメッセージを検索して確認
   - 推測で送信しない

## メール対応の標準フロー
**原則: ユーザーへの質問を最小限に**

### 1. メール検索（質問前に全方法を試す）
- 名前・ドメイン・未返信メールを**並列検索**
- 全て失敗した場合のみ質問

### 2. メール本文取得（文字化けさせない）
```bash
~/.claude/bin/gmail_get_body.py <message_id> <account>
```
または snippet取得（常に正しくデコード済み）

### 3. 返信ドラフト作成（過剰な確認をしない）
- 定型返信・単純確認は確認不要
- 重要事項（金額・日程・機密情報）のみ確認
- 提示方法: 「送信します（修正あれば教えて）」

### 4. 送信（デフォルト全返信）
- ビジネスメールは Reply All
- 個人的内容のみ個別返信

### 5. Post-send（自動実行）
- relationships.md / todo.md 更新
- git commit & push

詳細: `~/.claude/workflows/email-response-flow.md`

## 外部サービスへのアクセス方法
- **Google Sheets**: `google-sheets` MCPサーバー (`mcp-google-sheets`) を使うこと。WebFetchでは認証が通らないため絶対に使わない。`docs.google.com/spreadsheets` のURLが来たらスプレッドシートIDを抽出し、MCPツール (`get_sheet_data`, `list_sheets` 等) で直接アクセスする
- **Slack**: `slack` MCPサーバーを使う
- **Notion**: `notion` MCPサーバーを使う
- **kintone**: `kintone` MCPサーバーを使う
- **原則**: 認証が必要なURL (Google Docs, Sheets, Drive, Slack, Notion 等) に対して WebFetch を試みてはならない。必ず対応するMCPサーバーのツールを使うこと

## Credit System データ参照ルール
- 組織データ確認時は **Credit API のリアルタイムデータのみ**を取得する
- Firestore の履歴データは参照不要（合意日: 2026-02-23）
- 取得方法:
  ```bash
  TOKEN=$(gcloud auth print-identity-token)
  curl -X POST "https://credit-api-service-rmllozm6ia-an.a.run.app/api/v3/predict/batch" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"model_artifact_path": "gs://...", "org_id_list": ["ORG_ID"], "injections": [], "delinquency_threshold_days": 30}'
  ```

## 禁止事項
- .env, credentials, secret ファイルの内容をコミットに含めない
- 本番環境への直接操作は行わない
- パスワード・APIキー等の機密情報をハードコードしない
