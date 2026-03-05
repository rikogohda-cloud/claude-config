---
description: 日報自動生成＆投稿（分析版）
allowed-tools:
  - mcp__slack__conversations_add_message
  - mcp__slack__channels_list
  - Task
  - AskUserQuestion
---

# /daily - 日報生成

## 設定
- 投稿先チャンネル: #times_nippou（ID: C0AFMNT8PAS）
- 対象ユーザー: Riko Gohda（U07E74J2GEM / @riko.gohda）

---

## Phase 1: データ収集＆分析（Sonnet subagent委譲）

Task toolで以下のsubagentを起動する:
- **subagent_type**: general-purpose
- **model**: sonnet  # 品質重視: sonnet（~60kトークン）、コスト重視: haiku（~20kトークン）
- **prompt**: 以下のテキストを渡す（{TODAY}は実際の日付に置換）

```
~/.claude/daily-worker.md を Read ツールで読み、その指示に従ってデータ収集・分析・レポート生成を実行してください。
今日の日付は {TODAY} です。
最終出力として ===MAIN=== と ===THREAD=== のマーカーで区切った2ブロックのSlack mrkdwnテキストを返してください。

## アウトプットの定義（主要アウトプットセクションの構成基準）

以下を中心に構成すること:
1. **Claudeでのシステム改修** — Claude Code/Codexで実装・修正・改善したもの（スクリプト、スキル、PR等）
2. **Notion議事録の作成とネクストアクション設定** — 当日作成した議事録、設定したアクションアイテム
3. **Slackでの提案・アウトプット発言** — 自分が方針提案・判断表明・結論を出した発言（単なる確認・返答は除く）

上記に該当しない「調整・連絡・承認フロー」は :white_circle: 低インパクトにまとめるか詳細ログに移す。
```

subagentの結果を受け取り、Phase 2に進む。

---

## Phase 2: ユーザー確認

**対話モード（/daily実行時）:**
subagentから受け取ったレポートをそのまま表示し、AskUserQuestionで確認する:
- 内容の修正 / 追加 / 削除
- 投稿先チャンネルの確認
- **必ずユーザーの承認を得てから投稿すること**

**自動モード（run-daily-report.sh実行時）:**
プロンプトに「直接投稿」指示がある場合は確認をスキップして投稿する。

---

## Phase 3: Slack投稿

ToolSearchで `"select:mcp__slack__conversations_add_message"` をロードしてから投稿する。

1. メイン投稿: ===MAIN=== ブロックを `conversations_add_message` で投稿先チャンネルに投稿
2. スレッド返信: ===THREAD=== ブロックを、メイン投稿の thread_ts を指定して返信投稿
3. 1日に複数回実行した場合は新規投稿（前回の更新ではない）
