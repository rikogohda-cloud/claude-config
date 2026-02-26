@echo off
REM Slackサマリー 週次自動生成 - 毎週月曜9:00に自動実行
REM Claude Code CLI で /weekly-slack-summary を非対話実行

set CLAUDE_CMD=claude
set LOG_FILE=%USERPROFILE%\.claude\private\logs\weekly-slack-summary.log

REM ログディレクトリ作成
if not exist "%USERPROFILE%\.claude\private\logs" mkdir "%USERPROFILE%\.claude\private\logs"

echo [%date% %time%] Starting weekly slack summary >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/weekly-slack-summary" --allowedTools "Read,Write,Bash,Glob,Grep,Task,mcp__slack__slack_search_messages,mcp__slack__slack_get_channel_history,mcp__slack__slack_list_channels,mcp__slack-capital__slack_search_messages,mcp__slack-capital__slack_get_channel_history,mcp__notion__notion-search,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-query-data-sources" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
