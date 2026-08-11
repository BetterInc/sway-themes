#!/bin/sh
# Build the sway-themes .deb packages. Meant to run inside a disposable
# debian:12 container (CI): it installs the build deps, compiles SwayFX,
# swaylock-effects and mpvpaper via build-from-source.sh with PREFIX=/usr,
# then packages each component's installed files with dpkg-deb.
#
#   packaging/mkdebs.sh <version>        e.g. packaging/mkdebs.sh 0.1.0
#
# Produces: out/*.deb
set -e

VERSION="${1:?usage: mkdebs.sh <version>}"
VERSION="${VERSION#v}"
# component packages are versioned by their upstream version, suffixed with
# the sway-themes release tag so apt upgrade ordering follows our releases
SWAYFX_V="0.3.2+bi${VERSION}"
SWAYLOCK_V="1.7.0+bi${VERSION}"
MPVPAPER_V="1.9+bi${VERSION}"
REPO=$(dirname "$(dirname "$(realpath "$0")")")
OUT="$REPO/out"
SRC="$HOME/.local/src"
MAINT="BetterInc <noreply@github.com>"

rm -rf "$OUT"; mkdir -p "$OUT"

echo "==> Building binaries into /usr (disposable container)"
apt-get update
PREFIX=/usr "$REPO/build-from-source.sh" --force

# dpkg-shlibdeps for computed runtime dependencies
apt-get install -y dpkg-dev

# stage_from_build <builddir> <stagedir> - copy everything that build installed
stage_from_build() {
    python3 - "$1" "$2" <<'EOF'
import json, os, shutil, subprocess, sys
build, stage = sys.argv[1], sys.argv[2]
files = json.loads(subprocess.check_output(
    ["meson", "introspect", "--installed", build]))
for dest in files.values():
    tgt = stage + dest
    os.makedirs(os.path.dirname(tgt), exist_ok=True)
    if os.path.islink(dest):
        os.path.lexists(tgt) or os.symlink(os.readlink(dest), tgt)
    elif os.path.isfile(dest):
        shutil.copy2(dest, tgt)
EOF
}

# mkdeb <name> <version> <arch> <stagedir> <depends> [extra control lines...]
mkdeb() {
    name=$1; ver=$2; arch=$3; stage=$4; depends=$5; shift 5
    mkdir -p "$stage/DEBIAN"
    { echo "Package: $name"
      echo "Version: $ver"
      echo "Architecture: $arch"
      echo "Maintainer: $MAINT"
      echo "Depends: $depends"
      for line in "$@"; do echo "$line"; done
    } > "$stage/DEBIAN/control"
    dpkg-deb --build --root-owner-group "$stage" "$OUT/${name}_${ver}_${arch}.deb"
}

# shlib_deps <stagedir> <binary...> - compute Depends via dpkg-shlibdeps
shlib_deps() {
    stage=$1; shift
    ( cd "$stage" && mkdir -p debian && touch debian/control \
      && dpkg-shlibdeps -O "$@" 2>/dev/null | sed 's/^shlibs:Depends=//' \
      && rm -rf debian )
}

echo "==> Packaging swayfx (ships /usr/bin/sway, wlroots statically linked)"
S=/tmp/stage-swayfx; rm -rf $S
stage_from_build "$SRC/swayfx/build" $S
# Debian ships the stock wallpapers as a separate sway-backgrounds package;
# shipping them here conflicts with it and nothing in the rice uses them.
rm -rf $S/usr/share/backgrounds
deps=$(shlib_deps $S usr/bin/sway usr/bin/swaymsg usr/bin/swaybar usr/bin/swaynag)
mkdeb swayfx "$SWAYFX_V" amd64 $S "$deps" \
    "Conflicts: sway" "Provides: sway" "Replaces: sway, sway-backgrounds" \
    "Section: x11" "Priority: optional" \
    "Homepage: https://github.com/WillPower3309/swayfx" \
    "Description: SwayFX compositor - sway with blur, rounded corners and shadows
 Built from swayfx 0.3.2 with wlroots 0.16.2 statically linked.
 Installs as /usr/bin/sway, replacing the sway package."

echo "==> Packaging swaylock-effects (ships /usr/bin/swaylock)"
S=/tmp/stage-swaylock; rm -rf $S
stage_from_build "$SRC/swaylock-effects/build" $S
deps=$(shlib_deps $S usr/bin/swaylock)
mkdeb swaylock-effects "$SWAYLOCK_V" amd64 $S "$deps" \
    "Conflicts: swaylock" "Provides: swaylock" "Replaces: swaylock" \
    "Section: x11" "Priority: optional" \
    "Homepage: https://github.com/jirutka/swaylock-effects" \
    "Description: swaylock fork with fancy effects
 Screen locker for Wayland with blur, clock and effects."

echo "==> Packaging mpvpaper"
S=/tmp/stage-mpvpaper; rm -rf $S
stage_from_build "$SRC/mpvpaper/build" $S
deps=$(shlib_deps $S usr/bin/mpvpaper)
mkdeb mpvpaper "$MPVPAPER_V" amd64 $S "$deps" \
    "Section: video" "Priority: optional" \
    "Homepage: https://github.com/GhostNaN/mpvpaper" \
    "Description: video wallpaper program for wlroots compositors
 Plays videos with mpv as your wallpaper."

echo "==> Packaging sway-themes (themes + switcher + configs)"
S=/tmp/stage-themes; rm -rf $S
mkdir -p $S/usr/share/sway-themes $S/usr/bin
cp -r "$REPO/config" "$REPO/themes" "$REPO/bin" \
      "$REPO/install.sh" "$REPO/uninstall.sh" "$REPO/build-from-source.sh" \
      "$REPO/README.md" "$REPO/LICENSE" $S/usr/share/sway-themes/
# wallpaper videos are never distributed (see WALLPAPER-SOURCE.txt per theme)
rm -f $S/usr/share/sway-themes/themes/*/wallpaper.mp4
ln -s ../share/sway-themes/bin/sway-theme $S/usr/bin/sway-theme
ln -s sway-theme $S/usr/bin/sway-themes   # alias: people type the package name
# per-user setup entry point (a package cannot symlink into $HOME itself)
cat > $S/usr/bin/sway-themes-setup <<'SETUP'
#!/bin/sh
# Set up the sway-themes rice for the current user (symlinks into ~/.config,
# backups kept as *.bak). Wraps /usr/share/sway-themes/install.sh.
exec sh /usr/share/sway-themes/install.sh "$@"
SETUP
chmod 755 $S/usr/bin/sway-themes-setup $S/usr/share/sway-themes/bin/sway-theme \
    $S/usr/share/sway-themes/install.sh $S/usr/share/sway-themes/uninstall.sh \
    $S/usr/share/sway-themes/build-from-source.sh
mkdeb sway-themes "$VERSION" all $S \
    "swayfx, swaylock-effects, waybar, foot, rofi, swaybg, swayidle, dunst, fonts-font-awesome" \
    "Recommends: mpvpaper, ffmpeg" \
    "Section: x11" "Priority: optional" \
    "Homepage: https://github.com/BetterInc/sway-themes" \
    "Description: themeable SwayFX rice (matrix, purple, ...)
 Switchable desktop themes for sway/swayfx covering waybar, foot, rofi,
 swaylock, dunst and animated wallpapers. Run sway-themes-setup to
 activate for your user."

echo "==> Done:"
ls -la "$OUT"
