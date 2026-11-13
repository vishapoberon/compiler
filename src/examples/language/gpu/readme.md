# Independent arrays on the CPU and GPU

These examples use Oberon-V `ALL` statements. The same Oberon modules can be
compiled sequentially, with CPU OpenMP, or for an OpenMP target device.

Read [A gentle introduction to GPU programming](../../../../doc/GPUTutorial.md)
for the explanations and complete AMD/Clang setup.

## Programs

* `Vectors.Mod` fills and checks a fixed array.
* `GPUArrays.Mod` exports a scaling procedure for an open array, using a
  private temporary for each iteration.
* `UseGPU.Mod` imports that procedure and checks every result.
* `benchmark.py` generates larger, separately compiled numerical kernels
  and measures sequential, multicore, and GPU execution.

## Build and run

After building VOC, run from its source root:

```sh
make -C src/examples/language/gpu run-sequential
OMP_NUM_THREADS=4 make -C src/examples/language/gpu run-cpu
```

After configuring `VOC_OPENMP_CFLAGS`, `VOC_OPENMP_LDFLAGS`, and the runtime
library path for your GPU:

```sh
make -C src/examples/language/gpu run-gpu GPU_CC=clang-19
```

`run-gpu` first builds and runs the execution-location probe with mandatory
offloading. Both Oberon programs must then print their success message.

`test-fallback` explicitly disables offloading and checks the generated code
on the host. Use `run-gpu` to verify device execution.

Set `VOC`, `VOCROOT`, `VOCLIBDIR`, `MODEL`, or `BUILD` to use another matching
VOC installation or build directory. Keep each mode's generated files
separate. `GPU_CC` and `GPU_CFLAGS` select the offload compiler and its
optimization settings; the tested optimized AMD configuration uses Clang 19.

## Benchmark

```sh
python3 src/examples/language/gpu/benchmark.py --cpu-only
python3 src/examples/language/gpu/benchmark.py --gpu-cc clang-19 --label rx5600xt
```

The first command measures one sequential thread and 4/16 OpenMP threads.
The second also verifies actual GPU execution and includes transfers in the
GPU measurements. `--quick` uses small arrays for a short correctness and
build check. Other options select the VOC installation, output directory,
compilers, flags, or CPU thread counts. CPU `-march=native` is a benchmark
setting for the current machine. Supply it explicitly when repeating those
CPU measurements.

The workloads contain 1080p- and 4K-sized arrays of three floating-point
channels per pixel. The first applies `x * 0.5 + 0.25`; the second performs
16 such stages per channel. Five warmed batches are measured, every output
is checked, and the first call is reported separately. Compiling the kernel
and timing driver as separate modules prevents repeated passes from being
merged into one calculation. No link-time optimization is requested.

See the [published measurements](../../../../doc/ParallelBenchmarks.md) for
the tested AMD devices and the separate HALD workload.
