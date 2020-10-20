Param(
[string]$B2CPath =  "..\..\..\..\Utils\CommandLineB2CAuth\bin\Debug"
 )

try
{
	$B2CPath =Resolve-Path -Path $B2CPath -ErrorAction stop
}
catch 
{
	write-host "B2C Path is not available."
	return
} 
 
if ($Environment -eq "QA")
{
    #QA
    $B2CTenant = "nof1v220b2cqa.onmicrosoft.com";
    $B2CApplicationId = "ce96aaa6-0966-489c-8f03-a7b2d840f0ff";
    $B2CApplicationName = "nof1-portal";
    $B2CPolicy = "B2C_1_nof1-qa-signin";
}

if ($Environment -eq "DEV")
{
    #DEV
    $B2CTenant = "nof1v220b2cdev.onmicrosoft.com";
    $B2CApplicationId = "dbcb9d1e-521e-4e58-a523-bf38a378f8e3";
    $B2CApplicationName = "nof1-portal";
    $B2CPolicy = "B2C_1_nof1-dev-signin";
}

###################################################################################
# Get the bearer value from an authenticated user
$b2c = "$B2CPath\CommandLineB2CAuth.exe -t='$B2CTenant' -a='$B2CApplicationId' -n='$B2CApplicationName' -p='$B2CPolicy'";
Try
{
    $bearer = Invoke-Expression $b2c
}
Catch
{
    Write-Host "User failed to authenticate. CommandLineB2CAuth was terminated."
    $rc = 1;
    return $rc, $bearer, $headers;
}

if ($bearer)
{
    $headers = @{
    "Authorization"="Bearer " + $bearer;
    "Content-Type"="application/json; charset=utf-8";
    }
    $rc = 0;
}
else
{
    Write-Host "User failed to authenticate."
    $rc = 1;
}
return $rc, $bearer, $headers;