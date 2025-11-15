#!/bin/bash
# Android Release Keystore Generator
# Run this script to create a production signing keystore for founderVers

echo "🔐 FounderVers Android Release Keystore Generator"
echo "=================================================="
echo ""

# Default values
KEYSTORE_NAME="foundervers-release.keystore"
KEY_ALIAS="foundervers"
VALIDITY_DAYS=10000 # ~27 years

echo "📋 This script will generate a production keystore for signing Android releases."
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Store the keystore file SECURELY (backup in multiple locations)"
echo "   - NEVER commit the keystore or key.properties to Git"
echo "   - If you lose this keystore, you CANNOT update your app on Play Store"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Ask for keystore location
echo "Where do you want to save the keystore?"
echo "Default: $HOME/$KEYSTORE_NAME"
read -p "Path (press Enter for default): " KEYSTORE_PATH
KEYSTORE_PATH=${KEYSTORE_PATH:-"$HOME/$KEYSTORE_NAME"}

echo ""
echo "Creating keystore at: $KEYSTORE_PATH"
echo ""

# Generate keystore
keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity $VALIDITY_DAYS

# Check if keystore was created successfully
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore created successfully!"
    echo ""
    echo "📝 Next steps:"
    echo ""
    echo "1. Create android/key.properties with the following content:"
    echo ""
    echo "   storePassword=<your-keystore-password>"
    echo "   keyPassword=<your-key-password>"
    echo "   keyAlias=$KEY_ALIAS"
    echo "   storeFile=$KEYSTORE_PATH"
    echo ""
    echo "2. Add key.properties to .gitignore:"
    echo "   echo 'android/key.properties' >> .gitignore"
    echo ""
    echo "3. Update android/app/build.gradle.kts (see PRODUCTION_READINESS_REPORT.md)"
    echo ""
    echo "⚠️  BACKUP INSTRUCTIONS:"
    echo "   - Copy $KEYSTORE_PATH to a secure location"
    echo "   - Store passwords in a password manager"
    echo "   - Consider uploading to secure cloud storage"
    echo ""
    echo "🔒 Never share your keystore or passwords with anyone!"
    echo ""
else
    echo ""
    echo "❌ Failed to create keystore. Please check the error messages above."
    exit 1
fi
