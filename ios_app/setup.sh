#!/bin/bash
# Setup script for OASTH Live iOS app
# Run this after installing Flutter

set -e

echo "🍎 Setting up OASTH Live iOS app..."

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

cd "$(dirname "$0")"

echo "📦 Getting dependencies..."
flutter pub get

echo "🔧 Creating iOS project structure..."
flutter create --platforms=ios,android .

echo "📱 Copying widget extension..."
# The widget extension files are already in ios/BusWidget
# They need to be integrated via Xcode

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Push to GitHub to trigger the build workflow"
echo "2. Download the IPA from GitHub Actions artifacts"
echo "3. Sideload with AltLinux or Sideloadly"
echo ""
echo "For testing on Linux:"
echo "   flutter run -d linux"
echo "   flutter run -d chrome"
