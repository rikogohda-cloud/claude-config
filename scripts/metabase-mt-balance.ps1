# Metabase MT残高一括取得スクリプト
# 出力: orgID → MT残高 の JSON ファイル (~/.claude/private/tmp_mt_balance.json)

$tokenPath = "$env:USERPROFILE\.claude\private\.metabase-session"
$outputPath = "$env:USERPROFILE\.claude\private\tmp_mt_balance.json"

try {
    $token = (Get-Content $tokenPath -Raw -ErrorAction Stop).Trim()
} catch {
    Write-Host "ERROR: Token file not found at $tokenPath"
    exit 1
}

$headers = @{ "X-Metabase-Session" = $token }

# Step 1: Verify token
try {
    Invoke-RestMethod -Uri "https://upsider.metabaseapp.com/api/user/current" -Headers $headers -ErrorAction Stop | Out-Null
} catch {
    Write-Host "EXPIRED"
    exit 2
}

# Step 2: Query model/4192
try {
    $result = Invoke-RestMethod -Uri "https://upsider.metabaseapp.com/api/card/4192/query/json" -Method Post -Headers $headers -ContentType "application/json" -ErrorAction Stop

    # Build orgID -> balance mapping
    # Note: Column name contains → character which gets garbled in PowerShell encoding
    # Use partial match on property names instead of hardcoded strings
    $mapping = @{}
    foreach ($row in $result) {
        $props = $row.PSObject.Properties
        $orgIdProp = $props | Where-Object { $_.Name -like "*Organization ID*" } | Select-Object -First 1
        $balanceProp = $props | Where-Object { $_.Name -like "*Balance*" } | Select-Object -First 1
        if ($null -ne $orgIdProp -and $null -ne $balanceProp) {
            $orgId = $orgIdProp.Value
            $balance = $balanceProp.Value
            if ($null -ne $orgId -and $orgId -ne 0) {
                $mapping["$orgId"] = $balance
            }
        }
    }

    $jsonStr = $mapping | ConvertTo-Json -Compress
    [System.IO.File]::WriteAllText($outputPath, $jsonStr, [System.Text.UTF8Encoding]::new($false))
    Write-Host "OK:$($mapping.Count)"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 3
}
