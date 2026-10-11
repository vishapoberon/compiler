MODULE Main;
  IMPORT Out, oocStrings;
  VAR text: ARRAY 64 OF CHAR;
BEGIN
  text := "native";
  oocStrings.Capitalize(text);
  oocStrings.Append(" MODULES", text);
  Out.String(text); Out.Ln
END Main.
