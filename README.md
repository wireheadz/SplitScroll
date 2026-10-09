# SplitScroll

**Natural scrolling for your trackpad. Traditional scrolling for your mouse.**

SplitScroll is a native macOS menu bar app that lets you choose a scrolling direction for each mouse and trackpad. Keep macOS Natural scrolling enabled, then adjust your devices independently.

Built with SwiftUI and macOS system frameworks. No external dependencies, network requests, analytics, or input logging.

## Features

- **Per-device settings** — reverse vertical and horizontal scrolling independently.
- **Saved preferences** — settings return when devices reconnect with the same hardware identity.
- **Trackpad-friendly defaults** — trackpads stay unchanged; mice start with both axes reversed.
- **Quick controls** — enable or pause scrolling changes from the menu bar.
- **Guided setup** — a three-step introduction explains scrolling, devices, and Accessibility permission.
- **Optional launch at login** — start SplitScroll automatically when you sign in.
- **Hideable menu bar icon** — reopen the app from Finder or Spotlight to return to settings.
- **Gesture preservation** — changing direction preserves gesture and momentum phase metadata.

## Requirements

- macOS 13 Ventura or later.
- Accessibility permission to modify scroll events.
- For building from source: Xcode with Swift 5.9 or later.

The build script produces an app for the build machine's architecture. The locally inspected app is Apple Silicon (`arm64`); it is not a universal Intel/Apple Silicon download. Compatibility with every device and macOS version has not been verified.

## Build and install

From the directory containing SplitScroll's `Package.swift`, run:

```sh
bash scripts/build-app.sh
open dist
```

If you cloned the current `codes` repository, run `cd SplitScroll` first.

Move `dist/SplitScroll.app` into **Applications**, then open it. Install it in its final location before granting permissions or enabling launch at login.

The default build uses an **ad-hoc signature** and is **not notarized**. It is intended for local builds and testing. macOS may require approval before opening downloaded builds. See [Apple's Developer ID guidance](https://developer.apple.com/developer-id/) for signing and notarization.

### First launch

1. Leave **System Settings → Trackpad → Scroll & Zoom → Natural scrolling** enabled.
2. Complete SplitScroll's introduction.
3. Click **Allow Accessibility**, then enable SplitScroll in **System Settings → Privacy & Security → Accessibility**. Use the **+** button to add the app if it is missing.
4. Return to SplitScroll. Its status should become **Active — device settings applied**. Quit and reopen it if macOS does not pick up the permission change.
5. Try scrolling with your mouse, then your trackpad.

## Use SplitScroll

Click the mouse icon in the menu bar to open settings. Under **Devices**, select a device and set **Reverse vertical scrolling** and **Reverse horizontal scrolling** independently.

| Input | Default behavior |
| --- | --- |
| Identified mouse | Both axes reversed |
| Identified trackpad | Both axes unchanged |
| Unidentified discrete mouse wheel | Uses **Other mouse wheels** settings |
| Unidentified continuous or phased input | Unchanged |

The **Other mouse wheels** defaults can be customized. Newly discovered mice inherit those defaults; registered device profiles keep their own settings.

Turn **Enable** off to pause changes. Click outside the settings panel or press Escape to close it while scrolling continues. **Quit** or Command-Q stops the app and restores normal macOS event handling.

If you turn **Show in menu bar** off, the icon hides when the panel closes. Open SplitScroll again from Finder or Spotlight to temporarily restore the icon and open settings.

## Privacy and permissions

SplitScroll listens only to scroll-wheel events. It does not capture keystrokes, record input, send data over the network, or change the system Natural scrolling preference. Device profiles and app preferences are stored locally using macOS UserDefaults.

Accessibility permission allows SplitScroll to modify scroll events. The app does not request Input Monitoring permission.

## Compatibility and known limits

Per-device routing uses the undocumented `CGEventCopyIOHIDEvent` and `IOHIDEventGetSenderID` functions, loaded at runtime. If either becomes unavailable, the app reports that device identification is unavailable and falls back to **Other mouse wheels** behavior. This implementation is intended for direct distribution and is not presented as Mac App Store ready.

Device identification also has hardware-specific limits:

- Devices without serial numbers may get a new profile when moved to another USB port or when their Bluetooth identity changes.
- Devices without a serial number or connection location use a session identity, so their profiles may not persist across reconnects.
- A receiver exposing multiple physical mice as one HID device has one shared profile.
- Synthetic or remote scroll events may not have an identifiable hardware sender.
- The first event from a newly resolved sender may use fallback behavior before its profile is applied.

Avoid running multiple scroll-reversal utilities at the same time. For background on device attribution, see the [LinearMouse maintainers' discussion](https://github.com/linearmouse/linearmouse/discussions/200).

## Troubleshooting

| Problem | Try this |
| --- | --- |
| Scrolling does not change | Check **Enable** and Accessibility permission, then quit and reopen the app. |
| Mouse scrolling reverses twice | Pause other scrolling utilities and keep macOS Natural scrolling enabled. |
| A mouse ignores its selected settings | Adjust **Other mouse wheels**; its sender may not be identifiable. |
| The menu bar icon disappeared | Open SplitScroll from Finder or Spotlight. |
| Permissions stop working after an update | Check that Accessibility points to the installed app; remove and re-add it if needed. |
| Launch at login needs approval | Check **System Settings → General → Login Items**. |

## Development

Open `Package.swift` in Xcode, or run tests from the package directory:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

Tests create in-memory scroll events and never post synthetic input to the desktop. Coverage includes independent axes, fractional and pixel deltas, continuous input, gesture/momentum preservation, pause behavior, profile persistence, and corrupted preferences. Hardware identification and permission flows require manual testing.

### Project structure

```text
SplitScroll/
├── Package.swift
├── Info.plist
├── Sources/
│   ├── ScrollCore/       # Event transformation and saved profiles
│   ├── SenderBridge/     # Runtime lookup of device-attribution functions
│   └── SplitScroll/      # Menu bar UI, onboarding, devices, and event tap
├── Tests/ScrollCoreTests/
└── scripts/build-app.sh
```

### Signing a build

The build script accepts a signing identity:

```sh
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  bash scripts/build-app.sh
```

Setting a signing identity does not complete the distribution workflow. Hardened runtime configuration, notarization, and ticket stapling still need to be added before shipping a notarized release.

### Manual release checks

- Grant and revoke Accessibility permission; confirm the app reports its state correctly.
- Test both axes with a mouse and trackpad, including momentum scrolling.
- Alternate devices with opposite settings; confirm profiles remain independent.
- Reconnect devices and test sleep/wake recovery.
- Pause, quit, and relaunch; confirm normal scrolling and saved settings.
- Hide the icon and reopen settings through Finder or Spotlight.
- Enable launch at login, sign out and back in, then verify disabling it.
- Test an upgrade over an existing installation and record the macOS version and device models.

## Bug reports

Include your macOS version, Mac architecture, mouse or trackpad model, connection type (USB, Bluetooth, or receiver), affected axis, and the status shown in SplitScroll. Describe whether the problem occurs after reconnecting or waking from sleep, and whether another scrolling utility is running.

## Uninstall

Disable **Launch at login**, quit SplitScroll, and move the app to the Trash. Remove its entry from **Privacy & Security → Accessibility** if it remains listed.

To also remove saved preferences, run this after quitting:

```sh
defaults delete com.tomo.SplitScroll
```
