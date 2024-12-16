$path = "C:\Windows\System32\inetsrv\config\applicationHost.config"
[xml]$config = Get-Content -Path $path

$anonymousAuth = $config.configuration.'system.webServer'.sectionGroup.section | Where-Object { $_.name -eq 'anonymousAuthentication' }
$windowsAuth = $config.configuration.'system.webServer'.sectionGroup.section | Where-Object { $_.name -eq 'windowsAuthentication' }

$anonymousAuth.overrideModeDefault = "Allow"
$windowsAuth.overrideModeDefault = "Allow"

$config.Save($path)
