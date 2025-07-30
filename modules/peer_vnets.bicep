param sourceVnetName string
param destinationVnetName string
param createGateway bool=false

resource sourceVnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing ={
  name: sourceVnetName
}

resource destinationVnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing ={
  name: destinationVnetName
}

resource sourceVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01'= {
  parent: sourceVnet 
  name: '${sourceVnetName}-to-${destinationVnetName}'   
  properties: {
     allowForwardedTraffic: true
     allowVirtualNetworkAccess: true
     allowGatewayTransit: createGateway ? true : false
     remoteVirtualNetwork: {
      id: destinationVnet.id        
    } 
  }
}

resource destinationVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01'= {
  parent: destinationVnet  
  name: '${destinationVnetName}-to-${sourceVnetName}'
  properties: {
     allowForwardedTraffic: true
     allowVirtualNetworkAccess: true    
     useRemoteGateways: createGateway ? true : false 
     allowGatewayTransit: true
     remoteVirtualNetwork: {
      id: sourceVnet.id
   } 
  }
  dependsOn: [
    sourceVnetPeering
  ]
}

