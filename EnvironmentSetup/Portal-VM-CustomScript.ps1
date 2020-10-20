# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] $PortalHomeDirectory = "C:\inetpub\wwwroot\nof1-portal",
  [string] [Parameter(Mandatory=$true)] $DnnDatabaseConnectionString,
  [string] [Parameter(Mandatory=$true)] $KeyVaultUri,
  [string] [Parameter(Mandatory=$true)] $KeyVaultClientId,
  [string] $KeyVaultClientSecret,
  [string] [Parameter(Mandatory=$true)] $KeyVaultCertificateThumbprint,
  [string] $Timestamp # The timestamp parameter ensures the command text is unique, in case it needs to be run again.
)

$ErrorActionPreference = "Stop"


# Install the URL Rewrite module.
Start-Process msiexec.exe -Wait -ArgumentList "/i $PSScriptRoot\rewrite_amd64_en-US.msi /quiet"


# Load up web.config into the XML parser.
$xml = New-Object xml
$xml.PreserveWhitespace = $true
$xml.Load("$PortalHomeDirectory\web.config")


# Update web.config with the key vault settings.
$n1 = $xml.SelectSingleNode("configuration/autofac/modules/module[@type='Nof1Health.Configuration.Autofac.KeyVaultModule, Nof1Health.Configuration.Autofac']")
$n2 = $xml.SelectSingleNode("configuration/autofac/modules/module[@type='Nof1Health.Portal.AzureServicesPortalModule, Nof1Health.Portal']")

$keyvaultNodes = @($n1, $n2)

foreach ($node in $keyvaultNodes) {
    $node.SelectSingleNode("properties/property[@name='ClientId']/@value").InnerText = $KeyVaultClientId
    $node.SelectSingleNode("properties/property[@name='CertificateThumbprint']/@value").InnerText = $KeyVaultCertificateThumbprint
    $node.SelectSingleNode("properties/property[@name='VaultName']/@value").InnerText = $KeyVaultUri

    $clientSecretNode = $node.SelectSingleNode("properties/property[@name='ClientSecret']")
    if ($clientSecretNode -ne $null) {
        $clientSecretNode.ParentNode.RemoveChild($clientSecretNode)
    }
}

$xml.Save("$PortalHomeDirectory\web.config")

# Grant the portal app pool permission to the certificate.
$certificateName = (((gci cert:\LocalMachine\my | ? {$_.thumbprint -like $KeyVaultCertificateThumbprint}).PrivateKey).CspKeyContainerInfo).UniqueKeyContainerName
$certificatePath = $env:ProgramData + “\Microsoft\Crypto\RSA\MachineKeys\” + $certificateName

$certificateAcl = Get-Acl $certificatePath
$certificateAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\nof1-portal", "Read", "Allow")
$certificateAcl.SetAccessRule($certificateAccessRule)
Set-Acl $certificatePath $certificateAcl

iisreset
