@echo off
REM 週次ネクストアクションリマインダー - 毎週月曜9:00に自動実行
REM Claude Code CLI で /weekly-reminder を非対話実行

set CLAUDE_CMD=claude
set LOG_FILE=%USERPROFILE%\.claude\private\logs\weekly-reminder.log

REM ログディレクトリ作成
if not exist "%USERPROFILE%\.claude\private\logs" mkdir "%USERPROFILE%\.claude\private\logs"

echo [%date% %time%] Starting weekly reminder >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/weekly-reminder" --allowedTools "Read,Bash,mcp__slack-capital__slack_post_message" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
