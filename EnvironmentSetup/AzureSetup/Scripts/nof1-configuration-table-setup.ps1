Param (
    [string][Parameter(Mandatory=$True)]$subscriptionName,
    [string][Parameter(Mandatory=$True)]$resourceGroupName,
    [string][Parameter(Mandatory=$True)]$storageAccount,
    [string][Parameter(Mandatory=$True)]$tableName,
    [string][Parameter(Mandatory=$True)]$location,
    [string][Parameter(Mandatory=$True)]$configTableJSONFileName,
    [string]$azureRmProfilePath,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $configTableJSONFileName))
{
    throw "Config table JSON file $configTableJSONFileName does not exist."
}

$jsonDoc = Get-Content -Raw -Path $configTableJSONFileName | ConvertFrom-Json

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

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccount -ErrorAction Stop).Context

$table = Get-AzureStorageTable -Name $tableName -Context $saContext -ErrorAction Ignore
if($table -eq $null)
{
    Write-Host "Table $tableName does not exist. Creating..."
    New-AzureStorageTable –Name $tableName –Context $saContext
    $table = Get-AzureStorageTable -Name $tableName -Context $saContext
    Write-Host "Created table $tableName."
}

#Function Add-Entity: Adds configuration row to the storage table.
function Add-Entity() {
    [CmdletBinding()]
    param(
       $table,
       [String]$partitionKey,
       [String]$rowKey,
       [String]$settingValue
    )

  #$entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $partitionKey, $rowKey
  #$entity.Properties.Add("SettingValue", $settingValue)

  #$result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($entity))

  # New way!!!
  Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey $rowKey -property @{"SettingValue"=$settingValue}
}

$jsonDoc

$jsonDoc.rows | 
    ForEach{ 
        $partitionKey = $_ | Select -ExpandProperty PartitionKey
        $rowKey = $_ | Select -ExpandProperty RowKey
        $settingValue = $_ | Select -ExpandProperty SettingValue
        Add-Entity -Table $table -PartitionKey $partitionKey -RowKey $rowKey -SettingValue $settingValue
        Write-Host "Added setting " $rowKey
    }


