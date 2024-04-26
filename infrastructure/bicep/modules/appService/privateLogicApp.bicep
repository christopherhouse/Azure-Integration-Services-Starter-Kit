param logicAppName string
param location string
param aseResourceId string
param appServicePlanResourceId string
param blobDnsZoneResourceId string
param tableDnsZoneResourceId string
param queueDnsZoneResourceId string
param fileDnsZoneResourceId string
param storageSubnetResourceId string
param keyVaultName string
param appInsightsInstrumentationKeySecretUri string
param appInsightsConnectionStringSecretUri string
param logAnalyticsWorkspaceResourceId string
param zoneRedundantStorage bool = false
param buildId string

var logicAppUamiName = '${logicAppName}-uami'
var logicAppUamiDeploymentName = '${logicAppUamiName}-${buildId}'

module uami '../managedIdentity/userAssignedManagedIdentity.bicep' = {
  name: logicAppUamiDeploymentName
  params: {
    managedIdentityName: logicAppUamiName
    location: location
  }
}

module logicApp './logicApp.bicep' = {
  name: '${logicAppName}-mod-${buildId}'
  params: {
    location: location
    aseResourceId: aseResourceId
    appServicePlanResourceId: appServicePlanResourceId
    blobDnsZoneResourceId: blobDnsZoneResourceId
    tableDnsZoneResourceId: tableDnsZoneResourceId
    queueDnsZoneResourceId: queueDnsZoneResourceId
    fileDnsZoneResourceId: fileDnsZoneResourceId
    storageSubnetResourceId: storageSubnetResourceId
    buildId: buildId
    logicAppName: logicAppName
    uamiPrincipalId: uami.outputs.principalId
    uamiResourceId: uami.outputs.id
    keyVaultName: keyVaultName
    appInsightsInstrumentationKeySecretUri: appInsightsInstrumentationKeySecretUri
    appInsightsConnectionStringSecretUri: appInsightsConnectionStringSecretUri
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    zoneRedundantStorage: zoneRedundantStorage
  }
}

output logicAppName string = logicApp.outputs.name
output logicAppId string = logicApp.outputs.id
output userAssignedManagedIdentityName string = uami.outputs.name
output userAssignedManagedIdentityId string = uami.outputs.id
output userAssignedManagedIdentityClientId string = uami.outputs.clientId
output userAssignedManagedIdentityPrincipalId string = uami.outputs.principalId
