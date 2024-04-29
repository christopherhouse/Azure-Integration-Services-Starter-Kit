param appServicePlanName string
param region string
// This module expects to deploy to ASE, so only allow Isolated SKUs
@allowed(['P0v3'
  'P1v3'
  'P2v3'
  'P3v3'
  'P1mv3'
  'P2mv3'
  'P3mv3'
  'P4mv3'
  'P5mv3'
  'I1v2'
  'I1mv2'
  'I2v2'
  'I2mv2'
  'I3v2'
  'I3mv2'
  'I4v2'
  'I4mv2'
  'I5v2'
  'I5mv2'
  'I6v2'])
param skuName string
param skuCapacity int = 1
param aseResourceId string?
param zoneRedundant bool
param tags object

var profile = aseResourceId != null ? {
    id: aseResourceId
} : null

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: region
  tags: tags
  properties: {
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerSizeId: 0
    hostingEnvironmentProfile: profile
    zoneRedundant: zoneRedundant
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
