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
coordinate in the LUT, followed by green and blue. Supply decoded pixel
arrays, rather than PNG or JPEG file contents.

The source length must be divisible by four, the LUT must contain exactly
`range * range * range` pixels, and the target must have room for all source
bytes. The GPU and `cpu-kernel` implementations require disjoint source,
LUT, and target storage; overlap is rejected on the calling thread. An
oversized target's unused tail is preserved.

The calculation uses trilinear interpolation. Each interpolation step rounds
with `(a * (255-f) + b * f + 127) DIV 255`. The source alpha byte is copied
unchanged; LUT alpha bytes are ignored. No floating-point approximation is
used.

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
execution. `test-gpu` instead selects explicit host fallback for machines
without an offload device; it checks correctness, not GPU execution.

## How the GPU backend works

`HaldClut.Mod` remains the canonical algorithm. `kernel.py` asks VOC to
translate it with `-sFjPSx`, then builds a synchronous OpenMP target loop with
explicit mappings for the source, LUT, coordinate table, and output. The
result is compiled into `HaldClut.o` with the configured GPU C compiler.
Generated files stay in the build directory.

The original host-side size and cube assertions are retained. Translation
uses `-x` for this fixed algorithm: the host table is filled at indices
0..255, and the kernel indices follow from the validated dimensions and
byte-valued inputs. With fractions in 0..255, each interpolation numerator is nonnegative
and at most 65152, including the rounding term. C division by the positive
constant 255 therefore has exactly the required Oberon result. The backend
replaces those 21 divisions inside the validated kernel. It maps the complete
output with `map(from:)`
because every output byte is written.

The backend checks the Oberon source fingerprint and expected generated-code
structure. A changed source or unexpected compiler output stops the build
and requires review. It is specific to this library: the general `-jG`
backend still accepts a smaller numerical-array subset. No manual edits of
generated C are required.

`cpu-kernel` builds the same streamlined calculation as a CPU OpenMP loop:

```sh
make -C src/examples/utilities/hald cpu-kernel test-cpu-kernel
```

This provides a control when comparing GPU performance, so a speedup cannot
be attributed only to simplifying the generated kernel.

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
