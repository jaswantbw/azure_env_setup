$ErrorActionPreference = "Stop"

Set-Location "$PSScriptRoot"

# Set up a firewall rule to allow SSH traffic.
$firewallRule = Get-NetFirewallRule -Name "SSH-Port22" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Remove-NetFirewallRule -Name "SSH-Port22"
}
New-NetFirewallRule -Name "SSH-Port22" -DisplayName "SSH - Port 22" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22

Add-Type -AssemblyName System.IO.Compression.FileSystem
Remove-Item -Recurse -Force -Path "$PSScriptRoot\OpenSSH-Win64" -ErrorAction SilentlyContinue
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PSScriptRoot\OpenSSH-Win64.zip", "$PSScriptRoot")

copy sshd_config $PSScriptRoot\OpenSSH-Win64

pushd $PSScriptRoot\OpenSSH-Win64
powershell -ExecutionPolicy Bypass -File install-sshd.ps1
.\ssh-keygen.exe -A

Stop-Service sshd

# Give the SSH user full control to this directory.
icacls "$PSScriptRoot\OpenSSH-Win64" /grant '"NT SERVICE\SSHD":(OI)(CI)F' /T

Start-Service sshd
Set-Service sshd -StartupType Automatic

Write-Host "SSH Setup Complete!"

Set-Location "$PSScriptRoot"
