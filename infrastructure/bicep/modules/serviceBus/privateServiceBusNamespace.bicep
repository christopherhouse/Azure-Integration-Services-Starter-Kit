@description('The name of the Service Bus namespace to create')
param serviceBusNamespaceName string

@description('The Azure region in which to create the Service Bus namespace')
param region string

@description('The resource ID of the Log Analytics workspace to use for diagnostics')
param logAnalyticsWorkspaceResourceId string

@description('The resource ID of the DNS zone to use for private endpoint DNS configuration')
param dnsZoneResourceId string

@description('The resource ID of the subnet in which to create the private endpoint')
param subnetResourceId string

@description('The configuration for the Service Bus namespace')
param serviceBusConfiguration serviceBusConfigurationType

@description('The tags to apply to the Service Bus namespace and private endpoint')
param tags object = {}

@export()
type serviceBusEnabledConfigurationType = {
  deployServiceBus: 'yes'
  serviceProperties: serviceBusServiceConfigurationType
}

@export()
type serviceBusServiceConfigurationType = {
  capacityUnits: int
  enableZoneRedundancy: bool
}

@export()
type serviceBusDisabledConfigurationType = {
  deployServiceBus: 'no'
}

@discriminator('deployServiceBus')
@export()
type serviceBusConfigurationType = serviceBusEnabledConfigurationType | serviceBusDisabledConfigurationType

var sbnsDeploymentName = '${serviceBusNamespaceName}-private-deployment-${deployment().name}'
var sbnsPeDeploymentName = '${serviceBusNamespaceName}-pe-${deployment().name}'
var sbnsPeName = '${serviceBusNamespaceName}-pe'

module sbns './serviceBusNamespace.bicep' = {
  name: sbnsDeploymentName
  params: {
    location: region
    capacityUnits: serviceBusConfiguration.serviceProperties.capacityUnits
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    serviceBusNamespaceName: serviceBusNamespaceName
    tags: tags
  }
}

module pe '../privateEndpoint/privateEndpoint.bicep' = {
  name: sbnsPeDeploymentName
  params: {
    dnsZoneId: dnsZoneResourceId
    groupId: 'namespace'
    region: region
    privateEndpointName: sbnsPeName
    subnetId: subnetResourceId
    targetResourceId: sbns.outputs.id
    tags: tags
  }
}

output id string = sbns.outputs.id
output name string = sbns.outputs.name
