# VOC 4.0.6 validation

A clean release-only source snapshot completed `make all` with GCC on x86-64
Linux, rebuilding the compiler, both library type models, the local installation
image and the full confidence suite. The resulting compiler reports 4.0.6.
The 2,664 checks below were repeated with that compiler, and the documented
memory-file example passed against the rebuilt libraries in both type models.
All build and installation-image files stayed under `/tmp/opencode`.

To reproduce the conventional build from a clean source tree:

```sh
make all INSTALLDIR="$PWD/install"
```

The memory-file and native picture-codec changes were checked on x86-64 Linux
with GCC/C23, TCC, Clang/C23 ASan/UBSan and shared modules. Each profile passed
the same 2,664 checks:

| Suite | Checks |
| --- | ---: |
| Preserved PNG fixtures | 338 |
| Preserved JPEG fixtures | 70 |
| Preserved GIF fixtures | 39 |
| Memory files and bounded codec APIs | 88 |
| Ordinary-file compatibility | 263 |
| PNG file-versus-memory metadata, errors and pixels | 1,383 |
| JPEG file-versus-memory metadata, errors and pixels | 294 |
| GIF file-versus-memory metadata, errors and pixels | 175 |
| zlib regressions | 14 |

Tests cover input-prefix validation, fixed output capacity, sticky write
failures and purge recovery, buffers larger than the ordinary file cache,
number and string rider operations, PNG alpha values 0 and 128, GIF canvas
offset limits, invalid encoder pixel buffers and preserved decoding results.
Linux syscall traces of the memory-only suite showed no file creation,
temporary-file creation or memory-file descriptors. Original upstream hash
records remain unchanged; adapted codec hashes are checked separately.

With a matching compiler installation, run:

```sh
make -C src/ports/polpo test VOC="$PWD/install/bin/voc"
```

For shared modules, set the library paths for that installation, then run:

```sh
python3 src/ports/polpo/check-codecs.py --shared \
  --voc "$PWD/install/bin/voc" --build "$PWD/build/picture-memory-shared"
```

The TCC and sanitizer profiles recompiled the generated C for `Files`, the
codecs, zlib and the test modules, linking these objects ahead of the
conventional runtime archive. The sanitizer profile used `-std=c23 -O1 -g`,
`-fno-strict-aliasing -fno-omit-frame-pointer`,
`-fsanitize=address,undefined -fno-sanitize=function`, an uninstrumented
conservative core, `ASAN_OPTIONS=detect_leaks=0:detect_stack_use_after_return=0`
and `UBSAN_OPTIONS=halt_on_error=1`.

Broader adversarial image review and native Windows validation remain pending.
Earlier compiler and runtime matrix coverage is documented in
[4.0.3 validation](ReleaseValidation-4.0.3.md).
