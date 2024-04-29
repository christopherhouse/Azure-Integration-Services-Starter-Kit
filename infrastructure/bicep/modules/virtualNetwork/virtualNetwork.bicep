import * as udt from '../../types.bicep'

@description('The name of the virtual network')
param virtualNetworkName string

@description('The Azure region where the virtual network will be created')
param region string

@description('The address prefixes for the virtual network')
param addressPrefixes array // Array of strings, ie ['10.0.0.0/24', '192.168.0.1']

@description('The subnet configurations for the virtual network')
param subnetConfiguration udt.subnetConfigurationsType

@description('The resource ID of the network security group to associate with the API Management subnet')
param apimNsgResourceId string

@description('The resource ID of the network security group to associate with the API Management subnet')
param appGwNsgResourceId string

@description('The tags to associate with the API Center resource')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualNetworkName
  tags: tags
  location: region
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: subnetConfiguration.appServicePrivateEndpointSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.appServicePrivateEndpointSubnet.addressPrefix
          delegations: subnetConfiguration.appServicePrivateEndpointSubnet.delegation == 'none' ? [] : [
            {
              name: subnetConfiguration.appServicePrivateEndpointSubnet.delegation
              properties: {
                serviceName: subnetConfiguration.appServicePrivateEndpointSubnet.delegation
              }
            }
          ]
        }
      }
      {
        name: subnetConfiguration.appServiceVnetIntegrationSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.appServiceVnetIntegrationSubnet.addressPrefix
          delegations: [
            {
              name: subnetConfiguration.appServiceVnetIntegrationSubnet.delegation
              properties: {
                serviceName: subnetConfiguration.appServiceDelegation
              }
            }
          ]
        
        }
      }
      {
        name: subnetConfiguration.servicesSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.servicesSubnet.addressPrefix
          delegations: subnetConfiguration.servicesSubnet.delegation == 'none' ? [] : [
            {
              name: subnetConfiguration.servicesSubnet.delegation
              properties: {
                serviceName: subnetConfiguration.servicesSubnet.delegation
  
              }
            }
          ]
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
output appServicePrivateEndpointSubnetId string = filter(vnet.properties.subnets, subnet => subnet.name == subnetConfiguration.appServicePrivateEndpointSubnet.name)[0].id
output appServiceVnetIntegrationSubnetId string = filter(vnet.properties.subnets, subnet => subnet.name == subnetConfiguration.appServiceVnetIntegrationSubnet.name)[0].id
output servicesSubnetId string = filter(vnet.properties.subnets, subnet => subnet.name == subnetConfiguration.servicesSubnet.name)[0].id
output apimSubnetId string = filter(vnet.properties.subnets, subnet => subnet.name == subnetConfiguration.apimSubnet.name)[0].id
output appGwSubnetId string = filter(vnet.properties.subnets, subnet => subnet.name == subnetConfiguration.appGwSubnet.name)[0].id
