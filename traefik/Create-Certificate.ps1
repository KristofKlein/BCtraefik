if (!(get-command openssl)) {
  # maybe you have git:
  if (!(get-command 'C:\Program Files\Git\mingw64\bin\openssl.exe')) {
  
  Write-Host "OpenSSL is not installed. Please install it from https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Red
  Write-Host "OpenSSL light should be good enough https://slproweb.com/download/Win64OpenSSL_Light-3_3_1.msi" -ForegroundColor Red
  Write-Host "or install GIT - as it also has openssl.exe onboard." -ForegroundColor Red
  exit
  } else 
  {
    Write-Host "Using openssl from git" -ForegroundColor Yellow
    $openssl = 'C:\Program Files\Git\mingw64\bin\openssl.exe'
    Set-Alias openssl $openssl -Scope script
  }
}

$publicDnsName = [System.Net.Dns]::GetHostByName($env:computerName).HostName
$hostName = hostname
$runPath = "$PWD\config"

Write-Host "Creating Self Signed Certificate for $publicDnsName"
$cert = New-SelfSignedCertificate -DnsName @($publicDnsName, $hostName) -CertStoreLocation Cert:\LocalMachine\My -KeyExportPolicy Exportable -Verbose -NotAfter (Get-Date).AddYears(2) -FriendlyName 'Local Machine certificate for e.g. container user'

do
{
    $SecurePfxPassword = Read-Host "Enter a at least 8 digits Password for the pfx certificate export" -AsSecureString    
}
while ($SecurePfxPassword.length -lt 8)

$certificatePfxFile = Join-Path $runPath "server.pfx"
$certificateCerFile = Join-Path $runPath "server.cer"
$certificateKeyFile = Join-Path $runPath "server.key"
$certificateCrtFile = Join-Path $runPath "server.crt"

Export-PfxCertificate -Cert $cert -FilePath $certificatePfxFile -Password $SecurePfxPassword | Out-Null
Export-Certificate -Cert $cert -FilePath $CertificateCerFile | Out-Null

$certificateThumbprint = $cert.Thumbprint
Write-Host "Self Signed Certificate Thumbprint $certificateThumbprint"
Import-PfxCertificate -Password $SecurePfxPassword -FilePath $certificatePfxFile -CertStoreLocation "cert:\localMachine\TrustedPeople" | Out-Null

$dnsidentity = $cert.GetNameInfo('SimpleName',$false)
Write-Host "DNS identity $dnsidentity"

if (get-command openssl) {
  & openssl pkcs12 -in $certificatePfxFile -out $certificateKeyFile -nodes -nocerts
  & openssl pkcs12 -in $certificatePfxFile -out $certificateCrtFile -nodes
}