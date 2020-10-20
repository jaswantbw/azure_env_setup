###################################################################################
# Find-StudySite
function Find-StudySite()
{
    Param ([string]$orgId, [string]$studyProtocolId, [System.Array]$entity)
    #Write-Host Find-Entity
    #Write-Host "entity: " $entity
    #Write-Host "name: " $name
    $studySiteId = "";
    $studySiteIdentifier = "";

    For ($i=0; $i -lt $entity.Count; $i++)  
    {
        $item = $entity.Item($i)
        #Write-Host $item.OrganizationId $orgId
        #Write-Host $item.StudyProtocolId $studyProtocolId

        if ($item.OrganizationId -eq $orgId -and $item.StudyProtocolId -eq $studyProtocolId)
        {
            $studySiteId = $item.Id
            $studySiteIdentifier = $item.StudySiteIdentifier
            break;
        }
    }

    return $studySiteIdentifier
}

###################################################################################
# Update-Entity
function Update-Entity()
{
Param ([System.Collections.Hashtable]$headers, [System.Collections.Hashtable]$body, [string]$url)

$json = ConvertTo-Json $body
Invoke-RestMethod -Method Post -Uri $url -Body $json -Headers $headers 
}

###################################################################################
# Main

$studySiteIdentifier = "";
if ($studyProtocolIdentifier -eq "THE")
{
    $studySiteIdentifier = Find-StudySite -orgId $orgId -studyProtocolId $studyProtocolId -entity $acmStudySites
}
else
{
    $studySiteIdentifier = Find-StudySite -orgId $orgId -studyProtocolId $studyProtocolId -entity $nof1StudySites
}
    
if ($studySiteIdentifier -eq "")
{
    $url = $urlBase + "organization/" + $orgId + "/studysite/";

    $body = @{
    "OrganizationId"=$orgId;
    "StudyProtocolId"=$studyProtocolId;
    "Name"=$name;
        }

    Update-Entity -headers $headers -body $body -url $url
}

return;