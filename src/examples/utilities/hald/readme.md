# Applying a HALD colour lookup table

`HaldCmd` loads a JPEG or PNG photograph and a HALD PNG, applies the LUT, and
writes a PNG. The reusable calculation is the
[`HaldClut` library](../../../ports/norayr/hald-clut/readme.md). PNG and JPEG
decoding use the bundled Oberon codecs.

## Sequential and multicore builds

From the VOC source root, after building the compiler:

```sh
make -C src/examples/utilities/hald
./build/examples/hald/2/sequential/HaldCmd photo.jpg lut.png result.png
OMP_NUM_THREADS=4 ./build/examples/hald/2/cpu/HaldCmd photo.jpg lut.png result-cpu.png
```

Use `LD_LIBRARY_PATH="$PWD/install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"`
if the local VOC runtime is not on the system library search path.

The arguments are:

```text
HaldCmd input.jpg|png lut.png output.png|- [repetitions]
```

The optional repetition count is 1..1000. Each timed conversion starts from
the unchanged source. `-` skips output encoding, for example:

```sh
OMP_NUM_THREADS=16 ./build/examples/hald/2/cpu/HaldCmd photo.jpg lut.png - 10
```

The command warms the conversion once before reporting conversion times.
Reading, decoding, and writing files are outside those timings.

## GPU build and use

Follow the [GPU setup guide](../../../../doc/GPUSetup.md).
For the tested RX 5600 XT, the essential settings are:

```sh
export GPU_ARCH=gfx1010
export ROCR_VISIBLE_DEVICES=0
export OMP_DEFAULT_DEVICE=0
export VOC_OPENMP_CFLAGS="-fopenmp -fopenmp-targets=amdgcn-amd-amdhsa --offload-arch=$GPU_ARCH --rocm-device-lib-path=/usr/lib/llvm-17/lib/clang/17/amdgcn/bitcode"
export VOC_OPENMP_LDFLAGS="$VOC_OPENMP_CFLAGS"
export LD_LIBRARY_PATH="$PWD/install/lib:/usr/lib/llvm-19/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
make -C src/examples/utilities/hald gpu GPU_CC=clang-19
make -C src/examples/utilities/hald test-gpu-device GPU_CC=clang-19
OMP_TARGET_OFFLOAD=MANDATORY ./build/examples/hald/2/gpu/HaldCmd photo.jpg lut.png result-gpu.png
```

GPU numbering depends on the machine. The test machine's integrated Radeon
was selected with `ROCR_VISIBLE_DEVICES=1` and `GPU_ARCH=gfx1036`. Confirm your
device with `rocminfo`, and rebuild the GPU objects after changing targets.

`OMP_TARGET_OFFLOAD=MANDATORY` requires offloading. The device test also checks
the execution location, so CPU fallback cannot count as GPU success.
Clang 19 is the tested optimized offload compiler on these AMD cards. GCC 14
failed with `INVALID_ISA` on the integrated card at optimization levels above
`-O0`, including in standalone C.

## Tests

```sh
make -C src/examples/utilities/hald test
make -C src/examples/utilities/hald test-cpu-kernel
make -C src/examples/utilities/hald test-gpu-device GPU_CC=clang-19
```

The tests cover cube ranges 2, 3, 4, 16, and 64, identity/inverted/random LUTs,
boundary and random colours, and alpha preservation. Output pixels are
compared with a Python integer reference. `test-gpu` is an explicitly
host-fallback correctness test when no GPU is available.

## Repeating the measurements

Build the same-kernel CPU control as well as the other applications:

```sh
make -C src/examples/utilities/hald all cpu-kernel gpu \
  CFLAGS='-O3 -march=native -fno-strict-aliasing' \
  KERNEL_CC=gcc-14 KERNEL_CFLAGS='-O3 -march=native -fno-strict-aliasing' \
  GPU_CC=clang-19
python3 src/examples/utilities/hald/benchmark.py \
  --build build/examples/hald/2 --image photo.jpg --lut lut.png --gpu-cc clang-19
```

This benchmark additionally needs Pillow (`python3-pil` on Debian). It decodes
each input once and supplies identical raw RGBA bytes to every implementation.
`HaldBench.Mod` measures just `HaldClut.Apply`, including GPU mappings and
transfers, with a microsecond timer. Allocation, image decoding, output
writing, and correctness checks are outside the measured interval.

The script tests native size, 1080p, and 4K, with 1, 4, and 16 CPU threads.
It reports the first call separately, calibrates repeated calls, takes five
timed batches, and records their median. Every final output is checked
against the original sequential Oberon implementation. Local logs and JSON
results go under the build directory.

For a CPU-only run, use `--modes sequential cpu cpu-kernel`. For another CPU
compiler control, rebuild `cpu-kernel` with `KERNEL_CC=clang-19` and repeat.
The [published tables](../../../../doc/ParallelBenchmarks.md) explain the
hardware, compiler settings, and interpretation of the original measurements.

## Build settings

`VOC`, `VOCROOT`, `VOCLIBDIR`, `MODEL`, and `BUILD` select the matching compiler,
runtime, and output directory. `CFLAGS` controls the ordinary builds;
`GPU_CC`/`GPU_CFLAGS` control the GPU; `KERNEL_CC`/`KERNEL_CFLAGS` control the
same-kernel CPU build. The default `all` target builds only sequential and
CPU versions. GPU builds are explicit and need Python 3 plus a configured
OpenMP offload toolchain.
