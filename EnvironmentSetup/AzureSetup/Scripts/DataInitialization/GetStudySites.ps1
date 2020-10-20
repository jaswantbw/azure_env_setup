###################################################################################
# Get-Entity
function Get-Entity()
{
    Invoke-RestMethod -Method Get -Uri $url -Headers $headers
}

###################################################################################
# Get the list of existing study sites
$studySites = Get-Entity -url $url

return $studySites;