#### (Work in progress)

### Porting to a new platform

Porting to a new 32 or 64 bits platform is usually automatically handled
by `make full`:

  -  The makefile compiles `src/tools/make/configure.c` with the
     platform's default C compiler.
  -  `configure.c` determines which types to use for 32 and 64 bit
     variables, and their alignment.
  -  `configure.c` uses a number of strategies to determine the
     operating system it is running on and what the appropriate
     installation directory will be.
  -  `configure.c` sets makefile variables that are used to select
     which of 5 sets of preprepared C source files to build to create
     the bootstrap compiler.

On most systems this will be sufficient for `make full` to build
and install the compiler and libraries.

`make full` will terminate with a message such as:

`--- Branch v2docs freebsd gcc LP64 confidence tests passed ---`

#### Updating configure.c

It should only be necessary to change `configure.c` if it
cannot determine the correct install directory.

In this case add code to `src/tools/make/configure.c`'s
function `determineOS()` to set the `os` variable to the name
of the new OS platform.

The following variables are also set by `determineOS()` to the
followind defaults:

variable     | set to                 | example
--------     | ------                 | -------
`platform`   | Base platform          | `"unix"`
`binext`     | Binary file extension  | `""`
`staticlink` | Static linking option  | `"-static"`

If your new platform does not support static removing, set the
`staticlink` variable to `""`.

Then modify `determineInstallDirectory()` to select the correct
instalation root based on the changes you have made to `determineOS()`.

The `platform` variable selects which variety of the Platform
module is compiled. Vishap provides two varieties, one specific
to the Windows API (`Platformwindows.Mod`), and one suitable for
Unix-like systems including Linux, BSD, Android and cygwin
(`Platformunix.Mod`).


#### How to add a new compiler option

 - Define it in OPM as a constant before defopt is defined.
 - Define a BOOLEAN variable in OPM which will describe if setting is set.
 - Add handling of a new option in OPM.ScanOptions
 - Set your BOOLEAN value in OPM.OpenPari (or in ScanOptions, after the
   CASE) so you can check it later.
 - Check your boolean when necessary, (see useParFile in OPM.GetOptions)
 - Add it in OPC.GenHeaderMsg function.

#### Known bugs

When using SYSTEM.LSH(s, n) where s is SET,
the C compiler generates an error like
`error: duplicate 'unsigned'`,
that's because SET is defined as unsigned in SYSTEM.h,
while LSH is defined in SYSTEM.h as ((t)((unsigned t)(x)<<(n))),
and it makes not possible to make SYSTEM.LSH with type SET.

I don't want to prohibit it at the parser level
because C backend is only one of possible backends.

The solution currently is to cast set type to longint before lsh-ing it.
And then casting it back to set if necessary.
