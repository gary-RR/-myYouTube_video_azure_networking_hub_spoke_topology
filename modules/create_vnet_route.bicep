type subnetType = {
  name: string
  prefix: string
  nsgInfo: object // { name: string, id: string }
  deligationInfo: object // { name: string, id: string }
  vnetName: string
}

type vnetInfoType = {
  name: string
  location: string
  subnets: subnetType[]
  prefix: string
  tags: object
}

param vnet vnetInfoType
param routeTablesName string
param nextHopType string  
param nextHopIpAddress string // next hop IP address for VirtualAppliance
param setNextHopIpAddress bool //= false // Flag to set next hop IP address

resource routeTable 'Microsoft.Network/routeTables@2023-11-01' existing = {
  name:  routeTablesName 
}

resource addVnetNextHop 'Microsoft.Network/routeTables/routes@2023-11-01' =  {
    name:  'rt-rule-for-${vnet.name}'
    parent: routeTable
    properties: union({      
      addressPrefix: vnet.prefix
      nextHopType: nextHopType
    }, setNextHopIpAddress ? {
      nextHopIpAddress: nextHopIpAddress
    } : {})
  }


output routeId string = addVnetNextHop.id
