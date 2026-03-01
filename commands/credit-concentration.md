---
description: "与信集中ガイドライン超過承認申請ページを自動生成"
allowed-tools:
  - Read
  - Bash
  - Write
  - Glob
  - Grep
  - Task
  - WebSearch
  - mcp__notion__notion-fetch
  - mcp__notion__notion-create-pages
  - mcp__notion__notion-update-page
  - mcp__notion__notion-query-data-sources
---

# 与信集中ガイドライン超過承認：自動稟議ドラフト生成

## Input

`$ARGUMENTS` を解釈する:

```
<OrgID> <会社名> <現行枠M> <申請枠M> <Google Drive URL> [前回稟議Notion URL]
```

例:
```
/credit-concentration 22634439 株式会社サポート 1100 2000 https://drive.google.com/drive/folders/xxx https://www.notion.so/xxx
```

引数不足時（5個未満）はエラー終了し使い方を表示。

引数の解釈:
- `OrgID`: 数値（Credit SystemのOrg ID）
- `会社名`: 日本語文字列（スペースを含まない。㈱等略称OK）
- `現行枠M`: 数値（百万円単位、Mなし）
- `申請枠M`: 数値（百万円単位、Mなし）
- `Google Drive URL`: `https://drive.google.com/drive/folders/<folder_id>` 形式
- `前回稟議Notion URL`: 任意。Notion URL形式

---

## 設定

`~/.claude/private/credit-concentration-config.md` を Read して以下を取得:
- Notion DB data_source_id
- テンプレートページID
- Credit API エンドポイント
- Firestore プロジェクト・コレクション
- Google Drive ダウンロード先
- リスク分析閾値

---

## Process

### Phase 1: 並行データ収集

**3-4個の Task subagent を並行起動する。**

#### Subagent A: Notion テンプレート + 前回稟議

1. 設定ファイルからテンプレートIDを取得
2. `notion-fetch` でテンプレートページを取得 → セクション構造（0〜8）を把握
3. 前回稟議URL が引数にある場合:
   - `notion-fetch` で前回稟議ページを取得
   - 前回のCredit Systemデータ・財務データ・リスク分析を参照用データとして抽出
4. 結果: テンプレート構造 + 前回データ（あれば）を返す

#### Subagent B: Credit API

1. `gcloud auth print-identity-token` でトークン取得
2. Firestore REST API で最新の `model_artifact_path` を取得:
   ```bash
   TOKEN=$(gcloud auth print-identity-token)
   curl -s -H "Authorization: Bearer $TOKEN" \
     "https://firestore.googleapis.com/v1/projects/upsider-production/databases/(default)/documents/credit_model_artifacts?orderBy=created_at%20desc&pageSize=1"
   ```
3. Credit API `/api/v3/predict/batch` を呼び出し:
   - MT版（`delinquency_threshold_days: 30`）
   - NONMT版（injections で MT利用を0にする等、通常版）
   - 両方の結果を取得
4. 結果: スコア、目安枠、ランク（現在/RW/内部）、各種指標を返す

#### Subagent C: Google Drive → PDF ダウンロード

1. Drive URL から `folder_id` を抽出（URL末尾の `/folders/<id>` 部分）
2. `python3 ~/.claude/scripts/gdrive_list_folder.py <folder_id> --recursive` でファイル一覧取得
3. PDFファイルを特定（mimeType が `application/pdf`）
4. 各PDFを `python3 ~/.claude/scripts/gdrive_download.py <file_id> /tmp/credit-concentration/<OrgID>/<filename>` でダウンロード
5. Google Docs/Sheets は PDF エクスポートされる
6. 結果: ダウンロードしたファイル一覧（パス + 元ファイル名）を返す

#### Subagent D: WebSearch（任意）

1. `<会社名> 代表者` `<会社名> 事業内容` で検索
2. 代表者名、事業概要を補完
3. 最新ニュース・プレスリリースがあれば取得

---

### Phase 2: PDF 財務データ抽出

Phase 1C（Drive ダウンロード）完了後に実行。

**ファイル3個以下**: 直接 Read で処理
**ファイル4個以上**: Task subagent で並行処理

各PDFから Read ツール（`pages` パラメータで分割読み取り、最大20ページ/回）で以下を抽出:

- **文書情報**: 期数・決算期、文書種別（確定申告書/決算報告書/試算表）
- **PL**: 売上高、営業利益、経常利益、当期純利益
- **BS**: 現預金、売掛金、短期貸付金、長期貸付金、子会社株式・関係会社株式、総資産、純資産（自己資本）
- **その他BS**: 流動資産合計、流動負債合計、借入金（短期+長期）
- **算出**: 自己資本比率 = 純資産 / 総資産

**大きいPDF対策**: まず1-10ページ目を読み、財務諸表の位置を特定。必要に応じて追加ページを読む。

**読み取り失敗時**: スキップし、読めたファイルのみで続行。最終報告に失敗ファイルを含める。

抽出結果は **3期分の時系列データ** として整理（古い期→新しい期の順）。

---

### Phase 3: リスク分析 + ページ生成

Phase 1-2 全データが揃ってから実行。

#### 自動計算指標

| 指標 | 計算式 |
|------|--------|
| ガイドライン超過率 | 申請枠 ÷ 目安枠 × 100% |
| 純利益カバー倍率 | 直近期純利益 ÷ 申請枠 |
| 純資産カバー倍率 | 純資産 ÷ 申請枠 |
| 現預金カバー倍率 | 現預金 ÷ 申請枠 |
| 関連当事者エクスポージャー | 短期貸付金 + 長期貸付金 + 子会社株式 |
| 調整後純資産（貸付全損） | 純資産 − (短期貸付金+長期貸付金) |
| 調整後純資産（関連当事者全毀損） | 純資産 − エクスポージャー |
| 売上CAGR（3期） | (直近期売上/3期前売上)^(1/2) − 1 |
| 純利益CAGR（3期） | 同上ロジック（マイナス→マイナスの場合は「赤字継続」等テキスト） |

#### テンプレート準拠セクション生成

**セクション0: 基本情報**
- OrgID、付議日（今日）、現行枠、申請枠は自動記入
- 申請者: `※要記入` と明記
- 証跡: `※要記入` と明記
- 与信スキーム: 前回稟議があれば引継ぎ、なければ `※要記入`

**セクション1: 案件サマリー**
- 会社名・枠はパラメータから
- 代表者名: WebSearch結果 or 前回稟議から。不明なら `※要確認`
- 事業内容: WebSearch結果 or 前回稟議から
- 申請理由: 「ガイドライン目安枠○○Mに対し申請枠○○Mへの増枠」を基本文にし、前回稟議の理由があれば補完

**セクション2: Credit System データ**
- Credit API結果から全項目自動記入
- ランク外・特例: 該当しなければ「N/A」

**セクション3: リスク構造**
- チェックボックス: 財務データとCredit APIの内容から自動判定
  - 貸付金・子会社株式があれば → 「顧客単体の信用力」+ リスクドライバーに関連当事者言及
  - 純資産が薄ければ → 「特定事業の成否」
- リスクドライバー要約: 定量データに基づいて自動生成（`※要レビュー`付き）

**セクション4-A: 顧客単体の財務**
- `<details>` タグは使用せず展開状態で記載
- 直近決算ハイライト: 抽出データの直近期
- 過去3期推移テーブル: 抽出データの全期
- トレンド列: CAGR or 増減率を記載
- 営業CF: PDF から抽出できなければ `データなし（CF計算書の提出なし）`
- Cash変動要因分析: 自動生成（`※要レビュー`付き）

**セクション5: 意思決定ポイント**
3つのポイントを自動生成:
1. **PL吸収力**: 純利益カバー倍率を軸にOK/NG/条件付き判定
2. **BS + 関連当事者エクスポージャー**: 純資産・調整後純資産・現預金カバーを軸に判定
3. **ガイドライン超過の妥当性**: 超過率 + 3期トレンドを軸に判定
`※要レビュー` 付き

**セクション6: 撤退基準**
- 即時撤退トリガー: 自動生成（赤字転落、自己資本比率20%割れ、等）
- モニタリング指標テーブル: 主要指標の現在値と基準値を設定
- モニタリング頻度: 「四半期ごとに決算書を確認」等
`※要レビュー` 付き

**セクション7: 対外説明**
- 3-5文で自動生成。ガイドライン超過だが承認する合理性を第三者向けに説明
`※要レビュー` 付き

**セクション8: AIレビュー結果**
- 空欄（calloutのみ配置）。AI別途記入のため。

---

### Phase 4: Notion ページ一発作成

**重要**: `notion-create-pages` で完成版を1回で作成する。骨格→更新の2段階方式は禁止。

```
parent: {data_source_id: "869c61ce-3a65-43d4-ad9c-b8f7c943a75e"}
properties:
  Name: "<会社名>"
content: テンプレート準拠の完全なNotionマークダウン
```

**Notion記法の注意点:**
- テーブル: `<table header-row="true" header-column="true">` + 各行は個別 `<tr><td>` で記載（インライン化するとセルマージが発生）
- callout: `::: callout {icon="📋" color="blue_bg"}` 形式
- 見出し: `## セクション名`
- 区切り線: `---`
- チェックボックス: `- [x]` / `- [ ]`
- `<details><summary>` は使用しない（展開状態で記載）
- 数値は百万円単位で統一（`○○M` or `○○百万円`）

---

### Phase 5: 完了報告

出力:
1. **Notion ページ URL**
2. **Credit System サマリー**: ランク、目安枠、超過率
3. **財務ハイライト**: 直近期の売上/営業利益/純資産/現預金/自己資本比率
4. **主要リスク項目**: 関連当事者エクスポージャー、調整後純資産等
5. **※要確認・要記入リスト**: 自動では埋められなかった項目一覧
6. **PDF読み取り結果**: ファイル一覧と成功/失敗

---

## ルール

- AskUserQuestion は使用しない（非対話で完結）
- エラー時も可能な範囲で続行。読めないPDFはスキップし最終報告に含める
- Credit API 失敗時: セクション2を「取得失敗 — 手動確認が必要」で記載し続行
- Drive トークン失効: refresh_token で自動更新。それも失敗→再認証案内を出して終了
- Notion API 失敗: リトライ1回。それでも失敗→ローカルにマークダウン保存
- 前回稟議未指定: 前回参照なしで続行
- 金額は百万円単位で統一。端数は整数に丸める
- CAGR計算でマイナス値がある場合はテキスト説明（「赤字転落」「赤字継続」等）
- `※要レビュー` `※要記入` `※要確認` を明確に区別:
  - `※要記入`: データが存在しないため人間の入力が必須
  - `※要確認`: 自動生成したが正確性の検証が必要
  - `※要レビュー`: 自動生成した分析・判断で、人間のレビューが必要
