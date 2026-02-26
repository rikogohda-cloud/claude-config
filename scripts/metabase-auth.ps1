$email = "riko.gohda@up-sider.com"
$pass = Read-Host "Metabase password" -MaskInput
$body = @{ username = $email; password = $pass } | ConvertTo-Json
try {
    $res = Invoke-RestMethod -Uri "https://upsider.metabaseapp.com/api/session" -Method Post -Body $body -ContentType "application/json"
    $token = $res.id
    $tokenPath = "$env:USERPROFILE\.claude\private\.metabase-session"
    $token | Out-File -FilePath $tokenPath -NoNewline -Encoding utf8
    Write-Host "Session token saved to $tokenPath" -ForegroundColor Green
    # verify
    $headers = @{ "X-Metabase-Session" = $token }
    $user = Invoke-RestMethod -Uri "https://upsider.metabaseapp.com/api/user/current" -Headers $headers
    Write-Host "Authenticated as: $($user.common_name) ($($user.email))" -ForegroundColor Green
} catch {
    Write-Host "Authentication failed: $_" -ForegroundColor Red
}
