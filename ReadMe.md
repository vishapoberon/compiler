### 𝓥ishap Ѵishap Ꮙishap Oberon

Oberon is both a computer language, an operating system and a graphical
user interface. Originally designed and implemented by by Niklaus Wirth and
Jürg Gutknecht at ETH Zürich in the late 1980s, it demonstrates that the
fundamentals of a modern OS and GUI can be implemented in clean and simple code
orders of magnitude smaller than found in contemporary systems.

[𝓥ishap ⱱishap Ꮙishap Oberon](http://oberon.vishap.am) is a free and open source (GPLv3)
implementation of the Oberon-2 language compiler and libraries for use on
current operating systems such as Linux, BSD, Android, Mac and Windows.

The Oberon language is the logical evolution of the Pascal and Modula languages,
following the principals of Einstein and Antoine de Saint-Exupéry:

>  Make it as simple as possible, but not simpler. (A. Einstein)

>  Perfection is finally attained not when there is no longer anything to add, but
>  when there is no longer anything to take away. (Antoine de Saint-Exupéry,
>  Terre des Hommes, 1939, translated by Lewis Galantière.)

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

It can also compile programs written to the Oberon07 report.


#### Libraries

Vishap Oberon comes with libraries easing the porting of code from the major
Oberon systems:

 - Oberon V4 and S3 compatible library set.

 - ooc (optimizing oberon-2 compiler) library port.

 - Ulm’s Oberon system library port.

Some other freely redistributable libraries are available as a part of voc distribution.


#### Features

See [Features](/doc/Features.md).

#### Installation

See [Installation](/doc/Installation.md).

#### Compiling Oberon modules

See [Compiling](/doc/Compiling.md).

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

#### To be left out?

Work on other compatibility layers is in progress.
voc team also works on bindings to existing C/Pascal libraries.
