#!/usr/bin/env bash
# Metabase MT残高一括取得スクリプト (bash版)
# 出力: orgID → MT残高 の JSON ファイル (~/.claude/private/tmp_mt_balance.json)

TOKEN_PATH="$HOME/.claude/private/.metabase-session"
OUTPUT_PATH="$HOME/.claude/private/tmp_mt_balance.json"
BASE_URL="https://upsider.metabaseapp.com"

# Step 0: Read token
if [ ! -f "$TOKEN_PATH" ]; then
    echo "ERROR: Token file not found at $TOKEN_PATH"
    exit 1
fi
TOKEN=$(cat "$TOKEN_PATH" | tr -d '[:space:]')

# Step 1: Verify token
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-Metabase-Session: $TOKEN" \
    "$BASE_URL/api/user/current")

if [ "$HTTP_CODE" != "200" ]; then
    echo "EXPIRED"
    exit 2
fi

# Step 2: Query model/4192
RESPONSE=$(curl -s -X POST \
    -H "X-Metabase-Session: $TOKEN" \
    -H "Content-Type: application/json" \
    "$BASE_URL/api/card/4192/query/json")

if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    echo "ERROR: Failed to query Metabase"
    exit 3
fi

# Step 3: Build orgID -> balance mapping using jq or node
# Try jq first, fall back to node
if command -v jq &>/dev/null; then
    # jq: extract Organization ID and Balance from each row
    # Property names contain special chars, use partial match
    MAPPING=$(echo "$RESPONSE" | jq '
        [.[] | to_entries] |
        map(
            (map(select(.key | test("Organization ID"))) | first // empty) as $org |
            (map(select(.key | test("Balance"))) | first // empty) as $bal |
            select($org.value != null and $org.value != 0) |
            {key: ($org.value | tostring), value: $bal.value}
        ) | from_entries
    ')
elif command -v node &>/dev/null; then
    MAPPING=$(node -e "
        const data = JSON.parse(require('fs').readFileSync('/dev/stdin', 'utf8'));
        const mapping = {};
        for (const row of data) {
            const keys = Object.keys(row);
            const orgKey = keys.find(k => k.includes('Organization ID'));
            const balKey = keys.find(k => k.includes('Balance'));
            if (orgKey && balKey && row[orgKey] && row[orgKey] !== 0) {
                mapping[String(row[orgKey])] = row[balKey];
            }
        }
        console.log(JSON.stringify(mapping));
    " <<< "$RESPONSE")
else
    echo "ERROR: jq or node required"
    exit 4
fi

if [ $? -ne 0 ] || [ -z "$MAPPING" ]; then
    echo "ERROR: Failed to parse response"
    exit 3
fi

# Write output
echo "$MAPPING" > "$OUTPUT_PATH"
COUNT=$(echo "$MAPPING" | grep -o '"[0-9]*":' | wc -l | tr -d ' ')
echo "OK:$COUNT"
