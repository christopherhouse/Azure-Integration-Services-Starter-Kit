param integrationAccountName string
param region string
param logAnalyticsWorkspaceId string
param integrationAccountConfiguration integrationAccountConfigurationType
param tags object = {}

@export()
@discriminator('deployIntegrationAccount')
type integrationAccountConfigurationType = integrationAccountEnabledConfigurationType | integrationAccountDisabledConfigurationType

@export()
type integrationAccountEnabledConfigurationType = {
  deployIntegrationAccount: 'yes'
  serviceConfiguration: {
    sku: 'Standard' | 'Basic' | 'Free'
  }
}

@export()
type integrationAccountDisabledConfigurationType = {
  deployIntegrationAccount: 'no'
}

resource ia 'Microsoft.Logic/integrationAccounts@2019-05-01' = {
  name: integrationAccountName
  location: region
  tags: tags
  sku: {
    name: integrationAccountConfiguration.serviceConfiguration.sku
  }
  properties: {}
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diags'
  scope: ia
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}
