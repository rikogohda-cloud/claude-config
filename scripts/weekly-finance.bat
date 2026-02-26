@echo off
REM 週次ファイナンスメールサマリー - 毎週月曜8:45に自動実行
REM Claude Code CLI で /weekly-finance を非対話実行

set CLAUDE_CMD=claude
set LOG_FILE=%USERPROFILE%\.claude\private\logs\weekly-finance.log

REM ログディレクトリ作成
if not exist "%USERPROFILE%\.claude\private\logs" mkdir "%USERPROFILE%\.claude\private\logs"

echo [%date% %time%] Starting weekly finance summary >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/weekly-finance" --allowedTools "Read,Bash,Write,Edit,mcp__slack__slack_post_message" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
