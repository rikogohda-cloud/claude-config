@echo off
REM 朝の自動ブリーフィング - 平日 8:30 に自動実行
REM Claude Code CLI で /morning-auto を非対話実行 → Slack DM通知

set CLAUDE_CMD=claude
set LOG_DIR=%USERPROFILE%\.claude\private\logs
set LOG_FILE=%LOG_DIR%\morning-briefing.log

REM ログディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo [%date% %time%] Starting morning briefing >> "%LOG_FILE%"

%CLAUDE_CMD% -p "/morning-auto" --allowedTools "Read,Bash,Glob,Grep,Write,mcp__slack__slack_search_messages,mcp__slack__slack_get_channel_history,mcp__slack__slack_get_thread_replies,mcp__slack__slack_list_channels,mcp__slack__slack_get_users,mcp__slack__slack_get_user_profile,mcp__slack__slack_post_message,mcp__slack-capital__slack_search_messages,mcp__slack-capital__slack_get_channel_history,mcp__slack-capital__slack_get_thread_replies,mcp__slack-capital__slack_list_channels,mcp__slack-capital__slack_get_users,mcp__slack-capital__slack_get_user_profile,mcp__slack-capital__slack_post_message" >> "%LOG_FILE%" 2>&1

echo [%date% %time%] Completed >> "%LOG_FILE%"
