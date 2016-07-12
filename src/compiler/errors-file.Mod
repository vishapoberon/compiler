MODULE errors;

IMPORT Files, Console;

VAR f: Files.File; r: Files.Rider;

PROCEDURE eoln(c: CHAR): BOOLEAN; BEGIN RETURN (c = 0DX) OR (c = 0AX) END eoln;

PROCEDURE Write*(n: INTEGER);
  VAR done: BOOLEAN; e: INTEGER; c: CHAR;
BEGIN
  IF f = NIL THEN f := Files.Old("VishapOberonErrors.txt") END;
  ASSERT(f # NIL);
  Files.Set(r, f, 0);  Files.Read(r, c);  done := r.eof;
  WHILE ~done DO (* Process one line each time round this loop *)
    IF (c >= '0') & (c <= '9') THEN (* Line begins with a number, parse it *)
      e := ORD(c) - ORD('0'); Files.Read(r, c);
      WHILE (c >= '0') & (c <= '9') DO
        e := e * 10 + ORD(c) - ORD('0');
        Files.Read(r, c)
      END
    ELSE
      e := n+1; (* Line does not begin with a number, make sure we don't match *)
    END;
    IF e = n THEN
      WHILE c = ' ' DO Files.Read(r, c) END; (* Rest of this line is the message we want *)
      WHILE ~eoln(c) & ~r.eof DO Console.Char(c); Files.Read(r, c) END;
      done := TRUE
    ELSE
      (* This line does not contain our message *)
      WHILE ~eoln(c) & ~r.eof DO Files.Read(r, c) END;
      WHILE eoln(c) DO Files.Read(r, c) END;
      done := r.eof
    END
  END;
END Write;


BEGIN
END errors.
