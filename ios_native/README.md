# OASTH Live - Native iOS (xtool) 🍏

Native Swift iOS app built with [xtool](https://github.com/xtool-org/xtool) - **no Mac required!**

## ✨ Features

- **LED-style UI** matching Android widget
- **Session management** automatic OASTH authentication  
- **Line filtering** show only specific buses
- **Urgency colors** 🔴 red < 5min, 🟢 green >= 5min
- **Cross-platform build** works on Linux, Windows, macOS

## 🚀 Quick Start

### Install xtool
```bash
# Download AppImage (Linux x86_64)
curl -L https://github.com/xtool-org/xtool/releases/latest/download/xtool-x86_64.AppImage -o ~/bin/xtool
chmod +x ~/bin/xtool
```

### Build & Run
```bash
cd ios_native/OASTHLive

# First time: setup SDK and auth
xtool setup

# Build and deploy to connected iPhone
xtool dev
```

### Install to Device
```bash
# List connected devices
xtool devices

# Install IPA
xtool install OASTHLive.ipa
```

## 📁 Project Structure

```
OASTHLive/
├── Package.swift         # Swift Package Manager config
├── xtool.yml            # xtool configuration
└── Sources/OASTHLive/
    ├── OASTHLiveApp.swift   # App entry point
    ├── ContentView.swift    # LED-style UI
    ├── Models.swift         # BusArrival, SessionData, WidgetConfig
    └── OasthAPI.swift       # OASTH API client
```

## 🎨 Why Native Swift?

| Flutter iOS | Native Swift (xtool) |
|-------------|---------------------|
| Widget extensions need Xcode | Full control from Linux |
| Complex project structure | Simple SwiftPM |
| Dart + Swift + Xcode | Pure Swift |

## ⚠️ Requirements

- **Apple ID** for signing (free works, 7-day re-sign)
- **iPhone connected via USB** for `xtool dev`
- **Linux/Windows/macOS** with xtool installed

## 🔧 Adding Home Screen Widget

Widgets require WidgetKit which xtool is still developing support for.
For now, this app displays arrivals in the app itself.
