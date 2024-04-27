import * as apimTypes from './modules/apiManagement/apiManagementService.bicep'
import * as eventHubTypes from './modules/eventHub/eventHubNamespace.bicep'
import * as serviceBusTypes from './modules/serviceBus/privateServiceBusNamespace.bicep'
import * as integrationAcctTypes from './modules/integrationAccount/integrationAccount.bicep'
import * as adfTypes from './modules/dataFactory/dataFactory.bicep'
import * as acrTypes from './modules/containerRegistry/containerRegistry.bicep'

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

@description('The configuration for Service Bus')
param serviceBusConfiguration serviceBusTypes.serviceBusConfigurationType

@description('The configuration for Integration Account')
param integrationAccountConfiguration integrationAcctTypes.integrationAccountConfigurationType

@description('The configuration for Data Factory')
param dataFactoryConfiguration adfTypes.dataFactoryConfigurationType

@description('The configuration for Container Registry')
param acrConfiguration acrTypes.acrConfigurationType

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

// Public IP Address for APIM
module apimPip './modules/publicIpAddress/publicIpAddress.bicep' = {
  name: 'apim-pip-${deploymentName}'
  params: {
    region: region
    logAnalyticsWorkspaceId: law.id
    publicIpAddressName: names.outputs.apimPublicIpName
    tags: tags
  }
}

// User Assigned Managed Identity for APIM
module apimUami './modules/managedIdentity/userAssignedManagedIdentity.bicep' = if(apimConfiguration.deployApim == 'yes') {
  name: 'apim-uami-${deploymentName}'
  params: {
    location: region
    managedIdentityName: names.outputs.apimUserAssignedManagedIdentityName
    tags: tags
  }
}

// API Management
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

// Service Bus + Event Hub DNS
module sbDns './modules/dns/privateDnsZone.bicep' = if(eventHubConfiguration.deployEventHub == 'yes' || serviceBusConfiguration.deployServiceBus == 'yes') {
  name: 'sb-dns-${deploymentName}'
  params: {
    zoneName: names.outputs.serviceBusPrivateLinkZoneName
    vnetResourceId: vnet.id
    tags: tags
  }
}

// Event Hub
module eventHub './modules/eventHub/eventHubNamespace.bicep' = if(eventHubConfiguration.deployEventHub == 'yes') {
  name: 'eventHub-${deploymentName}'
  params: {
    region: region
    eventHubNamespaceName: names.outputs.eventHubNamespaceName
    dnsZoneResourceId: sbDns.outputs.id
    eventHubConfiguration: eventHubConfiguration
    logAnalyticsWorkspaceResourceId: law.id
    subnetResourceId: servicesSubnet.id
    tags: tags
  }
}

// Service Bus
module serviceBus './modules/serviceBus/privateServiceBusNamespace.bicep' = if(serviceBusConfiguration.deployServiceBus == 'yes') {
  name: 'serviceBus-${deploymentName}'
  params: {
    region: region
    serviceBusNamespaceName: names.outputs.serviceBusNamespaceName
    dnsZoneResourceId: sbDns.outputs.id
    logAnalyticsWorkspaceResourceId: law.id
    serviceBusConfiguration: serviceBusConfiguration
    subnetResourceId: servicesSubnet.id
    tags: tags
  }
}

// Integration Account
module ia './modules/integrationAccount/integrationAccount.bicep' = if(integrationAccountConfiguration.deployIntegrationAccount == 'yes') {
  name: 'integrationAccount-${deploymentName}'
  params: {
    region: region
    integrationAccountName: names.outputs.integrationAccountName
    integrationAccountConfiguration: integrationAccountConfiguration
    logAnalyticsWorkspaceId: law.id
    tags: tags
  }
}

// Data Factory
module adf './modules/dataFactory/dataFactory.bicep' = if(dataFactoryConfiguration.deployDataFactory == 'yes') {
  name: 'adf-${deploymentName}'
  params: {
    dataFactoryConfiguration: dataFactoryConfiguration
    dataFactoryName: names.outputs.dataFactoryName
    region: region
    logAnalyticsWorkspaceResourceId: law.id
    tags: tags
  }
}

module acrDns './modules/dns/privateDnsZone.bicep' = if(acrConfiguration.deployAcr == 'yes') {
  name: 'acr-dns-${deploymentName}'
  params: {
    zoneName: names.outputs.acrPrivateLinkZoneName
    vnetResourceId: vnet.id
    tags: tags
  }
}

module acr './modules/containerRegistry/containerRegistry.bicep' = if(acrConfiguration.deployAcr == 'yes') {
  name: 'acr-${deploymentName}'
  params: {
    acrConfiguration: acrConfiguration
    acrName: names.outputs.acrName
    dnsZoneResourceId: acrDns.outputs.id
    logAnalyticsWorkspaceResourceId: law.id
    region: region
    subnetResourceId: servicesSubnet.id
    tags: tags
  }
}
