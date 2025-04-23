param tenantId string = '9882c17f-9662-42ad-bdb0-07923b42850f' // Replace with your actual tenant ID
param resourceGroupName string = 'acrresourcegroup'
param location string = 'eastus'
param keyVaultName string = 'cachekv'
param acrName string = 'cacheacr2222'
param loginServer string = 'docker.io'
param repoName string = 'nginx'
param sourceRepo string = 'docker.io/library/nginx'


resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource credentialSet 'Microsoft.ContainerRegistry/registries/credentialSets@2025-04-01' = {
  name: 'credentialset'
  parent: containerRegistry
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    loginServer: loginServer
    authCredentials: [
      {
        name: 'credential1'
        usernameSecretIdentifier: 'https://${keyVaultName}.vault.azure.net/secrets/repousername'
        passwordSecretIdentifier: 'https://${keyVaultName}.vault.azure.net/secrets/repopassword'
      }
    ]
  }
}

resource cacheRule 'Microsoft.ContainerRegistry/registries/cacheRules@2025-04-01' = {
  name: repoName
  parent: containerRegistry
  properties: {
    targetRepository: repoName
    sourceRepository: sourceRepo
    credentialSetResourceId: credentialSet.id
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVault.id, containerRegistry.id)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: credentialSet.identity.principalId
  }
}

