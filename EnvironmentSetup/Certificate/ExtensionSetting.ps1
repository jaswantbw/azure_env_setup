Get-WebBinding -Port 443 -Name "nof1-portal" | Remove-WebBinding
Remove-Item -path "IIS:\SslBindings\0.0.0.0!443"

New-WebBinding -Name "nof1-portal" -Protocol https -Port 443
(Get-ChildItem cert:\localmachine\My | Where-Object {$_.FriendlyName -like '*.nof1health.com'} | sort notafter -Descending)[0] | New-Item -Path IIS:\SslBindings\!443