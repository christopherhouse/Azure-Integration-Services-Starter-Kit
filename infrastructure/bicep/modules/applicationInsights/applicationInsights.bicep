param appInsightsName string
param region string
param logAnalyticsWorkspaceId string
param keyVaultName string
param deploymentName string
@description('The tags to associate with the API Center resource')
param tags object = {}

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  tags: tags
  location: region
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

module connectionString '../keyVault/keyVaultSecret.bicep' = {
  name: 'app-insights-connection-string-${deploymentName}'
  params: {
    keyVaultName: keyVaultName
    secretName: 'appInsightsConnectionString'
    secretValue: ai.properties.ConnectionString
  }
}

module iKey '../keyVault/keyVaultSecret.bicep' = {
  name: 'app-insights-instrumentationkey-${deploymentName}'
  params: {
    keyVaultName: keyVaultName
    secretName: 'appInsightsInstrumentationKey'
    secretValue: ai.properties.InstrumentationKey
  }
}

output id string = ai.id
output name string = ai.name
output instrumentationKeySecretUri string = iKey.outputs.secretUri
output connectionStringSecretUri string = connectionString.outputs.secretUri
