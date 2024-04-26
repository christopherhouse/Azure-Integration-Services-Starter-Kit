@description('The name of the virtual network')
param virtualNetworkName string

@description('The Azure region where the virtual network will be created')
param location string

@description('The address prefixes for the virtual network')
param addressPrefixes array // Array of strings, ie ['10.0.0.0/24', '192.168.0.1']

@description('The subnet configurations for the virtual network')
param subnetConfiguration subnetConfigurationsType

@description('The resource ID of the network security group to associate with the API Management subnet')
param apimNsgResourceId string

@description('The resource ID of the network security group to associate with the API Management subnet')
param appGwNsgResourceId string

@description('The resource ID of the network security group to associate with the Key Vault subnet')
param keyVaultNsgResourceId string

@description('The tags to associate with the API Center resource')
param tags object = {}

@export()
type subnetConfigurationType = {
  name: string
  addressPrefix: string
  delegation: string
}

@export()
type subnetConfigurationsType = {
  appServiceOutboundSubnet: subnetConfigurationType
  appServiceInboundSubnet: subnetConfigurationType
  keyVaultSubnet: subnetConfigurationType
  apimSubnet: subnetConfigurationType
  appGwSubnet: subnetConfigurationType
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualNetworkName
  tags: tags
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: subnetConfiguration.appServiceOutboundSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.appServiceOutboundSubnet.addressPrefix
          delegations: subnetConfiguration.appServiceOutboundSubnet.delegation == 'none' ? [] : [
            {
              name: subnetConfiguration.appServiceOutboundSubnet.delegation
              properties: {
                serviceName: subnetConfiguration.appServiceOutboundSubnet.delegation
              }
            }
          ]
        }
      }
      {
        name: subnetConfiguration.appServiceInboundSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.appServiceInboundSubnet.addressPrefix
          delegations: subnetConfiguration.appServiceInboundSubnet.delegation == 'none' ? [] : [
            {
              name: subnetConfiguration.appServiceInboundSubnet.delegation
              properties: {
                serviceName: subnetConfiguration.appServiceInboundSubnet.delegation
              }
            }
          ]
        }
      }
      {
        name: subnetConfiguration.keyVaultSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.keyVaultSubnet.addressPrefix
          delegations: subnetConfiguration.keyVaultSubnet.delegation == 'none' ? [] : [
            {
              name: subnetConfiguration.keyVaultSubnet.delegation
              properties: {
                serviceName: subnetConfiguration.keyVaultSubnet.delegation
  
              }
            }
          ]
          networkSecurityGroup: {
            id: keyVaultNsgResourceId
          }
        }
      }
      {
        name: subnetConfiguration.apimSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.apimSubnet.addressPrefix
          delegations: subnetConfiguration.apimSubnet.delegation == 'none' ? [] : [
            {
              name: subnetConfiguration.apimSubnet.delegation
              properties: {
                serviceName: subnetConfiguration.apimSubnet.delegation
              }
            }
          ]
          networkSecurityGroup: {
            id: apimNsgResourceId
          }
        }
      }
      {
        name: subnetConfiguration.appGwSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.appGwSubnet.addressPrefix
          delegations: subnetConfiguration.appGwSubnet.delegation == 'none' ? [] : [
            {
              name: subnetConfiguration.appGwSubnet.delegation
              properties: {
                serviceName: subnetConfiguration.appGwSubnet.delegation
              }
            }
          ]
          networkSecurityGroup: {
            id: appGwNsgResourceId
          }
        }
      }
    ]
  }
}

output id string = vnet.id
output name string = vnet.name
output kvSubnetId string = vnet.properties.subnets[2].id
