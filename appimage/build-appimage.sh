#!/bin/bash
set -e

APP_NAME="xonix"
VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/AppDir"

echo "=== Building $APP_NAME AppImage ==="

echo "==> Building application..."
gprbuild -P xonix.gpr -p

echo "==> Creating AppDir structure..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/48x48/apps"
mkdir -p "$APP_DIR/usr/share/metainfo"

echo "==> Copying executable..."
cp bin/xonix "$APP_DIR/usr/bin/"

echo "==> Copying libraries..."
cp /usr/lib/x86_64-linux-gnu/libncursesada.so.6.2.4 "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libncurses.so.6 "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libgnat-13.so "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libc.so.6 "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libform.so.6 "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libmenu.so.6 "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libpanel.so.6 "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libtinfo.so.6 "$APP_DIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libm.so.6 "$APP_DIR/usr/lib/"

echo "==> Creating AppRun..."
cat >"$APP_DIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"

if [ -t 0 ]; then
    exec "${HERE}/usr/bin/xonix" "$@"
else
    for term in xfce4-terminal gnome-terminal konsole xterm kitty alacritty; do
        if command -v "$term" &>/dev/null; then
            case "$term" in
                xfce4-terminal) exec "$term" -x "${HERE}/usr/bin/xonix" "$@" ;;
                gnome-terminal) exec "$term" -- "${HERE}/usr/bin/xonix" "$@" ;;
                konsole)       exec "$term" -e "${HERE}/usr/bin/xonix" "$@" ;;
                xterm)        exec "$term" -e "${HERE}/usr/bin/xonix" "$@" ;;
                kitty)        exec "$term" "${HERE}/usr/bin/xonix" "$@" ;;
                alacritty)    exec "$term" -e "${HERE}/usr/bin/xonix" "$@" ;;
            esac
        fi
    done
    exec "${HERE}/usr/bin/xonix" "$@"
fi
EOF
chmod +x "$APP_DIR/AppRun"

echo "==> Creating desktop file..."
cat >"$APP_DIR/com.github.dolgarev.xonix.desktop" <<'EOF'
[Desktop Entry]
Name=Xonix
Comment=Classic arcade game
Exec=xonix
Icon=xonix
Type=Application
Categories=Game;
Terminal=true
EOF
cp "$APP_DIR/com.github.dolgarev.xonix.desktop" "$APP_DIR/usr/share/applications/"

echo "==> Copying icon..."
cp "$(dirname "$0")/xonix.png" "$APP_DIR/xonix.png"

echo "==> Creating AppStream metainfo..."
cat >"$APP_DIR/com.github.dolgarev.xonix.appdata.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<component type="console-application">
  <id>com.github.dolgarev.xonix</id>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>GPL-3.0-only</project_license>
  <name>Xonix</name>
  <summary>Classic arcade game</summary>
  <description>
    <p>Xonix is a classic arcade game where the goal is to capture a certain percentage of the game field (75% or more) while avoiding enemies.</p>
    <p>Draw traces to capture territory. Return to the safe area to close the trace and fill the enclosed area. Avoid balls and land enemies!</p>
  </description>
  <url type="homepage">https://github.com/dolgarev/xonix</url>
  <launchable type="desktop-id">com.github.dolgarev.xonix.desktop</launchable>
  <provides>
    <binary>xonix</binary>
  </provides>
  <categories>
    <category>Game</category>
  </categories>
  <content_rating type="oars-1.1"/>
</component>
EOF
cp "$APP_DIR/com.github.dolgarev.xonix.appdata.xml" "$APP_DIR/usr/share/metainfo/"

if command -v appimagetool &>/dev/null; then
	APPIMAGETOOL="appimagetool"
elif [ -x /tmp/appimagetool ]; then
	APPIMAGETOOL="/tmp/appimagetool"
else
	echo "==> Error: appimagetool not found"
	echo "==> Install AppImageKit: https://github.com/AppImage/AppImageKit"
	echo "    Or download prebuilt binary from: https://github.com/AppImage/AppImageKit/releases"
	echo "    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/appimagetool && chmod +x /tmp/appimagetool"
	exit 1
fi

echo "==> Creating AppImage..."
mkdir -p "$(dirname "$0")/../bin"
"$APPIMAGETOOL" "$APP_DIR" "$(dirname "$0")/../bin/$APP_NAME-$VERSION-x86_64.AppImage"

echo "=== Done! ==="
