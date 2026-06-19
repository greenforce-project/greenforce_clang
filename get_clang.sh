#!/usr/bin/env bash

set -euo pipefail

DIR="$(pwd)"
CLANG_DIR="$DIR/greenforce-clang"
URL_SCRIPT="https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_latest_url.sh"

# Colors (only when output is an actual terminal)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
    GREEN=''; RED=''; YELLOW=''; NC=''
fi
ok()   { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

echo "========================================"
echo " Greenforce Clang Setup Script"
echo "========================================"
echo "Working directory : $DIR"
echo "Install directory  : $CLANG_DIR"
echo ""

# Step 1: Check dependencies & prepare directory
echo "[1/6] Checking dependencies & preparing directory..."
for cmd in wget tar; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Required command not found: $cmd"
done
if [[ -d "$CLANG_DIR" ]]; then
    echo "  Existing install found, removing for a clean setup..."
    rm -rf "$CLANG_DIR"
fi
mkdir -p "$CLANG_DIR"
ok "Dependencies OK, directory ready"
echo ""

# Step 2: Fetch latest URL (parse value only, never execute remote script)
echo "[2/6] Fetching latest download URL..."
LATEST_URL="$(wget -qO- "$URL_SCRIPT" | sed -n 's/^LATEST_URL=//p')"
[[ -n "$LATEST_URL" ]] || fail "Failed to fetch latest URL"
ok "Successfully fetched URL"
echo "Latest URL: $LATEST_URL"
echo ""

# Step 3: Download & extract
echo "[3/6] Downloading Greenforce Clang..."
wget -qO- "$LATEST_URL" | tar -xz -C "$CLANG_DIR" \
    || fail "Download or extraction failed"
ok "Download & extraction complete"
echo ""

# Step 4: Verify installation
echo "[4/6] Verifying installation..."
if [[ -x "$CLANG_DIR/bin/clang" ]]; then
    CLANG_VERSION="$("$CLANG_DIR/bin/clang" --version | head -n 1)"
    ok "Clang found"
    echo "Version: $CLANG_VERSION"
else
    fail "Clang binary not found at $CLANG_DIR/bin/clang (archive layout may have changed)"
fi
echo ""

# Step 5: Export PATH (current session only)
echo "[5/6] Exporting PATH..."
export PATH="$CLANG_DIR/bin:$PATH"
ok "PATH updated for current session"
echo ""

# Step 6: Validate PATH
echo "[6/6] Validating clang in PATH..."
if command -v clang >/dev/null 2>&1; then
    ok "Clang is accessible globally"
    echo "Detected at: $(command -v clang)"
else
    warn "Clang not detected in PATH!"
    echo "  Add it manually: export PATH=\"$CLANG_DIR/bin:\$PATH\""
fi

echo ""
echo "========================================"
echo " Setup completed!"
echo "========================================"
echo "Clang binary : $CLANG_DIR/bin/clang"
echo ""
echo "NOTE:"
echo "- The PATH export above only applies to this shell session."
echo "- To make it permanent, add this line to your shell config (~/.bashrc, ~/.zshrc):"
echo "  export PATH=\"$CLANG_DIR/bin:\$PATH\""
echo "========================================"
