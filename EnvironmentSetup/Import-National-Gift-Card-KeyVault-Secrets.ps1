# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile,
  [string] [Parameter(Mandatory=$true)] $ApiUsername,
  [string] [Parameter(Mandatory=$true)] $ApiPassword,
  [string] [Parameter(Mandatory=$false)] $ApiUrl,
  [string] [Parameter(Mandatory=$false)] $StudyIdentifier
)

$ErrorActionPreference = "Stop"

# Create a hash table for the parameters.
$parameters = @{}

# Populate the parameters hash table with values from the parameter file(s).
$parameterFile = (Get-Content $TemplateParameterFile) -join "`n" | ConvertFrom-Json
$parameterObject = $parameterFile.parameters

$parameterObject | Get-Member -MemberType NoteProperty | ForEach-Object {
    $key = [string]$_.Name
    $value = [string]$parameterObject."$key".value

    $parameters[$key] = $value
}

$resourceGroupName = "$($parameters.customerIdentifier)-$($parameters.environment)"
$keyVaultName = "$($parameters.customerIdentifier)-keyvault-$($parameters.environment)"

# Log in to the KeyVault tenant.
$loginInfo = az account show | ConvertFrom-Json
$loggedInTenantId = $loginInfo.tenantId

if ($loggedInTenantId -ne $parameters.activeDirectoryTenantId) {
    az login --tenant $parameters.activeDirectoryTenantId --allow-no-subscriptions
}


if ($ApiUrl -ne "") {
    $command = "az keyvault secret set --% --name ""NationalGiftCard-ApiUrl"" --vault-name ""$keyVaultName"" --value ""$($ApiUrl)"" "
    (Invoke-Expression $command) | ConvertFrom-Json
}

if ($StudyIdentifier -eq "") {
    $command = "az keyvault secret set --% --name ""NationalGiftCard-ApiPassword"" --vault-name ""$keyVaultName"" --value ""$($ApiPassword)"" "
    (Invoke-Expression $command) | ConvertFrom-Json

    $command = "az keyvault secret set --% --name ""NationalGiftCard-ApiUsername"" --vault-name ""$keyVaultName"" --value ""$($ApiUsername)"" "
    (Invoke-Expression $command) | ConvertFrom-Json
}
else {
    $command = "az keyvault secret set --% --name ""NationalGiftCard-$($StudyIdentifier)-ApiPassword"" --vault-name ""$keyVaultName"" --value ""$($ApiPassword)"" "
    (Invoke-Expression $command) | ConvertFrom-Json

    $command = "az keyvault secret set --% --name ""NationalGiftCard-$($StudyIdentifier)-ApiUsername"" --vault-name ""$keyVaultName"" --value ""$($ApiUsername)"" "
    (Invoke-Expression $command) | ConvertFrom-Json
}
