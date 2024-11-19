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
Write_Host "Restarting IIS..."
iisreset

# Start W3SVC service
Write_Host "Starting W3SVC service"
Start-Service W3SVC

# Send a request to localhost to trigger logging
Write-Host "Sending request to localhost to generate IIS logs..."
Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null

# Automatically detect IIS log file path
Write-Host "Detecting IIS log directory..."
$logDirectory = Get-WebConfigurationProperty -Filter "system.applicationHost/sites/siteDefaults/logFile" -Name "directory"
$logDirectory = if ($logDirectory) { $logDirectory } else { "C:\inetpub\logs\logfiles" }

# Determine site ID (assumes single site)
$siteID = Get-WebConfigurationProperty -Filter "system.applicationHost/sites/site[@name='Default Web Site']" -Name "id"
$logPath = Join-Path -Path $logDirectory -ChildPath "W3SVC$siteID\u_extend1.log"

Write-Host "Log file path: $logPath"

# Wait for the log file to be created, with retries
$retries = 10
while (!(Test-Path -Path $logPath) -and ($retries -gt 0)) {
    Write-Host "Log file not found, waiting for 5 seconds..."
    Start-Sleep -Seconds 5
    $retries--
}

if (Test-Path -Path $logPath) {
    Write-Host "Log file found. Streaming contents to stdout:"
    Get-Content -Path $logPath -Tail 1 -Wait
} else {
    Write-Host "Log file still not found after retries. Ensure IIS is properly configured and traffic is reaching the site."
}
