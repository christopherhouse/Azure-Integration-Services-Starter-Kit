@description('The name of the network security group to create')
param networkSecurityGroupName string

@description('The Azure region where the network security group should be created')
param region string

@description('The ID of the Log Analytics workspace to send diagnostic logs to')
param logAnalyticsWorkspaceId string

@description('The subnet range for the API Management subnet')
param apimSubnetRange string

@description('The subnet range for the Application Gateway subnet')
param appGatewaySubnetRange string

param appServiceOutboundSubnetRange string

@description('The subnet range for the services subnet')
param servicesSubnet string

@description('The tags to associate with the API Center resource')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: networkSecurityGroupName
  tags: tags
  location: region
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
        name: 'AllowAPIMandAppGWAndAppsToKeyVault'
        properties: {
          priority: 200
          protocol:'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '443'
            '5671-5672'
          ]
          sourceAddressPrefixes: [
            appGatewaySubnetRange
            apimSubnetRange
            appServiceOutboundSubnetRange
          ]
          destinationAddressPrefix: servicesSubnet
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
      {
        name: 'DenySSHRDPOutbound'
        properties: {
          priority: 3000
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Deny'
          direction: 'Outbound'
          description: 'Deny Management traffic outbound'
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
