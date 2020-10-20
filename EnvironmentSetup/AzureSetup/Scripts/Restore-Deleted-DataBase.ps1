# Setup script for N of 1 Disaster Recovery - Deleted Database restoration

# Before running this script in a PowerShell prompt:
# 1. Run Login-AzureRmAccount
# 2. Set the subscription by running Set-AzureRmContext -SubscriptionName "{{ SUBSCRIPTION NAME }}"

Param(
	[string] [Parameter(Mandatory=$true)] $TemplateParametersFile
)

$ErrorActionPreference = "Stop"

# Get Parameters from the parameters file
$params = (Get-Content $TemplateParametersFile) -join "`n" | ConvertFrom-Json
$customerIdentifier = $params.parameters.customerIdentifier.value
$environment = $params.parameters.environment.value
$sqlElasticPoolName = $params.parameters.sqlElasticPoolName.value
$sqlServerName = $params.parameters.sqlServerName.value
$dbName = $params.parameters.deletedDBName.value

# Get Resource Group. 
if (!$ResourceGroupName) {
    $ResourceGroupName = "$customerIdentifier-$environment"
} 
$dbResourceGroupName = ($ResourceGroupName -Replace "-$environment$", "-shared")

$sqlResourceGroup = Find-AzureRmResourceGroup | Where-Object {$_.Name -eq $dbResourceGroupName}
if ($sqlResourceGroup) {
    $sqlResourceGroup = Get-AzureRmResourceGroup -Name $dbResourceGroupName
    Write-Host "Using existing SQL resource group '$($sqlResourceGroup.ResourceGroupName)'."
}
else {
    Write-Host "Resource group '$dbResourceGroupName' doesn't exist!"
}

# Get the SQL Server. 
if ($sqlServerName) {
	Write-Host "Looking for SQL server '$sqlServerName'"
    $SQLServer = Get-AzureRmSqlServer -ServerName $sqlServerName -ResourceGroupName $dbResourceGroupName
    Write-Host "Found SQL Server '$($SQLServer.ServerName)'."
}
else {
    Write-Host "SQL server '$sqlServerName' doesn't exist in the SQL resource group '$dbResourceGroupName'!"
}

# Find deleted database in the SQL Server
Write-Host "Searching for deleted database '$dbName'"
$DeletedDatabase = Get-AzureRmSqlDeletedDatabaseBackup -ResourceGroupName $dbResourceGroupName -ServerName $SQLServer.ServerName -DatabaseName $dbName
Write-Host "Found deleted database '$dbName'"

# Restore the deleted database back into the Elastic Pool
Write-Host "SQL Database '$dbName' is being restored to SQL Server '$sqlServerName'."
Write-Host "Restoration in progress ... this may take a few minutes"
Restore-AzureRmSqlDatabase –FromDeletedDatabaseBackup –DeletionDate $DeletedDatabase.DeletionDate -ResourceGroupName $DeletedDatabase.ResourceGroupName -ServerName $DeletedDatabase.ServerName -TargetDatabaseName $dbName –ResourceId $DeletedDatabase.ResourceID –ElasticPoolName $sqlElasticPoolName