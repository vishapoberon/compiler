MODULE XmppTypes;

(* Component Pascal source widths mapped to VOC's Oberon-2 model. Character
   values use UTF-16 code units; indices and lengths use Int32. *)

IMPORT Unicode := oocUnicode;

TYPE
  Int16* = INTEGER;
  Int32* = LONGINT;
  Int64* = HUGEINT;
  Float32* = REAL;
  Float64* = LONGREAL;
  BitSet32* = SET;
  SignedByte* = SHORTINT;
  WireByte* = CHAR;
  CodeUnit* = Unicode.LONGCHAR;
  String* = POINTER TO ARRAY OF CodeUnit;

END XmppTypes.
