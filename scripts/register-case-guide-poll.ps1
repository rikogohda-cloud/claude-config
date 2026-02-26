$batPath = "$env:USERPROFILE\.claude\scripts\case-guide-poll.bat"
$action = New-ScheduledTaskAction -Execute $batPath
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$settings.ExecutionTimeLimit = 'PT30M'

# CIM instance for trigger with repetition
$trigger = New-CimInstance -CimClass (Get-CimClass -ClassName MSFT_TaskWeeklyTrigger -Namespace Root/Microsoft/Windows/TaskScheduler) -ClientOnly
$trigger.DaysOfWeek = 0x3E  # Mon-Fri (2+4+8+16+32)
$trigger.WeeksInterval = 1
$trigger.StartBoundary = '2026-02-18T09:00:00'
$trigger.Enabled = $true
$trigger.Repetition = New-CimInstance -CimClass (Get-CimClass -ClassName MSFT_TaskRepetitionPattern -Namespace Root/Microsoft/Windows/TaskScheduler) -ClientOnly
$trigger.Repetition.Interval = 'PT15M'
$trigger.Repetition.Duration = 'PT9H'
$trigger.Repetition.StopAtDurationEnd = $false

Register-ScheduledTask -TaskName 'CaseGuidePoll' -Action $action -Trigger $trigger -Settings $settings -Description 'Case Guide poll - checks DB for guide requests every 15min weekdays' -Force
