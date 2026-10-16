MODULE Coco;
(* Ported from Shiryaev's Coco/R 2012.01 for Oxford Oberon
   to Vishap Oberon Compiler by Claude, 2026.02
   
   Original improvements by A. V. Shiryaev include:
   - IF() LL(1)-resolver
   - Enhanced literal handling
   - Better LL(1) diagnostics
*)

IMPORT Oberon, Texts, CRS, CRP, CRT;

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
    IF n = 51 THEN (* override *)
      Msg("this symbol not expected in Coco")
    ELSIF n = 52 THEN (* override *)
      Msg("invalid start of the program")
    ELSE
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
      | 33: Msg("'IF' expected")
      | 34: Msg("'CONTEXT' expected")
      | 35: Msg("'<' expected")
      | 36: Msg("'>' expected")
      | 37: Msg("'(.' expected")
      | 38: Msg("'.)' expected")
      | 39: Msg("??? expected")
      | 40: Msg("invalid TokenFactor")
      | 41: Msg("invalid Factor")
      | 42: Msg("invalid Factor")
      | 43: Msg("invalid Term")
      | 44: Msg("invalid Symbol")
      | 45: Msg("invalid SimSet")
      | 46: Msg("this symbol not expected in TokenDecl")
      | 47: Msg("invalid TokenDecl")
      | 48: Msg("invalid Declaration")
      | 49: Msg("invalid Declaration")
      | 50: Msg("invalid Declaration")
      | 51: Msg("this symbol not expected in CR")
      | 52: Msg("invalid CR")
      ELSE Texts.WriteString(w, "error "); Texts.WriteInt(w, n, 0)
      END
    END
  ELSE
    CASE n OF
    | 201: Msg("unexpected end of file")
    | 202: Msg("string terminator not on this line")
    | 203: Msg("a literal must not have attributes")
    | 204: Msg("this symbol kind not allowed in production")
    | 205: Msg("symbol declared without attributes")
    | 206: Msg("symbol declared with attributes")
    | 207: Msg("name declared twice")
    | 208: Msg("this type not allowed on left side of production")
    | 209: Msg("symbol earlier referenced without attributes")
    | 210: Msg("symbol earlier referenced with attributes")
    | 211: Msg("missing production for grammar name")
    | 212: Msg("grammar symbol must not have attributes")
    | 213: Msg("a literal must not be declared with a structure")
    | 214: Msg("semantic action not allowed here")
    | 215: Msg("undefined name")
    | 216: Msg("attributes not allowed in token declaration")
    | 217: Msg("name does not match name in heading")
    | 220: Msg("token may be empty")
    | 221: Msg("token must not start with an iteration")
    | 222: Msg("only characters allowed in comment declaration")
    | 223: Msg("only terminals may be weak")
    | 224: Msg("tokens must not contain blanks")
    | 225: Msg("comment delimiter must not exceed 2 characters")
    | 226: Msg("character set contains more than one character")
    | 227: Msg("token string declared twice")             (* NEW: Shiryaev *)
    | 228: Msg("undefined string in production")           (* NEW: Shiryaev *)
    ELSE Texts.WriteString(w, "error "); Texts.WriteInt(w, n, 0)
    END
  END;
  Texts.WriteLn(w); Texts.Append(Oberon.Log, w.buf)
END Error;

PROCEDURE Options(VAR s: Texts.Scanner);
  VAR i: INTEGER;
BEGIN
  IF s.nextCh = "\" THEN Texts.Scan(s); Texts.Scan(s);
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
  VAR s: Texts.Scanner; src, t: Texts.Text;
    pos, beg, end, time: LONGINT; i: INTEGER;
BEGIN
  Texts.OpenScanner(s, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(s);
  IF s.class = Texts.Name THEN
    NEW(src); Texts.Open(src, s.s);
    IF src # NIL THEN
      Texts.WriteString(w, "Coco/R - Compiler-Compiler V2.2 (Shiryaev 2012.01, voc port 2026.02)");
      Texts.WriteLn(w);
      Texts.Append(Oberon.Log, w.buf);
      
      i := 0; WHILE i < 10 DO CRT.ddt[i] := FALSE; INC(i) END;
      Options(s);
      
      Texts.WriteString(w, s.s);
      Texts.WriteLn(w);
      Texts.Append(Oberon.Log, w.buf);
      
      CRS.Reset(src, 0, Error); lastErrPos := -10;
      CRP.Parse
    END
  END
END Compile;

BEGIN
  Texts.OpenWriter(w);
  Compile
END Coco.
