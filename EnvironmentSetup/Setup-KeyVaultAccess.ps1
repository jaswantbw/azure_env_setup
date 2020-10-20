# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile,
  [string] [Parameter(Mandatory=$true)] $KeyVaultSubscription,
  [switch] $ReplaceExisting
)

$ErrorActionPreference = "Stop"

Function CreateApp($applicationName) {

    # Create a self-signed certificate. Associate it with the app.

    # First, create and export a self-signed certificate.
    $password = [System.Web.Security.Membership]::GeneratePassword(20,5)
    Write-Host "Creating new self-signed certificate."

    $pfxFilePath = ".\$applicationName.pfx"

    $certificatePassword = ConvertTo-SecureString -String $password -Force -AsPlainText 
    $certificate = New-SelfSignedCertificate -DnsName $applicationName -CertStoreLocation "cert:\CurrentUser\My" `
        -NotBefore (Get-Date).ToUniversalTime().Date.AddDays(-1) `
        -NotAfter (Get-Date).ToUniversalTime().Date.AddYears(100) `
        -KeySpec Signature
    $pfxFileInfo = Export-PfxCertificate -cert $certificate -FilePath ".\$applicationName.pfx" -Password $certificatePassword
    $cerFileInfo = Export-Certificate -cert $certificate -FilePath ".\$applicationName.cer"

    # Get the contents of the self-signed certificate.
    $x509 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $x509.Import((Get-ChildItem ".\$applicationName.cer").FullName)
    $certificateValue = [System.Convert]::ToBase64String($x509.GetRawCertData())

    az ad app create --display-name "$applicationName" --identifier-uris "$applicationName" --key-type AsymmetricX509Cert --key-value $certificateValue `
        | ConvertFrom-Json | % { $application = $_ }

    Write-Host "Created application '$applicationName'."

    Write-Host "The certificate password is: "
    Write-Host $password -ForegroundColor Red
    Write-Host

    Write-Host "The certificate thumbprint is: "
    Write-Host $x509.Thumbprint -ForegroundColor Green
    Write-Host

    # Store the password and thumbprint in the parameters file.
    $pfxFileBytes = Get-Content $pfxFilePath -Encoding Byte
    $pfxFileContent = [System.Convert]::ToBase64String($pfxFileBytes)

    $parameters = (Get-Content $TemplateParameterFile) | ConvertFrom-Json
    $parameters.parameters | Add-Member -Force selfSignedCertificatePassword @{ value = $password }
    $parameters.parameters | Add-Member -Force selfSignedCertificateThumbprint @{ value = $x509.Thumbprint }
    $parameters.parameters | Add-Member -Force selfSignedCertificateBase64String @{ value = $pfxFileContent }

    # Format the JSON file using JSON.NET, because the PowerShell formatting sucks.
    [Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
    $jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($parameters | ConvertTo-Json | Out-String))
    $formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
    $formattedJson | Out-File $TemplateParameterFile
}

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

$applicationName = "$($parameters.customerIdentifier)-$($parameters.environment)"

# Check if the user is logged in to the specified tenant.
$loginInfo = az account show | ConvertFrom-Json
$loggedInTenantId = $loginInfo.tenantId

if ($loggedInTenantId -ne $parameters.activeDirectoryTenantId) {
    # Log in twice -- first to the default directory to get access to the subscription containing the KeyVault, then to the directory that the KeyVault authenticates against.
    az login
    az login --tenant $parameters.activeDirectoryTenantId --allow-no-subscriptions
}


# Create the KeyVault Administrators group.
$group = (az ad group list | ConvertFrom-Json) | Where { $_.displayName -eq "KeyVault Administrators" }
if ($null -eq $group) {
    Write-Host "Creating group 'KeyVault Administrators'."
    az ad group create --display-name "KeyVault Administrators" --mail-nickname "keyvault.administrators" | ConvertFrom-Json | % { $group = $_ }
}

$keyvaultAdministratorsGroupId = $group.objectId

# Add the current user to the "KeyVault Administrators" group.
az account show | ConvertFrom-Json | % { $username = $_.user.name }
$user = (az ad user list | ConvertFrom-Json) | Where { $_.givenName -eq $username }
az ad group member check --group "KeyVault Administrators" --member-id $user.objectId | ConvertFrom-Json | % { $isInGroup = $_.value }
if ($isInGroup -eq $false) {
    Write-Host "Adding the current user to the 'KeyVault Administrators' group, so they can perform the deployment."
    az ad group member add --group "KeyVault Administrators" --member-id $user.objectId | ConvertFrom-Json | % { $groupAddResult = $_ }
}
else {
    Write-Host "The current user is in the 'KeyVault Administrators' group."
}
Write-Host "Consider removing this access after deployment." -ForegroundColor Red

$keyVaultName = "$($parameters.customerIdentifier)-keyvault-$($parameters.environment)"
az keyvault set-policy --name "$keyVaultName" --subscription "$KeyVaultSubscription" `
    --object-id "$keyvaultAdministratorsGroupId" `
    --certificate-permissions backup create delete deleteissuers get getissuers import list listissuers managecontacts manageissuers purge recover restore setissuers update `
    --key-permissions backup create decrypt delete encrypt get import list purge recover restore sign unwrapKey update verify wrapKey `
    --secret-permissions backup delete get list purge recover restore set `
    | ConvertFrom-Json | % { $setPolicyResult = $_ }


# Create the KeyVault Readers group.
$group = (az ad group list | ConvertFrom-Json) | Where { $_.displayName -eq "KeyVault Readers" }
if ($null -eq $group) {
    Write-Host "Creating group 'KeyVault Readers'."
    az ad group create --display-name "KeyVault Readers" --mail-nickname "keyvault.readers" | ConvertFrom-Json | % { $group = $_ }
}

$keyvaultReadersGroupId = $group.objectId
az keyvault set-policy --name "$keyVaultName" --subscription "$KeyVaultSubscription" `
    --object-id "$keyvaultReadersGroupId" `
    --certificate-permissions get list `
    --key-permissions decrypt encrypt get list sign unwrapKey verify `
    --secret-permissions get list `
    | ConvertFrom-Json | % { $setPolicyResult = $_ }


# Create the application if it doesn't exist.
$apps = (az ad app list --display-name $applicationName | ConvertFrom-Json)
$app = $apps[0]
if ($app -eq $null) {
    CreateApp($applicationName)
}
else {
    Write-Host "The application '$applicationName' already exists."
    if ($ReplaceExisting -eq $true) {
        Write-Host "Deleting and re-creating application '$applicationName'..."
        az ad app delete --id $app.objectId
        CreateApp($applicationName)
    }
}


# Re-get the application ID, now that we now it exists.
az ad app list --display-name $applicationName | ConvertFrom-Json | % { $app = $_ }

# Create a service principal from the application, if it doesn't exist.
$servicePrincipals = (az ad sp list --display-name $applicationName | ConvertFrom-Json)
$servicePrincipal = $servicePrincipals[0]
if ($servicePrincipal -eq $null) {
    Write-Host "Creating service principal"
    az ad sp create --id $app.objectId | ConvertFrom-Json | % { $servicePrincipal = $_ }
}
else {
    Write-Host "The service principal '$applicationName' already exists."
    if ($ReplaceExisting -eq $true) {
        Write-Host "Deleting and re-creating service principal '$applicationName'..."
        az ad sp delete --id $servicePrincipal.objectId
        az ad sp create --id $app.objectId | ConvertFrom-Json | % { $servicePrincipal = $_ }
    }
}

# Add the service principal to the "KeyVault Readers" group.
az ad group member add --group "KeyVault Readers" --member-id $servicePrincipal.objectId | ConvertFrom-Json | % { $groupAddResult = $_ }


# Save the Solr instance details to the parameters file.
$templateParameters = (Get-Content $TemplateParameterFile) | ConvertFrom-Json
$templateParameters.parameters | Add-Member -Force activeDirectoryApplicationId @{ value = $servicePrincipal.appId }

# Format the JSON file using JSON.NET, because the PowerShell formatting sucks.
[Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
$jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($templateParameters | ConvertTo-Json | Out-String))
$formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
$formattedJson | Out-File $TemplateParameterFile

Write-Host "Active Directory application parameters have been added to the parameters file."
