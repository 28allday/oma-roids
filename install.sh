#!/bin/bash
set -euo pipefail

# OMA-RIODS Installer / Uninstaller
# Usage: ./install.sh          — install the game
#        ./install.sh uninstall — remove the game

GAME_NAME="oma-riods"
DISPLAY_NAME="OMA-RIODS"
COMMENT="Classic asteroids arcade game with Omarchy theme integration"
REPO_URL="https://git.no-signal.uk/nosignal/oma-riods.git"

INSTALL_DIR="$HOME/.local/share/$GAME_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/$GAME_NAME.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor"
UNINSTALL_BIN="$HOME/.local/bin/$GAME_NAME-uninstall"

# ── UNINSTALL ──
if [ "${1:-}" = "uninstall" ]; then
    echo "=== Uninstalling $DISPLAY_NAME ==="

    [ -f "$DESKTOP_FILE" ] && rm "$DESKTOP_FILE" && echo "Removed desktop entry"

    for size in 16 32 48 64 128 256 512; do
        local_icon="$ICON_DIR/${size}x${size}/apps/$GAME_NAME.png"
        [ -f "$local_icon" ] && rm "$local_icon"
    done
    [ -f "$ICON_DIR/scalable/apps/$GAME_NAME.svg" ] && rm -f "$ICON_DIR/scalable/apps/$GAME_NAME.svg"
    echo "Removed icons"

    [ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR" && echo "Removed game files"
    [ -f "$UNINSTALL_BIN" ] && rm "$UNINSTALL_BIN" && echo "Removed uninstall command"

    command -v gtk-update-icon-cache &>/dev/null && gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
    command -v omarchy-restart-walker &>/dev/null && omarchy-restart-walker 2>/dev/null || true

    echo "=== $DISPLAY_NAME uninstalled ==="
    exit 0
fi

# ── INSTALL ──
echo "=== Installing $DISPLAY_NAME ==="

# Check for Love2D
if ! command -v love &>/dev/null; then
    echo "Installing Love2D..."
    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm love
    else
        echo "Error: Love2D (love) is not installed and pacman not found."
        echo "Install Love2D manually and re-run this script."
        exit 1
    fi
fi

# Clone or update the game
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull --ff-only
else
    [ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR"
    echo "Cloning game repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Install icon
echo "Installing icon..."
ICON_SVG="$INSTALL_DIR/icon.svg"

if command -v rsvg-convert &>/dev/null; then
    for size in 16 32 48 64 128 256 512; do
        mkdir -p "$ICON_DIR/${size}x${size}/apps"
        rsvg-convert -w "$size" -h "$size" "$ICON_SVG" -o "$ICON_DIR/${size}x${size}/apps/$GAME_NAME.png"
    done
elif command -v magick &>/dev/null; then
    for size in 16 32 48 64 128 256 512; do
        mkdir -p "$ICON_DIR/${size}x${size}/apps"
        magick "$ICON_SVG" -resize "${size}x${size}" "$ICON_DIR/${size}x${size}/apps/$GAME_NAME.png"
    done
else
    echo "No SVG converter found, using SVG icon directly"
    mkdir -p "$ICON_DIR/scalable/apps"
    cp "$ICON_SVG" "$ICON_DIR/scalable/apps/$GAME_NAME.svg"
fi

# Create .desktop file
echo "Creating desktop entry..."
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=$DISPLAY_NAME
Comment=$COMMENT
Exec=uwsm app -- love $INSTALL_DIR
Icon=$GAME_NAME
Terminal=false
Categories=Game;ArcadeGame;
StartupNotify=true
TryExec=love
EOF

# Install uninstall command so user can remove it any time
mkdir -p "$HOME/.local/bin"
cat > "$UNINSTALL_BIN" << 'UNINSTALL'
#!/bin/bash
# Uninstall OMA-RIODS
SCRIPT_URL="https://git.no-signal.uk/nosignal/oma-riods/raw/branch/master/install.sh"
curl -sL "$SCRIPT_URL" | bash -s uninstall 2>/dev/null || bash "$HOME/.local/share/oma-riods/install.sh" uninstall 2>/dev/null || {
    # Fallback: inline uninstall
    rm -f "$HOME/.local/share/applications/oma-riods.desktop"
    rm -rf "$HOME/.local/share/oma-riods"
    for s in 16 32 48 64 128 256 512; do
        rm -f "$HOME/.local/share/icons/hicolor/${s}x${s}/apps/oma-riods.png"
    done
    rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/oma-riods.svg"
    rm -f "$HOME/.local/bin/oma-riods-uninstall"
    command -v omarchy-restart-walker &>/dev/null && omarchy-restart-walker 2>/dev/null
    echo "OMA-RIODS uninstalled"
}
UNINSTALL
chmod +x "$UNINSTALL_BIN"

# Update icon cache
command -v gtk-update-icon-cache &>/dev/null && gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true

# Restart walker
if command -v omarchy-restart-walker &>/dev/null; then
    echo "Refreshing app launcher..."
    omarchy-restart-walker 2>/dev/null || true
fi

echo ""
echo "=== $DISPLAY_NAME installed ==="
echo ""
echo "  Launch: search '$DISPLAY_NAME' in app launcher or run: love $INSTALL_DIR"
echo "  Uninstall: $GAME_NAME-uninstall"
echo ""
