
#### (Work in progress)

#### Machine size issues

I don't see any really good solutions to different machine sizes. Existing code,
such as the libraries, assumes that INTEGER is 16 bit and LONGINT is 32 bit and
so is broken on 64 bit builds of voc.

Could the implementation of INTnn types help? It would not solve (for example)
the need for a type that always matches address size. Nor would it provide
unsigned types. Implementation of low level memory management needs both.

Wirth's latest spec includes a BYTE type (not SYSTEM.BYTE, just BYTE) that
behaves as an unsigned 8 bit integer, for use in low level code. BYTE thus
avoids the need for SYSTEM.VAL when manipulating 8 bit unsigned numeric values,
making code easier to write and, more importantly, easier to read. A BYTE type
would be useful for microcontroller C support. So I believe it makes sense to
add Wirths's BYTE to voc.

Linux/Unix specifies many API datatypes and structure fields in terms of named C
numeric types, with the result that they vary in size between implementations.
This is perhaps the strongest driving force for adding support for various
numeric types to voc - but they would better match the C types than be of fixed
size.

So maybe one could provide Platform.int, Platform.long, Platform.longlong,
Platform.unsignedint, Platform.unsignedlong, Platform.unsignedlonglong and,
importantly for memory management, Platform.uintptr.

Personally I miss Pascal and Modula's subrange variables. As well as being great
for error detection (assuming value checking code is generated), they can also
be used to imply variables of arbitrary sizes (e.g. 'VAR mybyte = 0..255;').
With these one could remove the Platform.int* types and replace them with
constants Platform.MaxInt, Platform.MaxLong etc. I think this would be a cleaner
more generalised option - but maybe, probably, it is a step too far. Always
beware of over-generalising. Wirth found that most programmers did not use, or
very rarely used, subrange types.

#### More thoughts about 64 bit support and what INTEGER and LONGINT mean

Arguably, because Oberon says LONGINT is big enough for addresses,
it seems that LONGINT has to be 64 bits on a 64 bit system.

But I'm having second thoughts.

There's a lot of code out there that assumes the size of INTEGER and LONGINT
and is broken if they are not 16 and 32 bits respectively. Frustratingly a
lot of the broken code doesn't go wrong until it encounters values outside the
16 and 32 bit ranges - like Texts.WriteInt which handles values up 2**32 fine,
and then aborts the program with an index out of range error when the number
is more than 11 characters long.

I suggest use of LONGINT for addresses is a small subset of use cases of LONGINT.

Instead I propose we
 - keep INTEGER at 16 bits and LONGINT at 32 bits.
 - Add LONG64 for 64 bit signed integers, to be available on both 32 and 64
   bit systems, (quite possible as C has an int64_t on both systems).
 - add a SYSTEM.ADDRESS type for address manipulation
   - an unsigned type that always matches the machine address size (32, 64 or even 16 bit).
   - is compatible with SHORTINT, INTEGER, LONGINT and LONG64.

It means changing the memory management and platform interface code, but it
means client code does not need changing.

This fixes the current 16 bit hole in the range of INTEGER types on 64 bit systems.

#### Oakwood Guidelines on type sizes

The Oakwood guidelines are interesting.

  - 5.2 requires that e.g. LONGINT is 32 bits *or more*,

but
  - Appendix A 1.2.5.4 requires that MODULE Files *always* reads and writes
    LONGINT as 4 bytes.

The restriction for the Files module makes sense as it is intended to produce
and consume files in a compatible way between platforms. Thus if a system uses
64 bit LONGINT, it is an error (detected or not) to write
to MODULE Files any LONGINT values outside the 32 bit range.

To put it shockingly, it is an error to write the vast majority of possible
LONGINT values - specifically over 99.998% of LONGINT values are invalid for
MODULE Files.

I see this as another argument in favour of locking LONGINT down as 32 bits.

#### It's all the same to C

It should be possible to make the 32/64 bit compilation a compiler option
available whether the compiler binary itself was built with 32 or 64 bit C.

Indeed - is there any benefit in a 64 bit compiler binary? A 32 bit compiler
binary will be smaller and faster. The memory requirements of the compiler are
orders of magnitude less than those that would need a 64 bit implementation.

The only need for a 64 bit compiler binary is for systems that can only run
64 bit binaries.

Point being - the bit size of the compiler binary should be independent of the
bit size of the target machine of the C code being generated.

So the compiler options could be:

 1. Generated binary bit size - 32 or 64 bit. Determines bit size of
    SYSTEM.ADDRESS. Add 16 bit option for controllers.
 2. Size of INTEGER, SET and LONGINT. Defaulting to 16,32,32 the parameter would
    also allow 32/64/64.

The libraries would be written and compiled to handle all cases. e.g.
  - A WriteInt routine needs it's value parameter to accept integers of all
    sizes and would be coded as LONG64.   
  - ReadInt is slightly more difficult because the parameter is VAR. Make the
    parameter ARRAY OF BYTE and process according to SIZE(param).

#### A feature I'd really like to see

We should report .Mod file name and line number at fault when exiting abnormally,
e.g. due to index out of range. Followed by a stack trace.

Wirth's original Pascal (Pascal 6000 on the CDC mainframe at ETHZ) had this at
least by 1975. This could be achieved by including a table of .Mod file line
number vs code address, and having the runtime seach this table for the failure
address. It would be quite a lot of work!

The current position tracking code in the compiler is buggy - for example the
position at the end of the `expr` in `WHILE expr DO stmt END` is recorded as
the position of the END when it should be of the 'DO'. This makes compiler error
reporting a bit unhelpful, but it's worse for runtime error reporting as we end
up with duplicate entries in the line number table. The position handling code
is somewhat obscure as it uses a convenient but misnamed spare integer field in
the symbol record and it's difficult to follow just when it patches it.

#### Oberon 07/15 mode

 - Add standard BYTE type being an unsigned integer between 0 and 255.
 - Structured value parameters become read-only and get passed the same way as
   VAR parameters - i.e. no copying.
 - CASE statements only support INTEGER (with low positive values) and CHAR.
 - Reject LOOP statements.
 - All imported variables are read-only.

See [Difference between Oberon-07 and Oberon](https://www.inf.ethz.ch/personal/wirth/Oberon/Oberon07.pdf).

#### To be left out?

Work on other compatibility layers is in progress.
voc team also works on bindings to existing C/Pascal libraries.
