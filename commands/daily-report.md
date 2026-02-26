---
description: 作業日報の自動生成（非対話・Notion投稿）
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - Edit
  - Task
  - mcp__slack__slack_search_messages
  - mcp__slack__slack_get_channel_history
  - mcp__slack__slack_get_thread_replies
  - mcp__slack__slack_list_channels
  - mcp__slack__slack_get_users
  - mcp__slack__slack_get_user_profile
  - mcp__slack-capital__slack_get_channel_history
  - mcp__slack-capital__slack_get_thread_replies
  - mcp__slack-capital__slack_list_channels
  - mcp__slack-capital__slack_get_users
  - mcp__slack-capital__slack_get_user_profile
  - mcp__notion__notion-fetch
  - mcp__notion__notion-create-pages
  - mcp__notion__notion-update-page
---

# /daily-report - 作業日報の自動生成

前日（N日）の作業を振り返り、Notionに日報ページを自動作成する。
AM3:00にN日分の日報を生成する想定（スケジュール実行）。

## Identity
- riko.gohda@up-sider.com / 合田莉子 / UPSIDER

## Notion
- 親ページ: `30b93c7ce32d80cd8e0cee420637ef7f`（Nao作業日報）

## 対象日の決定

$ARGUMENTS が指定されている場合はその日付（YYYY-MM-DD）を対象日とする。
指定がない場合は **常に前日** を対象日とする。

例: 2026-02-19 に実行 → 対象日は 2026-02-18

当日分を生成したい場合は `today` または当日の日付を明示的に指定する。

## Phase 1: データ収集（並行実行）

**1a. カレンダー予定（両WS）**
```bash
ZONEINFO="C:/Users/rikogohda/.local/lib/zoneinfo.zip" gog calendar list --from=<対象日> --to=<対象日翌日> --account=riko.gohda@up-sider.com
```
```bash
```

**1b. メール（両WS）**
```bash
gog gmail search "after:<対象日> before:<翌日>" --account=riko.gohda@up-sider.com --max=30
```
```bash
```

**1c. Slack（UPSIDER本体WS）**
```
mcp__slack__slack_search_messages({ query: "from:riko.gohda after:<対象日>", sort: "timestamp", count: 50 })
mcp__slack__slack_search_messages({ query: "to:riko.gohda after:<対象日>", sort: "timestamp", count: 50 })
```

**1d. Slack（Capital WS - biz_ubdf）**
```
mcp__slack-capital__slack_get_channel_history({ channel_id: "C069192C2HY", oldest: "<対象日00:00のUNIXタイムスタンプ>", limit: 100 })
```
Capital WSにはsearch_messagesがないため、主要チャネルの履歴を取得する。

**1e. Todo変更**
Read `~/.claude/private/todo.md`
- 対象日付近（前後1日）に追加されたActiveタスク
- 対象日に完了（Done移動）されたタスク

**1f. Claude Code利用ログ（あれば）**
Read `~/.claude/private/logs/morning-briefing-<対象日>.md` — 朝ブリーフィングのログがあれば参照
Glob `~/.claude/private/logs/*<対象日>*` — その他のログ

## Phase 2: レポート構成

以下のセクションでNotionページを作成する:

### ページタイトル
`<対象日>（<曜日>）作業日報`（例: `2026-02-18（火）作業日報`）

### 時間カテゴリ定義

MTG・予定データとSlack/メール活動から、以下のカテゴリ別に稼働時間（h）を推定する:

| カテゴリ | 判定基準 |
|---|---|
| MTG | カレンダー上の社内/社外会議 |
| イベント | 社外イベント、懇親会、セミナー等 |
| Deep Work | 成果物を出した集中作業時間（空き時間のうち成果が確認できるもの） |
| Slack | Slack上のコミュニケーション中心の時間帯 |
| 移動 | 移動時間 |
| その他 | ジム、休憩、個人時間等 |

推定ルール:
- カレンダーの予定 → 直接カテゴリ割当
- 予定の空き時間 → Slack活動密度と成果物から Deep Work / Slack に配分
- 稼働時間: 09:00 ~ 最後のSlack/メール活動時刻を基本

### セクション構成

```
## MTG・予定

各予定にカテゴリ区分列と行カラーを付ける:

<table fit-page-width="true" header-row="true">
<tr><td>時間</td><td>内容</td><td>区分</td></tr>
<tr color="blue_bg"><td>HH:MM-HH:MM</td><td>会議名</td><td>MTG</td></tr>
<tr color="red_bg"><td>HH:MM-HH:MM</td><td>イベント名</td><td>イベント</td></tr>
<tr color="green_bg"><td>HH:MM-HH:MM</td><td>ジム等</td><td>その他</td></tr>
<tr><td>HH:MM-HH:MM</td><td>移動先</td><td>移動</td></tr>
</table>

行カラーのルール:
- MTG → blue_bg
- イベント → red_bg
- その他（ジム等） → green_bg
- 移動 → 色なし

※ 終日予定は別途記載。予定がない場合は「予定なし」

## 時間配分

稼働サマリー callout + pie チャート + カテゴリテーブルを横並びで表示する。

::: callout {icon="⏱" color="blue_bg"}
**稼働 X.Xh** ｜ MTG占有率 **XX%** ｜ Deep Work率 **XX%** ｜ MTG X件 + イベント X件
:::

<columns>
<column>

```mermaid
pie title 時間配分
    "MTG (X.Xh)" : X.X
    "Deep Work (X.Xh)" : X.X
    "イベント (X.Xh)" : X.X
    "Slack (X.Xh)" : X.X
    "移動 (X.Xh)" : X.X
```

</column>
<column>

カテゴリテーブルにも行カラーを付ける:

<table fit-page-width="true" header-row="true">
<tr><td>カテゴリ</td><td>時間</td><td>割合</td></tr>
<tr color="gray_bg"><td>Deep Work</td><td>X.Xh</td><td>XX%</td></tr>
<tr color="blue_bg"><td>MTG</td><td>X.Xh</td><td>XX%</td></tr>
<tr color="red_bg"><td>イベント</td><td>X.Xh</td><td>XX%</td></tr>
<tr color="green_bg"><td>その他</td><td>X.Xh</td><td>XX%</td></tr>
<tr><td>**合計**</td><td>**X.Xh**</td><td></td></tr>
</table>

</column>
</columns>
```

## 主な成果・アウトプット

対象日に出したアウトプットを箇条書き。例:
- Deal Review完了（X社）
- Notionページ作成
- メール返信（重要なもの）
- Slack上での意思決定・指示

メール・Slack・Todo完了から抽出する。
**自分が能動的に行ったアクション**を中心に記載（受動的な通知は除外）。

## Slack主要アクティビティ

チャネル/相手ごとに、やり取りの概要を箇条書き。
- 自分の発信・返信・依頼
- 自分宛の依頼・質問（未対応のものは明示）

## メール（主要）

重要度の高いメールのみ記載。以下は除外:
- 通知系（freee、GitHub、Slack通知）
- プロモーション
- noreply

| From | Subject | 概要 |
|---|---|---|

## タスク変動

### 新規追加
- 対象日に発生した新規タスク

### 完了
- 対象日に完了したタスク

### 明日以降の期限タスク
- 近い期限のもの（3日以内）

## 振り返り

### 良かった点
対象日の活動から、以下の観点でポジティブな点を2-3個抽出:
- 効率化・自動化の成果
- チームへの貢献・権限委譲
- 重要な意思決定の推進
- 新しい取り組みの着手

### 改善点
対象日の活動から、以下の観点で改善できる点を2-3個抽出:
- 未完了・先送りになったもの
- プロセスの非効率
- コミュニケーションの課題
- リスク管理の甘さ

### 学んだこと・気づき
ファクトから得られるインサイトを2-3個:
- 業務上の発見
- チーム・組織に関する気づき
- 市場・顧客に関する学び
- 自分の働き方に関する内省
```

## Phase 3: Notion投稿

- 親ページ `30b93c7ce32d80cd8e0cee420637ef7f` の子ページとして作成
- `mcp__notion__notion-create-pages` を使用

## Phase 4: ログ保存

レポート内容をローカルにも保存:
```
~/.claude/private/logs/daily-report-<対象日>.md
```

## 注意事項
- 非対話コマンド。AskUserQuestion は使わない
- 振り返りセクションはファクトに基づいたドラフト。過度に褒めたり批判しない。客観的に書く
- データ取得に失敗したセクションは「取得エラー」と明記し、取得できた範囲で日報を作成する
- DM返信検証ルール: Slack検索で相手のメッセージだけ見えて返信が見つからない場合、「未返信」と断定しない。必ず履歴で確認する
- gogcli: `gog` コマンドがPATHに入っていること
