#!/usr/bin/env bash
# wpx — umbrella installer for the CLI and (on macOS) the desktop app.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --version v0.1.0
#   curl -fsSL .../install.sh | bash -s -- --cli-only
#   curl -fsSL .../install.sh | bash -s -- --app-only
#
# Behaviour by platform:
#   macOS   → installs the CLI binary AND the .app bundle (default)
#   Linux   → installs the CLI binary only (no desktop app yet)
#   other   → fails fast
#
# Internals:
#   • CLI install delegates to cli/install.sh (downloads tar.gz,
#     verifies sha256, installs to INSTALL_DIR — see that script
#     for the full flow).
#   • App install downloads wpx-<version>.dmg from the matching
#     GitHub release, mounts it, copies wpx.app into /Applications,
#     and ejects.
#
# Idempotent — re-running upgrades both components to the requested
# version (or latest if --version isn't pinned).
set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────
REPO="akash-aman/wpx"
GITHUB_API="https://api.github.com/repos/${REPO}"
GITHUB_DL="https://github.com/${REPO}/releases/download"
GITHUB_RAW="https://raw.githubusercontent.com/${REPO}"

INSTALL_CLI=true
INSTALL_APP=true
WPX_VERSION=""
BRANCH="main"   # used only for fetching cli/install.sh during dev/test

# ── Args ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cli-only)      INSTALL_APP=false; shift ;;
    --app-only)      INSTALL_CLI=false; shift ;;
    --version)       WPX_VERSION="${2:-}"; shift 2 ;;
    --version=*)     WPX_VERSION="${1#*=}"; shift ;;
    --branch)        BRANCH="${2:-}"; shift 2 ;;
    --branch=*)      BRANCH="${1#*=}"; shift ;;
    -h|--help)
      sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "✗ unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# ── Colours ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()  { printf "${GREEN}  ✓${NC} %s\n" "$1"; }
info() { printf "${BLUE}  ℹ${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}  ⚠${NC} %s\n" "$1"; }
fail() { printf "${RED}  ✗${NC} %s\n" "$1" >&2; exit 1; }

# ── Platform detection ──────────────────────────────────────────
KERNEL="$(uname -s)"
case "$KERNEL" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux"; INSTALL_APP=false ;;  # no desktop app on Linux
  *)      fail "unsupported platform: $KERNEL (need Darwin or Linux)" ;;
esac

# ── Dep check ───────────────────────────────────────────────────
for dep in curl; do
  command -v "$dep" >/dev/null 2>&1 || fail "$dep is required but not found"
done

# ── Resolve version ─────────────────────────────────────────────
if [[ -z "$WPX_VERSION" ]]; then
  info "querying latest release..."
  WPX_VERSION=$(curl -fsSL "${GITHUB_API}/releases?per_page=1" \
                | grep -m1 '"tag_name"' \
                | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
  [[ -n "$WPX_VERSION" ]] || fail "no releases found at ${GITHUB_API}/releases"
fi
# Always tag-prefix for URL paths; strip for display where it's noise.
[[ "$WPX_VERSION" == v* ]] || WPX_VERSION="v${WPX_VERSION}"
VERSION_BARE="${WPX_VERSION#v}"

printf "${BOLD}wpx installer${NC}  ${BLUE}%s${NC}  →  ${BOLD}%s${NC}\n\n" \
  "$PLATFORM" "$WPX_VERSION"

# ── 1. Install CLI (delegate to cli/install.sh) ─────────────────
if $INSTALL_CLI; then
  info "installing CLI..."
  # When run from inside a checked-out tree, prefer the local script
  # so dev installs don't hit the network. Falls back to the published
  # script for curl-pipe-bash flows.
  SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || true)"
  CLI_INSTALL=""
  if [[ -n "$SELF_DIR" && -x "$SELF_DIR/cli/install.sh" ]]; then
    CLI_INSTALL="$SELF_DIR/cli/install.sh"
    info "using local $CLI_INSTALL"
    bash "$CLI_INSTALL" --version "$WPX_VERSION"
  else
    info "fetching cli/install.sh from ${BRANCH}"
    curl -fsSL "${GITHUB_RAW}/${BRANCH}/cli/install.sh" \
      | bash -s -- --version "$WPX_VERSION"
  fi
  log "CLI installed"
else
  info "skipping CLI (--app-only)"
fi

# ── 2. Install desktop app (macOS only) ─────────────────────────
if $INSTALL_APP && [[ "$PLATFORM" == "macos" ]]; then
  DMG="wpx-${VERSION_BARE}.dmg"
  DMG_URL="${GITHUB_DL}/${WPX_VERSION}/${DMG}"
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"; for v in /Volumes/WPX*; do [ -d "$v" ] && hdiutil detach "$v" -quiet -force 2>/dev/null || true; done' EXIT

  info "downloading ${DMG}..."
  curl -fSL --progress-bar -o "$TMPDIR/$DMG" "$DMG_URL" \
    || fail "DMG download failed (${DMG_URL}) — does this release have a desktop build?"

  info "mounting..."
  MOUNT="$(hdiutil attach -nobrowse -quiet "$TMPDIR/$DMG" \
            | awk '/\/Volumes\//{$1=$2=""; sub(/^[[:space:]]+/,""); print; exit}')"
  [[ -d "$MOUNT" ]] || fail "could not mount $DMG"

  APP_SRC="$MOUNT/wpx.app"
  [[ -d "$APP_SRC" ]] || fail "wpx.app missing inside DMG"

  APP_DEST="/Applications/wpx.app"
  if [[ -d "$APP_DEST" ]]; then
    info "removing existing $APP_DEST..."
    rm -rf "$APP_DEST"
  fi
  info "copying to /Applications..."
  cp -R "$APP_SRC" "$APP_DEST"

  info "ejecting..."
  hdiutil detach "$MOUNT" -quiet || true

  # Strip the macOS quarantine attribute so the user doesn't get a
  # "downloaded from internet" warning on first launch. Signed
  # releases don't strictly need this; unsigned dev builds do.
  xattr -dr com.apple.quarantine "$APP_DEST" 2>/dev/null || true

  log "App installed at $APP_DEST"
elif $INSTALL_APP && [[ "$PLATFORM" != "macos" ]]; then
  warn "desktop app is macOS-only for now; skipping"
fi

printf "\n${GREEN}${BOLD}done${NC}\n"
if $INSTALL_CLI; then
  echo "  • wpx        $(command -v wpx 2>/dev/null || echo 'not on PATH — restart your shell')"
fi
if $INSTALL_APP && [[ "$PLATFORM" == "macos" ]]; then
  echo "  • Desktop    open -a wpx"
fi
echo "  • Update     wpx self-update"
