@echo off
REM Case Guide ポーリング - 案件管理DBのガイド要求=trueを自動処理
REM スケジュール登録 or 手動実行可能

set CLAUDE_CMD=claude
set LOG_DIR=%USERPROFILE%\.claude\private\logs
set LOG_FILE=%LOG_DIR%\case-guide-%date:~0,4%%date:~5,2%%date:~8,2%.log

REM 作業ディレクトリをプロジェクトルートに設定（MCP接続の安定化）
cd /d "%USERPROFILE%\.claude\private"

REM ログディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo [%date% %time%] Starting case guide poll >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/case-guide poll" --allowedTools "Read,Bash,Write,Edit,Glob,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-update-page,mcp__notion__notion-query-data-sources,mcp__slack__slack_post_message,mcp__slack__slack_search_messages,mcp__slack__slack_get_thread_replies" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
