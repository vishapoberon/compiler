# VOC 4.0.4 validation

The picture-codec and zlib integration was checked on x86-64 Linux with GCC,
Clang, TCC and Clang ASan/UBSan: 338 PNG, 70 JPEG, 39 GIF and 14 zlib checks
passed. Command-line conversions covered filenames containing spaces.
Conventional builds, 257 shared-module ABI/load checks, shared codec fixtures,
installed tools and hosted picture commands also passed.

The sanitizer profile uses an uninstrumented conservative core,
`-fno-sanitize=function`, `ASAN_OPTIONS=detect_leaks=0:detect_stack_use_after_return=0`
and `UBSAN_OPTIONS=halt_on_error=1`. Generated C is built unoptimized to preserve
conservative stack roots. Native Windows validation remains pending.

The final Internet sources passed 330 socket checks and NetSystem basic (26),
refused (72), pending (280), blocking (135) and resume (8) checks against local
loopback peers. The recorded upstream revision is
`09bb5a97eea13d2fceaac99325e42c38fbe83fed`.

With a matching checkout installation, run:

```sh
make -C src/ports/polpo test VOC="$PWD/install/bin/voc"
make -C src/test/ports test NETWORK=1
```

The earlier runtime and compiler validation is documented in
[4.0.3 validation](ReleaseValidation-4.0.3.md). The full compiler matrix was
not repeated after the final additive Internet update.
