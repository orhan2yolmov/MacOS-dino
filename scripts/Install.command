#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="$SCRIPT_DIR/MacOS-Dino.app"
APP_DEST="/Applications/MacOS-Dino.app"

echo ""
echo "🦕 MacOS-Dino kuruluyor..."

rm -rf "$APP_DEST"
cp -r "$APP_SRC" "$APP_DEST"

xattr -rd com.apple.quarantine "$APP_DEST" 2>/dev/null
sudo xattr -rd com.apple.quarantine "$APP_DEST" 2>/dev/null

echo "✅ Kurulum tamamlandı! Uygulama açılıyor..."
sleep 1
open "$APP_DEST"
