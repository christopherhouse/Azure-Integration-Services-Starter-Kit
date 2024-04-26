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
param subnetConfigurations subnetConfigurationsType

@description('The tags to apply to the resources')
param tags object = {}

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
    location: region
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsWorkspaceName
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    tags: tags
  }
}

module apimNsg './modules/networkSecurityGroup/apimNetworkSecurityGroup.bicep' = {
  name: 'apimNsg-${deploymentName}'
  params: {
    location: region
    apimSubnetRange: subnetConfigurations.apimSubnet.addressPrefix
    appGatewaySubnetRange: subnetConfigurations.appGwSubnet.addressPrefix
    logAnalyticsWorkspaceResourceId: law.outputs.id
    nsgName: names.outputs.apimNsgName
    tags: tags
  }
}

module kvNsg './modules/networkSecurityGroup/keyVaultNetworkSecurityGroup.bicep' = {
  name: 'kvNsg-${deploymentName}'
  params: {
    location: region
    logAnalyticsWorkspaceId: law.outputs.id
    apimSubnetRange: subnetConfigurations.apimSubnet.addressPrefix
    appGatewaySubnetRange: subnetConfigurations.appGwSubnet.addressPrefix
    keyVaultSubnetRange: subnetConfigurations.servicesSubnet.addressPrefix
    networkSecurityGroupName: names.outputs.keyVaultNsgName
    tags: tags
  }
}
