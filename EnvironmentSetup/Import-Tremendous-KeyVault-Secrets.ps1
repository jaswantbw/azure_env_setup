# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile,
  [string] [Parameter(Mandatory=$true)] $ApiKey,
  [string] [Parameter(Mandatory=$true)] $ApiUrl
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
    $command = "az keyvault secret set --% --name ""Tremendous-ApiUrl"" --vault-name ""$keyVaultName"" --value ""$($ApiUrl)"" "
    (Invoke-Expression $command) | ConvertFrom-Json
}

if ($ApiKey -ne "") {
    $command = "az keyvault secret set --% --name ""Tremendous-ApiKey"" --vault-name ""$keyVaultName"" --value ""$($ApiKey)"" "
    (Invoke-Expression $command) | ConvertFrom-Json
}