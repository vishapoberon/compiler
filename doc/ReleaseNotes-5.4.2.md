# Vishap Oberon 5.4.2

Vishap Oberon compiles Oberon-2 programs through a C backend and supplies
libraries and tools for conventional operating systems. Version 5.4.2 fixes
confidence-test portability on NetBSD and FreeBSD.

## BSD regression tests

- Alternate-signal-stack failure injection redirects runtime calls after libc
  declarations are read. This preserves NetBSD's versioned symbol declarations
  while ensuring the test reaches the injected failure and checks its warning.
- Python-interpreter selection fixtures pass simulated exit statuses explicitly,
  avoiding shell-dependent leakage between test cases.
- Stack-fault tests report whether main-stack classification is enabled or why
  generic reporting is used.

The runtime retains the alternate-stack fatal-fault reporting and conservative
stack-overflow classification introduced in [5.4.1](ReleaseNotes-5.4.1.md).
See [runtime checks](RuntimeChecks.md#stack-exhaustion) for diagnostics and native
integration requirements.

## Native validation

Native builds and the full confidence suite pass on NetBSD 9.3 amd64 and
FreeBSD 15.1-RELEASE-p7 amd64. Both systems pass stack-fault regressions in both
type models; NetBSD confirms enabled main-stack classification with GCC.

Native OpenBSD, other architectures and Windows validation remain pending.
