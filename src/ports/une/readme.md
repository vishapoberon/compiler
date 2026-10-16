# Carlos Une's ports

| Package | Description | Licence | Example |
| --- | --- | --- | --- |
| `oberon-cairo` | Cairo graphics binding | LGPL-2.1 or MPL-1.1 | [Image rendering](../../examples/gui/cairo/readme.md) |
| `oberon-ip` | IPv4 address and subnet calculations | GPL-3.0 | [Subnet calculator](../../examples/network/ip/readme.md) |
| `oberon-stars` | Coordinates, precession, nutation and star positions | GPL-3.0 | [Star positions](../../examples/libraries/stars/readme.md) |

Build VOC first with `make` at the repository root. Then build an example:

```sh
make -C src/examples/gui/cairo
make -C src/examples/network/ip
make -C src/examples/libraries/stars
make -C src/test/ports/une test
```

Cairo requires `pkg-config` and Cairo development files, such as Debian's
`pkg-config libcairo2-dev`. The IP and astronomy examples need no additional
packages. The example builds compile their library modules; these modules are
not included in `libvoc`.

To build Cairo as a shared module:

```sh
make modular-library-bindings WITH_X11=0 WITH_RAYLIB=0
make modular-library-bindings-test WITH_X11=0 WITH_RAYLIB=0
```

The package READMEs describe the original upstream projects. For building
within VOC, use the commands above or the linked example instructions.
Each package's `PORT.toml` lists its source revision and porting changes.
