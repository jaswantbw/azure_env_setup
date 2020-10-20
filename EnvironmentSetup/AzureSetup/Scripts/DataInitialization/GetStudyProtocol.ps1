###################################################################################
# Get the studyProtocolIds from the nof1 database
$results = Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $Nof1Database -Username $DatabaseUserName -Password $DatabasePassword -Query "SELECT * FROM Study.StudyProtocol WHERE internalIdentifier = '$studyProtocolIdentifier'"
foreach ($item in $results)
    {
        $studyProtocolId = $item.studyProtocolId;
        $displayName = $item.displayName;
        $studyProtocolAcronym = $item.studyProtocolAcronym;
        $internalIdentifier = $item.internalIdentifier;
        $discriminator = $item.discriminator;
        if ($item.isActive -eq "True") { $isActive = 1 } else { $isActive = 0; }
        $lastChangedDatetime = $item.lastChangedDatetime;
        $lastChangedUserId = $item.lastChangedUserId;

        $query = [string]::Format("EXEC SysUtil.UpsertStudyProtocol @StudyProtocolId = '{0}', @DisplayName = '{1}', @StudyProtocolAcronym = '{2}', @InternalIdentifier = '{3}', @Discriminator = '{4}', @IsActive = {5}, @LastChangedDateTime = '{6}', @LastChangedUserId = '{7}'", $studyProtocolId, $displayName, $studyProtocolAcronym, $internalIdentifier, $discriminator, $isActive, $lastChangedDatetime, $lastChangedUserId);
        Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DwDatabase -Username $DatabaseUserName -Password $DatabasePassword -Query $query
    }
return $studyProtocolId;