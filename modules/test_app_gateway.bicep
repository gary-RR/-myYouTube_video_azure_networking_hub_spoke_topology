param location string =resourceGroup().location
param appName string='cosmo'
param staticSpoke1ProdVnetAddressPrefixe string= '10.2.0.0/16'
// param staticSpoke2ProdVnetAddressPrefixe string= '10.3.0.0/16'
// param dynamicSpoke1ProdVnetAddressPrefixe string= '10.4.0.0/16'
// param dynamicSpoke2ProdVnetAddressPrefixe string= '10.5.0.0/16'


var resourceNameSuffix=uniqueString(resourceGroup().id)
var staticSpoke1ProdName= 'staticSpoke1Prod-${appName}-${resourceNameSuffix}'
// var staticSpoke2ProdName= 'staticSpoke2Prod-${appName}-${resourceNameSuffix}'
// var dynamicSpoke1ProdName= 'dynamicSpoke1Prod-${appName}-${resourceNameSuffix}'
// var dynamicSpoke2ProdName= 'dynamicSpoke2Prod-${appName}-${resourceNameSuffix}'

var staticSpoke1ProdSubnets =[
  {
    name: 'frontendSubnet'
    prefix: '10.2.1.0/24' 
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }        
  }
  {
    name: 'appGateWaySubnet' 
    prefix: '10.2.2.0/24'  
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }      
  }
  {
    name: 'apiServerSubnetPrefix' 
    prefix: '10.2.3.0/24'  
    nsgInfo: {
      enable: false
      nsgId: null
    }  
    deligationInfo: {
      enable: true
      delegations: [{
        id: 'api-server'
        name: 'ipServer'
        properties: {
          serviceName: 'Microsoft.ContainerService/managedClusters'
        }
      }]
    }     
  } 
  {
    name: 'aksClusterSubnet' 
    prefix: '10.2.4.0/24'    
    nsgInfo: {
      enable: false
      nsgId: null
    }  
    deligationInfo: {
      enable: false
      delegations: [{}]
    }    
  } 
  {
    name: 'loadBalancerSubnet' 
    prefix: '10.2.5.0/24'    
    nsgInfo: {
      enable: false
      nsgId: null
    }  
    deligationInfo: {
      enable: false
      delegations: [{}]
    }    
  }         
]




var spokeVnetsInfo= [  
  {
    name: staticSpoke1ProdName
    subnets: staticSpoke1ProdSubnets
    prefix: staticSpoke1ProdVnetAddressPrefixe
    tags: {}
  }
]

module createSpokeVnets 'create_spokes.bicep'= {
  name: 'createSpokeVnets'
  //scope: resourceGroup()
  params: {
    location: location
    spokeVnetsInfo: spokeVnetsInfo
  }
}

module testAppGateway 'create_app_gateway_sample.bicep' = {
  name: 'testGateway'
  params: {
    location: location
    appGatewayName: 'gateway1'
    appGatewayPublicIpName: 'cosmos-app-gateway'
    appGatewaySubnetName: staticSpoke1ProdSubnets[1].name
   backendPoolIps: ['10.2.5.16']
    vnetName: staticSpoke1ProdName
  }
}

// resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
//   name: vnetName
//   location: location  
//   //tags: []  
//   properties: {    
//     addressSpace: {
//       addressPrefixes: [
//         spokeVnetsInfo[0].prefix
//       ]
//     }
//     subnets: [for subnet in  spokeVnetsInfo[0].subnets: {
//       name: subnet.name
//       properties: union({
//         addressPrefix: subnet.prefix
//       },
//       // Include the NSG configuration if enabled
//       subnet.nsgInfo.enable ? {
//         networkSecurityGroup: {
//           id: subnet.nsgInfo.nsgId
//         }
//       } : {},
//       // Include the delegation configuration if enabled
//       subnet.deligationInfo.enable ? {
//         delegations: [
//           {
//             //id: subnet.deligationInfo.delegations[0].id
//             name: subnet.deligationInfo.delegations[0].name
//             properties: {
//               serviceName: subnet.deligationInfo.delegations[0].properties.serviceName
//             }
//           }
//         ]
//       } : {})
//     }]    
//   }
// }


// resource vnet1 'Microsoft.Network/virtualNetworks@2023-04-01' =  {
//   name: spokeVnetsInfo[0].name
//   location: location
//   //tags: spokeVnetsInfo.tags  
//   properties: {    
//     addressSpace: {
//       addressPrefixes: [
//         spokeVnetsInfo[0].prefix
//       ]
//     }
//     subnets: [for subnet in spokeVnetsInfo[0].subnets: {
//       name: subnet.name
//       properties:  {
//         addressPrefix: subnet.prefix
        
//         networkSecurityGroup: subnet.nsgInfo.enable ? null : null
//       }
//     }]    
//   }
  
// }

// resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = { 
//   name: 'frontendSubnet' 
//   parent: vnet1 
// }


// resource subnetNsgAssociation 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
//   name: 'frontendSubnet'
//   parent: vnet1 
//   properties: union() 
//   // properties: {
//   //   networkSecurityGroup: {
//   //     id: 'nsgDenySshAccessToSubnet.id'
//   //   }
//   // }
// }

//output frontendSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetsInfo[0].name, 'frontendSubnet')

