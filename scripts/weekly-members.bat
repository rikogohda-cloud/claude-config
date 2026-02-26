@echo off
REM メンバー週次活動レポート - 毎週金曜17:00に自動実行
REM Claude Code CLI で /weekly-members を非対話実行

set CLAUDE_CMD=claude
set LOG_FILE=%USERPROFILE%\.claude\private\logs\weekly-members.log

REM ログディレクトリ作成
if not exist "%USERPROFILE%\.claude\private\logs" mkdir "%USERPROFILE%\.claude\private\logs"

echo [%date% %time%] Starting weekly members report >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/weekly-members" --allowedTools "Read,Write,Edit,Bash,Glob,AskUserQuestion,mcp__slack-capital__slack_search_messages,mcp__slack-capital__slack_list_channels,mcp__slack-capital__slack_get_users,mcp__slack-capital__slack_get_user_profile,mcp__slack__slack_search_messages,mcp__notion__notion-search,mcp__notion__notion-fetch,mcp__notion__notion-create-pages,mcp__notion__notion-update-page" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
