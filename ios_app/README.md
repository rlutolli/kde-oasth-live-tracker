# OASTH Live - iOS 🍎

Flutter iOS app with home screen widgets for real-time Thessaloniki bus arrivals.

## ✨ Features

- **Real-time arrivals** from OASTH API
- **Two widget variants**:
  - **OASTH Live** - Full widget with line, destination, time
  - **OASTH Compact** - Minimal widget with urgency colors (red < 5min, green ≥ 5min)
- **Line filtering** - Show only specific bus lines (e.g., 01, 31, 52)
- **LED-style UI** matching the Android widget
- **Automatic stop name lookup** from stops.json

## 🚀 Quick Start

### Option 1: Download Pre-built IPA
1. Go to [Releases](../../releases) or [Actions](../../actions) 
2. Download `OASTH-Live.ipa`
3. Sideload with [AltLinux](https://github.com/NyaMisty/AltLinux) or Sideloadly

### Option 2: Build Locally (requires Flutter)
```bash
# Install Flutter (if not installed)
# https://docs.flutter.dev/get-started/install/linux

cd ios_app
flutter pub get

# Test on Linux (without iOS features)
flutter run -d linux  # or use web: flutter run -d chrome
```

## 📁 Project Structure

```
ios_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/models.dart     # Data classes with lineFilter
│   ├── services/
│   │   ├── session_manager.dart
│   │   ├── oasth_api.dart
│   │   ├── widget_service.dart  # Updated with filtering
│   │   └── stop_repository.dart # Street ID to API ID mapping
│   └── screens/home_screen.dart # UI with filter input
├── ios/
│   └── BusWidget/
│       ├── BusWidget.swift      # Standard widget + WidgetBundle
│       └── MinimalBusWidget.swift # Compact with urgency colors
├── assets/
│   └── stops.json             # Stop data for ID mapping
├── .github/workflows/
│   └── build-ios.yml          # GitHub Actions for IPA
└── pubspec.yaml
```

## 🎨 Widget Features

### Standard Widget (OASTH Live)
- Shows: Line, Destination, Arrival Time
- LED-style amber/orange colors
- Stop code and name in footer
- Sizes: Small, Medium, Large

### Minimal Widget (OASTH Compact)
- Shows: Line number + Time only
- **Urgency colors** (Panos's idea):
  - 🔴 Red: < 5 minutes (hurry!)
  - 🟢 Green: ≥ 5 minutes (safe)
- Size: Small only

### Line Filtering
Enter comma-separated line IDs in the config:
- Example: `01, 31, 52`
- Empty = show all lines

## 🔧 Building the IPA

The GitHub Actions workflow automatically builds an unsigned IPA on push to `main`:

1. Push to GitHub
2. Actions runs on `macos-latest`  
3. Download IPA from workflow artifacts
4. Sideload to iPhone

## ⚠️ Sideloading Limitations

- **7-day expiration**: Free Apple IDs require re-signing weekly
- **3 app limit**: Can only have 3 sideloaded apps at once
- **iOS 16+**: Must enable Developer Mode on device
# Trigger iOS build
