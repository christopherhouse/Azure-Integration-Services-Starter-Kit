@export()
@discriminator('deployAppServicePlans')
type appServicePlanConfigurationType = appServicePlanEnabledConfigurationType | appServicePlanDisabledConfigurationType

@export()
type appServicePlanEnabledConfigurationType = {
    deployAppServicePlans: 'yes'
    serviceProperties: {
      useAppServiceEnvironment: bool
      plans: [
        {
          planName: string
          skuCapacity: int
          sku: 'P0v3' | 'P1v3' | 'P2v3' | 'P3v3' | 'P1mv3' | 'P2mv3' | 'P3mv3' | 'P4mv3' | 'P5mv3' | 'I1v2' | 'I1mv2' | 'I2v2' | 'I2mv2' | 'I3v2' | 'I3mv2' | 'I4v2' | 'I4mv2' | 'I5v2' | 'I5mv2' | 'I6v2'
          zoneRedundant: bool
        }
      ]
  }
}

@export()
type appServicePlanDisabledConfigurationType = {
  deployAppServicePlans: 'no'
}

@export()
type subnetConfigurationType = {
  name: string
  addressPrefix: string
  delegation: string
}

@export()
type subnetConfigurationsType = {
  appServiceDelegation: 'Microsoft.Web/serverFarms' | 'Microsoft.Web/hostingEnvironments'
  appServiceVnetIntegrationSubnet: subnetConfigurationType
  appServicePrivateEndpointSubnet: subnetConfigurationType
  servicesSubnet: subnetConfigurationType
  apimSubnet: subnetConfigurationType
  appGwSubnet: subnetConfigurationType
}

// APIM
@export()
@discriminator('deployApim')
type apimConfiguration = apimEnabledConfiguration | apimDisabledConfiguration

@export()
type apimEnabledConfiguration = {
  deployApim: 'yes'
  serviceProperties: {
    skuName: apimSkuType
    skuCapacity: int
    publisherEmailAddress : string
    publisherOrganizationName : string
  }
}

@export()
type apimDisabledConfiguration = {
  deployApim: 'no'
}

@export()
type apimServiceProperties = {
  skuName: apimSkuType
  skuCapacity: int
  publisherEmailAddress : string
  publisherOrganizationName : string
}

@export()
type hostNameConfigurationType = {
  hostName: string
  keyVaultSecretUrl: string
  type: 'Proxy' | 'Portal' | 'Scm' | 'Management'
}

@export()
@description('The type of SKU to provision')
type apimSkuType = 'Developer' | 'Premium'

@export()
@description('The vnet integration mode, internal for no public gateway endpoint, external to include a public gateway endpoint')
type vnetIntegrationModeType = 'External' | 'Internal'

@export()
type hostNameConfigurationsType = hostNameConfigurationType[]

// Logic Apps
@export()
@discriminator('deployLogicApps')
type logicAppDeploymentConfigurationType = logicAppEnabledConfigurationType | logicAppDisabledConfigurationType

@export()
type logicAppEnabledConfigurationType = {
  deployLogicApps: 'yes'
  logicApps: [
    {
      logicAppName: string
      appServicePlanName: string
    }
  ]
}

@export()
type logicAppDisabledConfigurationType = {
  deployLogicApps: 'no'
}

@export()
@discriminator('deployToAppServiceEnvironment')
type logicAppConfigurationType = logicAppPEConfigurationType | logicAppASEConfigurationType

@export()
type logicAppPEConfigurationType = {
  deployToAppServiceEnvironment: 'no'
  appServicePlanResourceId: string
  siteDnsZoneResourceId: string
  scmDnsZoneResourceId: string
  privateEndpointSubnetId: string
  vnetIntegrationSubnetId: string
}

@export()
type logicAppASEConfigurationType = {
  deployToAppServiceEnvironment: 'yes'
  aseResourceId: string
  appServicePlanResourceId: string
}

// Storage
@export()
type storageAccountConfigurationType = {
  accessTier: 'Cool' | 'Hot' | 'Premium'
  sku: 'Standard_ZRS' | 'Standard_LRS' | 'Standard_GRS' | 'Standard_GZRS' | 'Standard_RAGRS' | 'Standard_RAGZRS' | 'Premium_LRS' | 'Premium_ZRS'
  blobContainers: string[]?
  tables: string[]?
  queues: string[]?
  fileShares: fileShareConfigurationType[]
  addConnectionStringToKeyVault: bool
}

@export()
type fileShareConfigurationType = {
  name: string
  quota: int
}
