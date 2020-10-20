$urlBase = "https://nof1-v200-api-dev.azurewebsites.net/";

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
    Param ([string]$orgId, [string]$studyProtocolId)
    #Write-Host Find-Entity
    #Write-Host "entity: " $entity
    #Write-Host "name: " $name
    $studySiteId = "";
    $studySiteIdentifier = "";
    if($studyProtocolId -eq "5CAAC577-5A01-4F1A-B170-BFE8261E97E9")
    {
    $studySites = $acmStudySites;
    }#acm
    elseif($studyProtocolId -eq "E73D6262-D85D-4111-89FC-1F40CAE212D5")
    {
    $studySites = $nof1StudySites;
    }
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

    return $studySiteIdentifier, $studySiteId
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
   Param ([string]$orgId,[string]$method,[hashtable]$body, [string]$urlBase, [string]$studyProtocolId)
    $studySiteIdentifier = "";
    $returnValues = Find-StudySite -orgId $orgId -studyProtocolId $studyProtocolId
    $studySiteIdentifier = $returnValues[0]

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

###################################################################################
# Get the bearer value from an authenticated user
$bearer =  C:\Users\enging\Desktop\CommanLine\CommandLineB2CAuth\CommandLineB2CAuth\bin\Debug\CommandLineB2CAuth.exe
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
$acmStudySites = Get-Entity -url $url

Write-Host $studySites.Count
$studyProtocolId = "5CAAC577-5A01-4F1A-B170-BFE8261E97E9";

$studyid = "E73D6262-D85D-4111-89FC-1F40CAE212D5"; #nof1
$method = "studysite";
$url = $urlBase + "study/" + $studyid + "/" + $method + "/";
$nof1StudySites = Get-Entity -url $url

Write-Host $studySites.Count
$studyProtocolId = "E73D6262-D85D-4111-89FC-1F40CAE212D5";


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
    $studyProtocolId = "5CAAC577-5A01-4F1A-B170-BFE8261E97E9";

    Upsert-StudySite -orgId $orgId -method $method -body $body -urlBase $urlBase -studyProtocolId $studyProtocolId

    ###############################################################################
    # Physician Not Specified / N of 1 Disease Registry

    $studyProtocolIdentifier = "NOF1"
    $studyProtocolId = "E73D6262-D85D-4111-89FC-1F40CAE212D5";

    Upsert-StudySite -orgId $orgId -method $method -body $body -urlBase $urlBase -studyProtocolId $studyProtocolId

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
    $studyProtocolId = "5CAAC577-5A01-4F1A-B170-BFE8261E97E9";

    Upsert-StudySite -orgId $orgId -method $method -body $body -urlBase $urlBase -studyProtocolId $studyProtocolId

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
    $studyProtocolId = "5CAAC577-5A01-4F1A-B170-BFE8261E97E9";

    Upsert-StudySite -orgId $orgId -method $method -body $body -urlBase $urlBase -studyProtocolId $studyProtocolId

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
    $studyProtocolId = "5CAAC577-5A01-4F1A-B170-BFE8261E97E9";

    Upsert-StudySite -orgId $orgId -method $method -body $body -urlBase $urlBase -studyProtocolId $studyProtocolId


 ###################################################################################
 # Create - Personnel
 ###################################################################################
 function Upsert-Personnel()
{
    Param ([string]$emailAddress, [hashtable]$body)
    $url = $urlBase + "userRegistration?emailAddress=" + $emailAddress;
    $userExist = Invoke-RestMethod -Method Get -Uri $url 
    
    if($userExist)
      {
       $url = $urlBase + "personnel";
       $json = ConvertTo-Json $body
       $personnelData = Invoke-RestMethod -Method Post -Uri $url -Body $json -Headers $headers 
       $PersonId = $personnelData.Id;
        # Physician Not Specified / Acmeitis Registry
        Create-Member -PersonId $PersonId -SProtocolId "5CAAC577-5A01-4F1A-B170-BFE8261E97E9" -SProtocolName "Acmeitis Registry" -IsPrimary $true
        # Physician Not Specified / N of 1 Disease Registry
       #Create-Member -PersonId $PersonId -SProtocolId "E73D6262-D85D-4111-89FC-1F40CAE212D5" -SProtocolName "N of 1 Disease Registry" -IsPrimary $false
      }
      else
      {
      
          $studyProtocolId = "5CAAC577-5A01-4F1A-B170-BFE8261E97E9";
          $returnValues = Find-StudySite -orgId $orgId -studyProtocolId $studyProtocolId
           $studySiteId = $returnValues[1]
            $url = $urlBase + "organization/studySite/"+ $studySiteId+"/member/";
            $studySiteMembers = Invoke-RestMethod -Method Get -Uri $url  -Headers $headers
            For ($i=0; $i -lt $studySiteMembers.Count; $i++) 
            {
            $item = $studySiteMembers.Item($i)
             if ($item.Person.Email -eq $emailAddressBody)
                {
                    $personId = $item.PersonId
                    break;
                }
            }
            $url = $urlBase + "personnel/"+$personId
            $body = @{
	            "Email"= $emailAddressBody;
	            "FirstName"= $FirstName;
	            "LastName"= $LastName;
                "Id" = $personId
            }
            $json = ConvertTo-Json $body
            $personnelData = Invoke-RestMethod -Method Post -Uri $url -Body $json -Headers $headers
            Write-Host "User Account" for  $FirstName $LastName "Updated" 
      }
}
###################################################################################
 # Insert Organization Member
 ###################################################################################
 function Create-Member()
{
  Param([string]$PersonId,[string]$SProtocolId, [string]$SProtocolName , [string]$IsPrimary)
  $body = @{
            "PersonId"=$PersonId;
             "StudyProtocolId" = $SProtocolId;
             "StudyProtocolName" = $SProtocolName;
            }
  $url = $urlBase + "study/"+ $SProtocolId +"/member";
  $json = ConvertTo-Json $body
  $memberData = Invoke-RestMethod -Method Post -Uri $url -Body $json -Headers $headers 
  $memberId = $memberData.Id;
  Create-StudySiteMemberships -PersonId $PersonId -orgId $OrgId -sProtocolId $SProtocolId -IsPrimary $IsPrimary
}
###################################################################################
 # Insert Organization Member
 ###################################################################################
function Create-StudySiteMemberships()
        {
        #GetRoleId and StudySiteId dynamically
        Param([string]$PersonId, [string]$orgId, [string]$sProtocolId, [string]$IsPrimary )
    
         $returnValues = Find-StudySite -orgId $orgId -studyProtocolId $studyProtocolId
         $studySiteId = $returnValues[1]
            $url = $urlBase+ "role?allowedScope="+ $studySiteId;
            $rolesList = Get-Entity -url $url
            foreach ($item in $rolesList)
            {
                if ($item.DisplayName -eq $roleName)
                {
                    #Write-Host "itemid: " $item.Id 
                    #Write-Host "itemName:" $item.Name $name
                    $roleId = $item.Id
                    break;
                }
            }
            $roles = @{}
            $roles.Add("RoleId", $roleId);
            $body = @(@{
                    "StudySiteId"=$studySiteId;
                    "PersonId"=$PersonId;
                    "Roles"=
                    @(@{
                    "RoleId" = $roleId
                    })
                    ;
                    "IsPrimary" = $IsPrimary;
                    })
             $url = $urlBase + "Personnel/"+ $PersonId +"/studySiteMemberships";
             $json = ConvertTo-Json $body
              


             #Study Site Membership
             Invoke-RestMethod -Method Post -Uri $url -Body $json -Headers $headers 
             #Member Approval
             $body = @{"IsAutoApproved" = $true }            
             $url = $urlBase + "userRegistration/invitation/member/"+ $PersonId;
             $json = ConvertTo-Json $body
             Invoke-RestMethod -Method Post -Uri $url -Body $json -Headers $headers 
              #insert role
              $body = @{}
              $url = $urlBase + "study/"+ $studyProtocolId +"/member/"+$memberId+"/role/"+$roleId;
              $json = ConvertTo-Json $body
              Invoke-RestMethod -Method PUT -Uri $url -Body $json -Headers $headers 
              Write-Host "Script Completed"
        }

###################################################################################
###################################################################################

###################################################################################
 # Get the list of existing organizations
    $method = "organization";
    $url = $urlBase + $method;
    $orgs = Get-Entity -url $url
###################################################################################
# # Create Users
###################################################################################
$orgname = "Beacon Hospital Center";
$OrgId = Find-Entity -name $orgname -entity $orgs
###################################################################################
$emailAddress = "nof1v2test%2BJoshuaConnors%40gmail.com";
$emailAddressBody = "nof1v2test+JoshuaConnors@gmail.com";
$FirstName = "Joshua";
$LastName  = "Connors";
$roleName = "Help Desk"

$body = @{
	"Email"= $emailAddressBody;
	"FirstName"= $FirstName;
	"LastName"= $LastName
}


Write-Host "Creating User for" $FirstName $LastName
Upsert-Personnel -emailAddress $emailAddress -body $body





 
