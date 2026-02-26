@echo off
REM 作業日報の自動生成 - AM 3:00 に前日分を自動実行
REM Claude Code CLI で /daily-report を非対話実行 → Notion投稿

set CLAUDE_CMD=claude
set LOG_DIR=%USERPROFILE%\.claude\private\logs
set LOG_FILE=%LOG_DIR%\daily-report.log

REM ログディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo [%date% %time%] Starting daily report generation >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/daily-report" --allowedTools "Read,Bash,Glob,Grep,Write,Edit,Task,mcp__slack__slack_search_messages,mcp__slack__slack_get_channel_history,mcp__slack__slack_get_thread_replies,mcp__slack__slack_list_channels,mcp__slack__slack_get_users,mcp__slack__slack_get_user_profile,mcp__slack-capital__slack_get_channel_history,mcp__slack-capital__slack_get_thread_replies,mcp__slack-capital__slack_list_channels,mcp__slack-capital__slack_get_users,mcp__slack-capital__slack_get_user_profile,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-update-page" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
