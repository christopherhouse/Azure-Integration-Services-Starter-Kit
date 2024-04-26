@description('The name of the network security group to create')
param networkSecurityGroupName string

@description('The Azure region where the network security group should be created')
param location string

@description('The ID of the Log Analytics workspace to send diagnostic logs to')
param logAnalyticsWorkspaceId string

@description('The subnet range for the API Management subnet')
param apimSubnetRange string

@description('The subnet range for the Application Gateway subnet')
param appGatewaySubnetRange string

@description('The subnet range for the Key Vault subnet')
param keyVaultSubnetRange string

@description('The tags to associate with the API Center resource')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: networkSecurityGroupName
  tags: tags
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          priority: 100
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
          description: 'Allow Azure Load Balancer inbound'
        
        }
      }
      {
        name: 'AllowAPIMandAppGWtoKeyVault'
        properties: {
          priority: 200
          protocol:'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefixes: [
            appGatewaySubnetRange
            apimSubnetRange
          ]
          destinationAddressPrefix: keyVaultSubnetRange
          access: 'Allow'
          direction: 'Inbound'
          description: 'Allow HTTPS from APIM subnet to KeyVault subnet'
        }
      }
      {
        name: 'DenyVNetInbound'
        properties: {
          priority: 2000
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          direction: 'Inbound'
          description: 'Deny all inbound traffic within the VNet'
        }
      }
    ]
  }
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: nsg
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

output id string = nsg.id
output name string = nsg.name
