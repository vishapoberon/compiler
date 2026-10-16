MODULE PICS;  (* NW 22.2.2005 / 13.8.2014    Scanner for PIC compiler*)
IMPORT Texts, Oberon;

CONST IdLen * = 32; NofKeys = 25;
  (*symbols*) null = 0;
  ast = 1; slash = 2; plus = 3; minus = 4; not = 5; and = 6; or = 7;
  eql = 10; neq = 11; geq = 12; lss = 13; leq = 14; gtr = 15;
  period = 16; comma = 17; colon = 18;
  op = 20; query = 21; lparen = 22; becomes = 23;
  ident = 24; if = 25; while = 26; repeat = 27;
  inc = 28; dec = 29; rol = 30; ror = 31;
  number = 32; rparen = 33; then = 34; do =  35;
  semicolon = 36; end = 37; else = 38 ; elsif =  39; until =  40; return = 41;
  int = 42; set = 43; bool = 44;
  const = 50; begin = 51; proced = 52; module = 53; eof = 54;

  VAR val * , typ * : LONGINT;
  id * : ARRAY IdLen OF CHAR;

  ch: CHAR;  (*lookahead*)
  K: LONGINT;
  R: Texts.Reader;
  W: Texts.Writer;
  key: ARRAY NofKeys, 16 OF CHAR;
  symno: ARRAY NofKeys OF LONGINT;

PROCEDURE position* (): LONGINT;
BEGIN RETURN Texts.Pos(R)
END position;

PROCEDURE Ident (VAR sym: LONGINT);
  VAR i, j, m: LONGINT;
BEGIN i := 0;
  REPEAT
    IF i < IdLen - 1 THEN id[i] := ch; INC(i) END ;
    Texts.Read(R, ch)
  UNTIL (ch < "0") OR (ch > "9") & (ch < "A") OR (ch > "Z") & (ch < "a") OR (ch > "z");
  id[i] := 0X;
  i := 0; j := NofKeys; (*search for keyword*)
  WHILE i < j DO
    m := (i + j) DIV 2;
    IF key[m] < id THEN i := m + 1 ELSE j := m END
  END ;
  IF key[j] = id THEN sym := symno[i] ELSE sym := ident END
END Ident;

PROCEDURE Number;
BEGIN val := 0; typ := 1;
  REPEAT val := 10 * val + ORD(ch) - ORD("0"); Texts.Read(R, ch)
  UNTIL (ch < "0") OR (ch > "9")
END Number;

PROCEDURE GetDigit (): LONGINT;
  VAR d: LONGINT;
BEGIN
  IF ("0" <= ch) & (ch <= "9") THEN d := ORD(ch) - 30H
  ELSIF ("A" <= ch) & (ch <= "F") THEN d := ORD(ch) - 37H
  ELSE d := 0
  END ;
  Texts.Read(R, ch); RETURN d
END GetDigit;

PROCEDURE Hex;
  VAR d1, d0: LONGINT;
BEGIN val := GetDigit() * 10H + GetDigit(); typ := 2
END Hex;

PROCEDURE Get* (VAR sym: LONGINT);
BEGIN
  WHILE (ch <= " ") OR (ch = "{") DO
    IF ch = "{" THEN
      REPEAT Texts.Read(R, ch) UNTIL (ch = "}") OR R.eot
    END ;
    Texts.Read(R, ch)
  END ;
  REPEAT
    WHILE ~R.eot & (ch <= " ") DO Texts.Read(R, ch) END;
    IF ch < "A" THEN
      IF ch < "0" THEN
        IF ch = "!" THEN Texts.Read(R, ch); sym := op
        ELSIF ch = "#" THEN Texts.Read(R, ch); sym := neq
        ELSIF ch = "$" THEN Texts.Read(R, ch); Hex; sym := number; typ := 2
        ELSIF ch = "&" THEN Texts.Read(R, ch); sym := and
        ELSIF ch = "(" THEN Texts.Read(R, ch); sym := lparen
        ELSIF ch = ")" THEN Texts.Read(R, ch); sym := rparen
        ELSIF ch = "*" THEN Texts.Read(R, ch); sym := ast
        ELSIF ch = "+" THEN Texts.Read(R, ch); sym := plus
        ELSIF ch = "," THEN Texts.Read(R, ch); sym := comma
        ELSIF ch = "-" THEN Texts.Read(R, ch); sym := minus
        ELSIF ch = "." THEN Texts.Read(R, ch); sym := period
        ELSIF ch = "/" THEN Texts.Read(R, ch); sym := slash
        ELSE Texts.Read(R, ch); (* " %  ' *) sym := null
        END
      ELSIF ch <= "9" THEN Number; sym := number
      ELSIF ch = ":" THEN Texts.Read(R, ch);
        IF ch = "=" THEN Texts.Read(R, ch); sym := becomes ELSE sym := colon END
      ELSIF ch = ";" THEN Texts.Read(R, ch); sym := semicolon
      ELSIF ch = "<" THEN  Texts.Read(R, ch);
        IF ch = "=" THEN Texts.Read(R, ch); sym := leq ELSE sym := lss END
      ELSIF ch = "=" THEN Texts.Read(R, ch); sym := eql
      ELSIF ch = ">" THEN Texts.Read(R, ch);
        IF ch = "=" THEN Texts.Read(R, ch); sym := geq ELSE sym := gtr END
      ELSIF ch = "?" THEN Texts.Read(R, ch); sym := query
      ELSE (* @ *) Texts.Read(R, ch); sym := null
      END
    ELSIF  ch < "a" THEN
      IF ch <= "Z" THEN Ident(sym)
      ELSE (* [ \ ] ^ _ `*) Texts.Read(R, ch); sym := null
      END
    ELSIF ch <= "z" THEN Ident(sym)
    ELSIF ch = "~" THEN Texts.Read(R, ch); sym := not
    ELSE (* { | } *) Texts.Read(R, ch); sym := null
    END
  UNTIL sym # null
END Get;

PROCEDURE Init* (T: Texts.Text; pos: LONGINT);
BEGIN Texts.OpenReader(R, T, pos); Texts.Read(R, ch)
END Init;

PROCEDURE Enter (word: ARRAY OF CHAR; val: LONGINT);
BEGIN key[K] := word; symno[K] := val; INC(K)
END Enter;

BEGIN Texts.OpenWriter(W); K := 0;
  Enter("BEGIN", begin);
  Enter("BOOL", bool);
  Enter("CONST", const);
  Enter("DEC", dec);
  Enter("DO", do);
  Enter("ELSE", else);
  Enter("ELSIF", elsif);
  Enter("END", end);
  Enter("IF", if);
  Enter("INC", inc);
  Enter("INT", int);
  Enter("MODULE", module);
  Enter("OR", or);
  Enter("PROCEDURE", proced);
  Enter("REPEAT", repeat);
  Enter("RETURN", return);
  Enter("ROL", rol);
  Enter("ROR", ror);
  Enter("SET", set);
  Enter("THEN", then);
  Enter("UNTIL", until);
  Enter("WHILE", while);
  key[K] := "~ "
END PICS.

