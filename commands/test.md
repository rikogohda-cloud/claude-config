$ARGUMENTS で指定された対象のテストを実行・分析してください。

手順:
1. 言語・テストフレームワークを自動検出
2. テスト実行:
   - Go: go test -v -race -count=1 ./...
   - Rust: cargo test
   - TypeScript: npx vitest run or npx jest
   - Python: pytest -v
3. 結果報告: pass/fail/skip 件数、失敗の原因と修正案
4. テストが存在しない場合はテストケースを提案
5. $ARGUMENTS が空ならプロジェクト全体を実行
