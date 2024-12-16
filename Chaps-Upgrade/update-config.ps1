Import-Module WebAdministration

# Unlock the anonymous authentication section
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
    -filter 'system.webServer/security/authentication/anonymousAuthentication' `
    -name 'overrideModeDefault' -value 'Allow'

# Unlock the windows authentication section
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
    -filter 'system.webServer/security/authentication/windowsAuthentication' `
    -name 'overrideModeDefault' -value 'Allow'

Write-Host "Authentication sections unlocked successfully."