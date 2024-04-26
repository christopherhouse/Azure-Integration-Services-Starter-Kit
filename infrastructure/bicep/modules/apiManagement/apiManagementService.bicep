@description('The name of the API Management resource that will be created')
param apiManagementServiceName string

@description('The region where the new API Management resource will be created')
param location string

@description('The name of the SKU to provision')
@allowed(['Developer', 'Premium']) // Only allow SKUs that support vnet integration
param skuName string

@description('The number of scale units to provision')
param skuCapacity int

@description('The email address associated with the publisher.  This value can be used as the send-from address for email notifications')
param publisherEmailAddress string

@description('THe name of that API publisher\'s organization.  This value is used in the developer portal and for email notifications')
param publisherOrganizationName string

@description('The vnet integration mode, internal for no public gateway endpoint, external to include a public gateway endpoint')
@allowed(['External', 'Internal'])
param vnetIntegrationMode string

@description('The resource id of the subnet to integrate with')
param vnetSubnetResourceId string

@description('The resource id of the public IP address that will be attached to APIM')
param publicIpResourceId string

@description('The resource id of the user assigned managed identity that will be used to access the key vault')
param userAssignedManagedIdentityResourceId string

@description('The principal id of the user assigned managed identity that will be used to access the key vault')
param userAssignedManagedIdentityPrincipalId string

@description('The name of the key vault that will be used to store secrets')
param keyVaulName string

@description('The resource id of the log analytics workspace that will be used to store diagnostic logs')
param logAnalyticsWorkspaceId string

@description('The resource id of the virtual network that will be used to integrate with APIM')
param vnetResourceId string

@description('An array of hostname configurations that will be used to configure the APIM instance')
param hostNameConfigurations hostNameConfigurationsType = []

@description('A flag indicating whether the APIM instance should be zone redundant')
param zoneRedundant bool = false

@description('The tags to associate with the API Center resource')
param tags object = {}

@description('The unique identifier for the deployment')
param deploymentId string

@export()
type hostNameConfigurationType = {
  hostName: string
  keyVaultSecretUrl: string
  type: 'Proxy' | 'Portal' | 'Scm' | 'Management'
}

@export()
type hostNameConfigurationsType = hostNameConfigurationType[]

var hostNameConfigs = [for hostNameConfig in hostNameConfigurations: {
  certificateSource: 'KeyVault'
  hostName: hostNameConfig.hostName
  //identityClientId: userAssignedManagedIdentityClientId
  keyVaultId: hostNameConfig.keyVaultSecretUrl
  type: hostNameConfig.type
}]

var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

var zones = zoneRedundant ? ['1', '2', '3'] : []

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaulName
  scope: resourceGroup()
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: kvSecretsUserRoleId
  scope: subscription()
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, kvSecretsUserRoleId, userAssignedManagedIdentityPrincipalId)
  scope: kv
  properties: {
    principalId: userAssignedManagedIdentityPrincipalId
    roleDefinitionId: kvSecretsUserRole.id
    principalType: 'ServicePrincipal'
  }
}

resource kvRoleAssignmentSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, kvSecretsUserRoleId, apiManagementServiceName)
  scope: kv
  properties: {
    principalId: apiManagementService.identity.principalId
    roleDefinitionId: kvSecretsUserRole.id
    principalType: 'ServicePrincipal'
  }
}

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apiManagementServiceName
  tags: tags
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityResourceId}': {}
    }
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    apiVersionConstraint: {
      minApiVersion: '2021-08-01' // Security best practice, restricts access to mgmt API
    }
    hostnameConfigurations: hostNameConfigs
    publisherEmail: publisherEmailAddress
    publisherName: publisherOrganizationName
    virtualNetworkType: vnetIntegrationMode
    virtualNetworkConfiguration: {
      subnetResourceId: vnetSubnetResourceId
    }
    publicIpAddressId: publicIpResourceId
  }
  zones: zones
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: apiManagementService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
  }
}

module dns '../dns/privateDnsZone.bicep' = {
  name: '${apiManagementService.name}-dns-${deploymentId}'
  params: {
    vnetResourceId: vnetResourceId
    zoneName: 'azure-api.net'
    tags: tags
  }
}

module aRecords '../dns/aRecord.bicep' = {
  name: '${apiManagementService.name}-dns-a-records-${deploymentId}'
  params: {
    zoneName: dns.outputs.zoneName
    ipAddress: apiManagementService.properties.privateIPAddresses[0]
    recordNames: [
      apiManagementService.name
      '${apiManagementService.name}.protal'
      '${apiManagementService.name}.management'
      '${apiManagementService.name}.scm'
    ]
  }
}

output id string = apiManagementService.id
output name string = apiManagementService.name
output privateIpAddress string = apiManagementService.properties.privateIPAddresses[0]
output hostName string = apiManagementService.properties.hostnameConfigurations[0].hostName
