@description('The name of the Azure Data Factory that will be created')
param dataFactoryName string

@description('The Azure region in which to create the Azure Data Factory')
param region string

@description('The resource ID of the Log Analytics workspace to use for diagnostics')
param logAnalyticsWorkspaceResourceId string

@description('The configuration for the Azure Data Factory')
param dataFactoryConfiguration dataFactoryConfigurationType

@description('The tags to apply to the Azure Data Factory')
param tags object = {}


@export()
type dataFactoryEnabledConfigurationType = {
  deployDataFactory: 'yes'
}

@export()
type dataFactoryDisabledConfigurationType = {
  deployDataFactory: 'no'
}

@export()
@discriminator('deployDataFactory')
type dataFactoryConfigurationType = dataFactoryEnabledConfigurationType | dataFactoryDisabledConfigurationType

var dataFactoryUamiName = '${dataFactoryName}-uami'

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: dataFactoryUamiName
  location: region
  tags: tags
}

resource df 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: region
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    // TODO: support parameters for repo configuration
  }
}

resource dfMvn 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: 'managed-vnet'
  parent: df
  properties: {}
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diags'
  scope: df
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output id string = df.id
output name string = df.name
