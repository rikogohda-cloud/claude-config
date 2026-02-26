---
description: 週次ファイナンスメールサマリー（非対話・Slack DM通知）
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
  - mcp__slack__slack_post_message
---

# /weekly-finance - Weekly Finance Email Summary (Non-interactive)

週次で財務関連メールを収集・要約し、Slack DMで通知する非対話コマンド。

## Identity
- naoki.ishigami@up-sider.com / 石神直樹 / UPSIDER執行役員・公認会計士
- naoki.ishigami@upsidercap.com / 石神直樹 / UPSIDER Capital

## Slack DM Channel (self)
- UPSIDER本体: `UD44KMYCB`
→ サマリーは **UPSIDER本体WS** の自分DM (`UD44KMYCB`) に投稿する

## Phase 1: Gmail検索（4クエリ並行実行）

過去7日間のメールを対象とする。

**1a. 財務担当（kai.tamura）からのメール**
```bash
GOG_ACCOUNT=naoki.ishigami@up-sider.com gog.exe gmail messages search "from:kai.tamura newer_than:7d" --max 20 --include-body --json
```

**1b. UPSIDER本体 - 財務キーワード**
```bash
GOG_ACCOUNT=naoki.ishigami@up-sider.com gog.exe gmail messages search "(借入 OR 融資 OR GMV OR 金利 OR 資金繰り OR キャッシュフロー OR 支払いドットコム OR ITSS) newer_than:7d" --max 20 --include-body --json
```

**1c. Capital - 財務キーワード**
```bash
GOG_ACCOUNT=naoki.ishigami@upsidercap.com gog.exe gmail messages search "(ファンド OR UBDF OR 借入 OR 融資 OR 金利 OR LP OR 出資 OR コミットメント) newer_than:7d" --max 20 --include-body --json
```

**1d. 銀行ドメインからのメール**
```bash
GOG_ACCOUNT=naoki.ishigami@up-sider.com gog.exe gmail messages search "(from:mizuho-bk.co.jp OR from:aozorabank.co.jp OR from:bk.mufg.jp OR from:smbc.co.jp OR from:shokochukin.co.jp OR from:resonabank.co.jp) newer_than:7d" --max 20 --include-body --json
```

## Phase 2: 分類・要約

### 重複除去
- 4クエリの結果をmessageIdで重複除去

### カテゴリ分類
| カテゴリ | 説明 |
|---|---|
| 借入実行予定 | 借入実行日・金額・銀行に関する通知 |
| GMV実績 | GMV実績・速報値・日次/週次レポート |
| 支払いドットコム | 支払いドットコム関連（実績・オペレーション） |
| 銀行連絡 | 銀行からの直接連絡（契約・条件変更等） |
| ITSS | ITSS関連（信託・SPC・ファンド） |
| ファンド/LP | UBDF・LP関連（出資・コミットメント・報告） |
| その他財務 | 上記に該当しない財務関連 |

### 要点抽出
各メールについて:
- 送信者・日付・件名
- 要点（1-2行）
- 対応要否（要対応 / 情報のみ）
- 期限があれば明示

## Phase 3: Slack DM投稿

UPSIDER本体WSの自分DM (`UD44KMYCB`) に **1つのメッセージ** で投稿。
Slackのmrkdwn記法を使う。

```
:bank: *週次ファイナンスサマリー* [期間: MM/DD〜MM/DD]

*:rotating_light: 要対応* (N件)
• *[件名]* ([送信者], MM/DD) → [要対応内容]

*借入実行予定*
• [要点]

*GMV実績*
• [要点]

*支払いドットコム*
• [要点]

*銀行連絡*
• [要点]

*ITSS / ファンド*
• [要点]

*その他*
• [要点]

_計 N件のメールを処理_
```

**重要**:
- 該当メールが0件のカテゴリはセクションごと省略
- 要対応が0件の場合は「要対応なし :white_check_mark:」
- メッセージにAI由来プレフィックスを付けない

## Phase 4: todo.md更新

期限付き対応事項があれば `~/.claude/private/todo.md` の Active セクションに追記:
```
- [ ] `YYYY-MM-DD` [タスク内容] (from: [送信者] / 期限: [期限])
```

該当がなければ何もしない。

## 注意事項
- このコマンドは非対話。AskUserQuestion は使わない
- メールのアーカイブ、返信の送信は一切行わない
- 情報の収集と通知のみを行う
- エラーが発生した場合もDMで通知する（「Gmail取得エラー」等）
