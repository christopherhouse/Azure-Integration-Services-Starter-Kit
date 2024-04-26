param storageAccountName string
param location string
param fileShares array
param storageConnectionStringSecretName string
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageAccountSku string
param keyVaultName string
param buildId string

/*
fileShares should be an array of objects with the following structure:
[
  {
    "shareName": "share1",
    "quota": 1024
  },
  {
    "shareName": "share2",
    "quota": 2048
  }
]
*/

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSku
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'default'
  parent: storage
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = [for fileShare in fileShares : {
  name: fileShare.shareName
  parent: fileServices
  properties: {
    shareQuota: fileShare.quota
  }
}]

module blobSecret '../keyVault/keyVaultSecret.bicep' = if (length(storageConnectionStringSecretName) > 0 && length(keyVaultName) > 0) {
  name: '${storageConnectionStringSecretName}-${buildId}'
  params: {
    keyVaultName: keyVaultName
    secretName: storageConnectionStringSecretName
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  }
}

output id string = storage.id
output name string = storage.name
output connectionStringSecretUri string = blobSecret.outputs.secretUri
