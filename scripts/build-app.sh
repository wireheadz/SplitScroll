#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/splitscroll-clang-cache"
swift build -c release --scratch-path .build
BIN_DIR="$(swift build -c release --scratch-path .build --show-bin-path)"
APP="$PWD/dist/SplitScroll.app"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/splitscroll-package.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
STAGED_APP="$STAGING/SplitScroll.app"
mkdir -p "$STAGED_APP/Contents/MacOS"
cp "$BIN_DIR/SplitScroll" "$STAGED_APP/Contents/MacOS/SplitScroll"
cp Info.plist "$STAGED_APP/Contents/Info.plist"
xattr -cr "$STAGED_APP"
codesign --force --sign "${SIGNING_IDENTITY:--}" "$STAGED_APP"
codesign --verify --strict "$STAGED_APP"
mkdir -p dist
ditto "$STAGED_APP" "$APP"
xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
printf 'Built: %s\n' "$APP"
