@description('The identifier for this workload, used to generate resource names')
param workloadName string

@description('The identifier for the environment, used to generate resource names')
param environmentName string

var vnetName = '${workloadName}-${environmentName}-vnet'
output vnetName string = vnetName

var apimNsgName = '${workloadName}-${environmentName}-apim-nsg'
var appGwNsgName = '${workloadName}-${environmentName}-appgw-nsg'
var keyVaultNsgName = '${workloadName}-${environmentName}-kv-nsg'

output apimNsgName string = apimNsgName
output appGwNsgName string = appGwNsgName
output keyVaultNsgName string = keyVaultNsgName

var logAnalyticsWorkspaceName = '${workloadName}-${environmentName}-law'
output logAnalyticsWorkspaceName string = logAnalyticsWorkspaceName

var appInsightsName = '${workloadName}-${environmentName}-ai'
output appInsightsName string = appInsightsName
