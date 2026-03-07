# /commands - コマンド一覧

登録済みカスタムコマンドの一覧をカテゴリ別に表示する。

## 出力フォーマット

以下をそのまま表示すること（コード実行不要）:

```
日次ワークフロー
  /morning              朝の一括ブリーフィング（カレンダー+メール+Slack+Todo）
  /check-mail           Gmail未読トリアージ（スキップ/情報のみ/要対応を分類）
  /check-slack          Slack未読トリアージ（UPSIDER・Capital両WS対応）
  /prep <会議名|next>    ミーティング準備（情報収集+アジェンダ案生成）

業務データ
  /report <エイリアス|URL>          スプレッドシートKPIレポート取得・要約
  /report                         登録済みレポート一覧を表示
  /deal-review <Driveパス> <親ページID>  ベンチャーデット初期取上げ検討ドラフト自動生成
  /deal-review poll               Notion DB未処理案件を自動チェック・生成
  /weekly-members                 メンバー週次活動レポート（OKR貢献度分析）
  /weekly-slack-summary [期間]     週次Slackサマリー→Notion投稿+DB登録
  /weekly-finance                 週次ファイナンスメールサマリー

与信判定
  /bpsp-judge <org_id>            リアルタイム与信判定（BLUE/YELLOW/RED シグナル）

債権回収
  /case-alert                     シグナルアラート（スプシ→DB更新→Slack通知）
  /case-guide [企業名]             フェーズ判定+チェックリスト自動生成
  /case-summary [企業名|mtg]       案件サマリー / MTG準備資料
  /weekly-collections             債権回収 週次サマリーをNotionに作成

本部長会議
  /draft-weekly-ops               週次ページ自動下書き生成（Slack→天気図→Notion）
  /monthly-prep [YYYY-MM]         月次本部長会議の叩き台を週次データから自動生成
  /register-meeting-actions       会議後にDBへアクション・インシデント等を登録

1on1・フィードバック
  /1on1 <メンバー名>               1on1準備メモ生成
  /1on1 feedback <メンバー名>       フィードバック文書ドラフト

コード
  /review <ファイル|PR番号|diff>    コードレビュー
  /test <対象>                     テスト実行・分析
  /refactor <対象>                 リファクタリング提案
  /explain <対象>                  コード解説

スケジュール実行用（非対話）
  /morning-auto                   非対話版朝ブリーフィング（Slack DM通知）
  /todo-reminder                  Todo期限リマインダー（Slack DM通知）
  /weekly-reminder                月曜朝ネクストアクションSlack投稿
  /daily-report [YYYY-MM-DD]     作業日報自動生成→Notion投稿（毎日AM3:00）

その他
  /commands                       このコマンド一覧を表示
```

補足: 各コマンドの詳細は `/help` または直接コマンドを引数なしで実行して確認できる。
