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

## LLVM Version

Gf Clang is built directly from the upstream [llvm/llvm-project](https://github.com/llvm/llvm-project) `main` branch rather than from a tagged stable release. Each release is named after the LLVM development version and the build date, e.g. `gf-clang-23.0.0-YYYYMMDD.tar.gz`.

This means Gf Clang generally tracks ahead of the latest official LLVM stable release (e.g. while upstream LLVM may be on a `22.x` stable series, Gf Clang may already be building from the `23.0.0git` development tree). Benefits include earlier access to new Clang/LLVM features and fixes relevant to kernel builds; the trade-off is that trunk builds can occasionally introduce regressions before they're fixed upstream.

To check exactly which build you have after installation:

```bash
clang --version
```

If you need a more conservative, pinned toolchain instead of a rolling trunk build, consider using a tagged stable LLVM release from [releases.llvm.org](https://releases.llvm.org/download.html) or building one yourself with [tc-build](https://github.com/ClangBuiltLinux/tc-build).

## Building Linux

For an AArch64 cross-compilation setup, the following variables must be set. While some can be defined as environment variables, it is **highly recommended** to pass all of them directly to `make` to avoid unexpected behavior:

- `CC=clang` (must be passed directly to `make`)
- `CROSS_COMPILE=aarch64-linux-gnu-`
- For 32-bit vDSO: `CROSS_COMPILE_ARM32=arm-linux-gnueabi-`

> **Note:** On sufficiently recent mainline kernel trees, `CROSS_COMPILE` can technically be omitted when using only LLVM tools, since the `--target=` triple is inferred from `ARCH`. This inference is not present on older Android kernel trees (e.g. 4.19, 5.4, 5.10), so explicitly passing `CROSS_COMPILE` as shown above remains the safe, portable default.

Optionally, you may use LLVM-based tools to minimize reliance on GNU binutils:

- `LD=ld.lld`
- `AR=llvm-ar`
- `NM=llvm-nm`
- `OBJCOPY=llvm-objcopy`
- `OBJDUMP=llvm-objdump`
- `STRIP=llvm-strip`
- `READELF=llvm-readelf`

To leverage Clang's integrated assembler and LLVM's linker (`lld`), you can enable the following build options:

- `LLVM=1` (Use Clang and LLVM tools e.g., `clang`, `lld` instead of GNU tools.)
- `LLVM_IAS=1` (Use Clang's built-in assembler instead of GNU `as`.)

> **Note on LLVM_IAS defaults:** Since Linux v5.15, the kernel build system enables the integrated assembler **by default** — on these trees `LLVM_IAS=0` is what you'd pass to fall back to GNU `as`. On older kernel trees (anything prior to 5.15, which includes most current Android `common` branches such as 4.19/5.4/5.10), the integrated assembler is still **off by default**, so `LLVM_IAS=1` must be passed explicitly as shown above. When in doubt, pass `LLVM_IAS=1` explicitly — it's a no-op on trees where it's already the default.

> **Note:** Some older kernel versions or architectures may not be fully compatible with the integrated assembler. Disable `LLVM_IAS` or apply necessary patches if build errors occur.

Older Android kernels (pre-4.14) require specific patches to be built with any Clang-based toolchain. Refer to [android-kernel-clang](https://github.com/nathanchance/android-kernel-clang) for guidance.

For Android kernels 4.19 and newer, use the upstream variable `CROSS_COMPILE_COMPAT` in place of `CROSS_COMPILE_ARM32`.

## Differences from Other Toolchains

Gf Clang is designed to be easier to use compared to toolchains like AOSP Clang. Key improvements include:

- `CLANG_TRIPLE` does not need to be set because we don't use AOSP binutils.
- `LD_LIBRARY_PATH` does not need to be set because we set library load paths in the toolchain.
