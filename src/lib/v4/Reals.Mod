MODULE Reals;
  (* JT, 5.2.90 / RC 9.12.91 conversion between reals and strings for HP-700, MB 9.12.91, JT for Ofront, 16.3. 95*)

  IMPORT S := SYSTEM;
(* getting rid of ecvt -- noch
  PROCEDURE -ecvt (x: LONGREAL; ndigit, decpt, sign: LONGINT): LONGINT
      "(LONGINT)ecvt (x, ndigit, decpt, sign)";
*)
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
    S.GET(S.ADR(x)+4, h);
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
    S.GET(S.ADR(x)+4, h);
    h := h - expo + S.VAL(SET, ASH(LONG(e), 20));
    S.PUT(S.ADR(x)+4, h)
  END SetExpoL;
  
   PROCEDURE Reverse0 (VAR str : ARRAY OF CHAR; start, end : INTEGER);
   (* Reverses order of characters in the interval [start..end]. *)
   VAR
     h : CHAR;
   BEGIN
     WHILE start < end DO
       h := str[start]; str[start] := str[end]; str[end] := h;
       INC(start); DEC(end)
     END
   END Reverse0;
   (* these functions ⇅ necessary to get rid of ecvt -- noch *)
   PROCEDURE IntToStr*(int: LONGINT; VAR str: ARRAY OF CHAR);
   (* Converts the value of `int' to string form and copies the possibly truncated
   result to `str'. *)
   VAR
     b : ARRAY 21 OF CHAR;
     s, e: INTEGER;
     maxLength : SHORTINT; (* maximum number of digits representing a LONGINT value *)
   BEGIN
     IF SIZE(LONGINT) = 4 THEN maxLength := 11 END;
     IF SIZE(LONGINT) = 8 THEN maxLength := 20 END;
     (* build representation in string 'b' *)
     IF int = MIN(LONGINT) THEN (* smallest LONGINT, -int is an overflow *)
       IF SIZE(LONGINT) = 4 THEN
          b := "-2147483648";
          e := 11
       ELSE (* SIZE(LONGINT) = 8 *)
          b := "-9223372036854775808";
          e := 20
       END	  
     ELSE
       IF int < 0 THEN (* negative sign *)
         b[0] := "-"; int := -int; s := 1
       ELSE (* no sign *)
         s := 0
       END;
       e := s; (* 's' holds starting position of string *)
       REPEAT
         b[e] := CHR(int MOD 10+ORD("0"));
         int := int DIV 10;
         INC(e)
       UNTIL int = 0;
       b[e] := 0X;
       Reverse0(b, s, e-1);
     END;
       COPY(b, str) (* truncate output if necessary *)
   END IntToStr;

  PROCEDURE Convert*(x: REAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR i, k: LONGINT;
  BEGIN IF x < 0 THEN x := -x END;
    i := ENTIER(x); k := 0;
    WHILE k < n DO
      d[k] := CHR(i MOD 10 + 48); i := i DIV 10; INC(k)
    END
  END Convert;
(* experimental, -- noch
  PROCEDURE Convert0*(x: REAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR i, j, k: LONGINT;
    str : ARRAY 32 OF CHAR;
  BEGIN
  (*  IF x = MIN(LONGREAL) THEN x := MAX(LONGREAL) END;*)
    IF x < 0 THEN x := -x END;
    i := ENTIER(x);
    IF i < 0 THEN i := -i END;
    IntToStr(i, str);
    IF n >= LEN(d) THEN n := SHORT(LEN(d)) - 1 END;
    d[n] := 0X;
    j := n - 1 ; 
    IF j < 0 THEN j := 0 END;
    k := 0;
    REPEAT
      d[j] := str[k];
      DEC(j);
      INC(k);
    UNTIL (str[k] = 0X) OR (j < 0);	

    WHILE j >= 0 DO d[j] := "0"; DEC(j) END ; 
  END Convert0;
*)
  (* this seem to work -- noch *)
  PROCEDURE ConvertL*(x: LONGREAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR i, j, k: LONGINT;
    str : ARRAY 32 OF CHAR;
  BEGIN
  (*  IF x = MIN(LONGREAL) THEN x := MAX(LONGREAL) END;*)
    IF x < 0 THEN x := -x END;
    i := ENTIER(x);
    IF i < 0 THEN i := -i END;
    IntToStr(i, str);
    IF n >= LEN(d) THEN n := SHORT(LEN(d)) - 1 END;
    d[n] := 0X;
    j := n - 1 ; 
    IF j < 0 THEN j := 0 END;
    k := 0;
    REPEAT
      d[j] := str[k];
      DEC(j);
      INC(k);
    UNTIL (str[k] = 0X) OR (j < 0);	

    WHILE j >= 0 DO d[j] := "0"; DEC(j) END ; 
  END ConvertL;
(* getting rid of ecvt -- noch
  PROCEDURE ConvertL*(x: LONGREAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR decpt, sign: INTEGER; i: LONGINT; buf: LONGINT;
  BEGIN
    (*x := x - 0.5; already rounded in ecvt*)
    buf := ecvt(x, n+2, S.ADR(decpt), S.ADR(sign));
    i := 0;
    WHILE i < decpt DO S.GET(buf + i, d[n - i -1]); INC(i) END ; (* showdef was crashing here on oocLowLReal.sym because of ecvt *)
    i := n - i - 1;
    WHILE i >= 0 DO d[i] := "0"; DEC(i) END ;
  END ConvertL;
*)
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
