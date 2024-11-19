# copy process-level environment variables to machine level
foreach($key in [System.Environment]::GetEnvironmentVariables('Process').Keys) {
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

# echo the IIS log to the console:
Write-Host "Starting W3SVC service..."
Start-Service W3SVC

# Test application readiness (optional)
Write-Host "Sending request to localhost to ensure site is responsive..."
try {
    Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null
    Write-Host "Localhost request successful."
} catch {
    Write-Host "Localhost request failed. Check IIS configuration."
}

# Stream IIS logs to stdout
$logPath = "c:\inetpub\logs\logfiles\W3SVC\u_extend1.log"
Write-Host "Checking for log file: $logPath"
if (Test-Path -Path $logPath) {
    Write-Host "Log file found. Streaming log file to stdout."
    Get-Content -Path $logPath -Tail 1 -Wait
} else {
    Write-Host "Log file not found: $logPath. Skipping log streaming."
    # Keep the container alive to avoid crashing
    Start-Sleep -Seconds 3600
}
