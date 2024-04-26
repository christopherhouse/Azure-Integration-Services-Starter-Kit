import * as apimTypes from 'modules/apiManagement/apiManagementService.bicep'

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

param apimConfiguration apimTypes.apimConfiguration

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
    logAnalyticsWorkspaceId: names.outputs.logAnalyticsWorkspaceName
    publicIpResourceId: apimPip.outputs.id
    userAssignedManagedIdentityPrincipalId: apimUami.outputs.principalId
    userAssignedManagedIdentityResourceId: apimUami.outputs.id
    vnetResourceId: vnet.id
    vnetSubnetResourceId: apimSubnet.id
    tags: tags
  }
}
