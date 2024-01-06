# Greenforce Clang

## Host compatibility

This toolchain is built on Ubuntu 22.04.3 LTS, which uses glibc 2.35. Compatibility with older distributions cannot be guaranteed. Other libc implementations (such as musl) are not supported.

## Building Linux

This is how you start initializing the Greenforce Clang to your server, use a command like this:

```bash
# Create a directory for the source files
mkdir -p ~/toolchains/greenforce-clang
```

Then to download:

```bash
wget -c https://github.com/greenforce-project/greenforce_clang/releases/download/07012024/greenforce-clang-18.0.0git-07012024-0136.tar.zst -O - | tar --use-compress-program=unzstd -xf - -C ~/toolchains/greenforce-clang

```

Make sure you have this toolchain in your `PATH`:

```bash

export PATH="~/toolchains/greenforce-clang/bin:$PATH"

```

For an AArch64 cross-compilation setup, you must set the following variables. Some of them can be environment variables, but some must be passed directly to `make` as a command-line argument. It is recommended to pass **all** of them as `make` arguments to avoid confusing errors:

- `CC=clang` (must be passed directly to `make`)
- `CROSS_COMPILE=aarch64-linux-gnu-`
- If your kernel has a 32-bit vDSO: `CROSS_COMPILE_ARM32=arm-linux-gnueabi-`

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
- No separate GCC/binutils toolchains are necessary; all tools are bundled.
