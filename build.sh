#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP=build/ClaudeUsageBar.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [ ! -f build/AppIcon.icns ]; then
  swiftc -O icon/main.swift Starburst.swift -o build/make-icon
  build/make-icon build/AppIcon.iconset
  iconutil -c icns build/AppIcon.iconset -o build/AppIcon.icns
fi
cp build/AppIcon.icns "$APP/Contents/Resources/"
swiftc -O main.swift Starburst.swift -o "$APP/Contents/MacOS/ClaudeUsageBar"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>de.mcojocaru.ClaudeUsageBar</string>
  <key>CFBundleName</key><string>ClaudeUsageBar</string>
  <key>CFBundleExecutable</key><string>ClaudeUsageBar</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
pkill -x ClaudeUsageBar || true
rm -rf ~/Applications/ClaudeUsageBar.app
mkdir -p ~/Applications
cp -R "$APP" ~/Applications/
touch ~/Applications/ClaudeUsageBar.app
open ~/Applications/ClaudeUsageBar.app
echo "installed ~/Applications/ClaudeUsageBar.app"
