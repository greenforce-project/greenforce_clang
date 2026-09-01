#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================
# Greenforce Clang Installer
# ==========================================

SCRIPT_NAME="$(basename "$0")"
INSTALL_DIR="$(pwd)/greenforce-clang"
LOG_FILE=""
FORCE=0
ASSUME_YES=0
MAX_RETRIES=3
RETRY_DELAY=2

URL_SCRIPT="https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_latest_url.sh"

# ==========================================
# Colors
# ==========================================
if [[ -t 1 ]]; then
    GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[0;33m"
    CYAN="\033[0;36m"; BOLD="\033[1m"; NC="\033[0m"
else
    GREEN=""; RED=""; YELLOW=""; CYAN=""; BOLD=""; NC=""
fi

ts(){ date '+%Y-%m-%d %H:%M:%S'; }

ok(){   echo -e "${GREEN}✔${NC} $1"; }
info(){ echo -e "${CYAN}➜${NC} $1"; }
warn(){ echo -e "${YELLOW}⚠${NC} $1"; }
fail(){ echo -e "${RED}✘${NC} $1" >&2; exit 1; }

# ==========================================
# Usage
# ==========================================
usage(){
    cat << EOF
Usage: $SCRIPT_NAME [options]

Options:
  -d, --dir <path>   Install directory (default: ./greenforce-clang)
  -f, --force         Overwrite existing installation without prompting
  -y, --yes           Assume "yes" to all prompts (non-interactive)
  -h, --help          Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)   INSTALL_DIR="$2"; shift 2 ;;
        -f|--force) FORCE=1; shift ;;
        -y|--yes)   ASSUME_YES=1; shift ;;
        -h|--help)  usage ;;
        *) fail "Unknown option: $1 (use --help)" ;;
    esac
done

LOG_FILE="$(dirname "$INSTALL_DIR")/greenforce-clang-install.log"
TMP_ARCHIVE=""

# ==========================================
# Cleanup / Error handling
# ==========================================
cleanup(){
    local ec=$?
    [[ -n "$TMP_ARCHIVE" && -f "$TMP_ARCHIVE" ]] && rm -f "$TMP_ARCHIVE"
    if [[ $ec -ne 0 ]]; then
        echo
        echo -e "${RED}${BOLD}╔══════════════════════════════════════════╗${NC}"
        echo -e "${RED}${BOLD}║         Installation Failed               ║${NC}"
        echo -e "${RED}${BOLD}╚══════════════════════════════════════════╝${NC}"
        echo
        echo "Debug log: $LOG_FILE"
        echo
    else
        rm -f "$LOG_FILE"
    fi
    exit "$ec"
}
trap cleanup EXIT
trap 'fail "Interrupted"' INT TERM

exec > >(while IFS= read -r line; do echo "[$(ts)] $line"; done | tee "$LOG_FILE") 2>&1

# ==========================================
# Banner
# ==========================================
banner(){
    local w=44
    local line; line=$(printf '═%.0s' $(seq 1 $w))

    echo -e "${GREEN}╔${line}╗${NC}"
    printf "${GREEN}║${NC}%*s${GREEN}║${NC}\n" $w ""
    printf "${GREEN}║${NC}${BOLD}%*s%*s${NC}${GREEN}║${NC}\n" $(( (w + 21) / 2 )) "GREENFORCE CLANG" $(( (w - 21) / 2 )) ""
    printf "${GREEN}║${NC}%*s${GREEN}║${NC}\n" $w ""
    printf "${GREEN}║${NC}${CYAN}%*s%*s${NC}${GREEN}║${NC}\n" $(( (w + 24) / 2 )) "LLVM Toolchain Installer" $(( (w - 24) / 2 )) ""
    printf "${GREEN}║${NC}%*s${GREEN}║${NC}\n" $w ""
    echo -e "${GREEN}╚${line}╝${NC}"
    echo
    echo -e "  ${BOLD}Version${NC} : Latest Release"
    echo -e "  ${BOLD}Mode${NC}    : Automatic Installation"
    echo -e "  ${BOLD}Target${NC}  : $INSTALL_DIR"
    echo
}

system_info(){
    echo "System Information"
    echo "----------------------------------------"
    echo "OS       : $(uname -s)"
    echo "Arch     : $(uname -m)"
    echo "Kernel   : $(uname -r)"
    echo "Location : $INSTALL_DIR"
    echo
}

# ==========================================
# Step tracker
# ==========================================
TOTAL_STEPS=7
STEP=0

step(){
    STEP=$((STEP + 1))
    echo -e "${CYAN}${BOLD}[${STEP}/${TOTAL_STEPS}]${NC} $1"
}

# ==========================================
# Spinner
# ==========================================
spinner(){
    local pid=$1
    local msg=$2
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % ${#frames} ))
        printf "\r${CYAN}%s${NC} %s" "${frames:$i:1}" "$msg"
        sleep 0.1
    done
    tput cnorm 2>/dev/null || true
    printf "\r\033[K"
}

# ==========================================
# Dependency check (wget or curl)
# ==========================================
FETCH_CMD=""
check_dependencies(){
    step "Checking dependencies"

    for cmd in tar sed; do
        command -v "$cmd" >/dev/null 2>&1 || fail "Missing dependency: $cmd"
    done

    if command -v wget >/dev/null 2>&1; then
        FETCH_CMD="wget"
    elif command -v curl >/dev/null 2>&1; then
        FETCH_CMD="curl"
    else
        fail "Missing dependency: wget or curl"
    fi

    ok "Dependencies OK (using $FETCH_CMD)"
    echo
}

fetch(){
    # fetch <url> -> writes to stdout
    if [[ "$FETCH_CMD" == "wget" ]]; then
        wget -qO- "$1"
    else
        curl -fsSL "$1"
    fi
}

fetch_with_retry(){
    # fetch_with_retry <url> <output_file>
    local url="$1" out="$2" attempt=1

    while (( attempt <= MAX_RETRIES )); do
        if [[ "$FETCH_CMD" == "wget" ]]; then
            wget -qO "$out" "$url" && return 0
        else
            curl -fsSL "$url" -o "$out" && return 0
        fi

        warn "Attempt $attempt/$MAX_RETRIES failed, retrying in ${RETRY_DELAY}s..."
        sleep "$RETRY_DELAY"
        attempt=$((attempt + 1))
    done

    return 1
}

# ==========================================
# Prepare
# ==========================================
prepare_directory(){
    step "Preparing installation directory"

    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ $FORCE -eq 0 && $ASSUME_YES -eq 0 ]]; then
            read -r -p "Existing installation found at $INSTALL_DIR. Remove it? [y/N] " reply
            [[ "$reply" =~ ^[Yy]$ ]] || fail "Aborted by user"
        fi
        rm -rf "$INSTALL_DIR"
        ok "Old installation removed"
    fi

    mkdir -p "$INSTALL_DIR"
    ok "Directory ready"
    echo
}

# ==========================================
# Fetch latest URL
# ==========================================
fetch_url(){
    step "Fetching latest release info"

    LATEST_URL=$(fetch "$URL_SCRIPT" | sed -n 's/^LATEST_URL=//p')

    [[ -n "$LATEST_URL" ]] || fail "Unable to retrieve latest URL"
    [[ "$LATEST_URL" =~ ^https?:// ]] || fail "Retrieved URL looks invalid: $LATEST_URL"

    ok "Release detected"
    echo
    echo "Source:"
    echo "$LATEST_URL"
    echo
}

# ==========================================
# Download & extract
# ==========================================
download_extract(){
    step "Downloading & extracting toolchain"

    TMP_ARCHIVE="$(mktemp)"

    ( fetch_with_retry "$LATEST_URL" "$TMP_ARCHIVE" ) &
    local dl_pid=$!
    spinner "$dl_pid" "Downloading toolchain archive..."
    wait "$dl_pid" || fail "Download failed after $MAX_RETRIES attempts"

    [[ -s "$TMP_ARCHIVE" ]] || fail "Downloaded archive is empty"

    local size
    size=$(du -h "$TMP_ARCHIVE" | cut -f1)
    ok "Download completed (${size})"
    echo

    # Best-effort checksum verification, if the project publishes one
    local sums_url="${LATEST_URL}.sha256"
    if fetch "$sums_url" > /tmp/greenforce_sha256_check 2>/dev/null && [[ -s /tmp/greenforce_sha256_check ]]; then
        info "Verifying checksum..."
        local expected actual
        expected=$(awk '{print $1}' /tmp/greenforce_sha256_check)
        actual=$(sha256sum "$TMP_ARCHIVE" | awk '{print $1}')
        rm -f /tmp/greenforce_sha256_check

        if [[ "$expected" == "$actual" ]]; then
            ok "Checksum verified"
        else
            fail "Checksum mismatch! Expected $expected, got $actual"
        fi
    else
        warn "No checksum file found upstream, skipping verification"
    fi
    echo

    ( tar -xzf "$TMP_ARCHIVE" -C "$INSTALL_DIR" ) &
    local ex_pid=$!
    spinner "$ex_pid" "Extracting archive..."
    wait "$ex_pid" || fail "Extraction failed"

    rm -f "$TMP_ARCHIVE"; TMP_ARCHIVE=""
    ok "Extraction completed"
    echo
}

# ==========================================
# Verify
# ==========================================
verify(){
    step "Verifying installation"

    [[ -x "$INSTALL_DIR/bin/clang" ]] || fail "clang binary not found"

    CLANG_VERSION=$("$INSTALL_DIR/bin/clang" --version | head -n1)

    ok "clang installed"
    echo
    echo "Version:"
    echo "$CLANG_VERSION"
    echo
}

# ==========================================
# PATH
# ==========================================
detect_rc_file(){
    case "${SHELL:-}" in
        */zsh)  echo "$HOME/.zshrc" ;;
        */bash) echo "$HOME/.bashrc" ;;
        *)      echo "" ;;
    esac
}

setup_path(){
    step "Updating PATH"

    export PATH="$INSTALL_DIR/bin:$PATH"

    if command -v clang >/dev/null 2>&1; then
        ok "clang available in current shell"
    else
        warn "clang not detected in PATH"
    fi
    echo

    local rc_file; rc_file=$(detect_rc_file)
    local path_line="export PATH=\"$INSTALL_DIR/bin:\$PATH\""

    if [[ -n "$rc_file" ]]; then
        if [[ -f "$rc_file" ]] && grep -qF "$INSTALL_DIR/bin" "$rc_file" 2>/dev/null; then
            info "PATH entry already present in $rc_file"
        else
            local add_it=$ASSUME_YES
            if [[ $ASSUME_YES -eq 0 ]]; then
                read -r -p "Add clang to PATH permanently in $rc_file? [y/N] " reply
                [[ "$reply" =~ ^[Yy]$ ]] && add_it=1
            fi

            if [[ "$add_it" -eq 1 ]]; then
                {
                    echo ""
                    echo "# Added by Greenforce Clang Installer"
                    echo "$path_line"
                } >> "$rc_file"
                ok "PATH entry added to $rc_file"
            else
                info "Skipped — add manually if needed"
            fi
        fi
    else
        warn "Could not detect shell rc file, add PATH manually"
    fi
    echo
}

# ==========================================
# Summary
# ==========================================
summary(){
    local w=44
    local line; line=$(printf '═%.0s' $(seq 1 $w))

    echo -e "${GREEN}╔${line}╗${NC}"
    printf "${GREEN}║${NC}${BOLD}${GREEN}%*s%*s${NC}${GREEN}║${NC}\n" $(( (w + 22) / 2 )) "✔ Installation Complete" $(( (w - 22) / 2 )) ""
    echo -e "${GREEN}╚${line}╝${NC}"
    echo
    echo -e "  ${BOLD}Clang binary${NC} : $INSTALL_DIR/bin/clang"
    echo -e "  ${BOLD}Version${NC}      : $CLANG_VERSION"
    echo
    echo -e "  ${BOLD}Add to PATH (if not done automatically):${NC}"
    echo "    export PATH=\"$INSTALL_DIR/bin:\$PATH\""
    echo
    echo -e "  ${YELLOW}Note:${NC} PATH change in this shell is temporary unless"
    echo "        added to your shell rc file."
    echo
}

# ==========================================
# Main
# ==========================================
main(){
    banner
    system_info
    check_dependencies
    prepare_directory
    fetch_url
    download_extract
    verify
    setup_path
    summary
}

main
