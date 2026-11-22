#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
bash scripts/build-app.sh release
STAGE_DIR="$PROJECT_ROOT/.build/dmg-stage"
if [[ -d "$STAGE_DIR" ]]; then rm -rf "$STAGE_DIR"; fi
mkdir -p "$STAGE_DIR"
ditto .build/Release.noindex/MyFolds.app "$STAGE_DIR/MyFolds.app"
ln -s /Applications "$STAGE_DIR/Applications"
cp resources/安装说明.txt "$STAGE_DIR/安装说明.txt"
cp 原生测试版说明.md "$STAGE_DIR/原生测试版说明.md"
APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' resources/Info.plist)"
DMG_PATH="$PROJECT_ROOT/outputs/releases/MyFolds-$APP_VERSION-arm64.dmg"
mkdir -p "$PROJECT_ROOT/outputs/releases"
hdiutil create -volname MyFolds -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG_PATH"
hdiutil verify "$DMG_PATH"
(cd "$PROJECT_ROOT/outputs/releases" && shasum -a 256 "$(basename "$DMG_PATH")" > SHA256SUMS.txt)
printf '%s\n' "$DMG_PATH"
