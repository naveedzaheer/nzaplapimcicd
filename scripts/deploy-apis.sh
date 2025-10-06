#!/bin/bash

# APIM API Deployment Script
# Usage: ./deploy-apis.sh <environment>

set -e

ENVIRONMENT=${1:-development}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting API deployment to $ENVIRONMENT environment..."

# Load environment-specific configuration
if [ -f "$ROOT_DIR/environments/$ENVIRONMENT.env" ]; then
    source "$ROOT_DIR/environments/$ENVIRONMENT.env"
else
    echo "❌ Environment configuration file not found: $ROOT_DIR/environments/$ENVIRONMENT.env"
    exit 1
fi

# Validate required environment variables
if [ -z "$APIM_SERVICE_NAME" ] || [ -z "$RESOURCE_GROUP" ] || [ -z "$SUBSCRIPTION_ID" ]; then
    echo "❌ Missing required environment variables. Please check your environment configuration."
    exit 1
fi

echo "📋 Configuration:"
echo "  - Environment: $ENVIRONMENT"
echo "  - APIM Service: $APIM_SERVICE_NAME"
echo "  - Resource Group: $RESOURCE_GROUP"
echo "  - Subscription: $SUBSCRIPTION_ID"

# Set Azure subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Deploy Weather API
echo "🌤️  Deploying Weather API..."

# Import the API
az apim api import \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_SERVICE_NAME" \
    --api-id "weather-api" \
    --path "/weather" \
    --display-name "Weather API" \
    --protocols https \
    --service-url "https://api.openweathermap.org/data/2.5" \
    --specification-format OpenApi \
    --specification-path "$ROOT_DIR/api-specs/weather-api.yaml"

# Add API to product
az apim product api add \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_SERVICE_NAME" \
    --product-id "demo-product" \
    --api-id "weather-api"

# Apply rate limiting policy
echo "📝 Applying rate limiting policy..."
az apim api policy create \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_SERVICE_NAME" \
    --api-id "weather-api" \
    --policy-format xml \
    --value @"$ROOT_DIR/policies/rate-limit-policy.xml"

# Apply transformation policy to add API key
echo "🔧 Applying transformation policy..."
az apim api operation policy create \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_SERVICE_NAME" \
    --api-id "weather-api" \
    --operation-id "getCurrentWeather" \
    --policy-format xml \
    --value @"$ROOT_DIR/policies/add-apikey-policy.xml"

az apim api operation policy create \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_SERVICE_NAME" \
    --api-id "weather-api" \
    --operation-id "getWeatherForecast" \
    --policy-format xml \
    --value @"$ROOT_DIR/policies/add-apikey-policy.xml"

echo "✅ API deployment completed successfully!"
echo "🌐 API URL: https://$APIM_SERVICE_NAME.azure-api.net/weather"

# Optional: Run API tests
if [ "$RUN_TESTS" = "true" ]; then
    echo "🧪 Running API tests..."
    # Add your API testing logic here
    # For example, using Newman for Postman collections or custom test scripts
fi

echo "🎉 Deployment completed!"