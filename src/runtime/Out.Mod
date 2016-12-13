MODULE Out; (* DCW Brown. 2016-09-27 *)

IMPORT SYSTEM, Platform, Heap;

VAR
  IsConsole-: BOOLEAN;

  buf: ARRAY 128 OF CHAR;
  in: INTEGER;



PROCEDURE Flush*;
VAR error: Platform.ErrorCode;
BEGIN
  IF in > 0 THEN error := Platform.Write(Platform.StdOut, SYSTEM.ADR(buf), in) END;
  in := 0;
END Flush;

PROCEDURE Open*;
BEGIN
END Open;

PROCEDURE Char*(ch: CHAR);
BEGIN
  IF in >= LEN(buf) THEN Flush END;
  buf[in] := ch; INC(in);
  IF ch = 0AX THEN Flush END;
END Char;

PROCEDURE Length(VAR s: ARRAY OF CHAR): LONGINT;
VAR l: LONGINT;
BEGIN l := 0; WHILE (l < LEN(s)) & (s[l] # 0X) DO INC(l) END; RETURN l
END Length;

PROCEDURE String*(str: ARRAY OF CHAR);
  VAR l: LONGINT;  error: Platform.ErrorCode;
BEGIN
  l := Length(str);
  IF in + l > LEN(buf) THEN Flush END;
  IF l > LEN(buf) THEN
    (* Doesn't fit buf. Bypass buffering. *)
    error := Platform.Write(Platform.StdOut, SYSTEM.ADR(str), l)
  ELSE
    SYSTEM.MOVE(SYSTEM.ADR(str), SYSTEM.ADR(buf[in]), l); INC(in, SHORT(l));
  END
END String;


PROCEDURE Int*(x, n: HUGEINT);
  CONST zero = ORD('0');
  VAR s: ARRAY 22 OF CHAR; i: INTEGER; negative: BOOLEAN;
BEGIN
  negative := x < 0;
  IF x = MIN(HUGEINT) THEN
    s := "8085774586302733229"; i := 19
  ELSE
    IF x < 0 THEN x := - x END;
    s[0] := CHR(zero + (x MOD 10)); x := x DIV 10;
    i := 1; WHILE x # 0 DO
      s[i] := CHR(zero + (x MOD 10));
      x := x DIV 10;
      INC(i)
    END
  END;
  IF negative THEN s[i] := '-'; INC(i) END;
  WHILE n > i DO Char(' '); DEC(n) END;
  WHILE i > 0 DO DEC(i); Char(s[i]) END
END Int;

PROCEDURE Hex*(x, n: HUGEINT);
BEGIN
  IF n < 1 THEN n := 1 ELSIF n > 16 THEN n := 16 END;
  WHILE (n < 16) & (SYSTEM.LSH(x, -4*n) # 0) DO INC(n) END;
  x := SYSTEM.ROT(x, 4*(16-n));
  WHILE n > 0 DO
    x := SYSTEM.ROT(x,4); DEC(n);
    IF x MOD 16 < 10 THEN Char(CHR((x MOD 16) + ORD('0')))
    ELSE Char(CHR((x MOD 16) - 10 + ORD('A'))) END
  END
END Hex;

PROCEDURE Ln*;
BEGIN String(Platform.NL); Flush;
END Ln;

PROCEDURE HexDumpAdr*(adr: SYSTEM.ADDRESS; offset: HUGEINT; length: LONGINT);
VAR i: INTEGER; n, lim: SYSTEM.ADDRESS; c: CHAR;
BEGIN
  lim := SYSTEM.VAL(SYSTEM.ADDRESS, adr+length);
  WHILE adr < lim DO
    IF adr+16 < lim THEN n := 16 ELSE n := lim-adr END;
    Hex(offset,8); Char(" ");
    i := 0; WHILE i < n DO
      IF i MOD 4 = 0 THEN Char(" ") END;
      SYSTEM.GET(adr+i, c); Hex(ORD(c), 2); Char(" ");
      INC(i)
    END;
    WHILE i < 16 DO
      IF i MOD 4 = 0 THEN Char(" ") END; String("   ");
      INC(i)
    END;
    String(" ");
    i := 0; WHILE i < n DO
      SYSTEM.GET(adr+i, c);
      IF (ORD(c) < 32) OR (ORD(c) > 126) THEN Char(".") ELSE Char(c) END;
      INC(i)
    END;
    INC(adr,n); INC(offset,n); Ln
  END
END HexDumpAdr;

PROCEDURE HexDump*(VAR m: ARRAY OF SYSTEM.BYTE);
BEGIN HexDumpAdr(SYSTEM.ADR(m), 0, LEN(m))
END HexDump;


PROCEDURE DumpModule(m: Heap.Module);
BEGIN
  String("        next:     "); Hex(SYSTEM.VAL(SYSTEM.ADDRESS, m.next),1); Ln;
  String("        name:     "); String(m.name); Ln;
  String("        refcnt:   "); Hex(m.refcnt,1); Ln;
  String("        cmds:     "); Hex(SYSTEM.VAL(SYSTEM.ADDRESS, m.cmds),1); Ln;
  String("        types:    "); Hex(m.types,1); Ln;
  String("        enumPtrs: "); Hex(SYSTEM.VAL(SYSTEM.ADDRESS, m.enumPtrs),1); Ln;
END DumpModule;

PROCEDURE DumpTag*(addr: SYSTEM.ADDRESS);
TYPE
  typedesc = RECORD
    (* Array of type bound procedure addresses preceeds this. *)
    tag:      SYSTEM.ADDRESS;
    next:     SYSTEM.ADDRESS;
    level:    SYSTEM.ADDRESS;
    module:   SYSTEM.ADDRESS;
    name:     ARRAY 24 OF CHAR;
    bases:    ARRAY 16 OF SYSTEM.ADDRESS;
    reserved: SYSTEM.ADDRESS;
    blksz:    SYSTEM.ADDRESS;
    ptr0:     SYSTEM.ADDRESS;  (* Offset of first pointer. Others follow this. *)
  END;
  tag = POINTER [1] TO typedesc;
VAR
  desc: tag;
  i: INTEGER;
BEGIN
  String("      obj tag:  "); Hex(addr,1); Ln;
  DEC(addr, addr MOD 2); (* Work OK with incremented tags. *)
  desc := SYSTEM.VAL(tag, addr - (21*SIZE(SYSTEM.ADDRESS) + 24));
  String("      desc at:  "); Hex(SYSTEM.VAL(SYSTEM.ADDRESS, desc),1); Ln;
  String("      desc contains:"); Ln;
  String("      tag:      "); Hex(desc.tag,      1); Ln;
  String("      next:     "); Hex(desc.next,     1); Ln;
  String("      level:    "); Hex(desc.level,    1); Ln;
  String("      module:   "); Hex(desc.module,   1); Ln;
  IF desc.module # 0 THEN DumpModule(SYSTEM.VAL(Heap.Module, desc.module)) END;
  String("      name:     "); String(desc.name); Ln;
  String("      bases:    ");
  i := 0; WHILE i < 16 DO
    Hex(desc.bases[i], SIZE(SYSTEM.ADDRESS) * 2);
    IF i MOD 4 = 3 THEN Ln; String("                ") ELSE Char(" ") END;
    INC(i)
  END; Ln;
  String("      reserved: "); Hex(desc.reserved, 1); Ln;
  String("      blksz:    "); Hex(desc.blksz,    1); Ln;
  String("      ptr0:     "); Hex(desc.ptr0,     1); Ln;
END DumpTag;

PROCEDURE DumpType*(VAR o: ARRAY OF SYSTEM.BYTE);
VAR addr: SYSTEM.ADDRESS;
BEGIN
  SYSTEM.GET(SYSTEM.ADR(o) - SIZE(SYSTEM.ADDRESS), addr);
  DumpTag(addr);
END DumpType;


PROCEDURE -externheap "extern ADDRESS Heap_heap;";
PROCEDURE -getheap(): SYSTEM.ADDRESS "Heap_heap";

PROCEDURE DumpHeap*;
TYPE
  adrptr = POINTER [1] TO ARRAY 1 OF SYSTEM.ADDRESS;

  block     = POINTER [1] TO blockdesc;
  blockdesc = RECORD
    tag:      SYSTEM.ADDRESS;
    size:     SYSTEM.ADDRESS;
    sentinel: SYSTEM.ADDRESS;
    next:     SYSTEM.ADDRESS;
  END;

  chunk     = POINTER [1] TO chunkdesc;
  chunkdesc = RECORD
    next:       SYSTEM.ADDRESS;
    end:        SYSTEM.ADDRESS;
    reserved:   SYSTEM.ADDRESS;
    firstblock: blockdesc;
  END;
VAR
  caddr: SYSTEM.ADDRESS; c: chunk;
  baddr: SYSTEM.ADDRESS; b: block;
  tag: adrptr;
BEGIN
  caddr := Heap.heap;
  WHILE caddr # 0 DO
    String("Chunk at: "); Hex(caddr, 1); Ln;
    c := SYSTEM.VAL(chunk, caddr);
    String("  next:   "); Hex(c.next, 1);     Ln;
    String("  end:    "); Hex(c.end, 1); String(" => size: "); Hex(c.end - caddr,1 );     Ln;
    String("  rsvd:   "); Hex(c.reserved, 1); Ln;

    baddr := SYSTEM.ADR(c.firstblock);
    WHILE c.end - baddr > 0 DO
      String("  Block at:   "); Hex(baddr, 1); Ln;
      b := SYSTEM.VAL(block, baddr);
      tag  := SYSTEM.VAL(adrptr, b.tag - (b.tag MOD 2)); (* mask out heap management flag in bit 0. *)
      String("    tag:      "); Hex(b.tag, 1);  IF b.tag MOD 2 # 0 THEN String(" <--- ODD! ---") END; Ln;
      String("    tag^:     "); Hex(tag^[0], 1);    Ln;
      String("    size:     "); Hex(b.size, 1);     Ln;
      String("    sentinel: "); Hex(b.sentinel, 1); Ln;
      String("    next:     "); Hex(b.next, 1);     Ln;
      IF b.tag # SYSTEM.ADR(b.size) THEN
        (* There is a type descriptor. *)
        DumpTag(b.tag)
      END;
      INC(baddr, tag^[0]);
      Ln;
    END;

    caddr := c.next;
    Ln;
  END
END DumpHeap;


(* Real and Longreal display *)

PROCEDURE digit(n: HUGEINT; VAR s: ARRAY OF CHAR; VAR i: INTEGER);
BEGIN
  DEC(i); s[i] := CHR(n MOD 10 + 48);
END digit;

PROCEDURE prepend(t: ARRAY OF CHAR; VAR s: ARRAY OF CHAR; VAR i: INTEGER);
  VAR j: INTEGER; l: LONGINT;
BEGIN
  l := Length(t); IF l > i THEN l := i END;
  DEC(i, SHORT(l)); j := 0;
  WHILE j < l DO s[i+j] := t[j]; INC(j) END
END prepend;



PROCEDURE Ten*(e: INTEGER): LONGREAL;
VAR r, power: LONGREAL;
BEGIN r := 1.0D0; power := 1.0D1;
  WHILE e > 0 DO
    IF ODD(e) THEN r := r*power END;
    power := power*power; e := e DIV 2
  END;
  RETURN r
END Ten;

PROCEDURE -Entier64(x: LONGREAL): SYSTEM.INT64 "(INT64)(x)";

PROCEDURE RealP(x: LONGREAL; n: INTEGER; long: BOOLEAN);

(* RealP(x, n) writes the long real number x to the end of the output stream using an
   exponential form. If the textual representation of x requires m characters (including  a
   three-digit signed exponent), x is right adjusted in a ﬁeld of Max(n, m) characters padded
   with blanks at the left end. A plus sign of the mantissa is not written.
   LONGREAL is 1/sign, 11/exponent, 52/significand *)

VAR
  e:   INTEGER;          (* Exponent field *)
  f:   HUGEINT;          (* Fraction field *)
  s:   ARRAY 30 OF CHAR; (* Buffer built backwards *)
  i:   INTEGER;          (* Index into s *)
  el:  INTEGER;          (* Exponent length *)
  x0:  LONGREAL;
  nn:  BOOLEAN;          (* Number negative *)
  en:  BOOLEAN;          (* Exponent negative *)
  m:   HUGEINT;          (* Mantissa digits *)
  d:   INTEGER;          (* Significant digit count to display *)
  dr:  INTEGER;          (* Number of insignificant digits that can be dropped *)

BEGIN
  e  := SYSTEM.VAL(INTEGER, (SYSTEM.VAL(HUGEINT, x) DIV 10000000000000H) MOD 800H);
  f  := SYSTEM.VAL(HUGEINT, x) MOD 10000000000000H;
  nn := (SYSTEM.VAL(HUGEINT, x) < 0) & ~((e = 7FFH) & (f # 0)); (* Ignore sign on Nan *)
  IF nn THEN DEC(n) END;

  i := LEN(s);
  IF e = 7FFH THEN (* NaN / Infinity *)
    IF f = 0 THEN prepend("Infinity", s, i) ELSE prepend("NaN", s, i) END
  ELSE
    (* Calculate number of significant digits caller has proposed space for, and
       number of digits to generate. *)
    IF long THEN
      el := 3;
      dr := n-6;                    (* Leave room for dp and '+D000' *)
      IF dr > 17 THEN dr := 17 END; (* Limit to max useful significant digits *)
      d := dr;                      (* Number of digits to generate *)
      IF d < 15 THEN d := 15 END    (* Generate enough digits to do trailing zero supporession *)
    ELSE
      el := 2;
      dr := n-5;                    (* Leave room for dp and '+E00' *)
      IF dr > 9 THEN dr := 9 END;   (* Limit to max useful significant digits *)
      d := dr;                      (* Number of digits to generate *)
      IF d < 6 THEN d := 6 END      (* Generate enough digits to do trailing zero supporession *)
    END;

    IF e = 0 THEN
      WHILE el > 0 DO DEC(i); s[i] := "0"; DEC(el) END;
      DEC(i); s[i] := "+";
      m := 0;
    ELSE
      IF nn THEN x := -x END;

      (* Scale e to be an exponent of 10 rather than 2 *)
      e := SHORT(LONG(e - 1023) * 77 DIV 256);
      IF e >= 0 THEN x := x / Ten(e) ELSE x := Ten(-e) * x END ;
      IF x >= 10.0D0 THEN x := 0.1D0 * x; INC(e) END;

      (* Generate the exponent digits *)
      en := e < 0; IF en THEN e := - e END;
      WHILE el > 0 DO digit(e, s, i); e := e DIV 10; DEC(el) END;
      DEC(i); IF en THEN s[i] := "-" ELSE s[i] := "+" END;

      (* Scale x to enough significant digits to reliably test for trailing
         zeroes or to the amount of space available, if greater. *)
      x0 := Ten(d-1);
      x  := x0 * x;
      x  := x + 0.5D0; (* Do not combine with previous line as doing so
                          introduces a least significant bit difference
                          between 32 bit and 64 bit builds. *)
      IF x >= 10.0D0 * x0 THEN x := 0.1D0 * x; INC(e) END;
      m := Entier64(x)
    END;

    DEC(i); IF long THEN s[i] := "D" ELSE s[i] := "E" END;

    (* Drop trailing zeroes where caller proposes to use less space *)
    IF dr < 2 THEN dr := 2 END;
    WHILE (d > dr) & (m MOD 10 = 0) DO m := m DIV 10; DEC(d) END;

    (* Render significant digits *)
    WHILE d > 1 DO digit(m, s, i); m := m DIV 10; DEC(d) END;
    DEC(i); s[i] := '.';
    digit(m, s, i);
  END;

  (* Generate leading padding *)
  DEC(n, LEN(s)-i); WHILE n > 0 DO Char(" "); DEC(n) END;

  (* Render prepared number from right end of buffer s *)
  IF nn THEN Char("-") END;
  WHILE i < LEN(s) DO Char(s[i]); INC(i) END
END RealP;


PROCEDURE Real*(x: REAL; n: INTEGER);
BEGIN RealP(x, n, FALSE);
END Real;

PROCEDURE LongReal*(x: LONGREAL; n: INTEGER);
BEGIN RealP(x, n, TRUE);
END LongReal;

BEGIN
  IsConsole := Platform.IsConsole(Platform.StdOut);
  in := 0
END Out.
