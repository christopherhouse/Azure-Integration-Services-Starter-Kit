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
var appServiceInboundNsgName = '${workloadName}-${environmentName}-appservice-in-nsg'
var appServiceOutboundNsgName = '${workloadName}-${environmentName}-appservice-out-nsg'
var servicesNsgName = '${workloadName}-${environmentName}-services-nsg'

output apimNsgName string = apimNsgName
output appGwNsgName string = appGwNsgName
output appServiceInboundNsgName string = appServiceInboundNsgName
output appServiceOutboundNsgName string = appServiceOutboundNsgName
output servicesNsgName string = servicesNsgName

// Log Analytics
var logAnalyticsWorkspaceName = '${workloadName}-${environmentName}-law'
output logAnalyticsWorkspaceName string = logAnalyticsWorkspaceName

// Application Insights
var appInsightsName = '${workloadName}-${environmentName}-ai'
output appInsightsName string = appInsightsName

// Key Vault
var keyVaultName = '${workloadName}-${environmentName}-kv'
output keyVaultName string = keyVaultName

// API Management
var apimName = '${workloadName}-${environmentName}-apim'
var apimPublicIpName = '${workloadName}-${environmentName}-apim-pip'
var apimUserAssignedManagedIdentityName = '${workloadName}-${environmentName}-apim-uami'
output apimName string = apimName
output apimPublicIpName string = apimPublicIpName
output apimUserAssignedManagedIdentityName string = apimUserAssignedManagedIdentityName

// Event Hub
var eventHubNamespaceName = '${workloadName}-${environmentName}-ehns'
var serviceBusPrivateLinkZoneName = 'privatelink.servicebus.windows.net'
output eventHubNamespaceName string = eventHubNamespaceName
output serviceBusPrivateLinkZoneName string = serviceBusPrivateLinkZoneName

// Service Bus
var serviceBusNamespaceName = '${workloadName}-${environmentName}-sbns'
output serviceBusNamespaceName string = serviceBusNamespaceName

// Integration Account
var integrationAccountName = '${workloadName}-${environmentName}-ia'
output integrationAccountName string = integrationAccountName

// Data Factory
var dataFactoryName = '${workloadName}-${environmentName}-df'
output dataFactoryName string = dataFactoryName

var dataFactoryPrivateLinkZoneName = 'privatelink.datafactory.azure.net'
var dataFactoryPortalPrivateLinkZoneName = 'privatelink.adf.azure.com'
output dataFactoryPrivateLinkZoneName string = dataFactoryPrivateLinkZoneName
output dataFactoryPortalPrivateLinkZoneName string = dataFactoryPortalPrivateLinkZoneName

// Container Registry
var acrName = replace(toLower('${workloadName}${environmentName}acr'), '-', '')
output acrName string = acrName

var acrPrivateLinkZoneName = 'privatelink.azurecr.io'
output acrPrivateLinkZoneName string = acrPrivateLinkZoneName

// App Service Plans + ASE + DNS
var aseName = '${workloadName}-${environmentName}-ase'
output aseName string = aseName

var appServiceSitesPrivateLinkDnsZoneName = 'privatelink.azurewebsites.net'
var appServiceScmPrivateLinkDnsZoneName = 'scm.privatelink.azurewebsites.net'
output appServiceSitesPrivateLinkDnsZoneName string = appServiceSitesPrivateLinkDnsZoneName
output appServiceScmPrivateLinkDnsZoneName string = appServiceScmPrivateLinkDnsZoneName
