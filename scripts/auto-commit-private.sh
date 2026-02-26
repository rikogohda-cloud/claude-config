#!/bin/bash
# Auto commit & push changes in ~/.claude/ (config) and ~/.claude/private/

auto_commit() {
  local dir="$1"
  local label="$2"

  cd "$dir" || return 0

  if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    return 0
  fi

  git add -A
  git commit -m "auto: update ${label} $(date +%Y-%m-%d_%H:%M)"
  git push origin main
}

# Config repo (~/.claude/)
auto_commit "/c/Users/NaokiIshigami/.claude" "config"

# Private repo (~/.claude/private/)
auto_commit "/c/Users/NaokiIshigami/.claude/private" "private data"
