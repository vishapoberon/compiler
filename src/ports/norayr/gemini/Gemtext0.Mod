MODULE Gemtext0;  (** gemtext, line by line: the kinds of lines of text/gemini (and of Spartan) *)

(* Open a scanner on the body of a response (Gemini0) and take one line after the other with Next:
   its kind, its text, and for a link its URL (as written in the page; Gemini0.Resolve makes it
   absolute). The lines are not kept, so a page of any size needs no more memory than one line.
   A line longer than the text of a Line comes in pieces, all but the last with more = TRUE.
   Kinds: Text; Link (=> URL label: the label in text, the URL if there is no label); Prompt
   (=: URL label, Spartan: a link that asks for input); Heading1..3 (#, ##, ###); Item (a star, a blank); Quote
   (>); Pre (a line between ``` lines, as it is; text of the opening ``` line, the alt text, is in
   the PreStart line, the closing one is PreEnd). Line ends are LF or CR LF; text is left in
   UTF-8 as it arrived. *)

IMPORT Gemini0;

CONST
  Text* = 0; Link* = 1; Prompt* = 2; Heading1* = 3; Heading2* = 4; Heading3* = 5;
  Item* = 6; Quote* = 7; Pre* = 8; PreStart* = 9; PreEnd* = 10;  (** kinds of lines *)
  TextLen* = 4096;

TYPE
  Line* = RECORD
    kind*: LONGINT;
    text*: ARRAY TextLen OF CHAR;
    url*: ARRAY Gemini0.MaxURL OF CHAR;  (** Link, Prompt *)
    more*: BOOLEAN                      (** the text goes on in the next line *)
  END;

  Scanner* = RECORD
    chunk: Gemini0.Chunk;
    pos: LONGINT;
    pre: BOOLEAN;      (* inside ``` *)
    cont: LONGINT;     (* -1, or the kind of the line whose text goes on *)
    eot*: BOOLEAN      (** no more lines *)
  END;

PROCEDURE Open*(VAR S: Scanner; body: Gemini0.Chunk);
BEGIN
  S.chunk := body; S.pos := 0; S.pre := FALSE; S.cont := -1;
  WHILE (S.chunk # NIL) & (S.chunk.len = 0) DO S.chunk := S.chunk.next END;
  S.eot := S.chunk = NIL
END Open;

PROCEDURE Peek(VAR S: Scanner): CHAR;
BEGIN
  IF S.chunk = NIL THEN RETURN 0X END;
  RETURN S.chunk.data[S.pos]
END Peek;

PROCEDURE Skip(VAR S: Scanner);
BEGIN
  IF S.chunk # NIL THEN
    INC(S.pos);
    WHILE (S.chunk # NIL) & (S.pos >= S.chunk.len) DO S.chunk := S.chunk.next; S.pos := 0 END
  END
END Skip;

(* a := the rest of the line, at most LEN(a) - 1 characters; more: the line goes on *)
PROCEDURE ReadLine(VAR S: Scanner; VAR a: ARRAY OF CHAR; VAR more: BOOLEAN);
VAR i: LONGINT; c: CHAR;
BEGIN
  i := 0; more := FALSE;
  LOOP
    IF S.chunk = NIL THEN EXIT END;
    c := Peek(S);
    IF c = 0AX THEN Skip(S); EXIT END;
    IF i >= LEN(a) - 1 THEN more := TRUE; EXIT END;
    a[i] := c; INC(i); Skip(S)
  END;
  IF (i > 0) & (a[i - 1] = 0DX) & ~more THEN DEC(i) END;
  a[i] := 0X
END ReadLine;

PROCEDURE StartsWith(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0; WHILE (b[i] # 0X) & (a[i] = b[i]) DO INC(i) END;
  RETURN b[i] = 0X
END StartsWith;

(* a := a without its first n characters and the blanks after them *)
PROCEDURE Cut(VAR a: ARRAY OF CHAR; n: LONGINT);
VAR i: LONGINT;
BEGIN
  WHILE (a[n] = " ") OR (a[n] = 09X) DO INC(n) END;
  i := 0; WHILE a[n + i] # 0X DO a[i] := a[n + i]; INC(i) END;
  a[i] := 0X
END Cut;

(* a link line, the prefix cut: the URL to url, the label (or the URL) to text *)
PROCEDURE SplitLink(VAR L: Line);
VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE (L.text[i] # 0X) & (L.text[i] # " ") & (L.text[i] # 09X) DO INC(i) END;
  j := 0; WHILE (j < i) & (j < LEN(L.url) - 1) DO L.url[j] := L.text[j]; INC(j) END;
  L.url[j] := 0X;
  Cut(L.text, i);
  IF L.text[0] = 0X THEN COPY(L.url, L.text) END
END SplitLink;

(** the next line: FALSE at the end of the body *)
PROCEDURE Next*(VAR S: Scanner; VAR L: Line): BOOLEAN;
VAR more: BOOLEAN;
BEGIN
  L.url[0] := 0X; L.text[0] := 0X; L.more := FALSE;
  IF S.chunk = NIL THEN S.eot := TRUE; RETURN FALSE END;
  ReadLine(S, L.text, more);
  IF S.cont >= 0 THEN  (* the rest of a long line *)
    L.kind := S.cont; L.more := more; IF ~more THEN S.cont := -1 END;
    RETURN TRUE
  END;
  IF StartsWith(L.text, "```") THEN
    S.pre := ~S.pre;
    IF S.pre THEN L.kind := PreStart ELSE L.kind := PreEnd END;
    Cut(L.text, 3)
  ELSIF S.pre THEN L.kind := Pre
  ELSIF StartsWith(L.text, "=>") THEN L.kind := Link; Cut(L.text, 2); SplitLink(L)
  ELSIF StartsWith(L.text, "=:") THEN L.kind := Prompt; Cut(L.text, 2); SplitLink(L)
  ELSIF StartsWith(L.text, "###") THEN L.kind := Heading3; Cut(L.text, 3)
  ELSIF StartsWith(L.text, "##") THEN L.kind := Heading2; Cut(L.text, 2)
  ELSIF StartsWith(L.text, "#") THEN L.kind := Heading1; Cut(L.text, 1)
  ELSIF StartsWith(L.text, "* ") THEN L.kind := Item; Cut(L.text, 2)
  ELSIF StartsWith(L.text, ">") THEN L.kind := Quote; Cut(L.text, 1)
  ELSE L.kind := Text
  END;
  IF more THEN L.more := TRUE; S.cont := L.kind END;
  RETURN TRUE
END Next;

(** is the type of a response gemtext ("text/gemini", with or without parameters)? *)
PROCEDURE IsGemtext*(VAR meta: ARRAY OF CHAR): BOOLEAN;
VAR t: ARRAY 16 OF CHAR; i: LONGINT;
BEGIN
  IF meta[0] = 0X THEN RETURN TRUE END;  (* Gemini: an empty meta of a success means text/gemini *)
  i := 0;
  WHILE (i < 11) & (meta[i] # 0X) DO
    IF (meta[i] >= "A") & (meta[i] <= "Z") THEN t[i] := CHR(ORD(meta[i]) + 32) ELSE t[i] := meta[i] END; INC(i)
  END;
  t[i] := 0X;
  RETURN (t = "text/gemini") & ((meta[11] = 0X) OR (meta[11] = ";") OR (meta[11] = " "))
END IsGemtext;

END Gemtext0.
