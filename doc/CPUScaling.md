# Measuring CPU scaling

The CPU benchmark measures multidimensional `ALL`, `SUM` and `PROD` using
sequential execution and CPU OpenMP with one, two and four threads. It
requires a development compiler with those extensions, Python 3 and an
OpenMP-capable C backend.

From the source root, after building the compiler:

```sh
make -C src/test/oberonv benchmark-cpu
```

VOC compiles and links the generated Oberon modules through its C backend.
The benchmark selects GCC by default. Use `CPU_CC=clang` for Clang with its
OpenMP runtime installed. The
[setup guide](GPUSetup.md#installing-voc-with-clang) explains how to configure
Clang as VOC's normal backend.

For a short build-and-correctness check:

```sh
make -C src/test/oberonv benchmark-cpu CPU_BENCH_ARGS='--quick --samples 3 --batch-ms 50'
```

`MODEL=C` selects the other conventional type model. `VOC` and `VOCROOT`
select another compiler and runtime image, as with the correctness tests.

## Calculations

The grid cases use 1024×1024 and 2048×2048 `REAL` elements. One case performs
an affine transformation. The other applies sixteen affine stages through
an iteration-private temporary. CPU OpenMP distributes rows among workers.

Reductions use 1,048,576 and 8,388,608 elements. Integer cases use signed
64-bit inputs. Real cases use `LONGREAL`. Sum inputs are small signed
integers or exact binary fractions. Product inputs are alternating powers
of two, or a repeated integer sequence containing positive and negative
ones. Every case has an independently calculated exact result. These inputs
keep the full reduction useful while giving exact checks in every execution
mode.

## Timing and verification

All modes use the same C compiler and optimization flags:

```text
-O3 -march=native -fno-strict-aliasing -ffp-contract=off -fno-lto
```

The kernel and timing driver are separate Oberon modules. Link-time
optimization is disabled, so repeated calls remain separate calculations.
Initialization and verification are outside the timed intervals. Every
grid output and all reduction inputs are checked, together with each
reduction result.

The first call is recorded separately. The driver then calibrates a batch
to approximately 150 milliseconds, up to 4096 calls, and times five batches.
Inputs are reused between calls. The table reports
the median time per call. It also retains every sample in `results.json`,
alongside the processor, compiler, flags, compiler-executable and runtime-library hashes.
Execution modes run in a shuffled order with a fixed seed.

OpenMP uses fixed thread counts, core binding and passive waiting. On Linux,
the runner also records the observed thread count and worker CPU ticks.
Multi-thread runs require observed active workers.

## Reading the results

`versus_sequential` divides the sequential time by the reported time. A value
above one means that case ran faster. `versus_cpu1` compares against the
same OpenMP build using one thread. This second comparison separates thread
scaling from differences between the sequential and OpenMP-generated loop
shapes and their C compiler vectorization.

Small grids and reductions can spend more time starting parallel work than
they save. Memory bandwidth, cache size, processor frequency, power limits
and other applications also affect the result. Repeat measurements on an
otherwise idle machine before drawing conclusions. Correctness tests remain
separate from these machine-specific performance measurements.

## Four-core Intel measurements

Measurements on 14 November 2026 used an Intel Core i7-1165G7 with four
enabled CPU cores, Gentoo Linux, GCC 14.3.1 and VOC model 2. The compiler
included multidimensional `ALL` and reductions from the development sources.
The measurements below precede the counted-loop improvements described
under [checking automatic vectorization](#checking-automatic-vectorization).
[Counted-loop measurements](#counted-loop-measurements) repeat the comparison
with the improved sequential and OpenMP loops.

Two complete runs checked all six calculations at both sizes with sequential
execution and one, two and four OpenMP threads. The first used five samples
and 150 ms batches; the repeat used seven samples and 200 ms batches, with
the OpenMP thread counts supplied in reverse order before shuffling.

Times below are milliseconds per call. Each range spans the two run medians.
Speedup is calculated within each run before taking its range.

| Calculation | Elements | Sequential ms | OpenMP, 4 threads ms | Four-thread speedup |
| --- | ---: | ---: | ---: | ---: |
| Grid, affine | 1024×1024 | 0.350 | 0.770–1.073 | 0.33–0.45× |
| Grid, affine | 2048×2048 | 1.922–2.011 | 2.894–2.950 | 0.65–0.69× |
| Grid, 16 stages | 1024×1024 | 14.162–14.274 | 5.457–6.038 | 2.36–2.60× |
| Grid, 16 stages | 2048×2048 | 60.727–64.853 | 19.222–40.610 | 1.60–3.16× |
| Integer `SUM` | 1,048,576 | 0.324–0.342 | 1.456–1.846 | 0.19–0.22× |
| Integer `SUM` | 8,388,608 | 3.836–4.143 | 4.110–9.927 | 0.42–0.93× |
| `LONGREAL` `SUM` | 1,048,576 | 2.127–2.167 | 1.065–1.084 | 2.00× |
| `LONGREAL` `SUM` | 8,388,608 | 17.164–17.310 | 5.522–6.103 | 2.81–3.13× |
| Integer `PROD` | 1,048,576 | 1.994–2.037 | 0.595–0.666 | 2.99–3.43× |
| Integer `PROD` | 8,388,608 | 16.042–16.044 | 7.122–7.346 | 2.18–2.25× |
| `LONGREAL` `PROD` | 1,048,576 | 2.125 | 0.777–1.338 | 1.59–2.73× |
| `LONGREAL` `PROD` | 8,388,608 | 17.068–17.099 | 7.918–9.121 | 1.87–2.16× |

Four threads improve the arithmetic-heavy grid, floating-point sum and both
product calculations on this machine. The affine grid and integer sum run
faster sequentially. GCC's vectorization reports show SIMD loops for those
two sequential calculations and scalar loops in their OpenMP kernels. These
measurements motivated improving their OpenMP loop generation.

Some parallel samples varied substantially: the largest maximum-to-minimum
ratio within one configuration was 3.45×. Four threads also sometimes took
longer than two. These results establish useful speedups for several
calculations while showing the need to measure each workload and thread
count on the target machine.

## Checking automatic vectorization

GCC and Clang select SIMD instructions when their optimizers can establish
that a loop is suitable. The generated C loop shape and visible bounds
affect that decision, including inside OpenMP worker functions.

Development sources use direct counted sequential and OpenMP loops for
suitable constant ranges. The range checks establish that the iteration
count and final increment fit the index type. Other ranges retain the endpoint-safe loop
form. With array bounds checking enabled, VOC omits a per-element check
only when it can prove that the selected fixed-array dimension covers the
range. Dynamic and unproven accesses retain their checks.

The GCC regression target checks the vectorization report for the actual
sequential and OpenMP affine-grid, 16-stage-grid and integer-sum kernels:

```sh
make -C src/test/oberonv test-cpu-vectorization CPU_CC=gcc
make -C src/test/oberonv test-cpu-vectorization CPU_CC=gcc MODEL=C
```

This target uses `-march=native` and requires a GCC target with SIMD support.
It checks ordinary auto-vectorization, with SIMD instruction selection left
to GCC. The generated loops use OpenMP parallelization and reduction clauses.

## Counted-loop measurements

The complete measurements were repeated after improving the loop generation,
using the same benchmark runner, C compiler flags and runtime library. Both
the sequential and OpenMP grid loops now expose the constant bounds directly.
GCC's reports confirm auto-vectorization for the affine grid, 16-stage grid
and integer sum in both modes.

The first run again used five samples and 150 ms batches; the second used
seven samples and 200 ms batches. Ranges below span the two run medians.
Speedups compare each four-thread result against its own sequential result.

| Calculation | Elements | Sequential ms | OpenMP, 4 threads ms | Four-thread speedup |
| --- | ---: | ---: | ---: | ---: |
| Grid, affine | 1024×1024 | 0.337–0.344 | 0.132–0.138 | 2.44–2.61× |
| Grid, affine | 2048×2048 | 1.952–2.009 | 1.277–1.345 | 1.45–1.57× |
| Grid, 16 stages | 1024×1024 | 1.808–1.813 | 0.659–0.676 | 2.67–2.75× |
| Grid, 16 stages | 2048×2048 | 7.158–7.324 | 2.447–2.491 | 2.92–2.94× |
| Integer `SUM` | 1,048,576 | 0.317–0.318 | 0.125–0.133 | 2.39–2.53× |
| Integer `SUM` | 8,388,608 | 3.815–4.026 | 1.814–3.444 | 1.17–2.10× |
| `LONGREAL` `SUM` | 1,048,576 | 2.121–2.158 | 0.796–0.875 | 2.42–2.71× |
| `LONGREAL` `SUM` | 8,388,608 | 17.092–17.293 | 5.442–9.059 | 1.89–3.18× |
| Integer `PROD` | 1,048,576 | 1.991–1.993 | 0.704–1.381 | 1.44–2.83× |
| Integer `PROD` | 8,388,608 | 16.071–16.303 | 5.114–5.215 | 3.08–3.19× |
| `LONGREAL` `PROD` | 1,048,576 | 2.122–2.123 | 0.759–1.765 | 1.20–2.80× |
| `LONGREAL` `PROD` | 8,388,608 | 17.063–17.071 | 5.413–9.922 | 1.72–3.15× |

The sequential 16-stage grid also becomes substantially faster. Four-thread
speedups above therefore use that improved baseline. One-thread OpenMP
times are now close to sequential times for the grids and integer sum.

All twelve size-and-calculation combinations improve over sequential code
with four threads in both runs. Two threads still sometimes beat four;
for example, the large affine grid takes 1.170–1.190 ms with two threads.
The largest maximum-to-minimum ratio within a configuration is 2.60× in
these repeats, so workload and thread-count measurements remain important.

The machine's existing power-saving policy is retained. A sysfs reading
during measurement reports `powersave`, `balance_performance` and a configured
maximum frequency of 2 GHz on all four cores.
