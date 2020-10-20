Param(
  [string] [Parameter(Mandatory=$true)] $CustomerIdentifier,
  [string] [Parameter(Mandatory=$true)] $Environment,
  [int] [Parameter(Mandatory=$true)] $EnvironmentNumber
)

$ErrorActionPreference = "Stop"

# The shared secret to connect to the 'nof1-digitalinfuzion-bridge-1' virtual network.
$bridge1SharedKey = "GakZRoYGDvx2WJX9B6oU"

# Set the current directory to avoid a problem: PowerShell throws an error when starting jobs 
# when the current directory is a network share.
# This assumes $PSScriptRoot is not a network share.
[environment]::CurrentDirectory = $PSScriptRoot


# Names of existing resources.
$environmentResourceGroupName = "$CustomerIdentifier-$Environment"
$sharedResourceGroupName = "$CustomerIdentifier-shared"
$virtualNetworkName = "$CustomerIdentifier-network-$Environment"

# Names of new resources.
$virtualGatewayName = "$CustomerIdentifier-gateway-virtual-$Environment"
$localGatewayName = "$CustomerIdentifier-gateway-local-$Environment"
$gatewayPublicIPName = "$CustomerIdentifier-gateway-ip-$Environment"
$gatewayIPConfigurationName = "$CustomerIdentifier-gateway-ip-config-$Environment"


# Get the existing resource group.
$environmentResourceGroup = Get-AzureRmResourceGroup -Name $environmentResourceGroupName
$environmentResourceGroupLocation = $environmentResourceGroup.Location


# Create a public IP address for the gateways.
$gatewayPublicIP = Get-AzureRmPublicIpAddress -Name $gatewayPublicIPName -ResourceGroupName $environmentResourceGroupName -ErrorAction SilentlyContinue

if ($gatewayPublicIP) {
    Write-Host "Gateway public IP '$($gatewayPublicIP.Name)' already exists."
}
else {
    Write-Host "Creating gateway public IP '$($gatewayPublicIPName)'..."
    $gatewayPublicIP = New-AzureRmPublicIpAddress -Name $gatewayPublicIPName -ResourceGroupName $environmentResourceGroupName -Location $environmentResourceGroupLocation -AllocationMethod Dynamic
}

# Get the existing network configuration.
$virtualNetwork = Get-AzureRmVirtualNetwork -Name "$virtualNetworkName" -ResourceGroupName $environmentResourceGroupName
$gatewaySubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $virtualNetwork

$virtualGateway = Get-AzureRmVirtualNetworkGateway -Name $virtualGatewayName -ResourceGroupName $environmentResourceGroupName -ErrorAction SilentlyContinue
if ($virtualGateway) {
    Write-Host "Virtual network gateway '$($virtualGateway.Name)' already exists."
}
else {
    # The gateway IP configuration is not persisted independently from the VPN connection, so it must be created each time.
    $gatewayIPConfiguration = New-AzureRmVirtualNetworkGatewayIpConfig -Name $gatewayIPConfigurationName -SubnetId $gatewaySubnet.Id -PublicIpAddressId $gatewayPublicIP.Id

    # Create a virtual network gateway. This gateway contains the VPN connection.
    # The gateway may take a long time to create (45 minutes or more, according to the docs).
    Write-Host "Creating virtual network gateway '$virtualGatewayName'. This may take 45 minutes or more..."
    $virtualGateway = New-AzureRmVirtualNetworkGateway -Name $virtualGatewayName -ResourceGroupName $environmentResourceGroupName -Location $environmentResourceGroupLocation `
        -IpConfigurations $gatewayIPConfiguration -GatewayType Vpn -VpnType RouteBased -GatewaySku Basic
}

# Create a local gateway.
# The local gateway represents the DIFZ network inside the resource group's network.
$localGateway = Get-AzureRmLocalNetworkGateway -Name $localGatewayName -ResourceGroupName $environmentResourceGroupName -ErrorAction SilentlyContinue
if ($localGateway) {
    Write-Host "Local gateway '$($localGateway.Name)' already exists."
}
else {
    Write-Host "Creating local gateway '$($localGatewayName)'. This may take a few minutes..."
    $localGateway = New-AzureRmLocalNetworkGateway -Name $localGatewayName -ResourceGroupName $environmentResourceGroupName `
        -Location $environmentResourceGroupLocation -AddressPrefix "192.168.$($EnvironmentNumber).0/24" -GatewayIpAddress $gatewayPublicIP.IpAddress
}

# We need to create two VPN connections.
# 1 -- the connection from the environment VIRTUAL gateway to the difz-bridge-1 LOCAL gateway.
# 2 -- the connection from the environment LOCAL gateway to the difz-bridge-1 VIRTUAL gateway.

$connection1Name = "$virtualGatewayName-to-difz-bridge-1-local"
$connection2Name = "difz-bridge-1-virtual-to-$localGatewayName"

# The reason for multiple DIFZ "bridge" networks is because each virtual network has a limit on the number
# of VPN connections that are allowed.

# Connection #1: environment VIRTUAL to difz-bridge-1 LOCAL
$connection1 = Get-AzureRmVirtualNetworkGatewayConnection -Name $connection1Name -ResourceGroupName $environmentResourceGroupName -ErrorAction SilentlyContinue
if ($connection1) {
    Write-Host "Connection #1 already exists."
}
else {
    Write-Host "Creating VPN connection #1 (environment virtual to DIFZ local)..."
    $difzBridge1LocalGateway = Get-AzureRmLocalNetworkGateway -Name "nof1-bridge-1-and-digital-infuzion-local" -ResourceGroupName "nof1-digitalinfuzion-bridge-1"
    $connection1 = New-AzureRmVirtualNetworkGatewayConnection -Name "$virtualGatewayName-to-difz-bridge-1-local" -ResourceGroupName $environmentResourceGroupName `
        -Location $environmentResourceGroupLocation -VirtualNetworkGateway1 $virtualGateway -LocalNetworkGateway2 $difzBridge1LocalGateway `
        -ConnectionType IPsec -RoutingWeight 10 -SharedKey $bridge1SharedKey
}

# Connection #2: environment LOCAL to difz-bridge-1 VIRTUAL
$connection2 = Get-AzureRmVirtualNetworkGatewayConnection -Name $connection2Name -ResourceGroupName $environmentResourceGroupName -ErrorAction SilentlyContinue
if ($connection2) {
    Write-Host "Connection #2 already exists."
}
else {
    Write-Host "Creating VPN connection #2 (environment local to DIFZ virtual)..."
    $difzBridge1VirtualGateway = Get-AzureRmVirtualNetworkGateway -Name "nof1-digitalinfuzion-bridge-1-gateway" -ResourceGroupName "nof1-digitalinfuzion-bridge-1"
    $connection2 = New-AzureRmVirtualNetworkGatewayConnection -Name "difz-bridge-1-virtual-to-$localGatewayName" -ResourceGroupName $environmentResourceGroupName `
        -Location $environmentResourceGroupLocation -VirtualNetworkGateway1 $difzBridge1VirtualGateway -LocalNetworkGateway2 $localGateway `
        -ConnectionType IPsec -RoutingWeight 10 -SharedKey $bridge1SharedKey
}


# Finally, set the virtual network's DNS servers to DIFZ's DNS servers.
Write-Host "Setting virtual network's DNS servers to DIFZ's DNS servers..."
$virtualNetwork.DhcpOptions.DnsServers = "10.0.0.5"
$virtualNetwork.DhcpOptions.DnsServers += "10.0.0.4"
Set-AzureRmVirtualNetwork -VirtualNetwork $virtualNetwork
