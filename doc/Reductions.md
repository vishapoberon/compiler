# Adding and multiplying independent values

`SUM` adds a sequence of values. `PROD` multiplies them. Development sources
after VOC 5.0 enable both through the experimental Oberon-V option, `-j`.
They use the array-constructor
syntax described in Robert Griesemer's
[Oberon-V dissertation](https://norayr.am/papers/eth10277.pdf).

Suppose an array contains four measurements. We can add them with:

```oberon
total := SUM([i = 0 .. LEN(values)-1: values[i]])
```

The part before the colon declares the range. Both bounds are inclusive.
The expression after the colon gives the value contributed by one index.
The constructor describes those values directly; VOC generates a loop to
combine them.

A dot product multiplies corresponding elements before adding them:

```oberon
dot := SUM([i = 0 .. LEN(a)-1: a[i] * b[i]])
```

The caller must supply arrays covering the selected range. Ordinary array
bounds checks apply to sequential and CPU execution. GPU builds check the
supported index ranges on the CPU before launching device work.

## A complete program

Save this as `Measurements.Mod`:

```oberon
MODULE Measurements;
IMPORT Out;
VAR values: ARRAY 4 OF REAL; total, product: REAL; i: LONGINT;
BEGIN
  FOR i := 0 TO LEN(values)-1 DO values[i] := 0.5 END;
  total := SUM([i = 0 .. LEN(values)-1: values[i]]);
  product := PROD([i = 0 .. LEN(values)-1: values[i]]);
  ASSERT(total = 2); ASSERT(product = 0.0625);
  Out.String("reduction results passed"); Out.Ln
END Measurements.
```

With a compiler containing reduction support, compile and run it:

```sh
voc -sFmj Measurements.Mod
./Measurements
```

For CPU OpenMP execution:

```sh
voc -sFmjP Measurements.Mod
OMP_NUM_THREADS=4 ./Measurements
```

For a configured GPU backend:

```sh
voc -sFmjG Measurements.Mod
OMP_TARGET_OFFLOAD=MANDATORY ./Measurements
```

The [parallel tutorial](GPUTutorial.md) explains the execution modes. The
[setup guide](GPUSetup.md) covers GCC and Clang on Debian and Gentoo,
including the tested GPU compatibility limits. The
[GPU reduction measurements](GPUReductions.md) compare both AMD devices
with CPU baselines, including transfers.

## Ranges, types and empty results

The bounds are integer expressions. They are evaluated once, lower bound
first, before evaluating any contributed value. The range identifier is
read-only and belongs to the constructor. An enclosing variable with the
same name keeps its value.

The contributed expression must have an integer, `REAL` or `LONGREAL` type.
The result retains that expression's type. Use appropriately typed inputs
or widen values inside the constructor when a larger result type is needed.
Assigning the completed result to a wider variable preserves the already
computed result.

Integer constants use VOC's inferred constant type. A typed scalar or array
element selects the intended integer width explicitly.

For an empty range, `SUM` returns zero and `PROD` returns one, in the result
type. The contributed expression is skipped, so an empty reduction performs
zero element accesses or scalar reads from that expression. Single-element
ranges and ranges ending at the largest representable index are supported.

`SUM` and `PROD` are predefined functions. A local declaration can shadow
either name. Ordinary Oberon-2 compilation keeps those names available for
user declarations.

## Integer arithmetic

Integer combination uses modular arithmetic at the result type's width.
For example, adding one to the largest signed 32-bit result yields its
smallest signed value. CPU and GPU regrouping preserve that modular sum or
product. VOC uses unsigned accumulation and reconstructs the signed result
with defined C arithmetic.

This rule covers the combination of contributed values. Arithmetic inside
the contributed expression follows the usual VOC rules. Choose types wide
enough for those intermediate calculations too.

## Floating-point arithmetic

Sequential mode starts with zero for `SUM` or one for `PROD`, then combines
values in ascending index order. Each accumulator has the result's floating-
point type.

CPU OpenMP and GPU modes may group partial sums or products differently.
The grouping can change rounding, overflow, underflow and the handling of
cancelling large values. Compare parallel numerical results with an
appropriate tolerance. Compiler options controlling floating-point
transformations also affect the result.

## Initial supported subset

This implementation accepts one range identifier in each constructor.
Expressions can read scalar variables and direct one-dimensional numerical
array variables, including open-array parameters. Record fields and heap
designators remain further work. Bounds and contributed expressions must
be free of procedure calls. Nested reductions and reductions within an
`ALL` body remain further work. These rules let the compiler capture the
inputs for a private generated helper while retaining ordinary expression
use in assignments, arguments, conditions and returns.

GPU reductions use the existing numerical device-expression subset: array
indices must be the range identifier, a suitable widening conversion of it,
or a nonnegative constant. Operations requiring device runtime helpers are
diagnosed. Multiple potentially aliased array arguments are rejected by
the current GPU mapping checks. CPU reductions accept read-only aliasing,
including a dot product with the same array supplied twice.

The constructor syntax here belongs to `SUM` and `PROD`. General array views
and multidimensional reduction constructors remain further work.
[`ALL` with several ranges](GPUTutorial.md#processing-rows-and-columns) supports
sequential and CPU execution.

## Tests

From the source root, after building the updated compiler:

```sh
make -C src/test/oberonv test-reductions test-reductions-cpu
make -C src/test/oberonv test-reductions-gpu
```

The last target checks explicit host fallback. To test an actual configured
device, use:

```sh
make -C src/test/oberonv test-reductions-device GPU_CC=clang-19
```

Device tests require mandatory offloading and check the execution location
with `omp_is_initial_device()`. The cases cover integer widths, wrapping
results, floating-point values, empty ranges, integer endpoints, captures,
scope, bounds failures and rejected constructors. `MODEL=C` selects the
other conventional type model.
