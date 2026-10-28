MODULE PNGTest;  (* loksh PNGTest.Run pngsuite.list: PNG0 on the pictures of PngSuite *)

(* PngSuite (Willem van Schaik) has a picture for every colour type, bit depth, interlace,
  transparency and filter of PNG, and pictures damaged on purpose. pngsuite.list has a line for
  each: "name crc" for a picture to decode, crc the CRC-32 of its pixels as PNG0 decodes them
  (8-bit RGBA; checked against libpng, which differs only in rounding 16-bit samples to 8),
  "name !res" for a damaged one PNG0 must refuse with the result res. Each picture decoded is
  encoded again and the copy decoded: it must have the same pixels.

  PNGTest.Write names pngsuite.list writes the list for the pictures named in the file names (one
  a line) as PNG0 decodes them now. *)

IMPORT Files, Texts := PictureArgs, out := Out, Zlib, PNG0;

CONST Max = 128;

VAR checks, failed: LONGINT;

PROCEDURE Fail(VAR name: ARRAY OF CHAR; what: ARRAY OF CHAR; x: LONGINT);
BEGIN
  INC(failed); out.String("FAIL "); out.String(name); out.String(": "); out.String(what); out.String(" ");
  out.Int(x, 0); out.Ln
END Fail;

PROCEDURE Decode(VAR name: ARRAY OF CHAR; VAR img: PNG0.Image; VAR res: LONGINT);
VAR f: Files.File; R: Files.Rider;
BEGIN
  img := NIL; f := Files.Old(name);
  IF f = NIL THEN res := -1 ELSE Files.Set(R, f, 0); PNG0.Decode(R, img, res); Files.Close(f) END
END Decode;

PROCEDURE Crc(img: PNG0.Image): LONGINT;
BEGIN RETURN Zlib.CRC32(0, img.pix^, 0, img.width * img.height * 4)
END Crc;

(* encode img into a file in memory and decode it again: the same pixels? *)
PROCEDURE RoundTrip(img: PNG0.Image): BOOLEAN;
VAR f: Files.File; R: Files.Rider; copy: PNG0.Image; res, i, n: LONGINT;
BEGIN
  f := Files.New(""); Files.Set(R, f, 0); PNG0.Encode(R, img, 6, res);
  IF res # PNG0.ok THEN RETURN FALSE END;
  Files.Set(R, f, 0); PNG0.Decode(R, copy, res);
  IF (res # PNG0.ok) OR (copy.width # img.width) OR (copy.height # img.height) THEN RETURN FALSE END;
  n := img.width * img.height * 4; i := 0;
  WHILE i < n DO
    IF (copy.pix[i] # img.pix[i]) & (img.alpha OR (i MOD 4 # 3)) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END RoundTrip;

(* the next word of line from i *)
PROCEDURE Word(VAR line: ARRAY OF CHAR; VAR i: LONGINT; VAR w: ARRAY OF CHAR);
VAR k: LONGINT;
BEGIN
  WHILE line[i] = " " DO INC(i) END;
  k := 0; WHILE (line[i] # 0X) & (line[i] # " ") DO IF k < LEN(w) - 1 THEN w[k] := line[i]; INC(k) END; INC(i) END;
  w[k] := 0X
END Word;

PROCEDURE Number(VAR s: ARRAY OF CHAR; start: LONGINT): LONGINT;
VAR i, n: LONGINT; neg: BOOLEAN;
BEGIN
  i := start; n := 0; neg := FALSE;
  IF s[i] = "-" THEN neg := TRUE; INC(i) END;
  WHILE (s[i] >= "0") & (s[i] <= "9") DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END;
  IF neg THEN n := -n END;
  RETURN n
END Number;

PROCEDURE Case(VAR line: ARRAY OF CHAR);
VAR i, res, want: LONGINT; name, w: ARRAY Max OF CHAR; img: PNG0.Image;
BEGIN
  i := 0; Word(line, i, name); Word(line, i, w);
  IF (name = "") OR (name[0] = "#") THEN RETURN END;
  Decode(name, img, res);
  IF w[0] = "!" THEN
    INC(checks); want := Number(w, 1);
    IF res # want THEN Fail(name, "refused with", res) END
  ELSE
    INC(checks, 2); want := Number(w, 0);
    IF res # PNG0.ok THEN Fail(name, "not decoded, result", res); INC(failed)  (* both checks *)
    ELSE
      IF Crc(img) # want THEN Fail(name, "pixels differ, crc", Crc(img)) END;
      IF ~RoundTrip(img) THEN Fail(name, "encoded and decoded again it differs", 0) END
    END
  END
END Case;

PROCEDURE Line(VAR R: Files.Rider; VAR s: ARRAY OF CHAR): BOOLEAN;
VAR c: CHAR; i: LONGINT;
BEGIN
  i := 0; Files.Read(R, c);
  IF R.eof THEN RETURN FALSE END;
  WHILE ~R.eof & (c # 0AX) DO IF i < LEN(s) - 1 THEN s[i] := c; INC(i) END; Files.Read(R, c) END;
  s[i] := 0X; RETURN TRUE
END Line;

(* PNGTest.Run list *)
PROCEDURE Run*;
VAR A: Texts.Reader; name: ARRAY Max OF CHAR; line: ARRAY 256 OF CHAR; f: Files.File; R: Files.Rider;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, name) THEN out.String("usage: PNGTest.Run pngsuite.list"); out.Ln; RETURN END;
  f := Files.Old(name);
  IF f = NIL THEN out.String("FAIL no "); out.String(name); out.Ln; RETURN END;
  checks := 0; failed := 0; Files.Set(R, f, 0);
  WHILE Line(R, line) DO Case(line) END;
  out.String("PNGTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

PROCEDURE PutInt(VAR W: Files.Rider; x: LONGINT);
VAR d: ARRAY 12 OF CHAR; i: LONGINT;
BEGIN
  IF x < 0 THEN Files.Write(W, "-"); x := -x END;
  i := 0; REPEAT d[i] := CHR(x MOD 10 + ORD("0")); x := x DIV 10; INC(i) UNTIL x = 0;
  WHILE i > 0 DO DEC(i); Files.Write(W, d[i]) END
END PutInt;

(* PNGTest.Write names list: write the list for the pictures named in the file names *)
PROCEDURE Write*;
VAR A: Texts.Reader; names, list: ARRAY Max OF CHAR; name: ARRAY 256 OF CHAR; f, g: Files.File; R, W: Files.Rider;
  img: PNG0.Image; res, i: LONGINT;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, names) OR ~Texts.Arg(A, list) THEN out.String("usage: PNGTest.Write names list"); out.Ln; RETURN END;
  f := Files.Old(names);
  IF f = NIL THEN out.String(names); out.String(" not found"); out.Ln; RETURN END;
  g := Files.New(list); Files.Set(W, g, 0); Files.Set(R, f, 0);
  WHILE Line(R, name) DO
    IF name # "" THEN
      Decode(name, img, res);
      i := 0; WHILE name[i] # 0X DO Files.Write(W, name[i]); INC(i) END; Files.Write(W, " ");
      IF res = PNG0.ok THEN PutInt(W, Crc(img)) ELSE Files.Write(W, "!"); PutInt(W, res) END;
      Files.Write(W, 0AX)
    END
  END;
  Files.Register(g); Files.Close(g)
END Write;

END PNGTest.
