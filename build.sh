#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

APP_NAME="Fret Template Builder"
BUNDLE_ID="com.gary.fret-template-builder"
EXECUTABLE_NAME="fret-template-builder"

echo "=== Building Fret Template Builder ==="

# Step 1: Build the release binary
echo "Building Swift binary..."
BIN_PATH=$(swift build -c release --show-bin-path)
BINARY="$BIN_PATH/$EXECUTABLE_NAME"

if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY"
    exit 1
fi

echo "✓ Binary built: $BINARY"

# Step 2: Generate icon if needed
if [ ! -f "Resources/AppIcon.icns" ]; then
    echo "Generating app icon..."
    swift Scripts/generate_icon.swift
    iconutil -c icns AppIcon.iconset -o Resources/AppIcon.icns
    echo "✓ Icon generated"
else
    echo "✓ Icon already exists"
fi

# Step 3: Create app bundle structure
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Creating app bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Step 4: Copy binary and icon
cp "$BINARY" "$MACOS_DIR/$EXECUTABLE_NAME"
cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

echo "✓ Binary and icon copied"

# Step 5: Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Step 6: Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "✓ App bundle assembled"

# Step 7: Ad-hoc codesign
echo "Code signing..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true
echo "✓ Signed"

# Step 8: Install to ~/Applications
INSTALL_DIR="$HOME/Applications"
INSTALL_PATH="$INSTALL_DIR/$APP_NAME.app"

echo "Installing to $INSTALL_PATH..."
rm -rf "$INSTALL_PATH"
cp -R "$APP_BUNDLE" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH/Contents/MacOS/$EXECUTABLE_NAME"

echo "✓ Installed"

# Step 9: Force Spotlight indexing
echo "Registering with Spotlight..."
mdimport "$INSTALL_PATH" 2>/dev/null || true

echo ""
echo "=== Build complete! ==="
echo "App installed at: $INSTALL_PATH"
echo ""
echo "Launch with: open \"$INSTALL_PATH\""
echo "Or search Spotlight: Cmd+Space → Fret Template Builder"
