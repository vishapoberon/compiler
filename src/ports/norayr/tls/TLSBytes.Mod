MODULE TLSBytes;
(* Byte buffers and 32 bit words for the TLS modules, with 32 bit signed integers only (the
   same file serves voc and polpo): LONGINT holds a 32 bit word as its bit pattern; logical
   operations go through SET (32 bits), shifts and rotations through SYSTEM.LSH and SYSTEM.ROT,
   wrapping additions through Add32 (a signed overflow in the C of voc is undefined).
   Bytes are read with LONG(ORD(c)): ORD gives an INTEGER (16 bits). *)
IMPORT SYSTEM;

CONST
  MaxLen* = 32768;

TYPE
  Buffer* = RECORD
    len*: LONGINT;
    data*: ARRAY MaxLen OF CHAR
  END;

PROCEDURE Init*(VAR b: Buffer);
BEGIN
  b.len := 0
END Init;

PROCEDURE SetLen*(VAR b: Buffer; n: LONGINT);
BEGIN
  IF (n < 0) OR (n > MaxLen) THEN HALT(120) END;
  b.len := n
END SetLen;

PROCEDURE Byte*(x: LONGINT): CHAR;
BEGIN
  RETURN CHR(x MOD 256)
END Byte;

PROCEDURE AppendChar*(VAR b: Buffer; c: CHAR);
BEGIN
  IF b.len >= MaxLen THEN HALT(121) END;
  b.data[b.len] := c; INC(b.len)
END AppendChar;

PROCEDURE AppendByte*(VAR b: Buffer; x: LONGINT);
BEGIN
  AppendChar(b, Byte(x))
END AppendByte;

PROCEDURE Append*(VAR dst: Buffer; VAR src: Buffer);
VAR i: LONGINT;
BEGIN
  IF dst.len + src.len > MaxLen THEN HALT(122) END;
  i := 0;
  WHILE i < src.len DO
    dst.data[dst.len + i] := src.data[i]; INC(i)
  END;
  dst.len := dst.len + src.len
END Append;

PROCEDURE AppendOpen*(VAR dst: Buffer; VAR src: ARRAY OF CHAR; n: LONGINT);
VAR i: LONGINT;
BEGIN
  IF dst.len + n > MaxLen THEN HALT(123) END;
  i := 0;
  WHILE i < n DO
    dst.data[dst.len + i] := src[i]; INC(i)
  END;
  dst.len := dst.len + n
END AppendOpen;

PROCEDURE AppendString*(VAR dst: Buffer; s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    AppendByte(dst, ORD(s[i])); INC(i)
  END
END AppendString;

PROCEDURE Copy*(VAR src, dst: Buffer);
VAR i: LONGINT;
BEGIN
  dst.len := src.len;
  i := 0;
  WHILE i < src.len DO dst.data[i] := src.data[i]; INC(i) END
END Copy;

PROCEDURE Slice*(VAR src: Buffer; pos, n: LONGINT; VAR dst: Buffer);
VAR i: LONGINT;
BEGIN
  IF (pos < 0) OR (n < 0) OR (pos + n > src.len) OR (n > MaxLen) THEN HALT(124) END;
  dst.len := n;
  i := 0;
  WHILE i < n DO dst.data[i] := src.data[pos + i]; INC(i) END
END Slice;

PROCEDURE GetBE16*(VAR b: Buffer; pos: LONGINT): LONGINT;
BEGIN
  RETURN LONG(ORD(b.data[pos])) * 256 + LONG(ORD(b.data[pos+1]))
END GetBE16;

PROCEDURE GetBE24*(VAR b: Buffer; pos: LONGINT): LONGINT;
BEGIN
  RETURN LONG(ORD(b.data[pos])) * 65536 + LONG(ORD(b.data[pos+1])) * 256 + LONG(ORD(b.data[pos+2]))
END GetBE24;

PROCEDURE GetBE32*(VAR b: Buffer; pos: LONGINT): LONGINT;
(* the bit pattern: bytes 80H and above give a negative number *)
VAR v: LONGINT;
BEGIN
  v := LONG(ORD(b.data[pos]));
  IF v >= 128 THEN v := v - 256 END;
  v := v * 256 + LONG(ORD(b.data[pos+1]));
  v := v * 256 + LONG(ORD(b.data[pos+2]));
  RETURN v * 256 + LONG(ORD(b.data[pos+3]))
END GetBE32;

PROCEDURE PutBE16*(VAR b: Buffer; x: LONGINT);
BEGIN
  AppendByte(b, x DIV 256); AppendByte(b, x)
END PutBE16;

PROCEDURE PutBE24*(VAR b: Buffer; x: LONGINT);
BEGIN
  AppendByte(b, x DIV 65536); AppendByte(b, x DIV 256); AppendByte(b, x)
END PutBE24;



PROCEDURE PutBE32*(VAR b: Buffer; x: LONGINT);
(* DIV and MOD round down, so a negative x gives its bit pattern *)
BEGIN
  AppendByte(b, x DIV 1000000H); AppendByte(b, x DIV 10000H);
  AppendByte(b, x DIV 100H); AppendByte(b, x)
END PutBE32;

(** 64 bits: hi, then lo *)
PROCEDURE PutBE64*(VAR b: Buffer; hi, lo: LONGINT);
BEGIN
  PutBE32(b, hi); PutBE32(b, lo)
END PutBE64;

(* ----- 32 bit words ----- *)

(** a + b modulo 2^32, without overflowing *)
PROCEDURE Add32*(a, b: LONGINT): LONGINT;
VAR lo, hi: LONGINT;
BEGIN
  lo := a MOD 10000H + b MOD 10000H;
  hi := (a DIV 10000H + b DIV 10000H + lo DIV 10000H) MOD 10000H;
  IF hi >= 8000H THEN hi := hi - 10000H END;
  RETURN hi * 10000H + lo MOD 10000H
END Add32;

PROCEDURE Xor32*(a, b: LONGINT): LONGINT;
BEGIN RETURN SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, a) / SYSTEM.VAL(SET, b))
END Xor32;

PROCEDURE And32*(a, b: LONGINT): LONGINT;
BEGIN RETURN SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, a) * SYSTEM.VAL(SET, b))
END And32;

PROCEDURE Or32*(a, b: LONGINT): LONGINT;
BEGIN RETURN SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, a) + SYSTEM.VAL(SET, b))
END Or32;

PROCEDURE Not32*(a: LONGINT): LONGINT;
BEGIN RETURN SYSTEM.VAL(LONGINT, -SYSTEM.VAL(SET, a))
END Not32;

(** x rotated right by n (0 < n < 32) *)
PROCEDURE Rotr32*(x, n: LONGINT): LONGINT;
BEGIN RETURN SYSTEM.ROT(x, -n)
END Rotr32;

(** x shifted right by n, zeros in from the left *)
PROCEDURE Shr32*(x, n: LONGINT): LONGINT;
BEGIN RETURN SYSTEM.LSH(x, -n)
END Shr32;

PROCEDURE XorByte*(a, b: LONGINT): INTEGER;
BEGIN
  RETURN SHORT(Xor32(a, b) MOD 256)
END XorByte;

PROCEDURE Xor12*(VAR a, b, out: Buffer);
VAR i: LONGINT;
BEGIN
  IF (a.len # 12) OR (b.len # 12) THEN HALT(125) END;
  out.len := 12;
  i := 0;
  WHILE i < 12 DO out.data[i] := CHR(XorByte(ORD(a.data[i]), ORD(b.data[i]))); INC(i) END
END Xor12;

(** the 12 byte sequence number for the nonce: 4 zero bytes, then seq in 64 bits *)
PROCEDURE SeqNum12*(seq: LONGINT; VAR out: Buffer);
BEGIN
  IF seq < 0 THEN HALT(126) END;
  out.len := 0;
  PutBE32(out, 0); PutBE64(out, 0, seq)
END SeqNum12;

PROCEDURE EqualConstTime*(VAR a, b: Buffer): BOOLEAN;
VAR i, acc: LONGINT;
BEGIN
  IF a.len # b.len THEN RETURN FALSE END;
  acc := 0; i := 0;
  WHILE i < a.len DO acc := acc + XorByte(ORD(a.data[i]), ORD(b.data[i])); INC(i) END;
  RETURN acc = 0
END EqualConstTime;

END TLSBytes.
