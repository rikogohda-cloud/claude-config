---
description: "案件サマリー + MTG準備資料 - 単件Slackスレッド要約 / 全件MTG資料生成"
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
  - Glob
  - Task
  - mcp__slack__slack_search_messages
  - mcp__slack__slack_get_channel_history
  - mcp__slack__slack_get_thread_replies
  - mcp__slack__slack_post_message
  - mcp__notion__notion-fetch
  - mcp__notion__notion-create-pages
  - mcp__notion__notion-query-data-sources
---

# /case-summary - 案件サマリー + MTG準備資料

## Input

`$ARGUMENTS` を解釈する:
- `<企業名>` → 単件サマリー（Slack DMに出力）
- `<企業名> --notion` → 単件サマリー（Notion + Slack DMに出力）
- `mtg` → MTG準備資料（全アクティブ案件 → Notionに一括生成）
- 空 or `help` → 使い方を表示して終了

## 設定

設定ファイルを読み取る: `~/.claude/private/case-config.md`

- **案件管理DB data source ID**: case-config.md参照
- **回収リスト / 延滞MASTER / Legal管理**: case-config.md参照
- **GOG_ACCOUNT**: case-config.md「実行ユーザー」セクション参照
- **Slack自分ID**: case-config.md「実行ユーザー」セクション参照
- **Slack Ch**: case-config.md の `アラート投稿先` から Ch ID を取得

---

## コアロジック: 1案件のサマリー生成

以下のステップで1案件のサマリーを生成する。単件モード・MTGモードの両方で使用。

### Step A: Notion DB から基本情報取得

```
mcp__notion__notion-query-data-sources({
  data_source_id: "<case-config.mdのDB data source ID>",
  query: "SELECT * FROM \"collection://<case-config.mdのDB data source ID>\" WHERE 企業名 LIKE '%<企業名>%' LIMIT 5"
})
```
→ DB登録済みなら DPD, 債権額, フェーズ, 担当者, MT残高🤖, 保全実効性🤖, 保全ステータス, 案件ステータス_Legal, 連帯保証, サマリー 等を取得
→ 未登録なら Step B でスプシから直接取得

### Step B: Slack検索

```
mcp__slack__slack_search_messages({ query: "<企業名>" })
```
- 回収関連チャネルのメッセージを検索
- ヒットしたスレッドの `slack_get_thread_replies` で全文取得
- **注意**: 検索でヒットしない場合は `slack_get_channel_history` で回収チャネル（case-config.md参照）の履歴を取得して企業名で絞り込む

### Step C: スプレッドシート最新値で補完

```bash
GOG_ACCOUNT=<case-config.mdのGOG_ACCOUNT> gog sheets metadata <case-config.mdの回収リストID> --json
```
→ 最新シート特定後、企業名で行検索 → DPD・債権額等の最新値でDB情報を補完

列マッピング（case-config.md参照）:
→ **列位置はシートごとにずれるため、2行目ヘッダー名で動的に特定すること**
→ ヘッダー取得: `<シート名>!A2:AQ2` --json → キーワード部分一致で列インデックス特定
→ 対象列: OrgID, 回収状況, 回収担当者, 企業名, 支払期日, 請求額, 支払予定日, 延滞理由, ネクストアクションメモ, 回収手段

### Step C.5: MT残高取得（単件モード時）

単件モードでorgIDが判明している場合、Metabaseから最新MT残高を取得する:

```bash
bash "$HOME/.claude/scripts/metabase-mt-balance.sh"
```

→ 成功時: `~/.claude/private/tmp_mt_balance.json` から対象orgIDの残高を取得
→ 失効/エラー時: DB の MT残高🤖 値をそのまま使用（nullなら「不明」）

保全実効性を自動判定（case-config.md「保全実効性の自動判定」参照）:
- MT残高 >= 債権額の50% → 高
- MT残高 >= 100万 → 中
- MT残高 < 100万 → 低
- MT残高 = 不明 → 不明

**MTGモード時**: Metabase呼び出しは不要。DB の MT残高🤖 と 保全実効性🤖 をそのまま使用（case-alert が毎朝更新済み）。

### Step D: 構造化サマリー生成

以下の7セクションで構造化:

```
■ <企業名>（<債権額>M / DPD<X>）- フェーズ<N> / 担当: <担当者名>

【現在地】
・最新の状況を1-2文で要約

【連絡履歴】
・MM/DD: <誰が><何をした>（<結果>）
・MM/DD: ...
（時系列で直近10件まで）

【先方主張と裏付け状況】
・主張: <先方の主張>
・裏付け: <裏付け資料の提出状況>

【入手済み資料】
・税務申告書: 未取得/取得済み
・資金繰り表: 未取得/取得済み
・その他: <取得済み資料があれば列挙>

【口座・保全情報】
・MT残高: ¥XX（更新日: YYYY-MM-DD）/ 保全実効性: 高/中/低/不明
・判明している借入先・金額
・MT残高不明の場合: 「MT連携なし」と記載

【法的措置の状況】
・保全: <保全ステータス>
・本訴: <本訴ステータス>
・連帯保証: あり/なし

【要判断事項】
・<判断が必要な事項を箇条書き>
```

---

## 単件モード

1. `$ARGUMENTS` から企業名を取得
2. コアロジック（Step A-D）でサマリー生成
3. Slack DM（case-config.md「実行ユーザー」のSlack自分IDに投稿）
4. `--notion` 指定時:
   - `mcp__notion__notion-create-pages` で Notion ページも作成
   - 親ページ: case-config.md の MTG準備資料 親ページ
   - タイトル: `案件サマリー_<企業名>_YYYYMMDD`

---

## MTGモード（`/case-summary mtg`）

### Step 1: Notion DB から全アクティブ案件を取得

```
mcp__notion__notion-query-data-sources({
  data_source_id: "<case-config.mdのDB data source ID>",
  query: "SELECT * FROM \"collection://<case-config.mdのDB data source ID>\" WHERE ステータス = 'アクティブ' ORDER BY DPD DESC"
})
```
→ DBのアクティブ案件一覧を取得（DPD, 債権額, フェーズ, 担当者, MT残高🤖, 保全実効性🤖, 保全ステータス等）

### Step 2: スプシ最新値で補完

```bash
GOG_ACCOUNT=<case-config.mdのGOG_ACCOUNT> gog sheets metadata <case-config.mdの回収リストID> --json
```
→ 直近3ヶ月の `回収状況_YYYYMMDD` シートを取得し、DB案件のorgIDで最新値を補完

### Step 3: 並行でSlackサマリー生成

各案件について Task subagent で並行実行:
- 3-4件ずつバッチで Slack検索 → 構造化サマリー生成
- 各subagentにDB情報 + スプシ最新値を渡す

### Step 4: 引当金情報を追加

```bash
GOG_ACCOUNT=<case-config.mdのGOG_ACCOUNT> gog sheets get <case-config.mdの延滞MASTER ID> "個別引当!A1:Z30" --plain
```
→ 個別引当金対象企業は該当サマリーに引当金情報を追記

### Step 5: Legal管理シートから法的措置情報を補完

```bash
GOG_ACCOUNT=<case-config.mdのGOG_ACCOUNT> gog sheets get <case-config.mdのLegal管理ID> "管理シート本体!A1:BV210" --plain
```
→ orgIDでJOIN → 保全ステータス(Q列), 本訴ステータス(R列), 連帯保証(AD列) の最新値で補完

### Step 6: NotionデータベースエントリとしてMTG準備資料を作成

`mcp__notion__notion-create-pages` で MTG準備資料DBに新規エントリを作成:

- 親データベース: case-config.md の MTG準備資料DB data source ID
- プロパティ:
  - MTG日付（タイトル）: `YYYY-MM-DD`
  - アクティブ案件数: 全アクティブ案件数
  - 高リスク案件数: DPD30+ or 1,000万以上の件数
  - 要注意案件数: DPD10-29の件数
  - 経過観察案件数: DPD5-9の件数
  - ステータス: `完了`
- 本文（content）:

```
<callout icon="📋" color="blue_bg">
  **作成日**: YYYY-MM-DD / **対象期間**: 前回MTG〜本日
  **アクティブ案件**: X件 / **うち高リスク**: X件
</callout>

---

# 高リスク案件（DPD30+ or 1,000万以上）

■ XXX社（15.2M / DPD35）- フェーズ5 / 担当: Eisuke

【事実調査】
・延滞開始: YYYY-MM-DD / DPD: 35
・連絡履歴: （時系列）
・先方主張: 取引先入金遅れ
・裏付け状況: 税務申告書取得済み、入金予定の契約書未取得

【入手済み資料】
・税務申告書: 取得済み / 資金繰り表: 未取得

【口座・保全情報】
・MT残高: ¥XX（更新日: YYYY-MM-DD）/ 保全実効性: 高/中/低/不明
・借入先: （判明分）
・MT残高不明の場合: 「MT連携なし」と記載

【法的措置の状況】
・保全: <保全ステータス> / 本訴: <本訴ステータス>
・連帯保証: あり/なし

【担当者の判断】
・方向性: （Slackでの議論から推定）
・理由: （根拠）

---

# 要注意案件（DPD10-29）

■ YYY社（5.2M / DPD15）...

---

# 経過観察案件（DPD5-9）

■ ZZZ社（2.1M / DPD7）...

---

# 引当金情報
<table header-row="true">
<tr><td>企業名</td><td>債権額</td><td>DPD区分</td><td>引当金額</td></tr>
...
</table>
```

### Step 7: Slack通知

`#case-alerts` チャネル（case-config.md の Ch ID）に通知:
```
📋 法的手続き審査MTG 準備資料を作成しました

対象: アクティブ案件 X件
高リスク: X件 / 要注意: X件 / 経過観察: X件

<NotionページURL>
```

---

## Notes
- AskUserQuestion は使用しない（非対話で完結）
- Slack検索の制限に注意: 自分の発言が検索にヒットしない場合がある。企業名でヒットしない場合は channel_history で補完
- データ取得時にエラーが出た場合はスキップし、取得できたデータのみでサマリーを作成
- 金額は万円表記（小数点1桁）。例: 8,930,000 → 893.0万、30,000,000 → 3,000.0万
- MTGモードは案件数が多い場合10-15分かかる可能性あり
- MTGモードのデータ優先順位: Notion DB > スプシ最新値 > Slack情報
- gogcli: `gog` コマンドがPATHに入っていること
