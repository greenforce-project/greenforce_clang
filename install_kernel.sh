#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "No custom path provided. Using default path: $HOME/greenforce-clang"
    export cc_path="$HOME/greenforce-clang"
elif [ $# -eq 1 ]; then
    echo "Custom path provided: $1"
    export cc_path="$1"
    echo "Setting custom path: $cc_path"
else
    echo "Too many arguments. Only the first one will be considered."
    export cc_path="$1"
    echo "Setting custom path: $cc_path"
fi

if [ ! -d "$cc_path" ]; then
    mkdir -p "$cc_path"
fi

wget -N -q https://raw.githubusercontent.com/greenforce-project/greenforce_clang/main/latest_url.txt
source latest_url.txt; rm -rf latest_url.txt

echo "Downloading and extracting clang..."
wget -c "$latest_url" -O - | tar -k --use-compress-program=unzstd -xf - -C "$cc_path"
if [ -a $cc_path/bin/clang ]; then
    echo "Clang has been saved in: $cc_path"
fi

echo "Checking and cloning gcc64 repository..."
if [ ! -d "$HOME/gcc64" ]; then
    git clone https://github.com/greenforce-project/gcc-arm64 -b main "$HOME/gcc64" --depth=1
    echo "GCC64 repository cloned."
fi

echo "Checking and cloning gcc32 repository..."
if [ ! -d "$HOME/gcc32" ]; then
    git clone https://github.com/greenforce-project/gcc-arm64 -b main "$HOME/gcc32" --depth=1
    echo "GCC32 repository cloned."
fi

export PATH="$HOME/greenforce-clang/bin:$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
