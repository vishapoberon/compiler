MODULE OPS;  (* NW, RC 6.3.89 / 18.10.92 *)    (* object model 3.6.92 *)

  IMPORT OPM;

  CONST
    MaxStrLen* = 256;
    MaxIdLen = 256;

  TYPE
    Name* = ARRAY MaxIdLen OF CHAR;
    String* = ARRAY MaxStrLen OF CHAR;

  VAR
    (* name, str, numtyp, intval, realval, lrlval are implicit results of Get *)
    name*:    Name;
    str*:     String;
    numtyp*:  INTEGER;  (* 1 = char, 2 = integer, 3 = real, 4 = longreal *)
    intval*:  LONGINT;  (* integer value or string length *)
    realval*: REAL;
    lrlval*:  LONGREAL;

    ch: CHAR;     (*current character*)

  PROCEDURE err(n: INTEGER);
  BEGIN OPM.err(n)
  END err;

  PROCEDURE Str(VAR sym: SHORTINT);
    VAR i: INTEGER; och: CHAR;
  BEGIN i := 0; och := ch;
    LOOP OPM.Get(ch);
      IF ch = och THEN EXIT END ;
      IF ch < " " THEN err(3); EXIT END ;
      IF i = MaxStrLen-1 THEN err(241); EXIT END ;
      str[i] := ch; INC(i)
    END ;
    OPM.Get(ch); str[i] := 0X; intval := i + 1;
    IF intval = 2 THEN
      sym := OPM.number; numtyp := 1; intval := ORD(str[0])
    ELSE sym := OPM.string
    END
  END Str;

  PROCEDURE Identifier(VAR sym: SHORTINT);
    VAR i: INTEGER;
  BEGIN i := 0;
    REPEAT
      name[i] := ch; INC(i); OPM.Get(ch)
    UNTIL (ch < "0") OR ("9" < ch) & (CAP(ch) < "A") OR ("Z" < CAP(ch)) OR (i = MaxIdLen);
    IF i = MaxIdLen THEN err(240); DEC(i) END ;
    name[i] := 0X; sym := OPM.ident
  END Identifier;

  PROCEDURE Number;
    VAR i, m, n, d, e, maxHdig: INTEGER; dig: ARRAY 24 OF CHAR; f: LONGREAL; expCh: CHAR; neg: BOOLEAN;

    PROCEDURE Ten(e: INTEGER): LONGREAL;
      VAR x, p: LONGREAL;
    BEGIN x := 1; p := 10;
      WHILE e > 0 DO
        IF ODD(e) THEN x := x*p END;
        e := e DIV 2;
        IF e > 0 THEN p := p*p END (* prevent overflow *)
      END;
      RETURN x
    END Ten;

    PROCEDURE Ord(ch: CHAR; hex: BOOLEAN): INTEGER;
    BEGIN (* ("0" <= ch) & (ch <= "9") OR ("A" <= ch) & (ch <= "F") *)
      IF ch <= "9" THEN RETURN ORD(ch) - ORD("0")
      ELSIF hex THEN RETURN ORD(ch) - ORD("A") + 10
      ELSE err(2); RETURN 0
      END
    END Ord;

  BEGIN (* ("0" <= ch) & (ch <= "9") *)
    i := 0; m := 0; n := 0; d := 0;
    LOOP (* read mantissa *)
      IF ("0" <= ch) & (ch <= "9") OR (d = 0) & ("A" <= ch) & (ch <= "F") THEN
        IF (m > 0) OR (ch # "0") THEN (* ignore leading zeros *)
          IF n < LEN(dig) THEN dig[n] := ch; INC(n) END;
          INC(m)
        END;
        OPM.Get(ch); INC(i)
      ELSIF ch = "." THEN OPM.Get(ch);
        IF ch = "." THEN (* ellipsis *) ch := 7FX; EXIT
        ELSIF d = 0 THEN (* i > 0 *) d := i
        ELSE err(2)
        END
      ELSE EXIT
      END
    END; (* 0 <= n <= m <= i, 0 <= d <= i *)
    IF d = 0 THEN (* OPM.integer *)
      IF n = m THEN intval := 0; i := 0;
        IF ch = "X" THEN (* character *) OPM.Get(ch); numtyp := OPM.char;
          IF n <= 2 THEN
            WHILE i < n DO intval := intval*10H + Ord(dig[i], TRUE); INC(i) END
          ELSE err(203)
          END
        ELSIF ch = "H" THEN (* hexadecimal *) OPM.Get(ch); numtyp := OPM.integer;
          IF MAX(LONGINT) > 2147483647 THEN maxHdig := 16 ELSE maxHdig := 8 END;
          IF n <= maxHdig THEN
            IF (n = maxHdig) & (dig[0] > "7") THEN (* prevent overflow *) intval := -1 END;
            WHILE i < n DO intval := intval*10H + Ord(dig[i], TRUE); INC(i) END
          ELSE err(203)
          END
        ELSE (* decimal *) numtyp := OPM.integer;
          WHILE i < n DO d := Ord(dig[i], FALSE); INC(i);
            IF intval <= (MAX(LONGINT) - d) DIV 10 THEN intval := intval*10 + d
            ELSE err(203)
            END
          END
        END
      ELSE err(203)
      END
    ELSE (* fraction *)
      f := 0; e := 0; expCh := "E";
      WHILE n > 0 DO (* 0 <= f < 1 *) DEC(n); f := (Ord(dig[n], FALSE) + f)/10 END;
      IF (ch = "E") OR (ch = "D") THEN expCh := ch; OPM.Get(ch); neg := FALSE;
        IF ch = "-" THEN neg := TRUE; OPM.Get(ch)
        ELSIF ch = "+" THEN OPM.Get(ch)
        END;
        IF ("0" <= ch) & (ch <= "9") THEN
          REPEAT n := Ord(ch, FALSE); OPM.Get(ch);
            IF e <= (MAX(INTEGER) - n) DIV 10 THEN e := e*10 + n
            ELSE err(203)
            END
          UNTIL (ch < "0") OR ("9" < ch);
          IF neg THEN e := -e END
        ELSE err(2)
        END
      END;
      DEC(e, i-d-m); (* decimal point shift *)
      IF expCh = "E" THEN numtyp := OPM.real;
        IF (1-OPM.MaxRExp < e) & (e <= OPM.MaxRExp) THEN
          IF e < 0 THEN realval := SHORT(f / Ten(-e))
          ELSE realval := SHORT(f * Ten(e))
          END
        ELSE err(203)
        END
      ELSE numtyp := OPM.longreal;
        IF (1-OPM.MaxLExp < e) & (e <= OPM.MaxLExp) THEN
          IF e < 0 THEN lrlval := f / Ten(-e)
          ELSE lrlval := f * Ten(e)
          END
        ELSE err(203)
        END
      END
    END
  END Number;

  PROCEDURE Get*(VAR sym: SHORTINT);
    VAR s: SHORTINT;

    PROCEDURE Comment;  (* do not read after end of file *)
    BEGIN OPM.Get(ch);
      LOOP
        LOOP
          WHILE ch = "(" DO OPM.Get(ch);
            IF ch = "*" THEN Comment END
          END ;
          IF ch = "*" THEN OPM.Get(ch); EXIT END ;
          IF ch = OPM.Eot THEN EXIT END ;
          OPM.Get(ch)
        END ;
        IF ch = ")" THEN OPM.Get(ch); EXIT END ;
        IF ch = OPM.Eot THEN err(5); EXIT END
      END
    END Comment;

  BEGIN
    OPM.errpos := OPM.curpos-1;
    WHILE ch <= " " DO (*ignore control characters*)
      IF ch = OPM.Eot THEN sym := OPM.eof; RETURN
      ELSE OPM.Get(ch)
      END
    END ;
    CASE ch OF   (* ch > " " *)
      | 22X, 27X  : Str(s)
      | "#"  : s := OPM.neq; OPM.Get(ch)
      | "&"  : s := OPM.and; OPM.Get(ch)
      | "("  : OPM.Get(ch);
               IF ch = "*" THEN Comment; Get(s) ELSE s := OPM.lparen END
      | ")"  : s := OPM.rparen; OPM.Get(ch)
      | "*"  : s := OPM.times;  OPM.Get(ch)
      | "+"  : s := OPM.plus;   OPM.Get(ch)
      | ","  : s := OPM.comma;  OPM.Get(ch)
      | "-"  : s := OPM.minus;  OPM.Get(ch)
      | "."  : OPM.Get(ch);
               IF ch = "." THEN OPM.Get(ch); s := OPM.upto ELSE s := OPM.period END
      | "/"  : s := OPM.slash;  OPM.Get(ch)
      | "0".."9": Number; s := OPM.number
      | ":"  : OPM.Get(ch);
               IF ch = "=" THEN OPM.Get(ch); s := OPM.becomes ELSE s := OPM.colon END
      | ";"  : s := OPM.semicolon; OPM.Get(ch)
      | "<"  : OPM.Get(ch);
               IF ch = "=" THEN OPM.Get(ch); s := OPM.leq ELSE s := OPM.lss END
      | "="  : s :=  OPM.eql; OPM.Get(ch)
      | ">"  : OPM.Get(ch);
               IF ch = "=" THEN OPM.Get(ch); s := OPM.geq ELSE s := OPM.gtr END
      | "A": Identifier(s); IF name = "ARRAY" THEN s := OPM.array END
      | "B": Identifier(s);
            IF name = "BEGIN" THEN s := OPM.begin
            ELSIF name = "BY" THEN s := OPM.by
            END
      | "C": Identifier(s);
            IF name = "CASE" THEN s := OPM.case
            ELSIF name = "CONST" THEN s := OPM.const
            END
      | "D": Identifier(s);
            IF name = "DO" THEN s := OPM.do
            ELSIF name = "DIV" THEN s := OPM.div
            END
      | "E": Identifier(s);
            IF name = "END" THEN s := OPM.end
            ELSIF name = "ELSE" THEN s := OPM.else
            ELSIF name = "ELSIF" THEN s := OPM.elsif
            ELSIF name = "EXIT" THEN s := OPM.exit
            END
      | "F": Identifier(s); IF name = "FOR" THEN s := OPM.for END
      | "I": Identifier(s);
            IF name = "IF" THEN s := OPM.if
            ELSIF name = "IN" THEN s := OPM.in
            ELSIF name = "IS" THEN s := OPM.is
            ELSIF name = "IMPORT" THEN s := OPM.import
            END
      | "L": Identifier(s); IF name = "LOOP" THEN s := OPM.loop END
      | "M": Identifier(s);
            IF name = "MOD" THEN s := OPM.mod
            ELSIF name = "MODULE" THEN s := OPM.module
            END
      | "N": Identifier(s); IF name = "NIL" THEN s := OPM.nil END
      | "O": Identifier(s);
            IF name = "OR" THEN s := OPM.or
            ELSIF name = "OF" THEN s := OPM.of
            END
      | "P": Identifier(s);
            IF name = "PROCEDURE" THEN s := OPM.procedure
            ELSIF name = "POINTER" THEN s := OPM.pointer
            END
      | "R": Identifier(s);
            IF name = "RECORD" THEN s := OPM.record
            ELSIF name = "REPEAT" THEN s := OPM.repeat
            ELSIF name = "RETURN" THEN s := OPM.return
            END
      | "T": Identifier(s);
            IF name = "THEN" THEN s := OPM.then
            ELSIF name = "TO" THEN s := OPM.to
            ELSIF name = "TYPE" THEN s := OPM.type
            END
      | "U": Identifier(s); IF name = "UNTIL" THEN s := OPM.until END
      | "V": Identifier(s); IF name = "VAR" THEN s := OPM.var END
      | "W": Identifier(s);
            IF name = "WHILE" THEN s := OPM.while
            ELSIF name = "WITH" THEN s := OPM.with
            END
      | "G".."H", "J", "K", "Q", "S", "X".."Z": Identifier(s)
      | "["  : s := OPM.lbrak; OPM.Get(ch)
      | "]"  : s := OPM.rbrak; OPM.Get(ch)
      | "^"  : s := OPM.arrow; OPM.Get(ch)
      | "a".."z": Identifier(s)
      | "{"  : s := OPM.lbrace; OPM.Get(ch)
      | "|"  : s := OPM.bar; OPM.Get(ch)
      | "}"  : s := OPM.rbrace; OPM.Get(ch)
      | "~"  : s := OPM.not; OPM.Get(ch)
      | 7FX  : s := OPM.upto; OPM.Get(ch)
    ELSE s :=  OPM.null; OPM.Get(ch)
    END ;
    sym := s
  END Get;

  PROCEDURE Init*;
  BEGIN ch := " "
  END Init;

END OPS.
