# This script deploys an ARM template into an existing Nof1 v2.x environment.

# Before running this script in a PowerShell prompt:
# 1. Run Login-AzureRmAccount
# 2. Set the subscription by running Set-AzureRmContext -SubscriptionName "{{ SUBSCRIPTION NAME }}"

Param(
  [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
  [string] [Parameter(Mandatory=$true)] $TemplateFile,
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile
  
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

Write-Host "Deploying $TemplateFile to $resourceGroupName..."
$deployment = New-AzureRmResourceGroupDeployment -Name DataFactoryArmDeployment -TemplateFile $TemplateFile -ResourceGroupName $ResourceGroupName -TemplateParameterFile $TemplateParameterFile
Write-Host "Completed deploying $TemplateFile to $resourceGroupName."

$dataFactoryName = "$($parameters.customerIdentifier)-datafactory-$($parameters.environment)"
Write-Host $dataFactoryName
if($TemplateFile -like '*InternalNotification*'){
Write-Host "Start InternalNotification Timer"
Start-AzureRmDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $dataFactoryName -TriggerName  "InternalNotificationTimer"  -Force
}
elseif($TemplateFile -like '*SignInAuditLog*'){
Start-AzureRmDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $dataFactoryName -TriggerName  "SignInAuditTimer"  -Force
}


