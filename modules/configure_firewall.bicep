
type subnetType = {
  name: string
  prefix: string
  nsgInfo: object 
  deligationInfo: object 
  vnetName: string
}

type vnetInfoType = {
  name: string
  location: string
  subnets: subnetType[]
  prefix: string
  tags: object
}

// === Parameters ===
param region string
param ipConfigurations array   // Contain's firewall's IP configurations: [{ name, subnetId, privateIpAddress }]
param firewallName string
param firewallSubnetPrefix string // Firewall subnet prefix
param localFirewallPrivateIp string // Local firewall private IP
param peerFirewallPrivateIp string // Remote (peer) firewall private IP
param peerVnetAddressPrefix string // Remote hub VNet prefix
param localHUbVnetInfo vnetInfoType
param localSpokesVnetsInfo vnetInfoType[] // Spoke VNet info: [{ name, addressPrefix, subnets: [{ name, addressPrefix }] }]
param peerHubVnetInfo vnetInfoType// object // vnetInfo // Address prefix of peer hub VNet
param remoteSpokeVnetInfo vnetInfoType[] // Spoke VNet info: [{ name, addressPrefix, subnets: [{ name, addressPrefix }] }]
param vpnClientAddressPrefix string = '172.16.201.0/24'


// === Variables ===
var flattenedLocalSpokesVnets = [for vnet in localSpokesVnetsInfo: vnet]
var allLocalVnets = union(flattenedLocalSpokesVnets, [localHUbVnetInfo])

var flattenedRemoteSpokesVnets = [for vnet in remoteSpokeVnetInfo: vnet]
var allRemoteVnets = union(flattenedRemoteSpokesVnets, [peerHubVnetInfo])


// === Resources ===
// Existing VNet reference
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: localHUbVnetInfo.name
}

// Update Firewall with new rules
resource firewall 'Microsoft.Network/azureFirewalls@2023-11-01' = {
  name: firewallName
  location: region
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: ipConfigurations
    networkRuleCollections: [
      {
        name: 'networkRules'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            // 
            {
              name: 'allow-all-cross-region'
              sourceAddresses: ['*']
              destinationAddresses: ['*']
              destinationPorts: ['*']
              protocols: ['Any']
            }
            {
              name: 'allow-vpn-traffic'
              sourceAddresses: [vpnClientAddressPrefix]
              destinationAddresses: ['*']
              destinationPorts: ['*']
              protocols: ['Any']
            }           
          ]
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'appRules'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-azure-services'
              sourceAddresses: ['*'] //sourceAddressesForAppRule
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*.azure.com'
                '*.microsoft.com'
              ]
            }
          ]
        }
      }
    ]
  }
}


resource crossRegionRouteTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: '${region}-rt'
  location: region  
  properties: {
    routes: [
      {
        name: 'rt-rule-for-${peerHubVnetInfo.name}'
        properties: {
          addressPrefix: peerVnetAddressPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: peerFirewallPrivateIp
        }
      }
      {
        name: 'default-to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}


//Associate Route Table with AzureFirewallSubnet
resource firewallSubnetRoute 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: hubVnet
  name: 'AzureFirewallSubnet' 
  properties: {
    addressPrefix: firewallSubnetPrefix
    routeTable: {
      id: crossRegionRouteTable.id
    }
  }  
}

//@batchSize(1)
module addRmoteSpokesToRouteTable 'create_vnet_route.bicep' = [for vnet in allRemoteVnets: {
  name: 'addRmoteSpokesRouteTable-${vnet.name}'
  params: {
    vnet: vnet
    routeTablesName:crossRegionRouteTable.name
    nextHopType: 'VirtualAppliance'
    setNextHopIpAddress: true
    nextHopIpAddress: peerFirewallPrivateIp
  } 
}]

resource setDefaultGateWay 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'firewall-rt-spoke-to-peered-region-${region}'
  location: region
  properties: {
    routes: [
      {
        name: 'dg'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: localFirewallPrivateIp
        }
      }
    ]  
  }
}


//Module loop for subnet route config
module setSubnetDeaultGateWayRouteModules 'set_subnet_route.bicep' = [for vnet in allLocalVnets: {
  name: 'setSubnetRoutes-${vnet.name}'
  params: {
    subnets: vnet.subnets
    routeTableId:setDefaultGateWay.id
  }
  dependsOn: [
    firewall   
  ]
}]
