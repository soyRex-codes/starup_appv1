#!/bin/bash

# Test Hive AI v3 API with your actual API key
# Run this to verify the API is working

API_KEY="Eu9pAIRCidXD3nJD/RfZOw=="

# Create a small test image (1x1 red pixel PNG in base64)
# This is a tiny PNG file to test the API
TEST_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

echo "Testing Hive AI v3 API..."
echo "API Key: ${API_KEY:0:10}... (${#API_KEY} chars)"
echo ""

# Test the API
curl -X POST "https://api.thehive.ai/api/v3/sync/moderation" \
  -H "accept: application/json" \
  -H "authorization: token $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"media\": [
      {
        \"data\": \"$TEST_IMAGE\",
        \"media_type\": \"image/png\"
      }
    ]
  }" \
  -v

echo ""
echo "If you see a 200 response with JSON containing 'media' and 'classes', the API is working!"
echo "If you see 401, your API key is invalid."
echo "If you see 403, you may be out of credits."
