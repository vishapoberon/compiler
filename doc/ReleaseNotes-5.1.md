# Vishap Oberon 5.1

Vishap Oberon compiles Oberon-2 programs through a C backend and supplies
libraries and tools for conventional operating systems. Version 5.1 adds
experimental Oberon-V reductions, multidimensional independent iteration
on CPUs, and improved CPU loop generation.

## SUM and PROD reductions

`SUM` adds independently contributed values; `PROD` multiplies them:

```oberon
total := SUM([i = 0 .. LEN(values)-1: values[i]]);
product := PROD([i = 0 .. LEN(factors)-1: factors[i]])
```

Bounds are inclusive and evaluated once. The expression after the colon
supplies each value. The result retains that expression's integer, `REAL`
or `LONGREAL` type. Empty reductions return zero for `SUM` and one for
`PROD`, without reading contributed values. Integer arithmetic combines
values modulo the result width. Sequential floating-point reductions
retain ascending index order; parallel execution may regroup operations.

Choose an execution mode with the existing Oberon-V options:

| Options | Execution |
| --- | --- |
| `-j` | Sequential |
| `-jP` | CPU OpenMP |
| `-jG` | Synchronous GPU OpenMP target execution |

For a main program, add `-m`. CPU OpenMP uses a compatible C compiler and
runtime; `OMP_NUM_THREADS=4` requests four CPU threads. GPU execution needs
a compatible offload compiler, device runtime, libraries and driver.
VOC invokes the C backend and linker.

Reductions are one-dimensional. Procedure calls, nested reductions and
reductions inside `ALL` are outside the supported subset. The predefined
names can be shadowed by local declarations. See
[Adding and multiplying independent values](Reductions.md) for complete
programs, arithmetic rules and compilation examples.

## Multidimensional ALL on CPUs

Sequential and CPU OpenMP execution support several range identifiers:

```oberon
ALL row = 0 .. LEN(values)-1, col = 0 .. LEN(values, 1)-1 WITH t: REAL DO
  t := source[row, col] * factor;
  values[row, col] := t
END
```

Each index combination has its own private `WITH` variables. CPU OpenMP
distributes the outer range among workers. All bounds are evaluated before
iteration, and any empty range gives zero assignments. GPU `ALL` continues
to support a single range. The [parallel tutorial](GPUTutorial.md) introduces
the syntax and independence requirements.

## CPU loop generation and measurements

Suitable constant ranges produce direct counted loops, allowing GCC and
Clang to select SIMD instructions automatically. Bounds checks are omitted
only when a static proof covers the selected fixed-array dimension.
Unproven accesses retain their checks, and endpoint-safe loop forms cover
ranges that cannot use a direct counted loop.

The [CPU scaling measurements](CPUScaling.md#counted-loop-measurements)
compare sequential and OpenMP execution on a four-core Intel machine.
Four-thread results include 2.39–2.53× for a million-element integer `SUM`
and 3.08–3.19× for an eight-million-element integer `PROD`, against the
improved sequential code.

The [AMD reduction measurements](GPUReductions.md) compare GCC and Clang CPU
controls with two actual GPUs. With transfers included, the RX 5600 XT
improves the eight-million-element `LONGREAL PROD` by 1.29–1.30× over
sequential CPU code. Sixteen-thread CPU execution remains faster than both
GPUs in every tested reduction. The benchmark records first-call costs,
checks results and inputs, and requires actual GPU execution.

## GCC and Clang setup

The [setup guide](GPUSetup.md) covers CPU OpenMP and AMD GPU execution on
Debian and Gentoo, including package names, Gentoo USE flags, backend
selection, device access and offload compiler flags. Gentoo GPU instructions
are based on package inspection; device execution was validated on Debian.

Clang 19.1.7 passes optimized `ALL`, `SUM` and `PROD` device tests on the
RX 5600 XT (`gfx1010`) and integrated Radeon (`gfx1036`), in models 2 and C.
Debian GCC 14.2.0 passes sequential and CPU OpenMP tests. Its AMD offload
compiler rejects `gfx1010`; on `gfx1036`, `-O0` passes but optimized numerical
kernels report `HSA_STATUS_ERROR_INVALID_ISA` and hang. Standalone C
reproduces the optimized failure. Simple device-location probes alone do
not establish numerical correctness.

## Building and upgrading

Run `make` to build the compiler and conventional libraries and run the
confidence suite. Unix builds leave an installation image in `install/`.
See [installation](Installation.md) for system installation and dependencies.
Rebuild generated C, symbol files and libraries with the new compiler.
Keep the runtime and module libraries from the same build together, and
recompile GPU objects when changing backends, architectures or type models.

The release also includes IRC, option-parser and IRC bot updates using
`Platform.Exit` consistently for program termination.

## Validation

Clean GCC, Clang and TCC release builds pass the confidence suite on 64-bit
Linux. CPU OpenMP, automatic-vectorization and GPU host-fallback regression
tests cover models 2 and C. Shared-module OpenMP execution also passes in
both models. The IRC bot passes local-peer regression tests with GCC and
Clang. All five bootstrap C source sets are regenerated.
Mandatory-device correctness checks on both AMD GPUs and 224 full CPU/GPU
reduction measurements validate the numerical changes. Other operating
systems have regenerated bootstrap sources; fresh execution tests for this
release are limited to Linux.
