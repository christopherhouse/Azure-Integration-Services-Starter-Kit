@description('The identifier for this workload, used to generate resource names')
param workloadName string

@description('The identifier for the environment, used to generate resource names')
param environmentName string

// Virtual Network
var vnetName = '${workloadName}-${environmentName}-vnet'
output vnetName string = vnetName

// NSGs
var apimNsgName = '${workloadName}-${environmentName}-apim-nsg'
var appGwNsgName = '${workloadName}-${environmentName}-appgw-nsg'
var keyVaultNsgName = '${workloadName}-${environmentName}-kv-nsg'

output apimNsgName string = apimNsgName
output appGwNsgName string = appGwNsgName
output keyVaultNsgName string = keyVaultNsgName

// Log Analytics
var logAnalyticsWorkspaceName = '${workloadName}-${environmentName}-law'
output logAnalyticsWorkspaceName string = logAnalyticsWorkspaceName

// Application Insights
var appInsightsName = '${workloadName}-${environmentName}-ai'
output appInsightsName string = appInsightsName

// Key Vault
var keyVaultName = '${workloadName}-${environmentName}-kv'
output keyVaultName string = keyVaultName
