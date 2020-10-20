###################################################################################
# Update-Report
function Update-Report()
{
#Param ([System.Collections.Hashtable]$headers, [System.Collections.Hashtable]$body, [string]$url, [string]$filename)

$fileName = $reportPath.ToString() + $reportFile;
$contentType = 'multipart/form-data';

Write-Host "infile: " $filename
Write-Host "url1: " $url1
Write-Host "reportName: " $reportName
$id = "";

$step = 1;

$program = $uploadProgramPath.ToString() + "UploadPowerBiReport.exe -u='$url1' -r='$reportName' -f='$fileName' -b='$bearer'";
Try
{
    $out = Invoke-Expression $program
    $reportUrl = $out[0];
    $reportBiId = $out[1];

    Write-Host "reportUrl: " $reportUrl
    Write-Host "reportBiId: " $reportBiId

    $fail = $reportUrl.StartsWith("System"); 

    if ($fail)
    {
        Write-Host "Error in step $step.";
        Write-Host "$reportUrl";
        $rc = 1;
        return $rc, $id;
    }

    $step = 2;
    Write-Host "url2: " $url2

    $ReportStudyProtocols = '    "ReportStudyProtocols": [';

    if ($studyProtocol1.ToLower() -eq "true")
    {
        $ReportStudyProtocols = $ReportStudyProtocols + '
        {{
            "StudyProtocolId": "{0}",
            "Id": null
        }}' -f $studyProtocol1Id, $studyProtocol1DisplayName;
        
        if ($studyProtocol2.ToLower() -eq "true")
        {
            $ReportStudyProtocols = $ReportStudyProtocols + ',';
        }

    }
    
   if ($studyProtocol2.ToLower() -eq "true")
    {
        $ReportStudyProtocols = $ReportStudyProtocols + '
        {{
            "StudyProtocolId": "{0}",
            "Id": null
        }}' -f $studyProtocol2Id, $studyProtocol2DisplayName;
    }
    $ReportStudyProtocols = $ReportStudyProtocols + ']'

    $roles = New-Object System.Collections.ArrayList;
    if ($contentManager.ToLower() -eq "true") { $roles.Add('"'+$contentManagerId+'"'); }
    if ($dataManager.ToLower() -eq "true") { $roles.Add('"'+$dataManagerId+'"'); }
    #if ($edcCoordinator.ToLower() -eq "true") { $roles.Add('"'+$edcCoordinatorId+'"'); }
    #if ($eproCoordinator.ToLower() -eq "true") { $roles.Add('"'+$eproCoordinatorId+'"'); }
    if ($helpDesk.ToLower() -eq "true") { $roles.Add('"'+$helpDeskId+'"'); }
    if ($nof1Manager.ToLower() -eq "true") { $roles.Add('"'+$nof1ManagerId+'"'); }
    if ($nurse.ToLower() -eq "true") { $roles.Add('"'+$nurseId+'"'); }
    if ($participantPersonnelManager.ToLower() -eq "true") { $roles.Add('"'+$participantPersonnelManagerId+'"'); }
    if ($participantManager.ToLower() -eq "true") { $roles.Add('"'+$participantManagerId+'"'); }
    #if ($personnelManager.ToLower() -eq "true") { $roles.Add('"'+$personnelManagerId+'"'); }
    if ($physician.ToLower() -eq "true") { $roles.Add('"'+$physicianId+'"'); }
    #if ($studyManager.ToLower() -eq "true") { $roles.Add('"'+$studyManagerId+'"'); }
	#if ($systemAdministrator.ToLower() -eq "true") { $roles.Add('"'+$systemAdministratorId+'"'); }
    #if ($userAdministrator.ToLower() -eq "true") { $roles.Add('"'+$userAdministratorId+'"'); }

    $roleList = ($roles|group|Select -ExpandProperty Name) -join ",";
    $roleList = '"RolesWithAccess": [ ' + $roleList + ' ]'

    $body = '
{{
    "Description": "{10}",
    "Extensions": {{
        "deploymentLocations": {{
            "featured": {2},
            "participantDashboard": {3},
            "participantManagementWorkspace": {4},
            "siteDashboardParticipantProfile": {5},
            "siteDashboardSiteProfile": {6},
            "viewReportsList": {7},
            "mobile": {11}
            }}
        }},
    "Name": "{1}",
    {8},
    "ReportUrl": "{0}",
    {9}
}}' -f $reportUrl, $reportName, $featuredReport, $participantDashboardReport, $participantManagementWorkspaceReport, $siteDashboardParticipantProfileReport, $siteDashboardSiteProfileReport, $viewReportsListReport, $reportStudyProtocols, $roleList, $reportDescription, $mobileReport;

    Write-Host "body: " $body
    $out = Invoke-RestMethod -Uri $Url2 -Method Post -Headers $headers -Body $body -ContentType 'application/json';
}
Catch
{
    Write-Host "Error in step $step." 
    $rc = 1;
    return $rc, $id;
}

return;
}


Update-Report
