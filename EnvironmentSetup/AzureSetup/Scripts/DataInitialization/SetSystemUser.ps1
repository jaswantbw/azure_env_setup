###################################################################################
# Get the system user data from the dw database
$results = Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DwDatabase -Username $DatabaseUserName -Password $DatabasePassword -Query "SELECT * FROM Dim.UserAccount WHERE UserName = 'System'"
$SystemUserId = "";
foreach ($item in $results)
    {
        $SystemUserId = $item.UserAccountGUID;
    }
Write-Host "system user: " $SystemUserId

if ($SystemUserId -eq "")
{
    # need to insert into dw
    # get data from nof1 database
    $results = Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $Nof1Database -Username $DatabaseUserName -Password $DatabasePassword -Query "SELECT * FROM Platform.UserAccount WHERE UserName = 'System'"

    $userAccountId = "'" + $results[0] + "'";
    $SystemUserId = $results[0];
    $userName = "'" + $results[1] + "'";
    $AzureAdUserId = "'" + $results[5] + "'";
    if ($results[3].length -eq 1) { $personId = "NULL" } else { $personId = "'" + $results[3] + "'"; }
    if ($results[4] -eq "True") { $isSuperUser = 1 } else { $isSuperUser = 0; }
    if ($results[16] -eq "True") { $isActive = 1 } else { $isActive = 0; }
    $lastChangedDatetime = "'" + $results[12] + "'";

    $query = [string]::Format("EXEC SysUtil.UpsertUserAccount @UserAccountId = {0}, @UserName = {1}, @IsSuperUser = {2}, @AzureADUserID = {3}, @PersonID = {4}, @IsActive = {5}, @LastChangedDateTime = {6}", $userAccountId, $UserName, $isSuperUser, $AzureAdUserId, $personId, $isActive, $lastChangedDatetime);
    Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DwDatabase -Username $DatabaseUserName -Password $DatabasePassword -Query $query
}
return $SystemUserId;