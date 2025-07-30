param subnets array // Array of { name, prefix, vnetName, nsgInfo, deligationInfo }
param routeTableId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name:  subnets[0].vnetName  
}

@batchSize(1)
resource subnetRoutes 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = [for i in range(0, length(subnets)): if (subnets[i].name != 'GatewaySubnet' && subnets[i].name != 'AzureFirewallSubnet') {
  parent: vnet 
  name: subnets[i].name
  properties: {
    addressPrefix: subnets[i].prefix
    routeTable: { id: routeTableId }
  }
}]

output routeId string = subnetRoutes[0].id
output routeName string = subnetRoutes[0].name
