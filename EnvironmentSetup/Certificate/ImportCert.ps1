Param(
  [string] [Parameter(Mandatory=$true)] $CertificateName,
  [string] [Parameter(Mandatory=$true)] $keyVaultName,
  [string] [Parameter(Mandatory=$true)] $CertificateFilename,
  [string] [Parameter(Mandatory=$true)] $CertificatePassword,
  [string] [Parameter(Mandatory=$true)] $keyVaultAdminTenant
)

az login --tenant $keyVaultAdminTenant

# Construct the keyvault command as a string because the password may include special characters.
$command = "az keyvault certificate import --name ""$CertificateName"" --file $CertificateFilename --vault-name $keyVaultName --% --password ""$CertificatePassword"""
$commandResult = (Invoke-Expression $command) | ConvertFrom-Json
$commandResult