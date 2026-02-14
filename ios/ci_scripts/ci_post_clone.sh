#!/bin/sh

# ci_post_clone.sh
# Xcode Cloud post-clone script for Flutter + CocoaPods projects.
# This runs automatically after Xcode Cloud clones the repository,
# BEFORE the build starts. It installs Flutter, runs pub get (which
# generates Generated.xcconfig), and runs pod install.

set -e

echo "=== Xcode Cloud CI: Post-Clone Script ==="

# ------------------------------------------------------------------
# 1. Install Flutter SDK (if not already present)
# ------------------------------------------------------------------
if ! command -v flutter &> /dev/null; then
  echo ">>> Installing Flutter SDK..."
  
  # Clone Flutter stable channel
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  
  echo ">>> Flutter installed: $(flutter --version | head -1)"
else
  echo ">>> Flutter already available: $(flutter --version | head -1)"
fi

# Ensure flutter is on PATH for subsequent steps
export PATH="$HOME/flutter/bin:$PATH"

# ------------------------------------------------------------------
# 2. Pre-cache iOS artifacts and run pub get
#    (pub get generates ios/Flutter/Generated.xcconfig which is
#     required by the Podfile and the Xcode project)
# ------------------------------------------------------------------
echo ">>> Running flutter precache --ios..."
flutter precache --ios

echo ">>> Running flutter pub get..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

# ------------------------------------------------------------------
# 3. Install CocoaPods dependencies
#    (Pods/ is gitignored, so we must install them here)
# ------------------------------------------------------------------
echo ">>> Installing CocoaPods..."
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"

# Ensure CocoaPods is available
if ! command -v pod &> /dev/null; then
  echo ">>> Installing CocoaPods via gem..."
  gem install cocoapods
fi

echo ">>> Running pod install..."
pod install

echo "=== CI Post-Clone Complete ==="
