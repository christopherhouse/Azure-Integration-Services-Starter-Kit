@description('The identifier for this workload, used to generate resource names')
param workloadName string

@description('The identifier for the environment, used to generate resource names')
param environmentName string

@description('The identifier for the deployment, used to generate deployment names')
param deploymentName string = deployment().name

@description('The Azure region where resources will be deployed')
param region string

@description('The number of days to retain log data in the Log Analytics workspace')
param logAnalyticsWorkspaceRetentionInDays int = 90

@description('The tags to apply to the resources')
param tags object = {}

module names './nameProvider.bicep' = {
  name: 'names-${deploymentName}'
  params: {
    workloadName: workloadName
    environmentName: environmentName
  }
}

module law './modules/logAnalytics/logAnalyticsWorkspace.bicep' = {
  name: 'law-${deploymentName}'
  params: {
    location: region
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsWorkspaceName
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    tags: tags
  }
}
