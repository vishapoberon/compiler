MODULE testStrUtils;
IMPORT Out, strUtils, Strings;

PROCEDURE tstExtractWord(i: INTEGER; s: strUtils.string; ch: CHAR);
VAR
  ps: strUtils.pstring;
BEGIN
  Out.String("strUtils.ExtractWord(");
  Out.Int(i, 0);
  Out.String(", '");
  Out.String(s);
  Out.String("', '");
  Out.Char(ch);
  Out.String("') is ");
  ps := strUtils.ExtractWord(i, s, ch);
  Out.String(ps^); Out.Ln;
END tstExtractWord;


PROCEDURE test;
VAR
  s0, s1: strUtils.string;
  ps0, ps1: strUtils.pstring;
  pstrs0 : strUtils.pstrings;
  ch: CHAR;
  i : INTEGER;
BEGIN
  s0 := "manush";
  IF strUtils.contains(s0, "manush") THEN
    Out.String("contains!"); Out.Ln;
  ELSE
    Out.String("doesn't contain."); Out.Ln;
  END;
  strUtils.dumpChars(s0); Out.Ln;
  s0 := "aoeu,htns";
  ch := ",";
  i  := 2;
  Out.String("strUtils.Pos('");
  Out.Char(ch);
  Out.String("', '");
  Out.String(s0);
  Out.String("', ");
  Out.Int(i, 0);
  Out.String("); is ");
  i := strUtils.Pos(ch, s0, i);
  Out.Int(i, 0); Out.Ln;

  s0 := "aoe#;,.#yes#snthd#,,,";
  ch := '#';
  i  := 1; tstExtractWord(i, s0, ch);
  i  := 3; tstExtractWord(i, s0, ch);
  i  := 5; tstExtractWord(i, s0, ch);

  Out.String("strUtils.tokenize('");
  Out.String(s0);
  Out.String("', '");
  Out.Char(ch);
  Out.String("') is"); Out.Ln;
  pstrs0 := strUtils.tokenize(s0, ch);
  FOR i := 0 TO SHORT(LEN(pstrs0^)-1) DO
    Out.String(pstrs0^[i]^); Out.Ln
  END;

  s0 := "manush hangstatsi";
  strUtils.getNextWord(s0, 0, s1);
  Out.String(s1); Out.Ln;

  Out.String("testing strUtils.append"); Out.Ln;
  ps0 := NIL;
  ps1 := NIL;
  strUtils.append(ps1, ps0);

  ps0 := NIL;
  NEW(ps1, 5);
  COPY("aoeu", ps1^);
  strUtils.append(ps1, ps0);
    Out.String("length of src is "); Out.Int(Strings.Length(ps1^), 0); Out.Ln;
    Out.String("len of src is "); Out.Int(LEN(ps1^), 0); Out.Ln;
    Out.String("length of dst is "); Out.Int(Strings.Length(ps0^), 0); Out.Ln;
    Out.String("len of dst is "); Out.Int(LEN(ps0^), 0); Out.Ln;
    Out.String("res='"); Out.String(ps0^); Out.Char("'"); Out.Ln;
  NEW(ps0, 7); NEW(ps1, 3);
  COPY("norayr", ps0^);
  COPY(" t", ps1^);
  strUtils.append(ps1, ps0);
    Out.String("length of src is "); Out.Int(Strings.Length(ps1^), 0); Out.Ln;
    Out.String("len of src is "); Out.Int(LEN(ps1^), 0); Out.Ln;
    Out.String("length of dst is "); Out.Int(Strings.Length(ps0^), 0); Out.Ln;
    Out.String("len of dst is "); Out.Int(LEN(ps0^), 0); Out.Ln;
   Out.String("res='"); Out.String(ps0^); Out.Char("'"); Out.Ln;

   Out.String("testing copyBytes"); Out.Ln;
   NEW(ps0,2); NEW(ps1, 3);
   ps0^[0] := 'o'; ps0^[1] := 'e';
   ps1^[0] := 'a'; ps1^[1] := 'b'; ps1^[2] := 'c';
   strUtils.copyBytes(ps1^, ps0^, 0, 2);
   Out.String(ps0^); Out.Ln;

   Out.String("testing copyBytes"); Out.Ln;
   NEW(ps0,2); NEW(ps1, 3);
   ps0^[0] := 'o'; ps0^[1] := 'e';
   ps1^[0] := 'a'; ps1^[1] := 'b'; ps1^[2] := 'c';
   strUtils.copyBytes(ps0^, ps1^, 1, 2);
   Out.String(ps1^); Out.Ln;

   Out.String("testing strUtils.appendNumChars"); Out.Ln;
   NEW(ps0,3); ps1 := NIL;
   ps0^[0] := 'a'; ps0^[1] := 'o'; ps0^[2] := 'e';
   strUtils.appendNumChars(ps0, 3, ps1, 5);
   Out.String(ps1^); Out.Ln;

Out.String("testing strUtils.appendNumChars"); Out.Ln;
   NEW(ps0,3); NEW(ps1, 5);
   ps0^[0] := 'a'; ps0^[1] := 'o'; ps0^[2] := 'e';
   ps1^[0] := 'a'; ps1^[1] := 'b'; ps1^[2] := 'c'; ps1^[3]:='d'; ps1^[4]:='f';
   strUtils.appendNumChars(ps0, 3, ps1, 5);
   Out.String(ps1^); Out.Ln

END test;

BEGIN
  test
END testStrUtils.
