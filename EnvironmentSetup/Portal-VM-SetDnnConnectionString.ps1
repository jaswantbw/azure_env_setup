# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] $PortalHomeDirectory = "C:\inetpub\wwwroot\nof1-portal",
  [string] [Parameter(Mandatory=$true)] $DnnDatabaseConnectionString,
  [string] $Timestamp # The timestamp parameter ensures the command text is unique, in case it needs to be run again.
)

$ErrorActionPreference = "Stop"


# Load up web.config into the XML parser.
$xml = New-Object xml
$xml.PreserveWhitespace = $true
$xml.Load("$PortalHomeDirectory\web.config")

# Update web.config with the DNN database connection string. 
$n1 = $xml.SelectSingleNode("configuration/connectionStrings/add")
$n1.connectionString = $DnnDatabaseConnectionString

$n2 = $xml.SelectSingleNode("configuration/appSettings/add[@key='SiteSqlServer']")
$n2.value = $DnnDatabaseConnectionString

$xml.Save("$PortalHomeDirectory\web.config")

iisreset
