Param(
[string]$ProgramPath = "D:\git3\Nof1HealthPlatform\Utils\Nof1Health.Utilities.V1UserAccountMigration\bin\Debug"
)

$rc = 0;

$Program = ".\B2C.exe ";
Try
{
    Set-Location -Path $ProgramPath
    Get-Location
    $return = Start-Process $Program;
}
Catch
{
    Write-Host "Error running program."
    $rc = 1;
    return $rc;
}

return $rc;