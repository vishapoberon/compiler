![Build status](http://brownsmeet.com/build-status.svg)

# Ѵishap Oberon

[Ѵishap Oberon](http://oberon.vishap.am) is a free and open source (GPLv3)
implementation of the Oberon-2 language and libraries for use on
conventional operating systems such as Linux, BSD, Android, Mac and Windows.

Vishap's Oberon Compiler (voc) uses a C backend (gcc, clang or msc) to compile
Oberon programs under Unix, Mac or Windows. Vishap Oberon includes
libraries from the Ulm, oo2c and Ofront Oberon compilers, as well as
default libraries complying with the Oakwood Guidelines for Oberon-2 compilers.

###### Contents

> [Installation](#installation)  
> [A 'Hello' application](#a-hello-application)  
> [Licensing](#licensing)  
> [Platform support and porting](#platform-support-and-porting)  
> [Language support and libraries](#language-support-and-libraries)  
> [History](#history)  
> [Roadmap](#roadmap)  
> [Contributors](#contributors)  
> [Origin of the name "Ѵishap Oberon"](#origin-of-the-name-Ѵishap-oberon)  
> [References](#references)


## Installation

###### Prerequisites

| Platform               | Packages                                                           |
| ---------              | ------------                                                       |
| Debian/Ubuntu/Mint ... | apt-get install git                                                |
| Fedora/RHEL/CentOS ... | yum install git gcc glibc-static                                   |
| FreeBSD/OpenBSD/NetBSD | pkg install git                                                    |
| Cygwin                 | use setup-x86[_x64] to add packages git, make and gcc-core         |
| Darwin                 | run 'git' at the command line and accept the prompt to install it. |

More details, including for MingW and MS C, in [Installation](/doc/Installation.md).

###### Build and install

1. `git clone https://github.com/vishaps/voc`
2. `cd voc`
3. `[sudo] make full`

Since 'make full' will install the compiler and libraries, it needs root (unix) or administrator (windows) privileges.

###### PATH environment variable

Set your path to the installed compiler binary location as reported
by make full, e.g.

| System    | Set path                               |
| --------- | -------------------------------------- |
|  Linux    | `export PATH="/opt/voc/bin:$PATH"`             |
|  BSD      | `export PATH="/usr/local/share/voc/bin:$PATH"` |
|  Windows  | See [Installation](/doc/Installation.md) |
|  Termux   | `export PATH="/data/data/com.termux/files/opt/voc/bin:$PATH"` |

Also see [Installation](/doc/Installation.md).

## A 'Hello' application

Anything appended to Oberon.Log is automatically displayed on the console, so the
following conventional Oberon program will display 'Hello.':

```Modula-2
MODULE hello;
  IMPORT Oberon, Texts;
  VAR W: Texts.Writer;
BEGIN
  Texts.OpenWriter(W);
  Texts.WriteString(W, "Hello."); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf)
END hello.
```

Alternatively the Console may be accessed directly as follows:

```Modula-2
MODULE hello;
  IMPORT Console;
BEGIN
  Console.String("Hello."); Console.Ln;
END hello.
```

Compile as follows:

    voc hello.mod -m

The -m parameter tells voc that this is a main module, and to generate an
executable binary.

Execute as usual on Linux ('./hello') or Windows ('hello').


Also see [Compiling](/doc/Compiling.md).

## Licensing

Vishap Oberon's frontend and C backend engine is a fork of Josef Templ’s Ofront, which has been released
under the FreeBSD License. Unlike Ofront, Vishap Oberon does not include the Oberon v4 environment.

The Ulm Oberon Library  and the Ooc libraries are distributed under GPL. Proprietry code
using these libraries may not be statically linked.

Voc tools are distributed under GPLv3.

Most of the runtime in libVishapOberon is distributed under GPLv3 with runtime exception.


## Platform support and porting

Vishap Oberon supports 32 and 64 bit little-endian architectures including Intel x86 and x64, arm and ppc.

It compiles under gcc, clang and Microsoft Visual C.

Installation supports GNU/Linux, MAC OSX, BSD and Windows (native and cygwin).

A C program (src/tools/make/configure.c) detects the details of the C compiler
and operating system on which it is running. In most cases it will automatically
determine all that is needed for the port to a new platform. and 'make full'
will just work.

In some cases manual work will be required:

 - If configure.c cannot recognise the operating system on which it is running
   a few lines will need to be added to detect and set the make variables
   correctly.
 - If porting to a system that does not provide a Unix style API, it will be
   necessary to implement a new variant of Platform.Mod providing the same
   interface as Platformunix.Mod and Platform Windows.Mod.

For details, see [Porting](/doc/Porting.md).

## Language support and libraries

Vishap Oberon supports the Oberon 2 programming language, including type-bound procedures.

It also supports some features of Oberon-07.

Vishap Oberon comes with libraries easing the porting of code from the major
Oberon systems:

 - Oberon V4 and S3 compatible library set.

 - ooc (optimizing oberon-2 compiler) library port.

 - Ulm’s Oberon system library port.

Some other freely redistributable libraries are available as a part of voc distribution.

See also [Features](/doc/Features.md).

## History

See [History](/doc/History.md).

## Roadmap

See [Roadmap](/doc/Roadmap.md).

## Contributors

Originally developed as a cross platform implementation of the
Oberon system by Joseph Templ.

Updated for 64 bit support, refactored as a standalone compiler and brought
to new platforms by Norayr Chilingarian.

Build process simplified for more platform support and bugs fixed by David
C W Brown.

## Origin of the name "Ѵishap Oberon"

###### Ѵishap

Vishaps are dragons inhabiting the Armenian Highlands.
We decided to name the project “Vishap” because ties between compilers and dragons have ancient traditions.

Also, Vishaps are known in tales, fiction. [This page](http://blog.fogus.me/2015/04/27/six-works-of-computer-science-fiction/) refers to some technologies as “computer science fiction”. Among them to Oberon. This brings another meaning, Oberon is like aliens, ghosts. And Vishaps.

###### Oberon - System and Programming Language

Oberon is a programming language, an operating system and a graphical
user interface. Originally designed and implemented by by Niklaus Wirth and
Jürg Gutknecht at ETH Zürich in the late 1980s, it demonstrates that the
fundamentals of a modern OS and GUI can be implemented in clean and simple code
orders of magnitude smaller than found in contemporary systems.

The Oberon programming language is an evolution of the Pascal and Modula
languages. While it adds garbage collection, extensible types and (in
Oberon-2) type-bound procedures, it is also simplified following the principals
of Einstein and Antoine de Saint-Exupéry:

>  Make it as simple as possible, but not simpler. (Albert Einstein)

>  Perfection is finally attained not when there is no longer anything to add, but
>  when there is no longer anything to take away. (Antoine de Saint-Exupéry,
>  translated by Lewis Galantière.)

## References

###### Oberon
 - [The History of Modula-2 and Oberon](http://people.inf.ethz.ch/wirth/Articles/Modula-Oberon-June.pdf)
 - [The Programming Language Oberon](https://www.inf.ethz.ch/personal/wirth/Oberon/Oberon.Report.pdf)
 - [Project Oberon: The Design of an Operating System and Compiler ](http://www.ethoberon.ethz.ch/WirthPubl/ProjectOberon.pdf)
 - [Oberon - the Overlooked Jewel](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.90.7173&rep=rep1&type=pdf)

###### Oberon 2
 - [Differences between Oberon and Oberon-2](http://members.home.nl/jmr272/Oberon/Oberon2.Differences.pdf)
 - [The Programming Language Oberon-2](http://www.ssw.uni-linz.ac.at/Research/Papers/Oberon2.pdf)
 - [Programming in Oberon. Steps beyond Pascal and Modula](http://www.ethoberon.ethz.ch/WirthPubl/ProgInOberonWR.pdf)
 - [The Oakwood Guidelines for Oberon-2 Compiler Developers](http://www.math.bas.bg/bantchev/place/oberon/oakwood-guidelines.pdf)

###### Oberon 07
 - [Difference between Oberon-07 and Oberon](https://www.inf.ethz.ch/personal/wirth/Oberon/Oberon07.pdf)
 - [The Programming Language Oberon-07](https://www.inf.ethz.ch/personal/wirth/Oberon/Oberon07.Report.pdf)
 - [Programming in Oberon - a Tutorial](https://www.inf.ethz.ch/personal/wirth/Oberon/PIO.pdf)

###### Links
 - [Niklaus Wirth's personal page at ETH Zurich](https://www.inf.ethz.ch/personal/wirth/)
 - [ETH Zurich's Wirth publications page](http://www.ethoberon.ethz.ch/WirthPubl/)
 - [Oberon: Steps beyond Pascal and Modula](http://fruttenboel.verhoeven272.nl/Oberon/)
