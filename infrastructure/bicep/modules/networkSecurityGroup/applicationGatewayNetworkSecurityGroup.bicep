@description('The name of the network security group to create')
param networkSecurityGroupName string

@description('The location where the network security group will be created')
param location string

@description('The resource ID of the Log Analytics workspace to send diagnostic logs to')
param logAnalyticsWorkspaceResourceId string

@description('The address space of the subnet where the app gateway is deployed')
param appGatewaySubnetAddressSpace string

@description('The tags to associate with the API Center resource')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: networkSecurityGroupName
  tags: tags
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInboundFromInternetToAppGW'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: appGatewaySubnetAddressSpace
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowGatewayManangerToAppGW'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Allow_Azure_Load_Balancer_Any_Any'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }      
      {
        name: 'DenyVNetInbound'
        properties: {
          priority: 4096
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          direction: 'Inbound'
          description: 'Deny all inbound'
        }
      }      
    ]
  }
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: nsg
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
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
