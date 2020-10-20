Param (
    [string][Parameter(Mandatory=$True)]$subscriptionName,
    [string][Parameter(Mandatory=$True)]$resourceGroupName,
    [string][Parameter(Mandatory=$True)]$keyVaultName,
    [string][Parameter(Mandatory=$True)]$location,
    [string][Parameter(Mandatory=$True)]$keyVaultJSONFileName,
    [string][Parameter(Mandatory=$False)]$azureRmProfilePath,
    [switch]$WhatIf = $false
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $keyVaultJSONFileName))
{
    throw "KeyVault JSON file $keyVaultJSONFileName does not exist."
}

$jsonDoc = Get-Content -Raw -Path $keyVaultJSONFileName | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($azureRmProfilePath)) {
    Login-AzureRmAccount
    Write-Host "FYI: to avoid logging in, you can save your Azure credentials and use them when running this script."
    Write-Host "To save your current credentials, run this command from a PowerShell session where you have logged in (like this session):"
    Write-Host "Save-AzureRmProfile -Path ""{ CHOOSE PATH }"""
    Write-Host "Then, the next time you call this script, pass in the path as the -azureRmProfilePath parameter:"
    Write-Host ".\Publish.ps1 -azureRmProfilePath ""{ PROFILE FILE }"" ..."
}
else {
    Select-AzureRmProfile $azureRmProfilePath
}

Select-AzureRmSubscription -SubscriptionName $subscriptionName

$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName

$keyVaultObj = Get-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $keyVaultName -ErrorAction Ignore
if ($keyVaultObj -eq $null)  
{ 
    Write-Host "KeyVault $keyVaultName does not exist. Creating..."   
    
    $keyVaultProviderNamespace = "Microsoft.KeyVault"
    $keyVaultProvider = Get-AzureRmResourceProvider -ProviderNamespace $keyVaultProviderNamespace
    if ($keyVaultProvider.RegistrationState -eq "NotRegistered")
    {
        Write-Host "KeyVault provider is not registered. Registering..."
        Register-AzureRmResourceProvider -ProviderNamespace $keyVaultProviderNamespace
    }
    
    New-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $keyVaultName -Location "eastus"
    $keyVaultObj = Get-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $keyVaultName
    Write-Host "Successfully created KeyVault $keyVaultName..."
}

$jsonDoc.secrets | 
    ForEach { 
        $secretName = $_ | Select -ExpandProperty Name
        $secretValue = $_ | Select -ExpandProperty Value
        $secureString = ConvertTo-SecureString $secretValue -AsPlainText -Force

        Write-Host "Setting key vault '$($keyVaultObj.VaultName)' secret '$secretName' to '$secretValue'."
        if ($WhatIf) {
            Write-Host "(WhatIf is True, skipping deployment)"
        }
        else {
            Set-AzureKeyVaultSecret -VaultName $keyVaultObj.VaultName -Name $secretName -SecretValue $secureString
        }
    }
