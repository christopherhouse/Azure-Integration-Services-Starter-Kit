param acrName string
param location string
param logAnalyticsWorkspaceResourceId string
param zoneRedundancyEnabled bool = false

@allowed(['Basic', 'Standard', 'Premium'])
param skuName string

var zoneRedundancy = zoneRedundancyEnabled ? 'Enabled' : 'Disabled'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: zoneRedundancy
  }
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: acr
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
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

output id string = acr.id
output name string = acr.name
