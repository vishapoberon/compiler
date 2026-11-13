# Configuring VOC for AMD GPU execution

VOC's `-jG` option asks its C backend to compile OpenMP target regions.
The backend needs a compatible offload compiler, runtime, device libraries
and driver. This page describes the tested Debian 13 setup for an installed
VOC 5.0. The [tutorial](GPUTutorial.md) explains the Oberon programs.

## Packages and device access

The tested compiler is Clang 19.1.7 with LLVM OpenMP and Debian's ROCm
device libraries. Optimized GCC 14 offloading failed with
`HSA_STATUS_ERROR_INVALID_ISA` on the test machine's integrated AMD
`gfx1036` GPU. The failure also occurred in standalone C. Clang 19 passed
the optimized tests on both AMD GPUs, so this setup uses Clang.

An administrator can install the required packages with:

```sh
sudo apt install clang-19 clang-tools-19 lld-19 libomp-19-dev \
  rocm-device-libs-17 libhsa-runtime-dev rocminfo
```

`clang-tools-19` supplies the offload packager and linker wrapper. The OpenMP
package supplies the host and AMD device runtimes. The ROCm package supplies
device bitcode. `libhsa-runtime-dev` supplies the unversioned HSA library
name loaded by Clang's runtime. Package names and paths vary by distribution.

Check device availability and permissions:

```sh
rocminfo
id
ls -l /dev/kfd /dev/dri/render*
```

Your account needs access to the compute and render devices, usually through
the `render` group. An administrator may need to grant access, followed by a
fresh login.

## Installing VOC with Clang

VOC records its default C backend when it is built. To install a Clang-based
VOC in `/opt/voc`, run the following from the VOC source directory:

```sh
export PATH="/usr/lib/llvm-19/bin:$PATH"
make CC=clang INSTALLDIR=/opt/voc
sudo make CC=/usr/lib/llvm-19/bin/clang INSTALLDIR=/opt/voc install
export PATH="/opt/voc/bin:$PATH"
```

The first `make` builds and tests a local installation image. The second
copies it into `/opt/voc`. VOC then invokes `clang` by default. Keeping
LLVM 19's `bin` directory on `PATH` selects that version for later builds.
Use the paths supplied by your distribution when they differ.

For an existing GCC-based VOC installation, `CC=clang-19 voc ...` selects
Clang for a parallel compilation. A Clang-based installation lets subsequent
commands use simply `voc`.

## Selecting a device

The test machine contains these devices:

| GPU | Architecture | ROCr device index on the test machine |
| --- | --- | --- |
| Radeon RX 5600 XT | `gfx1010` | `0` |
| Ryzen 9 9950X integrated Radeon | `gfx1036` | `1` |

Choose the architecture and device reported by `rocminfo` on your machine.
The RX 5600 XT settings on the test machine are:

```sh
export GPU_ARCH=gfx1010
export ROCR_VISIBLE_DEVICES=0
export OMP_DEFAULT_DEVICE=0
```

`ROCR_VISIBLE_DEVICES` filters the devices visible to the AMD runtime.
`OMP_DEFAULT_DEVICE=0` chooses the first device after filtering.

## Configuring VOC's backend

Set these variables in the shell where you will run VOC:

```sh
export CFLAGS='-O3 -fno-strict-aliasing'
export VOC_OPENMP_CFLAGS="-fopenmp -fopenmp-targets=amdgcn-amd-amdhsa --offload-arch=$GPU_ARCH --rocm-device-lib-path=/usr/lib/llvm-17/lib/clang/17/amdgcn/bitcode"
export VOC_OPENMP_LDFLAGS="$VOC_OPENMP_CFLAGS"
export LD_LIBRARY_PATH="/usr/lib/llvm-19/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

VOC invokes the selected compiler and links the executable. For example:

```sh
voc -sFmjG Vectors.Mod
OMP_TARGET_OFFLOAD=MANDATORY ./Vectors
```

The compile and link settings both retain the offload flags so the final
executable contains its device image. The tested device bitcode resides in
LLVM 17's directory, while the compiler and OpenMP runtime are version 19.
Check the actual package paths on your system.

Keep these variables in a setup file if you use the same GPU regularly.
Source that file before compiling GPU programs. Recompile device objects
when changing architectures.

## Checking execution

`OMP_TARGET_OFFLOAD=MANDATORY` requires offloading. The source examples also
provide an execution-location probe using OpenMP's `omp_is_initial_device()`.
From a VOC source checkout, with an installed `voc` and `VOCROOT` naming its
data directory, run:

```sh
make -C src/examples/language/gpu run-gpu \
  VOC="$(command -v voc)" VOCROOT="$VOCROOT" GPU_CC=clang-19
```

The probe must confirm device execution before the Oberon examples run.
Host-fallback checks exercise generated code on the CPU.

## Diagnosing failures

* **Missing `clang-offload-packager`:** install the matching Clang tools.
* **Missing device bitcode:** check `--rocm-device-lib-path` and the files
  installed for the selected architecture.
* **Missing `libomptarget.so.19.1`:** add LLVM's library directory to the
  runtime search path.
* **Failure before the kernel runs:** check HSA library discovery, device
  permissions, visible-device selection and architecture. Run the location
  probe before testing a large application.
* **`INVALID_ISA` with optimized GCC 14 on `gfx1036`:** this failure was
  reproduced in standalone C and VOC output. GCC `-O0` passed. Clang 19
  passed the complete optimized suite on both tested AMD GPUs.
* **VOC rejects an expression:** check the supported GPU subset in the
  tutorial. HALD supplies a dedicated backend for its indirect lookups.

For detailed Clang runtime diagnostics, set `LIBOMPTARGET_INFO=63`.
Unset it before measuring performance.
