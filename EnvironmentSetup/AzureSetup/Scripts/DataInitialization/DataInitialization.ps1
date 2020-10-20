$urlBase = "https://nof1-v220-api-dev.azurewebsites.net/";
$DatabasePassword = "BF85nmWkbMQCEDjCXHkp";
$DatabaseServer = "nof1health-nof1-v220-sql.database.windows.net";
$Nof1Database = "nof1-v220-nof1-dev";
$DwDatabase = "nof1-v220-dw-dev";
$DatabaseUserName = "nof1health-nof1-v220-sql";



$B2CTenant = "nof1v220b2cdev.onmicrosoft.com";
$B2CApplicationId = "dbcb9d1e-521e-4e58-a523-bf38a378f8e3";
$B2CApplicationName = "nof1-portal";
$B2CPolicy = "B2C_1_nof1-dev-signin";


###################################################################################
# Update-Entity
function Update-Entity()
{
Param ([System.Collections.Hashtable]$headers, [System.Collections.Hashtable]$body, [string]$url)
#Write-Host Update-Entity
#Write-Host "headers: " $headers
#Write-Host "body: " $body
#Write-Host "url: " $url

$json = ConvertTo-Json $body
Invoke-RestMethod -Method Post -Uri $url -Body $json -Headers $headers 
}

###################################################################################
# Get-Entity
function Get-Entity()
{
Param ([string]$url)
#Write-Host Get-Entity
#Write-Host "url: " $url

Invoke-RestMethod -Method Get -Uri $url -Headers $headers
}

###################################################################################
# Find-Entity
function Find-Entity()
{
    Param ([string]$name, [System.Object[]]$entity)
    #Write-Host Find-Entity
    #Write-Host "entity: " $entity
    #Write-Host "name: " $name
    $id = "";
    foreach ($item in $entity)
    {
        if ($item.Name -eq $name)
        {
            #Write-Host "itemid: " $item.Id 
            #Write-Host "itemName:" $item.Name $name
            $id = $item.Id
            break;
        }
    }
    return $id
}

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
        Write-Host $item.OrganizationId $orgId
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
# Upsert-Entity
function Upsert-Entity()
{
    Param ([string]$name, [hashtable]$body, [string]$urlBase, [System.Object[]]$entity, [string]$method)
    #Write-Host Upsert-Entity

    $id = Find-Entity -name $name -entity $orgs
    if ($id)
    {
        # the organization was found, need to update it
        $body.Add("Id", $id);
        $url = $urlBase + "organization/" + $id + "/";
    }
    else
    {
        # the organization was not found, need to insert it
        $url = $urlBase + "organization/"
    }

    Write-Host
    Write-Host $name $url
    Update-Entity -headers $headers -body $body -url $url
}

###################################################################################
# Upsert-StudySite
function Upsert-StudySite()
{

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
        $url = $urlBase + "organization/" + $orgId + "/" + $method + "/";

        $body = @{
        "OrganizationId"=$orgId;
        "StudyProtocolId"=$studyProtocolId;
        "Name"=$name;
         }

        $studySiteId = Update-Entity -headers $headers -body $body -url $url
     }
}

###################################################################################
# End of functions
###################################################################################

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

###################################################################################
# Get the studyProtocolIds from the nof1 database
$results = Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $Nof1Database -Username $DatabaseUserName -Password $DatabasePassword -Query "SELECT * FROM Study.StudyProtocol"
foreach ($item in $results)
    {
        if ($item.internalIdentifier -eq "THE")
        {
            $AcmStudyProtocolId = $item.studyProtocolId
        }
        if ($item.internalIdentifier -eq "NOF1")
        {
            $Nof1StudyProtocolId = $item.studyProtocolId
        }

        $studyProtocolId = "'" + $item.studyProtocolId + "'";
        $displayName = "'" + $item.displayName + "'";
        $studyProtocolAcronym = "'" + $item.studyProtocolAcronym+ "'";
        $internalIdentifier = "'" + $item.internalIdentifier + "'";
        $discriminator = "'" + $item.discriminator + "'";
        if ($item.isActive -eq "True") { $isActive = 1 } else { $isActive = 0; }
        $lastChangedDatetime = "'" + $item.lastChangedDatetime + "'";
        $lastChangedUserId = "'" + $item.lastChangedUserId + "'";

        $query = [string]::Format("EXEC SysUtil.UpsertStudyProtocol @StudyProtocolId = {0}, @DisplayName = {1}, @StudyProtocolAcronym = {2}, @InternalIdentifier = {3}, @Discriminator = {4}, @IsActive = {5}, @LastChangedDateTime = {6}, @LastChangedUserId = {7}", $studyProtocolId, $displayName, $studyProtocolAcronym, $internalIdentifier, $discriminator, $isActive, $lastChangedDatetime, $lastChangedUserId);
        Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DwDatabase -Username $DatabaseUserName -Password $DatabasePassword -Query $query
    }
Write-Host "THE: " $AcmStudyProtocolId
Write-Host "NOF1: " $Nof1StudyProtocolId


 
###################################################################################
# Get the bearer value from an authenticated user
$b2c = "$B2CPath\CommandLineB2CAuth.exe -t='$B2CTenant' -a='$B2CApplicationId' -n='$B2CApplicationName' -p='$B2CPolicy'";
$bearer = Invoke-Expression $b2c
Write-Host $bearer

if ($bearer)
    {
    $headers = @{
    "Authorization"="Bearer " + $bearer;
    "Content-Type"="application/json; charset=utf-8";
    }
}
else
{
    Write-Host "User failed to authenticate."
    return 1
}

###################################################################################
# Get the list of existing organizations
$method = "organization";
$url = $urlBase + $method;
$orgs = Get-Entity -url $url

###################################################################################
# Get the lists of existing studysites
$method = "studysite";
$url = $urlBase + "study/" + $AcmStudyProtocolId + "/" + $method + "/";
$acmStudySites = Get-Entity -url $url
$url = $urlBase + "study/" + $Nof1StudyProtocolId + "/" + $method + "/";
$nof1StudySites = Get-Entity -url $url

Write-Host $acmStudySites.Count
Write-Host $nof1StudySites.Count


###################################################################################
# Physician Not Specified
$name = "Physician Not Specified";

$body = @{
"AddressLine1"="656 Quince Orchard Rd #300.";
"City"="Gaithersburg";
"StateProvinceOther"="MD";
"PostalCode"="20878";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Physician Not Specified";
}

$orgId = Upsert-Entity -name $name -body $body -urlBase $urlBase -entity $orgs -method $method

    ###############################################################################
    # Physician Not Specified / Theta EDC Study

    $studyProtocolIdentifier = "THE"
    $studyProtocolId = $AcmStudyProtocolId;

    Upsert-StudySite

    ###############################################################################
    # Physician Not Specified / Theta EDC Study

    $studyProtocolIdentifier = "NOF1"
    $studyProtocolId = $Nof1StudyProtocolId;

    Upsert-StudySite

###################################################################################
# Mountain View General Hospital
$name = "Mountain View General Hospital";

$body = @{
"AddressLine1"="656 Quince Orchard Rd #300.";
"City"="Gaithersburg";
"StateProvinceOther"="MD";
"PostalCode"="20878";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Mountain View General Hospital";
}

$orgId = Upsert-Entity -name $name -body $body -urlBase $urlBase -entity $orgs -method $method

    ###############################################################################
    # Mountain View General Hospital / Theta EDC Study

    $studyProtocolIdentifier = "THE"
    $studyProtocolId = $AcmStudyProtocolId;

    Upsert-StudySite

###################################################################################
# Lake Drive Medical Center
$name = "Lake Drive Medical Center";

$body = @{
"AddressLine1"="4069 Lake Drive SE";
"City"="Grand Rapids";
"StateProvinceOther"="MI";
"PostalCode"="49546";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Lake Drive Medical Center";
}

$orgId = Upsert-Entity -name $name -body $body -urlBase $urlBase -entity $orgs -method $method

###################################################################################
# Sacred Heart Hospital
$name = "Sacred Heart Hospital";

$body = @{
"AddressLine1"="421 Chew Street";
"City"="Allentown";
"StateProvinceOther"="PA";
"PostalCode"="18102";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Sacred Heart Hospital";
}

$orgId = Upsert-Entity -name $name -body $body -urlBase $urlBase -entity $orgs -method $method

###################################################################################
# Horizon Hospital Center
$name = "Horizon Hospital Center";

$body = @{
"AddressLine1"="111 Highway 70 East";
"City"="Dickson";
"StateProvinceOther"="TN";
"PostalCode"="37055";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Horizon Hospital Center";
}

$orgId = Upsert-Entity -name $name -body $body -urlBase $urlBase -entity $orgs -method $method

    ###############################################################################
    # Horizon Hospital Center / Theta EDC Study

    $studyProtocolIdentifier = "THE"
    $studyProtocolId = $AcmStudyProtocolId;

    Upsert-StudySite

###################################################################################
# Beacon Hospital Center
$name = "Beacon Hospital Center";

$body = @{
"AddressLine1"="711 Thorne Rd.";
"City"="Cornelius";
"StateProvinceOther"="NC";
"PostalCode"="28031";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Beacon Hospital Center";
}

$orgId = Upsert-Entity -name $name -body $body -urlBase $urlBase -entity $orgs -method $method

    ###############################################################################
    # Beacon Hospital Center / Theta EDC Study

    $studyProtocolIdentifier = "THE"
    $studyProtocolId = $AcmStudyProtocolId;

    Upsert-StudySite

