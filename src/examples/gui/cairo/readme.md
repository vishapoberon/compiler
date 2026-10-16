# Cairo image example

Carlos Une's example renders an image to `oberon.png` using Cairo.

Build VOC with `make` at the repository root first. You also need `pkg-config`
and Cairo development files (`pkg-config libcairo2-dev` on Debian).
From the repository root:

```sh
make -C src/examples/gui/cairo
make -C src/examples/gui/cairo run
```

`make run` writes the image in `src/examples/gui/cairo`.

The [Cairo binding](../../../ports/une/oberon-cairo/readme.md) is available
under LGPL-2.1 or MPL-1.1, at your option. See the
[examples index](../../readme.md) for compiler and output-directory settings.
