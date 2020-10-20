# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile
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

$context = New-AzureStorageContext -StorageAccountName $parameters['storageAccountName'] -StorageAccountKey $parameters['storageAccountKey'] -Protocol Https
$existingRule = (Get-AzureStorageCORSRule -ServiceType Blob -Context $context).AllowedHeaders
if ($existingRule -eq $null) {
    Write-Host "Setting CORS rule for storage account $($parameters['storageAccountName'])."
    $corsRules = (@{
        AllowedHeaders=@("*");
        AllowedOrigins=@("*");
        MaxAgeInSeconds=200;
        AllowedMethods=@("Get","Options")})
    Set-AzureStorageCORSRule -ServiceType Blob -Context $context -CorsRules $corsRules
}
else {
    Write-Host "CORS rule already exists for storage account $($parameters['storageAccountName'])."
}