Param(
  [string] [Parameter(Mandatory=$true)] $serverName,
  [string] [Parameter(Mandatory=$true)] $adminUsername,
  [string] [Parameter(Mandatory=$true)] $adminPassword,
  [string] [Parameter(Mandatory=$true)] $database,
  [string] [Parameter(Mandatory=$true)] $databasePassword
)

$ErrorActionPreference = "Stop"

# Create database logins.
$server = "tcp:$serverName.database.windows.net,1433"

$connectionString = "Server=$server;Database=$database;User ID=$adminUsername;Password=$adminPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection($connectionString)

$query = [System.IO.File]::ReadAllText(".\CreateSqlDbOwnerLogin.sql")
$command = New-Object -TypeName System.Data.SqlClient.SqlCommand($query, $connection)

$usernameParameter = New-Object -TypeName System.Data.SqlClient.SqlParameter("@Username", $database)
$command.Parameters.Add($usernameParameter)
$passwordParameter = New-Object -TypeName System.Data.SqlClient.SqlParameter("@Password", $databasePassword)
$command.Parameters.Add($passwordParameter)

$connection.Open()
$command.ExecuteNonQuery()
$connection.Close()

