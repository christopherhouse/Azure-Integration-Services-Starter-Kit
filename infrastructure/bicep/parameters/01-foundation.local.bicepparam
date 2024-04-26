using '../01-foundation.bicep'
param workloadName = 'ais-sk'
param environmentName = 'loc'
param region = 'eastus'
param tags = {
  Project_Name: 'AIS Stater Kit'
}
param logAnalyticsWorkspaceRetentionInDays = 90
