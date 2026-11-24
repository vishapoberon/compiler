# Vishap Oberon 5.4.1

Vishap Oberon compiles Oberon-2 programs through a C backend and supplies
libraries and tools for conventional operating systems. Version 5.4.1 improves
fatal-fault reporting when the main stack is exhausted.

## Stack-fault diagnostics

- Unix startup registers a 128 KiB alternate signal stack, preserving an
  existing host-provided stack. SIGSEGV handling can run without free space on
  the ordinary stack. Setup failures produce a warning and retain ordinary
  signal handling.
- Faults matching the cached main-stack boundary and interrupted stack pointer
  report `Fatal error: stack overflow (SIGSEGV).` Uncertain faults retain the
  generic invalid-memory diagnostic.
- Startup obtains the stack limit through `getrlimit()`. Linux mapping parsing
  uses Oberon; FreeBSD, NetBSD and OpenBSD have native `sysctl()` VM-map bindings.
  Signal-handler metadata uses `sig_atomic_t` storage. The handler performs no
  mapping queries, allocation, finalization or buffered-I/O cleanup.
- Missing mappings, unsupported contexts and unavailable or unlimited stack
  limits retain generic reporting. Bounds describe the startup main stack;
  native integrations changing stacks or limits must invalidate them.

Both fatal diagnostics exit with status `128 + SIGSEGV`. Stack-overflow
classification does not provide an Oberon source location. See
[runtime checks](RuntimeChecks.md#stack-exhaustion) for supported context layouts
and native integration requirements.

## Building and validation

Rebuild the runtime, dependent programs and shared modules to use the new
diagnostics. Unix bootstrap sources and build-time header staging are updated.

A clean GCC build on x86-64 Linux passes the confidence suite and reproduces
the saved bootstrap C sources. The non-network shared-module profile passes
271 ABI/load checks and its consumer tests, including stack-fault diagnostics
with embedded and dynamically linked cores.

Stack-fault, fallback, NIL-check and diagnostic regressions pass on x86-64 Linux
with GCC, Clang and TCC in both type models. With post-release test-harness
portability fixes, the full confidence suite also passes on NetBSD 9.3 amd64
with GCC, including enabled main-stack classification in both type models.
BSD VM-map query branches pass synthetic-interface checks; native FreeBSD,
OpenBSD, other architectures and Windows validation remain pending.
