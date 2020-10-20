# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile,
  [string] $PortalModuleBuildDirectory = ".\..\Portal\_installPackages"
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

# Resolve the portal module build directory into an absolute path.
$portalModuleBuildDirectoryFullPath = (Resolve-Path $PortalModuleBuildDirectory).Path

# Get the portal VM host name and credentials.
$resourceGroupName = "$($parameters.customerIdentifier)-$($parameters.environment)"
$portalVmPublicIpName = "$($parameters.customerIdentifier)-portal-public-ip-$($parameters.environment)"
$portalVmPublicIp = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name $portalVmPublicIpName
$portalVmDomainName = $portalVmPublicIp.DnsSettings.Fqdn

$portalVmUsername = $parameters.portalVirtualMachineAdminUsername
$portalVmPassword = $parameters.portalVirtualMachineAdminPassword


# Upload the portal modules.
Write-Host "Uploading portal modules to the VM..."
Write-Host
& .\WinSCP.com /ini=nul `
    /command "open sftp://$($portalVmUsername):$($portalVmPassword)@$portalVmDomainName -hostkey=* -rawsettings KEX=dh-group14-sha1,dh-gex-sha1,dh-group1-sha1,rsa " `
    "lcd ""$portalModuleBuildDirectoryFullPath"" " `
    "cd" "cd C:/inetpub/wwwroot/nof1-portal/Install/Module" `
    "synchronize remote . ." `
    "exit"

Write-Host "Completed uploading portal modules to the VM."

Write-Host "Installing modules..."
$installModuleResponse = Invoke-WebRequest -Uri "http://$portalVmDomainName/install/install.aspx?mode=installresources"
Write-Host ($installModuleResponse.Content -replace "<br>", "`r`n<br>`r`n")