#!/usr/bin/env bash

tc_path="$HOME"
cc_path="$tc_path/greenforce-clang"

if [ ! -d "$cc_path" ]; then
    mkdir -p "$cc_path"
fi

wget https://raw.githubusercontent.com/greenforce-project/greenforce_clang/main/get_latest_url.sh
source get_latest_url.sh; rm -rf get_latest_url.sh

echo "Downloading and extracting clang..."
wget -c "$LATEST_URL" -O - | tar -k --use-compress-program=unzstd -xf - -C "$cc_path"
if [ -a "$cc_path/bin/clang" ]; then
    echo "Clang has been saved in: $cc_path"
fi

echo "Checking and cloning gcc64 repository..."
if [ ! -d "$tc_path/gcc64" ]; then
    git clone https://github.com/greenforce-project/gcc-arm64 -b main "$tc_path/gcc64" --depth=1
    echo "GCC64 repository cloned."
fi

echo "Checking and cloning gcc32 repository..."
if [ ! -d "$tc_path/gcc32" ]; then
    git clone https://github.com/greenforce-project/gcc-arm64 -b main "$tc_path/gcc32" --depth=1
    echo "GCC32 repository cloned."
fi

export PATH="$cc_path/bin:$tc_path/gcc64/bin:$tc_path/gcc32/bin:$PATH"
export LD_LIBRARY_PATH="$cc_path/bin/../lib:$LD_LIBRARY_PATH"
