@echo off
REM Todo期限リマインダー - 平日 8:00 に自動実行
REM Claude Code CLI で /todo-reminder を非対話実行 → Slack DM通知

set CLAUDE_CMD=claude
set LOG_DIR=%USERPROFILE%\.claude\private\logs
set LOG_FILE=%LOG_DIR%\todo-reminder.log

REM ログディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo [%date% %time%] Starting todo reminder >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/todo-reminder" --allowedTools "Read,Glob,Grep,mcp__slack__slack_post_message" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
