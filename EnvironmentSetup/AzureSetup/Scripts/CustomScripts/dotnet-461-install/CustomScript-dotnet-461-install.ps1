Param(
  [string] [Parameter(Mandatory=$true)] $StorageAccountName,
  [string] [Parameter(Mandatory=$true)] $StorageAccountKey
)

net use X: \\$StorageAccountName.file.core.windows.net\dotnet-461-install /u:$StorageAccountName $StorageAccountKey
cd X:

Copy-Item -Recurse X:\ C:\dotnet-461-install -ErrorAction SilentlyContinue

cd C:\dotnet-461-install
.\dotNetFramework-4.6.1-web.exe /q

# Clean up
net use X: /delete