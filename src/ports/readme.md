# Ports

This directory contains libraries, bindings and tools from other Oberon
systems and projects, grouped by author or collection.

| Directory | Contents |
| --- | --- |
| `norayr/` | String utilities, collections, command-line options, TOML and networking libraries |
| [`sts-q/`](sts-q/readme.md) | JSON and terminal keyboard/mouse input |
| [`une/`](une/readme.md) | Carlos Une's Cairo, IPv4 and astronomy modules |
| `tmartiro/` | Tigran Martirosyan's raylib binding |
| `v4/`, `ooc/`, `oocX11/`, `ulm/`, `pow/`, `s3/` | Libraries from Ofront, oo2c, Ulm, POW! and ETH Oberon |
| [`xml/`](xml/README.md) | Native Oberon XML parsing, DTD validation, namespace builders and writing |
| [`punycode/`](punycode/README.md) | RFC 3492 Punycode, Unicode NFC and checked internationalized host names |
| [`xmpp/`](xmpp/README.md) | Unicode XMPP streams, stanzas and client negotiation; optional Linux TCP/TLS transport |
| [`picl/`](picl/readme.md) | Niklaus Wirth's PICL compiler |
| [`coco/`](coco/readme.md) | Coco/R from Native Oberon and the version with A. V. Shiryaev's additions |

Applications using these libraries are in [`src/examples`](../examples/readme.md).
Ofront's `Args` and `Console`, along with terminal utilities, are in
[`src/library`](../library/readme.md).

## Building

Run `make` at the repository root to build VOC and its libraries. The default
model-2 library includes `v4`, `ooc`, `punycode`, `xml`, `xmpp`, `ulm`, `pow`, `s3`, `base64`, `bdStrings`,
`strutils`, `lists`, `opts`, `toml` and `ssqJson`. Unix builds also include `Kbd`.
The IP and astronomy modules in `une/` are built with their examples instead.

To build the libraries as individual shared modules:

```sh
make modular-library
make modular-library-test
```

These targets require ELF Unix and use the VOC build in `install/`.
Linux networking libraries are included unless `WITH_NETWORK=0` is set.

The portable XMPP modules and native domain-name preparation build with the
normal library. Its Linux TCP/TLS driver builds through
`make -C src/ports/xmpp network`. See the package README for tests and the login
probe.

### Compiler tools

PICL and both Coco/R versions build separately using VOC in `install/`.
The default is model 2; set `MODEL=C` for model C. Tests need Python 3.

```sh
make -C src/ports/picl
make -C src/ports/coco/native  # Native Oberon version
make -C src/ports/coco/aixp    # Version with Shiryaev's additions
```

To build and run each tool's tests:

```sh
make -C src/ports/picl test
make -C src/ports/coco/native test
make -C src/ports/coco/aixp test
```

`make -C src/ports/coco` builds both Coco/R versions;
`make -C src/ports/coco test` builds and tests both.

Executables are `build/ports/picl/2/PICL`, `build/ports/coco/native/2/Coco`
and `build/ports/coco/aixp/2/Coco`. Each Coco/R build directory also contains
its scanner and parser frames; the `aixp` version includes a driver frame.
Run Coco/R from that directory with the grammar filename as its argument.

### Graphics bindings

X11, Cairo and raylib need additional development packages:

| Binding | Debian packages | Gentoo packages | Build switch |
| --- | --- | --- | --- |
| X11 | `libx11-dev` | `x11-libs/libX11` | `WITH_X11=0` |
| Cairo | `pkg-config libcairo2-dev` | `dev-util/pkgconf x11-libs/cairo` | `WITH_CAIRO=0` |
| raylib | `pkg-config libraylib-dev` | `dev-util/pkgconf media-libs/raylib` | `WITH_RAYLIB=0` |

Package availability depends on the distribution release. With the required
packages installed, build and test the bindings:

```sh
make modular-library-bindings
make modular-library-bindings-test
```

Use the switches to omit bindings you do not need. For example, to build only
Cairo:

```sh
make modular-library-bindings WITH_X11=0 WITH_RAYLIB=0
```

The bindings tests do not need a display. `libraries.list` and `bindings.list`
in `build/hresh/modules/2` list the built libraries and graphics bindings.

## Licences and source records

See each package's licence files and module headers. `libvoc` contains code
under several licences; VOC's runtime exception does not apply to every
bundled library. In particular, sts-q's `Json` and `Kbd` are GPL-3.0 without
that exception.

Each `PORT.toml` records the source repository, imported revision, selected
files and local changes. A blank revision means the original import has not
yet been traced. `kind` describes the package as a `library`, `bindings`,
`mixed` or `tool`; it does not determine which build includes it.

Some module names differ from upstream to avoid clashes. For example,
`StringBase64` is the string-oriented library used by HTTP, while `Base64` is
the ETH interface. ETH's `BIT`, `DES` and `TwoComplement` are in `s3/`.
`DES` uses the reversed-bit key convention required by VNC; it is obsolete
cryptography and should not be used for new protocols.
