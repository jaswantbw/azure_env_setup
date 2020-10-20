Param (
    [string][Parameter(Mandatory=$True)]$subscriptionName,
    [string][Parameter(Mandatory=$True)]$resourceGroupName,
    [string][Parameter(Mandatory=$True)]$storageAccount,
    [string][Parameter(Mandatory=$True)]$blobContainerName,
    [string][Parameter(Mandatory=$True)]$location,
    [string][Parameter(Mandatory=$True)]$folderToUpload,
    [string]$azureRmProfilePath,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $folderToUpload))
{
    throw "Folder $folderToUpload does not exist."
}

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

$container = Get-AzureStorageContainer -Name $blobContainerName -Context $saContext -ErrorAction Ignore

if (-not ($container))
{
    $container = New-AzureStorageContainer -Name $blobContainerName -Context $saContext
}

$container.CloudBlobContainer.Uri.AbsoluteUri

$filesToUpload = Get-ChildItem $folderToUpload -Recurse -File

foreach ($file in $filesToUpload) {
    $targetPath = ($file.fullname.Substring($folderToUpload.Length + 1)).Replace("\", "/")

    Write-Verbose "Uploading $("\" + $file.fullname.Substring($folderToUpload.Length + 1)) to $($container.CloudBlobContainer.Uri.AbsoluteUri + "/" + $targetPath)"
    Set-AzureStorageBlobContent -File $file.fullname -Container $container.Name -Blob $targetPath -Context $saContext -Force:$Force | Out-Null
}

