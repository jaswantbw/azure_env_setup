Param(
  [string] [Parameter(Mandatory=$true)] $VMResourceGroup,
  [string] [Parameter(Mandatory=$true)] $VMName,
  [string] [Parameter(Mandatory=$true)] $VmSubscriptionId,
  [string] [Parameter(Mandatory=$true)] $VaultName,
  [string] [Parameter(Mandatory=$true)] $VaultSubscriptionId,
  [string] [Parameter(Mandatory=$true)] $VaultResourceGroupName
)

Set-AzureRmContext -SubscriptionId $VmSubscriptionId
$vm = Get-AzureRmVM -ResourceGroupName $VMResourceGroup -Name $VMName
Update-AzureRmVM -ResourceGroupName $VMResourceGroup -VM $vm -IdentityType:SystemAssigned
$VMID = (Get-AzureRmADServicePrincipal -displayname $VMName).ID


Set-AzureRmContext -SubscriptionId $VaultSubscriptionId
Set-AzureRmKeyVaultAccessPolicy -VaultName $VaultName -ResourceGroupName $VaultResourceGroupName -ObjectId $VMID -PermissionsToCertificates get,list,getissuers,listissuers -PermissionsToKeys get,list -PermissionsToSecrets get,list