# This script creates the standard CosmosDB collections for an Nof1 v2.x environment.

# Before running this script in a PowerShell prompt:
# 1. Run Login-AzureRmAccount
# 2. Set the subscription by running Set-AzureRmContext -SubscriptionName "$$ SUBSCRIPTION NAME "

Param(
  [string] [Parameter(Mandatory=$true)] $SubscriptionName,
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

$CustomerIdentifier = $parameters.customerIdentifier
$EnvironmentName = $parameters.environment

az login
	
az account set --subscription $SubscriptionName
	
az cosmosdb database create `
    --db-name "$CustomerIdentifier-documents" `
    --name "$CustomerIdentifier-cosmosdb-$EnvironmentName" `
    --resource-group-name "$CustomerIdentifier-$EnvironmentName"
	
az cosmosdb collection create --collection-name "collection" --throughput 1000 --partition-key-path "/partitionKey" `
    --db-name "$CustomerIdentifier-documents" `
    --name "$CustomerIdentifier-cosmosdb-$EnvironmentName" `
    --resource-group-name "$CustomerIdentifier-$EnvironmentName"
	
az cosmosdb collection create --collection-name "phi" --throughput 400 `
    --db-name "$CustomerIdentifier-documents" `
    --name "$CustomerIdentifier-cosmosdb-$EnvironmentName" `
    --resource-group-name "$CustomerIdentifier-$EnvironmentName"

az cosmosdb collection create --collection-name "chat" --throughput 400 --partition-key-path "/partitionKey" `
    --db-name "$CustomerIdentifier-documents" `
    --name "$CustomerIdentifier-cosmosdb-$EnvironmentName" `
    --resource-group-name "$CustomerIdentifier-$EnvironmentName"
