# Runtime pointer checks

VOC checks for NIL before dereferencing Oberon pointers. These checks are enabled
by default, independently of pointer initialization, array bounds checks and type
guards. A failed check terminates the program with:

```text
Terminated by Halt(-10). NIL pointer dereference.
```

Checks cover explicit dereferences, pointer-based field and array accesses,
dynamic-array lengths, record arguments and assignments, type guards, method
receivers, and procedure-variable calls. Checking a pointer does not evaluate its
expression a second time. Pointer assignment, equality tests and short-circuit
conditions do not require a non-NIL value. A NIL pointer tested against an
extension type with `IS` yields `FALSE`.

Like the other safety options, `-n` toggles NIL checking; one occurrence disables
it and a second restores it. `-p` controls pointer initialization separately.
Disabling other checks with `-x` or `-t` does not disable NIL checking. Generated
method dispatch helpers retain the safety setting of their defining module.
Recompile modules to apply a changed safety setting to their generated code.

## Invalid memory accesses

NIL checks establish that a pointer is nonzero, not that an arbitrary address is
valid. Unsafe addresses supplied through `SYSTEM` or native interfaces can still
fault. On Unix, the automatic SIGSEGV handler reports:

```text
Fatal error: invalid memory access (SIGSEGV).
```

This diagnostic goes to standard error. The handler writes a fixed message and
exits with status `128 + SIGSEGV`, without invoking Oberon finalizers, buffered-I/O
cleanup, or normal exit handlers. Ordinary checked NIL errors use the regular
halt path, including finalization. SIGSEGV handling does not identify the faulty
Oberon expression; it does not imply that the pointer was NIL.

## Regression tests

Run `make -C src/test/nilchecks test`, selecting `VOC`, `VOCROOT`, `MODEL` and
`BUILD` for the compiler image and output directory. The suite runs faulting
programs in separate processes and disables core dumps. It checks confirmed NIL
errors, generic memory faults, finalization behavior, safety-option independence,
and valid pointer operations. Both type models `2` and `C` are supported.

These are VOC-specific tests: they exercise Oberon-2 methods, pointer-based open
arrays, compiler safety options and Unix signal handling.
