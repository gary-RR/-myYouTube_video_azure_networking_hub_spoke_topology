type vmCommonSettingsType = {
  adminUsernam: string
  patchMode: string
  rebootSetting: string
}

type vnetInfo = {
  name: string
  addressPrefix: string
  tags: object
}


param hub1VnetLocation string ='westus'
param hub2VnetLocation string = 'eastus'
param location string = hub1VnetLocation

param spokesStaticVnetLocation string =  hub1VnetLocation
param spokesDynamicVnetLocation string = hub2VnetLocation

param staticSpoke1WestLocation string = spokesStaticVnetLocation
param staticSpoke2WestLocation string = spokesStaticVnetLocation 

param dynamicSpoke1EastLocation string=  spokesDynamicVnetLocation
param dynamicSpoke2EastLocation string = spokesDynamicVnetLocation

param principalId string
param appName string='cosmos'
param dnsLLbel string='cosmoapps'
param createGateway bool=false
param createHub1Vm bool=false
param createHub2Vm bool=false
param createStaticSpoke1Vm bool=false
param createStaticSpoke2Vm bool=false
param createDynamicSpoke1Vm bool=false
param createDynamicSpoke2Vm bool=false

param hub1VnetAddressPrefixe string= '10.1.0.0/16'
param hub2VnetAddressPrefixe string= '10.10.0.0/16'

param staticSpoke1WestUSVnetAddressPrefixe string= '10.2.0.0/16'
param staticSpoke2WestUSVnetAddressPrefixe string= '10.3.0.0/16'

param dynamicSpoke1EastUSVnetAddressPrefixe string= '10.4.0.0/16'
param dynamicSpoke2EastUSVnetAddressPrefixe string= '10.8.0.0/16'

param vpnClientAddressPrefix string='172.16.201.0/24'
param resourceGroupName string 

param sshHub1Vm1KeyName string
param sshHub2Vm1KeyName string
param sshStaticSpoke1Vm1KeyName string
param sshStaticSpoke2Vm1KeyName string
param sshDynamicSpoke1Vm1KeyName string
param sshDynamicSpoke2Vm1KeyName string
param vm1LinuxName string='vm1-hub1'
param vm2LinuxName string='vm1-static-spoke1'
param vm3LinuxName string='vm1-static-spoke2'
param vm4LinuxName string='vm1-dynamic-spoke1'
param vm5LinuxName string='vm1-dynamic-spoke2'
param vm6LinuxName string='vm1-hub2'

param creatApplicationGateway bool=false

// Parameters for Hub1 Subnets
param hub1FrontendSubnetName string = 'utilitySubnet'
param hub1FrontendSubnetPrefix string = '10.1.1.0/24'


param hub1GatewaySubnetName string = 'GatewaySubnet'
param hub1GatewaySubnetPrefix string = '10.1.3.0/24'

param hub1FirewallSubnetName string = 'AzureFirewallSubnet'
param hub1FirewallSubnetPrefix string = '10.1.10.0/24'

// Parameters for Hub2 Subnets
param hub2FrontendSubnetName string = 'utilitySubnet'
param hub2FrontendSubnetPrefix string = '10.10.1.0/24'

param hub2GatewaySubnetName string = 'GatewaySubnet'
param hub2GatewaySubnetPrefix string = '10.10.3.0/24'

param hub2FirewallSubnetName string = 'AzureFirewallSubnet'
param hub2FirewallSubnetPrefix string = '10.10.6.0/24'

// Parameters for Static Spoke 1 Subnets
param staticSpoke1FrontendSubnetName string = 'frontendSubnet'
param staticSpoke1FrontendSubnetPrefix string = '10.2.1.0/24'

param staticSpoke1BackendSubnetName string = 'backendSubnet'
param staticSpoke1BackendSubnetPrefix string = '10.2.2.0/24'

// Parameters for Static Spoke 2 Subnets
param staticSpoke2FrontendSubnetName string = 'frontendSubnet'
param staticSpoke2FrontendSubnetPrefix string = '10.3.1.0/24'
param staticSpoke2BackendSubnetName string = 'backendSubnet'
param staticSpoke2BackendSubnetPrefix string = '10.3.2.0/24'

// Parameters for Dynamic Spoke 1 Subnets
param dynamicSpoke1FrontendSubnetName string = 'frontendSubnet'
param dynamicSpoke1FrontendSubnetPrefix string = '10.4.1.0/24'
param dynamicSpoke1BackendSubnetName string = 'backendSubnet'
param dynamicSpoke1BackendSubnetPrefix string = '10.4.2.0/24'

// Parameters for Dynamic Spoke 2 Subnets
param dynamicSpoke2FrontendSubnetName string = 'frontendSubnet'
param dynamicSpoke2FrontendSubnetPrefix string = '10.8.1.0/24'
param dynamicSpoke2BackendSubnetName string = 'backendSubnet'
param dynamicSpoke2BackendSubnetPrefix string = '10.8.2.0/24'

param vnetDNSZoneName string = 'galaxy.com'
param reverseDnsZoneName string= '10.in-addr.arpa'

//param routeInternetThroughFirewall bool = true

resource resouceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' existing = {
  name: resourceGroupName  
  scope: subscription()
}

param vmCommonSettings vmCommonSettingsType = {
  adminUsernam: 'gary'
  patchMode: 'AutomaticByPlatform'
  rebootSetting: 'IfRequired'
}

var resourceNameSuffix=uniqueString(resourceGroup().id)
var hub1VnetName= 'westHub-${appName}-${resourceNameSuffix}'
var hub2VnetName= 'eastHub-${appName}-${resourceNameSuffix}'
var staticSpoke1WestUSVnetName = 'staticSpoke1West-${appName}-${resourceNameSuffix}'
var staticSpoke2WestUSVnetName= 'staticSpoke2West-${appName}-${resourceNameSuffix}'
var dynamicSpoke1EastUSVnetName= 'dynamicSpoke1East-${appName}-${resourceNameSuffix}'
var dynamicSpoke2EastUSVnetName= 'dynamicSpoke2East-${appName}-${resourceNameSuffix}'
var westStaticNetworkGroupName='westStaticNetworkGroup-${appName}-${resourceNameSuffix}'
var eastDynamicNetworkGroupName='eastDynamicNetworkGroup-${appName}-${resourceNameSuffix}'
var virtualNetworManagerkName='virtualNetworManager-${appName}-${resourceNameSuffix}'
var staticWestGMember1Name='stat-westMember1-${appName}-${resourceNameSuffix}'
var staticWestMember2Name='stat-westMember2-${appName}-${resourceNameSuffix}'
var westUsconnectvityConfigName='westUsconnectivityConfig-${appName}-${resourceNameSuffix}'
var eastUsConnectivityConfigName='eastUsconnectivityConfig-${appName}-${resourceNameSuffix}'
var managedDeploymentUserName='hubSoke-topology-deployer-${appName}-${resourceNameSuffix}'

module assignUserJoinActionRole './modules/create_join_action_role.bicep' = {
  name: 'assignUserJoinActionRole'
  params: {
    principalId: principalId
  }
}

module assignNetworkContributoreRole './modules/assign_principal_contributor_access.bicep' = {
  name: 'assignNetworkContributoreRole'  
  params: {
    resourceGroupName: resourceGroup().name
    principalId: principalId
    principalType: 'User'
  }
}

var hub1Subnets = [
  {
    name: hub1FrontendSubnetName
    prefix: hub1FrontendSubnetPrefix
    vnetName: hub1VnetName
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
    name: hub1GatewaySubnetName
    prefix: hub1GatewaySubnetPrefix
    vnetName: hub1VnetName
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
    name: hub1FirewallSubnetName
    prefix: hub1FirewallSubnetPrefix
    vnetName: hub1VnetName
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

var hub2Subnets = [ 
  {
    name: hub2FrontendSubnetName
    prefix: hub2FrontendSubnetPrefix
    vnetName: hub2VnetName
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
    name: hub2GatewaySubnetName
    prefix: hub2GatewaySubnetPrefix
    vnetName: hub2VnetName
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
    name: hub2FirewallSubnetName
    prefix: hub2FirewallSubnetPrefix
    vnetName: hub2VnetName
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

var westUsHubVnetsInfo= {
    name:  hub1VnetName 
    location: hub1VnetLocation
    subnets: hub1Subnets
    prefix: hub1VnetAddressPrefixe    
    tags: {}
}

var eastUsHubVnetsInfo= {
    name: hub2VnetName
    location: hub2VnetLocation
    subnets: hub2Subnets
    prefix: hub2VnetAddressPrefixe
    tags: {}
}  


var staticSpoke1WestSubnets = [
  {
    name: staticSpoke1FrontendSubnetName
    prefix: staticSpoke1FrontendSubnetPrefix
    vnetName: staticSpoke1WestUSVnetName
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
    name: staticSpoke1BackendSubnetName
    prefix: staticSpoke1BackendSubnetPrefix
    vnetName: staticSpoke1WestUSVnetName
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

var staticSpoke2WestSubnets = [
  {
    name: staticSpoke2FrontendSubnetName
    prefix: staticSpoke2FrontendSubnetPrefix
    vnetName: staticSpoke2WestUSVnetName
    nsgInfo:  {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }
  }
  {
    name: staticSpoke2BackendSubnetName
    prefix: staticSpoke2BackendSubnetPrefix
    vnetName: staticSpoke2WestUSVnetName
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

var dynamicSpoke1EastSubnets = [
  {
    name: dynamicSpoke1FrontendSubnetName
    prefix: dynamicSpoke1FrontendSubnetPrefix
    vnetName: dynamicSpoke1EastUSVnetName
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
    name: dynamicSpoke1BackendSubnetName
    prefix: dynamicSpoke1BackendSubnetPrefix
    vnetName: dynamicSpoke1EastUSVnetName
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

var dynamicSpoke2EastSubnets = [
  {
    name: dynamicSpoke2FrontendSubnetName
    prefix: dynamicSpoke2FrontendSubnetPrefix
    vnetName: dynamicSpoke2EastUSVnetName
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
    name: dynamicSpoke2BackendSubnetName
    prefix: dynamicSpoke2BackendSubnetPrefix
    vnetName: dynamicSpoke2EastUSVnetName
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

var westUsSpokeVnetsInfo= [  
  {
    name: staticSpoke1WestUSVnetName 
    location: staticSpoke1WestLocation
    subnets: staticSpoke1WestSubnets
    prefix: staticSpoke1WestUSVnetAddressPrefixe
    tags: {}
  }
  {
    name: staticSpoke2WestUSVnetName
    location: staticSpoke2WestLocation
    subnets: staticSpoke2WestSubnets
    prefix: staticSpoke2WestUSVnetAddressPrefixe
    tags: {}
  }  
]

var eastUsSpokeVnetsInfo= [  
  {
    name: dynamicSpoke1EastUSVnetName 
    location: dynamicSpoke1EastLocation
    subnets: dynamicSpoke1EastSubnets
    prefix: dynamicSpoke1EastUSVnetAddressPrefixe
    tags: {
      dynamicMember: 'true'
    }
  }
  {
    name: dynamicSpoke2EastUSVnetName
    location: dynamicSpoke2EastLocation
    subnets: dynamicSpoke2EastSubnets
    prefix: dynamicSpoke2EastUSVnetAddressPrefixe
    tags: {
      dynamicMember: 'true'
    }
  }  
]

module hub1Vnet './modules/create_hub.bicep'={  
  name: 'hub-Vnet'
  scope: resouceGroup  
  params: {    
    appName: appName
    location: hub1VnetLocation
    vnetName: hub1VnetName
    hubSubnets: hub1Subnets
    vnetAddressPrefixe: hub1VnetAddressPrefixe 
    createGateway: createGateway 
    vpnClientAddressPrefix: vpnClientAddressPrefix  
    dnsLLbel: dnsLLbel 
    creatApplicationGateway: creatApplicationGateway
  }  
}

module hub2Vnet './modules/create_hub.bicep'={
  name: 'hub2-Vnet'
  scope: resouceGroup  
  params: {    
    appName: appName
    location: hub2VnetLocation
    vnetName: hub2VnetName
    hubSubnets: hub2Subnets
    vnetAddressPrefixe: hub2VnetAddressPrefixe 
    createGateway: false // createGateway 
    vpnClientAddressPrefix: vpnClientAddressPrefix  
    dnsLLbel: dnsLLbel 
    creatApplicationGateway: creatApplicationGateway
  }  
  dependsOn: [
    hub1Vnet
  ]
} 

// Deploy hub1 firewall
module hub1Firewall './modules/create_firewall.bicep' = {
  name: 'deployHub1Firewall'
  params: {
    vnetName: hub1VnetName
    region: hub1VnetLocation    
    firewallSubnetName: hub1FirewallSubnetName
    firewallName: 'hub1-firewall'
  }
  dependsOn: [
    hub1Vnet
    hub2Vnet
  ]
}

// Deploy hub2 firewall
module hub2Firewall './modules/create_firewall.bicep' = {
  name: 'deployHub2Firewall'
  params: {
    vnetName: hub2VnetName
    region: hub2VnetLocation    
    firewallSubnetName: hub2FirewallSubnetName
    firewallName: 'hub2-firewall'
  }
  dependsOn: [
    hub1Firewall
  ]
}


module createSpokeVnets './modules/create_spokes.bicep'= {
  name: 'createSpokeVnets'
  scope: resouceGroup
  params: {    
    spokeVnetsInfo: concat(westUsSpokeVnetsInfo, eastUsSpokeVnetsInfo)
  }
}

module peerHub1AndHub2Vnets './modules/peer_vnets.bicep' = {
  name: 'peerHub1AndHub2Vnets'
  params: {
    sourceVnetName: hub1Vnet.outputs.vnetName
    destinationVnetName: hub2Vnet.outputs.vnetName  
    createGateway: createGateway
  } 
}

module vnetDNSZone './modules/create_dns_zone.bicep' = {
  name: 'vnetDNSZone'
  params: {      
    vnetInfo: [
      {
        name: hub1VnetName
        id: hub1Vnet.outputs.vnetID   
        registrationEnabled: true             
      }
      {
        name: hub2VnetName
        id: hub2Vnet.outputs.vnetID
        registrationEnabled: true
      }
      {
        name: staticSpoke1WestUSVnetName 
        id: createSpokeVnets.outputs.aggregatedVnets[0].vnetId
        registrationEnabled: true
      }
      {
        name: staticSpoke2WestUSVnetName
        id: createSpokeVnets.outputs.aggregatedVnets[1].vnetId
        registrationEnabled: true
      }
      {
        name: dynamicSpoke1EastUSVnetName
        id: createSpokeVnets.outputs.aggregatedVnets[2].vnetId
        registrationEnabled: true
      }    
      {
        name: dynamicSpoke2EastUSVnetName
        id: createSpokeVnets.outputs.aggregatedVnets[3].vnetId
        registrationEnabled: true
      }
    
    ]
    dnsZoneName: vnetDNSZoneName   
  }
}

module createvNetReverseDnsZone './modules/create_reverse_dns_zone.bicep' = {
  name: 'createReverseDnsZone'
  params: {    
    vnetInfo: [
      {
        name: hub1VnetName
        id: hub1Vnet.outputs.vnetID
      }
      {
        name: staticSpoke1WestUSVnetName 
        id: createSpokeVnets.outputs.aggregatedVnets[0].vnetId
      }
      {
        name: staticSpoke2WestUSVnetName
        id: createSpokeVnets.outputs.aggregatedVnets[1].vnetId
      }
      {
        name: dynamicSpoke1EastUSVnetName
        id: createSpokeVnets.outputs.aggregatedVnets[2].vnetId
      }    
      {
        name: dynamicSpoke2EastUSVnetName
        id: createSpokeVnets.outputs.aggregatedVnets[3].vnetId
      }
    ]
    reverseDnsZoneName: reverseDnsZoneName
  }
}


module policy 'modules/create_dynamic_membership_policy.bicep' = {
  scope: subscription()
  name: 'dynamicPolicy'
  params: {
    networkGroupId: networkManager.outputs.eastDynamicNetworkGroupId 
    resourceGroupName: resourceGroupName
  }
}

module networkManager './modules/create_virtual_network_manager.bicep'= {
  name: 'networkManager-x'
  scope: resouceGroup
  params: {
    hub1VnetID: hub1Vnet.outputs.vnetID
    hub2VnetID: hub2Vnet.outputs.vnetID
    westStaticNetworkGroupName: westStaticNetworkGroupName
    eastDynamicNetworkGroupName: eastDynamicNetworkGroupName
    virtualNetworManagerkName: virtualNetworManagerkName
    westUsconnectvityConfigName: westUsconnectvityConfigName
    eastUsconnectvityConfigName: eastUsConnectivityConfigName
    managedDeploymentUserName: managedDeploymentUserName
    location: location
    createGateway: createGateway
    westStaticVnetGroups: [
      {
        GroupName: staticWestGMember1Name
        vnetName: createSpokeVnets.outputs.aggregatedVnets[0].vnetName
      }
      {
        GroupName: staticWestMember2Name
        vnetName: createSpokeVnets.outputs.aggregatedVnets[1].vnetName
      }
    ]
  }
  dependsOn: [
    assignUserJoinActionRole
    assignNetworkContributoreRole
    // assignVnetsContributorRole  
  ]
}

module deployWestUsNetworkManagerConnectivityConfig './modules/deploy_script.bicep' = {
  name: 'ds-${location}-deployWestUsNetworkManagerConnectivityConfig'
  scope: resouceGroup  
  dependsOn: [
    policy
  ]
  params: {
    location: location
    userAssignedIdentityId: networkManager.outputs.userAssignedIdentityId
    configurationId: networkManager.outputs.westUsconnectivityConfigurationId
    configType: 'Connectivity'
    networkManagerName: networkManager.outputs.networkManagerName
    deploymentScriptName: 'ds-${location}-connectivity-Configs'
  }
}


module hub1FirewallConfig './modules/configure_firewall.bicep' = {
  name: 'configureHub1Firewall'
  params: {    
    region: hub1VnetLocation
    ipConfigurations: hub1Firewall.outputs.ipConfigurations    
    firewallName: 'hub1-firewall'
    firewallSubnetPrefix: hub1FirewallSubnetPrefix
    localFirewallPrivateIp: hub1Firewall.outputs.firewallPrivateIp
    peerFirewallPrivateIp:  hub2Firewall.outputs.firewallPrivateIp
    peerVnetAddressPrefix: hub2VnetAddressPrefixe
    localHUbVnetInfo: westUsHubVnetsInfo
    localSpokesVnetsInfo: westUsSpokeVnetsInfo 
    peerHubVnetInfo: eastUsHubVnetsInfo  
    remoteSpokeVnetInfo: eastUsSpokeVnetsInfo
    vpnClientAddressPrefix: vpnClientAddressPrefix   
  }
  dependsOn: [
    createHub1Vm1
    hub1Firewall
    hub2Firewall
  ]  
}


module hub2FirewallConfig './modules/configure_firewall.bicep' = {
  name: 'configureHub2Firewall'
  params: {    
    region: hub2VnetLocation 
    firewallName: 'hub2-firewall'
    firewallSubnetPrefix: hub2FirewallSubnetPrefix
    localFirewallPrivateIp: hub2Firewall.outputs.firewallPrivateIp
    peerFirewallPrivateIp:  hub1Firewall.outputs.firewallPrivateIp
    ipConfigurations: hub2Firewall.outputs.ipConfigurations
    peerVnetAddressPrefix: hub1VnetAddressPrefixe
    localHUbVnetInfo: eastUsHubVnetsInfo
    localSpokesVnetsInfo: eastUsSpokeVnetsInfo
    peerHubVnetInfo: westUsHubVnetsInfo  
    remoteSpokeVnetInfo: westUsSpokeVnetsInfo
    vpnClientAddressPrefix: vpnClientAddressPrefix    
  }
  dependsOn: [
    createHub2Vm1
    hub1Firewall
    hub2Firewall
    hub1FirewallConfig
  ]  
}

module deployEastUsNetworkManagerConnectivityConfig './modules/deploy_script.bicep' = {
  name: 'ds-${hub2VnetLocation}-deployEastUsNetworkManagerConnectivityConfig'
  scope: resouceGroup  
  dependsOn: [
    policy
  ]
  params: {
    location: hub2VnetLocation
    userAssignedIdentityId: networkManager.outputs.userAssignedIdentityId
    configurationId: networkManager.outputs.eastUsconnectivityConfigurationId
    configType: 'Connectivity'
    networkManagerName: networkManager.outputs.networkManagerName
    deploymentScriptName: 'ds-${hub2VnetLocation}-connectivity-Configs'
  }
}

module createHub1Vm1 './modules/create_vm.bicep' = if (createHub1Vm) {
  name: '${vm1LinuxName}-module'
  scope: resouceGroup
  params: {
    sshKeyName: sshHub1Vm1KeyName
    vmCommonSettings: vmCommonSettings
    vmLinuxName: '${vm1LinuxName}-${appName}-${resourceNameSuffix}' 
    vnetName: hub1Vnet.outputs.vnetName 
    location: hub1VnetLocation 
    subnetName: hub1FrontendSubnetName
  }
}

module createHub2Vm1 './modules/create_vm.bicep' = if (createHub2Vm) {
  name: '${vm6LinuxName}-module'
  scope: resouceGroup
  params: {
    sshKeyName: sshHub2Vm1KeyName
    vmCommonSettings: vmCommonSettings
    vmLinuxName: '${vm6LinuxName}-${appName}-${resourceNameSuffix}' 
    vnetName: hub2Vnet.outputs.vnetName 
    location: hub2VnetLocation 
    subnetName: hub2FrontendSubnetName
  }
}

module createStaticSpoke1Vm1 './modules/create_vm.bicep' = if (createStaticSpoke1Vm) {
  name: '${vm2LinuxName}-module'
  scope: resouceGroup
  params: {
    sshKeyName: sshStaticSpoke1Vm1KeyName
    vmCommonSettings: vmCommonSettings
    vmLinuxName: '${vm2LinuxName}-${appName}-${resourceNameSuffix}'
    vnetName: createSpokeVnets.outputs.aggregatedVnets[0].vnetName
    location: staticSpoke1WestLocation
  }
}

module createStaticSpoke2Vm1 './modules/create_vm.bicep' = if (createStaticSpoke2Vm) {
  name: '${vm3LinuxName}-module'
  scope: resouceGroup
  params: {
    sshKeyName: sshStaticSpoke2Vm1KeyName
    vmCommonSettings: vmCommonSettings
    vmLinuxName: '${vm3LinuxName}-${appName}-${resourceNameSuffix}'
    vnetName: createSpokeVnets.outputs.aggregatedVnets[1].vnetName
    location: staticSpoke2WestLocation  
  }
}

module createDynamicSpoke1Vm1 './modules/create_vm.bicep' = if (createDynamicSpoke1Vm) {
  name: '${vm4LinuxName}-module'
  scope: resouceGroup
  params: {
    sshKeyName: sshDynamicSpoke1Vm1KeyName
    vmCommonSettings: vmCommonSettings
    vmLinuxName: '${vm4LinuxName}-${appName}-${resourceNameSuffix}'
    vnetName: createSpokeVnets.outputs.aggregatedVnets[2].vnetName
    location: dynamicSpoke1EastLocation  
  }
}

module createDynamicSpoke2Vm1 './modules/create_vm.bicep' = if (createDynamicSpoke2Vm) {
  name: '${vm5LinuxName}-module'
  scope: resouceGroup
  params: {
    sshKeyName: sshDynamicSpoke2Vm1KeyName
    vmCommonSettings: vmCommonSettings
    vmLinuxName: '${vm5LinuxName}-${appName}-${resourceNameSuffix}'
    vnetName: createSpokeVnets.outputs.aggregatedVnets[3].vnetName
    location: dynamicSpoke2EastLocation   
  }
}

module createHub1Vm1PtrRecord './modules/create_dns_ptr_record.bicep' = if (createHub1Vm) {
  name: 'createHub1Vm1PtrRecord'
  scope: resouceGroup
  params: {
    reverseZoneName: createvNetReverseDnsZone.outputs.reverseDnsZoneName 
    vmIpAddress: createHub1Vm1.outputs.vmPrivateIPAddress
    vmName: createHub1Vm1.outputs.vmName    
  }  
} 

module createHub2Vm1PtrRecord './modules/create_dns_ptr_record.bicep' = if (createHub2Vm) {
  name: 'createHub2Vm1PtrRecord'
  scope: resouceGroup
  params: {
    reverseZoneName: createvNetReverseDnsZone.outputs.reverseDnsZoneName 
    vmIpAddress: createHub2Vm1.outputs.vmPrivateIPAddress
    vmName: createHub2Vm1.outputs.vmName    
  }  
}

module createStaticSpoke1Vm1PtrRecord './modules/create_dns_ptr_record.bicep' = if (createStaticSpoke1Vm) {
  name: 'createSpoke1Vm2PtrRecord'
  scope: resouceGroup
  params: {
    reverseZoneName: createvNetReverseDnsZone.outputs.reverseDnsZoneName 
    vmIpAddress: createStaticSpoke1Vm1.outputs.vmPrivateIPAddress
    vmName: createStaticSpoke1Vm1.outputs.vmName
  }
}

module createStaticSpoke2Vm1PtrRecord './modules/create_dns_ptr_record.bicep' = if (createStaticSpoke2Vm) {
  name: 'createStaticSpoke2Vm1PtrRecord'
  scope: resouceGroup
  params: {
    reverseZoneName: createvNetReverseDnsZone.outputs.reverseDnsZoneName 
    vmIpAddress: createStaticSpoke2Vm1.outputs.vmPrivateIPAddress
    vmName: createStaticSpoke2Vm1.outputs.vmName
  }
}

module createDynamicSpoke1Vm1PtrRecord './modules/create_dns_ptr_record.bicep' = if (createStaticSpoke2Vm) {
  name: 'createDynamicSpoke1Vm1PtrRecord'
  scope: resouceGroup
  params: {
    reverseZoneName: createvNetReverseDnsZone.outputs.reverseDnsZoneName 
    vmIpAddress: createDynamicSpoke1Vm1.outputs.vmPrivateIPAddress
    vmName: createDynamicSpoke1Vm1.outputs.vmName
  }
}

module createDynamicSpoke2Vm1PtrRecord './modules/create_dns_ptr_record.bicep' = if (createStaticSpoke2Vm) {
  name: 'createDynamicSpoke2Vm1PtrRecord'
  scope: resouceGroup
  params: {
    reverseZoneName: createvNetReverseDnsZone.outputs.reverseDnsZoneName 
    vmIpAddress: createDynamicSpoke2Vm1.outputs.vmPrivateIPAddress
    vmName: createDynamicSpoke2Vm1.outputs.vmName
  }
}

module configHubVm1DnsSetting './modules/configuer_vm_dns_settings.bicep' = if (createHub1Vm) {
  name:'config_vm1'
  scope: resouceGroup
  params: {
    vmName: createHub1Vm1.outputs.vmName
    location: hub1VnetLocation
    domains: vnetDNSZoneName
  }
}

module configStaticSpoke1Vm1DnsSetting './modules/configuer_vm_dns_settings.bicep' = if (createStaticSpoke1Vm) {
  name:'config_vm2'
  scope: resouceGroup
  params: {
    vmName: createStaticSpoke1Vm1.outputs.vmName
    location: staticSpoke1WestLocation
    domains: vnetDNSZoneName
  }
}

module configStaticSpoke2Vm1DnsSetting './modules/configuer_vm_dns_settings.bicep' = if (createStaticSpoke2Vm) {
  name:'config_vm3'
  scope: resouceGroup
  params: {
    vmName: createStaticSpoke2Vm1.outputs.vmName
    location: staticSpoke2WestLocation
    domains: vnetDNSZoneName
  }
}

module configDynamicSpoke1Vm1DnsSetting './modules/configuer_vm_dns_settings.bicep' = if (createDynamicSpoke1Vm) {
  name:'config_vm4'
  scope: resouceGroup
  params: {
    vmName: createDynamicSpoke1Vm1.outputs.vmName
    location: dynamicSpoke1EastLocation
    domains: vnetDNSZoneName
  }
}

module configDynamicSpoke2Vm1DnsSetting './modules/configuer_vm_dns_settings.bicep' = if (createDynamicSpoke2Vm) {
  name:'config_vm5'
  scope: resouceGroup
  params: {
    vmName: createDynamicSpoke2Vm1.outputs.vmName
    location: dynamicSpoke2EastLocation
    domains: vnetDNSZoneName
  }
}

output vpnGateWayName string=hub1Vnet.outputs.vpnGateWayName
output staticSpoke1WestUSVnetName string=createSpokeVnets.outputs.aggregatedVnets[0].vnetName
output staticSpoke1WestUSVnetID string=createSpokeVnets.outputs.aggregatedVnets[0].vnetId
output hub1Vm1PrivateIPAddress string= createHub1Vm ? createHub1Vm1.outputs.vmPrivateIPAddress : ''  
output hub2Vm1PrivateIPAddress string= createHub2Vm ? createHub2Vm1.outputs.vmPrivateIPAddress : ''
output staticSpoke1Vm1PrivateIPAddress string= createStaticSpoke1Vm ? createStaticSpoke1Vm1.outputs.vmPrivateIPAddress : ''
output staticSpoke2Vm1PrivateIPAddress string= createStaticSpoke2Vm ? createStaticSpoke2Vm1.outputs.vmPrivateIPAddress : '' 
output dynamicSpoke1Vm1PrivateIPAddress string= createDynamicSpoke1Vm ? createDynamicSpoke1Vm1.outputs.vmPrivateIPAddress : ''
output dynamicSpoke2Vm1PrivateIPAddress string= createDynamicSpoke2Vm ? createDynamicSpoke2Vm1.outputs.vmPrivateIPAddress : ''

output staticSpoke2WestUSVnetName string=createSpokeVnets.outputs.aggregatedVnets[1].vnetName

output hub1Vm1Name string= createHub1Vm ? createHub1Vm1.outputs.vmName : ''
output hub2Vm1Name string= createHub2Vm ? createHub2Vm1.outputs.vmName : ''
output staticSpoke1Vm1Name string= createStaticSpoke1Vm ? createStaticSpoke1Vm1.outputs.vmName : ''
output staticSpoke2Vm1Name string= createStaticSpoke2Vm ? createStaticSpoke2Vm1.outputs.vmName : '' 
output dynamicSpoke1Vm1Name string= createDynamicSpoke1Vm ? createDynamicSpoke1Vm1.outputs.vmName : ''
output dynamicSpoke2Vm1Name string= createDynamicSpoke2Vm ? createDynamicSpoke2Vm1.outputs.vmName : ''


