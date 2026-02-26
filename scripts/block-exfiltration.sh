#!/bin/bash
# Block commands that could exfiltrate data to external services.
# Used as a PreToolUse hook for Bash commands.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Normalize: lowercase for case-insensitive matching
CMD_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

BLOCKED=""

# curl with data sending flags
if echo "$CMD_LOWER" | grep -qE 'curl\s' ; then
  if echo "$CMD_LOWER" | grep -qE -- '-d\b|--data|--data-|--form|-F\b|--upload-file|-T\b|-X\s*(post|put|patch|delete)'; then
    BLOCKED="curl with outbound data"
  fi
fi

# wget with POST
if echo "$CMD_LOWER" | grep -qE 'wget\s' ; then
  if echo "$CMD_LOWER" | grep -qE -- '--post-data|--post-file|--method\s*(post|put)'; then
    BLOCKED="wget with outbound data"
  fi
fi

# PowerShell web requests with body/outbound
if echo "$CMD_LOWER" | grep -qE 'invoke-(webrequest|restmethod)'; then
  if echo "$CMD_LOWER" | grep -qE -- '-body|-infile|-method\s*(post|put|patch|delete)'; then
    BLOCKED="PowerShell web request with outbound data"
  fi
fi

# gh gist create (can leak file contents publicly)
if echo "$CMD_LOWER" | grep -qE 'gh\s+gist\s+create'; then
  BLOCKED="gh gist create (potential data leak)"
fi

# nc/netcat/ncat sending data
if echo "$CMD_LOWER" | grep -qE '(^|\||\;|\&)\s*(nc|netcat|ncat)\s'; then
  BLOCKED="netcat (potential data exfiltration)"
fi

# Piping sensitive files to network commands
if echo "$CMD_LOWER" | grep -qE 'cat\s+.*\.(env|pem|key|secret|credentials).*\|'; then
  BLOCKED="piping sensitive file to another command"
fi

if [ -n "$BLOCKED" ]; then
  jq -n --arg reason "Blocked: $BLOCKED. If this is intentional, ask the user for approval." '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
fi

exit 0
