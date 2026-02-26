@echo off
REM Deal Review ポーリング - Notion DBの未処理案件を自動実行
REM スケジュール登録 or 手動実行可能

set CLAUDE_CMD=claude
set LOG_DIR=%USERPROFILE%\.claude\private\logs
set LOG_FILE=%LOG_DIR%\deal-review-%date:~0,4%%date:~5,2%%date:~8,2%.log

REM ログディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo [%date% %time%] Starting deal review poll >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/deal-review poll" --allowedTools "Read,Bash,Write,Glob,Grep,Task,WebSearch,WebFetch,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-update-page,mcp__notion__notion-search,mcp__notion__notion-query-data-sources,mcp__slack-capital__slack_post_message" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
