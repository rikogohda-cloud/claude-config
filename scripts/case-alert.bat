@echo off
REM 債権回収シグナルアラート v3 - スプシスキャン→DB更新→シグナル検知→Slack通知
REM スケジュール: 平日 9:00（朝スキャン・通常モード）
REM 午後スキャン（15:00・quietモード）は case-alert-pm.bat を使用

set CLAUDE_CMD=claude
set LOG_DIR=%USERPROFILE%\.claude\private\logs
set LOG_FILE=%LOG_DIR%\case-alert-%date:~0,4%%date:~5,2%%date:~8,2%.log

REM 平日チェック (Mon=1..Fri=5, Sat=6, Sun=0)
for /f %%d in ('powershell -NoProfile -Command "(Get-Date).DayOfWeek.value__"') do set DOW=%%d
if %DOW%==0 exit /b 0
if %DOW%==6 exit /b 0

REM ログディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo [%date% %time%] Starting case alert v3 scan >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/case-alert" --allowedTools "Read,Bash,Write,Edit,Glob,Task,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-update-page,mcp__notion__notion-query-data-sources,mcp__slack__slack_post_message" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
