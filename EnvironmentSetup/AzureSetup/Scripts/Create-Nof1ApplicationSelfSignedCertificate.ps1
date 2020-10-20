Param(
  [string] [Parameter(Mandatory=$true)] $CustomerIdentifier
)

. .\New-SelfSignedCertificateEx.ps1

$certificatePassword = Read-Host -Prompt "Enter certificate password"

New-SelfSignedCertificateEx -Subject "cn=$CustomerIdentifier,dc=nof1health,dc=com" -NotBefore ([datetime]::Now.AddDays(-1)) -NotAfter ([datetime]::Now.AddYears(100)) `
    -FriendlyName "$CustomerIdentifier Application Certificate" -Path ".\$CustomerIdentifier.pfx" -Password (ConvertTo-SecureString -AsPlainText $certificatePassword -Force) -Exportable

$pfx = Get-ChildItem .\$CustomerIdentifier.pfx

$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate -ArgumentList $pfx.FullName, $certificatePassword

$keyCredentialsString = @"
{
    "customKeyIdentifier": "$([Convert]::ToBase64String($certificate.GetCertHash()))",
    "keyId": "$([System.Guid]::NewGuid().ToString())",
    "type": "AsymmetricX509Cert",
    "usage": "verify",
    "value": "$([Convert]::ToBase64String($certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)))"
}
"@

$keyCredentials = $keyCredentialsString | ConvertFrom-Json | ConvertTo-Json

$keyCredentials | Out-File ".\$CustomerIdentifier.keyCredentials.json"

Write-Host
Write-Host
Write-Host "Add the contents of '$CustomerIdentifier.keyCredentials.json' to the 'keyCredentials' array in the AD application manifest."
Write-Host "Upload the PFX to any service (Web API, portal, etc) that needs it."

