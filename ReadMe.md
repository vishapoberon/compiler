### Ѵishap Oberon

[Ѵishap Oberon](http://oberon.vishap.am) is a free and open source (GPLv3)
implementation of the Oberon-2 language compiler and libraries for use on
conventional operating systems such as Linux, BSD, Android, Mac and Windows.

Vishap's Oberon Compiler (voc) uses a C backend to compile
Oberon programs under Unix or Windows. Vishap Oberon includes
libraries from the Ulm, oo2c and Ofront Oberon compilers, as well as
default libraries complying with the Oakwood Guidelines for Oberon-2 compilers.

##### Oberon - System and Programming Language

Oberon is a programming language, an operating system and a graphical
user interface. Originally designed and implemented by by Niklaus Wirth and
Jürg Gutknecht at ETH Zürich in the late 1980s, it demonstrates that the
fundamentals of a modern OS and GUI can be implemented in clean and simple code
orders of magnitude smaller than found in contemporary systems.

The Oberon programming language is an evolution of the Pascal and Modula
languages, following the principals of Einstein and Antoine de Saint-Exupéry:

>  Make it as simple as possible, but not simpler. (Albert Einstein)

>  Perfection is finally attained not when there is no longer anything to add, but
>  when there is no longer anything to take away. (Antoine de Saint-Exupéry,
>  translated by Lewis Galantière.)

##### Build status (png)

![Build status (png)](http://brownsmeet.com/build-status.png)

##### Build status (svg)

![Build status (svg)](http://brownsmeet.com/build-status.svg)

#### Installation

##### Prerequisites

##### Build and install

1. `git clone https://github.com/vishaps/voc`
2. `cd voc`
3. `[sudo] make full`

Since 'make full' will install the compiler and libraries, it needs root (unix) or administrator (windows) privileges.

##### PATH environment variable

Set your path to the installed compiler binary location as reported
by make full, e.g.

| System    | Set path                               |
| --------- | -------------------------------------- |
|  Linux    | `export PATH="/opt/voc/bin:$PATH"`             |
|  BSD      | `export PATH="/usr/local/share/voc/bin:$PATH"` |
|  Windows  | See [Installation](/doc/Installation.md) |
|  Termux   | `export PATH="/data/data/com.termux/files/opt/voc/bin:$PATH"` |

Also see [Installation](/doc/Installation.md).

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


Also see [Compiling](/doc/Compiling.md).

#### Licensing

Vishap Oberon's frontend and C backend engine is a fork of Josef Templ’s Ofront, which has been released
under the FreeBSD License. Unlike Ofront, Vishap Oberon does not include the Oberon v4 environment.

The Ulm Oberon Library  and the Ooc libraries are distributed under GPL. Proprietry code
using these libraries may not be statically linked.

Voc tools are distributed under GPLv3.

Most of the runtime in libVishapOberon is distributed under GPLv3 with runtime exception.


#### Platform support

Vishap Oberon supports 32 and 64 bit little-endian architectures including Intel x86 and x64, arm and ppc.

It compiles under gcc, clang and Microsoft Visual C.

Installation supports GNU/Linux, MAC OSX, BSD and Windows (native and cygwin).

#### Language support

Vishap Oberon supports the Oberon 2 programming language, including type-bound procedures.

It also supports some features of Oberon-07.


#### Libraries

Vishap Oberon comes with libraries easing the porting of code from the major
Oberon systems:

 - Oberon V4 and S3 compatible library set.

 - ooc (optimizing oberon-2 compiler) library port.

 - Ulm’s Oberon system library port.

Some other freely redistributable libraries are available as a part of voc distribution.


#### Features

See [Features](/doc/Features.md).

#### Porting to new platforms

See [Porting](/doc/Porting.md).

#### History

See [History](/doc/History.md).

#### Roadmap

See [Roadmap](/doc/Roadmap.md).

#### Contributors

Originally developed as a cross platform implementation of the
Oberon system by Joseph Templ.

Updated for 64 bit support, refactored as a standalone compiler and brought
to new platforms by Norayr Chilingarian.

Build process simplified for more platform support and bugs fixed by David
C W Brown.

#### Origin of the name Vishap

𝓥ishap Ꮙishap ⱱishap

#### To be left out?

Work on other compatibility layers is in progress.
voc team also works on bindings to existing C/Pascal libraries.
