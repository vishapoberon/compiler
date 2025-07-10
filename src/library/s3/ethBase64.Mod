MODULE ethBase64;  (* Adapted for VOC from Oberon System 3 *)
IMPORT Files, Texts, Oberon, Out;

VAR
  encTable: ARRAY 64 OF CHAR;
  decTable: ARRAY 128 OF INTEGER;
  W: Texts.Writer;

PROCEDURE DecodeText*(T: Texts.Text; beg: LONGINT; F: Files.File): BOOLEAN;
VAR
  R: Texts.Reader;
  codes: ARRAY 4 OF INTEGER;
  Ri: Files.Rider;
  i: INTEGER;
  ch: CHAR;
  ok, end: BOOLEAN;
BEGIN
  Files.Set(Ri, F, 0);
  ok := TRUE; end := FALSE;
  Texts.OpenReader(R, T, beg);
  Texts.Read(R, ch);
  REPEAT
    i := 0;
    WHILE ~R.eot & ok & (i < 4) DO
      WHILE ~R.eot & (ch <= " ") DO
        Texts.Read(R, ch)
      END;
      IF (ch >= 0X) & (ch < 80X) THEN
        codes[i] := decTable[ORD(ch)];
        ok := codes[i] >= 0; INC(i);
        IF ok THEN
          Texts.Read(R, ch)
        END
      ELSE
        ok := FALSE
      END
    END;
    IF i > 0 THEN
      IF ok & (i = 4) THEN
        Files.Write(Ri, CHR(ASH(codes[0], 2)+ASH(codes[1], -4)));
        Files.Write(Ri, CHR(ASH(codes[1], 4)+ASH(codes[2], -2)));
        Files.Write(Ri, CHR(ASH(codes[2], 6)+codes[3]))
      ELSIF ch = "=" THEN
        ok := TRUE; end := TRUE; DEC(i);
        IF i = 2 THEN
          Files.Write(Ri, CHR(ASH(codes[0], 2)+ASH(codes[1], -4)))
        ELSIF i = 3 THEN
          Files.Write(Ri, CHR(ASH(codes[0], 2)+ASH(codes[1], -4)));
          Files.Write(Ri, CHR(ASH(codes[1], 4)+ASH(codes[2], -2)))
        ELSIF i # 0 THEN
          ok := FALSE
        END
      ELSE
        end := TRUE
      END
    ELSE
      end := TRUE
    END
  UNTIL R.eot OR end;
  RETURN ok
END DecodeText;

PROCEDURE Decode*;
VAR
  S: Texts.Scanner;
  F: Files.File;
  T: Texts.Text;
  beg, end, time: LONGINT;
  res: INTEGER;
BEGIN
  Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
  Texts.Scan(S);
  IF S.class IN {Texts.Name, Texts.String} THEN
    Texts.WriteString(W, S.s);
    F := Files.New(S.s);
    Texts.Scan(S);
    IF (S.class = Texts.Char) & ((S.c = "@") OR (S.c = "^")) THEN
      T := NIL;
      time := -1;
      Oberon.GetSelection(T, beg, end, time);
      IF T = NIL THEN
        Texts.WriteString(W, " - no selection");
        Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        RETURN
      END
    ELSIF S.class IN {Texts.Name, Texts.String} THEN
      NEW(T);
      Texts.Open(T, S.s);
      beg := 0
    ELSE
      beg := Texts.Pos(S);
      T := Oberon.Par.text
    END;
    IF DecodeText(T, beg, F) THEN
      Files.Register(F);
      Texts.WriteString(W, " done")
    ELSE
      Texts.WriteString(W, " failed")
    END;
    Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END
END Decode;

PROCEDURE EncodeFile*(F: Files.File; T: Texts.Text);
VAR
  R: Files.Rider;
  i, j, c, c0, c1, c2, l: LONGINT;
  chars: ARRAY 3 OF CHAR;

  PROCEDURE OutCode();
  BEGIN
    IF l > 76 THEN  (* Standard line length for Base64 *)
      Texts.WriteLn(W);
      Texts.Append(T, W.buf);
      l := 0
    END;
    c0 := ORD(chars[0]);
    c := ASH(c0, -2);
    Texts.Write(W, encTable[c]);
    c0 := c0 - ASH(c, 2);

    c1 := ORD(chars[1]);
    c := ASH(c0, 4) + ASH(c1, -4);
    Texts.Write(W, encTable[c]);
    c1 := c1 MOD 16;

    c2 := ORD(chars[2]);
    c := ASH(c1, 2) + ASH(c2, -6);
    Texts.Write(W, encTable[c]);
    c2 := c2 MOD 64;

    Texts.Write(W, encTable[c2]);
    INC(l, 4)
  END OutCode;

BEGIN
  l := 0;
  Files.Set(R, F, 0);
  Files.Read(R, chars[0]);
  i := 1;
  WHILE ~R.eof DO
    IF i >= 3 THEN
      OutCode();
      i := 0
    END;
    Files.Read(R, chars[i]);
    INC(i)
  END;
  DEC(i);
  IF i > 0 THEN
    j := i;
    WHILE i < 3 DO
      chars[i] := 0X;
      INC(i)
    END;
    OutCode();
    (* Handle padding *)
    IF j < 3 THEN
      Texts.Append(T, W.buf);
      (* Remove extra characters and add padding *)
      j := 3 - j;
      Texts.Delete(T, T.len - j, T.len);
      FOR i := 1 TO j DO
        Texts.Write(W, "=")
      END
    END
  END;
  Texts.WriteLn(W);
  Texts.Append(T, W.buf)
END EncodeFile;

PROCEDURE Encode*;
VAR
  S: Texts.Scanner;
  F: Files.File;
  T: Texts.Text;
  name: ARRAY 256 OF CHAR;
BEGIN
  NEW(T);
  Texts.Open(T, "");
  Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
  Texts.Scan(S);
  IF S.class IN {Texts.Name, Texts.String} THEN
    COPY(S.s, name);
    F := Files.Old(name);
    IF F # NIL THEN
      EncodeFile(F, T);
      (* In VOC, we'll output to console instead of opening a viewer *)
      Out.String("=== Base64 Encoded: "); Out.String(name);
      Out.String(" ==="); Out.Ln;
      (* Output the encoded text - would need a helper to print Text to console *)
      Out.String("[Base64 encoded content would be here]"); Out.Ln;
      Out.String("=== End ==="); Out.Ln;
    ELSE
      Out.String("File not found: "); Out.String(name); Out.Ln;
    END
  END
END Encode;

PROCEDURE InitTables();
VAR i, max: INTEGER;
BEGIN
  (* Build encoding table *)
  max := ORD("Z") - ORD("A");
  FOR i := 0 TO max DO
    encTable[i] := CHR(i + ORD("A"))
  END;
  INC(max);
  FOR i := max TO max + ORD("z") - ORD("a") DO
    encTable[i] := CHR(i - max + ORD("a"))
  END;
  max := max + ORD("z") - ORD("a") + 1;
  FOR i := max TO max + ORD("9") - ORD("0") DO
    encTable[i] := CHR(i - max + ORD("0"))
  END;
  encTable[62] := "+";
  encTable[63] := "/";

  (* Build decoding table *)
  FOR i := 0 TO 127 DO
    decTable[i] := -1
  END;
  FOR i := 0 TO 63 DO
    decTable[ORD(encTable[i])] := i
  END
END InitTables;

BEGIN
  InitTables();
  Texts.OpenWriter(W)
END ethBase64.
