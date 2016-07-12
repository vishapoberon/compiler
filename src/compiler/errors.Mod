MODULE errors;

IMPORT Texts, Console;

VAR T: Texts.Text;  S: Texts.Scanner;

PROCEDURE Write*(n: INTEGER);
  VAR l: INTEGER;  c: CHAR;
BEGIN
  IF T = NIL THEN NEW(T); Texts.Open(T, "VishapOberonErrors.txt") END;
  Texts.OpenScanner(S, T, 0);
  REPEAT l := S.line; Texts.Scan(S)
  UNTIL (l # S.line) & (S.class = Texts.Int) & (S.i = n)  OR  S.eot;
  IF ~S.eot THEN Texts.Read(S, c);
    WHILE ~S.eot & (c >= ' ') DO Console.Char(c); Texts.Read(S, c) END
  END
END Write;

END errors.
