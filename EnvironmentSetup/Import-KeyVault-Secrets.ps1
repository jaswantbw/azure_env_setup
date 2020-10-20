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


$resourceGroupName = "$($parameters.customerIdentifier)-$($parameters.environment)"
$keyVaultName = "$($parameters.customerIdentifier)-keyvault-$($parameters.environment)"

# Log in to the KeyVault tenant.
$loginInfo = az account show | ConvertFrom-Json
$loggedInTenantId = $loginInfo.tenantId

if ($loggedInTenantId -ne $parameters.activeDirectoryTenantId) {
    az login --tenant $parameters.activeDirectoryTenantId --allow-no-subscriptions
}

$secretsTemplate = (Get-Content "./secrets-template.json" | ConvertFrom-Json)

# If the PHI encryption key & vector don't exist, create them and add them to the parameters. Don't persist these values in the parameters JSON.
$phiEncryptionKeySecretName = ($secretsTemplate.PSObject.Properties | Where-Object {$_.Value -eq "{phiEncryptionKey}"}).Name
$phiEncryptionVectorSecretName = ($secretsTemplate.PSObject.Properties | Where-Object {$_.Value -eq "{phiEncryptionVector}"}).Name
$phiEncryptionKeySecret = (az keyvault secret show --name "$phiEncryptionKeySecretName" --vault-name $keyVaultName) | ConvertFrom-Json
[Console]::ResetColor()

if ($phiEncryptionKeySecret -eq $null) {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.GenerateKey()
    $parameters.phiEncryptionKey = [System.Convert]::ToBase64String($aesManaged.Key)
    $aesManaged.GenerateIV()
    $parameters.phiEncryptionVector = [System.Convert]::ToBase64String($aesManaged.IV)
}
else {
    # The PHI encryption key has already been set. Don't overwrite it. Instead, remove the template entries so the secret isn't re-set.
    $secretsTemplate.PSObject.Properties.Remove($phiEncryptionKeySecretName)
    $secretsTemplate.PSObject.Properties.Remove($phiEncryptionVectorSecretName)
}


# If the general encryption key & vector don't exist, create them and add them to the parameters. Don't persist these values in the parameters JSON.
$generalEncryptionKeySecretName = ($secretsTemplate.PSObject.Properties | Where-Object {$_.Value -eq "{generalEncryptionKey}"}).Name
$generalEncryptionVectorSecretName = ($secretsTemplate.PSObject.Properties | Where-Object {$_.Value -eq "{generalEncryptionVector}"}).Name
$generalEncryptionKeySecret = (az keyvault secret show --name "$generalEncryptionKeySecretName" --vault-name $keyVaultName) | ConvertFrom-Json
[Console]::ResetColor()

if ($generalEncryptionKeySecret -eq $null) {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.GenerateKey()
    $parameters.generalEncryptionKey = [System.Convert]::ToBase64String($aesManaged.Key)
    $aesManaged.GenerateIV()
    $parameters.generalEncryptionVector = [System.Convert]::ToBase64String($aesManaged.IV)
}
else {
    # The general encryption key has already been set. Don't overwrite it. Instead, remove the template entries so the secret isn't re-set.
    $secretsTemplate.PSObject.Properties.Remove($generalEncryptionKeySecretName)
    $secretsTemplate.PSObject.Properties.Remove($generalEncryptionVectorSecretName)
}


# Fill the secrets from the template with parameter values.
$secretsTemplate.PSObject.Properties | % {
    $parameterRegexPattern = "{(.*?)}"
    $matches = ([regex]$parameterRegexPattern).Matches($_.Value)

    if ($matches.Count -gt 0) {

        foreach ($match in $matches) {
            $parameterName = [string]$match.Groups[1]
            $parameterValue = $parameters[$parameterName]
            if ($parameterValue -eq $null) {
                Write-Error "Parameter value not found: '$parameterName'"
                exit
            }

            $parameterValue = $_.Value -replace "{$parameterName}", $parameterValue
            $_.Value = $parameterValue
        }

    }
}


$secretsTemplate.PSObject.Properties | % { 

    # Check if the secret already exists.
    $existingSecret = (az keyvault secret show --name "$($_.Name)" --vault-name $keyVaultName) | ConvertFrom-Json
    [Console]::ResetColor()

    if ($existingSecret -eq $null) {
        if ($_.Value -eq "") {
            $secret = (az keyvault secret set --name "$($_.Name)" --vault-name $keyVaultName --value " ") | ConvertFrom-Json
        }
        else {
            # Construct the "keyvault secret set" command as a string because values sometimes include special characters.

            $command = "az keyvault secret set --% --name ""$($_.Name)"" --vault-name ""$keyVaultName"" --value ""$($_.Value)"" "
            $commandResult = (Invoke-Expression $command) | ConvertFrom-Json
        }

        Write-Host "Imported secret '$($_.Name)'."
    }
    else {
        Write-Host "Secret '$($_.Name)' already exists and has not been changed."
    }
}

# Process the self-signed certificate, if it hasn't already been created.

$selfSignedCertificateName = "$($parameters.customerIdentifier)-self-signed-certificate-$($parameters.environment)"

$existingCertificate= (az keyvault certificate show --name "$selfSignedCertificateName" --vault-name $keyVaultName) | ConvertFrom-Json

if ($existingCertificate -eq $null) {
    Write-Host "Importing the self-signed certificate into the KeyVault."

    $selfSignedCertificateFilename = "$($parameters.customerIdentifier)-$($parameters.environment).pfx"
    $selfSignedCertificatePassword = $parameters.selfSignedCertificatePassword

    # Construct the keyvault command as a string because the password may include special characters.
    $command = "az keyvault certificate import --name ""$selfSignedCertificateName"" --file $selfSignedCertificateFilename --vault-name $keyVaultName --% --password ""$selfSignedCertificatePassword"""
    $commandResult = (Invoke-Expression $command) | ConvertFrom-Json

    Write-Host "Importing the self-signed certificate into the Portal VM. This may take a minute or two."
    $portalVmName = "$($parameters.customerIdentifier)-portal-vm-$($parameters.environment)"

    $keyvault = Get-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName

    $certificate = (az keyvault certificate show --vault-name $keyVaultName --name $selfSignedCertificateName | ConvertFrom-Json)

    $portalVm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $portalVmName

    $portalVm = Add-AzureRmVMSecret -VM $portalVm -SourceVaultId $keyVault.ResourceId -CertificateStore "My" -CertificateUrl $certificate.sid
    Update-AzureRmVM -ResourceGroupName $resourceGroupName -VM $portalVm
}