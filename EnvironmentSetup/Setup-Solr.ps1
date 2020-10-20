# This script sets up Key Vault access for an Azure Active Directory application.

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateParameterFile,
  [string] [Parameter(Mandatory=$true)] $SolrVMHost,
  [string] [Parameter(Mandatory=$true)] $SolrVMUsername,
  [string] [Parameter(Mandatory=$true)] $SolrVMPassword,
  [int] $SolrInstancePort,
  [switch] $SkipEndpointCreation,
  [string] $ConfigurationDirectory = "..\Integration\Nof1Health.Integration.Solr\SolrConfiguration\v6.1.0"
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

$solrInstanceName = "$($parameters.customerIdentifier)-$($parameters.environment)"


# Attempt to determine the next Solr port, if one hasn't been specified.
if ($SolrInstancePort -eq 0) {
    $containers = & .\plink.exe $SolrVMUsername@$SolrVMHost -pw $SolrVMPassword "docker ps --format ""{{.Names}}--{{.Ports}}""" 
    $solrInstances = @{}
    $solrPorts = @()
    ([string]$containers).Split(' ') | % {
        $containerParts = $_ -split "--"

        # Get the port by reading the Docker output.
        $isMatch = $containerParts[1] -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:(?<Port>\d*)->8983/tcp"
        $solrPorts += $Matches.Port

        $solrInstances[$containerParts[0]] = $Matches.Port
    }


    $solrPorts = $solrPorts | Sort-Object
    
    # If there is any existing container that contains this solr instance name, use that port.
    foreach ($_ in $solrInstances.Keys) {
        if (([string]$_).Contains($solrInstanceName)) {
            $SolrInstancePort = $solrInstances[$_]
            break
        }
    }


    # If there is any existing container that contains the customer identifier, use the next available port from that series.
    if ($SolrInstancePort -eq 0) {
        foreach ($_ in $solrInstances.Keys) {
            if (([string]$_).Contains($parameters.customerIdentifier)) {
                $workingPort = $solrInstances[$_]
                while ($solrPorts.Contains($workingPort)) {
                    $workingPort++
                }
                break
            }
        }
    }
    

    # If there is still no existing container, use the next tens digit.
    if ($SolrInstancePort -eq 0) {
        $lastPort = $solrPorts[$solrPorts.Length - 1]
        $SolrInstancePort = ([Math]::Floor($lastPort/10) + 1) * 10
    }
}


$parameters.solrPort = $SolrInstancePort


if ($SkipEndpointCreation -ne $true) {
    # Check if the VM is a "Classic" VM. If so, add an endpoint for this port.
    Add-AzureAccount
    Select-AzureSubscription -SubscriptionName "DIFZ - N of 1 Services"
    $vmName = $SolrVMHost.Split('.')[0]
    $vm = Get-AzureVM -ServiceName $vmName -Name $vmName
    if ($vm -ne $null) {
    
        # The endpoint may already exist.
        $endpoint = ($vm | Get-AzureEndpoint -Name "solr-$solrInstanceName")
        if ($endpoint -eq $null) {
            Write-Host "Adding endpoint to Solr VM (classic)..."
            $vm | Add-AzureEndpoint -Name "solr-$solrInstanceName" -Protocol "tcp" -PublicPort $SolrInstancePort -LocalPort $SolrInstancePort | Update-AzureVM
            Write-Host "Successfully added endpoint to Solr VM (classic)."
        }
    }
}


# Create a YAML file for this Docker Solr deployment.
$solrYaml = Get-Content ".\solr-template.yaml"
$parameters.Keys | % {
    $key = $_
    $value = $parameters[$_]
    $solrYaml = $solrYaml.Replace("{$key}", $value)
}
$yamlFilename = "$solrInstanceName.yaml"
$solrYaml | Out-File -FilePath ".\$yamlFilename" -Force


# Create the Solr credentials. Create credentials files for this deployment.
$solrUsername = $solrInstanceName
$solrPassword = (([System.Web.Security.Membership]::GeneratePassword(40,0)) -replace "[^a-zA-Z0-9]", "").Substring(0,20)

$realmProperties = Get-Content "$ConfigurationDirectory/authentication/realm.properties"
$realmProperties = $realmProperties.Replace("{username}", $solrUsername).Replace("{password}", $solrPassword).Trim()
# Use ASCII encoding for the `realm.properties` because Powershell by default exports UTF8 with a BOM, which messes up the auth system parser.
$realmProperties | Out-File -FilePath "$ConfigurationDirectory/authentication/$solrInstanceName-realm.properties" -Encoding ascii


# Connect to the VM over SSH and create the directory. `mkdir -p` will succeed even if the directory already exists.
& .\plink.exe $SolrVMUsername@$SolrVMHost -pw $SolrVMPassword "mkdir -p ~/$solrInstanceName/cores && mkdir -p ~/$solrInstanceName/logs && cp ~/common/v6.1.0/* ~/$solrInstanceName/ && chmod -R 777 ~/$solrInstanceName"

# Upload the Solr configuration and the YAML file.
& .\WinSCP.com /ini=nul /command "open sftp://$($SolrVMUsername):$($SolrVMPassword)@$SolrVMHost -hostkey=*" `
    "cd" "cd $solrInstanceName/" `
    "option failonnomatch on" `
    "lcd ""$ConfigurationDirectory""" `
    "synchronize -permissions=777 remote .\cores ./cores/" `
    "put -permissions=777 .\authentication\*.keystore" `
    "put -permissions=777 -delete .\authentication\$solrInstanceName-realm.properties ./realm.properties" `
    "put -permissions=777 .\authentication\solr-jetty-context.xml" `
    "put -permissions=777 .\authentication\solr-override-web.xml" `
    "lcd ""$PSScriptRoot""" `
    "put -permissions=777 .\$solrInstanceName.yaml ./docker-compose.yaml" `
    "exit"


# Connect to the VM over SSH and start the Docker instance.
& .\plink.exe $SolrVMUsername@$SolrVMHost -pw $SolrVMPassword "cd ~/$solrInstanceName && docker-compose --file ./docker-compose.yaml up -d --force-recreate && docker ps -a"


# Save the Solr instance details to the parameters file.
$templateParameters = (Get-Content $TemplateParameterFile) | ConvertFrom-Json
$templateParameters.parameters | Add-Member -Force solrHost @{ value = $SolrVMHost }
$templateParameters.parameters | Add-Member -Force solrInstanceName @{ value = $solrInstanceName }
$templateParameters.parameters | Add-Member -Force solrUsername @{ value = $solrUsername }
$templateParameters.parameters | Add-Member -Force solrPassword @{ value = $solrPassword }
$templateParameters.parameters | Add-Member -Force solrPort @{ value = $SolrInstancePort }

# Format the JSON file using JSON.NET, because the PowerShell formatting sucks.
[Reflection.Assembly]::LoadFile("$PSScriptRoot\Newtonsoft.Json.dll")
$jobject = [Newtonsoft.Json.Linq.JObject]::Parse(($templateParameters | ConvertTo-Json | Out-String))
$formattedJson = $jobject.ToString([Newtonsoft.Json.Formatting]::Indented)
$formattedJson | Out-File $TemplateParameterFile

Write-Host "Solr parameters have been added to the parameters file."
