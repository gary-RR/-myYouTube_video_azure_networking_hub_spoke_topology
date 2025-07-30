type subnetType = {
  name: string
  prefix: string
}

type vmCommonSettingsType = {
  adminUsernam: string
  patchMode: string
  rebootSetting: string
}

param location string=resourceGroup().location
param vnetAddressPrefixe string
param hubSubnets object[] 
param vnetName string
param createGateway bool=false
param appName string
param vpnClientAddressPrefix string
param dnsLLbel string='cosmoapps'
param creatApplicationGateway bool=false

module hubVnet './create_vnet.bicep'={
  name: 'hubVnet'
  params: {
    location: location
    vnetName: vnetName    
    subnets: hubSubnets
    vnetAddressPrefixes: vnetAddressPrefixe    
  }  
}

var gatewaySubnetID= ((createGateway) ? hubVnet.outputs.subnets[1].id : '')

module creatAppGateway 'create_app_gateway.bicep' = if(creatApplicationGateway) {
  name: 'creatAppGatewayy'
  params: {
    location: location
    appGatewayName: 'gateway1'
    appGatewayPublicIpName: 'cosmos-app-gateway'
    appGatewaySubnetName: hubSubnets[2].name
    backendPoolIps: ['10.2.5.16']
    vnetName: vnetName
    dnsLabel: dnsLLbel
  }
}

module vpn './create_vpn_gateway.bicep' = if(createGateway) {
  name: 'vpn'
  params: {
    appName: appName
    vpnClientAddressPrefix: vpnClientAddressPrefix
    vpnGatewaySubnetId: gatewaySubnetID
  }
} 

output vnetName string=hubVnet.outputs.vnetName
output vnetID string=hubVnet.outputs.vnetId
output gatewaySubnetID string=gatewaySubnetID
output vpnGateWayName string = (createGateway ? (vpn.outputs.vpnGateWayName ?? '') : '')

output vpnGateWayId string= ((createGateway) ? (vpn.outputs.gatewayId ?? '') : '')
output appGatewayId string=((creatApplicationGateway) ? (creatAppGateway.outputs.appGatewayID ?? '') : '')
output appGatewayFQDN string=((creatApplicationGateway) ? (creatAppGateway.outputs.appGatewayFQDN ?? '') : '')

// output vmPrivateIPAddress string=createVm.outputs.vmPrivateIPAddress
