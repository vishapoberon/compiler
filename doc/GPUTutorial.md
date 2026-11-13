# A gentle introduction to GPU programming with VOC

## Contents

1. [Background](#background)
2. [An independent calculation](#an-independent-calculation)
3. [Running it on the CPU](#running-it-on-the-cpu)
4. [What changes on a GPU](#what-changes-on-a-gpu)
5. [Preparing an AMD GPU on Debian](#preparing-an-amd-gpu-on-debian)
6. [Our first GPU run](#our-first-gpu-run)
7. [Using a separate module](#using-a-separate-module)
8. [Private working variables](#private-working-variables)
9. [Choosing a suitable calculation](#choosing-a-suitable-calculation)
10. [A complete image-processing application](#a-complete-image-processing-application)
11. [Measuring performance](#measuring-performance)
12. [When a program will not offload](#when-a-program-will-not-offload)

## Background

This introduction is for a reader who can write a small Oberon program and
would like some calculations to run on a GPU. We shall start with one array,
compile the same calculation for the CPU and GPU, and then use it through a
separately compiled module. Finally, we shall build an image-processing
application and measure its conversion time.

VOC translates Oberon to C. For GPU execution it emits OpenMP target
directives, which the selected C compiler translates into host and device
code. The host is the CPU running the application; the device is the GPU
chosen for offloading. An offload runtime copies the required data and
launches the device calculation.

The examples use VOC's experimental Oberon-V `ALL` statement. The tested GPU
setup is 64-bit Debian Linux with Clang 19 and AMD graphics. Other toolchains
need their own compatible offload targets, runtimes, and drivers.

Build VOC first, or use a matching installed compiler and runtime. Commands
below start in the VOC source root. You can select the local installation:

```sh
export VOCROOT="$PWD/install"
export VOC="$VOCROOT/bin/voc"
export LD_LIBRARY_PATH="$VOCROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

For a small native model-2 development image on 64-bit Linux, there is also:

```sh
python3 src/test/oberonv/build-native.py
export VOCROOT="$PWD/build/oberonv-native/image"
export VOC="$VOCROOT/bin/voc"
export LD_LIBRARY_PATH="$VOCROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

The native helper is a development builder. It supplies the compiler and core
runtime; examples compile their additional library modules when needed.

## An independent calculation

Suppose we want to fill an array with twice its index. Save this as
`Vectors.Mod` in an empty working directory:

```oberon
MODULE Vectors;
IMPORT Out;
VAR values: ARRAY 16 OF REAL; i: LONGINT;
BEGIN
  ALL r = 0 .. LEN(values)-1 DO values[r] := r * 2 END;
  FOR i := 0 TO LEN(values)-1 DO ASSERT(values[i] = i * 2) END;
  Out.String("vector results passed"); Out.Ln
END Vectors.
```

The two bounds are inclusive. `r` is a read-only identifier belonging to the
`ALL` body. For each value of `r`, the calculation writes a different array
element. No iteration needs a value produced by another iteration. That is
what makes this calculation independent.

Both bounds are evaluated once before the assignments, lower bound first.
If the lower bound is greater than the upper bound, the body does no work.
Assignments within an iteration keep their source order. The order between
iterations is unspecified.

For comparison, `a[r] := a[r-1]` generally reads a value another iteration
writes. It is not an independent `ALL` calculation. A shared accumulator
such as `sum := sum + a[r]` is not an `ALL` reduction either. The programmer
must ensure independence, including through aliased parameters and pointers.

## Running it on the CPU

Compile and run the first program sequentially:

```sh
"$VOC" -O2 -sFmj Vectors.Mod
./Vectors
```

Here `-O2` selects VOC type model 2. It is not the C optimization setting.
`-m` builds a main program, and `-j` enables the Oberon-V syntax. `-sF`
permits creation and replacement of symbol files in this working directory.

The expected output is:

```text
vector results passed
```

Now ask for CPU OpenMP execution:

```sh
CC=gcc CFLAGS='-O3 -fno-strict-aliasing' \
  VOC_OPENMP_CFLAGS=-fopenmp VOC_OPENMP_LDFLAGS=-fopenmp \
  "$VOC" -O2 -sFmjP Vectors.Mod
OMP_NUM_THREADS=4 ./Vectors
```

`-P` selects the CPU OpenMP backend. `OMP_NUM_THREADS` requests the number of
CPU threads. The success message should be unchanged. This tiny program is
for learning and checking results; its array is too small to establish a
useful performance comparison.

VOC options toggle their settings. Apply `-jP` or `-jG` once in a command;
`-P` and `-G` are mutually exclusive and require `-j`. Options before the
filenames are global; following a filename they apply to that file. Keep
generated files for different modes in separate directories.

## What changes on a GPU

For GPU execution the computation still reads and writes the same Oberon
array. VOC arranges a synchronous target region around the assignments.
The generated OpenMP mapping describes which arrays the device needs.
Scalar values such as a scale factor are copied by value. The call returns
after the calculation and required transfers have completed.

There are two costs to consider: doing the calculation, and making its data
available to the GPU. A small calculation may finish on the CPU before the
GPU has received its input. Repeated transfers can also dominate large
calculations. Correct offloading and faster execution are separate questions.

## Preparing an AMD GPU on Debian

The tested setup used Debian 13, Clang 19.1.7, LLVM OpenMP, and the Debian
ROCm device libraries. On that system the relevant packages are:

```sh
sudo apt install clang-19 clang-tools-19 lld-19 libomp-19-dev \
  rocm-device-libs-17 libhsa-runtime-dev rocminfo
```

`clang-tools-19` supplies the offload packager and linker wrapper. The OpenMP
package supplies the host runtime and AMD device runtime. The ROCm package
supplies device-side bitcode. `libhsa-runtime-dev` supplies the unversioned
HSA library name that Clang's runtime loads. Package names and paths can
change between distributions.

Confirm that the operating system exposes the GPU:

```sh
rocminfo
id
ls -l /dev/kfd /dev/dri/render*
```

Your account needs access to the compute and render devices, usually through
the `render` group. An administrator may need to grant that access, followed
by a fresh login. Compiler flags cannot fix missing device permissions.

The tested machine has two AMD GPUs. Their tested settings were:

| GPU | Architecture | ROCr device index on that machine |
| --- | --- | --- |
| Radeon RX 5600 XT | `gfx1010` | `0` |
| Ryzen 9 9950X integrated Radeon | `gfx1036` | `1` |

Choose the architecture and device reported on your own machine. For the
RX 5600 XT example:

```sh
export GPU_ARCH=gfx1010
export ROCR_VISIBLE_DEVICES=0
export OMP_DEFAULT_DEVICE=0
export VOC_OPENMP_CFLAGS="-fopenmp -fopenmp-targets=amdgcn-amd-amdhsa --offload-arch=$GPU_ARCH --rocm-device-lib-path=/usr/lib/llvm-17/lib/clang/17/amdgcn/bitcode"
export VOC_OPENMP_LDFLAGS="$VOC_OPENMP_CFLAGS"
export LD_LIBRARY_PATH="$VOCROOT/lib:/usr/lib/llvm-19/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

`ROCR_VISIBLE_DEVICES` filters the devices visible to the AMD runtime.
`OMP_DEFAULT_DEVICE=0` chooses the first device after filtering. The C flags
choose the matching device architecture; the link flags must retain the
offload settings so that the device image and runtimes are linked too.

The tested device bitcode is installed under LLVM 17's directory even though
the selected compiler is Clang 19. Check the actual package paths instead of
assuming that those two version numbers match.

The tests initially used the installed versioned HSA runtime through a
private link, rather than installing its development package. If that is
your setup, the corresponding alternative is:

```sh
mkdir -p "$HOME/voc-openmp-libs"
ln -s /usr/lib/x86_64-linux-gnu/libhsa-runtime64.so.1 "$HOME/voc-openmp-libs/libhsa-runtime64.so"
export LD_LIBRARY_PATH="$HOME/voc-openmp-libs:$LD_LIBRARY_PATH"
```

Use this only when the target library exists and the new link does not
already exist. It changes a private directory, not the system installation.

## Our first GPU run

Compile `Vectors.Mod` with the selected offload compiler:

```sh
CC=clang-19 CFLAGS='-O3 -fno-strict-aliasing' \
  "$VOC" -O2 -sFmjG Vectors.Mod
OMP_TARGET_OFFLOAD=MANDATORY ./Vectors
```

The same result check should pass. `-G` selects VOC's GPU backend.
`OMP_TARGET_OFFLOAD=MANDATORY` requires offloading rather than accepting host
fallback when a device cannot be used.

We should also verify the execution location. The bundled examples do that:

```sh
make -C src/examples/language/gpu run-gpu \
  VOC="$VOC" VOCROOT="$VOCROOT" GPU_CC=clang-19
```

The test-only C probe calls OpenMP's `omp_is_initial_device()` inside a target
region. It must report device execution before the Oberon examples run. A
host-fallback test is useful for checking generated code, but does not prove
GPU execution.

## Using a separate module

A library can own the independent calculation while a main module owns the
data. `GPUArrays.Mod` exports a procedure operating on an open array:

```oberon
MODULE GPUArrays;
PROCEDURE Scale*(VAR values: ARRAY OF REAL; factor: REAL);
BEGIN
  ALL i = 0 .. LEN(values)-1 WITH t: REAL DO
    t := values[i] * factor;
    values[i] := t
  END
END Scale;
END GPUArrays.
```

The importing application initializes the array and checks the result:

```oberon
MODULE UseGPU;
IMPORT GPUArrays, Out;
VAR values: ARRAY 1024 OF REAL; i: LONGINT;
BEGIN
  FOR i := 0 TO LEN(values)-1 DO values[i] := i END;
  GPUArrays.Scale(values, 2);
  FOR i := 0 TO LEN(values)-1 DO ASSERT(values[i] = i * 2) END;
  Out.String("array results passed"); Out.Ln
END UseGPU.
```

Compile the library before the application, in a fresh directory containing
these two sources:

```sh
CC=clang-19 CFLAGS='-O3 -fno-strict-aliasing' \
  "$VOC" -O2 -sFjcG GPUArrays.Mod
CC=clang-19 CFLAGS='-O3 -fno-strict-aliasing' \
  "$VOC" -O2 -sFmjG UseGPU.Mod
OMP_TARGET_OFFLOAD=MANDATORY ./UseGPU
```

`-c` compiles the library without linking an application. Keep its `.sym`,
`.h`, and `.o` files together until the importer is built. The symbol file
describes the Oberon interface; the object contains the selected
implementation. Link the application with the same offload compiler,
runtime, target flags, and type model.

## Private working variables

In `Scale`, each iteration has its own `t`. `WITH t: REAL` declares that
temporary; it does not introduce shared storage. The compiler checks that
an iteration-local variable is assigned before it is read.

A procedure-level variable assigned by every iteration would instead be
shared storage. Merely moving a declaration outside `WITH` does not preserve
the same parallel meaning. Use the private declarations for intermediate
values belonging to one element.

## Choosing a suitable calculation

The direct `-jG` backend currently supports one-dimensional numerical arrays,
scalar value captures, and private scalar temporaries. Array accesses must
use the range identifier, a suitable widening conversion of it, or a
nonnegative constant index. One open-array argument can be mapped. Checked
index bounds are validated on the calling thread before launching the
device work.

Records, multidimensional arrays, heap designators, indirect LUT indices,
potentially aliased array arguments, runtime-dependent operations, and
procedure calls are outside this direct subset. The assignment sequence
does not contain arbitrary control flow. Constructs requiring runtime
helpers in the kernel are diagnosed rather than silently offloaded.

For example, `values[i] := values[i] * factor` fits the subset. A complete
HALD interpolation uses indirect indices and record-based coordinate tables;
it needs the library-specific backend described below. Disabling index
checks does not automatically make unsupported GPU constructs acceptable.

## A complete image-processing application

The [HALD example](../src/examples/utilities/hald/readme.md) loads an image,
applies a three-dimensional colour LUT, and writes a PNG. It uses an Oberon
library with a dedicated, checked OpenMP build backend. Its integer
interpolation preserves the existing rounding and source alpha exactly.

With the GPU environment already set:

```sh
make -C src/examples/utilities/hald gpu test-gpu-device \
  VOC="$VOC" VOCROOT="$VOCROOT" GPU_CC=clang-19
OMP_TARGET_OFFLOAD=MANDATORY \
  ./build/examples/hald/2/gpu/HaldCmd photo.jpg lut.png result.png
```

The build translates the canonical Oberon module, checks the expected source
and generated structure, and compiles the library's target kernel. It does
not require editing generated C by hand. Importing applications still call
the ordinary `HaldClut.Apply` interface. The generic `-jG` subset and this
library-specific backend are separate capabilities.

## Measuring performance

Measure correctness first, then compare the calculation with an optimized
CPU implementation. State whether device transfers, allocation, file I/O,
and first-use initialization are included. Reuse the same input and check
all output values. Measure several batches rather than one tiny call.

The bundled numerical benchmark is:

```sh
python3 src/examples/language/gpu/benchmark.py \
  --voc "$VOC" --vocroot "$VOCROOT" --gpu-cc clang-19 --label rx5600xt
```

The HALD example has a separate benchmark which decodes inputs once and times
the conversion. Its CPU control uses the same streamlined kernel, so a
speedup cannot be explained merely by removing redundant runtime checks.

The [published CPU/GPU measurements](ParallelBenchmarks.md) show why this
matters. Simple numerical array operations were fastest on the multicore
CPU. HALD on the RX 5600 XT was faster than both the existing CPU version
and the improved 16-thread CPU control, including transfers. A result for
one workload is not a general GPU speedup guarantee.

## When a program will not offload

* **Missing `clang-offload-packager`:** install the matching Clang tools
  package, not only the compiler driver.
* **Missing ROCm device libraries:** check `--rocm-device-lib-path` and the
  installed bitcode files for the target architecture.
* **Missing `libomptarget.so.19.1`:** include LLVM's library directory in the
  runtime search path.
* **Mandatory-offload failure before a kernel runs:** check the HSA library
  name, device permissions, visible-device selection, architecture, and
  runtime. A successful compilation is not proof that a usable GPU exists.
* **`INVALID_ISA` with GCC 14 on `gfx1036`:** this was reproduced in optimized
  standalone C as well as VOC output. GCC `-O0` passed, while Clang 19
  passed the complete optimized suite. This is a tested-toolchain result,
  not a hardware-independent VOC default.
* **VOC rejects a GPU expression:** keep the first program within the direct
  subset, or use a library with an explicit supported device backend.

For diagnosis, rerun the small execution-location probe before a large
application. `LIBOMPTARGET_INFO=63` can show Clang runtime mappings and kernel
launches; unset diagnostic output before benchmarking.
