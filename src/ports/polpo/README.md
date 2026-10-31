# Picture codecs for VOC

Native Oberon-2 PNG, JPEG and GIF readers and writers from Polpo. `PNG0`,
`JPEG0` and `GIF0` expose file-rider and bounded byte-array interfaces, image
information and RGBA pixel buffers. Each package records its pinned upstream
source, licence and VOC adaptations in `PORT.toml`. Original source hashes are
retained in `upstream-sha256.json`; adapted implementation hashes are recorded in
`voc-sha256.json`.
Package READMEs retain the original upstream documentation; the commands below
describe the VOC build and console interfaces.

The model-2 conventional and modular library builds include the codecs and
the console modules `png`, `jpeg` and `gif`. `PictureArgs` supplies an argument
cursor over VOC's `Args`; console output uses `Out`.

## Memory-only APIs

All three codecs export:

```oberon
ReadInfoBytes(data, length, info, res)
DecodeBytes(data, length, pixelLimit, image, res)
EncodeBytes(image, ..., maxBytes, data, length, res)
```

`data[0..length)` is the logical input prefix. Invalid lengths are rejected.
`pixelLimit` must be in `1..MaxPixels`; decoding checks it before allocating image
or component buffers. GIF checks the actual canvas, including frame offsets.
PNG checks chunk lengths against the remaining input before allocating chunks.

`EncodeBytes` takes the same quality argument as JPEG `Encode`, or compression
level as PNG `Encode`; GIF has no extra argument. It allocates a fixed-capacity
output buffer of `maxBytes` bytes. On success, only `data[0..length)` is valid;
the returned allocation can be larger than `length`. Exceeding the output limit
returns `tooLarge`, `data = NIL`, and `length = 0`. Invalid pixel buffers are
rejected before reading them.

These entry points use explicit `Files.NewMemory` / `Files.FromBytes` files.
They never create an OS file, register a finalizer for an OS descriptor, or spill
to temporary files. Input is copied, and output is returned without a second
copy. Pixel and output limits do not describe total process memory: decoders
also allocate bounded component, compression and scanline buffers.

The existing rider interfaces retain their signatures and default limits.
`Files.New("")` retains its buffered, potentially disk-backed behavior.

### Memory files

`Files.NewMemory(capacity)` creates a fixed-capacity, memory-only file;
`Files.FromBytes(data, length)` copies a logical prefix into one. Negative
capacities or invalid prefix lengths return `NIL`. Zero capacity is valid;
its backing allocation has one byte, but no byte may be written. Memory files
work with the existing rider read, write, seek, number and string operations.
Each `Write` or `WriteBytes` call that exceeds capacity is rejected without a
partial write, sets the rider's `res`, and sets `Files.MemoryFailed(file)` until
`Files.Purge(file)` clears it. `Close` and
`Register` do not persist memory files. `Files.MemoryData(file, length)` returns
the buffer and valid prefix; it returns `NIL` and length zero after a capacity
failure or for a regular file. The returned buffer shares storage with the file;
only its logical prefix is valid. `Files.IsMemory` distinguishes the two modes.

For example, this module writes and reads a string without creating an OS file:

```oberon
MODULE MemoryExample;
IMPORT Files;
VAR f: Files.File; r: Files.Rider; data: Files.Bytes;
  length: LONGINT; text: ARRAY 32 OF CHAR;
BEGIN
  f := Files.NewMemory(1024);
  Files.Set(r, f, 0); Files.WriteString(r, "hello");
  ASSERT(~Files.MemoryFailed(f));
  data := Files.MemoryData(f, length);
  ASSERT((data # NIL) & (length = 6));  (* includes the terminating zero *)
  Files.Set(r, f, 0); Files.ReadString(r, text);
  ASSERT(text = "hello")
END MemoryExample.
```

Rebuild the libraries and dependent programs and shared modules together when
upgrading: the `Files` record layout and codec symbol interfaces changed.

## Building and testing

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
Leak and fake-stack checking are disabled for the conservative collector.
Additional tests exercise memory-file boundaries and ordinary file compatibility,
and compare both APIs' metadata, errors and decoded pixels on every preserved
input. On Linux, when `strace` is available, the memory-only test also verifies
that no file-creation, temporary-file, or memory-file-descriptor syscalls occur.
Broader adversarial image review and native Windows testing remain pending.
