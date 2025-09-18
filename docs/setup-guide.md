# APIM CI/CD Demo - Setup Guide

This guide walks you through setting up the Azure API Management CI/CD demo in your own Azure environment.

## Prerequisites

- Azure subscription with Owner or Contributor access
- Azure CLI installed and configured
- GitHub account
- Basic knowledge of Azure services and CI/CD concepts

## Step 1: Fork the Repository

1. Fork this repository to your GitHub account
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/nzaplapimcicd.git
   cd nzaplapimcicd
   ```

## Step 2: Create Azure Resources

### Create Resource Groups

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create resource groups
az group create --name rg-apim-dev --location "East US 2"
az group create --name rg-apim-prod --location "East US 2"
```

### Create a Service Principal

Create a service principal for GitHub Actions:

```bash
az ad sp create-for-rbac --name "github-actions-apim-demo" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth
```

Save the JSON output - you'll need it for GitHub secrets.

## Step 3: Configure GitHub Secrets

In your GitHub repository, go to Settings > Secrets and Variables > Actions, and add these secrets:

```
AZURE_CREDENTIALS: {paste the entire JSON output from service principal creation}
AZURE_SUBSCRIPTION_ID: your-subscription-id
AZURE_TENANT_ID: your-tenant-id
AZURE_CLIENT_ID: your-client-id
AZURE_CLIENT_SECRET: your-client-secret
```

## Step 4: Update Environment Configuration

Edit the files in the `environments/` directory:

### `environments/development.env`
```bash
ENVIRONMENT=development
APIM_SERVICE_NAME=apim-demo-dev-YOUR_INITIALS
RESOURCE_GROUP=rg-apim-dev
SUBSCRIPTION_ID=your-subscription-id
PUBLISHER_EMAIL=your-email@domain.com
PUBLISHER_NAME="Your Dev Team"
RUN_TESTS=true
OPENWEATHERMAP_API_KEY=your-openweather-api-key
```

### `environments/production.env`
```bash
ENVIRONMENT=production
APIM_SERVICE_NAME=apim-demo-prod-YOUR_INITIALS
RESOURCE_GROUP=rg-apim-prod
SUBSCRIPTION_ID=your-subscription-id
PUBLISHER_EMAIL=your-email@domain.com
PUBLISHER_NAME="Your Production Team"
RUN_TESTS=false
OPENWEATHERMAP_API_KEY=your-production-openweather-api-key
```

## Step 5: Get OpenWeatherMap API Key

1. Sign up for a free account at [OpenWeatherMap](https://openweathermap.org/api)
2. Get your API key
3. Update the environment files with your API key

## Step 6: Update Infrastructure Parameters

Edit the parameter files in `infrastructure/`:

### `infrastructure/parameters.dev.json`
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "apimServiceName": {
      "value": "apim-demo-dev-YOUR_INITIALS"
    },
    "publisherEmail": {
      "value": "your-email@domain.com"
    },
    "publisherName": {
      "value": "Your Dev Team"
    }
  }
}
```

### `infrastructure/parameters.prod.json`
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "apimServiceName": {
      "value": "apim-demo-prod-YOUR_INITIALS"
    },
    "sku": {
      "value": "Standard"
    },
    "publisherEmail": {
      "value": "your-email@domain.com"
    },
    "publisherName": {
      "value": "Your Production Team"
    }
  }
}
```

## Step 7: Set Up Branch Protection

1. In GitHub, go to Settings > Branches
2. Add a branch protection rule for `main`:
   - Require pull request reviews before merging
   - Require status checks to pass before merging
   - Include administrators

## Step 8: Test the Setup

### Manual Deployment

Test the deployment scripts locally:

```bash
# Make scripts executable
chmod +x scripts/deploy-apis.sh
chmod +x scripts/health-check.sh

# Test infrastructure deployment
az deployment group create \
  --resource-group rg-apim-dev \
  --template-file infrastructure/apim.bicep \
  --parameters @infrastructure/parameters.dev.json

# Test API deployment (after APIM is provisioned)
./scripts/deploy-apis.sh development

# Run health check
./scripts/health-check.sh development
```

### Automated Deployment

1. Create a `develop` branch:
   ```bash
   git checkout -b develop
   git push origin develop
   ```

2. Make a small change and push to trigger the pipeline:
   ```bash
   echo "# Test" >> test.md
   git add test.md
   git commit -m "Test CI/CD pipeline"
   git push origin develop
   ```

3. Check the Actions tab in GitHub to see the pipeline running

## Step 9: Configure APIM Named Values

After the APIM service is deployed, configure the OpenWeatherMap API key as a named value:

```bash
az apim nv create \
  --resource-group rg-apim-dev \
  --service-name apim-demo-dev-YOUR_INITIALS \
  --named-value-id openweathermap-api-key \
  --display-name "OpenWeatherMap API Key" \
  --value "your-api-key" \
  --secret true
```

## Step 10: Test the APIs

### Using Postman

1. Import the collection from `testing/postman-collection.json`
2. Update the environment variables:
   - `apim_base_url`: Your APIM gateway URL
   - `subscription_key`: Get this from the APIM developer portal
3. Run the tests

### Using curl

```bash
# Get subscription key from APIM portal first
SUBSCRIPTION_KEY="your-subscription-key"
APIM_URL="https://apim-demo-dev-YOUR_INITIALS.azure-api.net"

# Test current weather
curl -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" \
  "$APIM_URL/weather/weather?q=London,UK&units=metric"

# Test forecast
curl -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" \
  "$APIM_URL/weather/forecast?q=London,UK&units=metric"
```

## Troubleshooting

### Common Issues

1. **APIM service name conflicts**: APIM service names must be globally unique. Add your initials or a random suffix.

2. **Subscription key not working**: Make sure you've subscribed to the "Demo Product" in the APIM developer portal.

3. **401 Unauthorized from OpenWeatherMap**: Verify your API key is correctly configured in APIM named values.

4. **GitHub Actions failing**: Check that all secrets are correctly configured and the service principal has the right permissions.

### Getting Help

- Check the GitHub Actions logs for detailed error messages
- Use `az apim` commands to inspect your APIM configuration
- Review Azure portal for resource deployment status

## Next Steps

1. **Add more APIs**: Create additional OpenAPI specifications and policies
2. **Enhance monitoring**: Set up Application Insights and custom dashboards
3. **Implement blue-green deployments**: Use APIM revisions for zero-downtime deployments
4. **Add security**: Implement OAuth 2.0, JWT validation, or IP filtering
5. **Performance testing**: Add load testing to your CI/CD pipeline

## Clean Up

To remove all resources:

```bash
az group delete --name rg-apim-dev --yes --no-wait
az group delete --name rg-apim-prod --yes --no-wait
```