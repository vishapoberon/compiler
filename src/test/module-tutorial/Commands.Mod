MODULE Commands;
  IMPORT Out, oocStrings;
  VAR calls: LONGINT;

  PROCEDURE Run*;
    VAR text: ARRAY 64 OF CHAR;
  BEGIN
    text := "loaded";
    oocStrings.Capitalize(text);
    INC(calls);
    Out.String(text); Out.String(" calls: ");
    Out.Int(calls, 0); Out.Ln
  END Run;
END Commands.
