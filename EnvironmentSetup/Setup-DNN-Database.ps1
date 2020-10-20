# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile
)

$ErrorActionPreference = "Stop"


# Create a hash table for the parameters.
$parameters = @{}

# Populate the parameters hash table with values from the parameter file(s).
$parameterFile = (Get-Content $TemplateParameterFile) -join "`n" | ConvertFrom-Json
$parameterObject = $parameterFile.parameters

$parameterObject | Get-Member -MemberType NoteProperty | ForEach-Object {
    $key = [string]$_.Name
    $value = [string]$parameterObject."$key".value

    $parameters[$key] = $value
}

# Add the current IP address to the SQL Server firewall.
$resourceGroupName = "$($parameters.customerIdentifier)-$($parameters.environment)"
$sqlServerName = "$($parameters.customerIdentifier)-sql-$($parameters.environment)"
$dnnDatabaseName = "$($parameters.customerIdentifier)-dnn-$($parameters.environment)"


# Use 'ipify.org' to get the client IP. This may need to change if this service becomes unavailable.
$ip = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json'

$firewallRule = Get-AzureRmSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $sqlServerName | where StartIpAddress -eq $ip.ip
if ($firewallRule -eq $null) {
    Write-Host "Creating firewall rule for current client IP ($($ip.ip))."
    New-AzureRmSqlServerFirewallRule -FirewallRuleName "ClientIP_$($ip.ip)" `
        -StartIpAddress $ip.ip -EndIpAddress $ip.ip `
        -ServerName $sqlServerName `
        -ResourceGroupName $resourceGroupName
}


# Check if the DNN database exists. If not, import it from a known backup and do some final setup.

$dnnDatabase = Get-AzureRmSqlDatabase -ServerName $sqlServerName -DatabaseName $dnnDatabaseName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if ($dnnDatabase -eq $null) {
    Write-Host "The DNN database ('$dnnDatabaseName') was not found. Creating & setting up the database..."
    # Import the DNN database BACPAC.

    # First, switch to the N of 1 Platform subscription and get the storage account key.
    $startingContext = Get-AzureRmContext

    Set-AzureRmContext -Subscription "N of 1 - Development"
    $bacpacStoargeAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName "Default-Storage-EastUS" -Name "nof1projectfiles").Value[0]

    Set-AzureRmContext -Subscription $startingContext.Subscription.Id

    $dnnInitialBacpacUri = "https://nof1projectfiles.blob.core.windows.net/platform/dnn-database-initial.bacpac"

    $sqlAdministratorPassword = ConvertTo-SecureString -AsPlainText $parameters.sqlAdministratorPassword -Force

    $importRequest = New-AzureRmSqlDatabaseImport `
        -ResourceGroupName $resourceGroupName `
        -DatabaseName $dnnDatabaseName `
        -ServerName $sqlServerName -Edition Basic -ServiceObjectiveName Basic -DatabaseMaxSizeBytes 32000000 `
        -StorageKeyType StorageAccessKey -StorageKey $bacpacStoargeAccountKey `
        -StorageUri $dnnInitialBacpacUri `
        -AdministratorLogin $parameters.sqlAdministratorUsername `
        -AdministratorLoginPassword $sqlAdministratorPassword

    Write-Host "Importing DNN database..."
    $importStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    while ($importStatus.Status -eq "InProgress")
    {
        $importStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
        Write-Host "." -NoNewline
        Start-Sleep -s 10
    }

    Write-Host "DNN database import complete."
    Write-Host "Moving DNN database into the elastic pool..."

    # Move the DNN database into the elastic pool.
    $elasticPoolName = "$($parameters.customerIdentifier)-sql-pool-$($parameters.environment)"
    Set-AzureRmSqlDatabase -ResourceGroupName $resourceGroupName `
        -ServerName $sqlServerName `
        -DatabaseName $dnnDatabaseName `
        -ElasticPoolName $elasticPoolName

    Write-Host "DNN database has been moved into the elastic pool."

    Write-Host "Creating DNN database user..."

    # Create a DNN database user.
    $dnnUserUsername = "$($parameters.customerIdentifier)-dnn-$($parameters.environment)"
    $dnnUserPassword = (([System.Web.Security.Membership]::GeneratePassword(40,0)) -replace "[^a-zA-Z0-9]", "").Substring(0,20)

    $adminConnectionString = "Data Source=$sqlServerName.database.windows.net;Initial Catalog=$dnnDatabaseName;User ID=$($parameters.sqlAdministratorUsername);Password=$($parameters.sqlAdministratorPassword)"

    $connection = New-Object System.Data.SqlClient.SqlConnection($adminConnectionString)
    $connection.Open()

    try {
        $commandText = "CREATE USER [$dnnUserUsername] WITH PASSWORD = '$dnnUserPassword';GRANT CONNECT TO [$dnnUserUsername];ALTER ROLE db_owner ADD MEMBER [$dnnUserUsername];"
        Write-Host $commandText
        $command = New-Object System.Data.SqlClient.SqlCommand($commandText, $connection)
        $command.ExecuteNonQuery()
    }
    finally {
        $connection.Close()
    }

    Write-Host "DNN database user created."

    # Save the DNN user credentials to the parameters file.
    $templateParameters = (Get-Content $TemplateParameterFile) | ConvertFrom-Json
    $templateParameters.parameters | Add-Member -Force dnnUserUsername @{ value = $dnnUserUsername }
    $templateParameters.parameters | Add-Member -Force dnnUserPassword @{ value = $dnnUserPassword }

    # Format the JSON file using JSON.NET, because the PowerShell formatting sucks.
    [Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
    $jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($templateParameters | ConvertTo-Json | Out-String))
    $formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
    $formattedJson | Out-File $TemplateParameterFile

    
    # Re-populate the parameters hash table with values from the parameter file, so the DNN credentials will be accessible.
    $parameterFile = (Get-Content $TemplateParameterFile) -join "`n" | ConvertFrom-Json
    $parameterObject = $parameterFile.parameters

    $parameterObject | Get-Member -MemberType NoteProperty | ForEach-Object {
        $key = [string]$_.Name
        $value = [string]$parameterObject."$key".value

        $parameters[$key] = $value
    }


    Write-Host "DNN database user credential has been added to the parameters file."
    Write-Host "The DNN database '$dnnDatabaseName' has been created and configured."
}
