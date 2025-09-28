#!/bin/bash

# Test script for the GitHub Action PR Trigger API
# Usage: ./scripts/test-api.sh [base_url] [api_token]

BASE_URL=${1:-"http://localhost:3000"}
API_TOKEN=${2:-$API_TOKEN}

if [ -z "$API_TOKEN" ]; then
  echo "❌ API_TOKEN is required. Set it as environment variable or pass as second argument."
  echo "Usage: $0 [base_url] [api_token]"
  exit 1
fi

echo "🧪 Testing GitHub Action PR Trigger API"
echo "📍 Base URL: $BASE_URL"
echo "🔑 Using API Token: ${API_TOKEN:0:8}..."
echo

# Test 1: Health Check
echo "1️⃣ Testing health endpoint..."
health_response=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/health")
health_status=$(echo "$health_response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
health_body=$(echo "$health_response" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$health_status" = "200" ]; then
  echo "✅ Health check passed"
  echo "   Response: $health_body"
else
  echo "❌ Health check failed (Status: $health_status)"
  echo "   Response: $health_body"
fi
echo

# Test 2: Status Check
echo "2️⃣ Testing status endpoint..."
status_response=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/api/status")
status_status=$(echo "$status_response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
status_body=$(echo "$status_response" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$status_status" = "200" ]; then
  echo "✅ Status check passed"
  echo "   Response: $status_body"
else
  echo "❌ Status check failed (Status: $status_status)"
  echo "   Response: $status_body"
fi
echo

# Test 3: Authentication Test (without token)
echo "3️⃣ Testing authentication (should fail without token)..."
auth_response=$(curl -s -w "HTTP_STATUS:%{http_code}" -X POST "$BASE_URL/api/trigger-pr-workflow")
auth_status=$(echo "$auth_response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
auth_body=$(echo "$auth_response" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$auth_status" = "401" ]; then
  echo "✅ Authentication test passed (correctly rejected without token)"
  echo "   Response: $auth_body"
else
  echo "❌ Authentication test failed (Expected 401, got $auth_status)"
  echo "   Response: $auth_body"
fi
echo

# Test 4: Payload Validation Test
echo "4️⃣ Testing payload validation (should fail with invalid payload)..."
validation_response=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/api/trigger-pr-workflow" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"invalid": "payload"}')
validation_status=$(echo "$validation_response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
validation_body=$(echo "$validation_response" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$validation_status" = "400" ]; then
  echo "✅ Payload validation test passed (correctly rejected invalid payload)"
  echo "   Response: $validation_body"
else
  echo "❌ Payload validation test failed (Expected 400, got $validation_status)"
  echo "   Response: $validation_body"
fi
echo

# Test 5: Valid Payload Test (will trigger actual workflow if configured)
echo "5️⃣ Testing with valid payload..."
echo "⚠️  Warning: This will trigger an actual GitHub workflow if properly configured!"
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if [ -f "examples/sample-payload.json" ]; then
    valid_response=$(curl -s -w "HTTP_STATUS:%{http_code}" \
      -X POST "$BASE_URL/api/trigger-pr-workflow" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      -d @examples/sample-payload.json)
    valid_status=$(echo "$valid_response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    valid_body=$(echo "$valid_response" | sed 's/HTTP_STATUS:[0-9]*$//')

    if [ "$valid_status" = "202" ]; then
      echo "✅ Valid payload test passed (workflow triggered)"
      echo "   Response: $valid_body"
    else
      echo "❌ Valid payload test failed (Status: $valid_status)"
      echo "   Response: $valid_body"
    fi
  else
    echo "❌ Sample payload file not found: examples/sample-payload.json"
  fi
else
  echo "⏭️  Skipped valid payload test"
fi
echo

echo "🎉 Testing completed!"
echo
echo "📝 Notes:"
echo "   • Make sure your .env file is properly configured"
echo "   • Check GitHub repository settings for required secrets"
echo "   • Monitor GitHub Actions tab for workflow execution"