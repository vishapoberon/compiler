MODULE Reals;
  (* JT, 5.2.90 / RC 9.12.91 conversion between reals and strings for HP-700, MB 9.12.91, JT for Ofront, 16.3. 95*)
  (* DCWB 20160817 Made independent of INTEGER size *)
  (* Endian-neutral: exponent byte offsets are set at module initialisation *)

  IMPORT SYSTEM, Platform;

  VAR
    (* Byte offsets within a REAL/LONGREAL for the two exponent-carrying bytes.
       expHi: contains sign(1) + exponent MSBs
       expLo: contains exponent LSB(s) + fraction MSBs
       Little-endian: REAL  expHi=3 expLo=2 / LONGREAL expHi=7 expLo=6
       Big-endian:    REAL  expHi=0 expLo=1 / LONGREAL expHi=0 expLo=1 *)
    realExpHi,  realExpLo:  INTEGER;
    lrealExpHi, lrealExpLo: INTEGER;


  PROCEDURE Ten*(e: INTEGER): REAL;
  VAR r, power: LONGREAL;
  BEGIN r := 1.0;
    power := 10.0;
    WHILE e > 0 DO
      IF ODD(e) THEN r := r * power END ;
      power := power * power; e := e DIV 2
    END ;
    RETURN SHORT(r)
  END Ten;


  PROCEDURE TenL*(e: INTEGER): LONGREAL;
    VAR r, power: LONGREAL;
  BEGIN r := 1.0;
    power := 10.0;
    LOOP
      IF ODD(e) THEN r := r * power END ;
      e := e DIV 2;
      IF e <= 0 THEN RETURN r END ;
      power := power * power
    END
  END TenL;


  (* IEEE 754 exponent layout (MSB-first bit numbering):
       REAL     bit 31=sign, bits 30-23=exponent(8),  bits 22-0=fraction(23)
       LONGREAL bit 63=sign, bits 62-52=exponent(11), bits 51-0=fraction(52)

     expHi byte: sign(1) | exponent[MSBs]
     expLo byte: exponent[LSBs] | fraction[MSBs]

     REAL:     exponent = (ORD(expHi) * 2  + ORD(expLo) DIV 128) MOD 256
     LONGREAL: exponent = (ORD(expHi) * 16 + ORD(expLo) DIV 16 ) MOD 2048 *)


  PROCEDURE Expo*(x: REAL): INTEGER;
    VAR hi, lo: CHAR;
  BEGIN
    SYSTEM.GET(SYSTEM.ADR(x) + realExpHi, hi);
    SYSTEM.GET(SYSTEM.ADR(x) + realExpLo, lo);
    RETURN (ORD(hi) * 2 + ORD(lo) DIV 128) MOD 256
  END Expo;

  PROCEDURE SetExpo*(VAR x: REAL; ex: INTEGER);
    VAR c: CHAR;
  BEGIN
    SYSTEM.GET(SYSTEM.ADR(x) + realExpHi, c);
    SYSTEM.PUT(SYSTEM.ADR(x) + realExpHi, CHR((ORD(c) DIV 128) * 128 + (ex DIV 2) MOD 128));
    SYSTEM.GET(SYSTEM.ADR(x) + realExpLo, c);
    SYSTEM.PUT(SYSTEM.ADR(x) + realExpLo, CHR( ORD(c) MOD 128            + (ex MOD 2) * 128))
  END SetExpo;

  PROCEDURE ExpoL*(x: LONGREAL): INTEGER;
    VAR hi, lo: CHAR;
  BEGIN
    SYSTEM.GET(SYSTEM.ADR(x) + lrealExpHi, hi);
    SYSTEM.GET(SYSTEM.ADR(x) + lrealExpLo, lo);
    RETURN (ORD(hi) * 16 + ORD(lo) DIV 16) MOD 2048
  END ExpoL;

  PROCEDURE SetExpoL*(VAR x: LONGREAL; ex: INTEGER);
    VAR c: CHAR;
  BEGIN
    SYSTEM.GET(SYSTEM.ADR(x) + lrealExpHi, c);
    SYSTEM.PUT(SYSTEM.ADR(x) + lrealExpHi, CHR((ORD(c) DIV 128) * 128 + (ex DIV 16) MOD 128));
    SYSTEM.GET(SYSTEM.ADR(x) + lrealExpLo, c);
    SYSTEM.PUT(SYSTEM.ADR(x) + lrealExpLo, CHR((ex MOD 16) * 16        +  ORD(c) MOD 16))
  END SetExpoL;


  (* Convert LONGREAL: Write positive integer value of x into array d.
     The value is stored backwards, i.e. least significant digit
     first. n digits are written, with trailing zeros fill.
     On entry x has been scaled to the number of digits required. *)
  PROCEDURE ConvertL*(x: LONGREAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR i, j, k: LONGINT;
  BEGIN
    IF x < 0 THEN x := -x END;
    k := 0;

    IF (SIZE(LONGINT) < 8) & (n > 9) THEN
      (* There are more decimal digits than can be held in a single LONGINT *)
      i := ENTIER(x /      1000000000.0D0);  (* The 10th and higher digits *)
      j := ENTIER(x - (i * 1000000000.0D0)); (* The low 9 digits *)
      (* First generate the low 9 digits. *)
      IF j < 0 THEN j := 0 END;
      WHILE k < 9 DO
        d[k] := CHR(j MOD 10 + 48); j := j DIV 10; INC(k)
      END;
      (* Fall through to generate the upper digits *)
    ELSE
      (* We can generate all the digits in one go. *)
      i := ENTIER(x);
    END;

    WHILE k < n DO
      d[k] := CHR(i MOD 10 + 48); i := i DIV 10; INC(k)
    END
  END ConvertL;


  PROCEDURE Convert*(x: REAL; n: INTEGER; VAR d: ARRAY OF CHAR);
  BEGIN ConvertL(x, n, d)
  END Convert;

  PROCEDURE ToHex(i: INTEGER): CHAR;
  BEGIN
    IF i < 10 THEN RETURN CHR(i+48)
    ELSE           RETURN CHR(i+55) END
  END ToHex;

  PROCEDURE BytesToHex(VAR b, d: ARRAY OF SYSTEM.BYTE);
    VAR i, j, len: INTEGER; by: CHAR;
  BEGIN
    len := SHORT(LEN(b));
    IF Platform.LittleEndian THEN i := 0 ELSE i := len - 1 END;
    j := 0;
    WHILE (i >= 0) & (i < len) DO
      by := SYSTEM.VAL(CHAR, b[i]);
      d[j*2]   := ToHex(ORD(by) DIV 16);
      d[j*2+1] := ToHex(ORD(by) MOD 16);
      INC(j);
      IF Platform.LittleEndian THEN INC(i) ELSE DEC(i) END
    END
  END BytesToHex;

  (* Convert Hex *)
  PROCEDURE ConvertH*(y: REAL; VAR d: ARRAY OF CHAR);
  BEGIN BytesToHex(y, d)
  END ConvertH;

  (* Convert Hex Long *)
  PROCEDURE ConvertHL*(x: LONGREAL; VAR d: ARRAY OF CHAR);
  BEGIN BytesToHex(x, d)
  END ConvertHL;


  PROCEDURE InitEndian;
  BEGIN
    IF Platform.LittleEndian THEN
      realExpHi  := 3; realExpLo  := 2;
      lrealExpHi := 7; lrealExpLo := 6
    ELSE
      realExpHi  := 0; realExpLo  := 1;
      lrealExpHi := 0; lrealExpLo := 1
    END
  END InitEndian;

BEGIN
  InitEndian
END Reals.
