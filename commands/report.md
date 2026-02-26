---
description: スプレッドシートKPIレポート取得・要約
argument-hint: <シート名 or URL or spreadsheetId>
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---

# /report - Spreadsheet Report

Args: $ARGUMENTS

## Overview
Google Sheets からデータを取得し、KPIサマリーやレポートを生成する。

## Identity
- naoki.ishigami / 石神直樹

## Accounts
| Alias | GOG_ACCOUNT |
|---|---|
| sider | naoki.ishigami@up-sider.com |
| cap | naoki.ishigami@upsidercap.com |

## 登録済みレポート

ここに頻繁に確認するスプレッドシートを登録できる。
ユーザーが新しいスプレッドシートを指定した場合、AskUserQuestion で登録するか確認する。

| エイリアス | SpreadsheetId | シート/範囲 | アカウント | 説明 |
|---|---|---|---|---|
| (例) capital-kpi | 1ABC...xyz | KPI!A1:Z50 | cap | Capital事業KPI |

**注意**: 初回実行時はスプレッドシートが未登録のため、ユーザーに登録を促す。
登録情報は `~/.claude/private/report-config.md` に保存する。

## Step 1: レポート対象の特定

If $ARGUMENTS がエイリアスに一致:
→ 登録済み設定を使用

If $ARGUMENTS が SpreadsheetId or URL:
→ URLからSpreadsheetIdを抽出（`/d/` と `/edit` の間）
→ メタデータを取得:
```bash
GOG_ACCOUNT=<account> gog.exe sheets metadata <spreadsheetId> --json
```
→ シート一覧を表示し、AskUserQuestion で対象シート・範囲を確認

If $ARGUMENTS が空:
→ 登録済みレポート一覧を表示
→ AskUserQuestion でどれを実行するか選択

## Step 2: データ取得

```bash
GOG_ACCOUNT=<account> gog.exe sheets get <spreadsheetId> "<シート名>!<範囲>" --plain
```

- 範囲が広い場合は複数回に分けて取得
- ヘッダー行を自動検出

## Step 3: 分析・要約

取得したデータを分析し、以下を出力:

```
## 📊 [レポート名] サマリー
**取得日時**: YYYY-MM-DD HH:MM
**データソース**: [スプレッドシート名] / [シート名]

### ハイライト
- [主要KPIの数値とトレンド]
- [前回比/前月比の変化]
- [注目すべき異常値]

### データテーブル
| ... | ... | ... |
|---|---|---|

### 所見
- [データから読み取れるポイント]
```

## Step 4: レポート登録（初回のみ）

新しいスプレッドシートの場合、AskUserQuestion で:
- エイリアス名
- デフォルトのシート/範囲
- 使用アカウント
を確認し、`~/.claude/private/report-config.md` に保存

## Notes
- gog.exe の sheets get は `--plain` でTSV出力（パースしやすい）
- 大きなシートは範囲を絞って取得
- Capital関連は `cap` アカウント、それ以外は `sider` アカウント
