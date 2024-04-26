@description('The name of the Public IP Address resource to be created')
param publicIpAddressName string

@description('The DNS label for the Public IP Address.  Defaults to resource name')
param dnsLabel string = publicIpAddressName

@description('The region where the Public IP Address will be created')
param region string

@description('A flag indicating whether the IP address will be zone redundant')
param zoneRedundant bool = false

@description('The ID of the Log Analytics workspace to send diagnostics data to')
param logAnalyticsWorkspaceId string

@description('The tags to associate with the API Center resource')
param tags object = {}

var zones = zoneRedundant ? ['1', '2', '3'] : []

resource pip 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIpAddressName
  tags: tags
  location: region
  sku: {
    name: 'Standard'
  }
  properties: {
    dnsSettings: {
      domainNameLabel: dnsLabel
    }
    publicIPAllocationMethod: 'Static'
  }
  zones: zones
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: pip
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
  }
}

output id string = pip.id
output ip string = pip.properties.ipAddress
