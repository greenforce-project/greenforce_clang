#!/usr/bin/env bash

set -e

DIR="$(pwd)"
CLANG_DIR="$DIR/greenforce-clang"

echo "========================================"
echo " Greenforce Clang Setup Script"
echo "========================================"
echo "Working directory : $DIR"
echo "Install directory : $CLANG_DIR"
echo ""

# Step 1: Prepare directory
echo "[1/6] Creating directory..."
mkdir -p "$CLANG_DIR"
echo "✓ Directory ready"
echo ""

# Step 2: Fetch latest URL
echo "[2/6] Fetching latest download URL..."
if source <(curl -sL https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_latest_url.sh); then
    echo "✓ Successfully fetched URL"
    echo "Latest URL: $LATEST_URL"
else
    echo "✗ Failed to fetch latest URL"
    exit 1
fi
echo ""

# Step 3: Download & Extract
echo "[3/6] Downloading Greenforce Clang..."
if wget -O - "$LATEST_URL" | tar -xz -C "$CLANG_DIR"; then
    echo "✓ Download & extraction complete"
else
    echo "✗ Download or extraction failed"
    exit 1
fi
echo ""

# Step 4: Verify installation
echo "[4/6] Verifying installation..."
if [[ -e "$CLANG_DIR/bin/clang" ]]; then
    echo "✓ Clang found"
    CLANG_VERSION=$("$CLANG_DIR/bin/clang" --version | head -n 1)
    echo "Version: $CLANG_VERSION"
else
    echo "✗ Error: Clang binary not found!"
    exit 1
fi
echo ""

# Step 5: Export PATH (temporary for this session)
echo "[5/6] Exporting PATH..."
export PATH="$CLANG_DIR/bin:$PATH"
echo "✓ PATH updated for current session"
echo ""

# Step 6: Validate PATH
echo "[6/6] Validating clang in PATH..."
if command -v clang >/dev/null 2>&1; then
    echo "✓ Clang is accessible globally"
    echo "Detected at: $(command -v clang)"
else
    echo "⚠ Clang not detected in PATH!"
    echo ""
    echo "You may need to export it manually:"
    echo "export PATH=\"$CLANG_DIR/bin:\$PATH\""
fi

echo ""
echo "========================================"
echo " Setup completed!"
echo "========================================"
echo "Clang binary : $CLANG_DIR/bin/clang"
echo ""
echo "NOTE:"
echo "- PATH export above only applies to current shell session."
echo "- To make it permanent, add this line to your shell config (~/.bashrc, ~/.zshrc):"
echo "  export PATH=\"$CLANG_DIR/bin:\$PATH\""
echo "========================================"
