param([string]$Environment)

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

Invoke-RestMethod -Method Get -Uri $url 
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
    #Param ([string]$orgId, [string]$studyProtocolId, [System.Array]$entity)
    #Write-Host Find-Entity
    #Write-Host "entity: " $entity
    #Write-Host "name: " $name
    $studySiteId = "";
    $studySiteIdentifier = "";

    For ($i=0; $i -lt $studySites.Count; $i++)  
    {
        $item = $studySites.Item($i)
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
    $studySiteIdentifier = Find-StudySite 

    if ($studySiteIdentifier -eq "")
    {
        $url = $urlBase + "organization/" + $orgId + "/" + $method + "/";

        $body = @{
        "OrganizationId"=$orgId;
        "StudyProtocolId"=$studyProtocolId;
         }

        $studySiteId = Update-Entity -headers $headers -body $body -url $url
     }
}

###################################################################################
# End of functions
###################################################################################



if ($Environment -eq "")
{
    Write-Host Environment is not specified
    $Environment = Read-Host 'Enter dev or qa'

    $Environment = $Environment.ToLower();
    if ($Environment -eq 'dev' -or $Environment -eq 'qa')
    {
        Write-Host $Environment
    }
    else
    {
        Write-Host $Environment is not a valid value for Environment
        return 1
    }

    $urlBase = "https://nof1-v200-api-"+$Environment+".azurewebsites.net/";
    Write-Host $urlBase
}

###################################################################################
# Get the bearer value from an authenticated user
$bearer = ..\..\..\Utils\CommandLineB2CAuth\bin\Debug\CommandLineB2CAuth.exe
#Write-Host $bearer

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
# Get the list of existing studysites
$studyid = "5CAAC577-5A01-4F1A-B170-BFE8261E97E9"; #acm
$method = "studysite";
$url = $urlBase + "study/" + $studyid + "/" + $method + "/";
$studySites = Get-Entity -url $url

Write-Host $studySites.Count
$studyProtocolId = "5caac577-5a01-4f1a-b170-bfe8261e97e9";


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
    # Physician Not Specified / Acmeitis Registry

    $studyProtocolIdentifier = "ACM"
    $studyProtocolId = "5caac577-5a01-4f1a-b170-bfe8261e97e9";

    Upsert-StudySite

    ###############################################################################
    # Physician Not Specified / N of 1 Disease Registry

    $studyProtocolIdentifier = "NOF1"
    $studyProtocolId = "E73D6262-D85D-4111-89FC-1F40CAE212D5";

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
    # Mountain View General Hospital / Acmeitis Registry

    $studyProtocolIdentifier = "ACM"
    $studyProtocolId = "5caac577-5a01-4f1a-b170-bfe8261e97e9";

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
    # Horizon Hospital Center / Acmeitis Registry

    $studyProtocolIdentifier = "ACM"
    $studyProtocolId = "5caac577-5a01-4f1a-b170-bfe8261e97e9";

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
    # Beacon Hospital Center / Acmeitis Registry

    $studyProtocolIdentifier = "ACM"
    $studyProtocolId = "5caac577-5a01-4f1a-b170-bfe8261e97e9";

    Upsert-StudySite

