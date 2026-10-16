# sts-q's Kbd library

`Kbd` reads terminal escape sequences and returns keys and mouse events as
32-bit integers. It comes from [sts-q's Oberon collection](https://codeberg.org/sts-q/oberon)
and works without terminfo or termcap.

The Unix model-2 library includes `Kbd`. It is also available through
`make modular-library`. Its licence is [GPL-3.0](LICENSE), without the VOC
runtime exception. Source revisions and porting changes are in [`PORT.toml`](PORT.toml).

## Reading keys

The application must put stdin into raw mode and arrange for reads to return
immediately when no input is available. For a terminal, use `termios.MakeRaw`
and `termios.Timeout(..., 0)`. For a pipe, set nonblocking mode. Restore the
terminal settings when the application exits. `Kbd` handles decoding, not
terminal setup.

- `NextKey()` returns the next key, or zero if none is ready.
- `GetKey()` waits for a key.
- `HasKey()` reports buffered input bytes; a partial escape sequence may still
  need more input before it becomes a key.
- `ShowKey(text, key)` writes a description such as `<CM-Up>` or `<B1-12-34>`.

Use `Kbd.KEY` for keys and mouse-output parameters. It is 32-bit in both
type models, unlike `INTEGER`.

For example, `Esc[1;7A` is Ctrl-Meta-Up,
`Kbd.FKey(Kbd.CM, Kbd.Up)`. The SGR mouse sequence `Esc[<0;34;12M` is a
left-button press at row 12, column 34, `Kbd.MKey(0, Kbd.B1, 12, 34)`.
Mouse coordinates start at 1 and must fit in 1..255.

Input is byte-oriented. UTF-8, bracketed paste and some function-key sequences
are not supported. Unsupported or malformed sequences return zero. Escape
sequences have a 50 ms timeout, so a slow sequence may be discarded; a lone
Escape is returned after that delay. NUL also has the value zero and cannot
be distinguished from no input. Read errors other than interruption or
would-block halt the program with a diagnostic.

## Key display example

After building VOC with `make` at the repository root:

```sh
make -C src/examples/libraries/sts-q
PETMOUSE=true make -C src/examples/libraries/sts-q run
```

Run it in a terminal. Press keys or click to see their descriptions; `q` or
Escape exits. The example includes terminal setup and cleanup.

The rest of sts-q's collection, including `Viewer` and its utility modules,
is in the [editor example](../../../examples/libraries/sts-q/editor/readme.md).

## Building separately

For a separate archive, including model-C builds:

```sh
make -C src/ports/sts-q/oberon
make -C src/ports/sts-q/oberon MODEL=C
```

These produce `libssq-O2.a` and `libssq-OC.a`, each containing only `Kbd.o`,
under `build/ports/sts-q/oberon/<model>`. Headers and symbols are in the same
directory. Set `VOCROOT` to use another VOC build, or `BUILD` to change the
output directory. Use separate output directories for different compilers,
type models and conventional/modular builds.

## Tests

The tests require Python 3 and Unix. Run them against the bundled library:

```sh
make -C src/test/ports/sts-q test-bundled
```

Or build and test the module separately:

```sh
make -C src/test/ports/sts-q test
make -C src/test/ports/sts-q test MODEL=C
```

They cover key encoding, mouse events, split sequences, malformed input,
EOF and read errors. They also run as part of the Unix model-2 confidence
tests and `make modular-library-test`.
