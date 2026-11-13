# CPU and GPU measurements

These measurements test VOC-generated independent array calculations and a
HALD CLUT image conversion. They distinguish correct device execution from
performance, and compare a sequential CPU implementation, CPU OpenMP, and
two actual AMD GPUs. Lower times are better.

## Tested system

Measurements were taken on 12–13 November 2026 using:

| Component | Configuration |
| --- | --- |
| CPU | AMD Ryzen 9 9950X, 16 physical cores, 32 logical CPUs |
| Integrated GPU | AMD Radeon in the Ryzen 9950X, `gfx1036`, 2 compute units, reported maximum clock 2200 MHz |
| Discrete GPU | AMD Radeon RX 5600 XT, `gfx1010`, 36 compute units, reported maximum clock 1780 MHz |
| Operating system | Debian 13, 64-bit Linux |
| VOC | Compiler/runtime built from `8786f6b2`; model 2, 64-bit addresses |
| CPU C compiler | GCC 14.2.0, Debian `14.2.0-19` |
| GPU C compiler | Clang 19.1.7, Debian `1:19.1.7-3+b1` |
| GPU runtime | LLVM OpenMP 19 and HSA runtime `6.1.2-3` |
| Device libraries | Debian `rocm-device-libs-17`, `6.0+git20231212.5a852ed-2` |

“1”, “4”, and “16” below describe CPU thread counts on this one processor,
not separate processor sockets. CPU OpenMP runs used `OMP_DYNAMIC=FALSE`,
`OMP_PLACES=cores`, `OMP_PROC_BIND=TRUE`, and `OMP_WAIT_POLICY=PASSIVE`, with
the thread limit matching the requested count. Sequential CPU runs used one
application thread.

Each GPU was selected explicitly. All GPU measurements used
`OMP_TARGET_OFFLOAD=MANDATORY`; `omp_is_initial_device()` independently
confirmed device execution. CPU fallback was never counted as GPU success.
The complete optimized device suite passed on both GPUs with Clang 19,
including numerical results, integer endpoints, rejected unsupported
constructs, and host-side bounds failures.

## Measurement method

The unit in every table is **milliseconds per conversion or array pass**.
The reported steady-state value is the median of five timed batches. The
driver calibrates a repetition count towards a 150 ms batch, with a bounded
number of repetitions. Slow calls use one repetition per sample. The first
call is recorded separately.

Timing uses the existing VOC wall-clock interface with microsecond
resolution. Array allocation, input initialization, result verification, and
image decoding/encoding are outside the timed interval. GPU mappings,
transfers, launch, execution, and synchronization are inside it. Inputs are
reused between passes. Caches and runtime initialization therefore affect
the relationship between first-call and steady-state performance.

Kernel and timing driver are compiled as separate modules, without link-time
optimization. Repeated passes cannot be merged into one calculation by
inlining the kernel into the timing loop. All output elements or image bytes
are checked. These measurements describe this implementation and machine;
they are not a general throughput guarantee.

## Numerical arrays: one CPU thread versus several

The arrays represent three `REAL` channels per pixel. This is floating-point
array data, not packed image bytes.

* **Simple:** `a[i] := b[i] * 0.5 + 0.25`.
* **16-stage:** start with `b[i]` and perform that affine operation 16 times
  in a private temporary, then store the result.

Inputs use the exact integer sequence `i MOD 256`. CPU flags were
`-O3 -march=native -fno-strict-aliasing -ffp-contract=off`. The sizes are
1920×1080×3 and 3840×2160×3 elements.

| Calculation | Size | Sequential CPU, 1 thread | CPU OpenMP, 4 threads | CPU OpenMP, 16 threads |
| --- | --- | ---: | ---: | ---: |
| Simple | 1080p | 0.797 | 0.591 | 0.044 |
| Simple | 4K | 5.598 | 5.502 | 5.088 |
| 16-stage | 1080p | 23.561 | 0.689 | 0.139 |
| 16-stage | 4K | 94.505 | 5.320 | 5.048 |

The large gains in some rows are not pure thread-count scaling. The generated
loop shapes permit different C compiler vectorization decisions, and the
reused data can fit differently across the processor's caches. The 4K rows
also show that adding threads need not improve a memory-limited calculation.

## Numerical arrays: optimized GPU comparison

GPU flags were `-O3 -fno-strict-aliasing -ffp-contract=off`, with the explicit
Clang AMD target and architecture flags shown in the
[GPU guide](GPUTutorial.md#preparing-an-amd-gpu-on-debian).

| Calculation | Size | CPU OpenMP, 16 threads | Integrated Radeon | RX 5600 XT |
| --- | --- | ---: | ---: | ---: |
| Simple | 1080p | 0.044 | 15.853 | 3.468 |
| Simple | 4K | 5.088 | 69.452 | 15.842 |
| 16-stage | 1080p | 0.139 | 16.184 | 3.504 |
| 16-stage | 4K | 5.048 | 68.517 | 15.842 |

The discrete GPU beats the sequential CPU on the 16-stage calculation by
about 6–7×. The multicore CPU remains faster than either GPU on these tests
when transfers are included. Simple numerical arrays therefore did not
establish a GPU advantage over the best tested CPU mode.

### Earlier unoptimized GPU runs

GCC 14 at `-O0 -fno-strict-aliasing -ffp-contract=off` correctly executed the
same direct VOC GPU subset on the integrated `gfx1036` device, but was much
slower:

| Calculation | Size | Integrated GPU, GCC `-O0` | Integrated GPU, Clang `-O3` |
| --- | --- | ---: | ---: |
| Simple | 1080p | 458.397 | 15.853 |
| Simple | 4K | 1842.300 | 69.452 |
| 16-stage | 1080p | 1675.769 | 16.184 |
| 16-stage | 4K | 6793.007 | 68.517 |

Optimized GCC 14 offloading failed with `HSA_STATUS_ERROR_INVALID_ISA` on
this integrated GPU. A standalone C numerical reproducer failed too; `-O0`
passed the full mandatory-device suite. Clang 19 supplied the working
optimized path. The precise GCC/runtime failure was not identified. These
observations should not be generalized to every GCC release or AMD device.

## HALD CLUT: a different workload

HALD applies a three-dimensional colour LUT with eight corner lookups and
integer trilinear interpolation for each RGB pixel. Every interpolation
stage retains the original rounding; source alpha is preserved. This is a
packed RGBA-byte workload with indirect reads, not the preceding floating-
point arithmetic test.

The numerical arrays use 12 bytes per pixel per array; HALD uses four.
The direct numerical backend preserves written arrays with `map(tofrom:)`,
whereas the HALD backend can use `map(from:)` for its completely written
output. Transfer volumes and mapping directions therefore differ. Compare
each workload with its own CPU reference rather than treating the difference
between the two GPU tables as a compiler-wide speedup.

Timing used the supplied Fujichrome Provia 100F LUT: 512×512 pixels, a cube
range of 64. The original photograph was 3264×2448, or 7,990,272 pixels. The
1080p and 4K inputs were resized copies. The source JPEG was decoded once to
RGBA and the identical bytes supplied to every implementation. The private
photograph and supplied LUT images are not bundled with these sources;
image content can affect lookup locality.

CPU flags were `-O3 -march=native -fno-strict-aliasing`. GPU flags were
Clang `-O3 -fno-strict-aliasing` with the matching AMD offload target. Image
files were read before timing and results written afterwards.

### Existing Oberon implementation: CPU scaling

This is `HaldClut.Mod` compiled normally, retaining its ordinary generated
checks and integer division handling.

| Input | Sequential CPU, 1 thread | CPU OpenMP, 4 threads | CPU OpenMP, 16 threads |
| --- | ---: | ---: | ---: |
| 1080p | 63.411 | 19.068 | 4.828 |
| 3264×2448 photo | 243.997 | 68.910 | 17.039 |
| 4K | 253.925 | 69.016 | 20.073 |

### Same streamlined kernel: CPU scaling

The library-specific backend retains host argument validation, uses a
canonical pixel loop, and removes redundant per-pixel checks. Its 21
divisions by 255 use ordinary C division, which is exact for these bounded,
nonnegative interpolation numerators. The GPU and this CPU control use the
same interpolation body. This prevents attributing all improvement to the
GPU when some comes from simplifying the generated code.

| Input | GCC CPU OpenMP, 1 thread | GCC CPU OpenMP, 4 threads | GCC CPU OpenMP, 16 threads |
| --- | ---: | ---: | ---: |
| 1080p | 40.682 | 10.250 | 3.031 |
| 3264×2448 photo | 155.445 | 39.370 | 11.046 |
| 4K | 161.121 | 43.284 | 12.030 |

The same CPU control was also measured with Clang 19:

| Input | Clang CPU OpenMP, 1 thread | Clang CPU OpenMP, 4 threads | Clang CPU OpenMP, 16 threads |
| --- | ---: | ---: | ---: |
| 1080p | 48.751 | 12.699 | 3.839 |
| 3264×2448 photo | 189.025 | 48.557 | 14.012 |
| 4K | 196.519 | 52.911 | 15.020 |

### HALD GPU comparison, including transfers

| Input | Existing CPU, 16 threads | Best same-kernel CPU, 16 threads | Integrated Radeon | RX 5600 XT | RX speedup over same-kernel CPU |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1080p | 4.828 | 3.031 | 23.983 | 1.597 | 1.90× |
| 3264×2448 photo | 17.039 | 11.046 | 97.281 | 4.978 | 2.22× |
| 4K | 20.073 | 12.030 | 96.779 | 5.175 | 2.32× |

GCC supplied the faster CPU control in these measurements. The RX 5600 XT
was about 3.0–3.9× faster than the existing 16-thread CPU implementation,
and 1.9–2.3× faster than the improved CPU control. The integrated GPU did
not improve on CPU OpenMP for HALD.

The first RX conversion, including first-use costs inside the call, took
3.333 ms at 1080p, 8.507 ms for the photograph, and 8.818 ms at 4K. These are
separate from the warmed medians above. The complete application also pays
for image decoding and encoding, so its total speedup will be smaller than
the conversion-only ratio.

## Correctness and scope

All six tested implementations matched an independent Python integer
reference for identity, inverted, and random LUTs at cube ranges 2, 3, 4, 16,
and 64. Tests included channel boundaries, random colours, non-opaque alpha,
and a one-pixel input. An empty raw image was rejected by the test driver's
array allocator before the kernel.

For the photograph, the sequential implementation, CPU OpenMP, both
streamlined CPU compiler controls, and both GPUs matched byte-for-byte
across all seven supplied LUTs: Astia 100, Astia 100F, Provia 100F, Sensia
400, Velvia 50, Kodak Ektar 25, and K64. The performance tables use Provia;
the other six photo LUTs were correctness checks.

HALD was tested through its explicit generated-C backend. These results do
not imply that the complete HALD module compiles through the generic `-jG`
subset. The package supplies the reproducible backend and keeps the
Oberon library interface unchanged.

## Reproducing the tests

Configure the compiler, architecture, visible GPU, and runtime paths using
the [GPU guide](GPUTutorial.md). Then run:

```sh
make -C src/examples/language/gpu run-gpu GPU_CC=clang-19
python3 src/examples/language/gpu/benchmark.py --gpu-cc clang-19 --label rx5600xt
make -C src/examples/utilities/hald all cpu-kernel gpu \
  CFLAGS='-O3 -march=native -fno-strict-aliasing' \
  KERNEL_CC=gcc-14 KERNEL_CFLAGS='-O3 -march=native -fno-strict-aliasing' \
  GPU_CC=clang-19
make -C src/examples/utilities/hald test test-cpu-kernel test-gpu-device GPU_CC=clang-19
python3 src/examples/utilities/hald/benchmark.py \
  --build build/examples/hald/2 --image photo.jpg --lut provia.png --gpu-cc clang-19
```

Set `--voc` and `--vocroot` for the numerical script, and `VOC`/`VOCROOT` for
the makefiles, when using a development image. The HALD benchmark needs
Pillow; correctness tests use only Python's standard library. Rebuild the
GPU objects after changing architectures. Use a fresh benchmark output
directory when retaining multiple runs. Detailed logs, generated objects,
and raw timing samples stay in local build directories.
