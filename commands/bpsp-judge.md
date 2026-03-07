与信判定を実行します。

以下の手順で実行してください（確認不要）:

```bash
# node_modules がなければ自動インストール
[ ! -d "/Users/rikogohda/credit-screening-bpsp/frontend-service/node_modules" ] && \
  cd /Users/rikogohda/credit-screening-bpsp/frontend-service && \
  npm install firebase-admin @google-cloud/bigquery

# 判定実行
cd /Users/rikogohda/credit-screening-bpsp/frontend-service && \
  bash get_org_realtime_with_signal.sh $ARGUMENTS
```

出力後、**必ず以下のテーブル形式**でorgごとにサマリーを出力してください（厳守）。
配列データ・調整過程・CRM情報・Credit API詳細・前回審査・与信枠履歴等の詳細セクションは不要です。

```
## N. 社名 (orgID)

| 項目 | 値 |
|------|-----|
| 信号 | 🔴/🟡/🔵 + アクション |
| 理由 | 判定理由 |
| 現在の与信枠 | X円 |
| 調整済み目安枠 | X円 |
| 比率 | X.XX |
| 残高 | X円 |
| RWランク | A/B/C |
| 内部ランク(MT) | ランク (スコア) |
| ランウェイ(調整後) | X日 |
| isBurn | true/false/N/A + 非Burn調整有無 |
| MT連携 | 正常/切れあり (口座数) |
| 延滞 | なし or 件数+詳細 |
```

- 1件につき1テーブル、全13項目を必ず出力する
- 複数org_idの場合は `## 1.`, `## 2.`, ... と番号を振る

## 各項目の判定ロジック

### シグナル（信号）

**絶対RED条件（OR: どれか1つでも該当すれば 🔴 RED）:**
- RED①: 内部ランクC以下
- RED②: 枠>目安 AND RW=C AND（内部BB以下 OR 延滞有）
- RED③: （枠>目安 OR RW=C）AND 延滞有 AND 連携切れ有

**絶対BLUE条件（REDに非該当かつ以下に該当すれば 🔵 BLUE）:**
- BLUE①: 枠<目安 AND RW=A AND 延滞有 AND 連携切れ無
- BLUE②: 枠<目安 AND RW=A AND 延滞無 AND 内部BBB以上

**それ以外 → 🟡 YELLOW（有人審査）**

### 各項目の読み方

| 項目 | データソース | 説明 |
|------|------------|------|
| 信号 | 上記フロー | 🔴 自動否決 / 🟡 有人審査 / 🔵 自動通過 |
| 理由 | 上記フロー | RED該当条件をすべて列挙。YELLOW/BLUEは比率を表示 |
| 現在の与信枠 | `creditLineCurrent` | 現在設定されている与信枠（円） |
| 調整済み目安枠 | `creditLineOptimizedAdjusted` | calculator.ts が算出した推奨与信枠（円） |
| 比率 | `調整済み目安枠 ÷ 現在の与信枠` | 小数点2桁。与信枠0の場合は0 |
| 残高 | `mtLastBalance` | MT（マネーフォワード）最終取得残高（円） |
| RWランク | `rank` | Runway（資金持続性）ランク。入出金パターンの安定性を表す（A/B/C） |
| 内部ランク(MT) | `internalRank` / `internalScore` | MT連携スコアによる内部ランク |
| ランウェイ(調整後) | `runwayAdjusted` | 現残高で何日資金が持つか。非Burn企業は補正済み |
| isBurn | `isBurn` / `nonBurnAdjusted` | `true`: 資金燃焼中 / `N/A`: 非Burn企業。非Burn調整ありの場合は明記 |
| MT連携 | `mtBrokenDays` | `5以下` → 正常連携中（許容範囲）/ `6以上` → 切れあり（N日） |
| 延滞 | `entaiSettlements` | 件数0 → なし / 1件以上 → 件数＋直近3件の日付・暦日数・金額 |
