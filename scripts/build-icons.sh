#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
ICON_BUILD_DIR="${1:?Usage: build-icons.sh output-directory}"
ICON_COMPOSER_TOOL="$(xcode-select --print-path)/../Applications/Icon Composer.app/Contents/Executables/ictool"
if [[ ! -x "$ICON_COMPOSER_TOOL" ]]; then
  echo 'Icon Composer from Xcode 27 is required to build the app artwork.' >&2
  exit 1
fi
BRAND_CATALOG="$ICON_BUILD_DIR/BrandAssets.xcassets"
BRAND_ICON_SET="$BRAND_CATALOG/AppBrandIcon.imageset"
mkdir -p "$BRAND_ICON_SET"

# In-app artwork and the running Dock icon follow the app's appearance.
# The supplied screenshot artwork has baked-in shading; its layer has effects
# disabled. Icon Composer supplies the system container and appearance variants.
for rendition in Default Dark; do
  for size in 128 256; do
    "$ICON_COMPOSER_TOOL" resources/MyFoldsFolder.icon --export-image \
      --output-file "$BRAND_ICON_SET/$rendition-$size.png" \
      --platform macOS --rendition "$rendition" \
      --width "$size" --height "$size" --scale 1 --design-generation 27 > /dev/null
  done
done
cat > "$BRAND_CATALOG/Contents.json" <<'JSON'
{"info":{"author":"xcode","version":1}}
JSON
cat > "$BRAND_ICON_SET/Contents.json" <<'JSON'
{
  "images": [
    {"idiom":"universal","filename":"Default-128.png","scale":"1x"},
    {"idiom":"universal","filename":"Default-256.png","scale":"2x"},
    {"idiom":"universal","filename":"Dark-128.png","scale":"1x","appearances":[{"appearance":"luminosity","value":"dark"}]},
    {"idiom":"universal","filename":"Dark-256.png","scale":"2x","appearances":[{"appearance":"luminosity","value":"dark"}]}
  ],
  "info":{"author":"xcode","version":1}
}
JSON
xcrun actool resources/MyFoldsFolder.icon "$BRAND_CATALOG" \
  --compile "$ICON_BUILD_DIR" \
  --platform macosx --minimum-deployment-target 27.0 \
  --app-icon MyFoldsFolder \
  --output-partial-info-plist "$ICON_BUILD_DIR/Info.plist" \
  --output-format human-readable-text --warnings --notices
