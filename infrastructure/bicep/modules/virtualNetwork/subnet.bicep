@description('The name of the subnet to create')
param subnetName string

@description('The name of the VNet to create the subnet in')
param vnetName string

@description('The address prefix for the subnet')
param addressPrefix string

@description('The delegation name for the subnet, use `none` if there is no delegation')
param delegation string = 'none'

@description('The NSG resource ID to associate with the subnet, `` for no nsg')
param nsgResourceId string = ''

@description('The service endpoints to associate with the subnet, use `[]` for no service endpoints')
param serviceEndpoints array = []

var serviceEndpointsConfig = [for endpoint in serviceEndpoints: {
  service: endpoint
}]

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: nsgResourceId == '' ? null :{
      id: nsgResourceId
    }
    delegations: delegation == 'none' ? [] : [
      {
        name: delegation
        properties: {
          serviceName: delegation
        }
      }
    ]
    serviceEndpoints: serviceEndpointsConfig
  }
}

output subnetId string = subnet.id
