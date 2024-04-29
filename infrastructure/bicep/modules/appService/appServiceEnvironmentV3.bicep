param aseName string
param region string
param aseSubnetResourceId string
param logAnalyticsWorkspaceResourceId string
param tags object

resource ase 'Microsoft.Web/hostingEnvironments@2023-01-01' = {
  name: aseName
  location: region
  tags: tags
  kind: 'ASEV3'
  properties: {
    internalLoadBalancingMode: 'Web, Publishing'
    virtualNetwork: {
      id: aseSubnetResourceId
    }
  }
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: ase
  properties: {
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
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

output id string = ase.id
output dnsSuffix string = ase.properties.dnsSuffix
