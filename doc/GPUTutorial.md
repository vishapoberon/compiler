# A gentle introduction to parallel programming with VOC

Suppose we have an array of numbers and wish to multiply every element by
two. Each element can be calculated independently. VOC can carry out this
work sequentially, across several CPU cores, or on a GPU.

We shall write one Oberon program and select its execution mode with a
compiler option. This introduction assumes VOC 5.0 is installed and `voc`
is available in your shell. Parallel modes also need an OpenMP toolchain;
the [AMD setup guide](GPUSetup.md) describes the tested GPU configuration.
VOC runs the C backend and linker for us.

## A first array calculation

Keep the example sources in a directory of your choice. Save this program
as `Vectors.Mod`:

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

`ALL` is an experimental Oberon-V statement. Its bounds are inclusive:
here `r` takes the values 0 through 15. Each iteration writes its own element
of `values`. The `FOR` loop then checks every result.

In your shell, enter the directory containing `Vectors.Mod` and run:

```sh
voc -sFmj Vectors.Mod
./Vectors
```

The output is:

```text
vector results passed
```

`-j` enables Oberon-V and selects sequential execution. `-m` builds an
executable. `-sF` permits creation and replacement of the example's symbol
file. VOC translates the program, compiles the generated C and links
`Vectors`. The generated files are placed beside the example sources.

## Using several CPU cores

Compile the same source with `-jP`:

```sh
voc -sFmjP Vectors.Mod
OMP_NUM_THREADS=4 ./Vectors
```

`-P` selects CPU OpenMP execution. The second command requests four CPU
threads. The program should print the same success message.

VOC uses its configured C backend and selects `-fopenmp` for GCC or Clang.
The matching OpenMP runtime must also be installed. The setup guide explains
how to [install VOC with Clang as its default backend](GPUSetup.md#installing-voc-with-clang).

Our sixteen-element array is useful for checking the program. Larger
calculations help repay the cost of starting parallel work.

## Using a GPU

GPU execution needs a backend configured for the device. The AMD tests
encountered an optimized GCC 14 offload failure on the integrated `gfx1036`
GPU. Clang 19 passed on both tested AMD GPUs, so the
[setup guide](GPUSetup.md) uses Clang. Complete that setup once for your
machine. Then compile with `-jG`:

```sh
voc -sFmjG Vectors.Mod
OMP_TARGET_OFFLOAD=MANDATORY ./Vectors
```

`-G` asks VOC to generate OpenMP target regions. VOC invokes the offload
compiler and links the host and device code into the executable.
`OMP_TARGET_OFFLOAD=MANDATORY` requires device execution. The setup guide
also explains the execution-location probe used by the bundled tests.

The CPU runs the application and supplies the array to the GPU. After the
GPU completes its assignments, the results return to the CPU. Execution
then continues with our checking loop. Data transfers and launches take
time, so a larger or more demanding calculation is usually needed to benefit
from GPU execution.

## Keeping iterations independent

Within one iteration, assignments run in source order. Different iterations
may run concurrently. Each iteration therefore needs its own writable
storage, and its inputs must remain stable while the statement runs.

For example, `values[r] := values[r] * 2` reads and writes one element per
iteration. A statement such as `values[r] := values[r-1]` introduces a
dependency between neighbouring elements and needs an ordered loop. A shared
sum also needs a sequential loop or a reduction algorithm.

The compiler checks types, body syntax and some simple overlaps. The
programmer remains responsible for independence through pointers, aliased
parameters and indirect indices.

The bounds are evaluated once, lower bound first. An empty range performs
zero assignments. The range identifier is read-only and belongs to the
`ALL` body.

## Private working variables

An intermediate value can belong to one iteration. `WITH` declares it:

```oberon
ALL r = 0 .. LEN(values)-1 WITH t: REAL DO
  t := values[r] * factor;
  values[r] := t
END
```

Each iteration has its own `t`. The compiler checks that it is assigned
before being read. Use this form for intermediate values when parallel
iterations would otherwise write to a shared procedure variable.

## Putting the calculation in a module

An application can call the calculation through an ordinary Oberon
interface. Save the following as `GPUArrays.Mod`:

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

Save its caller as `UseGPU.Mod` in the same example directory:

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

Compile the library first, then its caller:

```sh
voc -sFjcG GPUArrays.Mod
voc -sFmjG UseGPU.Mod
OMP_TARGET_OFFLOAD=MANDATORY ./UseGPU
```

`-c` produces the library's object file. The following invocation links it
with the main program. Keep the generated symbol, header and object files
together. All modules in a GPU build need a matching type model, backend
and offload configuration.

To use CPU threads, replace `G` with `P` in both compilation commands and
run `OMP_NUM_THREADS=4 ./UseGPU`. For sequential execution, omit `G` from
both commands. Recompile the library and caller when changing modes.

## Choosing a calculation

The direct GPU backend supports one-dimensional numerical arrays, scalar
value captures and private scalar temporaries. Its body is a sequence of
assignments. Array indices may be the range identifier, a suitable widening
conversion of it, or a nonnegative constant. One open-array argument can be
mapped. Checked bounds are validated on the CPU before launching the kernel.

Records, multidimensional arrays, heap designators, indirect lookup indices,
potentially aliased array arguments, runtime-dependent operations and
procedure calls are outside this initial GPU subset.

The [HALD application](../src/examples/utilities/hald/readme.md) demonstrates
a larger image calculation with indirect lookups. Its library supplies a
dedicated, checked GPU build backend and keeps the Oberon `HaldClut.Apply`
interface. The command reads a photograph and colour LUT and writes a PNG.

## Measuring the result

Check every result before measuring performance. Compare several timed
batches, record the first-call cost separately, and state whether transfers
and file I/O are included.

The [published measurements](ParallelBenchmarks.md) compare one, four and
sixteen CPU threads with two AMD GPUs. The multicore CPU was fastest for
the numerical examples. The RX 5600 XT was faster for HALD conversion,
including transfers. Measure your own workload to choose a mode.

The [array examples](../src/examples/language/gpu/readme.md) and
[HALD example](../src/examples/utilities/hald/readme.md) provide the sources,
tests and benchmark commands for repeating these experiments.
