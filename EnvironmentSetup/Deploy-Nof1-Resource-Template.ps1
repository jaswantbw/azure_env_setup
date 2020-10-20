# This script deploys an ARM template into an existing Nof1 v2.x environment.

# Before running this script in a PowerShell prompt:
# 1. Run Login-AzureRmAccount
# 2. Set the subscription by running Set-AzureRmContext -SubscriptionName "{{ SUBSCRIPTION NAME }}"

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateFile,
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

# Create hash tables for the full set of parameters, and the parameters for this deployment.
$parameters = @{}
$deploymentParameters = @{}

# Populate the parameters hash table with values from the parameter file(s).

# For the deployment parameters, only include the specific parameters from the template.
# The New-AzureRmResourceGroupDeployment command will throw an error if there are extra parameters.
# Which is really stupid. But here we are.
$parameterFile = (Get-Content $TemplateParameterFile) -join "`n" | ConvertFrom-Json
$parameterObject = $parameterFile.parameters
$templateParameters = ((Get-Content $TemplateFile) -join "`n" | ConvertFrom-Json).parameters

$parameterObject | Get-Member -MemberType NoteProperty | ForEach-Object {
    $key = [string]$_.Name
    $value = [string]$parameterObject."$key".value

    $parameters[$key] = $value

    if ($key -in $templateParameters.PSObject.Properties.Name) {
        $deploymentParameters[$key] = $value
    }
}

Write-Host "Deployment parameters:"
Write-Host ($deploymentParameters | Out-String)


$resourceGroupName = "$($deploymentParameters.customerIdentifier)-$($deploymentParameters.environment)"
Write-Host "Deploying $TemplateFile to $resourceGroupName..."
$deployment = New-AzureRmResourceGroupDeployment -TemplateFile $TemplateFile -ResourceGroupName $resourceGroupName -TemplateParameterObject $deploymentParameters
Write-Host "Completed deploying $TemplateFile to $resourceGroupName."

# Save any deployment outputs to the parameters file.
$templateParameters = (Get-Content $TemplateParameterFile) | ConvertFrom-Json
if ($deployment.Outputs -ne $null) {
    $deployment.Outputs.Keys | % {
        $key = [string]$_
        $value = [string]$deployment.Outputs[$_].Value

        $templateParameters.parameters | Add-Member -Force $key @{ value = $value }
    }

    # Format the JSON file using JSON.NET, because the PowerShell formatting sucks.
    [Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
    $jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($templateParameters | ConvertTo-Json | Out-String))
    $formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
    $formattedJson | Out-File $TemplateParameterFile

    Write-Host "Deployment outputs have been added to the parameters file."
}
