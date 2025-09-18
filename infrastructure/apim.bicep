@description('Name of the API Management service')
param apimServiceName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('SKU of the API Management service')
@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

@description('The email address of the owner of the service')
param publisherEmail string

@description('The name of the owner of the service')
param publisherName string

@description('Environment name')
param environment string

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimServiceName
  location: location
  sku: {
    name: sku
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
    }
  }
  tags: {
    Environment: environment
    Purpose: 'APIM CI/CD Demo'
  }
}

// Create a product for the demo APIs
resource demoProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apimService
  name: 'demo-product'
  properties: {
    displayName: 'Demo Product'
    description: 'Demo product for APIM CI/CD showcase'
    state: 'published'
    subscriptionRequired: true
    approvalRequired: false
  }
}

// Create a demo group
resource demoGroup 'Microsoft.ApiManagement/service/groups@2023-05-01-preview' = {
  parent: apimService
  name: 'demo-developers'
  properties: {
    displayName: 'Demo Developers'
    description: 'Demo group for developers'
    type: 'custom'
  }
}

// Link product to group
resource productGroup 'Microsoft.ApiManagement/service/products/groups@2023-05-01-preview' = {
  parent: demoProduct
  name: demoGroup.name
}

output apimServiceName string = apimService.name
output apimServiceUrl string = apimService.properties.gatewayUrl
output apimResourceGroup string = resourceGroup().name