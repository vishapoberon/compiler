MODULE Int;   (* :file: Int.Mod  --  Integer function procedures. *)
(* VOC adaptation, 2026-10-16: fixed-width types and the VOC system adapter. *)
IMPORT ssqTypes, Sys := ssqSys;
    
TYPE
        INTEGER = ssqTypes.Integer;
        T* = ssqTypes.Longint;


PROCEDURE And*(i,j: INTEGER): INTEGER;
BEGIN RETURN Sys.BitAnd(i,j) END And;

PROCEDURE Or*(i,j: INTEGER): INTEGER;
BEGIN RETURN Sys.BitOr(i,j) END Or;

PROCEDURE Xor*(i,j: INTEGER): INTEGER;
BEGIN RETURN Sys.BitXor(i,j) END Xor;

PROCEDURE Fac*(n: T): T;
VAR i,r: T;
BEGIN
   r := 1;
   i := 1;
   WHILE i <= n DO
      r := r * i;
      INC(i)
   END;
   RETURN r
END Fac;


PROCEDURE Fib*(n: T): T;
VAR r: T;
BEGIN
   IF n < 2 THEN
      r := n
   ELSE r :=  Fib(n-1) + Fib(n-2)
   END;
   RETURN r
END Fib;

PROCEDURE Max*(i,j: T): T;
BEGIN
   IF i < j THEN i := j END;
   RETURN i
END Max;

PROCEDURE Min*(i,j: T): T;
BEGIN
   IF i > j THEN i := j END;
   RETURN i
END Min;

PROCEDURE ShortMin* (i,j: T): INTEGER;
BEGIN RETURN ssqTypes.Short (Min (i,j)) END ShortMin;

PROCEDURE ShortMax* (i,j: T): INTEGER;
BEGIN RETURN ssqTypes.Short (Max (i,j)) END ShortMax;

PROCEDURE Muldivmod*(VAR d,m: T; i,j,k: T); (* currently all values are Int.T, no 128-bit intermediate *)
VAR aa,dd,mm: T;
BEGIN
   aa := i * j;
   dd := aa DIV k;
   mm := aa MOD k;
   d := dd;
   m := mm;
END Muldivmod;

PROCEDURE KeepWithin*(min, n, max: T): T;
BEGIN RETURN Max(min, Min(n, max)) END KeepWithin;

PROCEDURE Power*(n, exp: INTEGER): INTEGER;
VAR i,res: INTEGER;
BEGIN
   ASSERT( exp >= 0, 43);
   res := 1;
   FOR i := 1 TO exp DO res := res * n; END;
   RETURN res
END Power;

PROCEDURE Sign*(i: INTEGER): INTEGER;
VAR res: INTEGER;
BEGIN
   IF    i < 0 THEN res := -1
   ELSIF i = 0 THEN res :=  0
   ELSE             res :=  1
   END;
   RETURN res
END Sign;

PROCEDURE Sqrt*(n: INTEGER): INTEGER;
VAR x,p: INTEGER;
BEGIN
   x := n DIV 2;
   p := 0;
   WHILE x # p DO
      p := x;
      x := x - ((x - (n DIV x)) DIV 2)
   END;
   RETURN x
END Sqrt;


(* ------------------------------------------------------------------------- *)
(* :section:    test *)
PROCEDURE IsPrime*(n: INTEGER): BOOLEAN;
VAR
   i: INTEGER;
   res: BOOLEAN;
BEGIN
  n := ABS(n);
  IF    n < 2       THEN res := FALSE                   (* 0 1 *)
  ELSIF n < 4       THEN res := TRUE                    (* 2 3 *)
  ELSIF n MOD 2 = 0 THEN res := FALSE
  ELSIF n < 9       THEN res := TRUE                    (* 7 *)
  ELSIF n MOD 3 = 0 THEN res := FALSE
  ELSE
    i := 5;
    res := TRUE;
    WHILE (i*i < n+2) & res DO
      IF (n MOD i = 0) OR (n MOD (i+2) = 0) THEN res := FALSE END;
      INC(i, 6)
    END;
  END;
  RETURN res
END IsPrime;

PROCEDURE IsWithin*(i,j,k: T): BOOLEAN;                  (* i <= j < k *)
BEGIN RETURN  (i<=j) & (j<k) END IsWithin;


(* ------------------------------------------------------------------------- *)
(* :section:    read *)
PROCEDURE Read* (a: ARRAY OF CHAR; VAR pos: INTEGER): T;
(** Return an Integer read from ARRAY OF CHAR.
  * Start reading at pos.
  * Stop reading at first non-digit.
  * Fail, if pos does not point to a digit.
  *)
VAR
   max,i : INTEGER;
   c     : CHAR;
   res   : T;
BEGIN
(*    Sys.Out (a); *)
   max := ssqTypes.Short (LEN (a));
   res := 0;
   i   := pos;
   WHILE i < max DO
      c := a[i];
      IF (c >= "0") & (c <= "9") THEN
         res := res * 10 + ORD(c) - 48;
         INC(i)
      ELSE
         max := 0
      END
   END;
   Sys.Assert (i > pos, "Int.Read: error");
   pos := i;
   RETURN res
END Read;


(* ------------------------------------------------------------------------- *)
(* :section:    show *)
PROCEDURE Show*(VAR s: ARRAY OF CHAR; n,width: T);
(** Write s with ascii representation of n.
  * Align to right to width.
  * Terminate with 0X
  * s must be 21 characters of length, or longer.
  * TODO: align n = Min
  *)
CONST
   sa  = 32;  (* size of array *)
   Min = -9223372036854775 * 1000 - 808;   (* Number too large for voc-parser *)
VAR
   i,j,d,len,spc : T;
   r: ARRAY sa OF CHAR;
   neg : BOOLEAN;
   c: CHAR;
BEGIN
  (* store string at tail of s *)
  i := sa;   (* i points full *)
  DEC(i);
  r[i] := 0X;
  IF n = 0 THEN
     ASSERT (width + 2 < LEN (s), 45);
     FOR i := 0 TO width - 2 DO s[i] := ' ' END;
     s[i] := '0';
     s[i+1] := 0X
  ELSIF n = Min THEN COPY ("-9223372036854775808", s)
  ELSE
    IF n < 0 THEN
      n   := -n;
      neg := TRUE
    ELSE neg := FALSE
    END;
    WHILE n > 0 DO
      d := n MOD 10;
      n := n DIV 10;
      DEC( i );
      r[i] := CHR(d + 48);
    END;
    IF neg THEN DEC(i); r[i] := "-" END;
    len := sa - 1 - i;
    spc := Max (0, width - len);
    ASSERT (spc + len + 1 < LEN (s), 46);
    FOR j := 1 TO spc DO s[j - 1] := ' ' END;
    j := 0;
    REPEAT
      c := r[i+j];
      s[j + spc] := c;
      INC(j);
    UNTIL c = 0X;
  END;
END Show;
  
PROCEDURE Show00* (VAR a: ARRAY OF CHAR; n: INTEGER);
BEGIN
   ASSERT (n <= 99, 47);
   Show (a, n, 2);
   IF a[0] = ' ' THEN
      a[0] := '0'
   END 
END Show00;


(*---------------------------------------------------------------------------*)
END Int.   :file: (c) sts-q 2022-Feb,Nov   2024-Feb
