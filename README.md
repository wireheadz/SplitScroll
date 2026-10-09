# SplitScroll

[English](README.md) | [简体中文](README.zh-CN.md)

Natural scrolling for your trackpad, traditional scrolling for your mouse. Choose vertical and horizontal scrolling directions for each device from the macOS menu bar.

Requires **macOS 13 or later**. Settings are saved locally; no analytics, network requests, or input logging.

## Install

To build the app, install Xcode with Swift 5.9 or later, then run:

```sh
git clone https://github.com/wireheadz/SplitScroll.git
cd SplitScroll
bash scripts/build-app.sh
open dist
```

Move **SplitScroll.app** into **Applications** and open it. The current build is not notarized and builds for your Mac's architecture.

## Setup and use

1. Keep **System Settings → Trackpad → Scroll & Zoom → Natural scrolling** enabled.
2. In SplitScroll, click **Allow Accessibility**, then enable it in **System Settings → Privacy & Security → Accessibility**. Add the app with **+** if needed.
3. Select a device under **Devices** and adjust **Reverse vertical scrolling** and **Reverse horizontal scrolling**. Mice start reversed; trackpads stay unchanged.

Click the menu bar icon to change settings. Turn **Enable** off to pause, or choose **Quit** to stop the app. **Launch at login** is optional. If you hide the icon, reopen SplitScroll from Finder or Spotlight to reach settings.

## If something goes wrong

- **Scrolling is unchanged:** check Enable and Accessibility permission, then quit and reopen the app.
- **Your mouse is not identified:** try the **Other mouse wheels** settings. Some receivers share one profile across devices.
- **Settings reset after reconnecting:** devices without a stable identity may need to be configured again.

Avoid running another scroll-reversal utility at the same time. Device compatibility can vary across hardware and macOS versions.

[Report a problem](https://github.com/wireheadz/SplitScroll/issues) with your macOS version, device model, and connection type.

## Uninstall

Disable **Launch at login**, quit SplitScroll, and move the app to the Trash.
