import * as udt from '../../../types.bicep'

param logicAppName string
param region string
param aseResourceId string?
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
param logicAppConfiguration udt.logicAppASEConfigurationType
param storageAccountConfiguration udt.storageAccountConfigurationType
param tags object

var logicAppUamiName = '${logicAppName}-uami'
var logicAppUamiDeploymentName = '${logicAppUamiName}-${deployment().name}'

module uami '../../managedIdentity/userAssignedManagedIdentity.bicep' = {
  name: logicAppUamiDeploymentName
  params: {
    managedIdentityName: logicAppUamiName
    location: region
  }
}

module logicApp './logicApp.bicep' = {
  name: '${logicAppName}-mod-${deployment().name}'
  params: {
    blobDnsZoneResourceId: blobDnsZoneResourceId
    tableDnsZoneResourceId: tableDnsZoneResourceId
    queueDnsZoneResourceId: queueDnsZoneResourceId
    fileDnsZoneResourceId: fileDnsZoneResourceId
    storageSubnetResourceId: storageSubnetResourceId
    logicAppName: logicAppName
    uamiPrincipalId: uami.outputs.principalId
    uamiResourceId: uami.outputs.id
    keyVaultName: keyVaultName
    appInsightsInstrumentationKeySecretUri: appInsightsInstrumentationKeySecretUri
    appInsightsConnectionStringSecretUri: appInsightsConnectionStringSecretUri
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    logicAppConfiguration: logicAppConfiguration
    region: region
    storageAccountConfiguration: storageAccountConfiguration
    tags: tags
  }
}

output logicAppName string = logicApp.outputs.name
output logicAppId string = logicApp.outputs.id
output userAssignedManagedIdentityName string = uami.outputs.name
output userAssignedManagedIdentityId string = uami.outputs.id
output userAssignedManagedIdentityClientId string = uami.outputs.clientId
output userAssignedManagedIdentityPrincipalId string = uami.outputs.principalId
