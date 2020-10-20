#User Variables
$appName = "Graph API Service Application"

#Make sure you've created a new user account in the old azure portal, that has permission to add a new App (Admin role works :)).
$AdminUserName = "administrator@nof1v230b2cdev.onmicrosoft.com"
$AdminUserPassword = 'Touch@123'


Write-Host "Checking for AD Powershell module"

# Ensure that you have installed the Powershell AD Module using Install-Module MSOnline

$poshAdFound = get-item $env:SystemRootSystem32WindowsPowerShellv1.ModulesMSOnlineMicrosoft.Online.Administration.Automation.PSModule.dll -ErrorAction SilentlyContinue
if ($poshAdFound -eq $null) { Write-Host "AD Powershell module not found, install it from here. https://technet.microsoft.com/library/jj151815.aspx#bkmk_installmodule" exit}

Write-Host "Connecting to AD tenant"
$securePwString = ConvertTo-SecureString -String $AdminUserPassword -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $AdminUserName, $securePwString
$msolcred = Get-Credential -Credential $Credential
Connect-MsolService -credential $msolcred

Write-Host "Creating client secret"
$bytes = New-Object Byte[] 32
$rand = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rand.GetBytes($bytes)
$rand.Dispose()
$newClientSecret = [System.Convert]::ToBase64String($bytes)

Write-Host "Adding AD Application"
$newSP = New-MsolServicePrincipal -DisplayName $appName -Type password -Value $newClientSecret

Write-Host "Adding roles"
Add-MsolRoleMember -RoleObjectId 88d8e3e3-8f55-4a1e-953a-9b9898b8876b -RoleMemberObjectId $newSP.ObjectId -RoleMemberType servicePrincipal
Add-MsolRoleMember -RoleObjectId 9360feb5-f418-4baa-8175-e2a00bac4301 -RoleMemberObjectId $newSP.ObjectId -RoleMemberType servicePrincipal
Add-MsolRoleMember -RoleObjectId fe930be7-5e62-47db-91af-98c3a49a38b1 -RoleMemberObjectId $newSP.ObjectId -RoleMemberType servicePrincipal

Write-host $appname
Write-host "Client Secret : $newClientSecret"
Write-host "App Principal : $newSP.AppPrincipalId.ToString()"