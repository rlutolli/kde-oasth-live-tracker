#!/usr/bin/env ruby
# Script to automate iOS widget extension setup using xcodeproj gem
# Run on macOS (e.g., GitHub Actions macOS runner)
# 
# This script takes a simpler approach - just creating the necessary files
# without modifying the complex Xcode project structure, which Flutter manages.

require 'fileutils'

WIDGET_NAME = 'BusWidget'
APP_GROUP_ID = 'group.com.oasth.widget'
BUNDLE_ID_PREFIX = 'com.oasth.live'

puts "🔧 Setting up iOS Widget Extension files..."

# Ensure directories exist
FileUtils.mkdir_p("ios/#{WIDGET_NAME}")
FileUtils.mkdir_p("ios/Runner")

# Create Info.plist for widget
info_plist_path = "ios/#{WIDGET_NAME}/Info.plist"
puts "Creating #{info_plist_path}..."

info_plist = <<~PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>OASTH Live Widget</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>#{BUNDLE_ID_PREFIX}.#{WIDGET_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
PLIST

File.write(info_plist_path, info_plist)
puts "✓ Created #{info_plist_path}"

# Create Runner entitlements (App Group for main app)
runner_entitlements_path = "ios/Runner/Runner.entitlements"
puts "Creating #{runner_entitlements_path}..."

runner_entitlements = <<~ENTITLEMENTS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>#{APP_GROUP_ID}</string>
    </array>
</dict>
</plist>
ENTITLEMENTS

File.write(runner_entitlements_path, runner_entitlements)
puts "✓ Created #{runner_entitlements_path}"

# Create Widget entitlements
widget_entitlements_path = "ios/#{WIDGET_NAME}/#{WIDGET_NAME}.entitlements"
puts "Creating #{widget_entitlements_path}..."

File.write(widget_entitlements_path, runner_entitlements)
puts "✓ Created #{widget_entitlements_path}"

# Check Swift files exist
swift_files = ["ios/#{WIDGET_NAME}/BusWidget.swift", "ios/#{WIDGET_NAME}/MinimalBusWidget.swift"]
swift_files.each do |f|
  if File.exist?(f)
    puts "✓ Found #{f}"
  else
    puts "⚠ Missing #{f}"
  end
end

puts ""
puts "🎉 Widget extension files setup complete!"
puts ""
puts "Summary:"
puts "  - Widget folder: ios/#{WIDGET_NAME}/"
puts "  - Bundle ID: #{BUNDLE_ID_PREFIX}.#{WIDGET_NAME}"
puts "  - App Group: #{APP_GROUP_ID}"
puts ""
puts "Note: Due to Flutter/Xcode complexity, the widget extension target"
puts "must be manually added in Xcode or via a more complex setup."
puts ""
puts "For now, building the main Flutter app WITHOUT widget extension."
