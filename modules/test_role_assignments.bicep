param userObjectId string='72a4e41f-6b55-4fce-befd-f1396ae6b981'
param location string=resourceGroup().location

resource virtualNetworkManager 'Microsoft.Network/networkManagers@2024-01-01'= {
  name: 'VirtualNetworkManager1'
  location: location
  properties: {
    networkManagerScopeAccesses: [
      'Connectivity'
    ]
    networkManagerScopes: {
      subscriptions: [
        '/subscriptions/${subscription().subscriptionId}'
      ]
      managementGroups: []
    }        
  }  
}

module roleAssignment  'assign_roles.bicep'={
  name: 'callRoleAssignModule'
  params: {
    networkManagerName: virtualNetworkManager.name
    userObjectId: userObjectId
  }
}
