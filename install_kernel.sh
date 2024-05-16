#!/usr/bin/env bash

get_dir=$(pwd)
case $# in
    0)
        cc_path="$get_dir/greenforce-clang" ;;
    1)
        cc_path="$get_dir/$1" ;;
    *)
        echo "Too many arguments. Only the first one will be considered."
        cc_path="$get_dir/$1" ;;
esac
[[ ! -d $cc_path ]] && mkdir -p $cc_path
changesforthescripts

wget -c "$latest_url" -O - | tar --use-compress-program=unzstd -xf - -C $cc_path
git clone https://github.com/greenforce-project/gcc-arm64 -b main $get_dir/gcc64 --depth=1
git clone https://github.com/greenforce-project/gcc-arm64 -b main $get_dir/gcc32 --depth=1

BUILD_KERNEL_FLAGS="CC=clang "
BUILD_KERNEL_FLAGS+="AR=llvm-ar "
BUILD_KERNEL_FLAGS+="OBJDUMP=llvm-objdump "
BUILD_KERNEL_FLAGS+="STRIP=llvm-strip "
BUILD_KERNEL_FLAGS+="NM=llvm-nm "
BUILD_KERNEL_FLAGS+="VERBOSE=0 "
BUILD_KERNEL_FLAGS+="CROSS_COMPILE=aarch64-linux-gnu- "
BUILD_KERNEL_FLAGS+="CROSS_COMPILE_COMPAT=arm-linux-gnueabi-"
BUILD_KERNEL_FLAGS_LLD="$BUILD_KERNEL_FLAGS LD=ld.lld"
BUILD_KERNEL_FLAGS_FULL="$BUILD_KERNEL_FLAGS LLVM=1"

export PATH="$cc_path/bin:$get_dir/gcc64/bin:$get_dir/gcc32/bin:$PATH"
export BUILD_KERNEL_FLAGS BUILD_KERNEL_FLAGS_LLD BUILD_KERNEL_FLAGS_FULL
