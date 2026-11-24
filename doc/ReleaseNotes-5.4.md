# Vishap Oberon 5.4

Vishap Oberon compiles Oberon-2 programs through a C backend and supplies
libraries and tools for conventional operating systems. Version 5.4 strengthens
compiler and runtime safety and standardizes source diagnostics.

## Runtime pointer checks

NIL checks are enabled by default for pointer dereferences, field and array
accesses, dynamic-array lengths, method receivers and procedure-variable calls.
A confirmed NIL dereference terminates with halt code `-10`. The `-n` option
toggles NIL checking independently of pointer initialization and other checks.

On Unix, SIGSEGV faults are reported separately as invalid memory accesses.
The emergency handler writes a fixed diagnostic to standard error and exits
without running finalizers or normal exit handlers.

## Source diagnostics

Compilation errors, warnings, and location-bearing runtime failures use the
editor-readable `filename:line:column: severity: message` convention. Compiler
diagnostics retain their numbers, source excerpts and carets. Runtime NIL and
array-bounds failures include the actual source filename, Oberon module and
source byte offset. Imported modules report the failed operation in their own
source file.

See [runtime checks and diagnostics](RuntimeChecks.md) for position conventions,
safety options and examples. Source files are not needed to report an embedded
runtime location.

## Compiler safety

- `SYSTEM.GET` and `SYSTEM.GETREG` reject read-only destinations, including
  imported `-` exports and selected fields or elements. `SYSTEM.VAL` preserves
  read-only protection. `SYSTEM.PUT` continues to accept read-only input values.
- `ALL` requires a static memory-independence proof in sequential, CPU OpenMP
  and GPU modes. Ambiguous aliases and unproved destination mappings are
  rejected; proven pointwise updates, disjoint fields and copied inputs remain
  supported.

## Building and upgrading

Rebuild the compiler, runtime, dependent programs and shared modules together.
Location-bearing checks require the updated runtime. Recompile existing `ALL`
bodies to apply the independence checks.
