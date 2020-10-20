Param(
  [string] [Parameter(Mandatory=$true)] $StorageAccountName,
  [string] [Parameter(Mandatory=$true)] $StorageAccountKey
)

net use Z: /delete
net use Z: \\$StorageAccountName.file.core.windows.net\ssh-install /u:$StorageAccountName $StorageAccountKey
cd Z:

Copy-Item -Recurse Z:\ C:\ssh-install -ErrorAction SilentlyContinue

cd C:\ssh-install
./ssh-install-win64.ps1

# Clean up
net use Z: /delete