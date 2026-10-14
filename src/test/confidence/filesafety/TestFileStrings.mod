MODULE TestFileStrings;
  IMPORT SYSTEM, Files, Out;
  CONST Long = 40000;
  VAR file: Files.File; rider: Files.Rider; i: LONGINT;
    guarded: RECORD before: CHAR; text: ARRAY 4 OF CHAR; after: CHAR END;
    one: ARRAY 1 OF CHAR; large: ARRAY Long+1 OF CHAR;

  PROCEDURE -EmptyString(VAR r: Files.Rider)
    'Files_ReadString(r, r__typ, (CHAR*)0, 0)';
  PROCEDURE -EmptyLine(VAR r: Files.Rider)
    'Files_ReadLine(r, r__typ, (CHAR*)0, 0)';

  PROCEDURE Guard;
  BEGIN ASSERT((guarded.before = "[") & (guarded.after = "]")) END Guard;

  PROCEDURE Line(text: ARRAY OF CHAR; carriage: BOOLEAN);
    VAR j: LONGINT;
  BEGIN
    j := 0;
    WHILE text[j] # 0X DO Files.Write(rider, text[j]); INC(j) END;
    IF carriage THEN Files.Write(rider, 0DX) END;
    Files.Write(rider, 0AX)
  END Line;

BEGIN
  guarded.before := "["; guarded.after := "]";
  file := Files.New(""); Files.Set(rider, file, 0);
  Files.WriteString(rider, "abcdefgh"); Files.WriteString(rider, "xy");
  Files.WriteString(rider, "");
  FOR i := 1 TO Long DO Files.Write(rider, "x") END;
  Files.Write(rider, 0X); Files.WriteString(rider, "tail");
  Files.Set(rider, file, 0);
  Files.ReadString(rider, guarded.text); ASSERT(guarded.text = "abc"); Guard;
  ASSERT(Files.Pos(rider) = 9);
  Files.ReadString(rider, guarded.text); ASSERT(guarded.text = "xy"); Guard;
  Files.ReadString(rider, one); ASSERT(one[0] = 0X);
  Files.ReadString(rider, guarded.text); ASSERT(guarded.text = "xxx"); Guard;
  Files.ReadString(rider, guarded.text); ASSERT(guarded.text = "tai"); Guard;
  Files.ReadString(rider, guarded.text); ASSERT((guarded.text = "") & rider.eof); Guard;
  Files.Set(rider, file, 13); Files.ReadString(rider, large);
  FOR i := 0 TO Long-1 DO ASSERT(large[i] = "x") END;
  ASSERT(large[Long] = 0X);
  Files.Set(rider, file, 0); EmptyString(rider); ASSERT(Files.Pos(rider) = 9);
  Files.ReadString(rider, guarded.text); ASSERT(guarded.text = "xy"); Guard;

  file := Files.New(""); Files.Set(rider, file, 0);
  Line("abcdefgh", TRUE); Line("xy", FALSE); Line("", FALSE);
  Files.Write(rider, "a"); Files.Write(rider, "b"); Files.Write(rider, 0DX);
  Line("cdef", FALSE); Line("xy", TRUE); Line("", TRUE);
  FOR i := 1 TO Long DO Files.Write(rider, "x") END;
  Files.Write(rider, 0DX); Files.Write(rider, 0AX);
  Files.Write(rider, "t"); Files.Write(rider, "a"); Files.Write(rider, "i"); Files.Write(rider, "l");
  Files.Set(rider, file, 0);
  Files.ReadLine(rider, guarded.text); ASSERT(guarded.text = "abc"); Guard;
  ASSERT(Files.Pos(rider) = 10);
  Files.ReadLine(rider, guarded.text); ASSERT(guarded.text = "xy"); Guard;
  Files.ReadLine(rider, one); ASSERT(one[0] = 0X);
  Files.ReadLine(rider, guarded.text);
  ASSERT((guarded.text[0] = "a") & (guarded.text[1] = "b") &
    (guarded.text[2] = 0DX) & (guarded.text[3] = 0X)); Guard;
  Files.ReadLine(rider, guarded.text); ASSERT(guarded.text = "xy"); Guard;
  Files.ReadLine(rider, guarded.text); ASSERT(guarded.text = ""); Guard;
  Files.ReadLine(rider, large);
  FOR i := 0 TO Long-1 DO ASSERT(large[i] = "x") END;
  ASSERT(large[Long] = 0X);
  Files.ReadLine(rider, guarded.text); ASSERT((guarded.text = "tai") & rider.eof); Guard;
  Files.ReadLine(rider, guarded.text); ASSERT(guarded.text = ""); Guard;
  Files.Set(rider, file, 0); EmptyLine(rider); ASSERT(Files.Pos(rider) = 10);
  Files.ReadLine(rider, guarded.text); ASSERT(guarded.text = "xy"); Guard;
  Files.Set(rider, file, 0); Files.ReadLine(rider, one); ASSERT(one[0] = 0X);
  ASSERT(Files.Pos(rider) = 10);
  Out.String("bounded file string tests passed"); Out.Ln
END TestFileStrings.
