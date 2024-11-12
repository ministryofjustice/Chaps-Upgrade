$password = ConvertTo-SecureString -String 'dockerpa55w0rd' -AsPlainText -Force
Import-PfxCertificate -FilePath 'C:\https\certificate.pfx' -CertStoreLocation Cert:\LocalMachine\My -Password $password
 
Import-Module WebAdministration
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*CN=localhost*" }
#$certThumbprint = [string]($cert.Thumbprint -replace '\s|-','').ToLower()
#Write-Host "Using certificate thumbprint: $certThumbprint"
#Write-Host "Length of thumbprint: $($certThumbprint.Length)"
#$appid = [guid]::NewGuid().ToString()
#Write-Host "Using AppID: {$appid}"
netsh http add sslcert ipport=0.0.0.0:443 certhash=1e8427d6d82abb964441562e157e8ccaf3a91c65 appid='{205d4c23-0e3a-40cf-b2a7-e72602e643ca}'
