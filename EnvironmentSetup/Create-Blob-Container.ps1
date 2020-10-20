Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile,
  [string] [Parameter(Mandatory=$true)] $Subscription,
  [string] $ContainerName = 'study-colors-config'
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

$ResourceGroupOfStorageAccount = "$($parameters.customerIdentifier)-$($parameters.environment)"
$StorageAccountName = $parameters.storageAccountName

Connect-AzureRmAccount -Subscription $Subscription

$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupOfStorageAccount -Name $StorageAccountName 

New-AzureStorageContainer -Name $ContainerName -Permission Off -Context $storageAccount.Context

New-Item -Path .\test.txt -ItemType file -Force

Set-AzureStorageBlobContent -File .\test.txt `
-Container $ContainerName `
-Blob 'Backup/test.txt' `
-Context $storageAccount.Context