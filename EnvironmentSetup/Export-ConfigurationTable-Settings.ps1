# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $StorageAccountName,
  [string] [Parameter(Mandatory=$true)] $StorageAccountKey
)

$ErrorActionPreference = "Stop"

$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Protocol Https
$configurationTable = Get-AzureStorageTable –Name "Configuration" –Context $context

$configuration = @()

Get-AzureStorageTableRowAll -table $configurationTable | % {
    $configuration +=  [ordered]@{ partitionKey = $_.PartitionKey; rowKey = $_.RowKey; settingValue = $_.SettingValue }
}

# Format the JSON file using JSON.NET, because the PowerShell formatting sucks.
[Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
$jobject = [Newtonsoft.Json.Linq.JArray]::Parse(($configuration | Sort-Object @{e = { $_.partitionKey }}, @{e = { $_.rowKey }} | ConvertTo-Json | Out-String))
$formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
$formattedJson | Out-File ".\configuration-$StorageAccountName.json"
