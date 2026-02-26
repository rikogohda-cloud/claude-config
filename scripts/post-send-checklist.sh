#!/bin/bash
# PostToolUse hook: block after email send until post-send checklist is done.
# Triggers on: gog gmail send, gog gmail reply, gog.exe gmail send, gog.exe gmail reply

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only intercept Bash tool calls
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
CMD_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

# Check if this is a gmail send/reply command
if ! echo "$CMD_LOWER" | grep -qE 'gog(\.exe)?\s+gmail\s+(send|reply)'; then
  exit 0
fi

# Detect scheduling-related content
IS_SCHEDULING=false
if echo "$CMD_LOWER" | grep -qiE 'schedule|meeting|availability|calendar|日程|ミーティング|打ち合わせ|MTG|slot|候補日'; then
  IS_SCHEDULING=true
fi

if [ "$IS_SCHEDULING" = true ]; then
  REASON="[Post-send: scheduling email sent — complete NOW]

1. Register tentative calendar events for all proposed dates (prefix: [tentative])
2. Update relationships.md with any new contacts/info
3. Update todo.md with follow-up items
4. git add & commit & push (both config and private repos)

Do NOT proceed to the next task until all 4 steps are complete."
else
  REASON="[Post-send checklist — mandatory]

1. Verify the email was sent correctly (check --reply-to-message-id if reply)
2. Update relationships.md if new contact info was found
3. Update todo.md with any action items or follow-ups
4. Register calendar events if dates were mentioned
5. git add & commit & push (both config and private repos)

Do NOT proceed to the next task until all steps are complete."
fi

jq -n --arg reason "$REASON" '{
  decision: "block",
  reason: $reason,
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $reason
  }
}'
