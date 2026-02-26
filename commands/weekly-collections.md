---
description: 債権回収 週次サマリーをNotionに作成
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
  - Glob
  - AskUserQuestion
  - mcp__notion__notion-search
  - mcp__notion__notion-fetch
  - mcp__notion__notion-create-pages
  - mcp__notion__notion-update-page
---

# /weekly-collections - 債権回収 週次サマリー

毎週月曜日にスプレッドシートから債権回収データを収集し、Notionに週次まとめページを作成する。

## データソース
- **回収リスト**: SpreadsheetId `1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA`
- **延滞MASTER**: SpreadsheetId `18KCsBcryEx0V6UM-K3PGNyj08Tm_XtD-lCcHDaRZWWk`
- **Legal管理**: SpreadsheetId `10kATvj1sMOLGt8GGn718Uil9KmvtDbR9OVZq2mF8fVw`
- **GOG_ACCOUNT**: `riko.gohda@up-sider.com`

## Notion 投稿先
- **Parent page**: `30693c7ce32d8008a6f5cedf3a00f100`
  (Collection_Claudecodeによる週次まとめ)

## Step 1: データ収集（並行実行）

以下を並行で取得する:

### 1a. 回収率（月次推移）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA "回収率(社数/金額)!A1:AQ15" --plain
```

### 1b. 行動指標
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA "行動指標!A1:R31" --plain
```

### 1c. 複数月延滞（上位案件）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA "複数月延滞!A1:T50" --plain
```

### 1d. GP集計表
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA "GP集計表(10月以降) !A1:Z30" --plain
```

### 1e. 最新の回収状況シート
メタデータからシート名一覧を取得し、最新の`回収状況_YYYYMMDD銀行振込`と`回収状況_YYYYMMDD口座振替`シートを特定:
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets metadata 1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA --json
```
→ 最新2シートの先頭5行（サマリー行: 未回収件数・未回収金額）を取得:
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA "<最新銀行振込シート名>!A1:T5" --plain
```
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA "<最新口座振替シート名>!A1:T5" --plain
```

### 1f. PRESIDENT年会費（最新）
最新の`[PRESIDENT]年会費回収状況_YYYYMMDD`シートの先頭行を取得

### 1g. 延滞率・Gross Exposure（延滞MASTERのSummaryシート）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 18KCsBcryEx0V6UM-K3PGNyj08Tm_XtD-lCcHDaRZWWk "Summary!A1:AR20" --plain
```
→ 当月請求額、延滞債権(DPD1+)、Gross Exposure、延滞率を直近6ヶ月分抽出

### 1h. DPDエイジング・引当金内訳（延滞MASTERの引当金内訳シート）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 18KCsBcryEx0V6UM-K3PGNyj08Tm_XtD-lCcHDaRZWWk "引当金内訳!A1:BC20" --plain
```
→ DPD30以下、DPD31-60、DPD61-90、DPD90+ の残高と個別引当金対象を抽出

### 1i. 個別引当金（延滞MASTERの個別引当シート）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 18KCsBcryEx0V6UM-K3PGNyj08Tm_XtD-lCcHDaRZWWk "個別引当!A1:Z30" --plain
```
→ 個別引当金対象企業・DPD区分・要引当額を取得

### 1j. 受任通知・破産通知（回収リストの受任通知シート）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 1mFitr3VwRT7TduMcQE1xAK2OSFBUW_RilPimrWFdCDA "受任通知・破産通知!A1:Z30" --plain
```
→ 法的手続きに移行済みの案件一覧

### 1k. 債権売却実績（延滞MASTERの債権売却シート）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 18KCsBcryEx0V6UM-K3PGNyj08Tm_XtD-lCcHDaRZWWk "債権売却!A1:Z20" --plain
```

### 1l. 前週のNotionサマリー（差分比較用）
```
mcp__notion__notion-search({ query: "週次回収サマリー" })
```
→ 直前の週次サマリーページを取得し、数値を比較用に保持

### 1m. Legal管理シート（進行中案件）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 10kATvj1sMOLGt8GGn718Uil9KmvtDbR9OVZq2mF8fVw "管理シート本体!A1:V210" --plain
```
→ 全案件の基本情報（No, 社名, 担当, 弁済期限, メモ, ステータス, 延滞額, 回収額, 仮差押金額等）を取得
→ 案件ステータス列（I列）でフィルタ: 「進行中」「対応保留中」を抽出
→ メモ日付列（H列）で直近1週間に更新があった案件を特定

### 1n. Legalダッシュボード（パイプライン集計）
```bash
GOG_ACCOUNT=riko.gohda@up-sider.com gog.exe sheets get 10kATvj1sMOLGt8GGn718Uil9KmvtDbR9OVZq2mF8fVw "（作成中）ダッシュボード!A1:F15" --plain
```
→ 仮差押手続き・本訴手続きの各ステージ別件数

## Step 2: 分析・要約

### 2a. 回収率トレンド
- 直近3ヶ月の社数ベース・金額ベース回収率の推移
- 前月比の増減を矢印で表示
- 銀行振込 vs 口座振替の比較

### 2b. 延滞率・ポートフォリオ健全性 ★NEW
- Summaryシートから: Gross Exposure、延滞債権(DPD1+)、延滞率（= 延滞債権 / Gross Exposure）
- 直近6ヶ月のトレンドを表示
- 延滞率が前月比で悪化している場合は赤でハイライト

### 2c. DPDエイジング分布 ★NEW
- 引当金内訳シートから: DPD30以下、DPD31-60、DPD61-90、DPD90+ の残高
- 前月比での各バケットの増減を計算
- DPD90+の増加は特に注目（引当金積み増しの要否判断）
- 個別引当金対象債権の内訳も表示

### 2d. 最新期の回収状況
- 銀行振込: 未回収件数・金額、主要未回収案件（上位5件）
- 口座振替: 未回収件数・金額、主要未回収案件（上位5件）
- 各案件の担当者・ステータス・次アクション

### 2e. 行動指標
- ネクストアクション消化率
- チーム別の回収件数・回収割合・行動指標達成率

### 2f. 複数月延滞
- 複数月にわたり未回収の企業一覧
- 延滞額の大きい案件トップ10
- 各案件の担当者と現在のステータス

### 2g. 法的対応ステータス（Legal管理シート連携）
Legal管理シートの実データから以下を作成:

#### 2g-1. 法的対応パイプライン
ダッシュボードシートの仮差押・本訴の各ステージ別件数をそのまま表示。

#### 2g-2. 進行中案件の詳細
ステータスが「進行中」の全案件を延滞額降順で一覧化:
- 企業名、延滞額、法的手続きの現在ステージ（内容証明/仮差押/本訴/執行）
- 最新のメモ内容（直近の動き）
- 仮差押成功額・回収額

#### 2g-3. 今週の法的アクション
メモ日付が直近1週間以内の案件を抽出:
- 新規に法的手続きを開始した案件
- ステータスが変化した案件（回収完了、回収断念、対応終了など）
- 裁判所の決定・発令があった案件
- 入金・回収があった案件

#### 2g-4. 次のアクション・期限
メモ欄から裁判期日・支払期限・供託金払渡予定日等を抽出:
- 今週〜来週に期限が到来するアクション
- 裁判所への提出物・対応が必要な事項

#### 2g-5. 対応保留中案件
ステータスが「対応保留中」の案件一覧（内容証明不送達等で次アクション要検討）

#### 2g-6. 法的対応の回収実績サマリー
Legal管理シート全体から集計:
- 総案件数、回収完了件数、回収断念件数、進行中件数
- 内容証明のみで回収できた件数・金額
- 仮差押→回収完了の件数・金額
- 回収完了案件の合計回収額

### 2h. 週次差分 ★NEW
前週のNotionサマリーと比較:
- 未回収金額の前週比（銀行振込・口座振替それぞれ）
- 延滞率の前週比
- 今週新たに発生した延滞企業
- 今週回収完了した案件
- DPDバケット間の移動（悪化した案件）

### 2i. 引当金インパクト ★NEW
- 一般引当金 vs 個別引当金の残高
- 個別引当金対象の新規追加候補（DPD90+に新規流入）
- 債権売却実績（直近の売却があれば）
- 次回決算への影響見込み

### 2j. 回収P&L貢献（Creditチームの価値可視化）
Legal管理シートと回収リストから以下を算出:
- **月次回収額**: 当月の回収完了案件の合計金額
- **累計回収額**: Legal対応開始以降の合計回収額（¥709M+）
- **損失回避額**: 回収完了した案件の延滞額合計 = Creditチームがなければ丸損だった金額
- **回収コスト**: 供託金支出（仮差押の担保金）※多くは返還済
- **回収ROI**: 回収額 / 回収コスト
- **債権売却**: 売却先・売却額・損失額（額面比）
- 前月比で回収額の増減を表示

### 2k. Credit × GMV連動指標
延滞MASTERのGross Exposureと回収実績を組み合わせ:
- **Gross Exposure推移 × 延滞率推移** — GMV成長と延滞率の並行推移（6ヶ月）
- **回収率 × Gross Exposure** — GMVが伸びても回収率が維持されているか
- **内容証明→即回収率** — 法的アクション1通あたりの回収効果（抑止力の定量化）
- **早期介入効果** — DPD30以内に法的対応した案件 vs DPD60以降の回収率差
- 延滞率が抑制されている = Creditチームが安全なGMV成長を支えている、というメッセージ

### 2l. オペレーション効率
Legal管理シートの全案件データから分析:
- **法的手続き別の成功率**: 内容証明のみ回収 / 仮差押→回収 / 本訴→回収 / 回収断念の割合
- **平均回収期間**: 弁済期限→回収日の平均日数（手続き種別ごと）
- **担当者別実績**: 木村/伊澤それぞれの担当件数・回収件数・回収額・回収率
- **エスカレーション適時性**: 内容証明→仮差押→本訴の各ステップにかかった日数
- 改善ポイントの示唆（ボトルネック特定）

### 2m. 注目事項・アクションアイテム
- 大口未回収案件の動き
- 法的対応が必要な案件（2gの結果をサマリー）
- 前週から変化があった案件（2hの結果をサマリー）
- 引当金関連で経理への連携が必要な事項
- 回収P&L・GMV連動の注目ポイント

## Step 3: Notionページ作成

以下のフォーマットでNotionページを作成する:

```
mcp__notion__notion-create-pages({
  parent: { page_id: "30693c7ce32d8008a6f5cedf3a00f100" },
  pages: [{
    properties: { title: "週次回収サマリー YYYY/MM/DD" },
    content: <下記フォーマット>
  }]
})
```

### ページフォーマット（Notion Enhanced Markdown）

ページは以下のセクション順で構成する。Notionの<table>/<callout>タグを使用。

```
# 週次差分サマリー
（前週比の主要変動をcalloutで冒頭に表示）
<callout icon="📊" color="blue_bg">
  **前週比**: 未回収金額 ¥XXM → ¥XXM (±XX%) / 延滞率 X.XX% → X.XX%
  **新規延滞**: N社 / **回収完了**: N社
</callout>

# 延滞率・ポートフォリオ健全性
（Gross Exposure、延滞債権、延滞率の直近6ヶ月推移テーブル）
<table> で延滞率が悪化月は <span color="red"> で表示

# DPDエイジング分布
（DPD区分別の残高テーブル + 前月比増減）
<callout> でDPD90+が増加している場合は警告

# 回収率トレンド（直近3ヶ月）
（社数ベース・金額ベースの回収率テーブル）

# 最新期の未回収状況
## 銀行振込（YYYY/MM/DD）
（未回収件数・金額 + 主要案件テーブル）
## 口座振替（YYYY/MM/DD）
（同上）

# 行動指標
（ネクストアクション消化率 + チーム別パフォーマンステーブル）

# 複数月延滞（要注意案件）
（延滞額の大きい案件テーブル）

# 法的対応ステータス
## パイプライン概要
<callout> で仮差押・本訴の各ステージ別件数を表示（ダッシュボードデータ）

## 進行中案件（延滞額順）
<table> で企業名・延滞額・現在ステージ・最新動き・仮差押成功額
大口案件（¥10M以上）は太字で強調

## 今週の法的アクション
（直近1週間にメモ更新があった案件を時系列で表示）
- 新規開始 / ステータス変更 / 裁判所決定 / 入金・回収

## 次のアクション・期限
<table> で期限日・企業名・対応内容
期限が今週中のものは <span color="red"> で強調

## 対応保留中
（内容証明不送達等で次アクション要検討の案件リスト）

## 法的回収実績
<table> で総案件数・回収完了・回収断念・進行中・合計回収額
内容証明のみ回収 vs 仮差押後回収 vs 本訴後回収の内訳

# 引当金インパクト
（一般引当 vs 個別引当の残高テーブル + 個別引当対象企業リスト）
<callout> で次回決算への影響見込み

# Creditチーム 回収P&L
<callout> で当月回収額・累計回収額・回収ROIをハイライト
<table> で月次回収額推移（直近6ヶ月）
- 損失回避額 = 回収した延滞額合計
- 回収コスト（供託金等）と回収ROI
- 債権売却損の内訳

# Credit × GMV連動
<table> でGross Exposure × 延滞率 × 回収率の6ヶ月推移
- GMV成長と延滞率のバランスを可視化
- 内容証明→即回収率（法的アクションの抑止力効果）
- 早期介入 vs 遅延介入の回収率比較
<callout> で「GMVがX%成長する中、延滞率はX%に抑制」のメッセージ

# オペレーション効率
## 法的手続き別 成功率
<table> で手続き種別ごとの件数・成功件数・成功率・平均回収期間
## 担当者別実績
<table> で担当者ごとの件数・回収件数・回収額・回収率
## 改善ポイント
（ボトルネック特定・エスカレーション適時性の示唆）

# 注目事項・アクションアイテム
（上記分析から導出された具体的なアクションを箇条書き）
- 大口リスク案件
- オペレーション改善ポイント
- 経理連携事項
- 回収P&L・GMV連動の注目ポイント
```

## Step 4: 完了報告

- 作成したNotionページのURLを表示
- 前週比で大きな変動があった項目をハイライト

## Notes
- データ取得時にエラーが出た場合はスキップし、取得できたデータのみでまとめを作成
- 金額は円単位で3桁カンマ区切り表示
- 回収率は小数点2桁まで表示
- シート名の日付パターンは `YYYYMMDD` 形式
- 最新シートの特定: シート名を降順ソートして最新を取得
