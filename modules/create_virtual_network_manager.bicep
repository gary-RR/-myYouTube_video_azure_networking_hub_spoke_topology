type vnetGroupType = {
  GroupName: string
  vnetName: string
}

param location string=resourceGroup().location
param virtualNetworManagerkName string
param westStaticNetworkGroupName string
param eastDynamicNetworkGroupName string
param westStaticVnetGroups vnetGroupType[]
param hub1VnetID string
param hub2VnetID string
param westUsconnectvityConfigName string
param eastUsconnectvityConfigName string
param managedDeploymentUserName string
param userObjectId string='72a4e41f-6b55-4fce-befd-f1396ae6b981' // The deployer's Entra Id object ID
param createGateway bool=true
param isGlobal string='False' 
var useHubGateway= createGateway ? 'True' : 'False'

var networkContributoreRoleId=subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource virtualNetworkManager 'Microsoft.Network/networkManagers@2024-05-01'= {
  name: virtualNetworManagerkName  
  location: location  
  properties: {
    networkManagerScopeAccesses: [
      'Connectivity' 
      'SecurityAdmin'
    ]
    networkManagerScopes: {
      subscriptions: [
        '/subscriptions/${subscription().subscriptionId}'
      ]
      managementGroups: []
    }        
  }  
}

resource westStaticNetworkGroup 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' = {
  name: westStaticNetworkGroupName
  parent: virtualNetworkManager

  resource staticMembers 'staticMembers@2024-05-01' = [for group in westStaticVnetGroups: {
    name: group.GroupName
    properties: {
      resourceId: resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Network/virtualNetworks', group.vnetName)
    }
  }] 
}


resource eastDynamicNetworkGroup 'Microsoft.Network/networkManagers/networkGroups@2024-03-01'= {
  name: eastDynamicNetworkGroupName
  parent: virtualNetworkManager
}

resource westUsconnectvityConfig 'Microsoft.Network/networkManagers/connectivityConfigurations@2024-05-01' = {
  name: westUsconnectvityConfigName
  parent: virtualNetworkManager
  dependsOn: [for group in westStaticNetworkGroup::staticMembers: group]               
  
  properties: {
    appliesToGroups: [
      {
       groupConnectivity: 'DirectlyConnected' 
       networkGroupId: westStaticNetworkGroup.id
       isGlobal: 'False' 
       useHubGateway: useHubGateway       
      }      
    ]
    connectivityTopology: 'HubAndSpoke' 
    deleteExistingPeering: 'True'
    isGlobal: isGlobal  
    hubs: [
      {
       resourceId: hub1VnetID
       resourceType: 'Microsoft.Network/virtualNetworks'  
      }      
    ]
  }
}

resource eastUsconnectvityConfig 'Microsoft.Network/networkManagers/connectivityConfigurations@2024-05-01' = {
  name: eastUsconnectvityConfigName
  parent: virtualNetworkManager
  
  properties: {
    appliesToGroups: [      
      {
        groupConnectivity: 'DirectlyConnected' 
        networkGroupId:  eastDynamicNetworkGroup.id
        isGlobal: 'False' 
        useHubGateway: 'False' 
       }
    ]
    connectivityTopology: 'HubAndSpoke' 
    deleteExistingPeering: 'True'
    isGlobal: isGlobal  
    hubs: [      
      {
       resourceId: hub2VnetID
       resourceType: 'Microsoft.Network/virtualNetworks'  
      }
    ]
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedDeploymentUserName
  location: location 
  
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, managedIdentity.name)
  properties: {
    roleDefinitionId: networkContributoreRoleId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


// It assings these roles to whoever is deploying the modules: ContributorRole, ResourcePolicyContributorRole, SecurityAdminRoleurityAdminRole
module userRoleAssignment  'assign_networkmanager_executor_required_permissions.bicep'={
  name: 'callRoleAssignModule'
  params: {
    networkManagerName: virtualNetworkManager.name
    userObjectId: userObjectId
  }
}

output networkManagerName string = virtualNetworkManager.name
output userAssignedIdentityId string = managedIdentity.id
output westUsconnectivityConfigurationId string = westUsconnectvityConfig.id
output eastUsconnectivityConfigurationId string = eastUsconnectvityConfig.id
output networkGroupId string = westStaticNetworkGroup.id
output eastDynamicNetworkGroupId string=  eastDynamicNetworkGroup.id

