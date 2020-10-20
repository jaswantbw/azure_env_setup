# This script sets up Key Vault access for an Azure Active Directory application.

Param(
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

$sqlAdministratorUsername = "$($parameters.customerIdentifier)-sql-$($parameters.environment)"
$sqlAdministratorPassword = (([System.Web.Security.Membership]::GeneratePassword(40,0)) -replace "[^a-zA-Z0-9]", "").Substring(0,20)


# Save any deployment outputs to the parameters file.
$templateParameters = (Get-Content $TemplateParameterFile) | ConvertFrom-Json
$templateParameters.parameters | Add-Member -Force sqlAdministratorUsername @{ value = $sqlAdministratorUsername }
$templateParameters.parameters | Add-Member -Force sqlAdministratorPassword @{ value = $sqlAdministratorPassword }

# Format the JSON file using JSON.NET, because the PowerShell formatting sucks.
[Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
$jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($templateParameters | ConvertTo-Json | Out-String))
$formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
$formattedJson | Out-File $TemplateParameterFile

Write-Host "SQL Server parameters have been added to the parameters file."


# Deploy the database.
.\Deploy-Nof1-Resource-Template.ps1 -TemplateFile .\database-template.json -TemplateParameterFile $TemplateParameterFile
