#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# wpx uninstaller
# Stops all sites, destroys them, removes binary + state + shell integration.
# Usage: curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/uninstall.sh | bash
# ================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()  { printf "${GREEN}  ✓${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}  ⚠${NC} %s\n" "$1"; }
fail() { printf "${RED}  ✗${NC} %s\n" "$1" >&2; exit 1; }
info() { printf "${BLUE}  →${NC} %s\n" "$1"; }
header() { printf "\n${BOLD}%s${NC}\n" "$1"; }

WPX_HOME="${WPX_HOME:-$HOME/.wpx}"
WPX_SITES="${WPX_SITES_HOME:-$HOME/WPX Sites}"
WPX_BIN="/usr/local/bin/wpx"

header "wpx uninstaller"
echo ""
echo "  This will:"
echo "    1. Stop the wpx proxy"
echo "    2. Destroy all wpx sites (stops processes, removes data)"
echo "    3. Kill any orphan wpx processes"
echo "    4. Remove the wpx binary from $WPX_BIN"
echo "    5. Remove wpx state directory ($WPX_HOME)"
echo "    6. Remove shell integration from ~/.zshrc / ~/.bashrc"
echo ""

# ── Confirmation ──────────────────────────────────────────────
read -rp "  Are you sure? This cannot be undone. [y/N] " confirm
case "$confirm" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "  Aborted."; exit 0 ;;
esac

# ── 1. Stop proxy ────────────────────────────────────────────
header "[1/6] Stop proxy"

if command -v wpx &>/dev/null; then
    wpx proxy stop 2>/dev/null && log "proxy stopped" || warn "proxy was not running"
else
    warn "wpx binary not found — skipping proxy stop"
fi

# ── 2. Destroy all sites ─────────────────────────────────────
header "[2/6] Destroy all sites"

if command -v wpx &>/dev/null; then
    wpx destroy --all --force 2>/dev/null && log "all sites destroyed" \
        || warn "destroy returned non-zero (sites may not exist)"
else
    warn "wpx binary not found — skipping site destruction"
fi

# ── 3. Kill orphan processes ─────────────────────────────────
header "[3/6] Kill orphan processes"

KILLED=0

# Kill any process with wpx in its path or arguments
for pattern in "\.wpx/" "wpx.*proxy" "wpx.*nginx"; do
    pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        for pid in $pids; do
            # Don't kill ourselves
            [[ "$pid" == "$$" ]] && continue
            cmd=$(ps -p "$pid" -o command= 2>/dev/null || true)
            if [[ -n "$cmd" ]]; then
                kill "$pid" 2>/dev/null && { info "killed pid $pid: $cmd"; KILLED=$((KILLED + 1)); } || true
            fi
        done
    fi
done

# Wait briefly then force-kill any survivors
if [[ "$KILLED" -gt 0 ]]; then
    sleep 1
    for pattern in "\.wpx/" "wpx.*proxy" "wpx.*nginx"; do
        pids=$(pgrep -f "$pattern" 2>/dev/null || true)
        for pid in $pids; do
            [[ "$pid" == "$$" ]] && continue
            kill -9 "$pid" 2>/dev/null || true
        done
    done
fi

log "killed $KILLED orphan process(es)"

# ── 4. Remove binary ─────────────────────────────────────────
header "[4/6] Remove binary"

if [[ -f "$WPX_BIN" ]]; then
    info "removing $WPX_BIN (requires sudo)"
    sudo rm -f "$WPX_BIN" && log "removed $WPX_BIN" || warn "could not remove $WPX_BIN"
else
    log "binary not found at $WPX_BIN — already removed"
fi

# ── 5. Remove state directory ────────────────────────────────
header "[5/6] Remove state"

if [[ -d "$WPX_HOME" ]]; then
    info "removing $WPX_HOME..."
    rm -rf "$WPX_HOME" && log "removed $WPX_HOME" || warn "could not remove $WPX_HOME"
else
    log "$WPX_HOME does not exist — already clean"
fi

if [[ -d "$WPX_SITES" ]]; then
    read -rp "  Remove site files at $WPX_SITES? [y/N] " remove_sites
    case "$remove_sites" in
        [yY]|[yY][eE][sS])
            rm -rf "$WPX_SITES" && log "removed $WPX_SITES" || warn "could not remove $WPX_SITES"
            ;;
        *)
            warn "kept $WPX_SITES (remove manually if needed)"
            ;;
    esac
else
    log "$WPX_SITES does not exist"
fi

# ── 6. Remove shell integration ──────────────────────────────
header "[6/6] Shell integration"

remove_from_rc() {
    local rc="$1"
    [[ -f "$rc" ]] || return
    if grep -qF "# wpx" "$rc" 2>/dev/null; then
        # Remove the wpx block (from "# wpx" to next blank line or EOF)
        sed -i.bak '/^# wpx$/,/^$/d' "$rc" 2>/dev/null \
            || sed -i '' '/^# wpx$/,/^$/d' "$rc" 2>/dev/null \
            || true
        rm -f "${rc}.bak"
        log "cleaned $rc"
    fi
}

remove_from_rc "$HOME/.zshrc"
remove_from_rc "$HOME/.bashrc"
remove_from_rc "$HOME/.bash_profile"

# ── Hosts cleanup ─────────────────────────────────────────────
if grep -q "\.wpx\|# wpx" /etc/hosts 2>/dev/null; then
    warn "/etc/hosts may still have wpx entries — edit manually:"
    warn "  sudo nano /etc/hosts"
fi

# ── Done ──────────────────────────────────────────────────────
header "Done!"
echo ""
echo "  wpx has been completely removed."
echo "  Reload your shell: exec \$SHELL"
echo ""
