$path = "C:\Windows\System32\inetsrv\config\applicationHost.config"
[xml]$config = Get-Content -Path $path

# Find the authentication sections and unlock them
$config.configuration.'system.webServer'.sectionGroup.section | Where-Object { $_.name -eq 'anonymousAuthentication' } | ForEach-Object {
    $_.overrideModeDefault = "Allow"
}

$config.configuration.'system.webServer'.sectionGroup.section | Where-Object { $_.name -eq 'windowsAuthentication' } | ForEach-Object {
    $_.overrideModeDefault = "Allow"
}

# Save changes to applicationHost.config
$config.Save($path)

Write-Host "Authentication sections successfully unlocked in applicationHost.config."
