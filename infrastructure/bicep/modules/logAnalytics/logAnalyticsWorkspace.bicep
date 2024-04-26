@description('The name of the Log Analytics workspace to create')
param logAnalyticsWorkspaceName string

@description('The Azure region in which to create the Log Analytics workspace')
param region string

@description('The number of days to retain data in the Log Analytics workspace')
param retentionInDays int

@description('The tags to associate with the API Center resource')
param tags object = {}

resource laws 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  tags: tags
  location: region
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: 'PerGB2018'
    }
  }
}

output id string = laws.id
output name string = laws.name
