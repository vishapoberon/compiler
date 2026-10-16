MODULE Line;   (* :file: Line.Mod  --  Functions about lines of text.  *)
(* VOC adaptation, 2026-10-16: fixed-width types and the VOC system adapter. *)
IMPORT ssqTypes, Sys := ssqSys, Int, Char, Str, String;


TYPE    INTEGER = ssqTypes.Integer;
        T*    = String.T;
        (** in opposition to String a Line is always full:
          * the terminating 0X is at last [LEN - 1] position
          *)


(* ------------------------------------------------------------------------- *)
(* :section:    new *)
PROCEDURE New* (VAR a: ARRAY OF CHAR): T;       (** return new line from AOC *)
BEGIN RETURN String.New (a); END New;

PROCEDURE Create* (a: ARRAY OF CHAR): T;        (** return new line from AOC or array constant *)
BEGIN RETURN String.Create (a); END Create;

PROCEDURE Copy* (l: T):T;                       (** return new copy of line *)
VAR nl: T;
BEGIN RETURN New (l^) END Copy;

PROCEDURE Length*(l: T): INTEGER;               (** return using LEN length of l, terminating 0X exclusive *)
BEGIN RETURN ssqTypes.Short(LEN(l^)) - 1 END Length;

PROCEDURE Spaces* (n: INTEGER): T;
VAR
   i: INTEGER;
   l: T;
BEGIN
   NEW (l, n + 1);
   FOR i := 0 TO n - 1 DO l[i] := ' ' END;
   l[n] := 0X;
   RETURN l
END Spaces;

PROCEDURE Print* (l: T);                         (** print (== dot) line *)
BEGIN String.Print(l) END Print;


(* ------------------------------------------------------------------------- *)
(* :section:    subsequence *)
PROCEDURE Head*(l: T; stop: Int.T): T;
VAR
   res: T;
BEGIN
   stop := 1 + Int.Min(stop, Length(l));       (* include terminating 0X *)
   NEW(res, stop);
   COPY(l^, res^);
   RETURN res;
END Head;

PROCEDURE Tail*(l: T; start: Int.T): T;
VAR
   len, i: Int.T;
   res: T;
BEGIN
   len   := Length(l);
   start := Int.Min(start, len);
   NEW(res, len - start + 1);
   FOR i := 0 TO len - start DO                  (* copy inclusive 0X *)
      res[i] := l[i + start];
   END;
   RETURN res;
END Tail;

PROCEDURE Body*(l: T; start, stop: Int.T): T;
VAR
   length, i: Int.T;
   res: T;
BEGIN
   start := Int.Max(0,     start);
   stop  := Int.Min(stop,  Length(l));
   stop  := Int.Max(start, stop);
   length := stop - start + 1;
   NEW(res, length);
   FOR i := 0 TO length - 2 DO          (* don't copy: stop, 0X *)
      res[i] := l[i + start]
   END;
   res[length-1] := 0X;
   RETURN res;
END Body;

(* ------------------------------------------------------------------------- *)
(* :section:    indentation *)
PROCEDURE Indentation*(l: T): INTEGER;
VAR
   i, max: INTEGER;
   res:    INTEGER;
BEGIN
   max := Length(l) + 1;
   i := 0;
   WHILE (i < max) & (l[i] = " ") DO INC(i) END;
   res := i;
   RETURN res;
END Indentation;

PROCEDURE Indent*(l: T; indent: INTEGER): T;
VAR
   i, max, ind, length, delta: INTEGER;
   res: T;
BEGIN
   max := Length(l) + 1;
   ind := Indentation(l);
   delta := indent - ind;
   length := max + delta;
   NEW(res, length);
   FOR i := 0   TO indent - 1 DO res[i] := " " END;
   FOR i := ind TO max - 1    DO
      res[i + delta] := l[i]
   END;
   res[length - 1] := 0X;
   RETURN res;
END Indent;

PROCEDURE Despace*(l :T): T;                    (** return new line with trailing spaces removed *)
VAR
   i, len, nlen: INTEGER;
   start,end: INTEGER;
   res: T;
BEGIN
   len := Length(l);
   start := 0;
   end   := len - 1;
   WHILE (end >= 0) & (l[end] = " ") DO DEC(end) END;
   nlen := end - start + 1;
   NEW(res, nlen + 1);
   FOR i := 0 TO nlen - 1 DO
      res[i] := l[i + start]
   END;
   res[nlen] := 0X;
   RETURN res;
END Despace;

PROCEDURE Despace1*(l :T): T;                   (** return new line with 1 trailing space *)
VAR
   i, len, nlen: INTEGER;
   res: T;
BEGIN
   len := Length(l);
   i   := len - 1;
   WHILE (i >= 0) & (l[i] = " ") DO DEC(i) END;
   nlen := i + 1;
   NEW(res, nlen + 2);
   FOR i := 0 TO nlen - 1 DO
      res[i] := l[i]
   END;
   res[nlen] := " ";
   res[nlen+1] := 0X;
   RETURN res;
END Despace1;

PROCEDURE DespaceLeft* (l: T): T;               (** return new line with leading spaces removed *)
VAR len,nlen,start,end,i: INTEGER;
   res: T;
BEGIN
   len   := Length (l);
   start := 0;
   WHILE (start < len) & (l[start] = ' ') DO INC (start) END;
   end  := len - 1;
   nlen := end - start + 1;
   NEW (res, nlen + 1);
   FOR i := 0 TO nlen - 1 DO
      res[i] := l[i + start]
   END;
   res[nlen] := 0X;
   RETURN res;
END DespaceLeft;


(* ------------------------------------------------------------------------- *)
(* :section:    concat *)
PROCEDURE Concat2*(l, m: T): T;                  (** return l ++ m *)
VAR
   i, len, llen, mlen: INTEGER;
   res: T;
BEGIN
   llen := Length(l);
   mlen := Length(m);
   len  := llen + mlen;
   NEW(res, len + 1);
   i := 0;
   WHILE i < llen DO
      res[i] := l[i];
      INC(i)
   END;
   WHILE i < len DO
      res[i] := m[i - llen];
      INC(i)
   END;
   res[i] := 0X;
   RETURN res;
END Concat2;

PROCEDURE Concat3*(l, m, r: T): T;              (** return l ++ m ++ r *)
VAR
   i, len, llen, mlen, rlen: INTEGER;
   res: T;
BEGIN
   llen := Length(l);
   mlen := Length(m);
   rlen := Length(r);
   len  := llen + mlen + rlen;
   NEW(res, len + 1);
   i := 0;
   WHILE i < llen  DO
      res[i] := l[i];
      INC(i)
   END;
   WHILE i < llen + mlen DO
      res[i] := m[i - llen];
      INC(i)
   END;
   WHILE i < len DO
      res[i] := r[i - llen - mlen];
      INC(i)
   END;
   res[i] := 0X;
   RETURN res;
END Concat3;


(* ------------------------------------------------------------------------- *)
(* :section:    replace *)
(* PROCEDURE Replace*(l: T; start, stop: INTEGER; m: T): T; *)
(* BEGIN RETURN Concat3(Head(l, start), m, Tail(l, stop)); END Replace; *)

(* PROCEDURE Delete*(l: T; start, stop: INTEGER): T; *)
(* BEGIN RETURN Replace(l, start, stop, Empty()); END Delete; *)

(* PROCEDURE Insert*(l: T; start: INTEGER; m: T): T; *)
(* BEGIN RETURN Replace(l, start, start, m); END Insert; *)


(* ------------------------------------------------------------------------- *)
(* :section:    test *)
PROCEDURE HasHead* (line, head: T): BOOLEAN;            (** does line start with head ? *)
BEGIN RETURN Str.HasHead (line^, head^) END HasHead;

PROCEDURE HasChar* (line: T; c: CHAR): BOOLEAN;         (** does line contain char c ? *)
BEGIN RETURN Str.HasChar (line^, c) END HasChar;

PROCEDURE IsEmpty*(l: T): BOOLEAN;                      (** return (indentation = length)  *)
BEGIN RETURN Indentation (l) = Length (l) END IsEmpty;


(* ------------------------------------------------------------------------- *)
(* :section:    find *)
PROCEDURE FindSeq* (line: T; VAR seq: ARRAY OF CHAR; VAR pos: INTEGER): BOOLEAN;
BEGIN RETURN Str.FindSeq (line^, seq, pos) END FindSeq;


(* ------------------------------------------------------------------------- *)
(* :section:    text processing *)
PROCEDURE TabLength (cx: INTEGER): INTEGER;
CONST
   TabSize = 8;
BEGIN RETURN TabSize - ((cx - 1) MOD TabSize)
END TabLength;

PROCEDURE Untabify* (l: T): T;                          (** return new line, tabs replaced with spaces *)
CONST ASize = 2048;
VAR
   i,j,k,len: INTEGER;
   nl: T;
   a:  ARRAY ASize OF CHAR;
BEGIN
   len := Length (l);
   i := 0;
   j := 0;
   WHILE i < len DO
      IF l[i] = 9X THEN
         FOR k := 1 TO TabLength (i) DO a[j] := ' '; INC (j); END;
      ELSE a[j] := l[i]; INC (j);
      END;
      INC (i);
      Sys.Assert (j + 1 < ASize, "Line.Untabify: line too long for const array a");
   END;
   a[j] := 0X;
   NEW  (nl, j + 1);
   COPY (a,  nl^);
   RETURN nl;
END Untabify;

PROCEDURE Upcase* (l:T; start, end:INTEGER): T;
VAR nl: T;
   i: INTEGER;
BEGIN
   NEW (nl, Length (l) + 1);
   Sys.Assert ((start >= 0) & (start < Length (l)), "Line.Upcase: start out of bounds");
   Sys.Assert ((end   >= 0) & (end  <= Length (l)), "Line.Upcase: end out of bounds");
   COPY (l^, nl^);
   FOR i := start TO end - 1 DO
      IF Char.IsLowercase (nl[i]) THEN
         nl[i] := CHR (ORD (nl[i]) - 32)
      END;
   END;
   RETURN nl;
END Upcase;

PROCEDURE Downcase* (l:T; start, end:INTEGER): T;
VAR nl: T;
   i: INTEGER;
BEGIN
   NEW (nl, Length (l) + 1);
   Sys.Assert ((start >= 0) & (start < Length (l)), "Line.Upcase: start out of bounds");
   Sys.Assert ((end   >= 0) & (end  <= Length (l)), "Line.Upcase: end out of bounds");
   COPY (l^, nl^);
   FOR i := start TO end - 1 DO
      IF Char.IsUppercase (nl[i]) THEN
         nl[i] := CHR (ORD (nl[i]) + 32)
      END;
   END;
   RETURN nl;
END Downcase;


(* ========================================================================= *)
END Line.
(* :file: (c) sts-q 2023-Mrz *)
