Param (
    [string][Parameter(Mandatory=$True)]$subscriptionName,
    [string][Parameter(Mandatory=$True)]$resourceGroupName,
    [string][Parameter(Mandatory=$True)]$storageAccount,
    [string][Parameter(Mandatory=$True)]$tableName,
    [string][Parameter(Mandatory=$True)]$location,
    [string]$azureRmProfilePath
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

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccount -ErrorAction Stop).Context

$table = Get-AzureStorageTable -Name $tableName -Context $saContext

#Create a table query.
$query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery

#Define columns to select.
$list = New-Object System.Collections.Generic.List[string]
$list.Add("PartitionKey")
$list.Add("RowKey")
$list.Add("Timestamp")
$list.Add("SettingValue")

#Set query details.
$query.SelectColumns = $list
$query.TakeCount = 400

#Execute the query.
$entities = $table.CloudTable.ExecuteQuery($query)


$rows = New-Object System.Collections.Generic.List[object]
foreach ($entity in $entities) {
    $row = Select-Object -InputObject $entity PartitionKey,RowKey,@{Name="SettingValue";Expression={$_.Properties["SettingValue"].StringValue}}
    $rows.Add($row)
}

@{ rows = $rows } | ConvertTo-Json | % { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File -FilePath ".\$storageAccount.$tableName.json"
