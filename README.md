# Greenforce Clang

## Host compatibility

This toolchain is built on Ubuntu, which uses the default glibc version. Compatibility with older distributions cannot be guaranteed. Other libc implementations (such as musl) are not supported.

## Building Linux

This is how you start initializing the Greenforce Clang to your server, use a command like this:

```bash

wget https://github.com/greenforce-project/greenforce_clang/raw/main/install_kernel.sh; bash install_kernel.sh; rm -rf install_kernel.sh

```

Make sure you have this toolchain in your `PATH`:

```bash

export PATH="~/greenforce-clang/bin:~/gcc64/bin:~/gcc32/bin:$PATH"

```

For an AArch64 cross-compilation setup, you must set the following variables. Some of them can be environment variables, but some must be passed directly to `make` as a command-line argument. It is recommended to pass **all** of them as `make` arguments to avoid confusing errors:

- `CC=clang` (must be passed directly to `make`)
- `CROSS_COMPILE=aarch64-linux-gnu-`
- For 32-bit vDSO: `CROSS_COMPILE_ARM32=arm-linux-gnueabi-`

Optionally, you can also choose to use as many LLVM tools as possible to reduce reliance on binutils. All of these must be passed directly to `make`:

- `AR=llvm-ar`
- `NM=llvm-nm`
- `OBJCOPY=llvm-objcopy`
- `OBJDUMP=llvm-objdump`
- `STRIP=llvm-strip`

Note, however, that additional kernel patches may be required for these LLVM tools to work. It is also possible to replace the binutils linkers (`lf.bfd` and `ld.gold`) with `lld` and use Clang's integrated assembler for inline assembly in C code, but that will require many more kernel patches and it is currently impossible to use the integrated assembler for *all* assembly code in the kernel.

Android kernels older than 4.14 will require patches for compiling with any Clang toolchain to work; those patches are out of the scope of this project. See [android-kernel-clang](https://github.com/nathanchance/android-kernel-clang) for more information.

Android kernels 4.19 and newer use the upstream variable `CROSS_COMPILE_COMPAT`. When building these kernels, replace `CROSS_COMPILE_ARM32` in your commands and scripts with `CROSS_COMPILE_COMPAT`.

### Differences from other toolchains

Greenforce Clang has been designed to be easy-to-use compared to other toolchains, such as [AOSP Clang](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/). The differences are as follows:

- `CLANG_TRIPLE` does not need to be set because we don't use AOSP binutils.
- `LD_LIBRARY_PATH` does not need to be set because we set library load paths in the toolchain.
