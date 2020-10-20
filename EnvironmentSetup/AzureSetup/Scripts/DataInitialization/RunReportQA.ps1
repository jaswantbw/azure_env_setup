$Environment = "QA";
$urlBase = "https://nof1-v200-api-qa.azurewebsites.net/";
#$urlBase = "http://localhost:55075/";

$DatabasePassword = "BF85nmWkbMQCEDjCXHkp";
$DatabaseServer = "nof1health-nof1-v220-sql.database.windows.net";
$Nof1Database = "nof1-v200-nof1-qa";
$DwDatabase = "nof1-v200-dw-qa";
$DatabaseUserName = "nof1health-nof1-v220-sql";

try
{
	$reportPath = Resolve-Path -Path "..\..\..\..\Portal\Reports\QA\" -ErrorAction Stop
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
 
$studyProtocol1Id = "DC6D8283-0E66-494C-B623-D47E2E5B7239".ToLower();
$studyProtocol1DisplayName = "Theta EDC Study";

$studyProtocol2Id = "9FCA09D8-E9B2-4C4E-A3F5-1A501F9EB543".ToLower();
$studyProtocol2DisplayName = "Theta EDC Study";

$contentManagerId = "0A8E28AD-BF05-4B8A-A9D0-42BC84317E19".ToLower();
$nurseId = "69F2CB57-A42B-407A-ABB7-D18D3CF84321".ToLower();
$dataManagerId = "D90C6360-0FD5-4146-840C-DC482CD5F51D".ToLower();
$physicianId = "E8A66449-823F-4C7E-A1CC-4568C4C6421B".ToLower();
$helpDeskId = "28D69C33-7FFD-42F0-BF11-9E9A6EDF5D08".ToLower();
$participantPersonnelManagerId = "0EF5F2CE-0CAB-4B38-A63C-644A9A963A1D".ToLower();
$participantManagerId = "28113732-39E7-4054-8F7B-D50B962C98BB".ToLower();
$systemAdministratorId = "BA1BA485-F1DE-4D66-8B04-D106695B72E4".ToLower();
$nof1ManagerId = "152C3970-9901-4354-959B-D7D9A35DCDDC".ToLower();
$userAdministratorId = "DC134A7F-5C46-402E-8042-BF1A1C5F2FEE".ToLower();
#$edcCoordinatorId = "64BCD1C1-F61A-42F9-B88C-1059A1111348".ToLower();
#$eproCoordinatorId = "498F4D17-0333-4C7A-87CD-1E8D390A5EC1".ToLower();
#$personnelManagerId = "B2CA0D37-B591-4144-A622-6FA002A43A81".ToLower();
#$studyManagerId = "11462C4A-E968-4F3B-BA8D-3B6175FF6D24".ToLower();

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "false"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "false"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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

# study protocol
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "false"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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
$studyProtocol1 = "true"; #THE
$studyProtocol2 = "true"; #NOF1

# roles
$contentManager = "true";
$dataManager = "true";
$edcCoordinator = "true";
$eproCoordinator = "true";
$helpDesk = "true";
$nof1Manager = "true";
$nurse = "true";
$participantPersonnelManager = "true";
$participantManager = "true";
$personnelManager = "true";
$physician = "true";
$studyManager = "true";

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