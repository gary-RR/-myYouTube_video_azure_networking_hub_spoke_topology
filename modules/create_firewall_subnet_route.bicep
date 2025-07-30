param subnets array // Array of { name, prefix, vnetName, nsgInfo, deligationInfo }
param routeTablesName string
param nextHopType string  //= 'VnetLocal' // Default to VnetLocal, can be overridden
param nextHopIpAddress string // next hop IP address for VirtualAppliance
param setNextHopIpAddress bool //= false // Flag to set next hop IP address

resource routeTable 'Microsoft.Network/routeTables@2023-11-01' existing = {
  name:  routeTablesName 
}

resource addFirewallRoute 'Microsoft.Network/routeTables/routes@2023-11-01' = [
  for i in range(0, length(subnets)): if (subnets[i].name != 'GatewaySubnet' && subnets[i].name != 'AzureFirewallSubnet') {
    name:  'rt-rule-for${subnets[i].name}'
    parent: routeTable
    properties: union({
      addressPrefix: subnets[i].prefix
      nextHopType: nextHopType
    }, setNextHopIpAddress ? {
      nextHopIpAddress: nextHopIpAddress
    } : {})
  }
]

output routeId string = addFirewallRoute[0].id
