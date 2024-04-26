@description('The name of the API Center resource to create')
param apiCenterName string

@description('The Azure resource where the API Center resource will be created.  NOT CURRENTLY USED, REGION IS HARD-CODED')
param location string

@description('The name of the API Center workspace to create')
param apiCenterWorkspaceName string

@description('The tags to associate with the API Center resource')
param tags object = {}

resource apiCenter 'Microsoft.ApiCenter/services@2024-03-01' = {
  name: apiCenterName
  tags: tags
  location: 'eastus' // Hardcoded to eastus for now since API Center is available in limited environments
  sku: {
    name: 'None'
  }
  properties: {
  }
}

resource workspace 'Microsoft.ApiCenter/services/workspaces@2024-03-01' = {
  name: apiCenterWorkspaceName
  parent: apiCenter
  properties: {
    title: apiCenterWorkspaceName
    description: '${apiCenterWorkspaceName} workspace'
  }
}
