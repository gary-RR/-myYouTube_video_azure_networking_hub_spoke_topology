// File: firewall.bicep
// Description: Reusable module to deploy an Azure Firewall and its subnet in a VNet.

// Parameters
param vnetName string
param region string
param firewallSubnetName string = 'AzureFirewallSubnet'
param firewallName string

// VNet resource (assumed pre-existing)
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
  //scope: resourceGroup(resourceGroupName)
}

// Create AzureFirewallSubnet
resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: vnet
  name: firewallSubnetName
}

// Public IP for Azure Firewall
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${firewallName}-pip'
  location: region
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// Azure Firewall resource
resource firewall 'Microsoft.Network/azureFirewalls@2023-11-01' = {
  name: firewallName
  location: region
  properties: {
    sku: { name: 'AZFW_VNet', tier: 'Standard' }
    ipConfigurations: [
      {
        name: 'firewallIpConfig'
        properties: {
          subnet: { id: firewallSubnet.id }
          publicIPAddress: { id: firewallPublicIp.id }
        }
      }
    ]
  }  
}

// Output the firewall's private IP
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output ipConfigurations array = firewall.properties.ipConfigurations
