# copy process-level environment variables to machine level
foreach ($key in [System.Environment]::GetEnvironmentVariables('Process').Keys) {
    Write-Host 'Found process env var:' $key
    if ($null -eq [System.Environment]::GetEnvironmentVariable($key, 'Machine')) {
        if (($key -like '*RDS_*') -Or ($key -eq 'DB_NAME') -Or ($key -eq 'CLIENT_ID') -Or ($key -eq 'CurServer')) {
            Write-Host '** Promoting env var:' $key
            $value = [System.Environment]::GetEnvironmentVariable($key, 'Process')
            [System.Environment]::SetEnvironmentVariable($key, $value, 'Machine')
        }
    }
}

# restart IIS
Write-Host "Restarting IIS..."
iisreset

# Check IIS site and bindings
Write-Host "Checking IIS configuration..."
Import-Module WebAdministration
Get-Website | ForEach-Object { 
    Write-Host "Site Name: $($_.Name), Physical Path: $($_.PhysicalPath), State: $($_.State)" 
    }
Get-WebBinding | ForEach-Object { 
    Write-Host "Protocol: $($_.protocol), Binding Info: $($_.bindingInformation), SSL Flags: $($_.sslFlags)"
 }


# echo the IIS log to the console:
Write-Host "Starting W3SVC service..."
Start-Service W3SVC

# Test application readiness
Write-Host "Sending request to localhost to ensure site is responsive..."
try {
    $response = Invoke-WebRequest http://localhost -UseBasicParsing -MaximumRedirection 3
    Write-Host "Localhost request successful."
} catch {
    Write-Host "Localhost request failed. Exception: $_.Exception.Message"
}


# Stream IIS logs to stdout
$logPath = "c:\inetpub\logs\logfiles\W3SVC"
Write-Host "Checking for log file in $logPath"
if (Test-Path -Path $logPath) {
    $latestLog = Get-ChildItem -Path $logDir -Filter "u_ex*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestLog){
        Write-Host "Log file found: $($latestLog.Name). Streaming log file to stdout."
        Get-Content -Path $latestLog.FullName -Tail 1 -Wait
    } else {
    Write-Host "No Log files found in: $logPath. Skipping log streaming."
    } 
} else {
    Write-Host "Log directory not found: $logPath. Skipping log streaming."
}

# Keep the container alive
Write-Host "Keeping container alive for diagnostics..."
Start-Sleep -Seconds 3600
