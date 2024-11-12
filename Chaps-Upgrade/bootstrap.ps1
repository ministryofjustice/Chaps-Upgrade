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
iisreset

# echo the IIS log to the console:
Write-Host 'Start W3SVC'
Start-Service W3SVC
Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null
netsh http flush logbuffer | Out-Null
Write-Host 'Send IIS logs to stdout:'
Get-Content -path 'c:\inetpub\logs\logfiles\W3SVC\u_extend1.log' -Tail 1 -Wait
