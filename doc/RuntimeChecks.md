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

### Stack exhaustion

On Unix, program startup reserves a 128 KiB alternate signal stack for the main
thread and enables alternate-stack delivery for SIGSEGV. An already enabled
alternate stack supplied by an embedding host is preserved. Repeated setup
reuses the enabled stack. Host-provided stacks must have sufficient capacity
for their handlers. Other signal handlers retain their existing stack behavior.

When stack exhaustion raises SIGSEGV, the emergency handler can therefore run
without space on the ordinary stack. When the fault address and interrupted
stack pointer match the known main-stack boundary, it reports:

```text
Fatal error: stack overflow (SIGSEGV).
```

Otherwise it retains the generic invalid-memory diagnostic. Both paths exit
with status `128 + SIGSEGV`, without finalizers or buffered-I/O cleanup. Neither
path supplies an Oberon source location.

Startup reads the finite soft stack limit with `getrlimit()`. Linux discovers
the main-stack mapping through `/proc/self/maps`; FreeBSD, NetBSD and OpenBSD
use their native `sysctl()` VM-map interfaces. Mapping interpretation on Linux
is implemented in Oberon. Native structure layouts stay in the Unix binding
layer. No mapping query, allocation or resource-limit query runs in the signal
handler.

Classification requires a supported saved-stack-pointer layout: Linux x86,
x86-64, ARM and AArch64; FreeBSD x86, x86-64 and AArch64; NetBSD targets exposing
`_UC_MACHINE_SP`; and OpenBSD x86, x86-64 and AArch64. These paths assume a
downward-growing main stack. Missing mappings, unavailable or unlimited stack
limits, unsupported contexts and ambiguous faults retain generic reporting.
Native validation currently covers x86-64 Linux and NetBSD 9.3 amd64 with GCC
in both type models. Other listed targets remain pending.

The bounds describe the startup stack and limit. Native code that changes the
stack limit or switches stacks must disable classification with
`SYSTEM_SetStackBounds(0, 0)`. Replacement bounds must contain the original
startup stack anchor. Classification
recognizes nearby stack accesses and frame jumps up to 16 MiB below the cached
lower bound; larger or unrelated faults remain generic. A matching fault
describes the stack-boundary violation, not the cause of earlier memory
corruption.

If alternate-stack setup fails, startup writes a warning and retains ordinary
SIGSEGV handling; reporting after stack exhaustion is then unreliable. Alternate
signal stacks are per-thread. Additional native threads must provide separate
alternate stacks. Applications that replace or disable the signal stack or
handler control their subsequent fault behavior.

## Regression tests

Run `make -C src/test/nilchecks test`, selecting `VOC`, `VOCROOT`, `MODEL` and
`BUILD` for the compiler image and output directory. The suite runs faulting
programs in separate processes and disables core dumps. It checks confirmed NIL
errors, generic memory faults, finalization behavior, safety-option independence,
and valid pointer operations. Both type models `2` and `C` are supported.

The suite also runs recursive and large-local-array exhaustion with a 256 KiB
stack limit, checks that fatal faults do not flush output or run finalizers,
verifies actual alternate-stack delivery and preservation of host-provided
stacks, checks classification boundaries and injects alternate-stack
query/registration and stack-limit failures. Unlimited stack limits are also
checked for generic reporting. Run only these checks with
`make -C src/test/nilchecks stack`, using the same build variables.

These are VOC-specific tests: they exercise Oberon-2 methods, pointer-based open
arrays, compiler safety options and Unix signal handling.
