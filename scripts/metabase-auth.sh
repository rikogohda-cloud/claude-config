#!/usr/bin/env bash
# Metabase 認証スクリプト (bash版)
# セッショントークンを取得して保存

TOKEN_PATH="$HOME/.claude/private/.metabase-session"
BASE_URL="https://upsider.metabaseapp.com"

# メールアドレスを引数またはプロンプトで取得
if [ -n "$1" ]; then
    EMAIL="$1"
else
    read -p "Metabase email: " EMAIL
fi

# パスワード入力
read -s -p "Metabase password: " PASS
echo

# 認証リクエスト
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$EMAIL\",\"password\":\"$PASS\"}" \
    "$BASE_URL/api/session")

TOKEN=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "Authentication failed: $RESPONSE"
    exit 1
fi

# トークン保存
mkdir -p "$(dirname "$TOKEN_PATH")"
printf '%s' "$TOKEN" > "$TOKEN_PATH"
echo "Session token saved to $TOKEN_PATH"

# 検証
USER_INFO=$(curl -s -H "X-Metabase-Session: $TOKEN" "$BASE_URL/api/user/current")
USER_NAME=$(echo "$USER_INFO" | grep -o '"common_name":"[^"]*"' | cut -d'"' -f4)
USER_EMAIL=$(echo "$USER_INFO" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)
echo "Authenticated as: $USER_NAME ($USER_EMAIL)"
