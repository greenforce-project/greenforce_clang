#!/usr/bin/env bash

DIR="$(pwd)"

mkdir -p "$DIR/greenforce-clang"

source <(curl -sL https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_latest_url.sh) && \
    wget -O - "$LATEST_URL_GZ" | tar -xz -C "$DIR/greenforce-clang"

if [[ ! -e "$DIR/greenforce-clang/bin/clang" ]]; then
    echo "missing clang!" && exit 1
fi

rm -rf *.sh *.tar.gz


