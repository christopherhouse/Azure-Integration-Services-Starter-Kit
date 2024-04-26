@description('The identifier for this workload, used to generate resource names')
param workloadName string

@description('The identifier for the environment, used to generate resource names')
param environmentName string

@description('The identifier for the deployment, used to generate deployment names')
param deploymentName string

var vnetName = '${workloadName}-${environmentName}-vnet'
var vnetDeploymentName = '${vnetName}-${deploymentName}'
