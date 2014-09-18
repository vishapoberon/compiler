MODULE Reals;
  (* JT, 5.2.90 / RC 9.12.91 conversion between reals and strings for HP-700, MB 9.12.91, JT for Ofront, 16.3. 95*)

  IMPORT S := SYSTEM;


  PROCEDURE -ecvt (x: LONGREAL; ndigit, decpt, sign: LONGINT): LONGINT
      "(LONGINT)ecvt (x, ndigit, decpt, sign)";

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
  
  PROCEDURE Expo*(x: REAL): INTEGER;
  BEGIN
    RETURN SHORT(ASH(S.VAL(LONGINT, x), -23) MOD 256)
  END Expo;
  
  PROCEDURE ExpoL*(x: LONGREAL): INTEGER;
    VAR h: LONGINT;
  BEGIN
    (*S.GET(S.ADR(x)+4, h);*) (* commented out, powerpc is big endian *)
    S.GET(S.ADR(x), h);
    RETURN SHORT(ASH(h, -20) MOD 2048)
  END ExpoL;
  
  PROCEDURE SetExpo*(e: INTEGER; VAR x: REAL);
    CONST expo = {1..8};
  BEGIN
    x := S.VAL(REAL, S.VAL(SET, x) - expo + S.VAL(SET, ASH(LONG(e), 23)))
  END SetExpo;
  
  PROCEDURE SetExpoL*(e: INTEGER; VAR x: LONGREAL);
    CONST expo = {1..11};
    VAR h: SET;
  BEGIN
    (*S.GET(S.ADR(x)+4, h);*) (* big endian *)
    S.GET(S.ADR(x), h);
    h := h - expo + S.VAL(SET, ASH(LONG(e), 20));
    (*S.PUT(S.ADR(x)+4, h)*)
    S.PUT(S.ADR(x), h)
  END SetExpoL;
  
  PROCEDURE Convert*(x: REAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR i, k: LONGINT;
  BEGIN
    i := ENTIER(x); k := 0;
    WHILE k < n DO
      d[k] := CHR(i MOD 10 + 48); i := i DIV 10; INC(k)
    END
  END Convert;
(*
  PROCEDURE ConvertL*(x: LONGREAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR i, k: LONGINT;
  BEGIN
    i := ENTIER(x); k := 0;
    WHILE k < n DO
      d[k] := CHR(i MOD 10 + 48); i := i DIV 10; INC(k)
    END
  END ConvertL;
 *)
  PROCEDURE ConvertL*(x: LONGREAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR decpt, sign, i: LONGINT; buf: LONGINT;
  BEGIN
    (*x := x - 0.5; already rounded in ecvt*)
    buf := ecvt(x, n+2, S.ADR(decpt), S.ADR(sign));
    i := 0;
    WHILE i < decpt DO S.GET(buf + i, d[n - i -1]); INC(i) END ; (* showdef was crashing here on oocLowLReal.sym because of ecvt *)
    i := n - i - 1;
    WHILE i >= 0 DO d[i] := "0"; DEC(i) END ;
  END ConvertL;

  PROCEDURE Unpack(VAR b, d: ARRAY OF S.BYTE);
    VAR i, k: SHORTINT; len: LONGINT;
  BEGIN i := 0; len := LEN(b);
    WHILE i < len DO
      k := SHORT(ORD(S.VAL(CHAR, b[i])) DIV 16);
      IF k > 9 THEN d[i*2] := k + 55 ELSE d[i*2] := k + 48 END ;
      k := SHORT(ORD(S.VAL(CHAR, b[i])) MOD 16);
      IF k > 9 THEN d[i*2+1] := k + 55 ELSE d[i*2+1] := k + 48 END ;
      INC(i)
    END
  END Unpack;
  
  PROCEDURE ConvertH* (y: REAL; VAR d: ARRAY OF CHAR);
  BEGIN Unpack(y, d)
  END ConvertH;
  
  PROCEDURE ConvertHL* (x: LONGREAL; VAR d: ARRAY OF CHAR);
  BEGIN Unpack(x, d)
  END ConvertHL;

END Reals.
