(* Implementation restrictions
       3  too many nodes in graph (>1500)                         CRG.NewNode
       4  too many sets (ANY-symbols or SYNC symbols)     CRT.NewAnySet, 
                                                                               CRT.ComputeSyncSet
       6  too many symbols (>300)                                   CRT.NewSym
       7  too many character classes (>50)                        CRT.NewClass
       9  too many conditions in generated code (>100)        CRX.NewCondSet
       
   Trace output (ddt settings: ${digit})
    0  Prints states of automaton
    1  Prints start symbols and followers of nonterminals (also option /s)
    2  Prints the internal graph
    3  Trace of start symbol set computation
    4  Trace of follow set computation
    5  suppresses FORWARD declarations in parser (for multipass compilers)
    6  Prints the symbol list
    7  Prints a cross reference list  (also option /x)
    8  Write statistics
==========================================================================*)
MODULE Coco;

IMPORT Oberon, (*TextFrames,*) Texts := CmdlnTexts,(* Viewers,*) CRS, CRP, CRT;

CONST minErrDist = 8;

VAR w: Texts.Writer; lastErrPos: LONGINT;


PROCEDURE Error (n: INTEGER; pos: LONGINT);
  
  PROCEDURE Msg (s: ARRAY OF CHAR);
  BEGIN Texts.WriteString(w, s)
  END Msg;
  
BEGIN
  INC(CRS.errors);
  IF pos < lastErrPos + minErrDist THEN lastErrPos := pos; RETURN END;
  lastErrPos := pos;
  Texts.WriteInt(w, pos, 3); Texts.WriteString(w, ": ");
  IF n < 200 THEN
    CASE n OF
  |  0: Msg("EOF expected")
  |  1: Msg("ident expected")
  |  2: Msg("string expected")
  |  3: Msg("number expected")
  |  4: Msg("'COMPILER' expected")
  |  5: Msg("'IMPORT' expected")
  |  6: Msg("';' expected")
  |  7: Msg("'PRODUCTIONS' expected")
  |  8: Msg("'=' expected")
  |  9: Msg("'.' expected")
  | 10: Msg("'END' expected")
  | 11: Msg("'CHARACTERS' expected")
  | 12: Msg("'TOKENS' expected")
  | 13: Msg("'PRAGMAS' expected")
  | 14: Msg("'COMMENTS' expected")
  | 15: Msg("'FROM' expected")
  | 16: Msg("'TO' expected")
  | 17: Msg("'NESTED' expected")
  | 18: Msg("'IGNORE' expected")
  | 19: Msg("'CASE' expected")
  | 20: Msg("'+' expected")
  | 21: Msg("'-' expected")
  | 22: Msg("'CHR' expected")
  | 23: Msg("'(' expected")
  | 24: Msg("')' expected")
  | 25: Msg("'ANY' expected")
  | 26: Msg("'|' expected")
  | 27: Msg("'WEAK' expected")
  | 28: Msg("'[' expected")
  | 29: Msg("']' expected")
  | 30: Msg("'{' expected")
  | 31: Msg("'}' expected")
  | 32: Msg("'SYNC' expected")
  | 33: Msg("'CONTEXT' expected")
  | 34: Msg("'<' expected")
  | 35: Msg("'>' expected")
  | 36: Msg("'(.' expected")
  | 37: Msg("'.)' expected")
  | 38: Msg("??? expected")
  | 39: Msg("invalid TokenFactor")
  | 40: Msg("invalid Factor")
  | 41: Msg("invalid Factor")
  | 42: Msg("invalid Term")
  | 43: Msg("invalid Symbol")
  | 44: Msg("invalid SimSet")
  | 45: Msg("this symbol not expected in TokenDecl")
  | 46: Msg("invalid TokenDecl")
  | 47: Msg("invalid Declaration")
  | 48: Msg("invalid Declaration")
  | 49: Msg("invalid Declaration")
  | 50: Msg("this symbol not expected in Coco")
  | 51: Msg("invalid start of the program")
    ELSE Texts.WriteString(w, "error "); Texts.WriteInt(w, n, 0)
    END
  ELSE
    CASE n OF
    |  201: Msg("unexpected end of file");
    |  202: Msg("string terminator not on this line");
    |  203: Msg("a literal must not have attributes");
    |  204: Msg("this symbol kind not allowed in production");
    |  205: Msg("symbol declared without attributes");
    |  206: Msg("symbol declared with attributes");
    |  207: Msg("name declared twice");
    |  208: Msg("this type not allowed on left side of production");
    |  209: Msg("symbol earlier referenced without attributes");
    | 210: Msg("symbol earlier referenced with attributes");
    | 211: Msg("missing production for grammar name");
    | 212: Msg("grammar symbol must not have attributes");
    | 213: Msg("a literal must not be declared with a structure")
    | 214: Msg("semantic action not allowed here")
    | 215: Msg("undefined name")
    | 216: Msg("attributes not allowed in token declaration")
    | 217: Msg("name does not match name in heading")
    | 220: Msg("token may be empty")
    | 221: Msg("token must not start with an iteration")
    | 222: Msg("only characters allowed in comment declaration")
    | 223: Msg("only terminals may be weak")
    | 224:
    | 225: Msg("comment delimiter must not exceed 2 characters")
    | 226: Msg("character set contains more than one character")
    ELSE Texts.WriteString(w, "error "); Texts.WriteInt(w, n, 0)
    END
  END;
Texts.WriteLn(w); Texts.Append(Oberon.Log, w.buf)
END Error;

PROCEDURE Options(VAR s: Texts.Scanner);
  VAR i: INTEGER;
BEGIN
  IF s.nextCh = "/" THEN Texts.Scan(s); Texts.Scan(s);
    IF s.class = Texts.Name THEN i := 0;
      WHILE s.s[i] # 0X DO
        IF CAP(s.s[i]) = "X" THEN CRT.ddt[7] := TRUE
        ELSIF CAP(s.s[i]) = "S" THEN CRT.ddt[1] := TRUE
        END;
        INC(i)
      END
    END
  END;
END Options;


PROCEDURE Compile*;
  VAR (*v: Viewers.Viewer;*)(* f: TextFrames.Frame; *) s: Texts.Scanner; src, t: Texts.Text;
    pos, beg, end, time: LONGINT; i: INTEGER;
BEGIN
 (* Texts.OpenScanner(s, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(s);
  f := Oberon.Par.frame(TextFrames.Frame);
  src := NIL; pos := 0;
  IF (s.class = Texts.Char) & (s.c = "^") THEN
    Oberon.GetSelection(t, beg, end, time);
    IF time >= 0 THEN Texts.OpenScanner(s, t, beg); Texts.Scan(s) END
  END;*)
  IF s.class = Texts.Name THEN
    NEW(src); Texts.Open(src, s.s);
  (*ELSIF (s.class = Texts.Char) & (s.c = "*") THEN
    v := Oberon.MarkedViewer();
    IF (v # NIL) & (v.dsc.next IS TextFrames.Frame) THEN
      src := v.dsc.next(TextFrames.Frame).text;
      Texts.OpenScanner(s, v.dsc(TextFrames.Frame).text, 0); Texts.Scan(s)
    END
  ELSIF (s.class = Texts.Char) & (s.c = "@") THEN
    Oberon.GetSelection(t, beg, end, time);
    IF time >= 0 THEN src := t; pos := beg; s.s := " " END*)
  END;
  IF src # NIL THEN
    Texts.WriteString (w, "Coco/R - Compiler-Compiler V2.2"); Texts.Append(Oberon.Log, w.buf);
    i := 0; WHILE i < 10 DO CRT.ddt[i] := FALSE; INC(i) END;
    Options(s);
    Texts.WriteLn(w); Texts.WriteString(w, s.s); Texts.Append(Oberon.Log, w.buf);
    CRS.Reset(src, pos, Error); lastErrPos := -10;
    CRP.Parse
  END
END Compile;

BEGIN
  Texts.OpenWriter(w);
  Compile;
END Coco.
