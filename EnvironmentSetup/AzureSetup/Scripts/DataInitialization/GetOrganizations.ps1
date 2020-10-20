###################################################################################
# Get-Entity
function Get-Entity()
{
    Invoke-RestMethod -Method Get -Uri $url -Headers $headers
}

###################################################################################
# Get the list of existing organizations
$method = "organization";
$url = $urlBase + $method;
$orgs = Get-Entity -url $url

return $orgs;