Param(
  [string] [Parameter(Mandatory=$true)] $VMResourceGroup,
  [string] [Parameter(Mandatory=$true)] $VMName,
  [string] [Parameter(Mandatory=$true)] $VMLocation,
  [string] [Parameter(Mandatory=$true)] $URI,
  [string] [Parameter(Mandatory=$true)] $scriptName

)

$error.clear()
try { Get-AzVMExtension -ResourceGroupName $VMResourceGroup -VMName $VMName -Name IISBinding }
catch { "IISBinding VM Custom Script Extension not found" }
if (!$error) {
    Remove-AzVMCustomScriptExtension -ResourceGroupName $VMResourceGroup -VMName $VMName -Name IISBinding -Force
}

Set-AzureRmVMCustomScriptExtension -ResourceGroupName $VMResourceGroup `
    -VMName $VMName `
    -Location $VMLocation `
    -FileUri $URI `
    -Run $scriptName `
    -Name IISBinding