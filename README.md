# Shecan for macOS

Shecan is a macOS SwiftUI app for managing Shecan DNS with a native desktop experience.

It provides:

- One-click DNS toggle for the active Wi-Fi or Ethernet service
- Restore to automatic DNS
- Menu bar extra for quick access
- Shecan DDNS Link Updater support
- Secure local storage for updater settings
- A packaged DMG installer for distribution

## Features

- Native macOS app built with SwiftUI
- Compact main window with a quick connect/disconnect control
- Menu bar access for fast DNS actions
- Configurable Shecan DNS servers
- Configurable DDNS updater URL
- Automatic updater timer for periodic refresh
- Privileged DNS changes through a helper flow

## Default DNS

By default, the app uses:

- `178.22.122.101`
- `185.51.200.1`

These can be changed from the in-app settings.

## Installation

### Install from DMG

1. Download `Shecan.dmg` from the latest GitHub Release.
2. Open the DMG.
3. Drag `Shecan.app` into `Applications`.
4. Launch the app from `Applications`.

### First launch notes

- macOS may ask for confirmation when opening the app.
- DNS changes require elevated privileges.
- On first privileged setup, macOS may ask for administrator approval.

## Using the App

### Toggle DNS

- Open the app.
- Click the main circle button to enable or disable Shecan DNS.

### Configure DDNS updater

1. Click the settings button in the top-right corner.
2. Paste your Shecan DDNS updater URL.
3. Save settings.

Example placeholder:

```text
https://ddns.shecan.ir/update?password=xxx
```

### Manual update

- Use the `Update Now` action inside the Link Updater card.

## Project Structure

```text
Sources/
  App/
  Features/
  Helper/
  Resources/
  Services/
  Shared/
Scripts/
Packaging/
```

## Build

Open the project in Xcode:

```text
Shecan.xcodeproj
```

Or build from terminal:

```bash
xcodebuild -project Shecan.xcodeproj -scheme Shecan -configuration Debug build
```

Release build:

```bash
xcodebuild -project Shecan.xcodeproj -scheme Shecan -configuration Release build
```

## Packaging

The repository includes packaging assets for DMG generation.

- DMG background asset: `Packaging/dmg-background.png`
- Release app output: `build/Release/Shecan.app`

## Important Notes

- The app is intended for macOS 13+.
- DNS changes rely on `networksetup`.
- Privileged helper behavior may require proper signing for production distribution.
- If a VPN is active, effective DNS behavior may differ from the Wi-Fi DNS shown by `networksetup`.

## License

Add your preferred license here.
