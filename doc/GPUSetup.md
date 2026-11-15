# Configuring VOC for CPU and AMD GPU execution

VOC uses `-jP` for OpenMP across CPU cores and `-jG` for OpenMP GPU target
regions. VOC invokes the C compiler and linker in both cases. This guide
assumes VOC is installed; the [tutorial](GPUTutorial.md) introduces the
Oberon programs. `SUM` and `PROD` require development sources after VOC 5.0.

## Debian packages

For CPU execution with GCC on Debian 13:

```sh
sudo apt install gcc-14 libgomp1
```

For CPU execution with Clang:

```sh
sudo apt install clang-19 libomp-19-dev
```

AMD GPU execution also needs the kernel's `amdgpu` driver, suitable AMD
firmware, the HSA runtime and an offload toolchain. Debian supplies firmware
in `firmware-amd-graphics` from its `non-free-firmware` component.

The tested compiler is Clang 19.1.7 with LLVM OpenMP and Debian's ROCm
device libraries. Optimized GCC 14 offloading failed with
`HSA_STATUS_ERROR_INVALID_ISA` on the test machine's integrated AMD
`gfx1036` GPU. The failure also occurred in standalone C. Clang 19 passed
the optimized tests on both AMD GPUs, so this setup uses Clang.

For Clang AMD offloading, install:

```sh
sudo apt install clang-19 clang-tools-19 lld-19 libomp-19-dev \
  rocm-device-libs-17 libhsa-runtime-dev rocminfo
```

`clang-tools-19` supplies the offload packager and linker wrapper. The OpenMP
package supplies the host and AMD device runtimes. The ROCm package supplies
device bitcode. `libhsa-runtime-dev` supplies the unversioned HSA library
name loaded by Clang's runtime. Package names and paths vary by distribution.

The measured Debian installation used `libhsa-runtime64-1` 6.1.2-3 and a
private compatibility-library search directory for LLVM's HSA discovery.
The development package above is the normal way to provide the unversioned
library name; a fresh installation with that package was not tested.

For GCC AMD offloading on a supported architecture:

```sh
sudo apt install gcc-14 gcc-14-offload-amdgcn libgomp-plugin-amdgcn1 rocminfo
```

Keep GCC, its offload compiler and libgomp packages at matching versions.
The [compatibility results](#tested-compatibility) below describe the
limitations of the tested GCC 14 installation.

## Gentoo packages

AMD GPU execution needs a kernel with `CONFIG_DRM_AMDGPU` and
`CONFIG_HSA_AMD`, plus the GPU's firmware from `sys-kernel/linux-firmware`:

```sh
sudo emerge --ask sys-kernel/linux-firmware
```

CPU OpenMP with GCC needs `sys-devel/gcc` built with the `openmp` USE flag.
Add the following entry to a file under `/etc/portage/package.use/`, then
update the package:

```text
sys-devel/gcc openmp
```

```sh
sudo emerge --ask --changed-use sys-devel/gcc
```

For Clang CPU OpenMP:

```sh
sudo emerge --ask llvm-core/clang llvm-runtimes/openmp
```

For AMD GPU offloading, Clang also needs the LLVM AMDGPU target, the host
offload plugin, the AMD device runtime, ROCm device libraries and ROCr.
The package names and flags here were checked against Gentoo ebuilds;
GPU execution was measured on Debian, not Gentoo.

For a coherent LLVM 20 setup, add these package USE settings:

```text
llvm-core/llvm llvm_targets_AMDGPU
llvm-core/clang llvm_targets_AMDGPU
llvm-runtimes/offload llvm_targets_AMDGPU
```

Then install matching LLVM components and device libraries:

```sh
sudo emerge --ask --changed-use \
  llvm-core/llvm:20 llvm-core/clang:20 llvm-core/lld:20 \
  '=llvm-runtimes/openmp-20*' '=llvm-runtimes/offload-20*' \
  '=dev-libs/rocm-device-libs-6.4.3*' dev-libs/rocr-runtime dev-util/rocminfo
```

Some ROCm packages are keyworded `~amd64`; review Portage's keyword and
dependency requirements before accepting changes. ROCm device libraries
6.4.3 use LLVM 20 to produce their bitcode. Keep the compiler, OpenMP and
offload runtime on the same LLVM major version. In LLVM 22 and later,
Gentoo packages the AMD device runtime separately as
`llvm-runtimes/openmp-amdgcn-amd-amdhsa`; install the matching version too,
with AMDGPU enabled for Clang, LLVM, LLD and the offload package.

Gentoo's device libraries install under `/usr/lib/amdgcn/bitcode`.
Select the LLVM binaries with, for example,
`export PATH="/usr/lib/llvm/20/bin:$PATH"`. Inspect installed file paths with
`qlist` from `app-portage/portage-utils`; library directories may be
`/usr/lib64` or `/usr/lib/llvm/20/lib64` according to the package layout.

Gentoo's regular GCC ebuild enables NVIDIA offload tooling but does not
configure an AMD offload compiler. GCC CPU OpenMP works with `openmp`;
AMD GPU execution needs a separately built matching GNU AMD offload
toolchain, or the Clang setup above. The Debian GCC package command does
not have a direct Gentoo equivalent in the inspected tree.

## Device access

Check device availability and permissions:

```sh
rocminfo
id
ls -l /dev/kfd /dev/dri/render*
```

Your account needs access to the compute and render devices, usually through
the `render` group. When your account is added to the group, you may need to
relogin.

## Selecting an installed backend

For an installed VOC, select the parallel C backend once in the shell or
in a setup file that you source before compiling. On Debian with Clang 19:

```sh
export CC=clang-19
```

Use `export CC=clang` with Gentoo's LLVM `bin` directory on `PATH`, or
`export CC=gcc` for GCC CPU OpenMP. Subsequent parallel builds use simply
`voc`. This setting applies to `-jP` and `-jG`; sequential builds use the
backend recorded when VOC was built. Recompile module objects when
switching backends or execution modes.

## Installing VOC with Clang

VOC records its default C backend when it is built. To make Clang the
default for sequential builds too, optionally install a Clang-based VOC
in `/opt/voc` from the VOC source directory:

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

For Gentoo, use `/usr/lib/llvm/20/bin` in place of `/usr/lib/llvm-19/bin`
and its `clang` executable. To configure GCC instead, build and install with
`make CC=gcc INSTALLDIR=/opt/voc` and
`sudo make CC=gcc INSTALLDIR=/opt/voc install`.

## Using CPU cores

With the backend selected once, compile and run the tutorial's program:

```sh
export CFLAGS='-O3 -fno-strict-aliasing'
export VOC_OPENMP_CFLAGS='-fopenmp'
export VOC_OPENMP_LDFLAGS='-fopenmp'
voc -sFmjP Vectors.Mod
OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE ./Vectors
```

GCC links libgomp; Clang links libomp. These are threads on one shared-memory
machine. Choose a thread count suitable for its physical cores.
For a temporary parallel backend change, use `CC=gcc-14 voc ...` or
`CC=clang-19 voc ...` on Debian, and `CC=gcc voc ...` or `CC=clang voc ...`
on Gentoo. Sequential `-j` builds use VOC's configured default backend.
Reset the two OpenMP flag variables as above when switching from GPU to CPU.

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

## Configuring Clang GPU offloading

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

On Gentoo with LLVM 20 and its package paths, use:

```sh
export CFLAGS='-O3 -fno-strict-aliasing'
export VOC_OPENMP_CFLAGS="-fopenmp -fopenmp-targets=amdgcn-amd-amdhsa --offload-arch=$GPU_ARCH --rocm-device-lib-path=/usr/lib/amdgcn/bitcode"
export VOC_OPENMP_LDFLAGS="$VOC_OPENMP_CFLAGS"
```

If shared libraries are not in the loader's normal search path, add the
installed LLVM runtime library directory to `LD_LIBRARY_PATH`, as in the
Debian example. Confirm both the AMD plugin and device runtime are installed
before trying an Oberon kernel.

Keep these variables in a setup file if you use the same GPU regularly.
Source that file before compiling GPU programs. Recompile device objects
when changing architectures.

## Configuring GCC GPU offloading

With a GCC-configured VOC and a matching GNU AMD offload toolchain, use:

```sh
export GPU_ARCH=gfx1036
export CFLAGS='-O0 -fno-strict-aliasing -ffp-contract=off'
export VOC_OPENMP_CFLAGS="-fopenmp -foffload=amdgcn-amdhsa -foffload-options=amdgcn-amdhsa=-march=$GPU_ARCH"
export VOC_OPENMP_LDFLAGS="$VOC_OPENMP_CFLAGS"
voc -sFmjG Vectors.Mod
OMP_TARGET_OFFLOAD=MANDATORY ./Vectors
```

`-O0` is intentional for the tested GCC 14 `gfx1036` configuration. It
establishes correctness, not competitive GPU performance. Do not substitute
`gfx1010` with that compiler: it rejects the architecture.

## Tested compatibility

These checks used Debian GCC 14.2.0 and Clang 19.1.7, with models 2 and C.
The GPU suites required actual device execution.

| Backend and execution mode | `ALL`, `SUM` and `PROD` |
| --- | --- |
| GCC 14, sequential and CPU OpenMP | Passed |
| Clang 19, sequential and CPU OpenMP | Passed |
| Clang 19 `-O3`, RX 5600 XT `gfx1010` | Passed |
| Clang 19 `-O3`, integrated Radeon `gfx1036` | Passed |
| GCC 14 `-O0`, integrated Radeon `gfx1036` | Passed |
| GCC 14 `-O3`, integrated Radeon `gfx1036` | `HSA_STATUS_ERROR_INVALID_ISA`, then hangs |
| GCC 14, RX 5600 XT `gfx1010` | Architecture unsupported by the offload compiler |

The optimized GCC failure occurred separately for `SUM`, `PROD` and `ALL`,
and in a standalone C numerical loop. Simple location and teams probes
passed at `-O3`, so a successful probe alone does not validate numerical
execution. These observations describe the tested versions and devices.

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

For reductions in a development checkout, also run the numerical suite:

```sh
make -C src/test/oberonv test-reductions-device \
  VOC="$(command -v voc)" VOCROOT="$VOCROOT" GPU_CC=clang-19 \
  GPU_CFLAGS='-O3 -fno-strict-aliasing -ffp-contract=off'
```

Use `GPU_CC=clang` for the Gentoo LLVM selection above. See the
[reduction measurements](GPUReductions.md) for timing commands and results.

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
