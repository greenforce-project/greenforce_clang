# Gf Clang

Gf Clang is an LLVM toolchain designed to simplify Linux kernel compilation, particularly for Android. This toolchain is customized to reduce reliance on AOSP binutils and offer a more flexible developer experience.

## Host Compatibility

This toolchain is built on Ubuntu using the default `glibc` version. Compatibility with older distributions is not guaranteed. Other `libc` implementations (such as `musl`) are currently not supported.

## Installation

To install and initialize Gf Clang on your server, run the following command:

```bash

bash <(wget -qO- https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_clang.sh)

```

Ensure the toolchain is included in your PATH:

```bash

export PATH="$(pwd)/greenforce-clang/bin:$PATH"

```

## Building Linux

For an AArch64 cross-compilation setup, the following variables must be set. While some can be defined as environment variables, it is **highly recommended** to pass all of them directly to `make` to avoid unexpected behavior:

- `CC=clang` (must be passed directly to `make`)
- `CROSS_COMPILE=aarch64-linux-gnu-`
- For 32-bit vDSO: `CROSS_COMPILE_ARM32=arm-linux-gnueabi-`

Optionally, you may use LLVM-based tools to minimize reliance on GNU binutils:

- `AR=llvm-ar`
- `NM=llvm-nm`
- `OBJCOPY=llvm-objcopy`
- `OBJDUMP=llvm-objdump`
- `STRIP=llvm-strip`

To leverage Clang's integrated assembler and LLVM's linker (`lld`), you can enable the following build options:

- `LLVM=1` (Use Clang and LLVM tools e.g., `clang`, `lld` instead of GNU tools.)
- `LLVM_IAS=1` (Use Clang's built-in assembler instead of GNU `as`.)

>**Note:** Some older kernel versions or architectures may not be fully compatible with the integrated assembler. Disable `LLVM_IAS` or apply necessary patches if build errors occur.

Older Android kernels (pre-4.14) require specific patches to be built with any Clang-based toolchain. Refer to [android-kernel-clang](https://github.com/nathanchance/android-kernel-clang) for guidance.

For Android kernels 4.19 and newer, use the upstream variable `CROSS_COMPILE_COMPAT` in place of `CROSS_COMPILE_ARM32`.

## Differences from Other Toolchains

Gf Clang is designed to be easier to use compared to toolchains like AOSP Clang. Key improvements include:

- `CLANG_TRIPLE` does not need to be set because we don't use AOSP binutils.
- `LD_LIBRARY_PATH` does not need to be set because we set library load paths in the toolchain.
