# 日報ワーカー v2（トークン最適化版）

**トークン目標: 25,000トークン/回**（月1000万トークン × 6% ÷ 20回）

**変更点:**
- 2段階処理: データ収集（Haiku）→ レポート生成（Sonnet）
- 中間データをJSONファイルに保存し再利用
- 並列実行の徹底、重複排除
- データ量の適度な制限（質とコストのバランス）

---

## 設定（ユーザーごとにカスタマイズ）

| 項目 | 値 |
|------|-----|
| ユーザー名 | Riko Gohda |
| Slack User ID | U07E74J2GEM |
| Slack Handle | @riko.gohda |
| Slack Crawler DB |  |
| 除外チャンネル（times系） | times_riko |
| 議事録 Notion DB ID | 30d93c7ce32d8014a26ff8583dfadc9e |
| 振り返りトーン | strict |
| キャッシュディレクトリ | ~/.claude/cache/daily |

### トークン予算配分

| フェーズ | モデル | 目標トークン |
|---------|--------|------------|
| Phase 1: データ収集 | Haiku | 12,000 |
| Phase 2: レポート生成 | Sonnet | 13,000 |
| **合計** | - | **25,000** |
| **安全マージン** | - | 5,000 |
| **上限** | - | 30,000 |

---

## Phase 1: データ収集（Haiku subagent）

**目的:** 生データを収集してJSONファイルに保存（分析はしない）

**トークン目標: 12,000トークン**

### Step 1-0: 準備
```bash
mkdir -p ~/.claude/cache/daily
TARGET_DATE=$(date +%Y-%m-%d)
CACHE_FILE="$HOME/.claude/cache/daily/$TARGET_DATE.json"
```

### Step 1-1: 並列データ収集

以下を**完全並列**で実行し、結果をJSONに保存:

```json
{
  "date": "YYYY-MM-DD",
  "slack_messages": [...],  // 1-A: ユーザー送信メッセージ（最大20件）
  "slack_mentions": [...],  // 1-D: メンション
  "calendar_events": [...], // 1-G: カレンダー予定
  "notion_pages": [...],    // 1-H: Notion作成ページ
  "notion_minutes": [...],  // 1-L: 議事録（全文取得）
  "codex_sessions": [...],  // 1-I: Codexセッション
  "claude_sessions": [...], // 1-K: Claude Codeセッション
  "baseline_stats": {...}   // 1-E,F: SQLite統計
}
```

**データ収集の制限（トークン削減）:**
- Slackメッセージ: **最大20件**（v1の25件から削減）
- スレッド文脈取得: **最大3件**（v1の5件から削減、substantiveなもの優先）
- メッセージ切り取り: **最初の300文字**（v1の500文字から削減）
- 議事録: **全文取得**（質を維持、決定事項・AI抽出に必須）
- Notionページ: 当日作成分のみ

**除外対象:**
- Botメッセージ（WFログ等）
- times系チャンネルのbot通知
- ワークフローのボタン操作のみ

### Step 1-2: キャッシュ保存
```bash
echo "$JSON_DATA" > "$CACHE_FILE"
```

---

## Phase 2: レポート生成（Sonnet subagent）

**目的:** キャッシュデータから日報を生成

**トークン目標: 13,000トークン**

### Step 2-1: キャッシュ読込
```bash
CACHE_FILE="$HOME/.claude/cache/daily/$(date +%Y-%m-%d).json"
if [ -f "$CACHE_FILE" ]; then
  DATA=$(cat "$CACHE_FILE")
else
  echo "ERROR: Cache not found"
  exit 1
fi
```

### Step 2-2: 分析・分類

キャッシュから以下を抽出:
1. **議事録の決定事項・AI** → 主要アウトプットに含める（必須）
2. **Slackスレッドの要約** → カテゴリ別に分類
3. **時間推定** → 議事録作成時間（created_time〜last_edited_time + 15分）を含める
4. **明日のTODO** → 議事録のAI（ユーザー担当分）を優先度順に並べる

### Step 2-3: レポート生成

**トークン削減ルール:**
1. 詳細ログは各カテゴリ**最大3件**（重要度順）
2. 1項目あたり**最大100文字**（v1の80文字から微増、質を改善）
3. 絵文字は `■●○・!+✓` のみ使用
4. 補足説明は最小限（「背景:」「補足:」等のラベル不要）

**議事録の扱い（質を維持）:**
- MTGの決定事項: 完全反映
- アクションアイテム: 担当者・期限を含めて記載
- 主要な議論ポイント: 簡潔に要約

**出力フォーマット:**
```
===MAIN===
■ 日報 YYYY-MM-DD（曜日）

稼働: HH:MM - HH:MM（推定 X.Xh / MTG X.Xh）
意思決定 X件 / レビュー X件 / 問題解決 X件
MTG議事録: X/X件
Notion: X件 / Claude Code: Xセッション

*■ 主要アウトプット*

● 重大（:red_circle:）
- [MTG] 議事録タイトル: 決定事項要約、AI要約

○ 業務判断（:large_orange_diamond:）
- [#channel] 要約

○ 調整（:white_circle:）
- 件数のみ

*■ 時間配分*
カテゴリA ████░░░░░░ X.Xh (XX%)

*■ 振り返り*
! ヒヤリハット - 具体的案件名、actionable改善案
? 改善 - 具体的案件名、actionable改善案
+ Good - 具体的案件名

*■ 明日やること*
1. ● タスク — 理由
...

===THREAD===
*■ 詳細ログ*

_カテゴリ1_
- [#ch] 要約（最大3件）

_MTG議事録_
- [HH:MM] MTG名: 決定/AI要約

_Claude Code_
- HH:MM: 作業概要
```

---

## 使い方

### 初回実行（データ収集）
```bash
# Haiku subagentでデータ収集
claude code --prompt "~/.claude/daily-worker-v2.md の Phase 1 を実行し、$(date +%Y-%m-%d).json を保存"
```

### レポート生成
```bash
# Sonnet subagentでレポート生成
claude code --prompt "~/.claude/daily-worker-v2.md の Phase 2 を実行し、日報を生成"
```

### ワンステップ実行
```bash
# 両方を順次実行
claude code --prompt "~/.claude/daily-worker-v2.md の Phase 1（Haiku）→ Phase 2（Sonnet）を実行"
```

---

## トークン削減効果（実測値との比較）

| 項目 | v1実測 | v2目標 | 削減率 |
|------|--------|--------|--------|
| データ収集 | ~60k | 12k | -80% |
| レポート生成 | ~27k | 13k | -52% |
| **合計** | **~87k** | **25k** | **-71%** |

**削減施策:**
- Haikuでデータ収集（コスト-80%）
- Slackメッセージ件数制限（25→20件）
- スレッド文脈制限（5→3件）
- メッセージ切り取り（500→300文字）
- 詳細ログ件数制限（各カテゴリ3件）
- 文字数適正化（80→100文字、質とコストのバランス）

**質を維持する部分:**
- 議事録は全文取得（決定事項・AI完全反映）
- 主要アウトプットは全件記載
- 時間配分グラフ維持
- 振り返りは2-3項目

---

## 月間使用量（20回実行の場合）

| 項目 | 値 |
|------|-----|
| 1回あたり | 25,000トークン |
| 月間合計（20回） | 500,000トークン |
| 月間上限（1000万） | 10,000,000トークン |
| **使用率** | **5.0%** |
| **目標（6%）に対する余裕** | **1.0%（100,000トークン）** |
