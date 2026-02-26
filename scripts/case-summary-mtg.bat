@echo off
REM MTG準備資料 生成 - 全アクティブ案件のサマリーをNotionに作成
REM 手動実行（Rikoが MTG 前に実行）

set CLAUDE_CMD=claude
set LOG_DIR=%USERPROFILE%\.claude\private\logs
set LOG_FILE=%LOG_DIR%\case-summary-mtg-%date:~0,4%%date:~5,2%%date:~8,2%.log

REM ログディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo [%date% %time%] Starting case summary MTG generation >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/case-summary mtg" --allowedTools "Read,Bash,Write,Edit,Glob,Task,mcp__slack__slack_search_messages,mcp__slack__slack_get_channel_history,mcp__slack__slack_get_thread_replies,mcp__slack__slack_post_message,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-query-data-sources" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
