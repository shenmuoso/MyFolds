#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
BUILD_CONFIGURATION="${1:-release}"
if [[ "$BUILD_CONFIGURATION" != release && "$BUILD_CONFIGURATION" != debug ]]; then
  echo 'Usage: build-app.sh [release|debug]' >&2
  exit 2
fi
APP_ROOT="$PROJECT_ROOT/.build/Preview/MyFolds.app"
if [[ "$BUILD_CONFIGURATION" == release ]]; then APP_ROOT="$PROJECT_ROOT/.build/Release.noindex/MyFolds.app"; fi
if ps -axo command= | rg --fixed-strings --line-regexp "$APP_ROOT/Contents/MacOS/MyFolds" > /dev/null; then
  echo 'Quit the running build before replacing its executable.' >&2
  exit 1
fi
swift build --configuration "$BUILD_CONFIGURATION" --product MyFolds
BUILD_BINARY_DIR="$(swift build --configuration "$BUILD_CONFIGURATION" --show-bin-path)"
mkdir -p "$APP_ROOT/Contents/MacOS" "$APP_ROOT/Contents/Resources"
cp "$BUILD_BINARY_DIR/MyFolds" "$APP_ROOT/Contents/MacOS/MyFolds"
cp resources/Info.plist "$APP_ROOT/Contents/Info.plist"
if [[ "$BUILD_CONFIGURATION" == debug ]]; then
  # A locally launched preview must not compete with the installed application's
  # icon or launch entry in Launch Services and the system Apps list.
  /usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.myfolds.app.preview' "$APP_ROOT/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleName MyFolds Preview' "$APP_ROOT/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName MyFolds Preview' "$APP_ROOT/Contents/Info.plist"
fi
ICON_BUILD_DIR="$PROJECT_ROOT/.build/icon-$BUILD_CONFIGURATION"
bash scripts/build-icons.sh "$ICON_BUILD_DIR"
cp "$ICON_BUILD_DIR/Assets.car" "$APP_ROOT/Contents/Resources/Assets.car"
cp "$ICON_BUILD_DIR/MyFoldsFolder.icns" "$APP_ROOT/Contents/Resources/MyFoldsFolder.icns"
# Old builds used this resource name for different artwork. It must not remain
# in an incrementally assembled bundle or be selected as a stale fallback.
rm -f "$APP_ROOT/Contents/Resources/AppIcon.icns" "$APP_ROOT/Contents/Resources/MyFoldsIcon.icns"
/usr/libexec/PlistBuddy -c "Merge .build/icon-$BUILD_CONFIGURATION/Info.plist" "$APP_ROOT/Contents/Info.plist"
cp outputs/myfolds-design/assets/wallpaper.svg "$APP_ROOT/Contents/Resources/wallpaper.svg"
cp resources/ThirdPartyNotices.txt "$APP_ROOT/Contents/Resources/ThirdPartyNotices.txt"
printf 'APPL????' > "$APP_ROOT/Contents/PkgInfo"
codesign --force --sign - --timestamp=none "$APP_ROOT"
codesign --verify --strict --verbose=2 "$APP_ROOT"
printf '%s\n' "$APP_ROOT"
