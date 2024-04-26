@description('The name of the private DNS zone')
param zoneName string
@description('The resource ID of the virtual network the zone will link to')
param vnetResourceId string
@description('The tags to associate with the API Center resource')
param tags object = {}

resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  tags: tags
  location: 'global'
  properties: {}
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: zone
  tags: tags
  name: uniqueString(zone.id)
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetResourceId
    }
  }
}

output id string = zone.id
output zoneName string = zone.name
