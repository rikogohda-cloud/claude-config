---
description: kintone App 160（MT与信注入関係）へレコードを手動登録
argument-hint: (引数不要・対話式)
allowed-tools:
  - mcp__kintone__kintone-get-records
  - mcp__kintone__kintone-add-records
  - mcp__kintone__kintone-get-form-fields
  - mcp__kintone__kintone-delete-records
  - AskUserQuestion
---

# /kintone-register - MT与信注入関係レコード手動登録

Args: $ARGUMENTS

## 概要
kintone App 160（MT与信注入関係）にレコードを対話式で手動登録する。
全フィールドを1つずつユーザーに確認しながら入力する。

## 登録先
- アプリ: **160**（MT与信注入関係）
- URL: https://up-sider.cybozu.com/k/160/

## 入力フィールド一覧

| # | フィールド | 型 | 選択肢/説明 |
|---|-----------|-----|-------------|
| 1 | `source_organization_id` (注入元 org_id) | NUMBER | 数値入力。会社名は App 8 lookup で自動取得 |
| 2 | `target_organization_id` (注入先 org_id) | NUMBER | 数値入力。会社名は App 8 lookup で自動取得 |
| 3 | `group_multiplier` (注入掛目) | DROP_DOWN（必須） | 下記の選択肢から選択 |
| 4 | `notes` (備考) | CHECK_BOX | 下記の選択肢から複数選択可 |
| 5 | `文字列__1行__1` (関係エビデンス保存先URL) | TEXT | 任意。空欄可 |
| 6 | `文字列__1行__2` (連帯保証契約・誓約書URL) | TEXT | 任意。空欄可 |

### group_multiplier の選択肢
- `President用-100%`
- `Adboost用-100%`
- `子会社 - 連帯保証契約 - 100%`
- `子会社 - 誓約書 - 100%`
- `子会社 - 覚書 - 100%`
- `親会社 - 連帯保証契約 - 50%`
- `親会社 - 誓約書 - 50%`
- `親会社 - 覚書 - 50%`
- `兄弟会社 - 連帯保証契約 - 50%`
- `兄弟会社 - 誓約書 - 50%`
- `兄弟会社 - 覚書- 50%`
- `祖父会社 - 連帯保証契約 - 25%`
- `祖父会社 - 誓約書 - 25%`
- `祖父会社 - 覚書 - 25%`
- `関連会社 - 連帯保証契約 - 25%`
- `関連会社 - 誓約書 - 25%`
- `関連会社 - 覚書 - 25%`
- `孫会社 - 連帯保証契約 - 100%`
- `孫会社 - 誓約書 - 100%`
- `孫会社 - 覚書 - 100%`

### notes の選択肢
- `President用`
- `Adboost用`
- `関係エビデンスが未回収`
- `連帯保証契約・誓約書が未回収`

## 実行フロー

### Step 1: source_organization_id（注入元）

AskUserQuestion: 「注入元の organization_id を入力してください」

$ARGUMENTS に数値が含まれていればそれを提示して確認。

### Step 2: target_organization_id（注入先）

AskUserQuestion: 「注入先の organization_id を入力してください」

### Step 3: group_multiplier（注入掛目）

選択肢を番号付きで提示:
```
注入掛目を選択してください:
1. President用-100%
2. Adboost用-100%
3. 子会社 - 連帯保証契約 - 100%
4. 子会社 - 誓約書 - 100%
...
```

AskUserQuestion で番号 or テキストで選択。

### Step 4: notes（備考）

選択肢を提示（複数選択可）:
```
備考を選択してください（複数可、カンマ区切り。空欄可）:
1. President用
2. Adboost用
3. 関係エビデンスが未回収
4. 連帯保証契約・誓約書が未回収
```

### Step 5: 関係エビデンス保存先URL

AskUserQuestion: 「関係エビデンス保存先URLを入力してください（空欄可）」

### Step 6: 連帯保証契約・誓約書URL

AskUserQuestion: 「連帯保証契約・誓約書の保存先URLを入力してください（空欄可）」

### Step 7: 重複チェック

kintone-get-records で App 160 を検索:
- `source_organization_id` と `target_organization_id` の正順・逆順の両方をチェック

既存レコードがあれば:
- 正順一致 → 「既に登録済みです（レコード#XXX）」と表示。上書きするか確認
- 逆順一致 → 「逆向きレコード#XXX が存在します。削除して正順で再登録しますか？」と確認

### Step 8: 最終確認

全入力内容を一覧表示して確認:
```
=== 登録内容 ===
- 注入元: <source_org_id> (<source_org_name>)
- 注入先: <target_org_id> (<target_org_name>)
- 掛目: <group_multiplier>
- 備考: <notes>
- エビデンスURL: <url or 空欄>
- 契約書URL: <url or 空欄>

登録しますか？
```

※ 会社名は kintone-get-records で App 8 から取得して表示する。

### Step 9: レコード登録

kintone-add-records で登録。空欄フィールドは送信しない。

### Step 10: 結果表示

```
登録完了: レコード#XXX
https://up-sider.cybozu.com/k/160/show#record=XXX
```
