MODULE TOML;  (** a TOML reader: tables, keys, strings, arrays, inline tables, numbers, booleans *)

(* Parse reads a document into sections (tables) of fields. A field has its key (dotted keys
   and the keys of inline tables flattened: a.b), its value as text and its kind; an array has
   its elements in items, and as value the elements separated by blanks. Keys before the first
   table are in a section named "". [[name]] makes a new section name each time
   (GetNextSection finds the next one).
   Not TOML, but read for older files: an unquoted value up to the end of the line (kind Bare),
   and other characters than A-Z a-z 0-9 _ - in unquoted keys (path/file.Mod = ...).
   Errors are counted in doc.errors, the first one in doc.error and doc.errorLine; the rest
   of the line is skipped. Dates and times are kept as text (Bare). *)

CONST
  MaxKeyLen = 128;
  MaxValLen = 4096;
  MaxSecLen = 128;
  MaxItemLen = 512;

  (** kinds of values *)
  String* = 0; Integer* = 1; Float* = 2; Boolean* = 3; Array* = 4; Bare* = 5;

  TAB = 09X; LF = 0AX; CR = 0DX; QUOTE = 22X; APOS = 27X;
  TQ = '"""'; TA = "'''";

TYPE
  Item* = POINTER TO ItemDesc;
  ItemDesc* = RECORD
    value*: ARRAY MaxItemLen OF CHAR;
    next*: Item
  END;

  Field* = POINTER TO FieldDesc;
  FieldDesc* = RECORD
    key*:   ARRAY MaxKeyLen OF CHAR;
    value*: ARRAY MaxValLen OF CHAR;
    kind*:  INTEGER;
    items*: Item;  (* of an array *)
    line*:  LONGINT;
    next*:  Field
  END;

  Section* = POINTER TO SectionDesc;
  SectionDesc* = RECORD
    name*:  ARRAY MaxSecLen OF CHAR;
    first*: Field;
    next*:  Section
  END;

  Doc* = POINTER TO DocDesc;
  DocDesc* = RECORD
    first*: Section;
    errors*: INTEGER;
    error*: ARRAY 128 OF CHAR;  (* the first error *)
    errorLine*: LONGINT
  END;

VAR  (* the state of Parse *)
  pos, line: LONGINT;
  doc: Doc;
  sec, lastSec: Section;
  lastFld: Field;

(* no imports, so the module compiles unchanged with voc and polpo *)
PROCEDURE Length(VAR s: ARRAY OF CHAR): INTEGER;
VAR i: INTEGER;
BEGIN
  i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END;
  RETURN i
END Length;

PROCEDURE ToLower*(VAR s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    IF (s[i] >= "A") & (s[i] <= "Z") THEN s[i] := CHR(ORD(s[i]) + 20H) END;
    INC(i)
  END
END ToLower;

PROCEDURE TrimRight*(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := Length(s) - 1;
  WHILE (i >= 0) & ((s[i] = " ") OR (s[i] = TAB) OR (s[i] = CR) OR (s[i] = LF)) DO
    s[i] := 0X; DEC(i)
  END
END TrimRight;

PROCEDURE TrimLeft*(VAR s: ARRAY OF CHAR);
VAR i, j: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & ((s[i] = " ") OR (s[i] = TAB)) DO INC(i) END;
  IF i > 0 THEN
    j := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) DO s[j] := s[i]; INC(i); INC(j) END;
    s[j] := 0X
  END
END TrimLeft;

PROCEDURE Trim*(VAR s: ARRAY OF CHAR);
BEGIN TrimRight(s); TrimLeft(s) END Trim;

(* ----- parsing ----- *)

PROCEDURE Error(msg: ARRAY OF CHAR);
BEGIN
  IF doc.errors = 0 THEN COPY(msg, doc.error); doc.errorLine := line END;
  INC(doc.errors)
END Error;

(* the character at pos, 0X at the end *)
PROCEDURE Ch(VAR c: ARRAY OF CHAR): CHAR;
BEGIN
  IF pos < LEN(c) THEN RETURN c[pos] ELSE RETURN 0X END
END Ch;

PROCEDURE Next(VAR c: ARRAY OF CHAR);
BEGIN
  IF Ch(c) = LF THEN INC(line) END;
  IF Ch(c) # 0X THEN INC(pos) END
END Next;

PROCEDURE At(VAR c: ARRAY OF CHAR; s: ARRAY OF CHAR): BOOLEAN;  (* the text s at pos *)
VAR i: INTEGER;
BEGIN
  i := 0; WHILE (s[i] # 0X) & (pos + i < LEN(c)) & (c[pos + i] = s[i]) DO INC(i) END;
  RETURN s[i] = 0X
END At;

PROCEDURE SkipBlanks(VAR c: ARRAY OF CHAR);
BEGIN WHILE (Ch(c) = " ") OR (Ch(c) = TAB) DO Next(c) END
END SkipBlanks;

PROCEDURE SkipLine(VAR c: ARRAY OF CHAR);  (* to the start of the next line *)
BEGIN
  WHILE (Ch(c) # 0X) & (Ch(c) # LF) DO Next(c) END;
  IF Ch(c) = LF THEN Next(c) END
END SkipLine;

(* blanks, line ends and comments *)
PROCEDURE SkipSpace(VAR c: ARRAY OF CHAR);
BEGIN
  LOOP
    IF (Ch(c) = " ") OR (Ch(c) = TAB) OR (Ch(c) = CR) OR (Ch(c) = LF) THEN Next(c)
    ELSIF Ch(c) = "#" THEN WHILE (Ch(c) # 0X) & (Ch(c) # LF) DO Next(c) END
    ELSE EXIT
    END
  END
END SkipSpace;

PROCEDURE Put(VAR s: ARRAY OF CHAR; VAR n: INTEGER; ch: CHAR);
BEGIN
  IF n < LEN(s) - 1 THEN s[n] := ch; INC(n) END
END Put;

PROCEDURE Hex(ch: CHAR): LONGINT;
BEGIN
  IF (ch >= "0") & (ch <= "9") THEN RETURN ORD(ch) - ORD("0")
  ELSIF (CAP(ch) >= "A") & (CAP(ch) <= "F") THEN RETURN ORD(CAP(ch)) - ORD("A") + 10
  ELSE RETURN -1
  END
END Hex;

(* \uXXXX, \UXXXXXXXX: the code point as UTF-8 *)
PROCEDURE Unicode(VAR c: ARRAY OF CHAR; digits: INTEGER; VAR s: ARRAY OF CHAR; VAR n: INTEGER);
VAR u, d: LONGINT; i: INTEGER;
BEGIN
  u := 0; i := 0;
  WHILE i < digits DO
    d := Hex(Ch(c));
    IF d < 0 THEN Error("bad \u escape"); i := digits ELSE u := u * 16 + d; Next(c); INC(i) END
  END;
  IF u < 80H THEN Put(s, n, CHR(u))
  ELSIF u < 800H THEN Put(s, n, CHR(0C0H + u DIV 40H)); Put(s, n, CHR(80H + u MOD 40H))
  ELSIF u < 10000H THEN
    Put(s, n, CHR(0E0H + u DIV 1000H)); Put(s, n, CHR(80H + u DIV 40H MOD 40H)); Put(s, n, CHR(80H + u MOD 40H))
  ELSE
    Put(s, n, CHR(0F0H + u DIV 40000H MOD 8)); Put(s, n, CHR(80H + u DIV 1000H MOD 40H));
    Put(s, n, CHR(80H + u DIV 40H MOD 40H)); Put(s, n, CHR(80H + u MOD 40H))
  END
END Unicode;

(* a string at pos: "basic", 'literal', """multi-line basic""" or '''multi-line literal''' *)
PROCEDURE Str(VAR c: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
VAR q: CHAR; multi, basic: BOOLEAN; n: INTEGER; done: BOOLEAN;
BEGIN
  q := Ch(c); basic := q = QUOTE; n := 0;
  IF basic THEN multi := At(c, TQ) ELSE multi := At(c, TA) END;
  IF multi THEN
    Next(c); Next(c); Next(c);
    IF Ch(c) = CR THEN Next(c) END;
    IF Ch(c) = LF THEN Next(c) END  (* a line end after the opening quotes is not part of it *)
  ELSE Next(c)
  END;
  done := FALSE;
  WHILE ~done DO
    IF Ch(c) = 0X THEN Error("unterminated string"); done := TRUE
    ELSIF ~multi & ((Ch(c) = LF) OR (Ch(c) = CR)) THEN Error("line end in a string"); done := TRUE
    ELSIF Ch(c) = q THEN
      IF ~multi THEN Next(c); done := TRUE
      ELSIF (q = QUOTE) & At(c, TQ) OR (q = APOS) & At(c, TA) THEN
        Next(c); Next(c); Next(c);
        WHILE Ch(c) = q DO Put(s, n, q); Next(c) END;  (* up to two quotes before the closing ones *)
        done := TRUE
      ELSE Put(s, n, q); Next(c)
      END
    ELSIF basic & (Ch(c) = "\") THEN
      Next(c);
      CASE Ch(c) OF
        "b": Put(s, n, 08X); Next(c)
      | "t": Put(s, n, TAB); Next(c)
      | "n": Put(s, n, LF); Next(c)
      | "f": Put(s, n, 0CX); Next(c)
      | "r": Put(s, n, CR); Next(c)
      | "e": Put(s, n, 1BX); Next(c)
      | 22X: Put(s, n, QUOTE); Next(c)
      | "\": Put(s, n, "\"); Next(c)
      | "u": Next(c); Unicode(c, 4, s, n)
      | "U": Next(c); Unicode(c, 8, s, n)
      | " ", TAB, CR, LF:  (* a line ending backslash: the blanks and line ends after it go *)
        IF multi THEN WHILE (Ch(c) = " ") OR (Ch(c) = TAB) OR (Ch(c) = CR) OR (Ch(c) = LF) DO Next(c) END
        ELSE Error("bad escape"); Next(c)
        END
      ELSE Error("bad escape"); Next(c)
      END
    ELSIF Ch(c) = CR THEN Next(c)  (* CR LF: LF *)
    ELSE Put(s, n, Ch(c)); Next(c)
    END
  END;
  s[n] := 0X
END Str;

PROCEDURE BareKeyChar(ch: CHAR): BOOLEAN;  (* TOML, and more for older files *)
BEGIN
  RETURN (ch > " ") & (ch # "=") & (ch # ".") & (ch # "#") & (ch # QUOTE) & (ch # APOS)
    & (ch # "[") & (ch # "]") & (ch # "{") & (ch # "}") & (ch # ",")
END BareKeyChar;

(* a key at pos: parts, bare or quoted, joined by "." *)
PROCEDURE Key(VAR c: ARRAY OF CHAR; VAR key: ARRAY OF CHAR): BOOLEAN;
VAR part: ARRAY MaxKeyLen OF CHAR; n, i: INTEGER;
BEGIN
  n := 0; key[0] := 0X;
  LOOP
    SkipBlanks(c);
    IF (Ch(c) = QUOTE) OR (Ch(c) = APOS) THEN Str(c, part)
    ELSE
      i := 0; WHILE BareKeyChar(Ch(c)) DO Put(part, i, Ch(c)); Next(c) END; part[i] := 0X;
      IF i = 0 THEN Error("key expected"); RETURN FALSE END
    END;
    i := 0; WHILE part[i] # 0X DO Put(key, n, part[i]); INC(i) END;
    SkipBlanks(c);
    IF Ch(c) # "." THEN EXIT END;
    Put(key, n, "."); Next(c)
  END;
  key[n] := 0X;
  RETURN TRUE
END Key;

PROCEDURE NewSection(VAR name: ARRAY OF CHAR);
BEGIN
  NEW(sec); COPY(name, sec.name); sec.first := NIL; sec.next := NIL; lastFld := NIL;
  IF doc.first = NIL THEN doc.first := sec ELSE lastSec.next := sec END;
  lastSec := sec
END NewSection;

(* the section of keys before the first table *)
PROCEDURE Root;
VAR empty: ARRAY 2 OF CHAR;
BEGIN
  IF sec = NIL THEN empty := ""; NewSection(empty) END
END Root;

PROCEDURE NewField(VAR key: ARRAY OF CHAR; kind: INTEGER): Field;
VAR f: Field;
BEGIN
  Root;
  NEW(f); COPY(key, f.key); f.value[0] := 0X; f.kind := kind; f.items := NIL; f.line := line; f.next := NIL;
  IF sec.first = NIL THEN sec.first := f ELSE lastFld.next := f END;
  lastFld := f;
  RETURN f
END NewField;

(* a value that is not a string, an array or an inline table: up to ",", "]", "}", a comment or
   the end of the line (inArray, in an array or inline table: also "}" and blanks); its kind *)
PROCEDURE Scalar(VAR c: ARRAY OF CHAR; VAR s: ARRAY OF CHAR; inArray: BOOLEAN): INTEGER;
VAR n, i: INTEGER; digits, other, dot: BOOLEAN; ch: CHAR;
BEGIN
  n := 0;
  WHILE (Ch(c) # 0X) & (Ch(c) # LF) & (Ch(c) # CR) & (Ch(c) # "#")
    & ~(inArray & ((Ch(c) = ",") OR (Ch(c) = "]") OR (Ch(c) = "}") OR (Ch(c) = " ") OR (Ch(c) = TAB))) DO
    Put(s, n, Ch(c)); Next(c)
  END;
  s[n] := 0X; TrimRight(s);
  IF (s = "true") OR (s = "false") THEN RETURN Boolean END;
  IF (s = "inf") OR (s = "+inf") OR (s = "-inf") OR (s = "nan") OR (s = "+nan") OR (s = "-nan") THEN RETURN Float END;
  i := 0; IF (s[0] = "+") OR (s[0] = "-") THEN i := 1 END;
  digits := FALSE; other := FALSE; dot := FALSE;
  IF (s[i] = "0") & ((s[i+1] = "x") OR (s[i+1] = "o") OR (s[i+1] = "b")) THEN
    INC(i, 2); WHILE s[i] # 0X DO IF (Hex(s[i]) >= 0) OR (s[i] = "_") THEN digits := TRUE ELSE other := TRUE END; INC(i) END;
    IF digits & ~other THEN RETURN Integer END
  ELSE
    WHILE s[i] # 0X DO
      ch := s[i];
      IF (ch >= "0") & (ch <= "9") OR (ch = "_") THEN digits := TRUE
      ELSIF (ch = ".") OR (ch = "e") OR (ch = "E") OR (ch = "+") OR (ch = "-") THEN dot := TRUE
      ELSE other := TRUE
      END;
      INC(i)
    END;
    IF digits & ~other THEN IF dot THEN RETURN Float ELSE RETURN Integer END END
  END;
  RETURN Bare  (* a date, a time, or an unquoted text of older files *)
END Scalar;

PROCEDURE ^Value(VAR c: ARRAY OF CHAR; VAR key: ARRAY OF CHAR; f: Field; inArray: BOOLEAN);

(* add an element to the array f; its value grows by " " and the element *)
PROCEDURE AddItem(f: Field; VAR s: ARRAY OF CHAR);
VAR it, p: Item; n, i: INTEGER;
BEGIN
  NEW(it); COPY(s, it.value); it.next := NIL;
  IF Length(s) >= MaxItemLen THEN Error("array element too long") END;
  IF f.items = NIL THEN f.items := it ELSE p := f.items; WHILE p.next # NIL DO p := p.next END; p.next := it END;
  n := Length(f.value);
  IF n > 0 THEN Put(f.value, n, " ") END;
  i := 0; WHILE s[i] # 0X DO Put(f.value, n, s[i]); INC(i) END;
  f.value[n] := 0X;
  IF n >= MaxValLen - 1 THEN Error("array too long") END
END AddItem;

(* an array at pos, its elements to f; nested arrays are flattened *)
PROCEDURE Arr(VAR c: ARRAY OF CHAR; f: Field);
VAR s: ARRAY MaxValLen OF CHAR; k: INTEGER;
BEGIN
  Next(c);  (* [ *)
  LOOP
    SkipSpace(c);
    IF Ch(c) = "]" THEN Next(c); EXIT END;
    IF Ch(c) = 0X THEN Error("unterminated array"); EXIT END;
    IF Ch(c) = "[" THEN Arr(c, f)
    ELSIF (Ch(c) = QUOTE) OR (Ch(c) = APOS) THEN Str(c, s); AddItem(f, s)
    ELSIF Ch(c) = "{" THEN Error("inline table in an array (not supported)"); SkipLine(c); EXIT
    ELSE k := Scalar(c, s, TRUE); IF s = "" THEN Error("value expected"); Next(c) ELSE AddItem(f, s) END
    END;
    SkipSpace(c);
    IF Ch(c) = "," THEN Next(c)
    ELSIF Ch(c) # "]" THEN Error("',' or ']' expected in an array"); SkipLine(c); EXIT
    END
  END
END Arr;

(* an inline table at pos: its keys as prefix.key *)
PROCEDURE Inline(VAR c: ARRAY OF CHAR; VAR prefix: ARRAY OF CHAR);
VAR key, full: ARRAY MaxKeyLen OF CHAR; n, i: INTEGER;
BEGIN
  Next(c);  (* { *)
  SkipBlanks(c);
  IF Ch(c) = "}" THEN Next(c); RETURN END;
  LOOP
    IF ~Key(c, key) THEN SkipLine(c); EXIT END;
    IF Ch(c) # "=" THEN Error("'=' expected"); SkipLine(c); EXIT END;
    Next(c); SkipBlanks(c);
    COPY(prefix, full); n := Length(full); Put(full, n, "."); i := 0;
    WHILE key[i] # 0X DO Put(full, n, key[i]); INC(i) END;
    full[n] := 0X;
    Value(c, full, NIL, TRUE);
    SkipBlanks(c);
    IF Ch(c) = "}" THEN Next(c); EXIT
    ELSIF Ch(c) = "," THEN Next(c); SkipBlanks(c)
    ELSE Error("',' or '}' expected in an inline table"); SkipLine(c); EXIT
    END
  END
END Inline;

(* the value of key at pos, to a new field (f = NIL) *)
PROCEDURE Value(VAR c: ARRAY OF CHAR; VAR key: ARRAY OF CHAR; f: Field; inArray: BOOLEAN);
BEGIN
  IF (Ch(c) = QUOTE) OR (Ch(c) = APOS) THEN f := NewField(key, String); Str(c, f.value)
  ELSIF Ch(c) = "[" THEN f := NewField(key, Array); Arr(c, f)
  ELSIF Ch(c) = "{" THEN Inline(c, key)
  ELSE f := NewField(key, Bare); f.kind := Scalar(c, f.value, inArray)
  END
END Value;

(* [name] or [[name]] at pos *)
PROCEDURE Table(VAR c: ARRAY OF CHAR);
VAR name: ARRAY MaxKeyLen OF CHAR; double: BOOLEAN;
BEGIN
  Next(c); double := Ch(c) = "["; IF double THEN Next(c) END;
  IF Key(c, name) THEN
    IF Ch(c) # "]" THEN Error("']' expected"); SkipLine(c)
    ELSE
      Next(c);
      IF double THEN IF Ch(c) = "]" THEN Next(c) ELSE Error("']]' expected") END END;
      NewSection(name)
    END
  ELSE SkipLine(c)
  END
END Table;

(** read the TOML text content (ending with 0X or at its end) *)
PROCEDURE Parse*(VAR content: ARRAY OF CHAR): Doc;
VAR key: ARRAY MaxKeyLen OF CHAR; l: LONGINT;
BEGIN
  NEW(doc); doc.first := NIL; doc.errors := 0; doc.error := ""; doc.errorLine := 0;
  sec := NIL; lastSec := NIL; lastFld := NIL;
  pos := 0; line := 1;
  LOOP
    SkipSpace(content);
    IF Ch(content) = 0X THEN EXIT END;
    l := line;
    IF Ch(content) = "[" THEN Table(content)
    ELSIF Key(content, key) THEN
      IF Ch(content) # "=" THEN Error("'=' expected"); SkipLine(content)
      ELSE Next(content); SkipBlanks(content); Value(content, key, NIL, FALSE)
      END
    ELSE SkipLine(content)
    END;
    IF line = l THEN  (* only blanks or a comment may follow on the line *)
      SkipBlanks(content);
      IF Ch(content) = "#" THEN WHILE (Ch(content) # 0X) & (Ch(content) # LF) DO Next(content) END END;
      IF (Ch(content) # 0X) & (Ch(content) # LF) & (Ch(content) # CR) THEN Error("line end expected"); SkipLine(content) END
    END
  END;
  RETURN doc
END Parse;

PROCEDURE GetSection*(doc: Doc; VAR name: ARRAY OF CHAR): Section;
VAR
  sec: Section;
  sn, nn: ARRAY MaxSecLen OF CHAR;
BEGIN
  IF doc = NIL THEN RETURN NIL END;
  COPY(name, nn); ToLower(nn);
  sec := doc^.first;
  WHILE sec # NIL DO
    COPY(sec^.name, sn); ToLower(sn);
    IF sn = nn THEN RETURN sec END;
    sec := sec^.next
  END;
  RETURN NIL
END GetSection;

PROCEDURE GetNextSection*(prev: Section; VAR name: ARRAY OF CHAR): Section;
VAR
  sec: Section;
  sn, nn: ARRAY MaxSecLen OF CHAR;
BEGIN
  IF prev = NIL THEN RETURN NIL END;
  COPY(name, nn); ToLower(nn);
  sec := prev^.next;
  WHILE sec # NIL DO
    COPY(sec^.name, sn); ToLower(sn);
    IF sn = nn THEN RETURN sec END;
    sec := sec^.next
  END;
  RETURN NIL
END GetNextSection;

(** the field of key in sec (keys compared ignoring case); NIL if there is none *)
PROCEDURE Find*(sec: Section; VAR key: ARRAY OF CHAR): Field;
VAR
  fld: Field;
  fk, wk: ARRAY MaxKeyLen OF CHAR;
BEGIN
  IF sec = NIL THEN RETURN NIL END;
  COPY(key, wk); ToLower(wk);
  fld := sec^.first;
  WHILE fld # NIL DO
    COPY(fld^.key, fk); ToLower(fk);
    IF fk = wk THEN RETURN fld END;
    fld := fld^.next
  END;
  RETURN NIL
END Find;

PROCEDURE GetField*(sec: Section; VAR key: ARRAY OF CHAR; VAR value: ARRAY OF CHAR): BOOLEAN;
VAR fld: Field;
BEGIN
  COPY("", value);
  fld := Find(sec, key);
  IF fld = NIL THEN RETURN FALSE END;
  COPY(fld^.value, value); RETURN TRUE
END GetField;

END TOML.
