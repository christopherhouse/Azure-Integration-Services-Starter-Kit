param acrName string
param region string
param logAnalyticsWorkspaceResourceId string
param acrConfiguration acrConfigurationType
param dnsZoneResourceId string
param subnetResourceId string
param tags object = {}

@export()
@discriminator('deployAcr')
type acrConfigurationType = acrDisabledConfigurationType | acrEnabledConfigurationType

@export()
type acrDisabledConfigurationType = {
  deployAcr: 'no'
  serviceProperties: {
    enableZoneRedundancy: bool
  }
}

@export()
type acrEnabledConfigurationType = {
  deployAcr: 'yes'
  serviceProperties: {
    enableZoneRedundancy: bool
  }
}

var zoneRedundancy = acrConfiguration.serviceProperties.enableZoneRedundancy ? 'Enabled' : 'Disabled'
var peName = '${acrName}-pe'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: region
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: zoneRedundancy
  }
}

module pe '../privateEndpoint/privateEndpoint.bicep' = {
  name: '${peName}-${deployment().name}'
  params: {
    dnsZoneId: dnsZoneResourceId
    groupId: 'registry'
    privateEndpointName: peName
    region: region
    subnetId: subnetResourceId
    targetResourceId: acr.id
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
