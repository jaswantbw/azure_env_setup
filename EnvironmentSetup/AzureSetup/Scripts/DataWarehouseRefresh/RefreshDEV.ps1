Function LogWrite
{
   Param ([string]$logstring)

   $dateTime = GET-DATE -format s;
   Add-content $logfile -value ($dateTime + "`t" + $logstring);
}

$DatabasePassword = "BF85nmWkbMQCEDjCXHkp";
$DatabaseServer = "nof1health-nof1-v220-sql.database.windows.net";
$Nof1Database = "nof1-v220-nof1-dev";
$DwDatabase = "nof1-v220-dw-dev";
$DatabaseUserName = "nof1health-nof1-v220-sql";

$NoviDatabasePassword = "a514OdTJXR82QT1ekxfB";
$NoviDatabaseServer = "nof1health-novi-shared.database.windows.net";
$NoviDatabase = "NoviSurvey";
$NoviDatabaseUserName = "noviadmin";
$NoviOrganizationName = "Nof1V2";
$NoviFolderName = "Default";

$processStartDate = (GET-DATE);
$baseUrl = "https://nof1-v220-api-dev.azurewebsites.net/";
$logDate = GET-DATE -Format s;
$logDate = ($logDate -replace ':', '') -replace '-', '';
$path = Split-Path $MyInvocation.MyCommand.Path;
$scriptName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.ps1', '';
$timeout = 300;
Write-Host $path;
Write-Host $scriptName;

$logfile = $path + "\" + $scriptName + "_" + $logDate + ".log";

LogWrite ("Begin Refresh Data Warehouse from " + $scriptName);
<#
#########################################################################################
# truncate Nof1 from data warehouse
$startDate = (GET-DATE);
Write-Host "Truncate nof1 data from data warehouse";
$results = Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DwDatabase -Username $DatabaseUserName -Password $DatabasePassword -Query "EXEC SysETL.DeleteDataWarehouseData 0, 1, 0"
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for Truncate nof1 from data warehouse: " + $elapsedTime);

#########################################################################################
# Set up the system user
$startDate = (GET-DATE);
Write-Host "Set the system user";
& ($path + "\..\DataInitialization\SetSystemUser.ps1") 
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for Set the system user: " + $elapsedTime);

#########################################################################################
#$startDate = (GET-DATE);
#$api = "study/dataWarehouse/index/all";
#$url = $baseUrl + $api;
#Write-Host $url;
#Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
#$endDate = (GET-DATE);
#$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
#LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "userAccount/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "organization/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "organization/studysite/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "personnel/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "subject/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);


Write-Host "Personnel and Subjects need to complete before continuing.";

Read-Host "Press any key to continue";


#########################################################################################
$startDate = (GET-DATE);
$api = "userRegistration/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "notification/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "organization/studySite/member/effectiveClaimOverride/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);
<#
#########################################################################################
$startDate = (GET-DATE);
$api = "organization/studySite/roleClaimOverride/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "organization/studySite/prohibitedRole/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "signature/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "subjectGroup/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "survey/response/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
$startDate = (GET-DATE);
$api = "notification/survey/response/dataWarehouse/index/all";
$url = $baseUrl + $api;
Write-Host $url;
Invoke-RestMethod -Uri $Url -Method Post -TimeoutSec $timeout;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for " + $api + ": " + $elapsedTime);

#########################################################################################
# truncate odm data from data warehouse
$startDate = (GET-DATE);
Write-Host "Truncate odm data from data warehouse";
$results = Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DwDatabase -Username $DatabaseUserName -Password $DatabasePassword -Query "EXEC SysETL.DeleteDataWarehouseData 1, 0, 0"
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for Truncate odm data from data warehouse: " + $elapsedTime);
#>
#########################################################################################
# repopulate odm data in data warehouse
$startDate = (GET-DATE);
Write-Host "Repopulate odm data in data warehouse";
$results = Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DwDatabase -Username $DatabaseUserName -Password $DatabasePassword -QueryTimeout 0 -Query "EXEC SysETL.ReloadODMBatches"
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Elapsed Time for Repopulate odm data in data warehouse: " + $elapsedTime);
<#
#########################################################################################
# run ssis package to extract and load survey metadata
$startDate = (GET-DATE);
Write-Host "Extract and load survey metadata";
$dtsxPath = Split-Path -Path $path -Parent
$dtsxPath = Split-Path -Path $dtsxPath -Parent
$dtsxPath = Split-Path -Path $dtsxPath -Parent
$dtsxPath = Split-Path -Path $dtsxPath -Parent
$program = "C:\Program Files\Microsoft SQL Server\120\DTS\Binn\DTEXEC.EXE";
$program = "DTEXEC.EXE";

$cmd = $program ;
$cmd = $cmd + " /FILE `"\`"" + $dtsxPath + "\Utils\Nof1Health.Utilities.SSIS_NoviStudyBuild\Novi_Nof1_ODMExtract.dtsx\`"`"";

$cmd = $cmd + " /CONNECTION `"\`"Nof1_DB_Source\`"`"`;`"\`"Data Source=$DatabaseServer`;User ID=$DatabaseUserName`;Password=$DatabasePassword`;Initial Catalog=$Nof1Database`;Provider=SQLNCLI11.1`;Persist Security Info=True`;Auto Translate=False`;\`"`"";
$cmd = $cmd + " /CONNECTION `"\`"Nof1_DW_Target\`"`"`;`"\`"Data Source=$DatabaseServer`;User ID=$DatabaseUserName`;Password=$DatabasePassword`;Initial Catalog=$DwDatabase`;Provider=SQLNCLI11.1`;Persist Security Info=True`;Auto Translate=False`;\`"`"";
$cmd = $cmd + " /CONNECTION `"\`"NoviSurvey_Source\`"`"`;`"\`"Data Source=$NoviDatabaseServer`;User ID=$NoviDatabaseUserName`;Password=$NoviDatabasePassword`;Initial Catalog=$NoviDatabase`;Provider=SQLNCLI11.1`;Persist Security Info=True`;Auto Translate=False`;\`"`" ";
$cmd = $cmd + " /CHECKPOINTING OFF ";
$cmd = $cmd + " /REPORTING EW ";
$cmd = $cmd + " /SET `"\`"\Package.Variables[FolderName].Value\`"`"`;$NoviFolderName";
$cmd = $cmd + " /SET `"\`"\Package.Variables[OrganizationName].Value\`"`"`;$NoviOrganizationName"; 
#$cmd = "`"" + $cmd + "`"";

$cmd | Out-File RefreshDevSsis.bat -Width 2000 -Encoding ascii;
"pause" | Out-File RefreshDevSsis.bat -Width 2000 -Append -Encoding ascii;

Start-Process RefreshDEVSsis.bat -Verb runAs;
$endDate = (GET-DATE);
$elapsedTime = NEW-TIMESPAN -Start $startDate -End $endDate
LogWrite ("Extract and load survey metadata: " + $elapsedTime);


#########################################################################################
$elapsedTime = NEW-TIMESPAN -Start $processStartDate -End $endDate
LogWrite ("Elapsed Time for RefreshDEV: " + $elapsedTime);

return;
#>
