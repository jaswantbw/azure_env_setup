# Setup script for N of 1 v1.8

# Before running this script in a PowerShell prompt:
# 1. Run Login-AzureRmAccount
# 2. Set the subscription by running Set-AzureRmContext -SubscriptionName "{{ SUBSCRIPTION NAME }}"

Param(
  [string] [Parameter(Mandatory=$true)] $ResourceGroupLocation,
  [string] [Parameter(Mandatory=$true)] $TemplateFile,
  [string] [Parameter(Mandatory=$true)] $TemplateParametersFile
)

$ErrorActionPreference = "Stop"

# Set the current directory to avoid a problem: PowerShell throws an error when starting jobs 
# when the current directory is a network share.
# This assumes $PSScriptRoot is not a network share.
[environment]::CurrentDirectory = $PSScriptRoot

$params = (Get-Content $TemplateParametersFile) -join "`n" | ConvertFrom-Json
$customerIdentifier = $params.parameters.customerIdentifier.value
$environment = $params.parameters.environment.value
$environmentResourceGroupName = "$customerIdentifier-$environment"


# Deploy the environment-specific resources.
Write-Host "Beginning deployment of environment resources..."

$environmentResourceGroup = Find-AzureRmResourceGroup | Where-Object {$_.Name -eq $environmentResourceGroupName}
if ($environmentResourceGroup) {
    $environmentResourceGroup = Get-AzureRmResourceGroup -Name $environmentResourceGroupName
    Write-Host "Using existing resource group '$($environmentResourceGroup.ResourceGroupName)'."
}
else {
    Write-Host "Creating resource group '$environmentResourceGroupName'..."
    $environmentResourceGroup = New-AzureRmResourceGroup -Name $environmentResourceGroupName -Location $ResourceGroupLocation
    Write-Host "Resource group '$($environmentResourceGroup.ResourceGroupName)' created successfully."
}

# Perform the deployment.
Write-Host "Beginning deployment of resource group '$($environmentResourceGroup.ResourceGroupName)'..."

$environmentDeployment = New-AzureRmResourceGroupDeployment -Name "$($environmentResourceGroup.ResourceGroupName)" `
    -ResourceGroupName $environmentResourceGroup.ResourceGroupName `
    -TemplateFile $TemplateFile `
    -TemplateParameterFile $TemplateParametersFile `
    -Mode Incremental

Write-Host "Completed deployment of resource group '$($environmentResourceGroup.ResourceGroupName)'."

#Exit # DEBUG


# Deploy the shared resources.
Write-Host "Beginning deployment of shared resources..."
$sharedTemplateFile = ($TemplateFile -Replace "-environment.json$", "-shared.json")
$sharedResourceGroupName = ($environmentResourceGroupName -Replace "-$environment$", "-shared")

$sharedResourceGroup = Find-AzureRmResourceGroup | Where-Object {$_.Name -eq $sharedResourceGroupName}
if ($sharedResourceGroup) {
    $sharedResourceGroup = Get-AzureRmResourceGroup -Name $sharedResourceGroupName
    Write-Host "Using existing shared resource group '$($sharedResourceGroup.ResourceGroupName)'."
}
else {
    Write-Host "Creating resource group '$sharedResourceGroupName'..."
    $sharedResourceGroup = New-AzureRmResourceGroup -Name $sharedResourceGroupName -Location $ResourceGroupLocation
    Write-Host "Resource group '$($sharedResourceGroup.ResourceGroupName)' created successfully."
}

$sharedDeployment = New-AzureRmResourceGroupDeployment -Name "$($sharedResourceGroup.ResourceGroupName)" `
    -ResourceGroupName $sharedResourceGroup.ResourceGroupName `
    -TemplateFile $sharedTemplateFile `
    -TemplateParameterFile $TemplateParametersFile `
    -Mode Incremental
$sharedServerName = $sharedDeployment.Outputs.sqlServerName.value

$adminParameter = $params.parameters.sqlServerActiveDirectoryAdmin.value
$admin = Get-AzureRmSqlServerActiveDirectoryAdministrator –ResourceGroupName $sharedResourceGroupName –ServerName $sharedServerName
if ($admin.DisplayName -eq $adminParameter) 
{ 
    Write-Host "SQL Administrator already set." 
} 
else 
{ 
    Write-Host "Setting SQL Administrator..."
    Set-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName $sharedResourceGroupName -ServerName $sharedServerName -DisplayName $adminParameter
}

$ErrorActionPreference = "Continue"

# Create database login for Nof1.
& .\CreateSqlDbOwnerLogin.ps1 -serverName $sharedDeployment.Outputs.sqlServerName.value `
    -adminUsername $params.parameters.sqlServerName.value -adminPassword $params.parameters.sqlServerAdminPassword.value `
    -database $sharedDeployment.Outputs.sqlDatabaseNameNof1.value `
    -databasePassword $params.parameters.databasePasswordNof1.value

# Create database login for DNN.
& .\CreateSqlDbOwnerLogin.ps1 -serverName $sharedDeployment.Outputs.sqlServerName.value `
    -adminUsername $params.parameters.sqlServerName.value -adminPassword $params.parameters.sqlServerAdminPassword.value `
    -database $sharedDeployment.Outputs.sqlDatabaseNameDnn.value `
    -databasePassword $params.parameters.databasePasswordDnn.value

# Create database login for the warehouse.
& .\CreateSqlDbOwnerLogin.ps1 -serverName $sharedDeployment.Outputs.sqlServerName.value `
    -adminUsername $params.parameters.sqlServerName.value -adminPassword $params.parameters.sqlServerAdminPassword.value `
    -database $sharedDeployment.Outputs.sqlDatabaseNameDataWarehouse.value `
    -databasePassword $params.parameters.databasePasswordDataWarehouse.value

$ErrorActionPreference = "Stop"




# Deploy the DocumentDB resources.
#Write-Host "Beginning deployment of DocumentDB resources..."
#$docDbTemplateFile = ($TemplateFile -Replace "-environment.json$", "-documentdb.json")
#if (!$DocumentDbResourceGroupName) {
#    $DocumentDbResourceGroupName = ($environmentResourceGroupName -Replace "-$environment$", "-shared")
#}
#$docDbDeployment = &$deploy $docDbTemplateFile $DocumentDbResourceGroupName

# Set up the DocumentDB database & collection.
# (No direct PowerShell/ARM Template way to do this as of 2015-11-24.)
#$documentDbAccountName = $docDbDeployment.Outputs.documentDbAccountName.value
#$documentDbMasterKey = $docDbDeployment.Outputs.documentDbMasterKey.value
#&$setupDocumentDb $documentDbAccountName $documentDbMasterKey
#>



## CUSTOM SCRIPTS

$StorageAccountName = $environmentDeployment.Outputs.storageAccountName.value
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $environmentResourceGroupName -StorageAccountName $StorageAccountName).Value[0]
$portalVmName = $environmentDeployment.Outputs.portalVmName.value

## CUSTOM SCRIPTS: INSTALL SSH

<#
..\Tools\AzCopy.exe ".\CustomScripts\ssh-install\files" "https://$StorageAccountName.file.core.windows.net/ssh-install" /DestKey:$storageAccountKey /s /y /xo

..\Tools\AzCopy.exe ".\CustomScripts\ssh-install" "https://$StorageAccountName.blob.core.windows.net/custom-scripts" "CustomScript-ssh-install.ps1" /DestKey:$storageAccountKey /y

Set-AzureRmVMCustomScriptExtension -Name CustomScript-ssh-install -ResourceGroupName $environmentResourceGroupName -VMName $portalVmName -Location $ResourceGroupLocation -ContainerName "custom-scripts" -FileName "CustomScript-ssh-install.ps1" -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -Argument "-StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey"

Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $environmentResourceGroupName -VMName $portalVmName -Name "CustomScript-ssh-install" -Force 
#>


## CUSTOM SCRIPTS: SERVER CONFIGURATION

<#
..\Tools\AzCopy.exe ".\CustomScripts\portal-vm-role-setup\files" "https://$StorageAccountName.file.core.windows.net/portal-vm-role-setup" /DestKey:$storageAccountKey /s /y /xo

..\Tools\AzCopy.exe ".\CustomScripts\portal-vm-role-setup" "https://$StorageAccountName.blob.core.windows.net/custom-scripts" "CustomScript-portal-vm-role-setup.ps1" /DestKey:$storageAccountKey /y

Set-AzureRmVMCustomScriptExtension -Name CustomScript-portal-vm-role-setup -ResourceGroupName $environmentResourceGroupName -VMName $portalVmName -Location $ResourceGroupLocation -ContainerName "custom-scripts" -FileName "CustomScript-portal-vm-role-setup.ps1" -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey  -Argument "-StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey"

Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $environmentResourceGroupName -VMName $portalVmName -Name "CustomScript-portal-vm-role-setup" -Force 
#>
