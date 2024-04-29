import * as udt from './types.bicep'

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
param subnetConfigurations udt.subnetConfigurationsType

@description('The configuration for API Management')
param apimConfiguration udt.apimConfiguration

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

@description('The configuration for App Service Plans')
param appServicePlansConfiguration udt.appServicePlanConfigurationType

@description('The name of the key vault to use for secrets')
param keyVaultName string

param logicAppDeploymentConfiguration udt.logicAppDeploymentConfigurationType

@description('Tags to apply to all resources')
param tags object = {}

var lawName = '${workloadName}-${environmentName}-law'
var vnetName = '${workloadName}-${environmentName}-vnet'

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

resource appSvcPeSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: subnetConfigurations.appServicePrivateEndpointSubnet.name
  parent: vnet
}

resource appSvcVniSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: subnetConfigurations.appServiceVnetIntegrationSubnet.name
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

// Data Factory + DNS
module adfDns './modules/dns/privateDnsZone.bicep' = if(dataFactoryConfiguration.deployDataFactory == 'yes') {
  name: 'adf-dns-${deploymentName}'
  params: {
    zoneName: names.outputs.dataFactoryPrivateLinkZoneName
    vnetResourceId: vnet.id
    tags: tags
  }
}

module adfPortalDns './modules/dns/privateDnsZone.bicep' = if(dataFactoryConfiguration.deployDataFactory == 'yes') {
  name: 'adf-portal-dns-${deploymentName}'
  params: {
    zoneName: names.outputs.dataFactoryPortalPrivateLinkZoneName
    vnetResourceId: vnet.id
    tags: tags
  }
}

module adf './modules/dataFactory/dataFactory.bicep' = if(dataFactoryConfiguration.deployDataFactory == 'yes') {
  name: 'adf-${deploymentName}'
  params: {
    dataFactoryConfiguration: dataFactoryConfiguration
    dataFactoryName: names.outputs.dataFactoryName
    region: region
    logAnalyticsWorkspaceResourceId: law.id
    adfDnsZoneResourceId: adfDns.outputs.id
    adfPortalDnsZoneResourceId: adfPortalDns.outputs.id
    subnetResourceId: servicesSubnet.id
    tags: tags
  }
}

// Container Registry + DNS
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

// Storage + DNS
module storageDns './modules/storage/storagePrivateDns.bicep' = {
  name: 'storage-dns-${deploymentName}'
  params: {
    vnetResourceId: vnet.id
  }
}

// App Service Plans + ASE + DNS

// Only deploy app service DNS zones if not configured to use ASE
module appSvcSitesDns './modules/dns/privateDnsZone.bicep' = if(appServicePlansConfiguration.deployAppServicePlans == 'yes' && !appServicePlansConfiguration.serviceProperties.useAppServiceEnvironment) {
  name: 'appSvcSites-dns-${deploymentName}'
  params: {
    zoneName: names.outputs.appServiceSitesPrivateLinkDnsZoneName
    vnetResourceId: vnet.id
    tags: tags
  }
}

module appSvcScmDns './modules/dns/privateDnsZone.bicep' = if(appServicePlansConfiguration.deployAppServicePlans == 'yes' && !appServicePlansConfiguration.serviceProperties.useAppServiceEnvironment) {
  name: 'appSvcScm-dns-${deploymentName}'
  params: {
    zoneName: names.outputs.appServiceScmPrivateLinkDnsZoneName
    vnetResourceId: vnet.id
    tags: tags
  }
}

module ase './modules/appService/appServiceEnvironmentV3.bicep' = if(appServicePlansConfiguration.deployAppServicePlans == 'yes' && appServicePlansConfiguration.serviceProperties.useAppServiceEnvironment) {
  name: 'ase-${deploymentName}'
  params: {
    aseName: names.outputs.aseName
    region: region
    aseSubnetResourceId: appSvcVniSubnet.id
    logAnalyticsWorkspaceResourceId: law.id
    tags: tags
  }
}

module aseDns './modules/dns/privateDnsZone.bicep' = if(appServicePlansConfiguration.deployAppServicePlans == 'yes' && appServicePlansConfiguration.serviceProperties.useAppServiceEnvironment) {
  name: 'ase-dns-${deploymentName}'
  params: {
    zoneName: ase.outputs.dnsSuffix
    vnetResourceId: vnet.id
    tags: tags
  }
}

// App Service Plans
#disable-next-line BCP179
module plans './modules/appService/appServicePlan.bicep' = [for plan in appServicePlansConfiguration.serviceProperties.plans: if(appServicePlansConfiguration.deployAppServicePlans == 'yes' && !appServicePlansConfiguration.serviceProperties.useAppServiceEnvironment) {
  name: 'app-service-plans-${deploymentName}'
  params: {
   appServicePlanName: plan.planName
   region: region
   skuName: plan.sku
   skuCapacity: plan.skuCapacity
   zoneRedundant: plan.zoneRedundant
   tags: tags
  }
}]

var logicAppCfg = {
  deployToAppServiceEnvironment: appServicePlansConfiguration.deployAppServicePlans == 'yes' && appServicePlansConfiguration.serviceProperties.useAppServiceEnvironment ? 'yes' : 'no'
  appServicePlanResourceId: plans[0].outputs.id
  siteDnsZoneResourceId: appSvcSitesDns.outputs.id
  scmDnsZoneResourceId: appSvcScmDns.outputs.id
  privateEndpointSubnetId: appSvcPeSubnet.id
  vnetIntegrationSubnetId: appSvcVniSubnet.id
}

#disable-next-line BCP179
module la './modules/appService/logicApp/privateLogicApp.bicep' = [for logicApp in logicAppDeploymentConfiguration.logicApps: {
  name: 'la-${deploymentName}'
  params: {
    region: region
    logAnalyticsWorkspaceResourceId: law.id
    appServicePlanResourceId: '' // TODO: Fix
    tags: tags
    blobDnsZoneResourceId: storageDns.outputs.blobDnsZoneId
    fileDnsZoneResourceId: storageDns.outputs.fileDnsZoneId
    queueDnsZoneResourceId: storageDns.outputs.queueDnsZoneId
    tableDnsZoneResourceId: storageDns.outputs.tableDnsZoneId
    logicAppName: ''
    appInsightsConnectionStringSecretUri: ''
    appInsightsInstrumentationKeySecretUri: ''
    storageSubnetResourceId: servicesSubnet.id
    storageAccountConfiguration: {
      accessTier: 'Hot'
      sku: 'Standard_LRS'
      fileShares: [
        {
          name: 'la-content'
          quota: 1024
        }
      ]
      addConnectionStringToKeyVault: true
    }
    keyVaultName: keyVaultName
    logicAppConfiguration: appServicePlansConfiguration.serviceProperties.useAppServiceEnvironment ? {
        deployToAppServiceEnvironment: 'no'
        appServicePlanResourceId: '' // TODO: Fix
        siteDnsZoneResourceId: appSvcSitesDns.outputs.id
        scmDnsZoneResourceId: appSvcScmDns.outputs.id
        privateEndpointSubnetId: appSvcPeSubnet.id
        vnetIntegrationSubnetId: appSvcVniSubnet.id
      } : {
        deployToAppServiceEnvironment: 'yes'
        aseResourceId: ase.outputs.id
        appServicePlanResourceId: plans[0].outputs.id
    }      
  }
}]

func getAspResourceId(plans array, planName string) string => filter(plans, plan => plan.outputs.name == planName)[0].outputs.id
