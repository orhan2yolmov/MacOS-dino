#!/bin/bash
# MacOS-Dino – Lokal Mac Build Script
# Kullanım: ./build_local.sh
# Çıktı:    ./MacOS-Dino-1.0.0.dmg

set -e
cd "$(dirname "$0")"

echo "🦕 MacOS-Dino lokal build başlıyor..."
echo ""

# ── 1. Bağımlılıkları çöz
echo "📦 SPM bağımlılıkları çözülüyor..."
swift package resolve

# ── 2. Universal binary derle
echo "🔨 arm64 derleniyor..."
swift build -c release --arch arm64

echo "🔨 x86_64 derleniyor..."
swift build -c release --arch x86_64

echo "🔗 Universal binary birleştiriliyor..."
lipo -create \
  .build/arm64-apple-macosx/release/MacOSDino \
  .build/x86_64-apple-macosx/release/MacOSDino \
  -output MacOSDino_universal
lipo -info MacOSDino_universal

# ── 3. Metal shader'ları derle (opsiyonel – toolchain yoksa atla)
echo "⚡ Metal shader'lar derleniyor..."
METAL_OK=false
if xcrun -sdk macosx metal --version &>/dev/null; then
  mkdir -p /tmp/metal_air_dino
  METAL_FAILED=false
  for METAL in MacOSDino/Core/Shaders/*.metal; do
    BASE=$(basename "$METAL" .metal)
    if xcrun -sdk macosx metal \
      -mmacosx-version-min=14.0 \
      -std=metal3.0 \
      -c "$METAL" \
      -o "/tmp/metal_air_dino/${BASE}.air" 2>/dev/null; then
      echo "  ✅ $BASE.air"
    else
      METAL_FAILED=true
    fi
  done
  if [ "$METAL_FAILED" = false ] && ls /tmp/metal_air_dino/*.air &>/dev/null; then
    AIR_FILES=$(ls /tmp/metal_air_dino/*.air | tr '\n' ' ')
    xcrun -sdk macosx metallib $AIR_FILES -o /tmp/default.metallib
    echo "  ✅ default.metallib → $(du -sh /tmp/default.metallib | cut -f1)"
    METAL_OK=true
  fi
fi
if [ "$METAL_OK" = false ]; then
  echo "  ⚠️  Metal toolchain bulunamadı – shader derleme atlanıyor"
  echo "     (Kurmak için: xcodebuild -downloadComponent MetalToolchain)"
fi

# ── 4. .app bundle oluştur
echo "📁 .app bundle oluşturuluyor..."
APP_DIR="MacOS-Dino.app/Contents"
rm -rf MacOS-Dino.app
mkdir -p "${APP_DIR}/MacOS"
mkdir -p "${APP_DIR}/Resources"

cp MacOSDino_universal "${APP_DIR}/MacOS/MacOSDino"
chmod +x "${APP_DIR}/MacOS/MacOSDino"
cp MacOSDino/App/Info.plist "${APP_DIR}/Info.plist"
printf 'APPL????' > "${APP_DIR}/PkgInfo"
cp /tmp/default.metallib "${APP_DIR}/Resources/default.metallib" 2>/dev/null && echo "  ✅ default.metallib eklendi" || echo "  ⚠️  default.metallib yok (shader'lar çalışmayabilir)"

# Assets (isteğe bağlı)
if [ -d "MacOSDino/Resources/Assets.xcassets" ]; then
  xcrun actool \
    --compile "${APP_DIR}/Resources" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --output-format human-readable-text \
    MacOSDino/Resources/Assets.xcassets 2>&1 || echo "  ⚠️ actool uyarısı (devam ediliyor)"
fi

# SPM resource bundle
SPM_BUNDLE=".build/arm64-apple-macosx/release/MacOSDino_MacOSDino.bundle"
if [ -d "$SPM_BUNDLE" ]; then
  cp -r "$SPM_BUNDLE" "${APP_DIR}/Resources/"
fi

echo "  ✅ Bundle içeriği:"
find MacOS-Dino.app -type f | sort | sed 's/^/    /'

# ── 5. Ad-hoc imzala
echo "🔐 Ad-hoc imzalanıyor..."
codesign --deep --force --sign - \
  --entitlements MacOSDino/App/MacOSDino-Dev.entitlements \
  MacOS-Dino.app
codesign --verify --verbose MacOS-Dino.app
echo "  ✅ İmzalandı"

# ── 6. DMG oluştur
echo "💿 DMG oluşturuluyor..."
VERSION="1.0.0"
DMG_NAME="MacOS-Dino-${VERSION}.dmg"
rm -rf dmg_staging && mkdir -p dmg_staging
cp -r MacOS-Dino.app dmg_staging/
ln -s /Applications dmg_staging/Applications

hdiutil create \
  -volname "MacOS-Dino ${VERSION}" \
  -srcfolder dmg_staging \
  -ov -format UDZO -fs HFS+ \
  "${DMG_NAME}"

rm -rf dmg_staging

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  ✅ Build tamamlandı!                ║"
echo "╠══════════════════════════════════════╣"
printf "║  📦 %-35s║\n" "${DMG_NAME}"
printf "║  📏 %-35s║\n" "$(du -sh ${DMG_NAME} | cut -f1)"
printf "║  📂 %-35s║\n" "$(pwd)/${DMG_NAME}"
echo "╚══════════════════════════════════════╝"
