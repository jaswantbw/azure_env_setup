# This script will create the Resource Group for an N of 1 v2.x deployment.
# This script should typically be executed as the very first step in a deployment.

# Before running this script in a PowerShell prompt:
# 1. Run Login-AzureRmAccount
# 2. Set the subscription by running Set-AzureRmContext -SubscriptionName "{{ SUBSCRIPTION NAME }}"

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile
)

$ErrorActionPreference = "Stop"

# Check for the correct AzureRM version.
if ((Get-Module AzureRM).Version -ne "6.9.0") {
    Write-Host "Importing AzureRM module version 6.9.0..."

    # Remove the AzureRM module if it's loaded.
    if ((Get-Module AzureRM) -ne $null) {
        Remove-Module AzureRM
    }

    Import-Module AzureRM -RequiredVersion 6.9.0
    Write-Host "AzureRM module version 6.9.0 imported successfully."
}


# Set the current directory to avoid a problem: PowerShell throws an error when starting jobs 
# when the current directory is a network share.
# This assumes $PSScriptRoot is not a network share.
[environment]::CurrentDirectory = $PSScriptRoot

$templateParameters = (Get-Content $TemplateParameterFile ) -join "`n" | ConvertFrom-Json
$customerIdentifier = $templateParameters.parameters.customerIdentifier.value
$environment = $templateParameters.parameters.environment.value
$resourceGroupName = "$customerIdentifier-$environment"
$sharedResourceGroupName = "$customerIdentifier-shared"

# Set the default location. If there's a location in the parameter file, use that instead.
$location = "eastus2"
if ($templateParameters.parameters.location.value) {
    Write-Host "Location: $($templateParameters.parameters.location.value)"
}


Write-Host "Checking resource group '$resourceGroupName'..."
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue -ErrorVariable notPresent
if ($notPresent) {
    Write-Host "Creating resource group '$resourceGroupName'..."
    $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
    Write-Host "Resource group '$($resourceGroupName)' created successfully in '$($location)'."
}
else {
    Write-Host "The resource group '$($resourceGroupName)' already exists."
}
