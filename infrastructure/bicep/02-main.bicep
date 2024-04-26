import * as apimTypes from './modules/apiManagement/apiManagementService.bicep'
import * as eventHubTypes from './modules/eventHub/eventHubNamespace.bicep'

@description('The identifier for this workload, used to generate resource names')
param workloadName string

@description('The identifier for the environment, used to generate resource names')
param environmentName string

@description('The identifier for the deployment, used to generate deployment names')
param deploymentName string = deployment().name

@description('The Azure region where resources will be deployed')
param region string

@description('The subnet configurations for the virtual network')
param subnetConfigurations subnetConfigurationsType

@description('The configuration for API Management')
param apimConfiguration apimTypes.apimConfiguration

@description('The configuration for Event Hub')
param eventHubConfiguration eventHubTypes.eventHubConfigurationType

@description('Tags to apply to all resources')
param tags object = {}

var lawName = '${workloadName}-${environmentName}-law'
var vnetName = '${workloadName}-${environmentName}-vnet'

@export()
type subnetConfigurationType = {
  name: string
  addressPrefix: string
  delegation: string
}

@export()
type subnetConfigurationsType = {
  appServiceSubnet: subnetConfigurationType
  servicesSubnet: subnetConfigurationType
  apimSubnet: subnetConfigurationType
  appGwSubnet: subnetConfigurationType
}

// Names: everything depends on this
module names './nameProvider.bicep' = {
  name: 'names-${deploymentName}'
  params: {
    environmentName: environmentName
    workloadName: workloadName
  }
}

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: lawName
  scope: resourceGroup()
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource apimSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: subnetConfigurations.apimSubnet.name
  parent: vnet
}

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: subnetConfigurations.servicesSubnet.name
  parent: vnet
}

module apimPip './modules/publicIpAddress/publicIpAddress.bicep' = {
  name: 'apim-pip-${deploymentName}'
  params: {
    region: region
    logAnalyticsWorkspaceId: law.id
    publicIpAddressName: names.outputs.apimPublicIpName
    tags: tags
  }
}

module apimUami './modules/managedIdentity/userAssignedManagedIdentity.bicep' = if(apimConfiguration.deployApim == 'yes') {
  name: 'apim-uami-${deploymentName}'
  params: {
    location: region
    managedIdentityName: names.outputs.apimUserAssignedManagedIdentityName
    tags: tags
  }
}

module apim './modules/apiManagement/apiManagementService.bicep' = if(apimConfiguration.deployApim == 'yes') {
  name: 'apim-${deploymentName}'
  params: {
    region : region
    apiManagementServiceName: names.outputs.apimName
    configuration: apimConfiguration
    deploymentName: deploymentName 
    keyVaulName: names.outputs.keyVaultName
    logAnalyticsWorkspaceId: law.id
    publicIpResourceId: apimPip.outputs.id
    userAssignedManagedIdentityPrincipalId: apimUami.outputs.principalId
    userAssignedManagedIdentityResourceId: apimUami.outputs.id
    vnetResourceId: vnet.id
    vnetSubnetResourceId: apimSubnet.id
    tags: tags
  }
}

module sbDns './modules/dns/privateDnsZone.bicep' = if(eventHubConfiguration.deployEventHub == 'yes') {
  name: 'sb-dns-${deploymentName}'
  params: {
    zoneName: names.outputs.serviceBusPrivateLinkZoneName
    vnetResourceId: vnet.id
    tags: tags
  }
}

module eventHub './modules/eventHub/eventHubNamespace.bicep' = if(eventHubConfiguration.deployApim == 'yes') {
  name: 'eventHub-${deploymentName}'
  params: {
    region: region
    eventHubNamespaceName: names.outputs.eventHubNamespaceName
    dnsZoneResourceId: sbDns.outputs.id
    eventHubConfiguration: eventHubConfiguration
    logAnalyticsWorkspaceResourceId: law.id
    subnetResourceId: servicesSubnet.id
    vnetResourceId: vnet.id
    tags: tags
  }
}
