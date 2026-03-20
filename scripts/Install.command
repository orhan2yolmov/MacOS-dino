#!/bin/bash
# Install.command – MacOS-Dino Installer
# Copies the app to /Applications and removes Gatekeeper quarantine
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="MacOS-Dino.app"
SOURCE="$DIR/$APP_NAME"
DEST="/Applications/$APP_NAME"

# ── Colors ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      MacOS-Dino  ·  Installer v4.2      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Check source exists
if [ ! -d "$SOURCE" ]; then
    echo -e "${RED}❌  Cannot find $APP_NAME next to this script.${NC}"
    echo "    Make sure both files are in the same folder."
    read -p "Press Enter to exit..." dummy
    exit 1
fi

# Copy to /Applications (overwrite)
echo -e "📦  Installing to /Applications..."
cp -R "$SOURCE" "$DEST"

# Remove all quarantine / Gatekeeper flags
echo -e "🔓  Removing Gatekeeper quarantine..."
xattr -cr "$DEST"

# Re-sign with ad-hoc identity (makes Gatekeeper happy on first launch)
echo -e "✍️   Re-signing app..."
codesign --force --deep --sign - "$DEST" 2>/dev/null || true

echo ""
echo -e "${GREEN}✅  Installation complete!${NC}"
echo -e "    You can now launch MacOS-Dino from your Applications folder."
echo ""

# Offer to open
read -p "Open MacOS-Dino now? [Y/n]: " choice
if [[ "$choice" != "n" && "$choice" != "N" ]]; then
    open "$DEST"
fi
