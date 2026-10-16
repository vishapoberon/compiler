MODULE Json;   (* :file: Json.Mod  --  A simple Json parser. *)
IMPORT Out;

(** Json.Mod  --  A simple Json parser and printer.
  *
  * https://www.json.org/json-en.html
  * https://ecma-international.org/wp-content/uploads/ECMA-404_2nd_edition_december_2017.pdf
  *
  * No strings escape characters like \n, currently.
  * Return NIL and provide an error message in case of malformed json.
  * Provide warning about deviations from json syntax.
  * Formating real values is APPROXIMATIVE.    <.> In other words: not working </.>
  * Malformed real values are not detected.
  *
  * See README and examples.
  *
  *)


(* ------------------------------------------------------------------------- *)
(* :chapter: CONFIG *)
CONST
   IndentSize*  =   4;                          (* 'tabsize' for indentation of output *)
   SigFigs*     =   6;                          (* 3 <= SigFigs <= 10 formating reals: PROCEDURE PushReal *)
   jComment     = "/*";                         (* long comment:   /* ... */  no nested comments *)
   jLineComment = "--";                         (* lines comments  -- ... *)
   jCheckStrikt = TRUE;                        (* warn about missing or trailing comma in arrays *)


TYPE
   jInt*        = HUGEINT;                      (* Json integer values: anything from HUGEINT to SHORTINT *)
   jReal*       = LONGREAL;                     (* Json real or floating point number values *)
   jString*     = POINTER TO ARRAY OF CHAR;     (* Json string values: both, element-name and string-value *)


   (**
     * PROCEDURE IsValid (c: CHAR): BOOLEAN;            defines which characters are valid at all.
     * PROCEDURE IsValidSymbolChar (c: CHAR): BOOLEAN;  defines which are valid for symbols.
     *)


(* ------------------------------------------------------------------------- *)
(* :chapter: DECLARATIONS *)


   Value*  = POINTER TO ValueDesc;
   Bool*   = POINTER TO BoolDesc;
   Int*    = POINTER TO IntDesc;
   Null*   = POINTER TO NullDesc;
   Real*   = POINTER TO RealDesc;
   Str*    = POINTER TO StrDesc;
   Sym*    = POINTER TO SymDesc;
   Arr*    = POINTER TO ArrDesc;
   Obj*    = POINTER TO ObjDesc;

   ValueDesc  = RECORD END;
   BoolDesc   = RECORD( ValueDesc )  b*   : BOOLEAN  END;
   IntDesc    = RECORD( ValueDesc )  i*   : jInt     END;
   NullDesc   = RECORD( ValueDesc )                  END;
   RealDesc   = RECORD( ValueDesc )  r*   : jReal    END;
   StrDesc    = RECORD( ValueDesc )  str* : jString  END;
   SymDesc    = RECORD( ValueDesc )  s*   : jString  END;

   ArrDesc    = RECORD( ValueDesc )
                   value* : Value;
                   next*  : Arr;
                END;

   ObjDesc    = RECORD( ValueDesc )
                   name*  : jString;
                   value* : Value;
                   next*  : Obj;
               END;

   NameList*    = POINTER TO NameListDesc;
   NameListDesc = RECORD
                     name* : jString;
                     next* : NameList;
                  END;

VAR
   src     : POINTER TO ARRAY OF CHAR;          (* copy of json source *)
   cc      : CHAR;                              (* CurrentChar: cc := source[srcPos] *)
   srcPos  : INTEGER;
   srcLine : INTEGER;                           (* current line in source *)
   srcCol  : INTEGER;                           (* current column in current line *)
   nestingObj : INTEGER;
   nestingArr : INTEGER;
   noError : BOOLEAN;                           (* noError = TRUE --> keep going *)
   errmess : ARRAY 1024 OF CHAR;
   errmessFF : INTEGER;                         (* First Free position in errmess *)
   currentIndentation : INTEGER;                (* to format output *)
   lgc1, lgc2, lic1, lic2 : CHAR;               (* LonG-comment-Char, LIne-comment-Char *)


(* ------------------------------------------------------------------------- *)
(* :chapter: DEBUG *)
PROCEDURE lf;
BEGIN Out.Ln END lf;

PROCEDURE DdxOn;
(** Change forground color *)
BEGIN Out.Char (1BX); Out.String ("[38;2;255;60;170m"); Out.Flush END DdxOn;

PROCEDURE DdxOff;
(** Change forground color  back to white *)
BEGIN Out.Char (1BX); Out.String ("[38;2;255;255;255m"); Out.Flush END DdxOff;

PROCEDURE ddx (str: ARRAY OF CHAR);
BEGIN DdxOn; Out.String (str); Out.String (" "); DdxOff; Out.Flush END ddx;

PROCEDURE DDX (str: ARRAY OF CHAR);
BEGIN lf; ddx (str ) END DDX;

PROCEDURE iprint (i: HUGEINT);
BEGIN DdxOn; Out.Int (i, 6); Out.String (" "); DdxOff; Out.Flush; END iprint;



(* ------------------------------------------------------------------------- *)
(* :chapter: LIB *)
(* :section:    json *)
PROCEDURE ArrCons* (VAR arr: Arr; value: Value);
(** Prepend value to arr: [value, ...] *)
VAR na : Arr;
BEGIN
   NEW (na);
   na.value := value;
   na.next  := arr;
   arr := na;
END ArrCons;

PROCEDURE ArrJoin* (VAR arr: Arr; value: Value);
(** Append value to arr: [..., value] *)
VAR a,na : Arr;
BEGIN
   NEW (na);
   na.value := value;
   na.next  := NIL;
   a := arr;
   WHILE (a # NIL) & (a.next # NIL) DO a := a.next END;
   IF a # NIL THEN
      a.next := na;
   ELSE
      arr := na
   END;

END ArrJoin;

PROCEDURE ArrReverse* (l: Arr): Arr;
(** Reverse array *)
  VAR np,nl : Arr;
BEGIN
  nl := NIL;
  WHILE l # NIL DO
    NEW( np );
    np.value := l.value;
    np.next  := nl;
    nl := np;
    l  := l.next;
  END;
  RETURN nl
END ArrReverse;

PROCEDURE ObjHasName* (obj: Obj; name: jString): BOOLEAN;
(** return TRUE if has an element named <name> *)
VAR res : BOOLEAN;
BEGIN
   res := FALSE;
   WHILE ~res & (obj # NIL) DO 
      IF obj.name^ = name^ THEN res := TRUE END;
      obj := obj.next
   END;
   RETURN res 
END ObjHasName;

PROCEDURE ObjAdd* (VAR obj: Obj; name: jString; value: Value);
(** Add element to object: { name: value, ... } *)
VAR
   n : Obj;
BEGIN
   NEW (n);
   n.name  := name;
   n.value := value;
   n.next  := obj;
   obj := n;
END ObjAdd;

PROCEDURE ObjNames* (o: Obj): NameList;                                         (* _xmark_ *)
(** Return list of names of objects elements. *)
VAR res,last,n,n2 : NameList;
BEGIN
   NEW (res);
   IF o # NIL THEN
      NEW (n); res := n;
      REPEAT
         NEW (n2);
         n.name := o.name;
         n.next := n2;
         o := o.next;
         last := n;
         n := n2;
      UNTIL o = NIL;
      last.next := NIL;
   ELSE
      res := NIL
   END;
   RETURN res;
END ObjNames;

PROCEDURE ObjReverse (l: Obj): Obj;
(** Objects don't have an order,
  * they may be represented for instance as hash-tabels.
  * So, we don't export this function. *)
  VAR np,nl : Obj;
BEGIN
  nl := NIL;
  WHILE l # NIL DO
    NEW( np );
    np.name  := l.name;
    np.value := l.value;
    np.next  := nl;
    nl := np;
    l  := l.next;
  END;
  RETURN nl
END ObjReverse;

PROCEDURE ObjSelect* (VAR value: Value; VAR o: Obj; name: jString): BOOLEAN;
(** Return first element-value where element-name = name *)
VAR res : BOOLEAN;
BEGIN
   WHILE (o # NIL) & (o.name^ # name^) DO o := o.next; END;
   IF o # NIL THEN
      value := o.value;
      res   := TRUE
   ELSE
      value := NIL;
      res   := FALSE;
   END;
   RETURN res;
END ObjSelect;

(* ------------------------------------------------------------------------- *)
(* :section:    source *)
PROCEDURE NextCC;
BEGIN
   IF cc # 0X THEN
      IF cc = 0AX THEN
         INC (srcLine);
         srcCol := 1;
      ELSE
         INC (srcCol);
      END;
      INC (srcPos);
      cc := src[srcPos];
   END;
END NextCC;

PROCEDURE IsValid (c: CHAR): BOOLEAN;
(** valid character for: 
  * true, false, null, integer, real, symbol 
  *)
BEGIN
   RETURN    ('a' <= c) & (c <= 'z')          (* uupsieh: cc --> c *)
          OR ('A' <= c) & (c <= 'Z')
          OR ('0' <= c) & (c <= '9')
          OR (c = '+') OR (c = '-')
          OR (c = '_') OR (c = '.')           (* 1_000_000 *)
END IsValid;

PROCEDURE IsValidSymbolChar (c: CHAR): BOOLEAN;
(** valid character for: symbol *)
BEGIN
   RETURN    ('a' <= c) & (c <= 'z')
          OR ('A' <= c) & (c <= 'Z')
          OR ('0' <= c) & (c <= '9')
          OR (c = '_') 
          OR (c = '-') OR (c = '+')
END IsValidSymbolChar;

PROCEDURE IsSymbol (VAR s: ARRAY OF CHAR): BOOLEAN;
VAR
   i : LONGINT;
   c : CHAR;
BEGIN
   i := 0;
   REPEAT c := s[i]; INC (i);
   UNTIL (c = 0X) OR ~IsValidSymbolChar (c);
   RETURN c = 0X
END IsSymbol;

PROCEDURE IsInt (VAR s: ARRAY OF CHAR): BOOLEAN;
VAR
   i   : INTEGER;
   c   : CHAR;
BEGIN
   IF (s[0] = '+') OR (s[0] = '-')
   THEN
      IF s[1] = 0X THEN RETURN FALSE END;       (* found "+" or "-" *)
      i := 1
   ELSE i := 0;
   END;
   REPEAT c := s[i]; INC (i);
   UNTIL (c = 0X) OR ((c < '0') OR ('9' < c)) & (c # '_');
   RETURN c = 0X;
END IsInt;

PROCEDURE IsReal (s: ARRAY OF CHAR): BOOLEAN;
VAR
   i : INTEGER;
   c : CHAR;
BEGIN
   i := 0;
   REPEAT c := s[i]; INC (i);
   UNTIL     (c = 0X)
         OR (((c < '0') OR ('9' < c))
         &  ((c # '+') & (c # '-') & (c # 'E') & (c # '.')));
   RETURN c = 0X;
END IsReal;

PROCEDURE ReadSign (VAR b: BOOLEAN; VAR p: INTEGER; c: CHAR);
BEGIN
   IF    c = '-' THEN b := TRUE;  INC (p)
   ELSIF c = '+' THEN b := FALSE; INC (p)
   ELSE b := FALSE
   END;
END ReadSign;

(* ------------------------------------------------------------------------- *)
(* :section:    show *)
PROCEDURE ShowInt(VAR s: ARRAY OF CHAR; n: HUGEINT);
(** Write ascii representation of n to s. *)
CONST
  sa = 32;
VAR
  i, j, d: HUGEINT;
  neg: BOOLEAN;
  r: ARRAY sa OF CHAR;
BEGIN
  (* store string at tail of s *)
  i := sa;   (* i points full *)
  DEC(i);
  s[i] := 0X;

  IF n = 0 THEN
    (* s := "0" *)
    COPY("0", s);
  ELSIF n = -2147483647 THEN
    COPY("-2147483647", s)
  ELSIF n = 2147483648 THEN
    COPY("2147483648", s)
  ELSE

    IF n < 0 THEN
      neg := TRUE;
      n := -n
    ELSE
      neg := FALSE
    END;

    WHILE n > 0 DO
      d := n MOD 10;
      n := n DIV 10;
      DEC( i );
      r[i] := CHR(d + 48);
    END;

    IF neg THEN
      DEC(i);
      r[i] := "-"
    END;

    j := 0;
    WHILE j < sa - i DO
      s[j] := r[i+j];
      INC(j)
    END;
    s[j-1] := 0X;

  END;
END ShowInt;


(* ------------------------------------------------------------------------- *)
(* :section:    push to buffer *)
PROCEDURE Indent (delta: INTEGER);
BEGIN
   INC (currentIndentation, delta * IndentSize);
END Indent;

PROCEDURE PushChr (VAR buffer: ARRAY OF CHAR; VAR pos: INTEGER; c: CHAR);
BEGIN
   IF pos + 1 < LEN (buffer) THEN
      buffer[pos] := c;
      INC (pos);
   ELSE
      buffer[pos] := 0X
   END;
END PushChr;

PROCEDURE PushNewline (VAR buffer: ARRAY OF CHAR; VAR pos: INTEGER);
VAR i : INTEGER;
BEGIN
   PushChr (buffer, pos, 0AX);
   FOR i := 1 TO currentIndentation DO PushChr (buffer, pos, ' ') END;
END PushNewline;

PROCEDURE PushText (VAR buffer: ARRAY OF CHAR; VAR pos: INTEGER; str: ARRAY OF CHAR);
VAR i : INTEGER;
BEGIN
   i := 0;
   WHILE str[i] # 0X DO
      PushChr (buffer, pos, str[i]);
      INC (i)
   END;
END PushText;

PROCEDURE PushStr (VAR buffer: ARRAY OF CHAR; VAR pos: INTEGER; str: ARRAY OF CHAR);
VAR i : INTEGER;
BEGIN
   PushChr  (buffer, pos, CHR(34));
   PushText (buffer, pos, str);
   PushChr  (buffer, pos, CHR(34));
END PushStr;

PROCEDURE PushInt (VAR buffer: ARRAY OF CHAR; VAR pos: INTEGER; n: HUGEINT);
VAR s: ARRAY 32 OF CHAR;
BEGIN
   ShowInt  (s, n);
   PushText (buffer, pos, s);
END PushInt;

PROCEDURE PushReal (VAR buffer: ARRAY OF CHAR; VAR pos: INTEGER; r: jReal);
VAR
   significand : HUGEINT;
   s     : ARRAY 64 OF CHAR;
   exp   : LONGREAL;
   neg   : BOOLEAN;
   p10,i : INTEGER;

        PROCEDURE Push (c: CHAR);
        BEGIN PushChr (buffer, pos, c) END Push;

        PROCEDURE Rnd (r: LONGREAL): HUGEINT;
        VAR res : HUGEINT;
        BEGIN
           IF r < 0.0 THEN
                res := -ENTIER (-r + 0.5)
           ELSE res :=  ENTIER ( r + 0.5 )
           END;
           RETURN res
        END Rnd;

        PROCEDURE P10 (n: INTEGER): LONGREAL;
        (** return 10^n *)
        VAR
           i   : INTEGER;
           res : LONGREAL;
        BEGIN
           res := 1;
           FOR i := 1 TO ABS (n) DO res := res * 10 END;
           IF n < 0 THEN res := 1 / res END;
           RETURN res;
        END P10;

BEGIN (* PushReal *)
   IF r < 0 THEN
      r := -r;
      neg := TRUE
   ELSE neg := FALSE
   END;
   IF r = 0 THEN
      significand := 0;
      p10         := 0;
   ELSIF r > 10 THEN
      exp := 10.0;
      p10 := 1;
      WHILE r > exp DO INC (p10); exp := P10 (p10); ASSERT( p10 < 256, 251) END;
      significand := Rnd (r * P10 (SigFigs - p10));
   ELSIF r < 1 THEN
      exp := 1.0;
      p10 := 1;
      WHILE (r < exp) & (exp # 0.0) DO exp := P10 (-p10); INC (p10) END;
      significand := Rnd (r * P10 (SigFigs + p10 - 2));
      p10 := -p10;
   ELSE
      significand := Rnd (r * P10 (SigFigs - 1));
      p10 := 0;
   END;
   IF neg THEN Push ('-') ELSE Push (' ') END;
   ShowInt (s, significand);
   Push (s[0]);
   Push ('.');
   i := 1; WHILE s[i] # 0X DO Push (s[i]); INC (i) END;
   WHILE i < SigFigs DO Push ('0'); INC (i) END;
   Push ('E');
   IF p10 >= 0 THEN Push ('+') ELSE Push ('-'); p10 := -p10 END;
   IF p10 > 0  THEN DEC (p10) END;
   IF ABS(p10) < 10 THEN Push ('0') END;
   PushInt (buffer, pos, p10);
END PushReal;


(* ------------------------------------------------------------------------- *)
(* :chapter: ERRORS *)
PROCEDURE DoWarn (typ, mess: ARRAY OF CHAR);
VAR start,i : INTEGER;
BEGIN
   IF errmessFF > 0 THEN DEC (errmessFF) END;
   start := errmessFF;
   PushInt (errmess, errmessFF, srcPos);  PushText (errmess, errmessFF, ":");
   PushInt (errmess, errmessFF, srcLine); PushText (errmess, errmessFF, ":");
   PushInt (errmess, errmessFF, srcCol);
   FOR i := 0 TO 24 - (errmessFF - start) DO PushChr (errmess, errmessFF, ' ') END;
   PushText(errmess, errmessFF, typ);
   PushChr (errmess, errmessFF, '|');
   PushText(errmess, errmessFF, mess);
   PushChr (errmess, errmessFF, 0AX);
   PushChr (errmess, errmessFF, 0X);
END DoWarn;

PROCEDURE Warn (mess: ARRAY OF CHAR);
BEGIN
   DoWarn ("Warning ", mess);
END Warn;

PROCEDURE Error (mess: ARRAY OF CHAR);
BEGIN
   DoWarn ("  ERROR ", mess);
   noError := FALSE;
END Error;


(* ------------------------------------------------------------------------- *)
(* :chapter: FORMAT *)
PROCEDURE DoFormat (VAR buffer: ARRAY OF CHAR; VAR pos: INTEGER; ob: Value);
VAR itm: Value;
BEGIN
   IF ob = NIL THEN
      PushText (buffer, pos, "NIL")
   ELSE
      itm := ob;
      WITH
        itm: Str  DO PushStr  (buffer, pos, itm.str^)
      | itm: Bool DO IF itm.b THEN PushText(buffer, pos, "true") ELSE PushText(buffer, pos,"false") END
      | itm: Int  DO PushInt  (buffer, pos, itm.i)
      | itm: Null DO PushText (buffer, pos, "null")
      | itm: Real DO PushReal (buffer, pos, itm.r)
      | itm: Sym  DO PushText (buffer, pos, itm.s^)
      | itm: Arr  DO
                PushChr (buffer, pos, '[');
                Indent (+1);
                WHILE itm # NIL DO
                   DoFormat (buffer, pos, itm.value);
                   IF itm.next # NIL THEN PushText (buffer, pos, ", ") END;
                   itm := itm.next;
                END;
                Indent (-1);
                PushChr     (buffer, pos, ']');
      | itm: Obj  DO
                PushChr (buffer, pos, '{');
                Indent  (+1);
                WHILE itm # NIL DO
                   PushNewline (buffer, pos);
                   PushStr  (buffer, pos, itm.name^);
                   PushChr  (buffer, pos, ':');
                   PushChr  (buffer, pos, ' ');
                   DoFormat (buffer, pos, itm.value);
                   IF itm.next # NIL THEN PushChr (buffer, pos, ',') END;
                   itm := itm.next;
                END;
                Indent (-1);
                PushNewline (buffer, pos);
                PushChr     (buffer, pos, '}')
      ELSE ASSERT (noError # noError, 200)
      END;
   END;
END DoFormat;

PROCEDURE Format* (VAR buffer: ARRAY OF CHAR; value: Value): BOOLEAN;
(** format/write Json.Value to buffer
    return TRUE in case of success
    return FALSE in case of buffer overflow
  *)
VAR 
   pos : INTEGER;
   res : BOOLEAN;
BEGIN
   pos := 0;
   DoFormat     (buffer, pos, value);
   PushNewline  (buffer, pos);
   PushChr      (buffer, pos, 0X);
   IF pos + 1 < LEN (buffer) THEN
      res := TRUE
   ELSE
      Out.Ln; Out.String ("############  Format: source buffer overflow."); 
      Out.Ln;
      res := FALSE
   END;
   RETURN res
END Format;


(* ------------------------------------------------------------------------- *)
(* :chapter: READ *)
(* :section:    spaces *)
PROCEDURE IsComment(): BOOLEAN;
BEGIN RETURN (cc = lgc1) & (src[srcPos + 1] = lgc2) END IsComment;

PROCEDURE IsLineComment(): BOOLEAN;
BEGIN RETURN (cc = lic1) & (src[srcPos + 1] = lic2) END IsLineComment;

PROCEDURE SkipComment;
BEGIN
   NextCC;
   WHILE (cc # 0X) & ~((lgc2 = cc) & (lgc1 = src[srcPos + 1])) DO NextCC END;
   IF cc # 0X THEN
      NextCC; NextCC
   ELSE
      Error ("comment not terminated")
   END
END SkipComment;

PROCEDURE SkipLineComment;
BEGIN
   WHILE (cc # 0X) & (cc # 0AX) DO NextCC END;
END SkipLineComment;

PROCEDURE SkipSpaces;
BEGIN
   WHILE   (cc # 0X)
        & ((cc = ' ') OR (cc = 0AX) OR (cc = 0DX) OR (cc = 09X))
   DO NextCC
   END;
   IF    IsComment()     THEN SkipComment;     SkipSpaces
   ELSIF IsLineComment() THEN SkipLineComment; SkipSpaces
   END;
END SkipSpaces;


(* ------------------------------------------------------------------------- *)
(* :section:    string *)
PROCEDURE ReadString (VAR s: jString);
VAR
   start, stop, len, i: INTEGER;
BEGIN
   (* ddx ("[ReadString"); *)
   ASSERT (cc = '"', 100);
   NextCC;
   start := srcPos;
   WHILE (cc # 0X) & (cc # '"') DO NextCC END;
   IF cc = 0X THEN Error ("string terminator missing") END;
   stop := srcPos;
   len  := stop - start;
   NEW (s, len + 1);
   NextCC; SkipSpaces;
   FOR i := 0 TO len - 1 DO  s[i] := src[start + i] END;
   s[len] := 0X;
   (* ddx (s^); ddx ("]"); *)
END ReadString;

PROCEDURE ReadStringValue (VAR value: Value);
VAR
   s   : jString;
   str : Str;
BEGIN
   ReadString (s);
   NEW (str); str.str := s;
   value := str;
END ReadStringValue;


(* ------------------------------------------------------------------------- *)
(* :section:    others *)
PROCEDURE ParseInt (VAR s: ARRAY OF CHAR): jInt;
VAR
   i   : INTEGER;
   c   : CHAR;
   neg : BOOLEAN;
   res : jInt;
BEGIN
   (* ddx (s); *)
   res := 0;
   i   := 0;
   ReadSign (neg, i, s[0]);
   REPEAT
      c := s[i];
      INC (i);
      IF (c # 0X) & (c # '_') THEN res := 10 * res + SHORT(ORD(c)) - 48 END;    (* in case jInt = SHORTINT *)
   UNTIL c = 0X;
   IF neg THEN res := -res END;
   (* ddx ("ParseInt]"); *)
   RETURN res;
END ParseInt;

PROCEDURE ParseReal (VAR s: ARRAY OF CHAR): jReal;
(** copy&pasted from String.Mod: PROCEDURE StrToReal
  * no dependency to Reals.Mod
  * now allways returning jReal
  *)
VAR
   p,e      : INTEGER;
   y,g      : jReal;
   neg,negE : BOOLEAN;

        PROCEDURE Ten (exp: INTEGER): jReal;
        (** return 10^exp *)
        VAR res,power : jReal;
        BEGIN
           res   :=  1.0;
           power := 10.0;
           WHILE exp > 0 DO
              (* bit for bit calculation of res *)
              IF ODD (exp) THEN res := res * power END ;
              power := power * power;
              exp   := exp DIV 2
           END;
           RETURN res
        END Ten;

BEGIN
   p := 0;
   y := 0;
   ReadSign (neg, p, s[p]);
   WHILE ("0" <= s[p]) & (s[p] <= "9") DO y := y * 10 + (ORD(s[p]) - 30H); INC(p); END;
   IF s[p] = "." THEN
      INC(p);
      g := 1;
      WHILE ("0" <= s[p]) & (s[p] <= "9") DO g := g / 10; y := y + g * (ORD(s[p]) - 30H); INC(p); END;
   END;
   IF s[p] = "E" THEN
      e := 0;
      INC (p);
      ReadSign (negE, p, s[p]);
      WHILE ("0" <= s[p]) & (s[p] <= "9") DO e := e * 10 + (ORD(s[p]) - 30H); INC(p); END;
      IF negE THEN
         y := y / Ten(e)
      ELSE y := y * Ten(e)
      END;
   END;
   IF neg THEN y := -y END;
   RETURN y
END ParseReal;


(* ------------------------------------------------------------------------- *)
(* :chapter: PARSE *)
PROCEDURE ReadOthers (VAR value: Value);
VAR
   s : jString;
   start, stop, len, i: INTEGER;
   bool : Bool;
   null : Null;
   int  : Int;
   res  : INTEGER;
   r    : jReal;
   real : Real;
   sym  : Sym;
BEGIN
   (* ddx ("[ReadOthers"); *)
   start := srcPos;
   WHILE (cc # 0X) & IsValid (cc) DO NextCC END;
   stop := srcPos;
   len  := stop - start;
   NEW (s, len + 1);
   FOR i := 0 TO len - 1 DO s[i] := src[start + i] END;
   s[len] := 0X;
   IF    (s^ = "true")  OR (s^ = "TRUE")  THEN NEW (bool); bool.b := TRUE;  value := bool
   ELSIF (s^ = "false") OR (s^ = "FALSE") THEN NEW (bool); bool.b := FALSE; value := bool
   ELSIF (s^ = "null")  OR (s^ = "NULL")  THEN NEW (null);                  value := null
   ELSIF IsInt    (s^)                    THEN NEW (int);  int.i  := ParseInt  (s^); value := int
   ELSIF IsReal   (s^)                    THEN NEW (real); real.r := ParseReal (s^); value := real
   ELSIF IsSymbol (s^)                    THEN NEW (sym);  sym.s  := s;              value := sym
   ELSE Error ("ReadOthers: strange item found"); value := NIL
   END;
   (* ddx ("ReadOthers]"); *)
END ReadOthers;


PROCEDURE ReadValue (VAR value: Value);
        PROCEDURE ReadArray (VAR value: Value);
        VAR
           arr,mem : Arr;
           v       : Value;
        BEGIN
           (* ddx ("[ReadArray"); *)
           ASSERT (cc = '[', 51);
           NextCC;
           INC (nestingArr);
           NEW (arr); arr := NIL;
           REPEAT
              SkipSpaces;
              IF cc # ']' THEN
                 ReadValue (v);
                 ArrCons   (arr, v);
              END;
              SkipSpaces;
              IF cc = ',' THEN
                 NextCC; SkipSpaces;
                 IF jCheckStrikt & (cc = ']') THEN Warn ("comma not recommended") END
              ELSIF jCheckStrikt & (cc # ']') THEN Warn ("comma expected")
              END;
              IF cc = '}' THEN Error ("']' or ',' expected. Got '}'") END;
           UNTIL (cc = 0X) OR (cc = ']') OR ~noError;
           NextCC; SkipSpaces;
           value := ArrReverse (arr);
           DEC (nestingArr);
        END ReadArray;

        PROCEDURE ReadObject (VAR value: Value);
        VAR
           obj,elt: Obj;
           name   : jString;
           v      : Value;
        BEGIN
           (* ddx ("ReadObject"); *)
           DEC (nestingObj);
           ASSERT (cc = '{', 52);
           NextCC;
           NEW (obj); obj := NIL;
           REPEAT
              NEW (elt);
              SkipSpaces;
              IF cc # '}' THEN
                 IF cc # '"' THEN Error ("Element name expected."); RETURN END;
                 ReadString(name);
                 IF cc # ':' THEN Error ("':' expected"); RETURN END;
                 NextCC; SkipSpaces;
                 ReadValue (v); SkipSpaces;
                 IF cc = ';' THEN Warn ("got a semicolon"); NextCC END;
                 IF cc = ',' THEN
                    NextCC; SkipSpaces;
                    IF cc = '}' THEN Warn ("comma trailing last element not recommended") END
                 ELSIF cc # '}' THEN Warn ("comma as element separator expected")
                 END;
                 IF name^ = "" THEN Warn ("element name is empty string.") END;
                 IF jCheckStrikt & ObjHasName (obj, name) THEN Warn ("element name multiple times listed") END;
                 ObjAdd (obj, name, v);
              END;
              IF cc = ']' THEN Error ("'}' or ',' expected. Got ']'") END;
           UNTIL (cc = 0X) OR (cc = '}') OR ~noError;
           NextCC; SkipSpaces;
           INC (nestingObj);
           value := ObjReverse (obj);
        END ReadObject;

(* ------------------------------------------------------------------------- *)
(* :section:    begin ReadValue *)
BEGIN
   (* DDX ("ReadValue"); iprint (srcLine); Out.Flush; *)
   SkipSpaces;
   IF    cc = 0X        THEN value := NIL
   ELSIF cc = CHR(34)   THEN ReadStringValue (value)
   ELSIF cc = '['       THEN ReadArray  (value)
   ELSIF cc = '{'       THEN ReadObject (value)
   ELSIF IsValid (cc)   THEN ReadOthers (value)
   ELSE Error ("ReadValue: Strange item found.")
   END;
   (* DDX ("ReadValue]"); *)
END ReadValue;


(* ------------------------------------------------------------------------- *)
(* :section:    parse *)
PROCEDURE Parse* (VAR value: Value; VAR jsonSource: ARRAY OF CHAR; VAR errormess: ARRAY OF CHAR): BOOLEAN;
(** Parse jsonSource
  * on success          return TRUE  and set value to result
  * on empty file       return TRUE  and set value to NIL
  * on failure          return FALSE and set value to NIL
  * print error messages and warnings about syntax deviations to errormess
  * in case error messages buffer overflow overflowing text is ignored
  * (errormess # "")  -> some warnings even on success of parsing
  *)
VAR res : BOOLEAN;
BEGIN
   (* DDX ("[Parse"); *)
   NEW  (src, LEN(jsonSource));
   COPY (jsonSource, src^);
   currentIndentation := 0;
   cc         := src[0];
   srcPos     := 0;
   srcCol     := 1;
   srcLine    := 1;
   noError    := TRUE;
   errmess    := "";
   errmessFF  := 0;
   nestingObj := 0;
   nestingArr := 0;
   value      := NIL;

   ReadValue (value);
   IF value = NIL THEN Warn ("file empty / no values found") END;

   SkipSpaces;
   IF cc # 0X         THEN Error ("trailing text following first value. (Is source 0-terminated?)") END;
   IF nestingObj # 0  THEN Error ("object nesting does not match: '{ }' are not balanced.") END;
   IF nestingArr # 0  THEN Error ("array nesting does not match: '[ ]' are not balanced.") END;
   IF noError THEN
      res := TRUE
   ELSE
      value := NIL;
      res   := FALSE
   END;
   COPY (errmess, errormess);
   (* IF res THEN ddx ("Parse]") ELSE DDX ("parsing-failed]") END; *)
   RETURN res;
END Parse;


(* ------------------------------------------------------------------------- *)
(* :chapter: MAIN *)
PROCEDURE Info*;
(** Types and Real numbers in Oberon
  * differ in size and range in depending on compiler flags and type names.
  * This is an attempt to find out, what currently is actualy used by
  * this parser.
  * PROCEDURE Info prints max and min values and type size.
  * Formating reals back to string is a story of it's own
  * and not yet solved.
  *)
BEGIN
   Out.Ln; Out.String ("============  Json.Mod Info");
   Out.Ln; Out.String ("  jInt");
   Out.Ln; Out.String ("    MAX (jInt):  "); Out.Int (MAX(jInt), 24);
   Out.Ln; Out.String ("    MIN (jInt):  "); Out.Int (MIN(jInt), 24);
   Out.Ln; Out.String ("    SIZE:        "); Out.Int (SIZE(jInt), 6);
   Out.Ln;
   Out.Ln; Out.String ("  jReal");
   Out.Ln; Out.String ("    SigFigs:     "); Out.Int (SigFigs, 6);  Out.String ("   !!! 3 <= SigFigs <= 10 " );
   Out.Ln; Out.String ("    SIZE:        "); Out.Int (SIZE(jReal), 6);
   Out.Ln;
   Out.Ln; Out.String ("  jComment:      "); Out.String ("     ");
        Out.Char (lgc1); Out.Char (lgc2);Out.String ("  ...  ");  Out.Char (lgc2); Out.Char (lgc1);
   Out.Ln; Out.String ("  jLineComment:  "); Out.String ("     ");
        Out.Char (lic1); Out.Char (lic2); Out.String ("  ...");
   Out.Ln; Out.String ("  jStrikt:            "); 
        IF jCheckStrikt THEN Out.String ("TRUE") ELSE Out.String ("FALSE") END;
END Info;


BEGIN (* MAIN *)

   COPY (jComment, errmess);
   lgc1 := errmess[0];
   lgc2 := errmess[1];
   COPY (jLineComment, errmess);
   lic1 := errmess[0];
   lic2 := errmess[1];
   COPY ("Nothing to complain about, so far.", errmess);
   (* Info; *)

END Json.


(* ------------------------------------------------------------------------- *)
(* :file: END (c) sts-q 2024-Feb *)
