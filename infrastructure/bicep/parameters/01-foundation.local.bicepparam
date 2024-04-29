using '../01-foundation.bicep'
import * as udt from '../types.bicep'

param workloadName = 'ais-sk'
param environmentName = 'loc'
param region = 'eastus'
param tags = {
  Project_Name: 'AIS Stater Kit'
}
param logAnalyticsWorkspaceRetentionInDays = 90
param virtualNetworkAddressSpaces = ['10.254.0.0/24']
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
