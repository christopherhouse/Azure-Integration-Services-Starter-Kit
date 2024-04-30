import * as udt from './types.bicep'

@description('The identifier for this workload, used to generate resource names')
param workloadName string

@description('The identifier for the environment, used to generate resource names')
param environmentName string

@description('The identifier for the deployment, used to generate deployment names')
param deploymentName string = deployment().name

@description('The Azure region where resources will be deployed')
param region string

@description('The number of days to retain log data in the Log Analytics workspace')
param logAnalyticsWorkspaceRetentionInDays int = 90

@description('The address spaces for the virtual network')
param virtualNetworkAddressSpaces array

@description('The subnet configurations for the virtual network')
param subnetConfigurations udt.subnetConfigurationsType

@description('The tags to apply to the resources')
param tags object = {}

@export()
type subnetConfigurationType = {
  name: string
  addressPrefix: string
  delegation: string
}

module names './nameProvider.bicep' = {
  name: 'names-${deploymentName}'
  params: {
    workloadName: workloadName
    environmentName: environmentName
  }
}

module law './modules/logAnalytics/logAnalyticsWorkspace.bicep' = {
  name: 'law-${deploymentName}'
  params: {
    region: region
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsWorkspaceName
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    tags: tags
  }
}

module apimNsg './modules/networkSecurityGroup/apimNetworkSecurityGroup.bicep' = {
  name: 'apimNsg-${deploymentName}'
  params: {
    region: region
    apimSubnetRange: subnetConfigurations.apimSubnet.addressPrefix
    appGatewaySubnetRange: subnetConfigurations.appGwSubnet.addressPrefix
    logAnalyticsWorkspaceResourceId: law.outputs.id
    nsgName: names.outputs.apimNsgName
    tags: tags
  }
}

module appGwNsg './modules/networkSecurityGroup/applicationGatewayNetworkSecurityGroup.bicep' = {
  name: 'appGwNsg-${deploymentName}'
  params: {
    region: region
    appGatewaySubnetAddressSpace: subnetConfigurations.appGwSubnet.addressPrefix
    logAnalyticsWorkspaceResourceId: law.outputs.id
    networkSecurityGroupName: names.outputs.appGwNsgName
    tags: tags
  }
}

module appSvcInNsg './modules/networkSecurityGroup/appServiceInboundNetworkSecurityGroup.bicep' = {
  name: 'appSvcInNsg-${deploymentName}'
  params: {
    apimSubnetRange: subnetConfigurations.apimSubnet.addressPrefix
    appServiceInboundSubnetRange: subnetConfigurations.appServicePrivateEndpointSubnet.addressPrefix
    logAnalyticsWorkspaceId: law.outputs.id
    networkSecurityGroupName: names.outputs.appServiceInboundNsgName
    region: region
    tags: tags
  }
}

module appSvcOutNsg './modules/networkSecurityGroup/appServiceOutboundNetworkSecurityGroup.bicep' = {
  name: 'appSvcOutNsg-${deploymentName}'
  params: {
    logAnalyticsWorkspaceId: law.outputs.id
    networkSecurityGroupName: names.outputs.appServiceOutboundNsgName
    region: region
    tags: tags
  }
}

module svcsNsg './modules/networkSecurityGroup/servicesNetworkSecurityGroup.bicep' = {
  name: 'svcsNsg-${deploymentName}'
  params: {
    appGatewaySubnetRange: subnetConfigurations.appGwSubnet.addressPrefix
    apimSubnetRange: subnetConfigurations.apimSubnet.addressPrefix
    appServiceOutboundSubnetRange: subnetConfigurations.appServiceVnetIntegrationSubnet.addressPrefix
    servicesSubnet: subnetConfigurations.servicesSubnet.addressPrefix
    logAnalyticsWorkspaceId: law.outputs.id
    networkSecurityGroupName: names.outputs.servicesNsgName
    region: region
    tags: tags
  }
}

module vnet './modules/virtualNetwork/virtualNetwork.bicep' = {
  name: 'vnet-${deploymentName}'
  params: {
    addressPrefixes: virtualNetworkAddressSpaces
    apimNsgResourceId: apimNsg.outputs.id
    appGwNsgResourceId: appGwNsg.outputs.id
    appServiceInboundNsgResourceId: appSvcInNsg.outputs.id
    appServiceOutboundNsgResourceId: appSvcOutNsg.outputs.id
    servicesNsgResourceId: svcsNsg.outputs.id
    subnetConfiguration: subnetConfigurations
    region: region
    virtualNetworkName: names.outputs.vnetName
    tags: tags
  }
}

module kv './modules/keyVault/privateKeyVault.bicep' = {
  name: 'kv-${deploymentName}'
  params: {
    region: region
    deploymentName: deploymentName
    keyVaultName: names.outputs.keyVaultName
    logAnalyticsWorkspaceResourceId: law.outputs.id
    servicesSubnetResourceId: vnet.outputs.servicesSubnetId
    vnetName: vnet.outputs.name
    tags: tags
  }
}

module ai './modules/applicationInsights/applicationInsights.bicep' = {
  name: 'ai-${deploymentName}'
  params: {
    appInsightsName: names.outputs.appInsightsName
    deploymentName: deploymentName
    keyVaultName: kv.outputs.name
    logAnalyticsWorkspaceId: law.outputs.id
    region: region
    tags: tags
  }
}
