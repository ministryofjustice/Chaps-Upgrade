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

# Start W3SVC service
Write-Host "Starting W3SVC service"
Start-Service W3SVC

# Send a request to localhost to trigger logging
Write-Host "Sending request to localhost to generate IIS logs..."
Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null

# Detect IIS log file path
Write-Host "Detecting IIS log directory..."
$logDirectory = (Get-WebConfigurationProperty -Filter "system.applicationHost/sites/siteDefaults/logFile" -Name "directory").Value
if (-not $logDirectory) {
  Write-Host "Defaulting to standard IIS log directory..."
  $logDirectory = "C:\inetpub\logs\logfiles"
}

Write-Host "Log directory detected: $logDirectory"

# Dynamically determine site ID (assumes 'Default Web Site')
Write-Host "Determining the site ID for 'Default Web Site'..."
$siteID = (Get-WebConfigurationProperty -Filter "system.applicationHost/sites/site[@name='Default Web Site']" -Name "id").Value

# Debug: output site ID
if (-not $siteID) {
    Write-Host "Error: Could not determine site ID for 'Default Web Site'. Exiting."
    Exit 1
} else {
  Write-Host "Site ID detected: $siteID"
}

# Build the log file path
$logFilePath = Join-Path -Path $logDirectory -ChildPath "W3SVC$siteID\u_extend1.log"
Write-Host "Log file path: $logPath"

# Wait for the log file to be created, with retries
$retries = 10
while (!(Test-Path -Path $logPath) -and ($retries -gt 0)) {
    Write-Host "Log file not found, waiting for 5 seconds..."
    Start-Sleep -Seconds 5
    $retries--
}

# Stream log file contents or exit gracefully if not found
if (Test-Path -Path $logPath) {
    Write-Host "Log file found. Streaming contents to stdout:"
    Get-Content -Path $logPath -Tail 1 -Wait
} else {
    Write-Host "Log file still not found after retries. Exiting gracefully."
    Exit 0
}
