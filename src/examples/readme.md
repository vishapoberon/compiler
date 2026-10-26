# Examples

Build VOC first by running `make` at the repository root. Then choose an
example:

```sh
make -C src/examples/language/events
make -C src/examples/language/events run
```

The first command builds it; the second runs it. To pass arguments, use
`make run ARGS='hello 42'` in the example directory. Examples are built
separately from the compiler and libraries.

## What's here

| Directory | Example | Requirements beyond VOC |
| --- | --- | --- |
| `language/events` | Callbacks | None |
| `libraries/files`, `texts`, `ooc`, `md5` | File, text, argument and hashing interfaces | None |
| `libraries/vt100` | Terminal output | A terminal |
| `libraries/sts-q` | Keyboard and mouse input | Unix terminal |
| [`libraries/sts-q/editor`](libraries/sts-q/editor/readme.md) | sts-q's editor components; modules only, no executable | Unix |
| [`libraries/stars`](libraries/stars/readme.md) | Star positions | None |
| [`network/ip`](network/ip/readme.md) | IPv4 subnet calculator | None |
| [`network/xmpp-publish`](network/xmpp-publish/readme.md) | Publish a Unicode XMPP microblog entry | Linux; XMPP account with PEP support |
| `servers/sockets` | Forking socket server | Unix |
| `utilities/sound` | Audio generation | `oggenc` and `ogg123` |
| `gui/x11/simple`, `gui/x11/ifs` | XYplane drawing | X11 development files; a display to run |
| `games/mines`, `pacman`, `tetris`, `tron`, `vier` | X11 games | X11 development files; a display to run |
| `gui/newt` | Text-mode forms | libnewt development files; a terminal |
| `gui/gtk` | GTK/libglade demo | GTK 2 and libglade-2.0 development files |
| [`gui/cairo`](gui/cairo/readme.md) | Render an image | `pkg-config` and Cairo development files |
| [`games/snake`](games/snake/readme.md) | Tigran Martirosyan's Odzik | `pkg-config` and raylib development files; a display to run |
| `module-tutorial`, [`shared-libraries`](shared-libraries/readme.md) | Load and call shared modules | GNU make, ELF Unix, case-sensitive filesystem |

Licences are listed with the individual examples and their library sources.

## Compiler and output paths

The Makefiles use the compiler in this checkout's `install/bin`, with its
matching libraries. Build output goes to `build/examples/<path>/2`; resource
files stay beside the source.

Set `VOCROOT` to use another VOC build and `BUILD` to choose another output
directory:

```sh
make -C src/examples/language/events VOCROOT=/path/to/voc/install BUILD=/path/to/output
```

The shared defaults are in `src/tools/make/example.mk`. They also accept
`VOC`, `VOCLIBDIR`, `MODEL`, `CC`, `CFLAGS`, `LDFLAGS` and `LDLIBS`.
Most library examples use model 2. Model C has the core runtime and, on Unix,
terminal modules, but not the full library collection.

Graphics examples compile the bindings they need into their output directory.
The shared-module examples build a modular compiler and libraries under
`build/hresh`; set `HRESH_BUILD` to change that location.

## Build checks

```sh
python3 src/test/examples/test-builds.py
```

Add `--x11` to compile the X11 examples, or `--native` to test the shared-module
examples. These checks run only noninteractive programs; they do not start
servers, games, graphics windows or audio tools. GTK and newt are not covered.
