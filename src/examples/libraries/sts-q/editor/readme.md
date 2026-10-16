# sts-q's editor modules

`Viewer` is a terminal text editor component from
[sts-q's Oberon collection](https://codeberg.org/sts-q/oberon). This directory
also contains its text, string, colour and system utilities. They are built
locally for the examples, not installed as VOC libraries.

These are component modules, not a complete editor application.
The [`Keys` example](../Keys.Mod) uses the terminal utilities;
the [`Kbd` library](../../../../ports/sts-q/oberon/readme.md) is separate.

## Building

Build VOC first with `make` at the repository root, then:

```sh
make -C src/examples/libraries/sts-q/editor
make -C src/examples/libraries/sts-q/editor test
```

The first command compiles the modules, including `Viewer.o`, into
`build/examples/libraries/sts-q/editor/2`. The second tests the utility routines,
screen construction and terminal cleanup. It does not start the editor.
Use `MODEL=C` for model C, `VOCROOT` for another VOC build, or `BUILD` for
another output directory.

`Viewer` contains editor-specific paths, autosaving and external commands.
Read those parts before using it in an application. The system adapter uses
a fixed UTC+2 offset for `TimeValues`, and its 32-bit Unix timestamps are
limited to dates before 2038. `Random` is not a cryptographic generator.

The sources are [GPL-3.0](LICENSE). Source revisions and porting details are in
[`PORT.toml`](../../../../ports/sts-q/oberon/PORT.toml).
