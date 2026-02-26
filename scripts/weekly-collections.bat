@echo off
REM 債権回収 週次サマリー - 毎週月曜9:00に自動実行
REM Claude Code CLI で /weekly-collections を非対話実行

set CLAUDE_CMD=claude
set LOG_FILE=%USERPROFILE%\.claude\private\logs\weekly-collections.log

REM ログディレクトリ作成
if not exist "%USERPROFILE%\.claude\private\logs" mkdir "%USERPROFILE%\.claude\private\logs"

echo [%date% %time%] Starting weekly collections summary >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/weekly-collections" --allowedTools "Read,Bash,Write,Edit,Glob,mcp__notion__notion-search,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-update-page" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
