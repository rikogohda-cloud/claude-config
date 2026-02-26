@echo off
REM 月次本部長会議 叩き台自動生成 - 毎月15日 9:00に自動実行
REM Claude Code CLI で /monthly-prep を非対話実行

set CLAUDE_CMD=claude
set LOG_FILE=%USERPROFILE%\.claude\private\logs\monthly-prep.log

REM ログディレクトリ作成
if not exist "%USERPROFILE%\.claude\private\logs" mkdir "%USERPROFILE%\.claude\private\logs"

echo [%date% %time%] Starting monthly prep >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/monthly-prep" --allowedTools "Read,Write,Bash,Task,mcp__notion__notion-search,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-update-page,mcp__notion__notion-query-data-sources" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
