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

# Use a custom script extension to finalize the VM configuration.
$customScriptFileUri = "https://nof1projectfiles.blob.core.windows.net/platform/ColorConfigTaskSchedular.ps1?sp=r&st=2020-03-03T18:34:08Z&se=2050-03-04T02:34:08Z&spr=https&sv=2019-02-02&sr=b&sig=Osme19e45tldSNETdpxb1J6dXqiBVzjBGr6Hh3cWmU8%3D"

$User = $parameters.portalVirtualMachineAdminUsername
$Password = $parameters.portalVirtualMachineAdminPassword

$timestamp = Get-Date
$settings = @{ "fileUris" = @($customScriptFileUri) }
$protectedSettings = @{"commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File .\ColorConfigTaskSchedular.ps1 -User ""$User"" -Password ""$Password"" "}

$location = (Get-AzureRmResourceGroup -Name $resourceGroupName).Location

Set-AzureRmVMExtension `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -VMName "$($parameters.customerIdentifier)-vm-$($parameters.environment)" `
    -Name "Portal-VM-Custom-Script" `
    -Publisher "Microsoft.Compute" `
    -ExtensionType "CustomScriptExtension" `
    -TypeHandlerVersion "1.9" `
    -Settings $settings `
    -ProtectedSettings $protectedSettings `
