param eventHubNamespaceName string
param region string
param vnetResourceId string
param subnetResourceId string
param dnsZoneResourceId string
param logAnalyticsWorkspaceResourceId string
param eventHubConfiguration eventHubConfigurationType
param tags {}

@export()
type eventHubEnabledConfiguration = {
    deployEventHub: 'yes'
    serviceProperties: {
        capacityUnits: int
        enableZoneRedundancy: bool
    }
}

@export()
type eventHubDisabledConfiguration = {
    deployEventHub: 'no'
}

@export()
@discriminator('deployEventHub')
type eventHubConfigurationType = eventHubEnabledConfiguration | eventHubDisabledConfiguration

resource ehNs 'Microsoft.EventHub/namespaces@2024-01-01' = {
    name: eventHubNamespaceName
    location: region
    tags: tags
    sku: {
        name: 'Premium'
        capacity: eventHubConfiguration.serviceProperties.capacityUnits
    }
    properties: {
        zoneRedundant: eventHubConfiguration.serviceProperties.enableZoneRedundancy
        publicNetworkAccess: 'Disabled'
    }
}

module pe '../privateEndpoint/privateEndpoint.bicep' = {
    name: 'ehns-pe-${deployment().name}'
    params: {
        dnsZoneId: dnsZoneResourceId
        groupId: 'namespace'
        privateEndpointName: '${eventHubNamespaceName}-pe'
        region: region
        subnetId: subnetResourceId
        targetResourceId: ehNs.id
    }
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
    name: 'laws'
    scope: ehNs
    properties: {
        logs: [
            {
                category: 'allLogs'
                enabled: true
            }
        ]
    }
}

output id string = ehNs.id
output name string = ehNs.name
