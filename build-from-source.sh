#!/bin/sh
# Build the from-source components of this rice: SwayFX (with a statically
# linked wlroots), swaylock-effects, and mpvpaper. Installs into ~/.local.
#
#   ./build-from-source.sh              build whatever is missing
#   ./build-from-source.sh --force      rebuild everything
#   PREFIX=/some/where ./build-from-source.sh   custom install prefix
#
# Debian 12 ships wlroots 0.15, too old for SwayFX 0.3.x - so wlroots 0.16.2
# is built as a static library first and SwayFX links against it.
set -e

PREFIX="${PREFIX:-$HOME/.local}"
SRC="$HOME/.local/src"
JOBS=$(nproc 2>/dev/null || echo 4)
FORCE=""; [ "$1" = "--force" ] && FORCE=1

SUDO=""; [ "$(id -u)" != 0 ] && SUDO=sudo

# Build dependencies per package manager (runtime deps: install.sh).
APT_DEPS="gcc libevdev-dev meson ninja-build cmake pkg-config git wayland-protocols
libwayland-dev libegl1-mesa-dev libgles2-mesa-dev libdrm-dev libgbm-dev
libinput-dev libxkbcommon-dev libudev-dev libpixman-1-dev libseat-dev
libvulkan-dev glslang-tools hwdata xwayland
libxcb1-dev libxcb-composite0-dev libxcb-dri3-dev libxcb-icccm4-dev
libxcb-present-dev libxcb-render0-dev libxcb-res0-dev libxcb-xfixes0-dev
libxcb-xinput-dev libxcb-shm0-dev libxcb-ewmh-dev
libjson-c-dev libpcre2-dev libpango1.0-dev libcairo2-dev
libgdk-pixbuf-2.0-dev scdoc libpam0g-dev libmpv-dev"

PACMAN_DEPS="gcc libevdev meson ninja cmake pkgconf git wayland wayland-protocols mesa
libdrm libinput libxkbcommon pixman seatd vulkan-headers vulkan-icd-loader
glslang hwdata xorg-xwayland libxcb xcb-util-wm xcb-util-image
xcb-util-renderutil xcb-util-errors json-c pcre2 pango cairo gdk-pixbuf2
scdoc pam mpv"

DNF_DEPS="gcc libevdev-devel meson ninja-build cmake pkgconf-pkg-config git wayland-devel
wayland-protocols-devel mesa-libEGL-devel mesa-libgbm-devel libdrm-devel
libinput-devel libxkbcommon-devel systemd-devel pixman-devel libseat-devel
vulkan-loader-devel glslang hwdata libxcb-devel xcb-util-wm-devel
xcb-util-image-devel xcb-util-renderutil-devel json-c-devel pcre2-devel
pango-devel cairo-devel gdk-pixbuf2-devel scdoc pam-devel mpv-libs-devel
xorg-x11-server-Xwayland-devel"

echo "==> Installing build dependencies"
# shellcheck disable=SC2086
if command -v apt-get >/dev/null; then
    $SUDO apt-get install -y $APT_DEPS
elif command -v pacman >/dev/null; then
    $SUDO pacman -S --needed --noconfirm $PACMAN_DEPS
elif command -v dnf >/dev/null; then
    $SUDO dnf install -y $DNF_DEPS
else
    echo "!! unknown package manager - make sure meson/ninja and the wayland,"
    echo "   wlroots, pam and mpv dev headers are installed, then re-run."
fi

mkdir -p "$SRC"
# cover every libdir convention: Debian multiarch, Fedora lib64, plain lib
export PKG_CONFIG_PATH="$PREFIX/lib/$(gcc -dumpmachine)/pkgconfig:$PREFIX/lib64/pkgconfig:$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

# --------------------------------------------------------------- wlroots 0.16.2 (static)
if [ -n "$FORCE" ] || ! pkg-config --atleast-version=0.16 wlroots 2>/dev/null; then
    echo "==> Building wlroots 0.16.2 (static library)"
    rm -rf "$SRC/wlroots"
    git clone --depth 1 -b 0.16.2 https://gitlab.freedesktop.org/wlroots/wlroots.git "$SRC/wlroots"
    meson setup "$SRC/wlroots/build" "$SRC/wlroots" --prefix="$PREFIX" \
        --libdir=lib --buildtype=release -Ddefault_library=static -Dwerror=false \
        -Dexamples=false -Dxwayland=enabled
    ninja -C "$SRC/wlroots/build" -j"$JOBS" install
fi

# --------------------------------------------------------------- SwayFX 0.3.2
# SwayFX reports its own project version (0.3.x); vanilla sway reports 1.x
if [ -n "$FORCE" ] || ! "$PREFIX/bin/sway" --version 2>/dev/null | grep -q '^sway version 0\.3'; then
    echo "==> Building SwayFX 0.3.2"
    rm -rf "$SRC/swayfx"
    git clone --depth 1 -b 0.3.2 https://github.com/WillPower3309/swayfx.git "$SRC/swayfx"
    # With wlroots linked statically, swayfx's own matrix_projection collides
    # with wlroots' internal symbol of the same name - rename swayfx's copy.
    grep -rl 'matrix_projection' "$SRC/swayfx/sway" "$SRC/swayfx/include" 2>/dev/null \
        | xargs -r sed -i 's/\bmatrix_projection\b/fx_matrix_projection/g'
    meson setup "$SRC/swayfx/build" "$SRC/swayfx" --prefix="$PREFIX" \
        --buildtype=release -Dwerror=false
    ninja -C "$SRC/swayfx/build" -j"$JOBS" install
    echo "    installed: $PREFIX/bin/sway ($("$PREFIX/bin/sway" --version 2>/dev/null || true))"
fi

# --------------------------------------------------------------- swaylock-effects
if [ -n "$FORCE" ] || ! [ -x "$PREFIX/bin/swaylock" ]; then
    echo "==> Building swaylock-effects"
    rm -rf "$SRC/swaylock-effects"
    # pinned: one commit past v1.7.0.0 (background rescale fix)
    git init -q "$SRC/swaylock-effects"
    git -C "$SRC/swaylock-effects" fetch -q --depth 1 https://github.com/jirutka/swaylock-effects.git 496059a8565c2d5eed672c2e5bc5e1edd14b3de8
    git -C "$SRC/swaylock-effects" checkout -q FETCH_HEAD
    meson setup "$SRC/swaylock-effects/build" "$SRC/swaylock-effects" \
        --prefix="$PREFIX" --sysconfdir="$PREFIX/etc" --buildtype=release
    ninja -C "$SRC/swaylock-effects/build" -j"$JOBS" install
fi

# --------------------------------------------------------------- mpvpaper (optional but nice)
if [ -n "$FORCE" ] || ! [ -x "$PREFIX/bin/mpvpaper" ]; then
    echo "==> Building mpvpaper"
    rm -rf "$SRC/mpvpaper"
    git clone --depth 1 -b 1.9 https://github.com/GhostNaN/mpvpaper.git "$SRC/mpvpaper"
    meson setup "$SRC/mpvpaper/build" "$SRC/mpvpaper" --prefix="$PREFIX" --buildtype=release
    ninja -C "$SRC/mpvpaper/build" -j"$JOBS" install
fi

echo "==> Done. Make sure $PREFIX/bin is on your PATH and start sway by its"
echo "    full path from your login shell profile (e.g. exec $PREFIX/bin/sway)."
