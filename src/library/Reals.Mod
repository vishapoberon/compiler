MODULE Reals;
  (* JT, 5.2.90 / RC 9.12.91 conversion between reals and strings for HP-700, MB 9.12.91, JT for Ofront, 16.3. 95*)
  (* DCWB 20160817 Made independent of INTEGER size *)
  (* Endian-neutral: exponent byte offsets are set at module initialisation *)

  IMPORT SYSTEM, Platform;

  CONST
    limbBits = 15; limbBase = 32768; limbCount = 512;
    (* Every binary32/binary64 rounding midpoint has fewer significant decimal
       digits. A nonzero discarded tail therefore only needs a sticky digit. *)
    MaxDecimalDigits* = 1100;
    decimalDigits = MaxDecimalDigits;

  TYPE
    Big = RECORD
      len: INTEGER;
      digit: ARRAY limbCount OF SYSTEM.INT32
    END;

  VAR
    (* Byte offsets within a REAL/LONGREAL for the two exponent-carrying bytes.
       expHi: contains sign(1) + exponent MSBs
       expLo: contains exponent LSB(s) + fraction MSBs
       Little-endian: REAL  expHi=3 expLo=2 / LONGREAL expHi=7 expLo=6
       Big-endian:    REAL  expHi=0 expLo=1 / LONGREAL expHi=0 expLo=1 *)
    realExpHi,  realExpLo:  INTEGER;
    lrealExpHi, lrealExpLo: INTEGER;

  (* Integer limbs keep decimal conversion independent of the host's libc,
     floating-point rounding mode and Oberon INTEGER/LONGINT size model. *)
  PROCEDURE FromInt(value: SYSTEM.INT64; VAR a: Big);
  BEGIN
    a.len := 0;
    WHILE value > 0 DO
      a.digit[a.len] := SHORT(value MOD limbBase); INC(a.len);
      value := value DIV limbBase
    END
  END FromInt;

  PROCEDURE Trim(VAR a: Big);
  BEGIN WHILE (a.len > 0) & (a.digit[a.len-1] = 0) DO DEC(a.len) END END Trim;

  PROCEDURE Multiply(VAR a: Big; factor: SYSTEM.INT32);
    VAR i: INTEGER; value, carry: SYSTEM.INT32;
  BEGIN
    carry := 0;
    FOR i := 0 TO a.len-1 DO
      value := a.digit[i]*factor + carry;
      a.digit[i] := value MOD limbBase; carry := value DIV limbBase
    END;
    IF carry > 0 THEN
      ASSERT(a.len < limbCount); a.digit[a.len] := carry; INC(a.len)
    END
  END Multiply;

  PROCEDURE AddDigit(VAR a: Big; value: SYSTEM.INT32);
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE value > 0 DO
      IF i = a.len THEN ASSERT(i < limbCount); a.digit[i] := 0; INC(a.len) END;
      INC(value, a.digit[i]); a.digit[i] := value MOD limbBase;
      value := value DIV limbBase; INC(i)
    END
  END AddDigit;

  PROCEDURE Shift(VAR a: Big; bits: INTEGER; VAR b: Big);
    VAR i, words: INTEGER; factor, value, carry: SYSTEM.INT32;
  BEGIN
    IF a.len = 0 THEN b.len := 0; RETURN END;
    words := bits DIV limbBits; factor := 1; factor := SYSTEM.LSH(factor, bits MOD limbBits);
    ASSERT(a.len + words + 1 <= limbCount);
    FOR i := 0 TO words-1 DO b.digit[i] := 0 END;
    carry := 0;
    FOR i := 0 TO a.len-1 DO
      value := a.digit[i]*factor + carry;
      b.digit[i+words] := value MOD limbBase; carry := value DIV limbBase
    END;
    b.len := a.len + words;
    IF carry > 0 THEN b.digit[b.len] := carry; INC(b.len) END
  END Shift;

  PROCEDURE Half(VAR a: Big);
    VAR i: INTEGER; value, carry: SYSTEM.INT32;
  BEGIN
    carry := 0;
    FOR i := a.len-1 TO 0 BY -1 DO
      value := carry*limbBase + a.digit[i];
      a.digit[i] := value DIV 2; carry := value MOD 2
    END;
    Trim(a)
  END Half;

  PROCEDURE Compare(VAR a, b: Big): INTEGER;
    VAR i: INTEGER;
  BEGIN
    IF a.len < b.len THEN RETURN -1 ELSIF a.len > b.len THEN RETURN 1 END;
    i := a.len;
    WHILE i > 0 DO
      DEC(i);
      IF a.digit[i] < b.digit[i] THEN RETURN -1
      ELSIF a.digit[i] > b.digit[i] THEN RETURN 1 END
    END;
    RETURN 0
  END Compare;

  PROCEDURE Subtract(VAR a, b: Big);
    VAR i: INTEGER; value, borrow: SYSTEM.INT32;
  BEGIN
    borrow := 0;
    FOR i := 0 TO a.len-1 DO
      value := a.digit[i] - borrow;
      IF i < b.len THEN DEC(value, b.digit[i]) END;
      IF value < 0 THEN INC(value, limbBase); borrow := 1 ELSE borrow := 0 END;
      a.digit[i] := value
    END;
    ASSERT(borrow = 0); Trim(a)
  END Subtract;

  PROCEDURE BitLength(VAR a: Big): INTEGER;
    VAR n: INTEGER; value: SYSTEM.INT32;
  BEGIN
    IF a.len = 0 THEN RETURN 0 END;
    n := (a.len-1)*limbBits; value := a.digit[a.len-1];
    WHILE value > 0 DO INC(n); value := value DIV 2 END;
    RETURN n
  END BitLength;

  PROCEDURE SignedBits(bits: SYSTEM.INT64; negative, single: BOOLEAN): SYSTEM.INT64;
  BEGIN
    IF negative THEN
      IF single THEN DEC(bits, 2147483648) ELSE INC(bits, MIN(SYSTEM.INT64)) END
    END;
    RETURN bits
  END SignedBits;

  PROCEDURE ParseBits(text: ARRAY OF CHAR; single: BOOLEAN): SYSTEM.INT64;
    VAR numerator, denominator, temporary: Big;
      position: SYSTEM.ADDRESS;
      count, precision, minimum, maximum, exponent, shift, j, comparison: INTEGER;
      digit: SYSTEM.INT32; scale, explicit, magnitude, unit, quotient, bits: SYSTEM.INT64;
      negative, point, sticky, negExp: BOOLEAN; ch: CHAR;
  BEGIN
    position := 0; count := 0; scale := 0; point := FALSE; sticky := FALSE;
    negative := FALSE; numerator.len := 0;
    IF LEN(text) = 0 THEN RETURN 0 END;
    IF text[0] = "-" THEN negative := TRUE; INC(position)
    ELSIF text[0] = "+" THEN INC(position) END;
    LOOP
      IF position >= LEN(text) THEN EXIT END;
      ch := text[position];
      IF (ch >= "0") & (ch <= "9") THEN
        digit := ORD(ch)-ORD("0");
        IF (count > 0) OR (digit # 0) THEN
          IF count < decimalDigits THEN
            Multiply(numerator, 10); AddDigit(numerator, digit); INC(count);
            IF point THEN DEC(scale) END
          ELSE
            sticky := sticky OR (digit # 0);
            IF ~point THEN INC(scale) END
          END
        ELSIF point THEN DEC(scale)
        END
      ELSIF (ch = ".") & ~point THEN point := TRUE
      ELSE EXIT
      END;
      INC(position)
    END;
    explicit := 0; negExp := FALSE;
    IF (position < LEN(text)) & ((text[position] = "E") OR (text[position] = "e") OR (text[position] = "D")) THEN
      INC(position);
      IF (position < LEN(text)) & (text[position] = "-") THEN negExp := TRUE; INC(position)
      ELSIF (position < LEN(text)) & (text[position] = "+") THEN INC(position) END;
      LOOP
        IF position >= LEN(text) THEN EXIT END;
        ch := text[position]; IF (ch < "0") OR (ch > "9") THEN EXIT END;
        digit := ORD(ch)-ORD("0");
        IF explicit <= (MAX(SYSTEM.INT64)-digit) DIV 10 THEN explicit := explicit*10 + digit
        ELSE explicit := MAX(SYSTEM.INT64) END;
        INC(position)
      END
    END;
    IF negExp THEN explicit := -explicit END;
    IF (explicit > 0) & (scale > MAX(SYSTEM.INT64)-explicit) THEN scale := MAX(SYSTEM.INT64)
    ELSIF (explicit < 0) & (scale < MIN(SYSTEM.INT64)-explicit) THEN scale := MIN(SYSTEM.INT64)
    ELSE INC(scale, explicit) END;
    IF single THEN precision := 24; minimum := -126; maximum := 127
    ELSE precision := 53; minimum := -1022; maximum := 1023 END;
    unit := SYSTEM.LSH(SYSTEM.VAL(SYSTEM.INT64, 1), precision-1);
    IF numerator.len = 0 THEN RETURN SignedBits(0, negative, single) END;
    IF scale > 400 THEN RETURN SignedBits((2*maximum+1)*unit, negative, single)
    ELSIF scale < -decimalDigits-401 THEN RETURN SignedBits(0, negative, single) END;
    IF sticky THEN Multiply(numerator, 10); AddDigit(numerator, 1); INC(count); DEC(scale) END;
    magnitude := scale + count-1;
    IF magnitude > 400 THEN RETURN SignedBits((2*maximum+1)*unit, negative, single)
    ELSIF magnitude < -400 THEN RETURN SignedBits(0, negative, single) END;
    FromInt(1, denominator);
    IF scale >= 0 THEN
      WHILE scale > 0 DO Multiply(numerator, 10); DEC(scale) END
    ELSE
      WHILE scale < 0 DO Multiply(denominator, 10); INC(scale) END
    END;
    exponent := BitLength(numerator)-BitLength(denominator);
    IF exponent >= 0 THEN
      Shift(denominator, exponent, temporary);
      IF Compare(numerator, temporary) < 0 THEN DEC(exponent) END
    ELSE
      Shift(numerator, -exponent, temporary);
      IF Compare(temporary, denominator) < 0 THEN DEC(exponent) END
    END;
    IF exponent > maximum THEN RETURN SignedBits((2*maximum+1)*unit, negative, single) END;
    IF exponent >= minimum THEN shift := precision-1-exponent
    ELSE shift := precision-1-minimum END;
    IF shift >= 0 THEN Shift(numerator, shift, temporary); numerator := temporary
    ELSE Shift(denominator, -shift, temporary); denominator := temporary END;
    quotient := 0; j := BitLength(numerator)-BitLength(denominator);
    IF j >= 0 THEN
      ASSERT(j <= precision); Shift(denominator, j, temporary);
      WHILE j >= 0 DO
        quotient := quotient*2;
        IF Compare(numerator, temporary) >= 0 THEN Subtract(numerator, temporary); INC(quotient) END;
        Half(temporary); DEC(j)
      END
    END;
    Shift(numerator, 1, temporary); comparison := Compare(temporary, denominator);
    IF (comparison > 0) OR ((comparison = 0) & ODD(quotient)) THEN INC(quotient) END;
    IF exponent < minimum THEN bits := quotient
    ELSE
      IF quotient = 2*unit THEN quotient := quotient DIV 2; INC(exponent) END;
      IF exponent > maximum THEN bits := (2*maximum+1)*unit
      ELSE bits := (exponent+maximum)*unit + quotient-unit END
    END;
    RETURN SignedBits(bits, negative, single)
  END ParseBits;

  (* Callers validate decimal token syntax. Round to nearest, ties to even,
     including subnormals and signed zero; overflow produces IEEE infinity. *)
  PROCEDURE ParseReal*(text: ARRAY OF CHAR): REAL;
    VAR bits: SYSTEM.INT32;
  BEGIN bits := SHORT(ParseBits(text, TRUE)); RETURN SYSTEM.VAL(REAL, bits) END ParseReal;

  PROCEDURE ParseLongReal*(text: ARRAY OF CHAR): LONGREAL;
    VAR bits: SYSTEM.INT64;
  BEGIN bits := ParseBits(text, FALSE); RETURN SYSTEM.VAL(LONGREAL, bits) END ParseLongReal;

  PROCEDURE DivideTen(VAR a: Big): CHAR;
    VAR i: INTEGER; value, remainder: SYSTEM.INT32;
  BEGIN
    remainder := 0;
    FOR i := a.len-1 TO 0 BY -1 DO
      value := remainder*limbBase + a.digit[i];
      a.digit[i] := value DIV 10; remainder := value MOD 10
    END;
    Trim(a); RETURN CHR(remainder + ORD("0"))
  END DivideTen;

  (* Seventeen decimal significant digits preserve every finite binary64
     value on readback. Generate them from its exact integer/power-of-two
     representation, then round in decimal with ties to even. *)
  PROCEDURE FormatLongReal*(value: LONGREAL; VAR text: ARRAY OF CHAR);
    VAR a, temporary: Big;
      reverse: ARRAY decimalDigits OF CHAR; digits: ARRAY 17 OF CHAR; exp: ARRAY 8 OF CHAR;
      bits, mantissa: SYSTEM.INT64;
      binary, scale, exponent, count, kept, i, j, position, n: INTEGER;
      negative, round: BOOLEAN;
  BEGIN
    ASSERT(LEN(text) >= 32);
    bits := SYSTEM.VAL(SYSTEM.INT64, value); negative := bits < 0;
    binary := SHORT(SHORT(SYSTEM.LSH(bits, -52) MOD 2048)); ASSERT(binary # 2047);
    mantissa := bits MOD 10000000000000H;
    IF binary # 0 THEN INC(mantissa, 10000000000000H); binary := binary-1023-52
    ELSE binary := -1074 END;
    FromInt(mantissa, a); scale := 0;
    IF binary >= 0 THEN Shift(a, binary, temporary); a := temporary
    ELSE scale := -binary;
      WHILE binary < 0 DO Multiply(a, 5); INC(binary) END
    END;
    count := 0;
    WHILE a.len > 0 DO reverse[count] := DivideTen(a); INC(count) END;
    IF count = 0 THEN reverse[0] := "0"; count := 1; scale := 0 END;
    exponent := count-scale-1;
    IF count > 17 THEN kept := 17 ELSE kept := count END;
    FOR i := 0 TO kept-1 DO digits[i] := reverse[count-1-i] END;
    IF count > kept THEN
      i := count-kept-1; round := reverse[i] > "5";
      IF reverse[i] = "5" THEN
        round := ODD(ORD(digits[kept-1])-ORD("0"));
        WHILE i > 0 DO DEC(i); round := round OR (reverse[i] # "0") END
      END;
      IF round THEN
        i := kept-1;
        WHILE (i > 0) & (digits[i] = "9") DO digits[i] := "0"; DEC(i) END;
        IF digits[i] = "9" THEN digits[i] := "1"; INC(exponent)
        ELSE digits[i] := CHR(ORD(digits[i])+1) END
      END
    END;
    WHILE (kept > 1) & (digits[kept-1] = "0") DO DEC(kept) END;
    position := 0;
    IF negative THEN text[position] := "-"; INC(position) END;
    text[position] := digits[0]; INC(position); text[position] := "."; INC(position);
    IF kept = 1 THEN text[position] := "0"; INC(position)
    ELSE FOR i := 1 TO kept-1 DO text[position] := digits[i]; INC(position) END END;
    text[position] := "e"; INC(position);
    IF exponent < 0 THEN text[position] := "-"; INC(position); exponent := -exponent END;
    n := 0;
    REPEAT exp[n] := CHR(exponent MOD 10 + ORD("0")); INC(n); exponent := exponent DIV 10 UNTIL exponent = 0;
    FOR j := n-1 TO 0 BY -1 DO text[position] := exp[j]; INC(position) END;
    text[position] := 0X
  END FormatLongReal;


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
