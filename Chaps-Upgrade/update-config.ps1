# Unlock anonymousAuthentication
C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:system.webServer/security/authentication/anonymousAuthentication

# Unlock windowsAuthentication
C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:system.webServer/security/authentication/windowsAuthentication

Write-Host "Sections successfully unlocked using appcmd."

