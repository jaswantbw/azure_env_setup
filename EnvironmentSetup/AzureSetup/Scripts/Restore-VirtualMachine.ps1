# Setup script for N of 1 Disaster Recovery - Restoring the Virtual Machine From Back Up

# Before running this script in a PowerShell prompt:
# 1. Run Login-AzureRmAccount
# 2. Set the subscription by running Set-AzureRmContext -SubscriptionName "{{ SUBSCRIPTION NAME }}"

Param(
	[string] [Parameter(Mandatory=$true)] $TemplateParametersFile
)

$ErrorActionPreference = "Stop"

# Get Parameters from the parameters file
$params = (Get-Content $TemplateParametersFile) -join "`n" | ConvertFrom-Json
$customerIdentifier = $params.parameters.customerIdentifier.value
$environment = $params.parameters.environment.value
$vmName = "nof1-dep-test"
#$vmName = "$customerIdentifier-$environment"
$vmLocation = $params.parameters.vmLocation.value
$vmLocationShortName = ($vmLocation.ToLower() -Replace '\s','')
$backupPolicyName = "$customerIdentifier-vm-policy"
$recoveryVaultName = "nof1-dp-test-recovery"
#$recoveryVaultName = "$customerIdentifier-$environment-recovery-vault-$vmLocationShortName"
$vmDiskStorageAccountName =  ("$customerIdentifier-storagepr-$environment" -Replace '-','')
$portalVmAdminPassword = $params.parameters.portalVmAdminPassword.value
$newVmName = "re-$vmName"
$ipName = "re-$customerIdentifier-ip-$environment"
$nicName = "$customerIdentifier-nic-$environment"
$vnetName = "$customerIdentifier-network-$environment"
$domainNameLabel = "re-$customerIdentifier-$environment"

Write-Host "vmLocation is '$vmLocation'"	
Write-Host "backupPolicyName is '$backupPolicyName'"
Write-Host "vmName is '$vmName'"
Write-Host "recoveryVaultName is '$recoveryVaultName'"
Write-Host "storage account name is '$vmDiskStorageAccountName'"

# Get Resource Group. 
if (!$resourceGroupName) {
    $resourceGroupName = "$customerIdentifier-$environment"
} 
$resourceGroup = Find-AzureRmResourceGroup | Where-Object {$_.Name -eq $resourceGroupName}
if ($resourceGroup) {
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName
    Write-Host "Using existing resource group '$($resourceGroup.ResourceGroupName)'."
}
else {
    Write-Host "Resource group '$resourceGroupName' doesn't exist!"
}

# Set the recovery service context 
Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"
$recoveryVault = Get-AzureRmRecoveryServicesVault –Name $recoveryVaultName -ResourceGroupName $resourceGroupName
$recoveryVault | Set-AzureRmRecoveryServicesVaultContext

# Find the Backup Container for the VM
Write-Host "Searching for backup for virtual machine '$vmName'..."
$namedContainer = Get-AzureRmRecoveryServicesBackupContainer  -ContainerType AzureVM –Status Registered -Name $vmName
$backupitem = Get-AzureRmRecoveryServicesBackupItem –Container $namedContainer  –WorkloadType "AzureVM"

# Get a list of the recovery point available between the dates of the specified start and end dates
$startDate = (Get-Date).AddDays(-7)
$endDate = Get-Date
$recoveryPoint = Get-AzureRmRecoveryServicesBackupRecoveryPoint -Item $backupitem -StartDate $startdate.ToUniversalTime() -EndDate $enddate.ToUniversalTime()
Write-Host "Found the following recovery points for virtual machine '$vmName'"
$recoveryPoint
# select the first recovery point within that interval
Write-Host
Write-Host "Selecting the first recovery point for restoration..."

<# restore the disk
Write-Host "Starting disk restoration..."
$restorejob = Restore-AzureRmRecoveryServicesBackupItem -RecoveryPoint $recoveryPoint[0] -StorageAccountName $vmDiskStorageAccountName -StorageAccountResourceGroupName $resourceGroupName | Out-Null

# Get details of the disk restoration and use it to create the VM
$restoreJobs = Get-AzureRmRecoveryServicesBackupJob -Status 'InProgress'

$restorejob = $restoreJobs[0] 
	while ( $restorejob.Status -ne 'Completed')
    {
       Write-Host "Disk restoration in progress...this may take a while"
       Start-Sleep -Seconds 300
       $restorejob = Get-AzureRmRecoveryServicesBackupJob  -Job $restorejob
    }
    Write-Host "Disk restoration complete."
Write-Host
$restorejob
$details = Get-AzureRmRecoveryServicesBackupJobDetails -Job $restorejob

$properties = $details.properties
$storageAccountName = $properties["Target Storage Account Name"]
$containerName = $properties["Config Blob Container Name"]
$blobName = $properties["Config Blob Name"]
#>
# Set Azure storage context
Set-AzureRmCurrentStorageAccount -Name $vmDiskStorageAccountName -ResourceGroupName $resourceGroupName
$destination_path = "C:\vmconfig.json"
Get-AzureStorageBlobContent -Container 'vhd48e6d680e70247b28daf7df39d166eb8' -Blob 'config456fa41c-8117-496a-ac31-2ca0e6dee6eb.json' -Destination $destination_path
$configObject = ((Get-Content -Raw -Path $destination_path -Encoding Unicode)).TrimEnd([char]0x00) |ConvertTo-Json | ConvertFrom-Json
$configObject = $configObject  -Join "`n" | ConvertFrom-Json
$configObject | Get-Member
$configObject
$computerName = $configObject.OSProfile.computerName
Write-Host "VM Computer name : $computerName"

# Using the Json configuration object, create the VM configuration
$vm = New-AzureRmVMConfig -VMSize $configObject.HardwareProfile.VirtualMachineSize -VMName $newVmName # this VM name has to be different??
$vmPassword = ConvertTo-SecureString $portalVmAdminPassword -AsPlainText -Force
$vmCredential = New-Object System.Management.Automation.PSCredential($newVmName, $vmPassword)

# The next line of command fails because we are unable to set the OsProfile 
#Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $newVmName -Credential $vmCredential -ProvisionVMAgent -EnableAutoUpdate

Set-AzureRmVMOSDisk -VM $vm -Name "osdisk" -VhdUri $configObject.StorageProfile.OSDisk.VirtualHardDisk.Uri -CreateOption Attach
$vm.StorageProfile.OsDisk.OsType = $configObject.StorageProfile.OSDisk.OperatingSystemType 
foreach($dd in $configObject.StorageProfile.DataDisks)
{
	$vm = Add-AzureRmVMDataDisk -VM $vm -Name "datadisk1" -VhdUri $dd.VirtualHardDisk.Uri -DiskSizeInGB 127 -Lun $dd.Lun -CreateOption Attach
}

# Create the Public IP Address and Network Interface
try
{
	Write-Host "Searching for IP Address '$ipName'..."
	$pip = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name $ipName
	Write-Host "IP Address '$ipName' found."
}
catch { 
	Write-Host "IP Address '$ipName' was not found."
	Write-Host "Creating IP Address '$ipName'..."
	$pip = New-AzureRmPublicIpAddress -Name $ipName -DomainNameLabel $domainNameLabel -ResourceGroupName $resourceGroupName -Location $vmLocation -AllocationMethod Dynamic
	Write-Host "IP Address '$ipName' created."
}
finally {
	Write-Host "Searching for Virtaul Network '$vnetName'..."
	$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
	Write-Host "Virtaul Network '$vnetName' found."
	$nic = Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName
	Write-Host "Creating Network Interface '$nicName'..."
	$nic = New-AzureRmNetworkInterface -Name "re-$nicName" -ResourceGroupName $resourceGroupName -Location $vmLocation -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
	Write-Host "Network Interface '$nicName' created."
	$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
}

$vm.StorageProfile.OsDisk.OsType = $configObject.StorageProfile.OSDisk.OperatingSystemType
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $vmLocation -VM $vm
#>