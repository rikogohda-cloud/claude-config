---
description: "週次Slackサマリーを自動生成し、Notionに投稿。DBへのインシデント/PJ自動登録も行う"
allowed-tools: mcp__slack__slack_search_messages, mcp__slack__slack_get_channel_history, mcp__slack__slack_list_channels, mcp__slack-capital__slack_search_messages, mcp__slack-capital__slack_get_channel_history, mcp__notion__notion-create-pages, mcp__notion__notion-fetch, mcp__notion__notion-search, mcp__notion__notion-query-data-sources, Bash, Read, Write, Glob, Grep, Task
---

# 週次Slackサマリー自動生成

引数: `$ARGUMENTS`（オプション: 日付範囲 `YYYYMMDD-YYYYMMDD`。未指定なら直近1週間）

## 重要ルール
- AskUserQuestion は使用しない（非対話で完結）
- すべてのステップを自動実行する
- エラーが発生しても可能な範囲で続行する

---

## Phase 1: 日付範囲の決定

引数 `$ARGUMENTS` を解析する:
- `YYYYMMDD-YYYYMMDD` 形式なら、その範囲を使用
- 未指定なら、今日から7日前～昨日を対象期間とする
- Slack検索用に `after:YYYY-MM-DD before:YYYY-MM-DD` 形式に変換

---

## Phase 2: Slackチャネルからデータ収集

以下のチャネルグループからメッセージを検索する。**並行実行で効率化すること。**

UPSIDER本体WS (`mcp__slack__slack_search_messages`) を使用:

### 部門別チャネルマッピング

| 部門 | チャネル名 |
|------|-----------|
| Credit（与信） | `#credit`, `#legal_credit`, `#dev_credit_system` |
| Data | `#data`, `#prj_c4i` |
| 経理 | `#corp_accounting` |
| Finance（財務） | `#biz_finance` |
| CorpIT | `#new_urit`, `#corpit_security-team` |
| Capital | `#biz_ubdf`, `#biz_board`, `#prj_online_lending` |
| Growth | `#biz_sales`, `#new_グロース部門_リーダーズ`, `#new_biz_management` |
| Panda | `#pjt_panda_members` |
| Operations | `#biz_operation_release` |
| Legal/Compliance | `#mizuho-risk-screening-operations` |

### 検索方法

各チャネルに対して `in:#channel_name after:YYYY-MM-DD before:YYYY-MM-DD` で検索する。

**並行度を上げるため、Task subagent を活用する:**
- 4〜5個の Task subagent を並行起動し、部門グループごとに検索を分担
- 各 subagent は担当チャネルのメッセージを取得し、チャネルごとのサマリーを返す

各 subagent への指示テンプレート:
```
以下のSlackチャネルからメッセージを検索し、チャネルごとに要約してください。

検索条件: in:#<channel> after:<start_date> before:<end_date>
ツール: mcp__slack__slack_search_messages

チャネル: <チャネルリスト>

各チャネルについて以下を出力:
1. チャネル名
2. 主要トピック（箇条書き、各トピック1-2行）
3. 重要な決定事項やアクションアイテム
4. インシデント・リスクに該当しそうな事項（あれば）
5. 新規プロジェクトや進捗報告に該当しそうな事項（あれば）

メッセージが少ない/無いチャネルは「特筆事項なし」と記載。
```

---

## Phase 3: サマリー生成

収集したデータを以下の構造でまとめる:

### 3-1. エグゼクティブサマリー

全チャネルの情報を横断的に分析し、以下を生成:

**重要事項（3〜5項目）**:
- 経営判断に影響する重要トピックを抽出
- 各項目は1-2行で簡潔に
- 関連チャネル名を括弧書きで付記

**部門別注意事項**:
- 各部門で特に注目すべき点を1行ずつ

### 3-2. 部門別詳細

各部門について、トグル（`▶`）形式で:
```
▶ **部門名**
  ▶ **#channel_name**
    - トピック1の要約
    - トピック2の要約
    ...
```

---

## Phase 4: DB自動登録

サマリーからインシデント・プロジェクト情報を抽出し、既存DBと照合して新規分のみ登録する。

### 4-1. 既存データ確認

以下のDBを並行クエリして、重複を避ける:
- **リスク & インシデントDB** (`collection://d1177745-5429-4c1c-bb3a-687c0e5f1dbb`): `mcp__notion__notion-query-data-sources` で最近のエントリを取得
- **プロジェクトDB** (`collection://109b79ac-15cf-4c34-b5d9-4596e7b7cdad`): 同上
- **労務インシデントDB** (`collection://845750c1-2f84-4ffa-80ac-8903298f088d`): 同上
- **顧客クレームDB** (`collection://e28b0381-bcba-4645-86b5-44936e651851`): 同上

### 4-2. 新規エントリ登録

抽出した事項を適切なDBに登録する。`mcp__notion__notion-create-pages` を使用:

**リスク & インシデントDB**:
```json
{
  "parentId": "d1177745-5429-4c1c-bb3a-687c0e5f1dbb",
  "title": "インシデント内容",
  "properties": {
    "本部": { "multi_select": "[\"部門名\"]" },
    "状況": { "select": "Open" },
    "影響・背景": { "text": "概要" },
    "対応・ネクストステップ": { "text": "対応内容" },
    "発生日": { "date": "YYYY-MM-DD" }
  }
}
```

**プロジェクトDB**:
```json
{
  "parentId": "109b79ac-15cf-4c34-b5d9-4596e7b7cdad",
  "title": "プロジェクト名",
  "properties": {
    "ステータス": { "select": "On Track" },
    "フェーズ": { "select": "進行中" },
    "今週の差分": { "text": "進捗内容" },
    "本部": { "select": "部門名" }
  }
}
```

**労務インシデントDB** / **顧客クレームDB** も同様に、該当があれば登録。

---

## Phase 5: Notionページ作成

`mcp__notion__notion-create-pages` で以下を作成:

- **親ページ**: `2ad93c7ce32d80a9920deb13a7579d4e`（Slackサマリ）
- **タイトル**: `Slackサマリ_YYYYMMDD-YYYYMMDD`（対象期間）

### Notion Markdown フォーマット

```markdown
# エグゼクティブサマリー

## 重要事項
1. **項目タイトル** — 説明文（#channel_name）
2. ...

## 部門別注意事項
- **Credit**: 注意事項
- **Data**: 注意事項
- ...

---

# 部門別詳細

▶ **Credit（与信）**
	▶ **#credit**
		- トピック1
		- トピック2
	▶ **#legal_credit**
		- トピック1
	▶ **#dev_credit_system**
		- トピック1

▶ **Data**
	▶ **#data**
		- トピック1
	▶ **#prj_c4i**
		- トピック1

▶ **経理**
	▶ **#corp_accounting**
		- トピック1

▶ **Finance（財務）**
	▶ **#biz_finance**
		- トピック1

▶ **CorpIT**
	▶ **#new_urit**
		- トピック1
	▶ **#corpit_security-team**
		- トピック1

▶ **Capital**
	▶ **#biz_ubdf**
		- トピック1
	▶ **#biz_board**
		- トピック1
	▶ **#prj_online_lending**
		- トピック1

▶ **Growth**
	▶ **#biz_sales**
		- トピック1
	▶ **#new_グロース部門_リーダーズ**
		- トピック1
	▶ **#new_biz_management**
		- トピック1

▶ **Panda**
	▶ **#pjt_panda_members**
		- トピック1

▶ **Operations**
	▶ **#biz_operation_release**
		- トピック1

▶ **Legal/Compliance**
	▶ **#mizuho-risk-screening-operations**
		- トピック1

---

# DB登録結果

## 新規登録
- リスク & インシデント: X件
- プロジェクト: X件
- 労務インシデント: X件
- 顧客クレーム: X件

（登録がない場合は「新規登録なし」と記載）
```

---

## Phase 6: 完了報告

最終的に以下を出力する:
1. 作成したNotionページのURL（あれば）
2. DB登録件数のサマリー
3. 対象期間
4. 特筆すべきエラーや警告（あれば）
