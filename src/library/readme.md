# Library modules

| Sources | Purpose |
| --- | --- |
| `Args.Mod`, `Console.Mod` | Command-line arguments and console output, from Josef Templ's Ofront |
| `terminal/` | `LineEditor` for line editing; `termios` and `UnixTermios` for Unix terminal settings |
| `misc/` | Other libraries, including `crt`, `Listen`, `MersenneTwister` and multidimensional arrays |

`make` at the repository root builds these into `libvoc`. `Args`, `Console`
and `misc` are available in model 2. The Unix terminal modules are available
in both model 2 (`-O2`) and model C (`-OC`).

For individual shared modules, use `make modular-library`.
`make modular-runtime` builds just the runtime and terminal modules.

See the module headers for authorship and licence terms. The core runtime is
in [`src/runtime`](../runtime/), other library collections are in
[`src/ports`](../ports/readme.md), and programs using them are in
[`src/examples`](../examples/readme.md).
