# This script will create B2CGraphAPIService Application in azure B2C tenant
Param(
  [string] [Parameter(Mandatory=$true)] $templateParameterFile
)

$ErrorActionPreference = "Stop"

# Create a hash table for the parameters.
$parameters = @{}

# Populate the parameters hash table with values from the parameter file(s).
$parameterFile = (Get-Content $templateParameterFile) -join "`n" | ConvertFrom-Json
$parameterObject = $parameterFile.parameters

$parameterObject | Get-Member -MemberType NoteProperty | ForEach-Object {
    $key = [string]$_.Name
    $value = [string]$parameterObject."$key".value

    $parameters[$key] = $value
}

# Create strong credentials for b2c administrator account
$azureADB2CGraphAPIDisplayName = "B2CGraphAPIService"
$azureADAppPassword = (([System.Web.Security.Membership]::GeneratePassword(40,0)) -replace "[^a-zA-Z0-9]", "").Substring(0,20)
$identifierUris = "http://www.digitalinfuzion.com"
$tenant = $parameters.b2cTenantName
$requiredResourceManifest = "$($PSScriptRoot)\B2CGraphAPIService-AppRegistration.json"

$login = Login-AzureRmAccount --tenant $tenant --allow-no-subscription | ConvertFrom-Json

# Check if the B2C AD application already exist
$existingApp = (az ad app list --display-name $azureADB2CGraphAPIDisplayName | ConvertFrom-Json).displayName
[Console]::ResetColor()    
if ($existingApp -eq $azureADB2CGraphAPIDisplayName) {

    Write-Host "Azure AD B2C Application named $azureADB2CGraphAPIDisplayName already exists and has not been changed."
    Exit

}
else {

    #create b2c Azure AD Application
    [string] $application = az ad app create --display-name $azureADB2CGraphAPIDisplayName --password $azureADAppPassword --identifier-uris $identifierUris --required-resource-accesses $requiredResourceManifest
    $appId = (ConvertFrom-Json -InputObject $application).appId

    #assign Application admin consent
    az ad app permission admin-consent --id $appId
    Write-Host "Created $azureADB2CGraphAPIDisplayName Azure AD B2C Application."
}

#Save B2CGraphAPIService Azure AD Application and its password to parameter file.
$templateParameters = (Get-Content $templateParameterFile) | ConvertFrom-Json
$templateParameters.parameters | Add-Member -Force azureADB2CGraphAPIAppId @{ value = $appId }
$templateParameters.parameters | Add-Member -Force azureADB2CGraphAPIAppPassword @{ value = $azureADAppPassword }

# Format the JSON file
[Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
$jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($templateParameters | ConvertTo-Json | Out-String))
$formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
$formattedJson | Out-File $templateParameterFile