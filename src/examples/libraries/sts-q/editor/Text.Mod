MODULE Text;   (* :file: Text.Mod  --  Text handling. *)
(* VOC adaptation, 2026-10-16: fixed-width types and the VOC system adapter. *)
IMPORT ssqTypes, Sys := ssqSys, Char, Int, Str, String, Line, Dot;

CONST
        LoadBufferSize  = 8000000;
        SizeMax = 8000;
        SizeStd = 8000;


TYPE
        INTEGER = ssqTypes.Integer;
        Lines    = POINTER TO ARRAY OF Line.T;  (* in principle resizeable, (resizing needs type Lines) *)

        T*       = POINTER TO TextDesc;
        TextDesc = RECORD
                        name     : Line.T;
                        path     : Line.T;
                        lines    : Lines;
                        ff       : INTEGER;
                        size     : INTEGER;
                        modified : BOOLEAN;
                     END;

        ModProc = PROCEDURE (l:Line.T; cy,cx: INTEGER): Line.T;


VAR 
        mess*: ARRAY 64 OF CHAR;


(* ========================================================================= *)
(* :chapter: NEW *)
PROCEDURE New*(VAR t: T; size: INTEGER);
VAR ls:  Lines;
BEGIN
   Sys.Assert (size <= SizeMax, "Text.New: size too large");
   NEW (ls, size);
   NEW (t);
   t.name     := Line.Create ("<name>");
   t.path     := Line.Create ("<path>");
   t.lines    := ls;
   t.ff       := 0;
   t.size     := size;
   t.modified := FALSE;
   Sys.Assert (t # NIL, "Text.New: res = NIL");
END New;

PROCEDURE SetPath*(t: T; VAR path: ARRAY OF CHAR);
BEGIN t.path := Line.New (path); END SetPath;

PROCEDURE SetName*(t: T; VAR name: ARRAY OF CHAR);
BEGIN t.name := Line.New (name); END SetName;

PROCEDURE SetModified* (t: T; b: BOOLEAN);
BEGIN t.modified := b END SetModified;

PROCEDURE Name* (t: T): Line.T;
BEGIN RETURN t.name END Name;

PROCEDURE Path* (t: T): Line.T;
BEGIN RETURN t.path END Path;

PROCEDURE IsModified*(t: T): BOOLEAN;
BEGIN RETURN t.modified END IsModified;

PROCEDURE Length*(t: T): INTEGER;               (** number of lines *)
BEGIN RETURN t.ff END Length;

PROCEDURE NofChars*(t: T): INTEGER;             (** number of characters in text *)
VAR i,res : Int.T;
BEGIN
   res := 0;
   FOR i := 0 TO t.ff - 1 DO INC (res, LEN(t.lines[i]^)); END;
   RETURN ssqTypes.Short (res);
END NofChars;

PROCEDURE Size* (t: T): INTEGER;                (** maximal number of lines for this text *)
BEGIN RETURN t.size END Size;

PROCEDURE ModfChar* (t: T): CHAR;               (** return '*' if modified, '-' if not *)
VAR c: CHAR;
BEGIN
   IF t.modified THEN
      c := '*'
   ELSE c := '-'
   END;
   RETURN c
END ModfChar;

PROCEDURE Dump* (t: T);                         (** print text properties *)
VAR
   i: INTEGER;
BEGIN
   Dot.Lff; Dot.Mess("------- Text.Dump");
   FOR i := 0 TO t.ff - 1 DO Dot.Lf; Dot.Mess( t.lines[i]^ ) END;
   Dot.Lf; Dot.Mess("---------------------------");
   Dot.Lf; Dot.Mess("name      <"); Dot.Mess(t.name^); Dot.Mess("> ");
   Dot.Lf; Dot.Mess("path   <");    Dot.Mess (t.path^); Dot.Mess (">");
   Dot.Lf; Dot.Mess("modified: ");  Dot.Bool(t.modified, 8);
   Dot.Lf; Dot.Mess("length:   ");  Dot.Int(t.ff, 8);
   Dot.Lf; Dot.Mess("size:     ");  Dot.Int(t.size, 8);
   Dot.Lf; Dot.Mess("chars     ");  Dot.Int(NofChars(t), 8);
   Dot.Lff;
END Dump;


(* ========================================================================= *)
(* :section:    lib *)
PROCEDURE IsPosValid* (t:T; cy,cx: INTEGER): BOOLEAN;           (** is cy/cx an existing char pos in text *)
BEGIN RETURN (cy < t.ff) & (cx < Line.Length (t.lines[cy])) END IsPosValid;

PROCEDURE IsPosValid1* (t:T; cy,cx: INTEGER): BOOLEAN;          (** like IsPosValid, cx=LEN is valid, too *)
BEGIN RETURN (cy < t.ff) & (cx <= Line.Length (t.lines[cy])) END IsPosValid1;

PROCEDURE ChangeLine* (t: T; l: Line.T; pos: INTEGER);
BEGIN
   Sys.Assert (pos < Length (t), "Text.ChangeLine: pos >= Length (t)");
   t.lines[pos] := Line.Despace (l);
   t.modified := TRUE;
END ChangeLine;

PROCEDURE HasChar* (VAR c: CHAR;   t: T; cy,cx: INTEGER): BOOLEAN;   (** return c if pos is valid in t *)
VAR res: BOOLEAN;
BEGIN
   IF IsPosValid (t, cy,cx) THEN
      c := t.lines[cy][cx];
      res := TRUE
   ELSE res := FALSE
   END;
   RETURN res
END HasChar;

PROCEDURE HasLine* (VAR l: Line.T; t: T; ln: INTEGER): BOOLEAN;
VAR res: BOOLEAN;
BEGIN
  IF ln < Length (t) THEN
     l := t.lines[ln];
     res := TRUE
  ELSE res := FALSE
  END;
  RETURN res
END HasLine;

PROCEDURE GetLine* (t: T; n: Int.T): Line.T;    (** return pointer to line n *)
BEGIN
   Sys.Assert (n < t.ff, "Text.GetLine: n");
   RETURN t.lines[n]
END GetLine;

PROCEDURE ModifyLine* (t:T; cy,cx:INTEGER; f:ModProc);
VAR l: Line.T;
BEGIN IF HasLine (l, t, cy) THEN ChangeLine (t, f (l,cy,cx), cy); END END ModifyLine;


(* ========================================================================= *)
(* :chapter: CHAR *)
PROCEDURE CharChange* (t:T; cy,cx: INTEGER; c: CHAR);
VAR l: Line.T;
BEGIN
   IF IsPosValid (t, cy,cx) THEN
      l := GetLine (t, cy);
      l[cx] := c;
      ChangeLine (t, l, cy);
      mess := "";
   ELSE
      mess := "ChangeChar: invalid pos";
   END
END CharChange;
 
PROCEDURE CharDelete* (t:T; cy,cx: INTEGER);
VAR
   l,nl: Line.T;
   len,i: INTEGER;
BEGIN
   IF IsPosValid (t, cy,cx) THEN
      l := t.lines[cy];
      len := Line.Length (l);
      NEW (nl, len);
      FOR i := 0  TO cx  - 1 DO nl[i] := l[i]     END;
      FOR i := cx TO len - 1 DO nl[i] := l[i+1]   END;  (* includes 0X *)
      ChangeLine (t, nl, cy);
      t.modified  := TRUE;
      mess := "";
   ELSE
      mess := "DeleteChar: invalid pos"
   END;
END CharDelete;

PROCEDURE CharInsert* (t:T; cy,cx: INTEGER; c: CHAR);
VAR
   a: ARRAY 2 OF CHAR;
   l,nl,spaces: Line.T;
   i,len,gaplen: INTEGER;
   pos: Int.T;
BEGIN
   IF IsPosValid1 (t, cy, cx) THEN
      l := t.lines[cy];
      len := Line.Length (l);
      NEW (nl, len + 2);
      pos := 0;
      Str.PushSeq (nl^, pos, l^, 0, cx);
      Str.PushChr (nl^, pos, c);
      Str.PushSeq (nl^, pos, l^, cx, len);
      ChangeLine (t, nl, cy);
      mess := "CharInsert";
   ELSIF (cy < t.ff) & (Line.Length (t.lines[cy]) < cx) & (c # ' ') THEN
      l := t.lines[cy];
      len := Line.Length (l);
      gaplen := cx - len;
      spaces := Line.Spaces (gaplen);
      NEW (nl, len + gaplen + 2);
      pos := 0;
      Str.PushSeq (nl^, pos, l^, 0, len);
      Str.PushStr (nl^, pos, spaces^);
      Str.PushChr (nl^, pos, c);
      ChangeLine (t, nl, cy);
      mess := "CharInsert: append with gap";
   ELSE
      mess := "Text.CharInsert: position not valid"
   END
END CharInsert;

PROCEDURE InsertStr* (t:T; cy,cx: INTEGER; VAR a:ARRAY OF CHAR);
VAR
   l,nl: Line.T;
   i,j,alen,nlen,start,end: INTEGER;
BEGIN
   IF IsPosValid1 (t, cy,cx) THEN
      l := t.lines[cy];
      alen  := Str.Length (a);
      nlen  := Line.Length (l) + alen;
      start := cx;
      end   := start + alen;
      j     := 0;
      NEW (nl, nlen + 1);
      FOR i := 0   TO start - 1 DO nl[i]         := l[j]; INC (j) END;
      FOR i := 0   TO alen - 1  DO nl[start + i] := a[i]          END;
      FOR i := end TO nlen - 1  DO nl[i]         := l[j]; INC (j) END;
      nl[nlen] := 0X;
      ChangeLine (t, nl, cy);
      mess := "";
   END
END InsertStr;


(* ========================================================================= *)
(* :chapter: LINE *)
PROCEDURE AppendLine*(VAR t: T; l: Line.T);
BEGIN
   Sys.Assert(t.ff < t.size, "Text.AppendLine: text if full.");
   t.lines[t.ff] := l;
   INC(t.ff);
   t.modified := TRUE;
   mess := "";
END AppendLine;

PROCEDURE DeleteLine* (t: T; cy: INTEGER);
VAR i: INTEGER;
BEGIN
   Sys.Assert (cy < t.ff, "Text.DeleteLine: cy");
   FOR i := cy TO t.ff -1 DO t.lines[i] := t.lines[i+1] END;
   DEC (t.ff);
   t.modified := TRUE;
   mess := "";
END DeleteLine;

PROCEDURE InsertLine* (t: T; cy: INTEGER; l: Line.T);
VAR i: INTEGER;
BEGIN
   Sys.Assert (cy <= t.ff, "Text.InsertLine: cy");
   Sys.Assert (t.ff < t.size, "Text.InsertLine: t.ff full");
   FOR i := t.ff - 1 TO cy BY -1 DO
      t.lines[i+1] := t.lines[i]
   END;
   t.lines[cy] := Line.Despace (l);
   INC (t.ff);
   t.modified := TRUE;
   mess := "";
END InsertLine;

PROCEDURE SplitLine* (t:T; VAR cy,cx: INTEGER);
VAR
   l,l1,l2: Line.T;
   ind,i,j: INTEGER;
BEGIN
   IF HasLine (l, t, cy) THEN
      NEW (l1, cx + 1);
      NEW (l2, Line.Length (l) - cx + 1);
      Str.Head (l1^, l^, cx);
      Str.Tail (l2^, l^, cx);
      ind := Line.Indentation (l1);
      l2 := Line.Indent (l2, ind);
      ChangeLine (t, l1, cy);
      INC (cy);
      InsertLine (t, cy, l2);
      cx := ind;
      mess := "";
   ELSE
      mess := "Text.SplitLine: invalid pos";
   END;
END SplitLine;



(* ========================================================================= *)
(* :chapter: SECTION *)
PROCEDURE CopyLines* (VAR section:T; t:T; start, end: INTEGER; name: ARRAY OF CHAR); (** exlusive end *)
VAR
   i: INTEGER;
   nt: T;
BEGIN
   Sys.Assert ((0 <= start) & (start <= end), "Text.CopyLines: start");
   Sys.Assert (end <= t.ff, "Text.CopyLines: end");
   New (nt, end - start);
   nt.name := Line.Create (name);
   FOR i := 0 TO end - start - 1 DO
      nt.lines[i] := t.lines[i + start]
   END;
   nt.ff := end - start;
   nt.modified := FALSE;
   section := nt;
   mess := "";
END CopyLines;

PROCEDURE DeleteLines* (t: T; start,end: INTEGER);
VAR i,g: INTEGER;
BEGIN
   Sys.Assert ((0 <= start) & (start <= end) & (end <= t.ff), "Text.DeleteLine: start end");
   g := end - start;
   FOR i := start TO t.ff - 1 - g DO t.lines[i] := t.lines[i+g] END;
   DEC (t.ff, g);
   t.modified := TRUE;
   mess := "";
END DeleteLines;

PROCEDURE InsertLines* (t: T; cy: INTEGER; section: T): BOOLEAN;
VAR
   l: Line.T;
   i,slen: INTEGER;
   res: BOOLEAN;
BEGIN
   slen := section.ff;
   Sys.Assert ((0 <= cy) & (cy <= t.ff), "Text.InsertLine: cy");
   Sys.Assert (t.ff + slen < t.size, "Text.InsertLine: slen >= t.size");
   IF section # NIL THEN
      FOR i := t.ff + slen - 1 TO cy BY -1 DO
         t.lines[i] := t.lines[i - slen]
      END;
      FOR i := 0 TO slen - 1 DO
         l := Line.Despace (section.lines[i]);
         t.lines[cy + i] := l;
      END;
      INC (t.ff, slen);
      res := TRUE;
   ELSE res := FALSE
   END;
   t.modified := TRUE;
   mess := "";
   RETURN res
END InsertLines;


(* ========================================================================= *)
(* :chapter: FIND *)
(* :section:    find *)
PROCEDURE FindSeq* (t: T; VAR seq: ARRAY OF CHAR; VAR ypos, xpos: INTEGER): BOOLEAN;
(** Starting at line ypos, char xpos search for seq
  * RETURN TRUE and set ypos and xpos if found
  * RETURN false and leave ypos and xpos unchanged if not found
  *)
VAR
   y,x,tlen,llen: INTEGER;
   res: BOOLEAN;
BEGIN
   tlen := Length (t);
   y    := ypos;
   x    := xpos;
   res  := FALSE;
   WHILE ~res & (y < tlen) DO
      IF Line.FindSeq (GetLine (t, y), seq, x) THEN
         ypos := y;
         xpos := x;
         res := TRUE
      ELSE
         x := 0;
         INC (y)
      END;
   END;
      mess := "";
   RETURN res;
END FindSeq;

PROCEDURE FindSeqBackwards* (t: T; VAR seq: ARRAY OF CHAR; VAR ypos, xpos: INTEGER): BOOLEAN;
(** Starting at line ypos, char xpos search for seq
  * RETURN TRUE and set ypos and xpos if found
  * RETURN false and leave ypos and xpos unchanged if not found
  *)
VAR
   y,x,tlen,llen: INTEGER;
   res: BOOLEAN;
BEGIN
   y    := ypos;
   x    := xpos;
   res  := FALSE;
   WHILE ~res & (y >= 0) DO
      IF Line.FindSeq (GetLine (t, y), seq, x) THEN
         ypos := y;
         xpos := x;
         res := TRUE
      ELSE
         x := 0;
         DEC (y)
      END;
   END;
      mess := "";
   RETURN res;
END FindSeqBackwards;

PROCEDURE FindPosition* (VAR cy,cx: INTEGER; t:T; cpos: INTEGER): BOOLEAN;
VAR
   i,len: INTEGER;
   res,cont: BOOLEAN;
BEGIN
   Sys.Assert (cpos > 0, "Text.FindPosition: cpos < 0");
   i    := 0;
   cont := TRUE;
   WHILE cont DO
      IF i >= t.ff THEN
         res  := FALSE;
         cont := FALSE
      ELSE
         len := Line.Length (t.lines[i]);
         IF cpos <= len THEN
            cy   := i;
            cx   := cpos + 1;
            res  := TRUE;
            cont := FALSE
         ELSE
            DEC (cpos, 1 + len);
            INC (i)
         END
      END
   END;
   RETURN res;
END FindPosition;


(* ========================================================================= *)
(* :section:    thing-at-point *)
PROCEDURE FindWhitespaceEnd (VAR cx: INTEGER; l: Line.T): BOOLEAN;
(** cx pointing at whitespace
  * return cx pointing to last whitespace of current gap
  * return TRUE if first character after gap is non-whitespace
  * return FALSE if gap ends at line end
  *)
VAR
   len: INTEGER;
   res: BOOLEAN;
BEGIN
   len := Line.Length (l);
   Sys.Assert (len >= 1, "Text.FindWhitespaceEnd: length");
   Sys.Assert (cx < len, "Text.FindWhitespaceEnd: cx");
   Sys.Assert (Char.IsWhitespace (l[cx]), "Text.FindWhitespaceEnd: WS");
   WHILE (cx + 1 < len) & Char.IsWhitespace (l[cx + 1]) DO INC (cx) END;
   IF cx = len - 1 THEN
      res := FALSE
   ELSE res := TRUE
   END;
   RETURN res;
END FindWhitespaceEnd;

PROCEDURE IsWordEnd1 (cx: INTEGER; l: Line.T): BOOLEAN;
VAR len: INTEGER;
BEGIN
   len := Line.Length (l);
   RETURN
           (cx + 1 = len) & ~Char.IsWhitespace (l[cx])
        OR (cx + 1 < len) & Char.IsAlphaNumUs  (l[cx]) & ~Char.IsAlphaNumUs (l[cx + 1])
        OR (cx + 1 < len) & ~Char.IsWhitespace (l[cx]) & Char.IsWhitespace (l[cx + 1])
END IsWordEnd1;

PROCEDURE FindWSStart (VAR cx: INTEGER; l: Line.T);                             (* find whitespace start*)
VAR i: INTEGER;
BEGIN
   i := cx;
   WHILE (i > 0) & Char.IsWhitespace (l[i]) DO DEC (i) END;
   cx := i;
END FindWSStart;

PROCEDURE FindWSEnd (VAR cx: INTEGER; l: Line.T);                               (* find whitespace end *)
VAR i,len: INTEGER;
BEGIN
   i := cx;
   len := Line.Length (l);
   WHILE (i < len) & Char.IsWhitespace (l[i]) DO INC (i) END;
   cx := i;
END FindWSEnd;

PROCEDURE FindWStart (VAR cx: INTEGER; l: Line.T);
VAR i: INTEGER;
    res: BOOLEAN;
BEGIN
   cx := Int.ShortMin (cx, Line.Length (l));
   i := cx;
   IF (i > 0) & Char.IsWhitespace (l[i-1]) & ~Char.IsWhitespace (l[i]) THEN
      DEC (i);
      FindWSStart (i, l);
   ELSIF (i > 0) &  Char.IsAlphaNumUs (l[i-1]) & ~Char.IsAlphaNumUs (l[i]) THEN
      DEC (i);
   ELSIF (i > 0) & ~Char.IsAlphaNumUs (l[i-1]) &  Char.IsAlphaNumUs (l[i]) THEN
      DEC (i);
   END;
   IF Char.IsAlphaNumUs (l[i]) THEN
      WHILE (i > 0) & Char.IsAlphaNumUs (l[i-1]) DO DEC (i) END;
   ELSE
      WHILE (i > 0) & ~Char.IsAlphaNumUs (l[i]) & ~Char.IsWhitespace (l[i])
      DO DEC (i) END;
   END;
   cx := i;
END FindWStart;

PROCEDURE FindWEnd (VAR cx: INTEGER; l: Line.T);
VAR i,len: INTEGER;
    res: BOOLEAN;
BEGIN
   len := Line.Length (l);
   i   := Int.ShortMin (cx, len - 1);
   i   := Int.ShortMax (0, i);
   IF Char.IsAlphaNumUs (l[i]) THEN
      WHILE (i < len) & Char.IsAlphaNumUs (l[i]) DO INC (i) END;
   ELSE
      WHILE (i < len) & ~Char.IsAlphaNumUs (l[i]) & ~Char.IsWhitespace (l[i])
      DO INC (i) END;
   END;
   cx := i;
END FindWEnd;

PROCEDURE FindWord* (VAR cy,cx: INTEGER; t:T): BOOLEAN;                         (** == w *)
VAR
   l: Line.T;
   res: BOOLEAN;
BEGIN
   IF HasLine (l, t, cy) & (cx < Line.Length (l)) THEN
      IF Char.IsWhitespace (l[cx]) THEN
         FindWSEnd (cx, l)
      ELSE
         FindWEnd (cx, l);
         FindWSEnd (cx, l);
      END;
      res := TRUE;
   ELSE res := FALSE
   END;
   RETURN res
END FindWord;

PROCEDURE FindWordStart* (VAR cy,cx: INTEGER; t:T): BOOLEAN;                    (** == b *)
VAR
   i,j,start,end,len: INTEGER;
   l: Line.T;
   res: BOOLEAN;
BEGIN
   IF HasLine (l, t, cy) THEN
      cx := Int.ShortMin (cx, Line.Length (l) - 1);
      IF Char.IsWhitespace   (l[cx]) THEN
         FindWSStart (cx, l);
      END;
      FindWStart  (cx, l);
      res := TRUE
   ELSE res := FALSE
   END;
   RETURN res
END FindWordStart;

PROCEDURE FindWordEnd* (VAR cy,cx: INTEGER; t:T): BOOLEAN;                      (** == e *)
VAR
   len: INTEGER;
   l:   Line.T;
   res: BOOLEAN;
BEGIN
   res := FALSE;
   IF HasLine (l, t, cy) THEN
      len := Line.Length (l);
      IF len > 0 THEN
         cx := Int.ShortMin (cx, len - 1);
         IF Char.IsWhitespace (l[cx]) THEN
            IF FindWhitespaceEnd (cx, l) THEN
               INC (cx);
               WHILE (cx < len) & ~IsWordEnd1 (cx,l) DO INC (cx) END;
               res := TRUE;
            ELSE (* whitespace at end-of-line *)
            END;
         ELSIF IsWordEnd1 (cx, l) THEN
            IF cx < len - 1 THEN
               INC (cx);
               res := FindWordEnd (cy, cx, t)
            END;
         ELSE FindWEnd (cx, l)
         END;
      END;
   END;
   RETURN res
END FindWordEnd;

PROCEDURE TapThisWord* (VAR start,end: INTEGER; cy,cx: INTEGER; t:T): BOOLEAN;
VAR
   i,j,len: INTEGER;
   l: Line.T;
   res,found: BOOLEAN;
BEGIN
   IF ~HasLine (l, t, cy) THEN
      res := FALSE
   ELSE
      len := Line.Length (l);
      IF (cx >= len) THEN
         res := FALSE
      ELSE
         IF ~Char.IsAlphaNumUs (l[cx]) THEN
            res := FALSE
         ELSE
            (* find-start *)
            i := cx;
            found := FALSE;
            WHILE (i >= 0) & ~found DO
               IF i = 0 THEN
                  found := TRUE
               ELSIF Char.IsAlphaNumUs (l[i-1]) THEN
                  DEC (i)
               ELSE found := TRUE
               END
            END;
            start := i;
            (* find-end *)
            i := cx;
            found := FALSE;
            WHILE (i < len) & ~found DO
               IF    i = len - 1                 THEN found := TRUE
               ELSIF ~Char.IsAlphaNumUs (l[i+1]) THEN found := TRUE
               ELSE INC (i)
               END;
            END;
            end := i;
            res := TRUE;
         END
      END
   END;
   RETURN res
END TapThisWord;


(* ------------------------------------------------------------------------- *)
(* :section:    find word boundaries *)
PROCEDURE FindGapStart* (VAR cx: INTEGER; l: Line.T): BOOLEAN;
(** cx pointing at whitespace
  * return cx pointing to first whitespace of current gap
  * return TRUE if it is t true gap: first character before gap is non-whitespace
  * return FALSE if gap starts at column 0, that is there is no word before the gap *)
VAR res: BOOLEAN;
BEGIN
   Sys.Assert (Line.Length (l) >= 1,      "Text.FindWhitespaceStart: length");
   Sys.Assert (cx < Line.Length (l),      "Text.FindWhitespaceStart: cx");
   Sys.Assert (Char.IsWhitespace (l[cx]), "Text.FindWhitespace:      WS");
   WHILE (cx > 0) & Char.IsWhitespace (l[cx - 1]) DO DEC (cx) END;
   IF cx = 0 THEN
      res := FALSE
   ELSE res := TRUE
   END;
RETURN res END FindGapStart;

PROCEDURE FindGapEnd* (VAR cx: INTEGER; l: Line.T): BOOLEAN;
(** cx pointing at whitespace
  * return cx pointing to last whitespace of current gap
  * return TRUE if it is a true gap: first character after gap is non-whitespace
  * return FALSE if gap ends at line end, there is no word behind the gap *)
VAR len: INTEGER; res: BOOLEAN;
BEGIN
   len := Line.Length (l);
   Sys.Assert (len >= 1, "Text.FindWhitespaceEnd: length");
   Sys.Assert (cx < len, "Text.FindWhitespaceEnd: cx");
   Sys.Assert (Char.IsWhitespace (l[cx]), "Text.FindWhitespaceEnd: WS");
   WHILE (cx + 1 < len) & Char.IsWhitespace (l[cx + 1]) DO INC (cx) END;
   IF cx = len - 1 THEN
      res := FALSE
   ELSE res := TRUE
   END;
RETURN res END FindGapEnd;

PROCEDURE IsWordStart* (cx: INTEGER; l:Line.T): BOOLEAN;
VAR len: INTEGER;
BEGIN
   len := Line.Length (l);
   Sys.Assert (len > 0,  "Text.IsWordStart: length");
   Sys.Assert (cx < len, "Text.IsWordStart: cx");
RETURN (cx = 0) & ~Char.IsWhitespace (l[cx])
        OR (cx > 0) & ~Char.IsAlphaNumUs (l[cx - 1]) &  Char.IsAlphaNumUs (l[cx])
        OR (cx > 0) & (Char.IsWhitespace (l[cx - 1]) OR Char.IsAlphaNumUs (l[cx-1]))
                & (~Char.IsAlphaNumUs (l[cx]) & ~Char.IsWhitespace (l[cx])) END IsWordStart;

PROCEDURE IsWordEnd* (cx: INTEGER; l: Line.T): BOOLEAN;
VAR len: INTEGER;
BEGIN
   len := Line.Length (l);
   Sys.Assert (len > 0,  "Text.IsWordEnd: length");
   Sys.Assert (cx < len, "Text.IsWordEnd: cx");
RETURN (cx + 1 = len) & ~Char.IsWhitespace (l[cx])
        OR (cx + 1 < len) & Char.IsAlphaNumUs  (l[cx]) & ~Char.IsAlphaNumUs (l[cx + 1])
        OR (cx + 1 < len) & (~Char.IsAlphaNumUs (l[cx]) & ~Char.IsWhitespace (l[cx]))
                & (Char.IsWhitespace  (l[cx+1]) OR Char.IsAlphaNumUs (l[cx+1])) END IsWordEnd;


(* ========================================================================= *)
(* :chapter: OTHERS *)
PROCEDURE Format* (VAR outText:T; inText:T): BOOLEAN;                            (** format text paragraph *)
VAR
   l: Line.T;
   res: BOOLEAN;
BEGIN
   res := TRUE;
   outText := inText;
   RETURN res;
END Format;

PROCEDURE Contents* (VAR outText:T; inText:T) :BOOLEAN;                         (** return contents of text *)
CONST Size = 1024;
VAR
   name,path,file,chapter,section: ARRAY 32 OF CHAR;
   a:   ARRAY 256 OF CHAR;
   l,lastline:    Line.T;
   i,lastpoint: INTEGER;
   pos: Int.T;
BEGIN
   Sys.Assert (inText # NIL, "Text.Contents: inText is NIL");
   name    := "Contents";
   path    := "";
   chapter := " chapter:"; chapter[0] := ':';
   section := " section:"; section[0] := ':';
   file    := " file:";    file[0]    := ':';
   New (outText, Size);
   SetName (outText, name);
   SetPath (outText, path);
   lastpoint := -1;
   FOR i := 0 TO Length (inText) - 1 DO
      l := GetLine (inText, i);
      IF Str.HasSeq (l^, chapter) OR Str.HasSeq (l^, section) OR Str.HasSeq (l^, file) THEN
         IF lastpoint # -1 THEN
            pos := 0;
            Str.PushInt (a, pos, lastpoint,     8);
            Str.PushInt (a, pos, i - lastpoint, 8);
            Str.PushTab (a, pos, 18);
            Str.PushStr (a, pos, lastline^);
            AppendLine (outText, Line.Create (a));
         END;
         lastpoint := i;
         lastline  := l;
      END;
   END;
   IF lastpoint # -1 THEN
      pos := 0;
      Str.PushInt (a, pos, lastpoint,     8);
      Str.PushInt (a, pos, i - lastpoint, 8);
      Str.PushTab (a, pos, 18);
      Str.PushStr (a, pos, lastline^);
      AppendLine (outText, Line.Create (a));
   END;
   RETURN TRUE;
END Contents;

PROCEDURE Sort* (VAR t: T);
VAR l: Line.T;
   i,tlen: INTEGER;
   sorted: BOOLEAN;
BEGIN
   tlen   := Length (t);
   sorted := FALSE;
   WHILE ~sorted DO
      sorted := TRUE;
      FOR i := 0 TO tlen - 2 DO
         IF t.lines[i]^ > t.lines[i+1]^ THEN
            l := t.lines[i];
            t.lines[i] := t.lines[i+1];
            t.lines[i+1] := l;
            sorted := FALSE;
         END
      END
   END
END Sort;

(* ========================================================================= *)
(* :chapter: LOAD/SAVE *)
PROCEDURE Load*(VAR t: T; name, path: ARRAY OF CHAR): BOOLEAN;          (** creates NEW t *)
VAR
   buffer : ARRAY LoadBufferSize OF CHAR;
   a      : ARRAY 1024 OF CHAR;
   len,lines,i,start: INTEGER;
   line   : Line.T;
   res: BOOLEAN;
BEGIN
   New (t, SizeStd);
   t.name     := Line.New (name);
   t.path     := Line.Create (path);
   t.modified := FALSE;
   IF ~Sys.FileRead(buffer, len, path) THEN
      RETURN Sys.ERR("Text.Load: loading failed.")
   END;
   lines := 0;
   start := 0;
   i     := 0;
   WHILE i < len DO
      IF (buffer[i] = 0AX) OR (i = len - 1) THEN
         IF (i = len - 1) & (buffer[i] # 0AX) THEN      (* in order to get last char in case it is no 0A *)
            INC (i)
         END;
         Str.Sub (a, buffer, start, i);
         line := Line.New (a);
         AppendLine(t, line);
         start := i + 1;
         INC(lines)
      END;
      INC(i)
   END;
   t.modified := FALSE;
      mess := "";
   RETURN TRUE;
END Load;

PROCEDURE Save*(VAR t: T): BOOLEAN;
CONST CR = 0AX;
VAR
   txt: ARRAY 128 * 1024 OF CHAR;
   i,l,j:INTEGER;
   res: BOOLEAN;
BEGIN
   IF ~t.modified THEN RETURN TRUE END;
   IF t.path^ = "" THEN RETURN Sys.ERR("Text.Save: path is empty.") END;
   i := 0;
   FOR l := 0 TO Length (t) - 1 DO
      FOR j := 0 TO Line.Length (t.lines[l]) - 1 DO
         txt[i] := t.lines[l][j];
         INC (i);
      END;
      txt[i] := CR;
      INC (i);
   END;
   txt[i] := 0X;
   IF Sys.FileWrite (t.path^, txt, i) THEN
      t.modified := FALSE;
      res := TRUE
   ELSE res := FALSE
   END;
      mess := "";
   RETURN res
END Save;


(* ========================================================================= *)
END Text.   :file: (c) sts-q 2023-Jan  2024-Feb,Jun
