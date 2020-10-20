# This script will add keys to KeyVault and Azure Storage Table.
Param(
  [string] [Parameter(Mandatory=$true)] $templateParameterFile,
  [string] [Parameter(Mandatory=$true)] $subscription
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

$b2cTenant = $parameters.b2cTenantName
$ADTenant = $parameters.customerIdentifier+".onmicrosoft.com"
$azureADB2CGraphAPIAppId = $parameters.azureADB2CGraphAPIAppId
$azureADB2CGraphAPIAppPassword = $parameters.azureADB2CGraphAPIAppPassword
$keyVault = $parameters.keyVaultName
$registeredAzureADApp = $parameters.customerIdentifier+'-'+$parameters.environment
$storageAccount = $parameters.storageAccountName

#Below keys are 'Functions Keys' of 'Nof1-SharedFunctions - NOF1_AF_B2C_GRAPH_UPDATEUSER_DISPLAYNAME' and 'Nof1-SharedFunctions - NOF1_AF_B2C_GRAPH_UPDATEUSER_LOGINEMAIL' Function Apps which is created under 'Nof1-SharedFunctions' Function App service on Azure.
#We use these same function apps in all environment through Azure B2C GraphAPI to update user account display name and email ID
$B2CGraphApiKey = "B2C-Graph-API"
$B2CGraphApiValue = '{\"B2CTenant\": \"'+$($b2cTenant)+'\", \"B2CClientSecretID\": \"'+$($azureADB2CGraphAPIAppPassword)+'\", \"B2CClientID\": \"'+$($azureADB2CGraphAPIAppId)+'\"}'
$keyList = @{
    "Nof1SharedFunction-B2CGraphAPI-DisplayName-FunctionKey" = "UnzA17M6YTKNR6LQGI1Zq0tAPAvAAR7/6FavXx2eJXAhUijQzzquPQ=="
    "Nof1SharedFunction-B2CGraphAPI-LoginEmail-FunctionKey" = "JxcNSVIe2VyGtrj7fjeqadfnsSd72yKccDhDZKJxbHdNeopj6tWBsA=="
}
$keyList.Add( $B2CGraphApiKey,$B2CGraphApiValue)

$login = az login --tenant $ADTenant --allow-no-subscription | ConvertFrom-Json
[Console]::ResetColor()

foreach($key in $keyList.Keys)
{
    # Check if the secret already exists.
    $existingKey = (az keyvault secret show --name $key --vault-name $keyVault) | ConvertFrom-Json
    [Console]::ResetColor()    
    if ($existingKey -eq $null) {
        $keyvalue = $keyList[$key]

        # Adding Keys to Keyvault
        $command = "az keyvault secret set --% --name ""$key"" --vault-name ""$keyVault"" --value ""$keyvalue"" "
        $commandResult = (Invoke-Expression $command) | ConvertFrom-Json
        Write-Host "Imported secret $key."
    }
    else {
        Write-Host "Secret $key already exists and has not been changed."
    }
}

$partitionKeys = @("Nof1:Integration:SharedFunction", "Nof1:AzureAd")
$rowKeys = @("SharedFunctionBaseUrl", "ApplicationName")
$settingValues = @("https://nof1-sharedfunctions.azurewebsites.net/api", $registeredAzureADApp)

$count=0
foreach($key in $partitionKeys)
{
    # Check if the key already exists in Configuration table.
    $existingKey = (az storage entity show --partition-key $key --row-key $rowKeys[$count] --table-name configuration --account-name $storageAccount --subscription $subscription) | ConvertFrom-Json
    [Console]::ResetColor()    
    if ($existingKey -eq $null) {
        $rowKey = $rowKeys[$count]
        $settingValue = $settingValues[$count]

        # Adding Keys to Configuration table
        $command = "az storage entity insert --% -e PartitionKey=""$key"" RowKey=""$rowKey"" SettingValue=""$settingValue"" --table-name ""configuration"" --account-name ""$storageAccount"" --subscription ""$subscription"" "
        $commandResult = (Invoke-Expression $command) | ConvertFrom-Json
        Write-Host "Imported key $key in configuration table."
    }
    else {
        Write-Host "key $key already exists and has not been changed."
    }
$count = $count+1
}
