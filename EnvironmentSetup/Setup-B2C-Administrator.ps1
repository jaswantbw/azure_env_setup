# This script will create administrator account in azure B2C tenant
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

# Create strong credentials for b2c administrator account
$b2cAdministratorUsername = "administrator"
$b2cAdministratorPassword = (([System.Web.Security.Membership]::GeneratePassword(40,0)) -replace "[^a-zA-Z0-9]", "").Substring(0,20)
$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.ForceChangePasswordNextLogin = $False
$passwordProfile.Password = $b2cAdministratorPassword
$userPrincipalName = "$($b2cAdministratorUsername)@$($parameters.b2cTenantName)"

$azureADModule = Get-InstalledModule -Name "Azuread"
if($azureADModule -eq 0)
{
    Write-Host "AzureAD module is not installed. Installing AzureAD Module"
    Install-Module AzureAD -Force
}

Connect-AzureAD -TenantDomain $parameters.b2cTenantName

#create c2c admin account
New-AzureADUser -DisplayName $b2cAdministratorUsername -PasswordProfile $PasswordProfile -UserPrincipalName $userPrincipalName -AccountEnabled $true -PasswordPolicies "DisablePasswordExpiration" -MailNickName $b2cAdministratorUsername

#assign global admin role to b2c admin account

# Fetch user to assign to role
$roleMember = Get-AzureADUser -ObjectId $userPrincipalName

# Fetch User Account Administrator role instance
$role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq 'Company Administrator'}

# Add user to role
Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $roleMember.ObjectId

# Fetch role membership for role to confirm
#Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | Get-AzureADUser

#Save b2c admin account and password to parameter file.
$templateParameters = (Get-Content $TemplateParameterFile) | ConvertFrom-Json
$templateParameters.parameters | Add-Member -Force b2cAdministratorUsername @{ value = $userPrincipalName }
$templateParameters.parameters | Add-Member -Force b2cAdministratorPassword @{ value = $b2cAdministratorPassword }

# Format the JSON file
[Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
$jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($templateParameters | ConvertTo-Json | Out-String))
$formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
$formattedJson | Out-File $TemplateParameterFile