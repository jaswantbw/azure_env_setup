# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile,
  [string] $SnapshotResourceGroupName = "nof1-portal-snapshots",
  [string] $SnapshotName = "nof1-portal-initial-snapshot",
  [string] $SnapshotSubscriptionName = "N of 1 - Development"
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

$targetResourceGroupName = "$($parameters["customerIdentifier"])-$($parameters["environment"])"

$location = $parameters["location"]
if ([string]::IsNullOrWhiteSpace($location)) {
    $location = "eastus2"
}


# Check if the snapshot already exists.
$targetSnapshot = Get-AzureRmSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $SnapshotName -ErrorAction SilentlyContinue

if ($targetSnapshot -eq $null) {
    # Copy the snapshot from the snapshot subscription to the current subscription.

    # Get the current subscription so we can switch back to it later.
    $startingContext = Get-AzureRmContext


    # Switch to the subscription that the snapshot is stored in, to get a reference to the snapshot.
    Write-Host "Getting a reference to the snapshot '$SnapshotName'..."
    $context = Set-AzureRmContext -SubscriptionName $SnapshotSubscriptionName
    $snapshot = Get-AzureRmSnapshot -ResourceGroupName $SnapshotResourceGroupName -SnapshotName $SnapshotName


    # Switch back to the original subscription and copy the snapshot.
    Write-Host "Copying the snapshot '$SnapshotName' to '$targetResourceGroupName'..."
    $context = Set-AzureRmContext -SubscriptionName $startingContext.Subscription.Name
    $targetSnapshotConfig = New-AzureRmSnapshotConfig -OsType Windows -Location $location -CreateOption Copy -SourceResourceId $snapshot.Id
    $targetSnapshot = New-AzureRmSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $SnapshotName -Snapshot $targetSnapshotConfig    
}

# Create an image from the snapshot.
$imageName = $SnapshotName -replace "snapshot", "image"
$image = Get-AzureRmImage -ResourceGroupName $targetResourceGroupName -ImageName $imageName -ErrorAction SilentlyContinue

if ($image -eq $null) {
    Write-Host "Creating an image from the snapshot '$SnapshotName'..."
    $imageConfig = New-AzureRmImageConfig -Location $location
    Set-AzureRmImageOsDisk -Image $imageConfig -OsType Windows -OsState Generalized -SnapshotId $targetSnapshot.Id
    New-AzureRmImage -ResourceGroupName $targetResourceGroupName -ImageName $imageName -Image $imageConfig

    $image = Get-AzureRmImage -ResourceGroupName $targetResourceGroupName -ImageName $imageName
}


# Create strong credentials for the portal VM administrator account and save them to the parameters file.
$portalVirtualMachineAdminUsername = "$($parameters.customerIdentifier)-portal-$($parameters.environment)"
$portalVirtualMachineAdminPassword = (([System.Web.Security.Membership]::GeneratePassword(40,0)) -replace "[^a-zA-Z0-9]", "").Substring(0,20)

$templateParameters = (Get-Content $TemplateParameterFile) | ConvertFrom-Json
$templateParameters.parameters | Add-Member -Force portalVirtualMachineAdminUsername @{ value = $portalVirtualMachineAdminUsername }
$templateParameters.parameters | Add-Member -Force portalVirtualMachineAdminPassword @{ value = $portalVirtualMachineAdminPassword }

# Format the JSON file using JSON.NET, because the PowerShell formatting sucks.
[Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
$jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($templateParameters | ConvertTo-Json | Out-String))
$formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
$formattedJson | Out-File $TemplateParameterFile

Write-Host "Portal VM Admin credentials have been added to the parameters file."


Write-Host "Creating the virtual network..."
.\Deploy-Nof1-Resource-Template.ps1 -TemplateFile .\virtual-network-template.json -TemplateParameterFile $TemplateParameterFile

Write-Host "Creating the virtual machine..."
.\Deploy-Nof1-Resource-Template.ps1 -TemplateFile .\portal-vm-image-template.json -TemplateParameterFile $TemplateParameterFile

Write-Host "The virtual machine has been created."
