// Bicep module for creating a DNS A record for a VM

@description('Name of the virtual machine, used to construct the DNS record name')
param vmName string

@description('IP address of the virtual machine')
param vmIpAddress string

@description('Name of the DNS zone (e.g., example.com)')
param dnsZoneName string

@description('TTL for the DNS record in seconds')
param ttl int = 3600

// Reference to the DNS zone
resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName  
}

// Create the A record
resource aRecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: vmName
  parent: dnsZone
  properties: {
    TTL: ttl
    ARecords: [
      {
        ipv4Address: vmIpAddress
      }
    ]
  }
}

// Output the FQDN of the created DNS record
output fqdn string = '${vmName}.${dnsZoneName}'
