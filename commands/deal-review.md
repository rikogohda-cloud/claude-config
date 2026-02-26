---
description: "Deal Review - ベンチャーデット案件の初期取上げ検討ドラフトを自動生成"
allowed-tools:
  - Read
  - Bash
  - Write
  - Glob
  - Grep
  - Task
  - WebSearch
  - WebFetch
  - mcp__notion__notion-fetch
  - mcp__notion__notion-create-pages
  - mcp__notion__notion-update-page
  - mcp__notion__notion-search
  - mcp__notion__notion-query-data-sources
  - mcp__slack-capital__slack_post_message
---

# Deal Review: 初期取上げ検討ドラフト自動生成

## Input

`$ARGUMENTS` を解釈する:
- `<Driveパス> <Notion親ページID>` → 直接実行
- `poll` → Notion DB (data source: `23ef4b78-a403-4234-8721-f1d91ef0e14c`) からステータス=「未処理」or NULLを1件取得して実行。完了後ステータス更新+レポートURL記入
- 空 or `help` → 使い方を表示して終了

poll モード: ドライブレターは `H:` に正規化。エラー時はステータス「エラー」+メモ記入。

---

## 品質基準（生成時に遵守）

生成後の自己レビューPhaseは廃止。**以下を生成時に必ず満たすこと:**
1. 全テーブルにデータ区分（【実績/見込/計画/想定】）+ `> 出所: ファイル名 / シート名` 脚注
2. 「判断の核心」に具体的Go条件 + NEXTアクション（「誰に何を聞く」レベル）
3. 推測を含む記述に【想定】タグ。ソースで裏取りできない主張に🚩callout
4. 検討方向性は明確に判断がつく場合を除き「現時点では判断つかず」をデフォルト
5. データ不足セクションは「データ不足: 〇〇ファイルが必要」と明記（空にしない）

---

## Process

### Phase 1: フォルダスキャン

1. `find "<Driveパス>" -type f \( -name "*.xlsx" -o -name "*.csv" -o -name "*.pdf" -o -name "*.xls" -o -name "*.gsheet" -o -name "*.gdoc" -o -name "*.gslides" \) 2>/dev/null`
2. **ファイル0件時のフォールバック**:
   - Notion親ページID配下の子ページを `notion-fetch` で取得（面談メモ等）
   - `gog drive list --parent=<folderID>` or `gog drive search "<企業名>" --account=naoki.ishigami@upsidercap.com`
   - `.gsheet` → `gog drive search` でID取得 → `gog sheets get`
3. ファイル分類（優先順: 財務モデル→事業計画→月次試算表→KPI→債権→Cap table→ピッチ→その他）
4. CF予測チェック: `<Driveパス>/../02. CF予測/` に `.gsheet` があれば連携対象マーク

### Phase 2: データ抽出

Task subagent で並行抽出。ただし**ファイル3個以下ならsubagent不要（直接処理）**。

**読み取り方法**: memory の `deal-review.md` 参照（Excel: openpyxl→pandas→PowerShell / CSV: iconv→python / PDF: pdftotext→Read→pdfjs-dist）

**抽出項目**: 財務モデル(PL/BS/EBITDA) / 事業計画(KPI/売上/費用) / 月次試算表(月次PL・BS・キャッシュ) / KPI(GMV/LTV/CAC) / 債権(延滞率/デフォルト率) / Cap table(株主/Valuation) / ピッチ(事業概要/チーム) / CF予測(MTデータ/3シナリオ/マイルストーン)

### Phase 3: 競合分析（WebSearch — Phase 2と並行可）

Task subagent (general-purpose) で以下を調査:
1. 国内競合 3-4社 / 海外コンパラブル 2-3社
2. 対象企業の最新ニュース・プレスリリース

### Phase 4: Notionページ一発作成

**Phase 2,3 の全データが揃ってから** `notion-create-pages` で完成版を1回で作成する。
- テンプレート: `~/.claude/private/deal-review-template.md` を Read で読み取って使用
- 親ページ: 引数で指定されたNotion親ページID
- タイトル: `【AI Draft】<案件コード>_初期取上げ検討（自動生成）`

**重要**: 骨格作成→後から更新の2段階方式は禁止。データが揃った状態で1回の `notion-create-pages` で全セクションを含む完成版を作成する。これにより `replace_content_range` の fetch-modify-update サイクルが不要になる。

やむを得ず更新が必要な場合（借入一覧の追記等）のみ `notion-update-page` を使用。その際は memory の `deal-review.md` のNotion更新注意点を参照。

### Phase 5: 完了報告 + Slack通知

**出力:**
1. NotionページURL
2. 読み取ったファイル一覧と処理結果
3. データ不足セクション（あれば）
4. 推奨NEXTアクション

**Slack通知** (Capital WS `biz_ubdf` = `C069192C2HY`):
```
【Deal Review完了】<案件コード> <企業名>

初期取上げ検討ドラフトを作成しました。
<NotionページURL>

■ 検討方向性: <前向き/消極/判断つかず>
■ 主要論点:
  - <論点1>
  - <論点2>
  - <論点3>
■ NEXTアクション: <最重要アクション>
■ データ不足: <不足項目 or なし>
```

poll モード: Notion DB ステータス「完了」+ レポートURL記入。

---

## ルール

- AskUserQuestion は使用しない（非対話で完結）
- エラー時も可能な範囲で続行。読めないファイルはスキップし最終報告に含める
- 同一指標が複数ソースで異なる場合、両方記載+差異理由を脚注
- Net Debt計算にはコミットメントライン・流動化枠の存在を注記
- CF予測は空にしない（BS変動から簡易推計+【想定】タグ）
- Notion記法: テーブル `header-row="true"` / callout `icon`+`color` / セクション見出し `{color="gray_bg"}`
