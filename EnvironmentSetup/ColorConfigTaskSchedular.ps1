Param(
  [string] $EXEPath = "C:\ConfigurationStudyColor\ConfigurationStudyColor\ConfigurationStudyColor\bin\Release\ConfigurationStudyColor.exe",
  [string] [Parameter(Mandatory=$true)] $User,
  [string] [Parameter(Mandatory=$true)] $Password
)

$action = New-ScheduledTaskAction -Execute $EXEPath

$ServerName = $env:computername
$ID = $($ServerName)+'\'+$($User)

$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) `
    -RepetitionDuration (New-TimeSpan -Days (365 * 30))

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "ColorConfiguration" -User $ID -Password $Password