## TODO
 - Organise into summary and per-platfrom sections
   - with subsections for linux and BSD variants
 - Add pre-requisites. E.g. static library support.

#### Building and installation summary

1. git clone https://github.com/dcwbrown/olang
2. cd olang
3. make full

Since 'make full' will install the compiler and libraries, it needs root (unix) or administrator (windows) privileges.

| System                       | Install dir                            | Access required                |
| -----------------------      | -------------------------------------- | ------------------------------ |
|  Linux                       | /opt/voc                               | Needs root except under cygwin |
|  BSD                         | /usr/local/share/voc                   | Needs root                     |
|  Windows (mingw or Visual C) | %ProgramFiles[(X86)]%                  | Needs administrator            |
|  Termux (android)            | /data/data/com.termux/files/opt/voc    |                                |


#### 32 and 64 bit

The size of compiler built is determined by the C compiler that runs, which is in turn determined by
the shell or command prompt configuration you are running under.

The following Oberon types are independent of compiler size:

| Types          | Size   |
| -----          | -------|
| CHAR, SHORTINT | 8 bit  |
| REAL           | 32 bit |
| LONGREAL       | 64 bit |

The following type sizes follow the built compiler size:

| Types          | 32 bit builds | 64 bit builds |
| -----          | ------------- | ------------- |
| INTEGER        | 16 bit        | 32 bit        |
| LONGINT, SET   | 32 bit        | 16 bit        |

Note that many library modules have been written with the assumption that INTEGER
is 16 bit and LONGINT 32 bit, therefore they will only work in 32 bit builds.

#### Which compiler? (gcc vs clang)

By default make uses the compiler defined in variable CC. This can be overriden by running 'export CC=gcc' or 'export CC=clang' from the command line before running make.

*Note*: be sure to run 'make clean' any time you change the value of CC. Otherwise directories will be mixed up.

*Note*: Darwin (MAC OS/X) redirects gcc to clang, so specifying CC=gcc still builds clang binaries under Darwin.


#### Building on Windows

There are three ways to build on Windows:

| Type               | How to build                                             | Compiled binary uses: |
| -----------        | -------                                                  | --------------------- |
| cygwin             | Use 'make' from cygwin bash shell.                       | cygwin.dll            |
| mingw under cygwin | Set CC for mingw then use 'make' from cygwin bash shell. | Win32 API             |
| Visual C           | Use 'make.cmd' from Visual C command prompt.             | Win32 API             |

##### mingw on cygwin

To use mingw, install the correct sized package and export CC= the compiler name:

 - For 32 bit cygwin

   - use setup-x86.exe to add the package mingw64-i686-gcc-core.
   - run 'export CC=i686-w64-mingw32-gcc' then 'make full'

 - For 64 bit cygwin

   - use setup-x86\_64.exe to add the package mingw64-x86\_64-gcc-core.
   - run 'export CC=x86_64-w64-mingw32-gcc' then 'make full'

(*Note*: Don't be put off by the name 'mingw64' in the 32 bit package.)

##### Microsoft Visual C compiler

Use the free command line Visual C++ compiler. At the time of writing it can be
downloaded here:

  http://landinghub.visualstudio.com/visual-cpp-build-tools

For example (Windows 10):

Start an adminstrator command prompt from the start button as follows:

    Start / All apps / Visual C++ Build Tools

Right click on

    Visual C++ 2015 x86 Native Build Tools Command Prompt

or

    Visual C++ 2015 x64 Native Build Tools Command Prompt

And select

    More / Administrative Command Prompt

#### A 'Hello' application

Anything appended to Oberon.Log is automatically displayed on the console, so the
following conventional Oberon program will display 'Hello.':

    MODULE hello;
      IMPORT Oberon, Texts;
      VAR W: Texts.Writer;
    BEGIN
      Texts.OpenWriter(W);
      Texts.WriteString(W, "Hello."); Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf)
    END hello.

Alternatively the Console may be accessed directly as follows:

    MODULE hello;
      IMPORT Console;
    BEGIN
      Console.String("Hello."); Console.Ln;
    END hello.

Compile as follows:

    voc hello.mod -m

The -m parameter tells voc that this is a main module, and to generate an
executable binary.

Execute as usual on Linux ('./hello') or Windows ('hello').

#### How make adapts to each platform

On all platforms other than Visual C on Windows, make runs from a bash shell,
using makefile in the enlistment root, and vishap.make in the src/tools/make
directory.

For Visual C only, there is a slightly cut down implementation of the same
functionality in the file 'make.cmd' in the enlistment root.

In all cases src/tools/make/configure.c is executed to determine all
platform dependent parameters: it generates two files:

 - Configuration.Make: a set of environment variables included by the makefile
 - Configuration.Mod: An Oberon MODULE containing just configuraton constants.

The following examples correspond to a 32 bit Ubuntu build using GCC:

Configuration.Make:

    OLANGDIR=/home/dave/projects/oberon/olang
    COMPILER=gcc
    OS=ubuntu
    VERSION=1.2
    ONAME=voc
    DATAMODEL=ILP32
    INTSIZE=2
    ADRSIZE=4
    ALIGNMENT=4
    INSTALLDIR=/opt/voc
    PLATFORM=unix
    BINEXT=
    COMPILE=gcc -fPIC -g
    STATICLINK=-static
    LDCONFIG=if echo "/opt/voc/lib" >/etc/ld.so.conf.d/libvoc.conf; then ldconfig; fi

Configuration.Mod:

    MODULE Configuration;
    CONST
      name*        = 'voc';
      versionLong* = '1.2 [2016/06/11] for gcc ILP32 on ubuntu';
      intsize*     = 2;
      addressSize* = 4;
      alignment*   = 4;
      objext*      = '.o';
      objflag*     = ' -o ';
      linkflags*   = ' -L"';
      libspec*     = ' -l voc';
      compile*     = 'gcc -fPIC -g';
      dataModel*   = 'ILP32';
      installdir*  = '/opt/voc';
      staticLink*  = '-static';
    END Configuration.
