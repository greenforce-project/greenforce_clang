#!/usr/bin/env bash

DIR="$(pwd)"

mkdir -p "$DIR/greenforce-clang"

source <(curl -sL https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_latest_url.sh) && \
    wget -O - "$LATEST_URL" | tar -xz -C "$DIR/greenforce-clang"

if [[ ! -e "$DIR/greenforce-clang/bin/clang" ]]; then
    echo "Error: Clang not found." && exit 1
fi
