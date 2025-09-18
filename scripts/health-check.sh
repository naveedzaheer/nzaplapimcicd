#!/bin/bash

# APIM Health Check Script
# Usage: ./health-check.sh <environment>

set -e

ENVIRONMENT=${1:-development}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🏥 Starting health check for $ENVIRONMENT environment..."

# Load environment-specific configuration
if [ -f "$ROOT_DIR/environments/$ENVIRONMENT.env" ]; then
    source "$ROOT_DIR/environments/$ENVIRONMENT.env"
else
    echo "❌ Environment configuration file not found: $ROOT_DIR/environments/$ENVIRONMENT.env"
    exit 1
fi

APIM_URL="https://$APIM_SERVICE_NAME.azure-api.net"

echo "📋 Configuration:"
echo "  - Environment: $ENVIRONMENT"
echo "  - APIM URL: $APIM_URL"

# Check APIM service availability
echo "🔍 Checking APIM service availability..."
if curl -f -s "$APIM_URL" > /dev/null; then
    echo "✅ APIM service is accessible"
else
    echo "❌ APIM service is not accessible"
    exit 1
fi

# Check Weather API endpoints
echo "🌤️  Checking Weather API endpoints..."

# Test current weather endpoint
WEATHER_ENDPOINT="$APIM_URL/weather/weather?q=London,UK"
echo "Testing: $WEATHER_ENDPOINT"

RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/weather_response.json "$WEATHER_ENDPOINT")
HTTP_CODE="${RESPONSE: -3}"

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Weather API current weather endpoint is working"
elif [ "$HTTP_CODE" -eq 401 ]; then
    echo "⚠️  Weather API returned 401 - API key might be missing or invalid"
else
    echo "❌ Weather API current weather endpoint failed with HTTP $HTTP_CODE"
fi

# Test forecast endpoint
FORECAST_ENDPOINT="$APIM_URL/weather/forecast?q=London,UK"
echo "Testing: $FORECAST_ENDPOINT"

RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/forecast_response.json "$FORECAST_ENDPOINT")
HTTP_CODE="${RESPONSE: -3}"

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Weather API forecast endpoint is working"
elif [ "$HTTP_CODE" -eq 401 ]; then
    echo "⚠️  Weather API returned 401 - API key might be missing or invalid"
else
    echo "❌ Weather API forecast endpoint failed with HTTP $HTTP_CODE"
fi

# Check rate limiting headers
echo "🚦 Checking rate limiting..."
HEADERS=$(curl -s -I "$WEATHER_ENDPOINT" | grep -i "x-ratelimit\|x-quota" || true)
if [ -n "$HEADERS" ]; then
    echo "✅ Rate limiting headers found:"
    echo "$HEADERS"
else
    echo "⚠️  No rate limiting headers found"
fi

echo "🎉 Health check completed!"

# Clean up temporary files
rm -f /tmp/weather_response.json /tmp/forecast_response.json