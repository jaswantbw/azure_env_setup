Param(
  [string] [Parameter(Mandatory=$true)] $StorageAccountName,
  [string] [Parameter(Mandatory=$true)] $StorageAccountKey
)

net use Y: /delete
net use Y: \\$StorageAccountName.file.core.windows.net\portal-vm-role-setup /u:$StorageAccountName $StorageAccountKey

Install-WindowsFeature -ConfigurationFilePath Y:\DeploymentConfigTemplate-Server2016.xml

# Clean up
net use Y: /delete