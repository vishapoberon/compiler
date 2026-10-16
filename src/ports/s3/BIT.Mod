(* ETH Oberon, Copyright 1990-2003 Computer Systems Institute, ETH Zurich, CH-8092 Zurich.
Refer to the license.txt file provided with this distribution. *)

MODULE BIT;  (** portable *)  (* tk 12.2.96 *)
(** AUTHOR "tk"; PURPOSE "Bit manipulation"; *)

  IMPORT S := SYSTEM;

  TYPE
    SHORTCARD* = SHORTINT;
    CARDINAL* = INTEGER;
    LONGCARD* = LONGINT;

  CONST
    rbo = FALSE;  (* reverse bit ordering, e.g. PowerPC*)
    risc = FALSE;  (* risc architecture - no support for 8 and 16-bit rotations *)

  (** bitwise exclusive or: x XOR y *)
  PROCEDURE CXOR*(x, y: CHAR): CHAR;
  BEGIN RETURN CHR(S.VAL(LONGINT, S.VAL(SET, LONG(ORD(x))) / S.VAL(SET, LONG(ORD(y)))))
  END CXOR;

  PROCEDURE SXOR*(x, y: SHORTINT): SHORTINT;
  BEGIN RETURN SHORT(SHORT(S.VAL(LONGINT, S.VAL(SET, LONG(LONG(x))) / S.VAL(SET, LONG(LONG(y))))))
  END SXOR;

  PROCEDURE IXOR*(x, y: INTEGER): INTEGER;
  BEGIN RETURN SHORT(S.VAL(LONGINT, S.VAL(SET, LONG(x)) / S.VAL(SET, LONG(y))))
  END IXOR;

  PROCEDURE LXOR*(x, y: LONGINT): LONGINT;
  BEGIN RETURN S.VAL(LONGINT, S.VAL(SET, x) / S.VAL(SET, y))
  END LXOR;


  (** bitwise or: x OR y *)
  PROCEDURE COR*(x, y: CHAR): CHAR;
  BEGIN RETURN CHR(S.VAL(LONGINT, S.VAL(SET, LONG(ORD(x))) + S.VAL(SET, LONG(ORD(y)))))
  END COR;

  PROCEDURE SOR*(x, y: SHORTINT): SHORTINT;
  BEGIN RETURN SHORT(SHORT(S.VAL(LONGINT, S.VAL(SET, LONG(LONG(x))) + S.VAL(SET, LONG(LONG(y))))))
  END SOR;

  PROCEDURE IOR*(x, y: INTEGER): INTEGER;
  BEGIN RETURN SHORT(S.VAL(LONGINT, S.VAL(SET, LONG(x)) + S.VAL(SET, LONG(y))))
  END IOR;

  PROCEDURE LOR*(x, y: LONGINT): LONGINT;
  BEGIN RETURN S.VAL(LONGINT, S.VAL(SET, x) + S.VAL(SET, y))
  END LOR;


  (** bitwise and: x AND y *)
  PROCEDURE CAND*(x, y: CHAR): CHAR;
  BEGIN RETURN CHR(S.VAL(LONGINT, S.VAL(SET, LONG(ORD(x))) * S.VAL(SET, LONG(ORD(y)))))
  END CAND;

  PROCEDURE SAND*(x, y: SHORTINT): SHORTINT;
  BEGIN RETURN SHORT(SHORT(S.VAL(LONGINT, S.VAL(SET, LONG(LONG(x))) * S.VAL(SET, LONG(LONG(y))))))
  END SAND;

  PROCEDURE IAND*(x, y: INTEGER): INTEGER;
  BEGIN RETURN SHORT(S.VAL(LONGINT, S.VAL(SET, LONG(x)) * S.VAL(SET, LONG(y))))
  END IAND;

  PROCEDURE LAND*(x, y: LONGINT): LONGINT;
  BEGIN RETURN S.VAL(LONGINT, S.VAL(SET, x) * S.VAL(SET, y))
  END LAND;


  (** bitwise logical left-shift: x shifted n *)
  PROCEDURE CLSH*(x: CHAR; n: SHORTINT): CHAR;
    VAR masked: LONGINT;
  BEGIN
    masked := ORD(x) MOD 256; (* Ensure only the lower 8 bits are considered *)
    RETURN CHR(S.LSH(masked, n)); (* Perform the shift and return the result *)
  END CLSH;

  PROCEDURE SLSH*(x: SHORTINT; n: SHORTINT): SHORTINT;
  BEGIN
    IF risc THEN RETURN SHORT(SHORT(S.LSH(S.VAL(LONGINT, S.VAL(SET, LONG(LONG(x))) * S.VAL(SET, 0FFH)), n)))
    ELSE RETURN S.LSH(x, n) END
  END SLSH;

  PROCEDURE ILSH*(x: INTEGER; n: SHORTINT): INTEGER;
  BEGIN
    IF risc THEN RETURN SHORT(S.LSH(S.VAL(LONGINT, S.VAL(SET, LONG(x)) * S.VAL(SET, 0FFFFH)), n))
    ELSE RETURN S.LSH(x, n) END
  END ILSH;

  PROCEDURE LLSH*(x: LONGINT; n: SHORTINT): LONGINT;
  BEGIN RETURN S.LSH(x, n)
  END LLSH;


  (** bitwise rotation: x rotatated by n bits *)
  PROCEDURE CROT*(x: CHAR; n: SHORTINT): CHAR;
    VAR s0, s1: SET; i, bitMask: INTEGER;
  BEGIN
    IF risc THEN
      s0 := {}; s1 := {}; (* Initialize sets *)

      (* Populate s0 manually from the bits of ORD(x) *)
      FOR i := 0 TO 7 DO
        bitMask := S.LSH(1, i); (* Generate a bit mask for the i-th bit *)
        IF (ORD(x) MOD S.LSH(1, i + 1)) >= bitMask THEN
          INCL(s0, i);
        END;
      END;

      IF rbo THEN
        (* Reverse bit order rotation *)
        FOR i := 0 TO 7 DO
          IF (31 - i) IN s0 THEN INCL(s1, 31 - ((i + n) MOD 8)) END;
        END;
      ELSE
        (* Standard rotation *)
        FOR i := 0 TO 7 DO
          IF i IN s0 THEN INCL(s1, (i + n) MOD 8) END;
        END;
      END;

      RETURN CHR(S.VAL(LONGINT, s1));
    ELSE
      (* Use system-provided rotation for non-risc systems *)
      RETURN S.ROT(x, n);
    END;
  END CROT;


  PROCEDURE SROT*(x: SHORTINT; n: SHORTINT): SHORTINT;
    VAR s0, s1: SET; i: INTEGER;
  BEGIN
    IF risc THEN
      s0 := S.VAL(SET, LONG(LONG(x))); s1 := {};
      IF rbo THEN
        i := 0; WHILE i < 8 DO
          IF 31-i IN s0 THEN INCL(s1, 31 - ((i+n) MOD 8)) END;
          INC(i)
        END;
      ELSE
        i := 0; WHILE i < 8 DO
          IF i IN s0 THEN INCL(s1, (i+n) MOD 8) END;
          INC(i)
        END;
      END;
      RETURN SHORT(SHORT(S.VAL(LONGINT, s1)))
    ELSE RETURN S.ROT(x, n) END;
  END SROT;

  PROCEDURE IROT*(x: INTEGER; n: SHORTINT): INTEGER;
    VAR s0, s1: SET; i: INTEGER;
  BEGIN
    IF risc THEN
      s0 := S.VAL(SET, LONG(x)); s1 := {};
      IF rbo THEN
        i := 0; WHILE i < 16 DO
          IF 31-i IN s0 THEN INCL(s1, 31 - ((i+n) MOD 16)) END;
          INC(i)
        END;
      ELSE
        i := 0; WHILE i < 16 DO
          IF i IN s0 THEN INCL(s1, (i+n) MOD 16) END;
          INC(i)
        END;
      END;
      RETURN SHORT(S.VAL(LONGINT, s1))
    ELSE RETURN S.ROT(x, n) END;
  END IROT;

  PROCEDURE LROT*(x: LONGINT; n: SHORTINT): LONGINT;
  BEGIN RETURN S.ROT(x, n)
  END LROT;


  (** swap bytes to change byteordering *)
  PROCEDURE ISWAP*(x: INTEGER): INTEGER;
    TYPE integer = ARRAY 2 OF CHAR; VAR a, b: integer;
  BEGIN a := S.VAL(integer, x); b[0] := a[1]; b[1] := a[0]; RETURN S.VAL(INTEGER, b)
  END ISWAP;

  PROCEDURE LSWAP*(x: LONGINT): LONGINT;
    TYPE longint = ARRAY 4 OF CHAR; VAR a, b: longint;
  BEGIN a := S.VAL(longint, x); b[0] := a[3]; b[1] := a[2]; b[2] := a[1]; b[3] := a[0]; RETURN S.VAL(LONGINT, b)
  END LSWAP;


  (** test bit n in x*)
  PROCEDURE CBIT*(x: CHAR; n: SHORTINT): BOOLEAN;
    VAR mask: CHAR;
  BEGIN
    ASSERT((n >= 0) & (n <= 7));  (* Ensure the bit index is within the valid range *)

    IF rbo THEN
      mask := CHR(S.LSH(1, 31 - n));  (* Create a mask for the (31-n)-th bit *)
      RETURN (ORD(x) MOD S.LSH(1, 32)) >= ORD(mask);
    ELSE
      mask := CHR(S.LSH(1, n));  (* Create a mask for the n-th bit *)
      RETURN (ORD(x) MOD S.LSH(1, n + 1)) >= ORD(mask);
    END;
  END CBIT;

  PROCEDURE BIT*(x: LONGINT; n: SHORTINT): BOOLEAN;
  BEGIN ASSERT((n >= 0) & (n <= 31));
    IF rbo THEN RETURN (31-n) IN S.VAL(SET, x) ELSE RETURN n IN S.VAL(SET, x) END
  END BIT;


  (** set bit n in x*)
  PROCEDURE CSETBIT*(VAR x: CHAR; n: SHORTINT);
    VAR mask: SET; temp: SET;
    l: LONGINT;
  BEGIN
    ASSERT((n >= 0) & (n <= 7));  (* Ensure the bit index is within range *)

    mask := {n};  (* Create a mask with only the n-th bit set *)
    l := ORD(x);   (* Convert CHAR to LONGINT *)
    temp := S.VAL(SET, l);  (* Convert LONGINT x to a SET *)
    temp := temp + mask;         (* Perform bitwise OR using SET *)
    x := CHR(S.VAL(INTEGER, temp) MOD 256);  (* Convert back to CHAR, ensure 8-bit limit *)
  END CSETBIT;

  PROCEDURE SSETBIT*(VAR x: SHORTINT; n: SHORTINT);
    VAR i: SET; l: LONGINT;
  BEGIN
    ASSERT((n >= 0) & (n <= 7));  (* Ensure the bit index is within range *)

    l := LONG(x);            (* Convert SHORTINT x to LONGINT *)
    i := S.VAL(SET, l);      (* Convert LONGINT to SET *)

    INCL(i, n);              (* Add the bit at position n *)

    x := SHORT(S.VAL(INTEGER, i));  (* Convert back to SHORTINT *)
  END SSETBIT;

  PROCEDURE ISETBIT*(VAR x: INTEGER; n: SHORTINT);
    VAR i: SET;
        l: LONGINT;
  BEGIN
    ASSERT((n >= 0) & (n <= 15));
    l := x;
    i := S.VAL(SET, l);  (* Convert x to a set *)
    INCL(i, n);          (* Include the bit at position n *)
    x := S.VAL(INTEGER, i);  (* Convert back to INTEGER *)
  END ISETBIT;

  PROCEDURE LSETBIT*(VAR x: LONGINT; n: SHORTINT);
    VAR i: SET;
  BEGIN
    ASSERT((n >= 0) & (n <= 31));
    i := S.VAL(SET, x);  (* Convert x to a set *)
    INCL(i, n);          (* Include the bit at position n *)
    x := S.VAL(LONGINT, i);  (* Convert back to LONGINT *)
  END LSETBIT;


  (** clear bit n in x*)
  PROCEDURE CCLRBIT*(VAR x: CHAR; n: SHORTINT);
    VAR i: SET;
        l: LONGINT;
  BEGIN
    ASSERT((n >= 0) & (n <= 7));
    l := ORD(x);
    i := S.VAL(SET, l);  (* Convert x to a set *)
    EXCL(i, n);               (* Exclude the bit at position n *)
    x := CHR(S.VAL(LONGINT, i));  (* Convert back to CHAR *)
  END CCLRBIT;

  PROCEDURE SCLRBIT*(VAR x: SHORTINT; n: SHORTINT);
    VAR i: SET;
        l: LONGINT;
  BEGIN
    ASSERT((n >= 0) & (n <= 7));
    l := x;
    i := S.VAL(SET, l);  (* Convert x to a set *)
    EXCL(i, n);          (* Exclude the bit at position n *)
    x := SHORT(SHORT((S.VAL(LONGINT, i))));  (* Convert back to SHORTINT *)
  END SCLRBIT;

  PROCEDURE ICLRBIT*(VAR x: INTEGER; n: SHORTINT);
    VAR i: SET;
        l: LONGINT;
  BEGIN
    ASSERT((n >= 0) & (n <= 15));
    l := x;
    i := S.VAL(SET, l);  (* Convert x to a set *)
    EXCL(i, n);          (* Exclude the bit at position n *)
    x := SHORT(S.VAL(LONGINT, i));  (* Convert back to INTEGER *)
  END ICLRBIT;

  PROCEDURE LCLRBIT*(VAR x: LONGINT; n: SHORTINT);
    VAR i: SET;
  BEGIN
    ASSERT((n >= 0) & (n <= 31));
    i := S.VAL(SET, x);  (* Convert x to a set *)
    EXCL(i, n);          (* Exclude the bit at position n *)
    x := S.VAL(LONGINT, i);  (* Convert back to LONGINT *)
  END LCLRBIT;

  (** unsigned comparison: x < y *)
  PROCEDURE SLESS*(x, y: SHORTCARD): BOOLEAN;
  BEGIN
    RETURN
      S.VAL(LONGINT, S.VAL(SET, LONG(LONG(x))) * S.VAL(SET, 0FFH))
       <
     S.VAL(LONGINT, S.VAL(SET, LONG(LONG(y))) * S.VAL(SET, 0FFH));
  END SLESS;

  PROCEDURE ILESS*(x, y: CARDINAL): BOOLEAN;
  BEGIN
    RETURN
      S.VAL(LONGINT, S.VAL(SET,LONG(x)) * S.VAL(SET, 0FFFFH))
    <
      S.VAL(LONGINT, S.VAL(SET, LONG(y)) * S.VAL(SET, 0FFFFH))
  END ILESS;

  PROCEDURE LLESS*(x, y: LONGCARD): BOOLEAN;
    VAR x0, y0: LONGINT;
  BEGIN x0 := S.LSH(x, -1); y0 := S.LSH(y, -1);
    IF x0 - y0 = 0 THEN RETURN x0 MOD 2 < y0 MOD 2 ELSE RETURN x0 < y0 END
  END LLESS;


  (** unsigned comparison: x <= y *)
  PROCEDURE SLESSEQ*(x, y: SHORTCARD): BOOLEAN;
  BEGIN
    RETURN
      S.VAL(LONGINT, S.VAL(SET, LONG(LONG(x))) * S.VAL(SET, 0FFH))
    <=
      S.VAL(LONGINT, S.VAL(SET, LONG(LONG(y))) * S.VAL(SET, 0FFH))
  END SLESSEQ;

  PROCEDURE ILESSEQ*(x, y: CARDINAL): BOOLEAN;
  BEGIN
    RETURN
      S.VAL(LONGINT, S.VAL(SET,LONG(x)) * S.VAL(SET, 0FFFFH))
    <=
      S.VAL(LONGINT, S.VAL(SET, LONG(y)) * S.VAL(SET, 0FFFFH))
  END ILESSEQ;

  PROCEDURE LLESSEQ*(x, y: LONGCARD): BOOLEAN;
    VAR x0, y0: LONGINT;
  BEGIN x0 := S.LSH(x, -1); y0 := S.LSH(y, -1);
    IF x0 - y0 = 0 THEN RETURN x0 MOD 2 <= y0 MOD 2 ELSE RETURN x0 <= y0 END
  END LLESSEQ;


  (** unsigned division: x DIV y *)
  PROCEDURE SDIV*(x, y: SHORTCARD): SHORTCARD;
  BEGIN RETURN SHORT(SHORT(S.VAL(LONGINT, S.VAL(SET, LONG(LONG(x))) * S.VAL(SET, 0FFH)) DIV y))
  END SDIV;

  PROCEDURE IDIV*(x, y: CARDINAL): CARDINAL;
  BEGIN RETURN SHORT(S.VAL(LONGINT, S.VAL(SET, LONG(x)) * S.VAL(SET, 0FFFFH))) DIV y;
  END IDIV;

  PROCEDURE LDIV*(x, y: LONGCARD): LONGCARD;
    CONST m = 4.294967296D9;
    VAR x0, y0: LONGREAL;
  BEGIN IF x < 0 THEN x0 := m - x ELSE x0 := x END;
    IF y < 0 THEN y0 := m - y ELSE y0 := y END;
    RETURN ENTIER(x0 / y0)
  END LDIV;

END BIT.

