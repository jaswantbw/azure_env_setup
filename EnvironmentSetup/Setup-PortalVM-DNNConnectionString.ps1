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
$sqlServerName = "$($parameters.customerIdentifier)-sql-$($parameters.environment)"
$dnnDatabaseName = "$($parameters.customerIdentifier)-dnn-$($parameters.environment)"


# Use a custom script extension to finalize the VM configuration.

$customScriptFileUri = "https://nof1projectfiles.blob.core.windows.net/platform/Portal-VM-SetDnnConnectionString.ps1?st=2018-01-01T00%3A00%3A00Z&se=2040-12-31T00%3A00%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=8yMExXPLhAzAEJVEfSJAyJY8Qqlqdq2igLgxVCPJq5A%3D"

$dnnConnectionString = "Data Source=$sqlServerName.database.windows.net;Initial Catalog=$dnnDatabaseName;User ID=$($parameters.dnnUserUsername);Password=$($parameters.dnnUserPassword)"
$timestamp = Get-Date
$settings = @{ "fileUris" = @($customScriptFileUri) }
$protectedSettings = @{"commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File .\Portal-VM-SetDnnConnectionString.ps1 -DnnDatabaseConnectionString ""$dnnConnectionString"" -Timestamp ""$timestamp"" "}

$location = (Get-AzureRmResourceGroup -Name $resourceGroupName).Location

Set-AzureRmVMExtension `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -VMName "$($parameters.customerIdentifier)-portal-vm-$($parameters.environment)" `
    -Name "Portal-VM-Custom-Script" `
    -Publisher "Microsoft.Compute" `
    -ExtensionType "CustomScriptExtension" `
    -TypeHandlerVersion "1.9" `
    -Settings $settings `
    -ProtectedSettings $protectedSettings `
