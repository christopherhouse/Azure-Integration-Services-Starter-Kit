import * as udt from '../../types.bicep'

param storageAccountName string
param region string
param subnetId string
param blobDnsZoneId string
param fileDnsZoneId string
param queueDnsZoneId string
param tableDnsZoneId string
param keyVaultName string
param storageConnectionStringSecretName string
param storageConfiguration udt.storageAccountConfigurationType
param tags object

var blobPrivateEndpointName = '${storageAccountName}-blob-pe'
var filePrivateEndpointName = '${storageAccountName}-file-pe'
var queuePrivateEndpointName = '${storageAccountName}-queue-pe'
var tablePrivateEndpointName = '${storageAccountName}-table-pe'

var blobPrivateEndpointDeploymentName = '${blobPrivateEndpointName}-${deployment().name}'
var filePrivateEndpointDeploymentName = '${filePrivateEndpointName}-${deployment().name}'
var queuePrivateEndpointDeploymentName = '${queuePrivateEndpointName}-${deployment().name}'
var tablePrivateEndpointDeploymentName = '${tablePrivateEndpointName}-${deployment().name}'

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: region
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: storageConfiguration.sku
  }
  properties: {
    accessTier: storageConfiguration.accessTier
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource blobSvc 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' existing = {
  parent: storage
  name: 'default'
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for container in storageConfiguration.blobContainers: {
  parent: blobSvc
  name: container
  properties: {
    publicAccess: 'None'
  }
}]

resource tableSvc 'Microsoft.Storage/storageAccounts/tableServices@2022-09-01' existing = {
  parent: storage
  name: 'default'
}

resource tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01' = [for table in storageConfiguration.tables: {
  parent: tableSvc
  name: table
}]

resource queueSvc 'Microsoft.Storage/storageAccounts/queueServices@2022-09-01' existing = {
  parent: storage
  name: 'default'
}

resource queues 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' = [for queue in storageConfiguration.queues: {
  parent: queueSvc
  name: queue
}]

resource fileSvc 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' existing = {
  parent: storage
  name: 'default'
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = [for share in storageConfiguration.fileShares: {
  parent: fileSvc
  name: share.name
  properties: {
    shareQuota: share.quota
  }
}]

module blobPe '../privateEndpoint/privateEndpoint.bicep' = {
  name: blobPrivateEndpointDeploymentName
  params: {
    dnsZoneId: blobDnsZoneId
    groupId: 'blob'
    region: region
    privateEndpointName: blobPrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.id
    tags: tags
  }
}

module filePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: filePrivateEndpointDeploymentName
  params: {
    dnsZoneId: fileDnsZoneId
    groupId: 'file'
    region: region
    privateEndpointName: filePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.id
    tags: tags
  }
}

module queuePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: queuePrivateEndpointDeploymentName
  params: {
    dnsZoneId: queueDnsZoneId
    groupId: 'queue'
    region: region
    privateEndpointName: queuePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.id
    tags: tags
  }
}

module tablePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: tablePrivateEndpointDeploymentName
  params: {
    dnsZoneId: tableDnsZoneId
    groupId: 'table'
    region: region
    privateEndpointName: tablePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.id
    tags: tags
  }
}

module blobSecret '../keyVault/keyVaultSecret.bicep' = if (length(storageConnectionStringSecretName) > 0 && length(keyVaultName) > 0) {
  name: '${storageConnectionStringSecretName}-${deployment().name}'
  params: {
    keyVaultName: keyVaultName
    secretName: storageConnectionStringSecretName
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  }
}


output id string = storage.id
output name string = storage.name
output connectionStringSecretUri string = blobSecret.outputs.secretUri
