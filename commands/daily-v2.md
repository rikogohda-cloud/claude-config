---
description: 日報自動生成＆投稿（トークン最適化版）
allowed-tools:
  - mcp__slack__conversations_add_message
  - Task
  - AskUserQuestion
  - Bash
  - Write
  - Read
---

# /daily-v2 - 日報生成（トークン最適化版）

## 設定
- 投稿先チャンネル: C0AFMNT8PAS
- 対象ユーザー: Riko Gohda（U07E74J2GEM / @riko.gohda）

---

## 変更点（v1との比較）

| 項目 | v1 | v2 |
|------|----|----|
| トークン消費 | ~87k | ~30k (-66%) |
| 処理方式 | 1段階（Sonnet） | 2段階（Haiku→Sonnet） |
| データ保存 | なし | JSONキャッシュ |
| 議事録反映 | ✓ | ✓ |
| 詳細ログ | 全件 | 各カテゴリ最大3件 |

---

## Phase 1: データ収集（Haiku subagent）

Task toolで以下のsubagentを起動:
- **subagent_type**: general-purpose
- **model**: haiku  # コスト削減
- **prompt**:

```
~/.claude/daily-worker-v2.md の Phase 1 を実行してください。
今日の日付は {TODAY} です。

以下を実行:
1. 並列データ収集（Slack、Notion議事録、Calendar、Codex、Claude Code）
2. JSONキャッシュに保存: ~/.claude/cache/daily/{TODAY}.json

議事録は必ず全文取得すること（決定事項・AI抽出に必須）。
```

---

## Phase 2: レポート生成（Sonnet subagent）

Task toolで以下のsubagentを起動:
- **subagent_type**: general-purpose
- **model**: sonnet  # 品質重視
- **prompt**:

```
~/.claude/daily-worker-v2.md の Phase 2 を実行してください。
今日の日付は {TODAY} です。

以下を実行:
1. キャッシュ読込: ~/.claude/cache/daily/{TODAY}.json
2. 分析・分類（議事録の決定事項・AIを主要アウトプットに含める）
3. レポート生成（詳細ログは各カテゴリ最大3件）

最終出力として ===MAIN=== と ===THREAD=== のマーカーで区切った2ブロックのSlack mrkdwnテキストを返してください。
```

---

## Phase 3: ユーザー確認

**対話モード（/daily-v2実行時）:**
subagentから受け取ったレポートをそのまま表示し、AskUserQuestionで確認:
- 内容の修正 / 追加 / 削除
- **必ずユーザーの承認を得てから投稿すること**

---

## Phase 4: Slack投稿

1. メイン投稿: ===MAIN=== ブロックを `conversations_add_message` で投稿先チャンネルに投稿
2. スレッド返信: ===THREAD=== ブロックを、メイン投稿の thread_ts を指定して返信投稿
3. 1日に複数回実行した場合は新規投稿（前回の更新ではない）

---

## トラブルシューティング

### キャッシュが見つからない場合
```bash
# Phase 1を手動実行
ls -la ~/.claude/cache/daily/
```

### Phase 1のみ実行したい場合
```bash
# データ収集のみ実行（レポート生成はスキップ）
/daily-v2 --collect-only
```

### キャッシュを削除して再実行
```bash
rm ~/.claude/cache/daily/$(date +%Y-%m-%d).json
/daily-v2
```
