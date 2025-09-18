# Azure API Management CI/CD Demo

This repository demonstrates a complete CI/CD pipeline for Azure API Management (APIM) using Infrastructure as Code (IaC) and GitOps principles.

## 🏗️ Architecture

The demo includes:

- **Infrastructure as Code**: Bicep templates for APIM provisioning
- **API Management**: OpenAPI specifications and policies
- **CI/CD Pipeline**: GitHub Actions workflows for automated deployment
- **Environment Management**: Separate configurations for dev/prod
- **API Governance**: Linting and validation using Spectral

## 📁 Repository Structure

```
├── .github/workflows/          # GitHub Actions CI/CD pipelines
├── infrastructure/             # Bicep templates and parameters
├── api-specs/                  # OpenAPI specifications
├── policies/                   # APIM policy definitions
├── scripts/                    # Deployment scripts
├── environments/               # Environment-specific configurations
└── README.md                   # This file
```

## 🚀 Getting Started

### Prerequisites

- Azure subscription
- Azure CLI installed
- Node.js 18+ (for API validation tools)
- Git

### Setup

1. **Fork this repository**

2. **Configure Azure credentials** in GitHub Secrets:
   ```
   AZURE_CREDENTIALS: JSON containing service principal credentials
   AZURE_SUBSCRIPTION_ID: Your Azure subscription ID
   AZURE_TENANT_ID: Your Azure tenant ID
   AZURE_CLIENT_ID: Service principal client ID
   AZURE_CLIENT_SECRET: Service principal client secret
   ```

3. **Update environment configurations** in `environments/` folder:
   - `development.env`: Development environment settings
   - `production.env`: Production environment settings

4. **Create Azure Resource Groups**:
   ```bash
   az group create --name rg-apim-dev --location "East US 2"
   az group create --name rg-apim-prod --location "East US 2"
   ```

## 🔄 CI/CD Workflow

### Workflow Triggers

- **Development**: Triggered on push to `develop` branch
- **Production**: Triggered on push to `main` branch
- **Validation**: Triggered on all pull requests

### Pipeline Stages

1. **Validate**: 
   - OpenAPI specification validation using swagger-cli
   - API governance checks using Spectral
   
2. **Deploy Infrastructure**: 
   - Deploy APIM service using Bicep templates
   - Configure products, groups, and policies
   
3. **Deploy APIs**: 
   - Import API specifications
   - Apply transformation policies
   - Configure rate limiting and security

## 📋 API Specifications

### Weather API

A demo weather API that showcases:
- RESTful API design
- Comprehensive OpenAPI documentation
- Request/response schemas
- Error handling patterns

**Endpoints:**
- `GET /weather` - Get current weather
- `GET /forecast` - Get weather forecast

## 🛡️ API Policies

### Rate Limiting
- **Development**: 100 calls/hour, 1000 calls/day
- **Production**: 200 calls/hour, 5000 calls/day

### Security
- CORS configuration
- Header sanitization
- API key injection

### Transformation
- Automatic API key injection for backend calls
- Response header enrichment
- User-Agent modification

## 🧪 Testing

API specifications are automatically validated on every commit:

```bash
# Install validation tools
npm install -g @apidevtools/swagger-cli @stoplight/spectral-cli

# Validate OpenAPI specs
swagger-cli validate api-specs/weather-api.yaml

# Run governance checks
spectral lint api-specs/weather-api.yaml --ruleset api-specs/.spectral.yml
```

## 🔧 Local Development

### Manual Deployment

To deploy manually to a specific environment:

```bash
# Make the script executable
chmod +x scripts/deploy-apis.sh

# Deploy to development
./scripts/deploy-apis.sh development

# Deploy to production
./scripts/deploy-apis.sh production
```

### Infrastructure Deployment

Deploy APIM infrastructure using Azure CLI:

```bash
# Development
az deployment group create \
  --resource-group rg-apim-dev \
  --template-file infrastructure/apim.bicep \
  --parameters @infrastructure/parameters.dev.json

# Production
az deployment group create \
  --resource-group rg-apim-prod \
  --template-file infrastructure/apim.bicep \
  --parameters @infrastructure/parameters.prod.json
```

## 📈 Monitoring and Observability

The APIM service includes:

- Built-in analytics and metrics
- Application Insights integration
- Custom headers for request tracking
- Rate limiting monitoring

## 🤝 Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Ensure all validations pass
4. Create a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Resources

- [Azure API Management Documentation](https://docs.microsoft.com/en-us/azure/api-management/)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [OpenAPI Specification](https://spec.openapis.org/oas/v3.0.0)
- [Spectral API Linting](https://stoplight.io/open-source/spectral)