###################################################################################
# Find-Entity
function Find-Entity()
{
    Param ([string]$name, [System.Object[]]$entity)
    #Write-Host Find-Entity
    #Write-Host "entity: " $entity
    #Write-Host "name: " $name
    $id = "";
    foreach ($item in $entity)
    {
        if ($item.Name -eq $name)
        {
            #Write-Host "itemid: " $item.Id 
            #Write-Host "itemName:" $item.Name $name
            $id = $item.Id
            break;
        }
    }
    return $id
}

###################################################################################
# Update-Entity
function Update-Entity()
{
Param ([System.Collections.Hashtable]$headers, [System.Collections.Hashtable]$body, [string]$url)
#Write-Host Update-Entity
#Write-Host "headers: " $headers
#Write-Host "body: " $body
#Write-Host "url: " $url

$json = ConvertTo-Json $body
Invoke-RestMethod -Method Post -Uri $url -Body $json -Headers $headers 
}

###################################################################################
# Main
$id = Find-Entity -name $name -entity $orgs
if ($id -ne "")
{
    # the organization was found, need to update it
    $body.Remove("Id");
    $body.Add("Id", $id);
    $url = $urlBase + "organization/" + $id + "/";
}
else
{
    # the organization was not found, need to insert it
    $url = $urlBase + "organization/"
}

Update-Entity -headers $headers -body $body -url $url

if ($id -eq "")
{
    $orgs = & ((Split-Path $MyInvocation.InvocationName) + "\GetOrganizations.ps1")
    $id = Find-Entity -name $name -entity $orgs
}

return;