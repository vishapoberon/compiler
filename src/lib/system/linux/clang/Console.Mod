MODULE Console;  (* J. Templ, 29-June-96 *)

  (* output to Unix standard output device based Write system call *)

  IMPORT SYSTEM;

  VAR line: ARRAY 128 OF CHAR;
    pos: INTEGER;

  (* for read(), write() *)
  PROCEDURE -includeUnistd()
    "#include <unistd.h>";

  PROCEDURE -Write(adr, n: LONGINT)
    "write(1/*stdout*/, adr, n)";

  PROCEDURE -read(VAR ch: CHAR): LONGINT
    "read(0/*stdin*/, ch, 1)";

  PROCEDURE Flush*();
  BEGIN
    Write(SYSTEM.ADR(line), pos); pos := 0;
  END Flush;

  PROCEDURE Char*(ch: CHAR);
  BEGIN
    IF pos = LEN(line) THEN Flush() END ;
    line[pos] := ch;  INC(pos);
    IF ch = 0AX THEN Flush() END
  END Char;

  PROCEDURE String*(s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE s[i] # 0X DO Char(s[i]); INC(i) END
  END String;

  PROCEDURE Int*(i, n: LONGINT);
    VAR s: ARRAY 32 OF CHAR; i1, k: LONGINT;
  BEGIN
    IF i = SYSTEM.LSH(LONG(LONG(1)), SIZE(LONGINT)*8 - 1) THEN
      IF SIZE(LONGINT) = 8 THEN s := "8085774586302733229"; k := 19
      ELSE s := "8463847412"; k := 10
      END
    ELSE
      i1 := ABS(i);
      s[0] := CHR(i1 MOD 10 + ORD("0")); i1 := i1 DIV 10; k := 1;
      WHILE i1 > 0 DO s[k] := CHR(i1 MOD 10 + ORD("0")); i1 := i1 DIV 10; INC(k) END
    END ;
    IF i < 0 THEN s[k] := "-"; INC(k) END ;
    WHILE n > k DO Char(" "); DEC(n) END ;
    WHILE k > 0 DO  DEC(k); Char(s[k]) END
  END Int;

  PROCEDURE Ln*;
  BEGIN Char(0AX);  (* Unix end-of-line *)
  END Ln;

  PROCEDURE Bool*(b: BOOLEAN);
  BEGIN IF b THEN String("TRUE") ELSE String("FALSE") END
  END Bool;

  PROCEDURE Hex*(i: LONGINT);
    VAR k, n: LONGINT;
  BEGIN
    k := -28;
    WHILE k <= 0 DO
      n := ASH(i, k) MOD 16;
      IF n <= 9 THEN Char(CHR(ORD("0") + n)) ELSE Char(CHR(ORD("A") - 10 + n)) END ;
      INC(k, 4)
    END
  END Hex;

  PROCEDURE Read*(VAR ch: CHAR);
    VAR n: LONGINT;
  BEGIN Flush();
    n := read(ch);
    IF n # 1 THEN ch := 0X END
  END Read;

  PROCEDURE ReadLine*(VAR line: ARRAY OF CHAR);
    VAR i: LONGINT; ch: CHAR;
  BEGIN Flush();
    i := 0; Read(ch); 
    WHILE (i < LEN(line) - 1) & (ch # 0AX) & (ch # 0X) DO line[i] := ch; INC(i); Read(ch) END ;
    line[i] := 0X
  END ReadLine;

BEGIN pos := 0;
END Console.
