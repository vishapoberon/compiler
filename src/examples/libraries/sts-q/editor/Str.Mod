MODULE Str;   (* :file: Str.Mod.  --  Functions for Str: array of char *)
(* VOC adaptation, 2026-10-16: retain upstream's 32-bit integer contract. *)
IMPORT ssqTypes, Int;
TYPE INTEGER = ssqTypes.Integer;

(** Functions on str: ARRAY OF CHAR
  * An ASSERT is / should be raised in case of
  *     - a missing terminating 0X.
  *     - an index out of bounds. 
  *     - a result too large for it's array.
  **)


(* ------------------------------------------------------------------------- *)
(* :chapter: ARRAY OF CHAR *)
PROCEDURE Length* (VAR a: ARRAY OF CHAR): INTEGER;              (** return length up to terminating 0X *)
VAR
  i: INTEGER;
BEGIN
  i := 0;
  WHILE a[i] # 0X DO
     INC(i);
     ASSERT (i < LEN (a), 61)
  END;
  RETURN i
END Length;

PROCEDURE AlignRight*(VAR a: ARRAY OF CHAR; width: Int.T);      (** fill with spaces at left *)
VAR max,len,d,i : Int.T;
BEGIN
   max := ssqTypes.Short(LEN(a));
   len := Length(a);
   d   := width - len;
   IF Int.IsWithin (len+1, width, max) THEN
      FOR i := len-1 TO 0 BY -1 DO a[i+d] := a[i]; END;
      FOR i := 0     TO d-1     DO a[i] := " "     END;
      a[width] := 0X;
   END
END AlignRight;


(* ------------------------------------------------------------------------- *)
(* :section:    append *)
PROCEDURE Copy* (VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
BEGIN
   COPY (b, a);
END Copy;

PROCEDURE Append* (VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
(** a = a ++ b *)
VAR i,pos : INTEGER;
BEGIN
  pos := Length (a);
  i := 0;
  WHILE b[i] # 0X DO
    a[pos + i] := b[i];
    INC(i);
    ASSERT (i + 1 < LEN (a), 62);
  END;
  a[pos + i] := 0X;
END Append;

PROCEDURE AppendChar* (VAR a: ARRAY OF CHAR; c: CHAR);
VAR pos : INTEGER;
BEGIN
   pos := Length (a);
   ASSERT (pos + 1 < LEN (a), 63);
   a[pos]   := c;
   a[pos+1] := 0X;
END AppendChar;

PROCEDURE AppendInt* (VAR a: ARRAY OF CHAR; n, width :Int.T);
VAR s : ARRAY 32 OF CHAR;
BEGIN
   Int.Show (s, n, width);
   Append   (a, s);
END AppendInt;


(* ------------------------------------------------------------------------- *)
(* :section:    concat *)
PROCEDURE Concat2*(VAR a: ARRAY OF CHAR; VAR b,c: ARRAY OF CHAR); (** a = b ++ c *)
VAR
  maxa, i,j: INTEGER;
BEGIN
   maxa := ssqTypes.Short(LEN(a));
  i := 0;
  j := 0;
  WHILE (b[j] # 0X) DO
    ASSERT(i<maxa, 64);
    a[i] := b[j];
    INC(i);
    INC(j)
  END;
  j := 0;
  WHILE (c[j] # 0X) DO
    ASSERT(i<maxa, 65);
    a[i] := c[j];
    INC(i);
    INC(j)
  END;
  a[i] := 0X
END Concat2;

PROCEDURE Concat3*(VAR a: ARRAY OF CHAR; VAR b,c,d: ARRAY OF CHAR); (** a = b ++ c ++ d *)
BEGIN
  Concat2 (a,b,c);
  Append  (a,d);
END Concat3;


(* ------------------------------------------------------------------------- *)
(* :section:    push *)
PROCEDURE PushChr* (VAR a: ARRAY OF CHAR; VAR pos: Int.T; c: CHAR);     (** a = a ++ 'c' *)
VAR len: INTEGER;
BEGIN
   ASSERT(pos + 1 < LEN (a), 66);
   a[pos]   := c;
   a[pos+1] := 0X;
   INC (pos)
END PushChr;

PROCEDURE PushStr*(VAR a: ARRAY OF CHAR; VAR pos: Int.T; VAR b: ARRAY OF CHAR);   (** a = a ++ b *)
VAR max,i,j: Int.T;
BEGIN
   max := ssqTypes.Short(LEN(a));
  i := pos;
  j := 0;
  WHILE (i < max) & (b[j] # 0X) DO
    a[i] := b[j];
    INC(i);  
    INC(j);
  END;
  ASSERT(i < max, 67);
  a[i] := 0X;
  pos := i;
END PushStr;

PROCEDURE PushInt* (VAR a: ARRAY OF CHAR; VAR pos: Int.T; n,width: Int.T);
VAR s : ARRAY 32 OF CHAR;
BEGIN
   Int.Show   (s, n, width);
   PushStr    (a, pos, s);
END PushInt;

PROCEDURE PushSeq* (VAR a: ARRAY OF CHAR; VAR pos: Int.T; VAR seq: ARRAY OF CHAR; start, end: Int.T);
VAR
   i,j: Int.T;
BEGIN
   ASSERT (pos + end - start  < LEN (a), 71);
   ASSERT (start <= end, 72);
   ASSERT (end <= LEN (seq), 73);
   i := pos;
   j := start;
   WHILE (j < end) DO
      a[i] := seq[j];
      INC (i);
      INC (j);
   END;
   a[i] := 0X;
   pos := i;
END PushSeq;

PROCEDURE PushTab* (VAR a: ARRAY OF CHAR; VAR pos: Int.T; tab: Int.T);
BEGIN
   ASSERT (tab + 1 < LEN (a), 68);
   WHILE (pos < tab) DO
      a[pos] := " ";
      INC(pos);
   END;
   a[pos] := 0X;
END PushTab;


(* ------------------------------------------------------------------------- *)
(* :section:    substring *)
PROCEDURE Sub* (VAR res, src: ARRAY OF CHAR; start, end: Int.T);        (** exclusive end *)
VAR i : Int.T;
BEGIN
   ASSERT ((0 <= start) & (start <= end) & (end < LEN (src)), 69);
   ASSERT (end - start < LEN (res), 69);
   FOR i := 0 TO end - start - 1 DO res[i] := src[i + start] END;
   res[end - start] := 0X;
END Sub; 

PROCEDURE Head* (VAR res, src: ARRAY OF CHAR; end: Int.T);              (** exclusive end *)
BEGIN Sub (res, src, 0, end) END Head;

PROCEDURE Tail* (VAR res, src: ARRAY OF CHAR; start: Int.T);
BEGIN Sub (res, src, start, Length (src)) END Tail;


(* ------------------------------------------------------------------------- *)
(* :section:    tests *)
PROCEDURE HasChar* (VAR a: ARRAY OF CHAR; c: CHAR): BOOLEAN;
VAR
   i  : INTEGER;
   cc :CHAR;
BEGIN
   i := 0;
   REPEAT
      cc := a[i];
      INC (i)
   UNTIL (c = cc) OR (cc = 0X);
   RETURN c = cc
END HasChar;

PROCEDURE HasHead* (VAR a, head: ARRAY OF CHAR): BOOLEAN;
VAR
   i   : INTEGER;
   c,d : CHAR;
BEGIN
   i   := 0;
   REPEAT
      c := head[i];
      d := a[i];
      INC (i);
   UNTIL (c # d) OR (c = 0X) OR (d = 0X);
   RETURN c = 0X
END HasHead;

PROCEDURE HasSeq* (VAR a, seq: ARRAY OF CHAR): BOOLEAN;
VAR
   i,j: INTEGER;
   c,d: CHAR;
BEGIN
   i := 0;
   REPEAT
      j   := 0;
      REPEAT
         c := seq[j];
         d := a  [j + i];
         INC (j);
      UNTIL (c # d) OR (c = 0X) OR (d = 0X);
      INC (i);
   UNTIL (c = 0X) OR (d = 0X);
   RETURN c = 0X
END HasSeq;


(* ------------------------------------------------------------------------- *)
(* :section:    find *)
PROCEDURE FindChar* (VAR a: ARRAY OF CHAR; c: CHAR; VAR pos: INTEGER): BOOLEAN;
(** return TRUE and pos if found
  * return FALSE and leave pos unchanged if not found
  *)
VAR
   i: INTEGER;
   cc: CHAR;
   res: BOOLEAN;
BEGIN
   i := pos;
   REPEAT
      cc := a[i];
      INC (i);
   UNTIL (cc = 0X) OR (cc = c); 
   IF cc = c THEN
      pos := i - 1;
      res := TRUE;
   ELSE res := FALSE;
   END;
   RETURN res
END FindChar;

PROCEDURE FindCharBackwards* (VAR a: ARRAY OF CHAR; c: CHAR; VAR pos: INTEGER): BOOLEAN;
(** return TRUE and pos if found
  * return FALSE and leave pos unchanged if not found
  *)
VAR 
   i: INTEGER;
   res: BOOLEAN;
BEGIN
   i := pos;
   WHILE (i >= 0) & (a[i] # c) DO DEC (i) END;
   IF a[i] = c THEN 
      pos := i;
      res := TRUE
   ELSE res := FALSE;
   END;
   RETURN res 
END FindCharBackwards;

PROCEDURE FindCharLast* (VAR a: ARRAY OF CHAR; c: CHAR; VAR pos: INTEGER):BOOLEAN;
(** return TRUE and pos if found
  * return FALSE and pos:=Length(a) if not found
  *)
BEGIN
   pos := Length (a);
   RETURN FindCharBackwards (a, c, pos)
END FindCharLast; 

PROCEDURE FindSeq* (VAR a, seq: ARRAY OF CHAR; VAR pos: INTEGER): BOOLEAN;
VAR
   i,j: INTEGER;
   c,d: CHAR;
   res: BOOLEAN;
BEGIN
   res := FALSE;
   i := pos;
   REPEAT
      j := 0;
      REPEAT
         c := seq[j];
         d := a  [j + i];
         INC (j);
      UNTIL (c # d) OR (c = 0X) OR (d = 0X);
      INC (i);
   UNTIL (c = 0X) OR (d = 0X);
   IF c = 0X THEN
      pos := i - 1;
      res := TRUE
   END;
   RETURN res
END FindSeq;


(* ------------------------------------------------------------------------- *)

END Str.
   
(* ------------------------------------------------------------------------- *)
(* :file: (c) sts-q 2024-Feb *)
