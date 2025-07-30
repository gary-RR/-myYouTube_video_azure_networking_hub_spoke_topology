// Parameters
param networkManagerName string             // Resource ID of the Network Manager (NMV1)
param userObjectId string                 // Object ID of the human user (e.g., Gray)

// Extract the Network Manager resource as a reference
resource networkManager 'Microsoft.Network/networkManagers@2022-05-01' existing = {
  name: networkManagerName
}

// Role Definitions
var ContributorRole = 'b24988ac-6180-42a0-ab88-20f7382dd24c'  // Role ID for "Contributor"
var resourcePolicyContributorRole = '36243c78-bf99-498c-9df9-86d9f8d28608'  // Role ID for "Resource Policy Contributor"
var securityAdminRole='f1a07417-d97a-45cb-824c-7a7467783830'

// Assign "Network Contributor" to the user
resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(networkManager.id, userObjectId, ContributorRole)
  scope: networkManager
  properties: {
    principalId: userObjectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', ContributorRole)
  }
}

// Assign "Resource Policy Contributor" to the user
resource grayPolicyContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(networkManager.id, userObjectId, resourcePolicyContributorRole)
  scope: networkManager
  properties: {
    principalId: userObjectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', resourcePolicyContributorRole)
  }
}

// Assign "Resource Policy Contributor" to the user
resource securitAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(networkManager.id, userObjectId, securityAdminRole)
  scope: networkManager
  properties: {
    principalId: userObjectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', securityAdminRole)
  }
}
