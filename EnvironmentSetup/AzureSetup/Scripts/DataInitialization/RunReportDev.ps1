$Environment = "DEV";
$urlBase = "https://nof1-v220-api-dev.azurewebsites.net/";
#$urlBase = "http://localhost:55075/";

$DatabasePassword = "BF85nmWkbMQCEDjCXHkp";
$DatabaseServer = "nof1health-nof1-v220-sql.database.windows.net";
$Nof1Database = "nof1-v220-nof1-dev";
$DwDatabase = "nof1-v220-dw-dev";
$DatabaseUserName = "nof1health-nof1-v220-sql";

try
{
	$reportPath = Resolve-Path -Path "..\..\..\..\Portal\Reports\" -ErrorAction Stop
}
catch 
{
	Write-Host "Report Path not found"
    return
}

try
{
	$uploadProgramPath = Resolve-Path -Path "..\..\..\..\Utils\UploadPowerBiReport\bin\Debug\" -ErrorAction Stop
}
catch 
{
	Write-Host "Upload Program Path not found"
    return
}


$studyProtocol1Id = "5681DFB1-CF49-4DD6-B576-E5CB4A46849B".ToLower();
$studyProtocol1DisplayName = "Eta ePRO Study";

$studyProtocol2Id = "EAE574D7-9351-48A5-888D-9397B3422C24".ToLower();
$studyProtocol2DisplayName = "N of 1 EDC Integration Study";

$contentManagerId = "26657865-DF19-444E-BC2E-1BCAABC39FA2".ToLower();
$nurseId = "863DE40C-D041-49CB-894C-6D72A5E1EFEB".ToLower();
$dataManagerId = "2B8021C8-8CBD-4AC5-A269-F24462761F9A".ToLower();
$physicianId = "86BC687A-7EC0-4263-9A9D-87A61690D698".ToLower();
$helpDeskId = "D1BF5F0E-61E0-48A8-BD83-0480DD52CEB3".ToLower();
$participantPersonnelManagerId = "DEACB10D-CBC3-49EB-BD55-EEA274308B3B".ToLower();
$participantManagerId = "01FA12FB-2C70-41F3-B400-4DCA127682A1".ToLower();
$systemAdministratorId = "76589308-DB8C-4983-AEE2-8DC235652E13".ToLower();
$nof1ManagerId = "E052CA67-3885-4F65-BEE4-30DD15CFA18C".ToLower();
$userAdministratorId = "29527DD7-61D6-4315-AB0C-27D1A411C10E".ToLower();
#$edcCoordinatorId = "BE42B849-DD9C-4494-8188-F3CD6DE1C6D4".ToLower();
#$eproCoordinatorId = "8D76ACCD-949D-4428-BE87-8A2533A146D1".ToLower();
#$personnelManagerId = "B2CA0D37-B591-4144-A622-6FA002A43A81".ToLower();
#$studyManagerId = "96470784-184B-4A61-9312-6D4F91BB5B7D".ToLower();

# Get the $bearer token and the http $headers Pa$$w0rd_Nof1V2
$return = & ((Split-Path $MyInvocation.InvocationName) + "\AuthenticateUser.ps1") 
if ($return[0] -ne 0)
{
    Write-Host "Error authenticating user. Script ending.";
    return;
}
$bearer = $return[1];
$headers = $return[2];

$url1 = $urlbase + "report/upload/";
$url2 = $urlbase + "report";

##################################################################################
$reportName = "Bounce Back Email";
$reportFile = "BounceBackEmail.pbix";
$reportDescription = "Lists emails that have been rejected due to error on receiving side.  Lists reason for bouncing, and associated email address.";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "true";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "true";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1") 

##################################################################################
$reportName = "Electronic Signature";
$reportFile = "Signature.pbix";
$reportDescription = "Lists history of electronic signature.";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "true";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "true";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1") 

##################################################################################
$reportName = "Participant Heat Map";
$reportFile = "ParticipantHeatMap.pbix";
$reportDescription = "Displays all participant locations.";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "false";
$participantDashboardReport = "true";
$participantManagementWorkspaceReport = "true";
$siteDashboardParticipantProfileReport = "true";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "false";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

##################################################################################
$reportName = "Participant Heat Map All Studies";
$reportFile = "ParticipantHeatMapAllStudies.pbix";
$reportDescription = "Displays all participant locations for all studies";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "true";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "true";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

##################################################################################
$reportName = "Participant Questionnaire Audit Trail";
$reportFile = "AuditReportParticipant.pbix";
$reportDescription = "Audit Trail";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "false";
$participantDashboardReport = "true";
$participantManagementWorkspaceReport = "true";
$siteDashboardParticipantProfileReport = "true";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "false";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

###################################################################################
$reportName = "Participant Clinical Summary";
$reportFile = "PatientClinicalSummary.pbix";
$reportDescription = "Shows Height and Dose, Weight and Dose";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "false"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "false";
$participantDashboardReport = "true";
$participantManagementWorkspaceReport = "true";
$siteDashboardParticipantProfileReport = "true";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "false";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

###################################################################################
$reportName = "Physician Listing Report";
$reportFile = "PhysicianListingReport.pbix";
$reportDescription = "Lists all physicians across all studies.";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "true";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "true";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

##################################################################################
$reportName = "Questionnaire Audit Trail";
$reportFile = "AuditReport.pbix";
$reportDescription = "Shows all edits made to Questionnaires, who made the edits, when, and why.";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "true";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "true";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

#################################################################################
$reportName = "Questionnaire Compliance Report";
$reportFile = "Questionnaire Compliance.pbix";
$reportDescription = "Questionnaire compliance for all study sites and participants.";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "false"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "true";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "true";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

#################################################################################
$reportName = "Questionnaire Response Report";
$reportFile = "EproResponses.pbix";
$reportDescription = "All responses to all questionnaires for all participants";
clear
# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "true";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "false";
$viewReportsListReport = "true";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

##################################################################################
$reportName = "Site Data Download";
$reportFile = "SiteDataDownload.pbix";
$reportDescription = "Shows Demographic, Primary Therapy, and Vitals";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "false"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "false";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "true";
$viewReportsListReport = "false";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

##################################################################################
$reportName = "Study Site Questionnaire Audit Trail Report";
$reportFile = "AuditReportSiteDashboard.pbix";
$reportDescription = "Audit Trail Report for the Study Site";

# study protocol
$studyProtocol1 = "true"; #ETA
$studyProtocol2 = "true"; #LAM

# roles
$contentManager = "true";
$nurse = "true";
$dataManager = "true";
$physician = "true";
$helpDesk = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$systemAdministrator = "true";
$nof1Manager = "true";
$userAdministrator = "true";

# deployment options
$featuredReport = "false";
$participantDashboardReport = "false";
$participantManagementWorkspaceReport = "false";
$siteDashboardParticipantProfileReport = "false";
$siteDashboardSiteProfileReport = "true";
$viewReportsListReport = "false";
$mobileReport = "false";

$response = & ((Split-Path $MyInvocation.InvocationName) + "\UploadReport.ps1")

return;