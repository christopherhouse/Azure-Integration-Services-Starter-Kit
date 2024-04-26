param storageAccountName string
param buildId string
param location string
param subnetId string
param blobDnsZoneId string
param fileDnsZoneId string
param queueDnsZoneId string
param tableDnsZoneId string
param fileShares array = []
param keyVaultName string
param storageConnectionStringSecretName string
param zoneRedundant bool

/*
  The fileShares parameter expects an array of objects with the following structure:
  [
    {
      name: 'share1',
      quota: 1024
    },
    {
      name: 'share2',
      quota: 2048
    }
  ]
*/

var blobPrivateEndpointName = '${storageAccountName}-blob-pe'
var filePrivateEndpointName = '${storageAccountName}-file-pe'
var queuePrivateEndpointName = '${storageAccountName}-queue-pe'
var tablePrivateEndpointName = '${storageAccountName}-table-pe'

var blobPrivateEndpointDeploymentName = '${blobPrivateEndpointName}-${buildId}'
var filePrivateEndpointDeploymentName = '${filePrivateEndpointName}-${buildId}'
var queuePrivateEndpointDeploymentName = '${queuePrivateEndpointName}-${buildId}'
var tablePrivateEndpointDeploymentName = '${tablePrivateEndpointName}-${buildId}'

var storageAccountDeploymentName = '${storageAccountName}-mod-${buildId}'

var storageSku = zoneRedundant ? 'Standard_ZRS' : 'Standard_LRS'

module storage './storageAccount.bicep' = {
  name: storageAccountDeploymentName
  params: {
    storageAccountName: storageAccountName
    location: location
    fileShares: fileShares
    buildId: buildId
    keyVaultName: keyVaultName
    storageConnectionStringSecretName: storageConnectionStringSecretName
    storageAccountSku: storageSku
  }
}

module blobPe '../privateEndpoint/privateEndpoint.bicep' = {
  name: blobPrivateEndpointDeploymentName
  params: {
    dnsZoneId: blobDnsZoneId
    groupId: 'blob'
    location: location
    privateEndpointName: blobPrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.outputs.id
  }
}

module filePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: filePrivateEndpointDeploymentName
  params: {
    dnsZoneId: fileDnsZoneId
    groupId: 'file'
    location: location
    privateEndpointName: filePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.outputs.id
  }
}

module queuePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: queuePrivateEndpointDeploymentName
  params: {
    dnsZoneId: queueDnsZoneId
    groupId: 'queue'
    location: location
    privateEndpointName: queuePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.outputs.id
  }
}

module tablePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: tablePrivateEndpointDeploymentName
  params: {
    dnsZoneId: tableDnsZoneId
    groupId: 'table'
    location: location
    privateEndpointName: tablePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.outputs.id
  }
}

output id string = storage.outputs.id
output name string = storage.outputs.name
output connectionStringSecretUri string = storage.outputs.connectionStringSecretUri
