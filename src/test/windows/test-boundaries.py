#!/usr/bin/env python3
"""Test generated Windows runtime boundaries on a Unix host with mocked Win32 APIs.

Run after make: python3 src/test/windows/test-boundaries.py --build build/windows-tests
The C probes use AddressSanitizer to catch Win32 writes into undersized buffers.
They complement native Windows builds; they do not emulate Windows or MSYS2.
"""

import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--voc", type=Path, default=ROOT / "install/bin/voc")
parser.add_argument("--cc", default=os.environ.get("CC", "cc"))
parser.add_argument("--model", choices=("48", "88"), default="88", help="Windows bootstrap address size/alignment")
parser.add_argument("--build", type=Path, required=True, help="fresh output directory")
args = parser.parse_args()
build = args.build.resolve()
build.mkdir(parents=True, exist_ok=False)
voc = args.voc.resolve()
env = dict(os.environ)
for name in ("VOCROOT", "VOCLIBDIR", "OBERON", "MODULES", "CFLAGS", "LDFLAGS"):
    env.pop(name, None)
env["VOCROOT"] = str(voc.parent.parent)
env["VOCLIBDIR"] = str(voc.parent.parent / "lib")


def function(source, name):
    match = re.search(r"^[^\n;{}]*\b" + name + r"\s*\([^;{}]*\)\s*\{.*?^\}",
                      source, re.M | re.S)
    assert match, name
    return match.group()


def probe(name, source):
    c = build / (name + ".c")
    c.write_text(source)
    exe = build / name
    subprocess.run(shlex.split(args.cc) + ["-g", "-fsanitize=address,undefined",
                   "-fno-omit-frame-pointer", "-I", str(ROOT / "src/runtime"),
                   str(c), "-o", str(exe)], check=True)
    subprocess.run([str(exe)], check=True)


common = r'''
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "SYSTEM.h"
#undef __COPY
#define __COPY(s,d,n) do { assert(strlen((const char*)(s)) < (n)); strcpy((char*)(d),(const char*)(s)); } while (0)
#undef __X
#define __X(i,n,...) (assert((i)>=0 && (i)<(n)), (i))
#undef __RETCHK
#define __RETCHK abort()
void Modules_Halt(INT32 code) { fprintf(stderr, "unexpected halt %d\n", code); abort(); }
'''

platform = (ROOT / ("bootstrap/windows-" + args.model) / "Platform.c").read_text()
modules = (ROOT / ("bootstrap/windows-" + args.model) / "Modules.c").read_text()
macros = ["cleanupProcess", "createProcess", "getExitCodeProcess", "processInfo",
          "startupInfo", "waitForProcess", "executablePath"]
definitions = "\n".join(re.search(r"^#define Platform_" + name + r"\(.*$", platform, re.M).group()
                        for name in macros)
helpers = "\n".join(function(modules, "Modules_" + name) for name in (
    "CharCount", "Append", "AppendPart", "IsOneOf", "IsAbsolute", "Canonify",
    "IsFilePresent", "ExtractPart", "Trim", "FindBinaryDir"))
helpers = re.search(r"typedef\s+CHAR pathstring__\d+\[4096\];", modules).group() + "\n" + helpers
runtime_support = r'''
#define INTEGER INT16
typedef uint32_t DWORD;
typedef struct { int cb; } STARTUPINFO;
typedef struct { void *hProcess, *hThread; } PROCESS_INFORMATION;
#define INFINITE UINT32_MAX
typedef struct { int unused; } Platform_FileIdentity;
static ADDRESS *Platform_FileIdentity__typ;
static CHAR Platform_CWD[4096] = "D:/unrelated";
static INT16 Modules_ArgCount;
static const char *image = "D:\\Program Files\\voc\\bin\\voc.exe";
static DWORD child_status;
static int created = 1, waited, closed;
static DWORD GetModuleFileNameA(void *module, char *path, DWORD size) {
    size_t n = strlen(image);
    assert(module == NULL);
    if (!n) return 0;
    if (n >= size) { memcpy(path, image, size); return size; }
    strcpy(path, image); return (DWORD)n;
}
static int CreateProcess(void *a, char *cmd, void *b, void *c, int d, int e,
                         void *f, void *g, STARTUPINFO *si, PROCESS_INFORMATION *pi) {
    assert(si->cb == sizeof(*si)); return created;
}
static int WaitForSingleObject(void *handle, DWORD timeout) { return waited; }
static int GetExitCodeProcess(void *handle, DWORD *status) { *status = child_status; return 1; }
static void CloseHandle(void *handle) { ++closed; }
static void Modules_GetArg(INT16 n, CHAR *s, ADDRESS size) { abort(); }
static void Platform_GetEnv(CHAR *name, ADDRESS n, CHAR *s, ADDRESS size) { abort(); }
static INT16 Platform_IdentifyByName(CHAR *name, ADDRESS n, Platform_FileIdentity *id, ADDRESS *typ) { abort(); }
'''
probe("runtime", common + runtime_support + definitions + "\n" + function(platform, "Platform_ExecutablePath") + "\n" +
      function(platform, "Platform_System") + "\n" + helpers + r'''
int main(void) {
    CHAR path[1024], small[4];
    /* OS image discovery must work even without usable argv[0] or PATH. */
    Modules_FindBinaryDir(path, sizeof(path));
    assert(!strcmp((char*)path, "D:/Program Files/voc/bin"));
    image = "C:\\voc.exe";
    Modules_FindBinaryDir(path, sizeof(path));
    assert(!strcmp((char*)path, "C:/"));
    image = "\\\\server\\share\\bin\\voc.exe";
    Modules_FindBinaryDir(path, sizeof(path));
    assert(!strcmp((char*)path, "//server/share/bin"));
    assert(!Platform_ExecutablePath(small, sizeof(small)) && small[0] == 0);
    image = "";
    Modules_FindBinaryDir(path, sizeof(path));
    assert(path[0] == 0);
    for (int n = 0; n < 256; ++n) {
        child_status = n; closed = 0;
        INT16 result = Platform_System((CHAR*)"cl -c Module.c", 15);
        assert((uint16_t)result == n * 256);
        assert(closed == 2);
    }
    created = 0; closed = 0;
    assert(Platform_System((CHAR*)"missing", 8) == 127 * 256 && closed == 0);
    created = 1; waited = -1;
    assert(Platform_System((CHAR*)"cl", 3) == 127 * 256);
    puts("Windows image discovery and 32-bit process-status buffers passed");
}
''')

# Component Pascal's INTEGER is 32 bits, so its wait status must retain all
# 16 status bits rather than acquire the O2 model's signed 16-bit representation.
directory = build / "OC"
directory.mkdir()
subprocess.run([str(voc), "-SF", "-OC", str(ROOT / "src/runtime/PlatformNativewindows.Mod"),
                str(ROOT / "src/runtime/Platformwindows.Mod")],
               cwd=directory, env=env, check=True)
oc_platform = (directory / "Platform.c").read_text()
probe("runtime-OC", common + runtime_support.replace("#define INTEGER INT16", "#define INTEGER INT32") +
      definitions + "\n" + function(oc_platform, "Platform_System") + r'''
int main(void) {
    for (int n = 0; n < 256; ++n) {
        child_status = n;
        assert(Platform_System((CHAR*)"cl", 3) == n * 256);
    }
    puts("Windows Component Pascal process statuses passed");
}
''')

# Translate installation discovery for both native Windows compiler families.
# Only these generated functions are linked into the host probe.
configuration = (ROOT / "Configuration.Mod").read_text()
for compiler, suffix in (("msc", ".lib"), ("mingw", ".a")):
    directory = build / compiler
    directory.mkdir()
    config = configuration
    for key, value in {"name": "voc", "compiler": compiler, "os": "windows",
                       "libext": ".lib" if compiler == "msc" else "",
                       "installdir": "C:/configured", "libdir": "C:/configured/lib"}.items():
        config = re.sub(r"(" + key + r"\*\s*=\s*)'[^']*'", r"\g<1>'" + value + "'", config)
    (directory / "Configuration.Mod").write_text(config)
    subprocess.run([str(voc), "-SF", "Configuration.Mod", str(ROOT / "src/compiler/OPM.Mod")],
                   cwd=directory, env=env, check=True)
    opm = (directory / "OPM.c").read_text()
    probe("install-" + compiler, common + r'''
typedef struct { int unused; } Platform_FileIdentity;
static ADDRESS *Platform_FileIdentity__typ;
static CHAR Modules_BinaryDir[1024] = "D:/Program Files/voc/bin";
static CHAR OPM_InstallDir[1024], OPM_LibraryDir[1024];
static int have_library = 1;
static const char *override_root = "", *override_library = "";
static INT16 Strings_Length(CHAR *s, ADDRESS n) { return (INT16)strlen((char*)s); }
static void Strings_Append(CHAR *s, ADDRESS n, CHAR *d, ADDRESS size) {
    assert(strlen((char*)s) + strlen((char*)d) < size); strcat((char*)d, (char*)s);
}
static void Platform_GetEnv(CHAR *name, ADDRESS n, CHAR *value, ADDRESS size) {
    const char *text = !strcmp((char*)name, "VOCROOT") ? override_root : override_library;
    assert(strlen(text) < size); strcpy((char*)value, text);
}
static INT16 Platform_IdentifyByName(CHAR *name, ADDRESS n, Platform_FileIdentity *id, ADDRESS *typ) {
    const char *path = (char*)name;
    return !(strcmp(path, "D:/Program Files/voc/2/include/Oberon.h") == 0 ||
             strcmp(path, "D:/Program Files/voc/2/sym/Files.sym") == 0 ||
             (have_library && strcmp(path, "D:/Program Files/voc/lib/libvoc-O2SUFFIX") == 0));
}
'''.replace("SUFFIX", suffix) + function(opm, "OPM_IsProbablyInstallDir") + "\n" +
          function(opm, "OPM_FindLibraryDir") + "\n" +
          function(opm, "OPM_FindInstallDir") + r'''
int main(void) {
    OPM_FindInstallDir();
    assert(!strcmp((char*)OPM_InstallDir, "D:/Program Files/voc"));
    assert(!strcmp((char*)OPM_LibraryDir, "D:/Program Files/voc/lib"));
    override_library = "E:/libraries";
    OPM_FindInstallDir();
    assert(!strcmp((char*)OPM_LibraryDir, "E:/libraries"));
    override_library = ""; override_root = "D:/Program Files/voc";
    OPM_FindInstallDir();
    assert(!strcmp((char*)OPM_LibraryDir, "D:/Program Files/voc/lib"));
    override_library = "E:/libraries";
    OPM_FindInstallDir();
    assert(!strcmp((char*)OPM_LibraryDir, "E:/libraries"));
    override_library = ""; override_root = "E:/split/share/voc";
    OPM_FindInstallDir();
    assert(!strcmp((char*)OPM_InstallDir, "E:/split/share/voc"));
    assert(!strcmp((char*)OPM_LibraryDir, "C:/configured/lib"));
    override_root = "";
    have_library = 0;
    OPM_FindInstallDir();
    assert(!strcmp((char*)OPM_InstallDir, "C:/configured"));
    puts("Windows installation discovery passed");
}
''')

configure = (ROOT / "src/tools/make/configure.c").read_text()
globals_ = configure[configure.index("char builddate["):configure.index("void ParseOsRelease")]
for compiler in ("msc", "mingw"):
    platform_defines = '#define _WIN32\n#define optimize ""\n'
    platform_defines += ("#undef __GNUC__\n#define _MSC_VER 1951\n" if compiler == "msc"
                         else "#define __MINGW32__\n")
    probe("configure-" + compiler, common + platform_defines + globals_ + "\n" +
          "\n".join(function(configure, name) for name in (
              "determineOS", "determineCCompiler", "determineInstallDirectory", "determineInstallationPaths")) + r'''
static void paths(void) { determineInstallDirectory(); determineInstallationPaths(); }
int main(void) {
    oname = "voc";
    unsetenv("INSTALLDIR"); unsetenv("PREFIX"); unsetenv("BINDIR"); unsetenv("LIBDIR");
    setenv("ProgramFiles", "C:/Program Files", 1);
    setenv("ProgramFiles(x86)", "C:/Program Files (x86)", 1);
    determineOS(); determineCCompiler(); paths();
    assert(!strcmp(dynext, ".dll"));
    assert(!strcmp(bindir, "C:/Program Files/voc/bin") || !strcmp(bindir, "C:/Program Files\\voc/bin"));
    assert(!strcmp(libdir, "C:/Program Files/voc/lib") || !strcmp(libdir, "C:/Program Files\\voc/lib"));
    setenv("PREFIX", "D:/prefix", 1); paths();
    assert(!strcmp(bindir, "D:/prefix/bin") && !strcmp(libdir, "D:/prefix/lib"));
    setenv("INSTALLDIR", "D:/voc", 1); paths();
    assert(!strcmp(bindir, "D:/voc/bin") && !strcmp(libdir, "D:/voc/lib"));
    setenv("BINDIR", "D:/bin", 1); setenv("LIBDIR", "D:/lib", 1); paths();
    assert(!strcmp(bindir, "D:/bin") && !strcmp(libdir, "D:/lib"));
    puts("Windows configuration defaults and overrides passed");
}
''')

print("Windows boundary regressions passed")
