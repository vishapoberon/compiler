## Cross Platform Compatibility and Basic Type Sizes in Vishap Oberon

###### Abstract

Vishap Oberon needs to support 32 and 64 bit machine architectures. 16 and
possibly 8 bits would be good too.

Currently Vishap Oberon has different INTEGER, LONGINT and SET sizes on 16
and 32 bit architectures. While this enables memory management code to use
LONGINT on all architectures, it breaks library and user code which makes
assumptions about type sizes.

The goal is to specify changes to the Vishap compiler and library to allow C
code generation for multiple machine architectures without breaking existing
code, and to allow serialized data to be interchangeable between machine
architectures.

###### Motivation

Current type sizes are loosely specified and vary between implementations. There
are conflicting general assumptions, for example: that LONGINT is large enough
to contain any machine address; but also that LONGINT always take 32 bits when
serialised to files. (See Oakwood guidelines appendix A 1.2.5.4.)

The compiler has ended up with a number of INTEGER types, each with its own
set of code to handle declaration, access, storage etc. There is a good
opportunity to refactor and simplify the current duplicated code.

Neither C's basic types, nor Oberon's are fixed in size. Yet for cross platform
compatability we need fixed size types.

###### Basis of implementation - integers and sets

In the generated C code we use these types for all integer and set variables:

| Unsigned    | Signed      | Sets   |
| ----------- | ----------- | ------ |
| INTEGER_U8  | INTEGER_S8  | SET_8  |
| INTEGER_U16 | INTEGER_S16 | SET_16 |
| INTEGER_U32 | INTEGER_S32 | SET_32 |
| INTEGER_U64 | INTEGER_S64 | SET_64 |

SYSTEM.H uses conditional compilation to derive these types from the types
available in the C compiler we are building on.

Then, with suitable compiler options we control the mapping of compiler types
to these C types.

There are three strategies that clients may wish to use:

1) Emphasizing compatability with serialised data and existing code. Here
   we fix Oberon type sizes across platforms, and introduce a new LONG64 type
   as follows:

   | Oberon type | Size             |
   | ----------- | ---------------- |
   | BOOLEAN     | 8  bits          |
   | BYTE        | 8  bits unsigned |
   | SHORTINT    | 8  bits signed   |
   | INTEGER     | 16 bits signed   |
   | LONGINT     | 32 bits signed   |
   | SET         | 32 flag bits     |  
   | LONG64      | 64 bits signed   |

   This gives a set of sizes that are available on all platforms (even SDCC
   supports 64 bit ints), and which have fixed characteristics (e.g. the size of
   character array sufficient to support any LONGINT values is fixed.)

   Note that these sizes match current Vishap Oberon behaviour on x86.

2) Emphasizing performant maxima. Here we make e.g. LONGINT the largest
   efficient size available. On x86 we stick with the sizes as above, but for
   x64 we make changes to INTEGER, LONGINT and SET as follows:

   | Oberon type | Size on x64      |
   | ----------- | ---------------- |
   | INTEGER     | 32 bits signed   |
   | LONGINT     | 64 bits signed   |
   | SET         | 64 flag bits     |  

3) Supporting system code, especially memory management.

   With SYSTEM imported, we extend the parsing of type INTEGER to accept a
   subsequent qualifier which may be U8, S8, U16, S16, U32, S32, U64, S64 or
   ADDRESS.

   Thus the type `INTEGER ADDRESS` takes over the role of `LONGINT` in existing
   memory management code. The compiler will map `INTEGER ADDRESS` to the
   relevant `INTEGER_U32` or `INTEGER_U64` in generated C code.

   Additionally the fixed size qualifiers U8, S8, U16, etc. allow the writing of
   Oberon source code that generates the same C code regardless of compilation
   options used.

###### Cross platform libraries

Many integral input parameters are currently coded as LONGINT with the intention
of accepting any size of integer. E.g. Texts.WriteInt. All such code needs
upgrading to accept LONG64 with implementation changes where necessary to
account for the larger values. Boring, but straightforward.

Some integral output parameter are currently coded as `VAR LONGINT`, for example
the integer value field `i` in RECORD type `Scanner`. This is a problem:

Assuming scenario 1 - LONGINT is always 32 bits.

  - If retained as LONGINT, Scanner won't be able to handle 64 bit integers.
  - If changed to LONG64, existing code will compile with type compatibility
    errors.

So neither option is possible on its own.

The simplest workaround is to add a new field `l` and a new scanner class
Long64 (similar to the pair of REAL and LONGREAL values already in Scanner).

Existing code will continue to work with values in the 32 bit range (which is
OK, because that's all the existing code can generate). New code can allow for
thye LongReal case.

(Ugly but workable).

Oakwood says that INTEGER must be stored as 2 bytes little endian, so Files.Mod
must use 16 bits on file for Files.ReadInt and Files.WriteInt. So what happens
in scenario 2 above? Since INTEGER is 32 bits in scenario 2, it would be
necessary to call Files.WriteLInt Files.ReadLInt. This is not obvious, and will
need the coder to work around the apparent type incompatibility.  

If only the type compatibility of passing a smaller integer variable to a larger
value parameter also worked for a larger var parameter.

Would this be possible?

e.g.

```Modula-2
  PROCEDURE p(VAR x: LONGINT); BEGIN ... END p;

  PROCEDURE q;
  VAR r: INTEGER;
  BEGIN p(r) END q;
```

q passes an `INTEGER` to the `VAR x: LONGINT` parameter of p. Normally this
would be a type compatability error.

If we want to defer value range checking until runtime, the compiler would have
to behave as if q was written with a temp LONGINT variable like this:

```Modula-2
  PROCEDURE q;
  VAR r: INTEGER; temp: LONGINT;
  BEGIN p(temp); r := SHORT(temp) END q;
```

Not simple enough.


###### IMPORT SYSTEM

With SYSTEM imported, we allow the type INTEGER to be followed by a size and
sign specification consiting of a letter (U for unsigned or S for signed)
followed by a numeric bit count which may be 8, 16, 32 or 64. Additionally
INTEGER may be followed by the word ADDRESS to request an unsigned integer type
of the same size as a machine address.

Thus we could define

###### Not supported

This solution does not seek to handle architectures such as the 8086/80286 where
a generalised address is not a single numeric value. TopSpeed Modula handled
this nicely, but we don't go that far.
