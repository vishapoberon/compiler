MODULE LibraryMain;
  (* The host loads this application. Its imports are bundled VOC libraries,
     not LibraryDemo, and resolve as ordinary Oberon procedure calls. *)
  IMPORT oocStrings, ooc2IntStr, Math, Out;
  VAR text: ARRAY 64 OF CHAR; number: ARRAY 32 OF CHAR;
BEGIN
  text := "native"; oocStrings.Capitalize(text);
  oocStrings.Append(" MODULES", text);
  ASSERT(text = "NATIVE MODULES");
  ooc2IntStr.IntToStr(42, number); ASSERT(number = "42");
  ASSERT(ABS(Math.sqrt(16.0) - 4.0) < 0.001);
  Out.String(text); Out.Ln;
  Out.String("sqrt(16) = "); Out.Int(ENTIER(Math.sqrt(16.0)), 0); Out.Ln;
  Out.String("integer = "); Out.String(number); Out.Ln;
  Out.String("standalone library demo passed"); Out.Ln
END LibraryMain.
