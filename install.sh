#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# wpx installer for macOS (arm64) and Linux (amd64)
# Usage: curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/install.sh | bash
# Pin a version: WPX_VERSION=v1.2.3 bash install.sh
# ================================================================

REPO="akash-aman/wpx"
GITHUB_API="https://api.github.com/repos/${REPO}"
GITHUB_DL="https://github.com/${REPO}/releases/download"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()  { printf "${GREEN}  ✓${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}  ⚠${NC} %s\n" "$1"; }
fail() { printf "${RED}  ✗${NC} %s\n" "$1" >&2; exit 1; }
info() { printf "${BLUE}  →${NC} %s\n" "$1"; }
header() { printf "\n${BOLD}%s${NC}\n" "$1"; }

WPX_HOME="${WPX_HOME:-$HOME/.wpx}"
WPX_SITES="${WPX_SITES_HOME:-$HOME/WPX Sites}"
INSTALL_DIR="/usr/local/bin"

header "wpx installer"

# ── 1. Platform check ────────────────────────────────────────
header "[1/8] Platform"

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        GOOS="darwin"
        [[ "$ARCH" == "arm64" ]] || fail "wpx on macOS supports arm64 only (got $ARCH)"
        GOARCH="arm64"
        log "macOS $(sw_vers -productVersion) ($ARCH)"
        ;;
    Linux)
        GOOS="linux"
        [[ "$ARCH" == "x86_64" ]] || fail "wpx on Linux supports x86_64 only (got $ARCH)"
        GOARCH="amd64"
        log "Linux $(uname -r) ($ARCH)"
        ;;
    *)
        fail "unsupported OS: $OS (supported: macOS arm64, Linux amd64)"
        ;;
esac

# ── 2. Dependencies ──────────────────────────────────────────
header "[2/8] Dependencies"

for dep in curl shasum; do
    if command -v "$dep" &>/dev/null; then
        log "$dep: found"
    else
        fail "$dep is required but not found"
    fi
done

# Optional deps
if command -v docker &>/dev/null; then
    log "docker: found (optional — for --search / Elasticsearch)"
else
    warn "docker: not found (optional — only needed with --search flag)"
fi

if command -v mkcert &>/dev/null; then
    log "mkcert: found (for HTTPS)"
else
    warn "mkcert: not found — install: brew install mkcert nss"
fi

# ── 3. Resolve version ───────────────────────────────────────
header "[3/8] Resolve version"

VERSION="${WPX_VERSION:-}"

if [[ -z "$VERSION" ]]; then
    info "fetching latest release..."
    VERSION=$(curl -fsSL "${GITHUB_API}/releases/latest" \
        | grep '"tag_name"' \
        | sed -E 's/.*"([^"]+)".*/\1/') || fail "could not fetch latest version"
fi

# Ensure version starts with v
[[ "$VERSION" == v* ]] || VERSION="v${VERSION}"

log "version: $VERSION"

# ── 4. Download ──────────────────────────────────────────────
header "[4/8] Download"

TMPDIR=$(mktemp -d /tmp/wpx-install.XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT

TARBALL="wpx-${VERSION}-${GOOS}-${GOARCH}.tar.gz"
TARBALL_URL="${GITHUB_DL}/${VERSION}/${TARBALL}"
CHECKSUM_URL="${TARBALL_URL}.sha256"

info "downloading ${TARBALL}..."
curl -fSL --progress-bar -o "${TMPDIR}/${TARBALL}" "${TARBALL_URL}" \
    || fail "download failed — check version exists: ${TARBALL_URL}"

info "downloading checksum..."
curl -fsSL -o "${TMPDIR}/${TARBALL}.sha256" "${CHECKSUM_URL}" \
    || fail "checksum download failed"

info "verifying checksum..."
(cd "$TMPDIR" && shasum -a 256 -c "${TARBALL}.sha256") \
    || fail "checksum verification failed — file may be corrupted"
log "checksum OK"

info "extracting..."
tar xzf "${TMPDIR}/${TARBALL}" -C "${TMPDIR}"
[[ -f "${TMPDIR}/wpx" ]] || fail "tarball did not contain wpx binary"
log "extracted wpx binary"

# ── 5. Install binary ────────────────────────────────────────
header "[5/8] Install binary"

info "installing to $INSTALL_DIR/wpx..."
echo "  (requires sudo — enter your password if prompted)"

# Cache sudo for this session
if ! sudo -n true 2>/dev/null; then
    sudo -v || fail "sudo authentication failed"
fi

# Keep sudo alive in background for the rest of the script
( while true; do sudo -n true; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!
# Update trap to clean both tmpdir and sudo keepalive
trap "rm -rf '$TMPDIR'; kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

sudo mkdir -p "$INSTALL_DIR"
sudo cp "${TMPDIR}/wpx" "$INSTALL_DIR/wpx"
sudo chmod 755 "$INSTALL_DIR/wpx"
sudo chown "$(id -u):$(id -g)" "$INSTALL_DIR/wpx"

# Clear quarantine + re-sign (macOS only)
if [[ "$GOOS" == "darwin" ]]; then
    sudo xattr -cr "$INSTALL_DIR/wpx" 2>/dev/null || true
    sudo codesign -s - -f "$INSTALL_DIR/wpx" 2>/dev/null || true
fi

# Verify binary runs
if "$INSTALL_DIR/wpx" version &>/dev/null; then
    log "installed: $INSTALL_DIR/wpx ($VERSION)"
else
    warn "binary installed but 'wpx version' failed"
    warn "try: sudo xattr -cr $INSTALL_DIR/wpx"
fi

# ── 6. Directory structure & permissions ──────────────────────
header "[6/8] Directory structure"

dirs=(
    "$WPX_HOME"
    "$WPX_HOME/bin"
    "$WPX_HOME/cache"
    "$WPX_HOME/cache/php-ext"
    "$WPX_HOME/certs"
    "$WPX_HOME/locks"
    "$WPX_HOME/logs"
    "$WPX_HOME/proxy"
    "$WPX_HOME/proxy/conf.d"
    "$WPX_HOME/proxy/logs"
    "$WPX_HOME/proxy/temp"
    "$WPX_SITES"
)

for d in "${dirs[@]}"; do
    mkdir -p "$d"
    chmod 755 "$d"
done

# Init wpx (writes config.json, registry.json)
"$INSTALL_DIR/wpx" init 2>/dev/null || true

log "state: $WPX_HOME"
log "sites: $WPX_SITES"

# Permission audit

check_perm() {
    local path="$1" want="$2" label="$3"
    if [[ ! -e "$path" ]]; then
        warn "$label: $path does not exist"
        return
    fi
    actual=$(stat -f "%Lp" "$path" 2>/dev/null || stat -c "%a" "$path" 2>/dev/null)
    if [[ "$actual" == "$want" ]]; then
        log "$label: $path ($actual)"
    else
        warn "$label: $path is $actual, fixing to $want"
        chmod "$want" "$path"
    fi
}

check_perm "$WPX_HOME"          "755" "wpx home"
check_perm "$WPX_HOME/bin"      "755" "binaries"
check_perm "$WPX_HOME/cache"    "755" "cache"
check_perm "$WPX_HOME/certs"    "755" "certs"
check_perm "$WPX_HOME/locks"    "755" "locks"
check_perm "$WPX_HOME/logs"     "755" "logs"
check_perm "$WPX_HOME/proxy"    "755" "proxy"
check_perm "$WPX_SITES"         "755" "sites"

# /etc/hosts
if [[ -r /etc/hosts ]]; then
    log "/etc/hosts: readable"
else
    warn "/etc/hosts: not readable"
fi

if sudo -n test -w /etc/hosts 2>/dev/null; then
    log "/etc/hosts: writable (via sudo)"
else
    warn "/etc/hosts: sudo write will prompt each time"
fi

# ── 7. Port check ────────────────────────────────────────────
header "[7/8] Port check (80 & 443)"

check_port() {
    local port=$1
    local pids
    pids=$(lsof -ti "tcp:$port" -sTCP:LISTEN 2>/dev/null || true)

    if [[ -z "$pids" ]]; then
        log "port $port: free"
        return
    fi

    for pid in $pids; do
        local cmd
        cmd=$(ps -p "$pid" -o command= 2>/dev/null | head -c 80)

        # Check if it's our own proxy nginx
        if echo "$cmd" | grep -q "$WPX_HOME/proxy"; then
            log "port $port: wpx proxy (pid $pid)"
        elif echo "$cmd" | grep -q "nginx.*wpx"; then
            log "port $port: wpx nginx (pid $pid)"
        else
            warn "port $port: OCCUPIED by pid $pid"
            warn "  $cmd"

            if echo "$cmd" | grep -qi "httpd\|apache"; then
                warn "  fix: sudo apachectl stop"
                warn "  permanent: sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist"
            elif echo "$cmd" | grep -qi "caddy"; then
                warn "  fix: brew services stop caddy"
            elif echo "$cmd" | grep -qi "nginx"; then
                warn "  fix: sudo nginx -s stop  (or: brew services stop nginx)"
            fi
        fi
    done
}

check_port 80
check_port 443

# ── 8. SSL / mkcert ──────────────────────────────────────────
header "[8/8] SSL setup"

if command -v mkcert &>/dev/null; then
    info "installing local CA (may prompt for password)..."
    mkcert -install 2>/dev/null && log "local CA installed" || warn "mkcert -install failed"
else
    warn "mkcert not installed — sites will use HTTP only"
    warn "install: brew install mkcert nss && mkcert -install"
fi

# ── Shell integration ─────────────────────────────────────
header "Shell integration"

CURRENT_SHELL="$(basename "${SHELL:-/bin/zsh}")"

add_to_rc() {
    local rc="$1" content="$2" marker="$3"
    [[ -f "$rc" ]] || return
    if grep -qF "$marker" "$rc" 2>/dev/null; then
        return
    fi
    printf "\n%s\n" "$content" >> "$rc"
    log "updated $rc"
}

SHELL_BLOCK='# wpx
export PATH="/usr/local/bin:$PATH"'

case "$CURRENT_SHELL" in
    zsh)
        add_to_rc "$HOME/.zshrc" "$SHELL_BLOCK"$'\n''eval "$(wpx completion zsh)"' "# wpx"
        log "zsh: completion added to ~/.zshrc"
        ;;
    bash)
        add_to_rc "$HOME/.bashrc" "$SHELL_BLOCK"$'\n''eval "$(wpx completion bash)"' "# wpx"
        add_to_rc "$HOME/.bash_profile" 'test -f ~/.bashrc && source ~/.bashrc' ".bashrc"
        log "bash: completion added to ~/.bashrc"
        ;;
    *)
        warn "unknown shell ($CURRENT_SHELL) — add to PATH manually"
        ;;
esac

# ── Doctor ────────────────────────────────────────────────────
header "Doctor"
"$INSTALL_DIR/wpx" doctor 2>&1 || true

# ── Summary ───────────────────────────────────────────────────
header "Done!"
echo ""
echo "  wpx create mysite              # create a WordPress site (~12s)"
echo "  wpx create vip --vip           # VIP Go (memcached; pass --search for ES)"
echo "  wpx list                       # list sites"
echo "  wpx doctor                     # check system health"
echo ""
echo "  Reload your shell:  source ~/.${CURRENT_SHELL}rc"
echo ""
