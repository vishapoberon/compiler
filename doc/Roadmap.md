
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


#### A feature I'd really like to see

We should report .Mod file name and line number at fault when exiting abnormally,
e.g. due to index out of range. Followed by a stack trace.

Wirth's original Pascal (Pascal 6000 on the CDC mainframe at ETHZ) had this at
least by 1975. This could be achieved by including a table of .Mod file line
number vs code address, and having the runtime seach this table for the failure
address. It would be quite a lot of work!

#### Oberon 07/15 mode

 - Add standard BYTE type being an unsigned integer between 0 and 255.
 - Structured value parameters become read-only and get passed the same way as
   VAR parameters - i.e. no copying.
 - CASE statements only support INTEGER (with low positive values) and CHAR.
 - Reject LOOP statements.
 - All imported variables are read-only.

#### To be left out?

Work on other compatibility layers is in progress.
voc team also works on bindings to existing C/Pascal libraries.
