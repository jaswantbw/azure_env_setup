Param(
  [string] [Parameter(Mandatory=$true)] $keyVaultName,
  [string] [Parameter(Mandatory=$true)] $portalVmName,
  [string] [Parameter(Mandatory=$true)] $VMresourceGroupName,  
  [string] [Parameter(Mandatory=$true)] $VMLocation,
  [string] [Parameter(Mandatory=$true)] $CertificateName,
  [string] [Parameter(Mandatory=$true)] $VmSubscriptionId
)

$extName =  "KeyVaultForWindows"
$extPublisher = "Microsoft.Azure.KeyVault"
$extType = "KeyVaultForWindows"
$certURL = "https://"+$keyVaultName+".vault.azure.net/secrets/"+$CertificateName
$certURL
# Build settings
    $settings = '{"secretsManagementSettings": 
    { "pollingIntervalInS": "' + 86400 + 
    '", "certificateStoreName": "' + "MY" + 
    '", "certificateStoreLocation": "' + "LocalMachine" + 
    '", "observedCertificates": ["' + $certURL + '"] } }'

Set-AzureRmContext -SubscriptionId $VmSubscriptionId

# Start the deployment
Set-AzureRmVMExtension -TypeHandlerVersion "1.0" -ResourceGroupName $VMresourceGroupName -Location $VMLocation -VMName $portalVmName -Name $extName -Publisher $extPublisher -Type $extType -SettingString $settings