### Features

#### 32 bit and 64 bit systems vs integer, set and address size.

The Oberon language specification sets explicit lower bounds on the maximum and minimum
values supported by SHORTINT, INTEGER and LONGINT, and the maximum number of items supported
by SET.

Most Oberon systems implemented these lower bounds, however a few more recent systems allow
wider ranges of values.

While it may seem safe to compile code developed on earlier systems with the newer, larger
integer and set types, it is not. Some examples:

 - Code that uses MIN(INTEGER), MAX(INTEGER) etc. as a flag values will run into problems if
   it tries to store the flag value to a file using standard library functions. The Oakwood
   guidelines specify that INTEGER be stored in 16 bits on file regardless of it's size in
   memory*.

 - Code that assumes that INTEGER values wrap around at known values will fail. For example
   i: SHORTINT; ... i := 127; INC(i); will produce -128 on original systems, but +128 on
   systems with a larger SHORTINT representation.

 - Bit manipulation code that uses SYSTEM.VAL to access parts of values will access the
   wrong number of bits. For example, the implementation of REAL and LONGREAL library functions
   use SYSTEM.VAL(SET, realvalue) to access and change the sign, mantissa and exponent of REALs.

Therefore we provide compilation options to select the representation of SHORTINT, INTEGER, LONGINT and SET.

\* It makes sense for Oakwood to insist on fixed sizes for the standard types as this is a pre-requisite
for stable file exchange between different builds of applications, and between different applications following a standard file format.


#### Compiler options for integer and set sizes.

The -O2 and -OC compiler options select between the two most commonly used integer and set
type implementations.

| Type     | -O2 option (default) | -OC option |
| ---      | ---                  | ---        |
| SHORTINT | 8 bit                | 16 bit     |
| INTEGER  | 16 bit               | 32 bit     |
| LONGINT  | 32 bit               | 64 bit     |
| SET      | 32 bit               | 64 bit     |


The following Oberon types are independent of compiler size:

| Types    | Size                                  |
| -----    | -------                               |
| REAL     | 32 bit floating point                 |
| LONGREAL | 64 bit floating point                 |
| HUGEINT* | 64 bit signed integer                 |
| BYTE**   | 8 bit signed integer (-OC model only) |
| CHAR***  | 8 bit character                       |

\* The additional type HUGEINT is predefined as a 64 bit integer, providing 64 bit support even
in -O2 compilations.

\** The additional type BYTE is defined for -OC (Component Pascal) model only and is a *signed*
8 bit integer.

\*** No built-in support is provided for the UTF-16 or UCS-2 Unicode encodings. UTF-8 is the recommended Unicode encoding for text.
 - 16 bits has been insufficient for the Unicode character repetoire for at least 15 years.
 - Writing systems often require more than one unicode codepoint to represent a single character (and what constitutes a character can vary according to context).
 - UTF-8 is now widely used.

See [UTF-8 Everywhere](http://utf8everywhere.org/) for much more background on this recommendation.


#### SYSTEM.Mod support for fixed size integers and sets.

SYSTEM.Mod includes the following additional types:

| Type         | Size   | Range  |
| ---          | ---    | ---    |
| SYSTEM.INT8  | 8 bit  | -128 .. 127 |
| SYSTEM.INT16 | 16 bit | -32,768 .. 32,767 |
| SYSTEM.INT32 | 32 bit | -2,147,483,6478 .. ‭2,147,483,647‬ |
| SYSTEM.INT64 | 64 bit | -‭9,223,372,036,854,775,808 .. ‭9,223,372,036,854,775,807‬ |
| SYSTEM.SET32 | 32 bit | 0 .. 31 |
| SYSTEM.SET64 | 64 bit | 0 .. 63 |

Integer literals are recognised within the full signed 64 bit integer range MIN(SYSTEM.INT64) to MAX(SYSTEM.INT64). Additionally the parsing of hex notation allows negative values to be entered as a full 16 hex digits with top bit set. For example, -1 may be represented in Oberon source as 0FFFFFFFFFFFFFFFFH.


#### The SHORT and LONG functions

SHORT() of LONGINT and INTEGER values, and LONG() of SHORTINT and INTEGER values behave as
originally specified by Oberon-2.

In -O2, where LONGINT is 32 bits, LONG() now accepts a LONGINT value returning a HUGEINT value.

In -OC, where SHORTINT is 16 bits, SHORT() now accepts a SHORTINT value returning a SYSTEM.INT8 value.

#### ASH()

The Arithmetic shift function is defined by Oberon-2 as follows:

| Name          | Argument types         | Result Type | Function                       |
| ----          | ---                    | ---         | ---                            |
| ASH(*x*, *n*) | *x*, *n*: integer type | LONGINT     | arithmetic shift (*x* * 2^*n*) |

For compatability this definition is retained for all integer types up to LONGINT in size.
Additionally, when *x* is the new HUGEINT type, the result is HUGEINT.


#### Pointers and Addresses

Most Oberon systems have implicitly or explicitly assumed that LONGINT is large enough to hold
machine addresses. With the requirement to support 32 bit LONGINT on 64 bit systems, this is no
longer possible.

The type SYSTEM.ADDRESS is added, a signed integer type equivalent to either SYSTEM.INT32 or SYSTEM.INT64 according to the system address size.

The following SYSTEM module predefined functions and procedures now use SYSTEM.ADDRESS instead of LONGINT.

*Function procedures*

| Name                 | Argument types                   | Result Type    | Function |
| ----                 | ---                              | ---            | ---            |
| SYSTEM.ADR(*v*)      | any                              | SYSTEM.ADDRESS | Address of argument |
| SYSTEM.BIT(*a*, *n*) | *a*: SYSTEM.ADDESS; *n*: integer | BOOLEAN        | bit *n* of Mem[*a*] |

*Proper procedures*

| Name                         | Argument types                                                    | Function        |
| ----                         | ---                                                               | ---             |
| SYSTEM.GET(*a*, *v*)         | *a*: SYSTEM.ADDRESS; *v*: any basic type, pointer, procedure type | *v* := Mem[*a*] |
| SYSTEM.PUT(*a*, *x*)         | *a*: SYSTEM.ADDRESS; *x*: any basic type, pointer, procedure type | Mem[*a*] := *v* |
| SYSTEM.MOVE(*a0*, *a1*, *n*) | *a0*, *a1*: SYSTEM.ADDRESS; *n*: integer                          | Mem[*a1*..*a1*+*n*-1] := Mem[*a0*..*a0*+*n*-1] |

Note that the standard function LEN() still returns LONGINT.


#### Runtime error and exit handling

When passed FALSE, ASSERT displays the message 'Assertion failure.'. If a second, nonzero value is passed to ASSERT it will also be displayed. ASSERT then exits to the OS passing the assert value or zero.

HALT displays the message 'Terminated by Halt(n)'. For negative values that correspond to a standard runtime error a descriptive string is also printed. Finally Halt exits to the oprerating system passing the error code.

Bear in mind that both Linux and Windows generally treat the return code as a signed 8 bit value, ignoring higher order bits. Therefore it is best to restrict HALT and ASSERT codes to the range -128 .. 127.

A client application may register a halt handler by calling Platform.SetHalt(p) where p: PROCEDURE(n: SYSTEM.INT32). This procedure will be called before Halt displays it's message. The procedure may suppress the Halt message by calling Platform.Exit(code: INTEGER) directly.

