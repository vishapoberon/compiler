# HALD CLUT library

`HaldClut` applies a three-dimensional colour lookup table to an RGBA image.
Its Oberon implementation supports sequential and CPU OpenMP builds. The
GPU build uses the same Oberon source with the package's checked OpenMP C
backend. The caller imports the same module in every build.

The library is separate from image decoding and encoding. A command-line
application, tests, and benchmarks are in
[`src/examples/utilities/hald`](../../../examples/utilities/hald/readme.md).

## Interface

```oberon
IMPORT HaldClut;

range := HaldClut.CubeRange(lutWidth, lutHeight);
ASSERT(range > 0);
HaldClut.Apply(source^, lut^, range, target^)
```

`CubeRange(width, height)` returns the cube side whose cube equals the image's
pixel count, or zero for an invalid size. A 512 by 512 HALD image contains a
64 by 64 by 64 colour cube, so its range is 64.

`Apply(source, lut, range, target)` takes flat arrays of `CHAR`, with four
bytes per pixel in red, green, blue, alpha order. Red is the fastest-changing
coordinate in the LUT, followed by green and blue. Supply decoded RGBA pixel
arrays.

The source length must be divisible by four, the LUT must contain exactly
`range * range * range` pixels, and the target must have room for all source
bytes. The GPU and `cpu-kernel` implementations require disjoint source,
LUT, and target storage; overlap is rejected on the calling thread. An
oversized target's unused tail is preserved.

The calculation uses trilinear interpolation. Each interpolation step rounds
with `(a * (255-f) + b * f + 127) DIV 255`. The source alpha byte is copied
unchanged; LUT alpha bytes are ignored. All interpolation arithmetic uses
integers.

## Building

Build VOC, then run from its source root:

```sh
make -C src/examples/utilities/hald
make -C src/examples/utilities/hald test
```

The first command builds separate sequential and CPU OpenMP applications.
Set `VOC`, `VOCROOT`, `MODEL`, and `BUILD` to select another matching compiler
and runtime. The examples use model 2 by default.

For the GPU, first configure a working offload compiler and runtime as in
[A gentle introduction to GPU programming](../../../../doc/GPUTutorial.md).
Then:

```sh
make -C src/examples/utilities/hald gpu GPU_CC=clang-19
make -C src/examples/utilities/hald test-gpu-device GPU_CC=clang-19
```

The device test checks `omp_is_initial_device()` and requires actual device
execution. `test-gpu` selects explicit host fallback and checks correctness
on the CPU.

## How the GPU backend works

Use the make targets above for building and testing. They run the required
tools automatically.

`HaldClut.Mod` defines the interpolation algorithm. HALD uses indirect LUT
indices and a coordinate table, which need a library-specific GPU backend.
The makefile runs `kernel.py` to translate the module with VOC, adapt its
generated loop for OpenMP target execution and compile `HaldClut.o`.
Python 3 is a build-time requirement for this step.

The helper preserves the size and cube assertions, checks the source
fingerprint and expected generated structure, and stops on unexpected
changes. Its integer interpolation gives the same rounding as the Oberon
implementation. The source, LUT and coordinate table are supplied to the
GPU; the completely written output is copied back when the call finishes.
Generated files stay in the build directory.

The direct `-jG` backend supports the numerical-array subset described in
the GPU guide. Incorporating HALD's indirect lookups into that backend
would allow VOC to handle this build step directly.

`cpu-kernel` builds the same streamlined calculation as a CPU OpenMP loop:

```sh
make -C src/examples/utilities/hald cpu-kernel test-cpu-kernel
```

This provides a control for comparing CPU and GPU execution of the same
streamlined kernel.

For another application, keep `HaldClut.sym`, `HaldClut.h`, and `HaldClut.o`
from the selected build together. Compile importing modules in that build
directory, using the same type model, and link GPU applications with `-jG`,
the same C compiler, and the same `VOC_OPENMP_CFLAGS`/`VOC_OPENMP_LDFLAGS`.
The calling convention is the normal VOC module interface.

## Results and source provenance

The RX 5600 XT and the Ryzen 9950X integrated GPU passed the synthetic and
seven-LUT photo checks. The published
[CPU and GPU measurements](../../../../doc/ParallelBenchmarks.md) include
transfer time and the same-kernel CPU control.

The original Oberon module comes from
[voc-hald-clut](https://github.com/norayr/voc-hald-clut). `PORT.toml` and the
hash manifests record the upstream revision and VOC-specific additions.
