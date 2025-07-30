@description('Location for the resources')
param location string = resourceGroup().location

@description('Name of the Application Gateway')
param appGatewayName string

// @description('Name of the AKS cluster')
// param aksName string

@description('Name of the VNet where resources are deployed')
param vnetName string

@description('Subnet name for the Application Gateway')
param appGatewaySubnetName string

@description('Public IP name for Application Gateway')
param appGatewayPublicIpName string

param dnsLabel string='cosmoapps'

@description('Backend pool IP address (AKS ingress or service)')
param backendPoolIps array

@description('Backend service port (e.g., 80)')
param backendServicePort int = 80

@description('Frontend port for HTTPS')
param frontendHttpsPort int = 80 //443

@description('Enable WAF mode (Detection/Prevention)')
param wafMode string = 'Prevention'

resource appGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: appGatewayPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabel
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: appGatewayName
  location: location
  properties: {
    sku: {
      name: 'WAF_v2' // Use 'Standard_v2' for the cheapest option
      tier: 'WAF_v2'
      capacity: 1 // Minimum instance count
    } 
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, appGatewaySubnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGatewayPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'httpsFrontendPort'
        properties: {
          port: frontendHttpsPort
        }
      }
    ]
    // sslCertificates: [
    //   {
    //     name: 'appGatewaySslCert'
    //     properties: {
    //       data: sslCertBase64
    //       password: sslCertPassword
    //     }
    //   }
    // ]
    httpListeners: [
      {
        name: 'httpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'httpsFrontendPort')
          }
          protocol: 'Http'
          // protocol: 'Https'
          // sslCertificate: {
          //   id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, 'appGatewaySslCert')
          // }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            for ip in backendPoolIps: {
              ipAddress: ip
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpBackendSetting'
        properties: {
          port: backendServicePort
          protocol: 'Http'
          requestTimeout: 20
        }
      }
    ]    
    requestRoutingRules: [
      {
        name: 'appGatewayRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'httpsListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'httpBackendSetting')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: wafMode
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
}

output appGatewayID string=appGateway.id
output appGatewayFQDN string = appGatewayPublicIp.properties.dnsSettings.fqdn
