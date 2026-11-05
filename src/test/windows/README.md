# Windows runtime and installation checks

VOC's Windows runtime discovers the executable through `GetModuleFileNameA`.
The compiler uses that directory to locate a staged installation's headers,
symbol files and libraries. MSVC installations contain `libvoc-O2.lib`; MinGW
installations contain `libvoc-O2.a`.

## Native MSVC check

Run `make.cmd` in a Visual Studio native-tools command prompt. The build ends
by compiling and running `CheckInstallation.Mod` for both `-O2` and `-OC` with
the staged compiler under `install\bin`. The check clears `VOCROOT`,
`VOCLIBDIR`, `OBERON` and `MODULES` locally to exercise installation discovery.
It also verifies executable-directory discovery in the resulting program.

To repeat that check after building:

```bat
make.cmd check
```

## Host-side boundary regressions

After a Unix `make`, run:

```sh
python3 src/test/windows/test-boundaries.py --model 88 --build build/windows-tests-88
python3 src/test/windows/test-boundaries.py --model 48 --build build/windows-tests-48
```

Use fresh output directories. These tests require Python 3 and a C compiler
with AddressSanitizer and UndefinedBehaviorSanitizer support. `--cc` selects
the C compiler and `--voc` selects the staged VOC binary.

The probes execute generated Windows C with mocked Win32 calls. They cover
drive-letter paths, spaces, UNC paths, root directories, truncated image
paths, all 256 child exit codes, process creation/wait failures, installation
discovery with `.lib` and `.a`, and Windows configuration defaults and overrides.
The process-status probe detects a 32-bit Win32 write into a 16-bit Oberon
`INTEGER` as a stack-buffer overflow.

The probes run on the host ABI. Native Windows builds remain necessary to
validate the complete MSVC or MSYS2/MinGW toolchain.
