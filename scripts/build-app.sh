#!/usr/bin/env bash

set -euo pipefail

configuration="${1:-release}"
case "$configuration" in
  debug|release) ;;
  *)
    echo "Usage: $0 [debug|release]" >&2
    exit 64
    ;;
esac

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
product_name="SimpleWindowSwitcher"
executable_name="SimpleWindowSwitcher"
app_dir="$project_root/.build/app/$product_name.app"
contents_dir="$app_dir/Contents"
icon_source="$project_root/Assets/AppIcon.png"
iconset_dir="$project_root/.build/app/AppIcon.iconset"

cd "$project_root"
swift build --configuration "$configuration" --product "$executable_name"
bin_dir="$(swift build --configuration "$configuration" --show-bin-path)"

rm -rf "$app_dir" "$iconset_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"

cp "$bin_dir/$executable_name" "$contents_dir/MacOS/$executable_name"

if [ -f "$icon_source" ]; then
  mkdir -p "$iconset_dir"
  create_icon() {
    local size="$1"
    local filename="$2"
    sips -s format png -z "$size" "$size" "$icon_source" --out "$iconset_dir/$filename" >/dev/null
  }

  create_icon 16 icon_16x16.png
  create_icon 32 icon_16x16@2x.png
  create_icon 32 icon_32x32.png
  create_icon 64 icon_32x32@2x.png
  create_icon 128 icon_128x128.png
  create_icon 256 icon_128x128@2x.png
  create_icon 256 icon_256x256.png
  create_icon 512 icon_256x256@2x.png
  create_icon 512 icon_512x512.png
  create_icon 1024 icon_512x512@2x.png
  iconutil --convert icns "$iconset_dir" --output "$contents_dir/Resources/AppIcon.icns"
  rm -rf "$iconset_dir"
fi

cat > "$contents_dir/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>SimpleWindowSwitcher</string>
  <key>CFBundleIdentifier</key>
  <string>dev.sumetph.SimpleWindowSwitcher</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>SimpleWindowSwitcher</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAccessibilityUsageDescription</key>
  <string>SimpleWindowSwitcher needs accessibility permission to manage and switch windows.</string>
</dict>
</plist>
PLIST

plutil -lint "$contents_dir/Info.plist" >/dev/null

# Sign with Apple Development cert by default, or ad-hoc if not available.
# We'll use "-" for ad-hoc if no identity is specified.
codesign --force --sign "${CODE_SIGN_IDENTITY:-"-"}" "$app_dir"

echo "Built: $app_dir"
