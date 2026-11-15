# Measuring SUM and PROD on AMD GPUs

This benchmark compares one-dimensional `SUM` and `PROD` on a CPU and two
AMD GPUs. It requires development sources after VOC 5.0. The
[setup guide](GPUSetup.md) explains the Debian and Gentoo toolchains; the
[reduction introduction](Reductions.md) explains the Oberon syntax.

The RX 5600 XT improved the large `LONGREAL PROD` by **1.29–1.30× over
sequential CPU execution**, including transfers. It did not beat the
16-thread CPU on any tested reduction. The integrated GPU was slower than
the sequential CPU throughout.

## System and method

Measurements on 15 November 2026 used Debian 13, a Ryzen 9 9950X with
16 physical cores, a Radeon RX 5600 XT (`gfx1010`, 36 compute units), and
the processor's integrated Radeon (`gfx1036`, 2 compute units). VOC used
model 2 and the counted-loop CPU improvements described in
[CPU scaling](CPUScaling.md#checking-automatic-vectorization).

Sequential builds used VOC's configured GCC 14.2.0 backend. CPU OpenMP
was measured with both GCC 14.2.0 and Clang 19.1.7 at one, four and sixteen
threads. GPU builds used Clang 19.1.7, LLVM OpenMP 19, HSA runtime
6.1.2-3 and Debian's `rocm-device-libs-17`. All compilations used
`-O3 -march=native -fno-strict-aliasing -ffp-contract=off -fno-lto`, plus
the execution mode's OpenMP flags. `-march=native` selects the host CPU;
the GPU architecture is set separately with `--offload-arch`.

Each input contains either 1,048,576 or 8,388,608 eight-byte elements
(8 or 64 MiB). Integer reductions use `SYSTEM.INT64`; floating-point
reductions use `LONGREAL`. Inputs are identical across execution modes:

* Integer `SUM`: `i MOD 17 - 8`.
* `LONGREAL SUM`: `(i MOD 16) / 16.0D0`.
* Integer and `LONGREAL PROD`: the repeating sequence `1, 1, -1`.

The product factors keep every intermediate result at unit magnitude,
independently of GPU scheduling or reduction regrouping. This avoids
intermediate floating-point overflow and underflow. It differs from the
alternating `2, 0.5` real-product input in the earlier Intel CPU benchmark.
All results are exact for these inputs. Each run checks the reduction result
and every input element after the first call, calibration and timed batches.

The timing driver and reduction kernel are separate Oberon modules,
compiled and linked by VOC without link-time optimization. Each measurement
is the median of five calibrated batches, targeting 150 ms per batch with
at most 4096 repetitions. Two complete rounds reverse the order of the GCC
CPU, discrete-GPU and integrated-GPU runs; execution modes within each run
are deterministically shuffled. CPU workers are bound to cores with
`OMP_DYNAMIC=FALSE`, `OMP_PROC_BIND=TRUE`, `OMP_PLACES=cores` and
`OMP_WAIT_POLICY=PASSIVE`. Active CPU workers are checked through `/proc`.

GPU runs require `OMP_TARGET_OFFLOAD=MANDATORY`, and an independent
`omp_is_initial_device()` probe verifies device execution. Timing includes
mapping, input transfers, launch, reduction, result transfer and completion
of each call. Input initialization and correctness checks are outside the
timed interval. Each call maps its input array; these are host-to-host
end-to-end reduction times, rather than timings with inputs permanently
resident on the GPU. First-call time is recorded separately from steady
state and excludes executable startup and module initialization.

## Results

Times are **milliseconds per complete reduction**. Ranges span the medians
of the two rounds. The sequential column uses the separate GCC CPU control
from each round; Clang's one-thread and sixteen-thread OpenMP controls were
also measured. Speedups are calculated within each round before taking
their range. A ratio below one means the GPU is slower.

| Reduction | Elements | Sequential GCC | GCC, 16 threads | Clang, 16 threads | RX 5600 XT | Integrated Radeon | RX speedup over sequential |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Integer `SUM` | 1,048,576 | 0.055–0.056 | 0.016–0.018 | 0.021–0.022 | 0.622–0.653 | 2.349–2.442 | 0.08–0.09× |
| Integer `SUM` | 8,388,608 | 0.838–0.883 | 0.061–0.064 | 0.065–0.071 | 3.507–3.533 | 20.038–20.045 | 0.24–0.25× |
| `LONGREAL SUM` | 1,048,576 | 0.389–0.402 | 0.042–0.043 | 0.047–0.049 | 0.652–0.661 | 2.636–2.699 | 0.59–0.62× |
| `LONGREAL SUM` | 8,388,608 | 3.097–3.152 | 0.227–0.237 | 0.268–0.273 | 3.596–3.671 | 23.871 | 0.86× |
| Integer `PROD` | 1,048,576 | 0.077 | 0.018–0.019 | 0.022 | 0.646–0.659 | 2.682–2.733 | 0.12× |
| Integer `PROD` | 8,388,608 | 0.838–0.887 | 0.068–0.069 | 0.068–0.071 | 3.546–3.638 | 23.167–23.356 | 0.23–0.25× |
| `LONGREAL PROD` | 1,048,576 | 0.577–0.584 | 0.052–0.056 | 0.060–0.061 | 0.652–0.655 | 2.510–3.040 | 0.89× |
| `LONGREAL PROD` | 8,388,608 | 4.696–4.802 | 0.335–0.374 | 0.336–0.338 | 3.648–3.691 | 23.397–23.938 | **1.29–1.30×** |

For the large real product, the RX achieves only 0.09–0.10× the throughput
of the GCC sixteen-thread control: it takes 9.9–10.9 times as long.
Across all rows it takes 9.9–57.9 times as long as that control. The
sixteen-thread GCC reductions improve over their sequential baseline by
3.05–14.01× across the tested sizes and operations.

The first GPU call took 1.616–7.167 ms on the RX 5600 XT and
27.811–50.349 ms on the integrated Radeon, across both sizes and all four
reductions. These first-call ranges are separate from the warmed table.
The largest maximum-to-minimum sample ratio among all 224 full measurement
records was 1.23×.

Both GPU and CPU results passed all checks in the 224 full configurations.
Performance measurements use model 2; the separate device correctness and
short benchmark checks also cover model C.

The arrays are reused across calls, and their 8–64 MiB working sets can
benefit from CPU caches. Each GPU call still supplies its input through an
OpenMP mapping. Consequently, these results favour CPU execution for simple
reductions whose inputs begin on the host. They do not establish the cost
of a reduction embedded in a larger calculation with GPU-resident inputs.
Measure that complete calculation separately when choosing an execution mode.

## Reproducing the measurements

Configure Clang, the visible device and both `VOC_OPENMP_*FLAGS` variables
using the [setup guide](GPUSetup.md). From a development source checkout:

```sh
make -C src/test/oberonv benchmark-gpu GPU_CC=clang-19 \
  GPU_BENCH_ARGS='--threads 1 4 16 --label rx5600xt'
```

Use `GPU_CC=clang` with the Gentoo LLVM selection. Add `VOC` and `VOCROOT`
to select an installed development image. The runner calls VOC for the
Oberon modules and uses the selected C compiler directly only for the
independent device-location probe. GPU mode selects the four reduction
workloads and unit-magnitude product inputs automatically.

For GCC CPU controls with the same inputs:

```sh
make -C src/test/oberonv benchmark-cpu CPU_CC=gcc-14 \
  CPU_BENCH_ARGS='--threads 1 4 16 --bounded-products --workloads sum-integer sum-real prod-integer prod-real'
```

Use `CPU_CC=gcc` on Gentoo. `--cc` selects the parallel backend; sequential
compilation uses VOC's configured backend. Build logs record the actual
C compiler commands. Keep the GPU and CPU baselines on the same machine.
Recompile for each GPU architecture, retain each round in a separate
`BUILD` directory, and preserve `results.json` locally with the generated
sources and logs. `--quick --samples 3 --batch-ms 50` provides a shorter
build-and-correctness check.
