MODULE TestBDStrings;
IMPORT bdStrings, Out;

PROCEDURE OutBool(b: BOOLEAN);
BEGIN
  IF b THEN Out.String("TRUE") ELSE Out.String("FALSE") END
END OutBool;

PROCEDURE TestBasic;
VAR
  s1: ARRAY 10 OF CHAR;
  s2: ARRAY 5 OF CHAR;
  s3: ARRAY 3 OF CHAR;
  s4: ARRAY 256 OF CHAR;
  s5: ARRAY 1 OF CHAR;
BEGIN
  (* Test init and assign *)
  bdStrings.init(s1);
  bdStrings.assign(s1, "Hello");
  Out.String("s1: "); Out.String(s1);
  Out.String(" Len: "); Out.Int(bdStrings.length(s1), 0);
  Out.String(" Eos: "); Out.Int(bdStrings.eos(s1), 0); Out.Ln;

  (* Test append *)
  bdStrings.append(s1, "World");
  Out.String("Append: "); Out.String(s1);
  Out.String(" Len: "); Out.Int(bdStrings.length(s1), 0); Out.Ln;

  (* Test truncation *)
  bdStrings.assign(s2, "OverflowTest");
  Out.String("s2: "); Out.String(s2);
  Out.String(" Len: "); Out.Int(bdStrings.length(s2), 0); Out.Ln;

  (* Test accept *)
  s3[0] := 'A'; s3[1] := 'B'; s3[2] := bdStrings.nullChar;
  bdStrings.accept(s3);
  Out.String("s3: "); Out.String(s3);
  Out.String(" Eos: "); Out.Int(bdStrings.eos(s3), 0); Out.Ln;

  (* Test full string *)
  bdStrings.assign(s3, "XYZ");
  Out.String("Full s3: "); Out.String(s3);
  Out.String(" IsEmpty: "); OutBool(bdStrings.isEmpty(s3));
  Out.String(" Eos: "); Out.Int(bdStrings.eos(s3), 0); Out.Ln;

  (* Test boundary cases *)
  bdStrings.init(s5);
  Out.String("s5: "); Out.String(s5);
  Out.String(" IsEmpty: "); OutBool(bdStrings.isEmpty(s5)); Out.Ln;

  (* Test large string encoding *)
  bdStrings.init(s4);
  bdStrings.appendChar(s4, 'A');
  Out.String("s4 Len: "); Out.Int(bdStrings.length(s4), 0);
  Out.String(" Encoding: ");
  Out.Int(ORD(s4[255]), 0); Out.Ln;  (* Should show 255 for escVal *)
END TestBasic;

PROCEDURE TestAppendUpTo;
VAR
  s: ARRAY 20 OF CHAR;
  pos: LONGINT;
BEGIN
  bdStrings.init(s);
  pos := 0;
  bdStrings.appendUpTo(s, "Hello,World", pos, ',');
  Out.String("Part1: "); Out.String(s);
  Out.String(" pos: "); Out.Int(pos, 0); Out.Ln;

  bdStrings.append(s, " ");
  INC(pos);  (* Skip separator *)
  bdStrings.appendUpTo(s, "Hello,World", pos, 0X);
  Out.String("Full: "); Out.String(s); Out.Ln;
END TestAppendUpTo;

BEGIN
  Out.String("Starting tests..."); Out.Ln;
  TestBasic;
  TestAppendUpTo;
  Out.String("Tests completed."); Out.Ln;
END TestBDStrings.
