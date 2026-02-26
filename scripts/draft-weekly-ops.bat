@echo off
REM 本部長会議 週次ページ自動下書き - 毎週火曜8:30に自動実行
REM Claude Code CLI で /draft-weekly-ops を非対話実行

set CLAUDE_CMD=claude
set LOG_FILE=%USERPROFILE%\.claude\private\logs\draft-weekly-ops.log

REM ログディレクトリ作成
if not exist "%USERPROFILE%\.claude\private\logs" mkdir "%USERPROFILE%\.claude\private\logs"

echo [%date% %time%] Starting draft-weekly-ops >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/draft-weekly-ops" --allowedTools "Read,Write,Bash,Task,mcp__slack__slack_search_messages,mcp__slack__slack_get_channel_history,mcp__slack__slack_get_thread_replies,mcp__slack__slack_list_channels,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-update-page,mcp__notion__notion-search,mcp__notion__notion-query-data-sources" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
