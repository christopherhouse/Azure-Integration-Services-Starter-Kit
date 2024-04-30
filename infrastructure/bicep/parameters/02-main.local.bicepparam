using '../02-main.bicep'
import * as udt from '../types.bicep'

import * as apimTypes from '../modules/apiManagement/apiManagementService.bicep'
import * as eventHubTypes from '../modules/eventHub/eventHubNamespace.bicep'
import * as serviceBusTypes from '../modules/serviceBus/serviceBusNamespace.bicep'
import * as integrationAccountTypes from '../modules/integrationAccount/integrationAccount.bicep'
import * as dataFactoryTypes from '../modules/dataFactory/dataFactory.bicep'
import * as acrTypes from '../modules/containerRegistry/containerRegistry.bicep'

param workloadName = 'ais-sk'
param environmentName = 'loc'
param region = 'eastus'
param tags = {
  Project_Name: 'AIS Stater Kit'
}
param subnetConfigurations = {
  appServiceDelegation: 'Microsoft.Web/serverFarms'
  apimSubnet: {
    addressPrefix: '10.254.0.248/29'
    delegation: 'none'
    name: 'apim-subnet'
  }
  appGwSubnet: {
    addressPrefix: '10.254.0.0/26'
    delegation: 'none'
    name: 'appgw-subnet'
  }
  appServicePrivateEndpointSubnet: {
    addressPrefix: '10.254.0.64/27'
    delegation: 'Microsoft.Web/hostingEnvironments'
    name: 'appservice-private-endpoint-subnet'
  }
  appServiceVnetIntegrationSubnet: {
    addressPrefix: '10.254.0.96/27'
    delegation: 'none'
    name: 'appservice-vnet-integration-subnet'
  }
  servicesSubnet: {
    addressPrefix: '10.254.0.192/27'
    delegation: 'none'
    name: 'services-subnet'
  }
}

param apimConfiguration = {
  deployApim: 'yes'
  serviceProperties: {
    skuName: 'Developer'
    skuCapacity: 1
    publisherEmailAddress: 'foo.bar@bizbaz.yyz'
    publisherOrganizationName: 'Contoso'
  }
}
param eventHubConfiguration = {
  deployEventHub: 'yes'
  serviceProperties: {
    capacityUnits: 1
    enableZoneRedundancy: true
  }
}
param serviceBusConfiguration = {
  deployServiceBus: 'yes'
  serviceProperties: {
    capacityUnits: 1
    enableZoneRedundancy: false
  }
}
param integrationAccountConfiguration = {
  deployIntegrationAccount: 'yes'
  serviceConfiguration: {
    sku: 'Free'
  }
}
param dataFactoryConfiguration = {
  deployDataFactory: 'yes'
}
param acrConfiguration = {
  deployAcr: 'yes'
  serviceProperties: {
    enableZoneRedundancy: false
  }
}
param appServicePlansConfiguration = {
  deployAppServicePlans: 'yes'
  serviceProperties: {
    useAppServiceEnvironment: false
    plans: [
      {
        planName: 'ais-sk-loc-asp'
        skuCapacity: 1
        sku: 'P0v3'
        zoneRedundant: false
      }
    ]
  }
}
param keyVaultName = 'ais-sk-loc-kv'
param logicAppDeploymentConfiguration = {
  deployLogicApps: 'no'
}
