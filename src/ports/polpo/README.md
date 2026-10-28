# Picture codecs for VOC

Native Oberon-2 PNG, JPEG and GIF readers and writers from Polpo. `PNG0`,
`JPEG0` and `GIF0` expose file-rider interfaces, image information and RGBA pixel
buffers. The implementation modules are unchanged from their pinned upstream
releases; each package records its source and licence in `PORT.toml`.
Package READMEs retain the original upstream documentation; the commands below
describe the VOC build and console interfaces.

The model-2 conventional and modular library builds include the codecs and
the console modules `png`, `jpeg` and `gif`. `PictureArgs` supplies an argument
cursor over VOC's `Args`; console output uses `Out`.

```sh
make -C src/ports/polpo test VOC="$PWD/install/bin/voc"
make -C src/tools/pictures VOC="$PWD/install/bin/voc"
```

The standalone tools accept commands such as:

```sh
build/pictures/PngCmd Info picture.png
build/pictures/PngCmd ToPAM picture.png picture.pam
build/pictures/JpegCmd FromPNM picture.ppm picture.jpg 90
build/pictures/GifCmd Copy picture.gif copy.gif
```

Full Unix builds install the tools as `voc-png`, `voc-jpeg` and `voc-gif`.
Run a tool without arguments for its command list. Loadable modules expose the
same operations as `png.Info`, `jpeg.FromPNM`, `gif.Copy` and related commands.

Tests replay the original PNG, JPEG and GIF files and CRC lists unchanged:
338 PNG checks, 70 JPEG checks and 39 GIF checks. The zlib regression program
also checks 14 compression/decompression cases through one megabyte, including
stored blocks and exact-sized output buffers. The shared zlib fixes come from
Polpo commits `f802f9b`, `0fcad10` and `d34509f`; VOC's remaining interfaces and
read-only exports are preserved. Tests pass on x86-64 Linux with GCC/C23,
Clang/C23, TCC and Clang ASan/UBSan, and with shared modules. The sanitizer
profile keeps the conservative core uninstrumented and excludes generated-C
function-type checking, following VOC's existing sanitizer configuration.
Broader adversarial image review and native
Windows testing remain pending.
