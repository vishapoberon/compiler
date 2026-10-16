# Snake (Odzik)

A Snake game by Tigran Martirosyan, using raylib.
Source: <https://github.com/tmartiro/voc-snake>. Licence: [MIT](LICENSE).

Build VOC with `make` at the repository root first. You also need `pkg-config`
and raylib development files: `libraylib-dev` on Debian or `media-libs/raylib`
on Gentoo. From the repository root:

```sh
make -C src/examples/games/snake
make -C src/examples/games/snake run
```

`make run` opens the game window. Use the arrow keys to move and Escape to quit.
If hardware rendering is unavailable, try Mesa's software renderer:

```sh
LIBGL_ALWAYS_SOFTWARE=1 make -C src/examples/games/snake run
```

The raylib binding is in `src/ports/tmartiro/raylib`; its
[`PORT.toml`](../../../ports/tmartiro/raylib/PORT.toml) records the source
revision and porting changes.
