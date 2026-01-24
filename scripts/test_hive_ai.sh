#!/bin/bash

# Hive AI Content Moderation - Quick Setup & Test
# This script helps you get your Hive AI API key and test the integration

echo "Hive AI Content Moderation Setup"
echo "===================================="
echo ""

# Check if API key is set
if grep -q "YOUR_HIVE_AI_API_KEY_HERE" .env.mobile; then
    echo "Hive AI API key not set yet!"
    echo ""
    echo "📋 STEPS TO GET YOUR API KEY:"
    echo ""
    echo "1. Go to: https://thehive.ai/"
    echo "2. Click 'Sign Up' and create an account"
    echo "3. Verify your email"
    echo "4. Go to Dashboard → API Keys"
    echo "5. Create a new API key"
    echo "6. Copy the FULL key (starts with 'Token ')"
    echo ""
    echo "7. Open .env.mobile and replace:"
    echo "   HIVE_AI_API_KEY=YOUR_HIVE_AI_API_KEY_HERE"
    echo "   with:"
    echo "   HIVE_AI_API_KEY=Token your_actual_key_here"
    echo ""
    echo "8. Run this script again!"
    echo ""
    exit 1
fi

# Check if it's still the placeholder
HIVE_KEY=$(grep "HIVE_AI_API_KEY=" .env.mobile | cut -d'=' -f2)

if [ "$HIVE_KEY" == "YOUR_HIVE_AI_API_KEY_HERE" ]; then
    echo "Please replace YOUR_HIVE_AI_API_KEY_HERE with your actual key"
    exit 1
fi

echo "Hive AI API key found!"
echo ""
echo "Testing Hive AI connection..."
echo ""

# Test the API key with a simple request
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "https://api.thehive.ai/api/v2/task/sync" \
  -H "Authorization: $HIVE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://via.placeholder.com/150"}')

if [ "$RESPONSE" == "200" ]; then
    echo "SUCCESS! Hive AI API key is valid!"
    echo ""
    echo "Your Setup:"
    echo "  - Text moderation: OpenAI (FREE)"
    echo "  - Image moderation: Hive AI ($1 per 1,000 images)"
    echo "  - Free tier: 1,000 images/month"
    echo ""
    echo "Next Steps:"
    echo "  1. Run: flutter run"
    echo "  2. Try creating a post with images"
    echo "  3. Check console for moderation logs"
    echo ""
    echo "Look for these logs:"
    echo "  Checking X image(s) with Hive AI..."
    echo "  Hive AI approved image"
    echo "  Hive AI BLOCKED image (if inappropriate)"
    echo ""
elif [ "$RESPONSE" == "401" ]; then
    echo "INVALID API KEY!"
    echo ""
    echo "The API key in .env.mobile is not valid."
    echo "Please check that you copied the full key including 'Token ' prefix"
    echo ""
elif [ "$RESPONSE" == "000" ]; then
    echo "NETWORK ERROR!"
    echo ""
    echo "Could not connect to Hive AI. Check your internet connection."
    echo ""
else
    echo "Unexpected response code: $RESPONSE"
    echo ""
    echo "Please check your API key or try again later."
    echo ""
fi
