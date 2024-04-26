using '../02-main.bicep'
import * as apimTypes from '../modules/apiManagement/apiManagementService.bicep'

param workloadName = 'ais-sk'
param environmentName = 'loc'
param region = 'eastus'
param subnetConfigurations = {
  apimSubnet: {
    addressPrefix: '10.254.0.248/29'
    delegation: 'none'
    name: 'apim-subnet'
  }
  appGwSubnet: {
    addressPrefix: '10.254.0.0/26'
    delegation: 'none'
    name: 'appgw-subnet'
  }
  appServiceSubnet: {
    addressPrefix: '10.254.0.64/26'
    delegation: 'Microsoft.Web/hostingEnvironments'
    name: 'appservice-subnet'
  }
  servicesSubnet: {
    addressPrefix: '10.254.0.192/27'
    delegation: 'none'
    name: 'services-subnet'
  }
}
param apimConfiguration = {
  deployApim: 'yes'
  serviceProperties: {
    skuName: 'Developer'
    skuCapacity: 1
    publisherEmailAddress: 'foo.bar@bizbaz.yyz'
    publisherOrganizationName: 'Contoso'
  }
}
