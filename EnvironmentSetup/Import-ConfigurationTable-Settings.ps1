# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile,
  [switch] $DeleteAllExistingSettings
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

$context = New-AzureStorageContext -StorageAccountName $parameters.storageAccountName -StorageAccountKey $parameters.storageAccountKey -Protocol Https
$configurationTable = Get-AzureStorageTable -Name "Configuration" -Context $context -ErrorAction SilentlyContinue

if ($configurationTable -eq $null) {
  Write-Host "Creating Configuration table."
  $configurationTable = New-AzureStorageTable -Name "Configuration" -Context $context
}


# Get the portal VM host name.
$resourceGroupName = "$($parameters.customerIdentifier)-$($parameters.environment)"
$portalVmPublicIpName = "$($parameters.customerIdentifier)-portal-public-ip-$($parameters.environment)"
$portalVmPublicIp = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name $portalVmPublicIpName
$portalVmDomainName = $portalVmPublicIp.DnsSettings.Fqdn
$parameters.portalHost = $portalVmDomainName


# Fill the configuration settings from the template with parameter values.
$settingTemplates = (Get-Content "./configuration-template.json" | ConvertFrom-Json)
foreach ($settingTemplate in $settingTemplates) {
  $parameterRegexPattern = "{(\w+?)}"
  $matches = ([regex]$parameterRegexPattern).Matches($settingTemplate.settingValue)

  if ($matches.Count -gt 0) {

    foreach ($match in $matches) {
      $parameterName = [string]$match.Groups[1]
      $parameterValue = $parameters[$parameterName]
      if ($parameterValue -eq $null -or $parameterValue -eq "") {
        Write-Warning "Parameter value not found: '$parameterName'"
        $settingTemplate | Add-Member -Force requiresParameter $true
        continue
      }

      $parameterValue = $settingTemplate.settingValue -replace "{$parameterName}", $parameterValue
      $settingTemplate.settingValue = $parameterValue
    }
  }
}

# Populate the configuration table with all settings that have their parameters processed.
$processedSettings = ($settingTemplates | Where-Object {$_.requiresParameter -ne $true }) | Sort-Object @{e = { $_.partitionKey }}, @{e = { $_.rowKey }} 

# If we're replacing all existing settings, delete the existing rows.
if ($DeleteAllExistingSettings) {
  Write-Host "Deleting all existing rows."
  Get-AzureStorageTableRowAll -table $configurationTable | Remove-AzureStorageTableRow -table $configurationTable
}

# Get the existing rows. We'll update the ones that exist and create new ones if they don't exist.
$rows = Get-AzureStorageTableRowAll -table $configurationTable

foreach ($setting in $processedSettings | Select-Object) {
  $row = $rows | Where-Object {$_.PartitionKey -eq $setting.partitionKey -and $_.RowKey -eq $setting.rowKey }
  if ($row -eq $null) {
    Write-Host "Creating configuration row for $($setting.partitionKey):$($setting.rowKey)"
    $row = Add-StorageTableRow -table $configurationTable -partitionKey $setting.partitionKey -rowKey $setting.rowKey -property @{"SettingValue" = $setting.settingValue}
  }
  else {
    Write-Host "Updating configuration row for $($setting.partitionKey):$($setting.rowKey)"
        $row.SettingValue = $setting.settingValue
        $row = $row | Update-AzureStorageTableRow -table $configurationTable
    }
}