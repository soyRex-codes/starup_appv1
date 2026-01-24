// Android Release Signing Configuration
// Add this code to android/app/build.gradle.kts

// ============================================
// STEP 1: Add this at the TOP of the file (before the plugins block)
// ============================================

import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// ============================================
// STEP 2: Add signingConfigs INSIDE android {} block
// ============================================

android {
    namespace = "com.foundervers.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ADD THIS signingConfigs BLOCK:
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] ?: "")
                storePassword = keystoreProperties["storePassword"] as? String
                keyAlias = keystoreProperties["keyAlias"] as? String
                keyPassword = keystoreProperties["keyPassword"] as? String
            }
        }
    }

    // ... rest of configuration

    buildTypes {
        release {
            // CHANGE THIS LINE FROM:
            // signingConfig = signingConfigs.getByName("debug")
            
            // TO THIS:
            signingConfig = signingConfigs.getByName("release")
            
            // Keep existing release config:
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// ============================================
// STEP 3: Create android/key.properties file
// ============================================

// File: android/key.properties
// (Replace with YOUR actual values after running ./generate_android_keystore.sh)

/*
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyPassword=YOUR_KEY_PASSWORD_HERE
keyAlias=foundervers
storeFile=/Users/YOUR_USERNAME/foundervers-release.keystore
*/

// ============================================
// STEP 4: Add to .gitignore (CRITICAL!)
// ============================================

// Add these lines to your .gitignore:
/*
android/key.properties
*.keystore
key.properties
*/

// ============================================
// STEP 5: Verify Build
// ============================================

// Run these commands to test:
// flutter clean
// flutter pub get
// flutter build appbundle --release

// Expected output:
// Built build/app/outputs/bundle/release/app-release.aab

// ============================================
// TROUBLESHOOTING
// ============================================

// Error: "Keystore file not found"
// -> Check storeFile path in key.properties matches actual keystore location

// Error: "Keystore password was incorrect"
// -> Verify storePassword and keyPassword in key.properties are correct

// Error: "Key with alias 'foundervers' not found"
// -> Ensure keyAlias in key.properties matches the alias used when creating keystore

// ============================================
// PRODUCTION CHECKLIST
// ============================================

// Before uploading to Play Store:
// [ ] Keystore backed up to secure location
// [ ] key.properties added to .gitignore
// [ ] Passwords saved in password manager
// [ ] Build command runs without errors
// [ ] app-release.aab file created successfully
// [ ] App bundle size reasonable (<50MB)

// ============================================
// END OF CONFIGURATION
// ============================================
