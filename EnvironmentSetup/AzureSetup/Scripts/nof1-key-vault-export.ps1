Param (
    [string][Parameter(Mandatory=$True)]$subscriptionName,
    [string][Parameter(Mandatory=$True)]$resourceGroupName,
    [string][Parameter(Mandatory=$True)]$keyVaultName,
    [string][Parameter(Mandatory=$True)]$location,
    [string][Parameter(Mandatory=$False)]$azureRmProfilePath
)

$ErrorActionPreference = "Stop"

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
    throw "KeyVault $keyVaultName does not exist."
}

$exportedSecrets = New-Object System.Collections.ArrayList
$secrets = Get-AzureKeyVaultSecret -VaultName $keyVaultName
foreach ($secret in $secrets) {
    $s = Get-AzureKeyVaultSecret -VaultName $secret.VaultName -Name $secret.Name
    $exportedSecret = Select-Object -InputObject $s @{Name="Name";Expression={$_."Name"}}, @{Name="Value";Expression={$_."SecretValueText"}}
    $_ = $exportedSecrets.Add($exportedSecret)
}

@{ secrets = $exportedSecrets } | ConvertTo-Json | Out-File -FilePath ".\$keyVaultName.json"
