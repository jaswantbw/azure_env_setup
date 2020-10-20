# This script will import .pfx certificate to Azure Functions and update application settings to include certificate thumprint
Param(
  [string] [Parameter(Mandatory=$true)] $templateParameterFile,
  [string] [Parameter(Mandatory=$true)] $certificateFilePath
)

$ErrorActionPreference = "Stop"

# Create a hash table for the parameters.
$parameters = @{}

# Populate the parameters hash table with values from the parameter file(s).
$parameterFile = (Get-Content $templateParameterFile) -join "`n" | ConvertFrom-Json
$parameterObject = $parameterFile.parameters

$parameterObject | Get-Member -MemberType NoteProperty | ForEach-Object {
    $key = [string]$_.Name
    $value = [string]$parameterObject."$key".value
    $parameters[$key] = $value
}

$certificateName = $parameters.customerIdentifier+'-'+$parameters.environment
$CertificateThumbprint = $parameters.selfSignedCertificateThumbprint
$CertificatePassword = ConvertTo-SecureString $($parameters.selfSignedCertificatePassword) -AsPlainText -Force
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertificatePassword)
$ClearTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$azureFunctionSubscription = "DIFZ - N of 1 Services"
$resourceGroup = "Nof1-SharedFunctions"
$azureFunction = "Nof1-SharedFunctions"
$applicationSettingName = "WEBSITE_LOAD_CERTIFICATES"

$login = az login | ConvertFrom-Json
[Console]::ResetColor()

#Get list of all Certificates uploaded on AzureFunction 
$certificateList = az functionapp config ssl list --resource-group $resourceGroup --subscription $azureFunctionSubscription | ConvertFrom-Json
$checkCertificateName = $null
$certificateList | % { if($_.thumbprint -eq $CertificateThumbprint){$checkCertificateName = $_.hostnames}}
    
if ($checkCertificateName -eq $certificateName) {

    Write-Host "Certificate $certificateName already uploaded on Azure functions and has not been changed."
}
else {
    
    # Uploading Certificate on Azure Functions
    az functionapp config ssl upload --certificate-file $certificateFilePath --certificate-password $ClearTextPassword --name $azureFunction --resource-group $resourceGroup --subscription $azureFunctionSubscription | ConvertFrom-Json
    Write-Host "Certificate $certificateName sucessfully Uploaded on Azure Functions."
}

#check if WEBSITE_LOAD_CERTIFICATES application setting already contain certificate thumprint

$appSettingList = az functionapp config appsettings list --name $azureFunction --resource-group $resourceGroup --subscription $azureFunctionSubscription | ConvertFrom-Json
$value = $null
$appSettingList | % { if( $_.name -eq $applicationSettingName) {$value = $_.value}}

if($value -like "*$CertificateThumbprint*"){

    Write-Host "Thumprint $CertificateThumbprint already exists in $applicationSettingName application setting and has not been added."
    
    }
else{
    
    $ValueToSet = $value+','+$CertificateThumbprint
   $appSettingList = az functionapp config appsettings set --name $azureFunction --resource-group $resourceGroup --settings "$applicationSettingName=$ValueToSet" --subscription $azureFunctionSubscription | ConvertFrom-Json
   $appSettingList | % { if( $_.name -eq $applicationSettingName) {$value = $_.value}}
    Write-Host "Thumprint is added in $applicationSettingName application setting. New Value of $applicationSettingName is: $value"
    
    }