$Environment = "QA";
$urlBase = "https://nof1-v220-api-qa.azurewebsites.net/";

$DatabasePassword = "BF85nmWkbMQCEDjCXHkp";
$DatabaseServer = "nof1health-nof1-v220-sql.database.windows.net";
$Nof1Database = "nof1-v200-nof1-qa";
$DwDatabase = "nof1-v200-dw-qa";
$DatabaseUserName = "nof1health-nof1-v220-sql";

# Get the $bearer token and the http $headers
$return = & ((Split-Path $MyInvocation.InvocationName) + "\AuthenticateUser.ps1") 
if ($return[0] -ne 0)
{
    Write-Host "Error authenticating user. Script ending.";
    return;
}
$bearer = $return[1];
$headers = $return[2];

# Set up the system user
$SystemUserId = & ((Split-Path $MyInvocation.InvocationName) + "\SetSystemUser.ps1") 

# Get studyProtocolId for THE
$studyProtocolIdentifier = "THE";
$AcmStudyProtocolId = & ((Split-Path $MyInvocation.InvocationName) + "\GetStudyProtocol.ps1") 

# Get studyProtocolId for NOF1
$studyProtocolIdentifier = "NOF1";
$Nof1StudyProtocolId = & ((Split-Path $MyInvocation.InvocationName) + "\GetStudyProtocol.ps1") 

# Get organizations
$orgs = & ((Split-Path $MyInvocation.InvocationName) + "\GetOrganizations.ps1") 

# Get study sites for THE
$url = $urlBase + "study/" + $AcmStudyProtocolId + "/studysite/";
$acmStudySites = & ((Split-Path $MyInvocation.InvocationName) + "\GetStudySites.ps1")

# Get study sites for Nof1
$url = $urlBase + "study/" + $Nof1StudyProtocolId + "/studysite/";
$nof1StudySites = & ((Split-Path $MyInvocation.InvocationName) + "\GetStudySites.ps1")

###############################################################################
# Upsert organization Physician Not Specified
$name = "Physician Not Specified";

$body = @{
"AddressLine1"="656 Quince Orchard Rd #300.";
"City"="Gaithersburg";
"StateProvinceOther"="MD";
"PostalCode"="20878";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Physician Not Specified";
}

$orgId = & ((Split-Path $MyInvocation.InvocationName) + "\UpsertOrganization.ps1") 

# Upsert study site Physician Not Specified / Theta EDC Study
$studyProtocolIdentifier = "THE"
$studyProtocolId = $AcmStudyProtocolId;

& ((Split-Path $MyInvocation.InvocationName) + "\UpsertStudySite.ps1") 

# Physician Not Specified / Theta EDC Study

$studyProtocolIdentifier = "NOF1"
$studyProtocolId = $Nof1StudyProtocolId;

& ((Split-Path $MyInvocation.InvocationName) + "\UpsertStudySite.ps1") 

###################################################################################
# Upsert Organization Mountain View General Hospital
$name = "Mountain View General Hospital";

$body = @{
"AddressLine1"="656 Quince Orchard Rd #300.";
"City"="Gaithersburg";
"StateProvinceOther"="MD";
"PostalCode"="20878";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Mountain View General Hospital";
}

$orgId = & ((Split-Path $MyInvocation.InvocationName) + "\UpsertOrganization.ps1") 

# Mountain View General Hospital / Theta EDC Study

$studyProtocolIdentifier = "THE"
$studyProtocolId = $AcmStudyProtocolId;

& ((Split-Path $MyInvocation.InvocationName) + "\UpsertStudySite.ps1") 

###################################################################################
# Upsert Organization Lake Drive Medical Center
$name = "Lake Drive Medical Center";

$body = @{
"AddressLine1"="4069 Lake Drive SE";
"City"="Grand Rapids";
"StateProvinceOther"="MI";
"PostalCode"="49546";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Lake Drive Medical Center";
}

$orgId = & ((Split-Path $MyInvocation.InvocationName) + "\UpsertOrganization.ps1")

###################################################################################
# Upsert Organization Sacred Heart Hospital
$name = "Sacred Heart Hospital";

$body = @{
"AddressLine1"="421 Chew Street";
"City"="Allentown";
"StateProvinceOther"="PA";
"PostalCode"="18102";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Sacred Heart Hospital";
}

$orgId = & ((Split-Path $MyInvocation.InvocationName) + "\UpsertOrganization.ps1")

###################################################################################
# Upsert Organization Horizon Hospital Center
$name = "Horizon Hospital Center";

$body = @{
"AddressLine1"="111 Highway 70 East";
"City"="Dickson";
"StateProvinceOther"="TN";
"PostalCode"="37055";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Horizon Hospital Center";
}

$orgId = & ((Split-Path $MyInvocation.InvocationName) + "\UpsertOrganization.ps1")

# Horizon Hospital Center / Theta EDC Study

$studyProtocolIdentifier = "THE"
$studyProtocolId = $AcmStudyProtocolId;

& ((Split-Path $MyInvocation.InvocationName) + "\UpsertStudySite.ps1") 

###################################################################################
# Upsert Organization Beacon Hospital Center
$name = "Beacon Hospital Center";

$body = @{
"AddressLine1"="711 Thorne Rd.";
"City"="Cornelius";
"StateProvinceOther"="NC";
"PostalCode"="28031";
"CountryId"="FD5A259D-8930-415E-8E02-7352891DDB7D";
"Name"="Beacon Hospital Center";
}

$orgId = & ((Split-Path $MyInvocation.InvocationName) + "\UpsertOrganization.ps1")

# Beacon Hospital Center / Theta EDC Study

$studyProtocolIdentifier = "THE"
$studyProtocolId = $AcmStudyProtocolId;

& ((Split-Path $MyInvocation.InvocationName) + "\UpsertStudySite.ps1") 

###################################################################################
# Create the default users

& ((Split-Path $MyInvocation.InvocationName) + "\CreateDefaultUsers.ps1") 
