# Runtime pointer checks

VOC checks for NIL before dereferencing Oberon pointers. These checks are enabled
by default, independently of pointer initialization, array bounds checks and type
guards. A failed check terminates the program with:

```text
Example.Mod:12:7: runtime error: Terminated by Halt(-10). NIL pointer dereference. (module Example, pos 193)
```

Diagnostics begin with `filename:line:column: severity: message`, following the
GCC/Clang convention recognized by editor problem lists, Vim quickfix and Emacs
compilation mode. The filename is the source argument supplied to VOC, including
its directory and original extension. Relative filenames are relative to the
compilation directory. The Oberon module name is retained separately, so source
filenames need not match module names.

Lines and columns are one-based; source byte offsets are zero-based. Columns
count source bytes; a tab occupies one column. LF, CRLF and CR line endings are
recognized. The location is embedded at compilation time, so the source file need
not be present when the program runs.

Array bounds errors use the same format:

```text
Example.Mod:18:14: runtime error: Terminated by Halt(-2). Index out of range. (module Example, pos 287)
```

For an indexed access, the location points to the index expression. NIL checks
point to the dereference or selection that requires the pointer, or to the
procedure-variable call. Checks in imported modules report the module containing
the failed operation. Array-copy length checks and GPU host-side bounds checks
also carry locations. Pointer type-guard errors handled by the checked pointer
helpers include the guard location.

Locations are passed directly to each failing check, without a shared last-known
position. Finalizers performing other checked operations do not overwrite the
original check's location.

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
Location-bearing checks require the updated runtime as well as the compiler.

## Compiler diagnostics

Compiler errors and warnings use the same filename and position prefix. They
retain their diagnostic numbers and source offsets, followed by the source line
and a caret:

```text
Example.Mod:36:33: error: this variable (field) is read only [err 76 at pos 593]
  36:   SYSTEM.GET(address, Data.value);
                                      ^
```

Warnings use `warning:` and a `[warning ...]` identifier. Driver errors without a
source position, such as an unreadable source file, omit the line and column.

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
