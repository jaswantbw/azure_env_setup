# Setup script for N of 1 Disaster Recovery - Backing Up Virtual Machine

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

# Get Recovery Vault in the same location as the Virtual Machine (the location is important)
Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"
$recoveryVault = Get-AzureRmRecoveryServicesVault –Name $recoveryVaultName -ResourceGroupName $resourceGroupName
if ($recoveryVault) {
	Write-Host "Using the existing recovery vault '$recoveryVaultName'."
}
else {
	Write-Host "Couldn't find existing recovery vault with the name '$recoveryVaultName'."
	Write-host "Started creating new recovery vault '$recoveryVaultName'..."
	$recoveryVault = New-AzureRmRecoveryServicesVault -Name $recoveryVaultName -ResourceGroupName $resourceGroupName -Location $vmLocation
	Write-Host "Finished creating new recovery vault '$recoveryVaultName'"
	Write-Host "Started setting the recovery services backup to be Geo-redundant..."
	Set-AzureRmRecoveryServicesBackupProperties  -Vault $recoveryVault -BackupStorageRedundancy GeoRedundant
	Write-Host "Recovery services backup  has been set to be Geo-redundant"
}

# Set the recovery service context 
$recoveryVault | Set-AzureRmRecoveryServicesVaultContext

# Get/Create a backup policy
$schPol = Get-AzureRmRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
$retPol = Get-AzureRmRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
try
{
	$backupPolicy = Get-AzureRmRecoveryServicesBackupProtectionPolicy -Name $backupPolicyName
	Write-Host "Using the existing backup policy '$backupPolicyName'."
}
catch {
	Write-Host "Creating a new backup policy..."
	$backupPolicy = New-AzureRmRecoveryServicesBackupProtectionPolicy -Name $backupPolicyName -WorkloadType AzureVM -RetentionPolicy $retPol -SchedulePolicy $schPol
	Write-Host "Policy '$backupPolicyName' has been created."
}


<# Modify the Protection Schedule/Policy (This is done by changing the schedule run time, run frequency and retention policy) 
#$schPol.ScheduleRunTimes.RemoveAll()
#$DT = Get-Date
#$schPol.ScheduleRunTimes.Add($DT.ToUniversalTime())
#$SchPol.ScheduleRunFrequency = "Weekly"
#$retPol.DailySchedule.DurationCountInDays = 365
#Set-AzureRmRecoveryServicesBackupProtectionPolicy -Policy $backupPolicy  -RetentionPolicy  $retPol -SchedulePolicy $schPol
#>

# Enable Protection (this will only work if the VM isn't already being backed up by another policy)
Write-Host "Enabling backup...this may take a few minutes"
Enable-AzureRmRecoveryServicesBackupProtection -Policy $backupPolicy -Name $vmName -ResourceGroupName $resourceGroupName
Write-Host "Virtual Machine '$vmName' Backup enabled"

# Run Backup (If this script is run and it's not the first back up of the day, it will over-write the backup for that day)
$namedContainer = Get-AzureRmRecoveryServicesBackupContainer -ContainerType "AzureVM" -Status "Registered" -Name $vmName
$item = Get-AzureRmRecoveryServicesBackupItem -Container $namedContainer -WorkloadType "AzureVM"
Write-Host "Virtual Machine '$vmName' Backing up now..."
Backup-AzureRmRecoveryServicesBackupItem -Item $item

<# Monitoring backup
$joblist = Get-AzureRmRecoveryservicesBackupJob –Status InProgress
$joblist[0]
#>