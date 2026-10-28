MODULE JPEGTest;  (* loksh JPEGTest.Run jpegsuite.list: JPEG0 on the pictures of jpegsuite.tgz *)

(* jpegsuite.tgz has pictures cjpeg (libjpeg-turbo 3.1) made of a few small pictures with every kind of
  sampling, baseline and progressive, grey and RGB, with restart intervals, at qualities from 3 to 100;
  and pictures to refuse: arithmetic coding, 12 bits, lossless, damaged headers, not JPEG. jpegsuite.list
  has a line for each: "name crc crc75" for a picture to decode, crc the CRC-32 of its pixels as JPEG0
  decodes them (8-bit RGBA; equal to those of djpeg, but for xtruncp.jpg, a progressive picture cut
  short, where libjpeg guesses the missing coefficients), crc75 that of the pixels after encoding the
  picture with the quality 75 and decoding it again (equal to cjpeg -quality 75, -grayscale for grey
  pictures, and djpeg); "name !res" for a picture JPEG0 must refuse with the result res.

  JPEGTest.Write names list writes the list for the pictures named in the file names (one a line)
  as JPEG0 decodes and encodes them now. *)

IMPORT Files, Texts := PictureArgs, out := Out, Zlib, JPEG0;

CONST Max = 128;

VAR checks, failed: LONGINT;

PROCEDURE Fail(VAR name: ARRAY OF CHAR; what: ARRAY OF CHAR; x: LONGINT);
BEGIN
  INC(failed); out.String("FAIL "); out.String(name); out.String(": "); out.String(what); out.String(" ");
  out.Int(x, 0); out.Ln
END Fail;

PROCEDURE Decode(VAR name: ARRAY OF CHAR; VAR img: JPEG0.Image; VAR res: LONGINT);
VAR f: Files.File; R: Files.Rider;
BEGIN
  img := NIL; f := Files.Old(name);
  IF f = NIL THEN res := -1 ELSE Files.Set(R, f, 0); JPEG0.Decode(R, img, res); Files.Close(f) END
END Decode;

PROCEDURE Crc(img: JPEG0.Image): LONGINT;
BEGIN RETURN Zlib.CRC32(0, img.pix^, 0, img.width * img.height * 4)
END Crc;

(* the CRC of img encoded with the quality 75 into a file in memory and decoded again; -1 if that fails *)
PROCEDURE Crc75(img: JPEG0.Image): LONGINT;
VAR f: Files.File; R: Files.Rider; copy: JPEG0.Image; res: LONGINT;
BEGIN
  f := Files.New(""); Files.Set(R, f, 0); JPEG0.Encode(R, img, 75, res);
  IF res # JPEG0.ok THEN RETURN -1 END;
  Files.Set(R, f, 0); JPEG0.Decode(R, copy, res);
  IF (res # JPEG0.ok) OR (copy.width # img.width) OR (copy.height # img.height) THEN RETURN -1 END;
  RETURN Crc(copy)
END Crc75;

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
VAR i, res, want: LONGINT; name, w, w75: ARRAY Max OF CHAR; img: JPEG0.Image;
BEGIN
  i := 0; Word(line, i, name); Word(line, i, w); Word(line, i, w75);
  IF (name = "") OR (name[0] = "#") THEN RETURN END;
  Decode(name, img, res);
  IF w[0] = "!" THEN
    INC(checks); want := Number(w, 1);
    IF res # want THEN Fail(name, "refused with", res) END
  ELSE
    INC(checks, 2);
    IF res # JPEG0.ok THEN Fail(name, "not decoded, result", res); INC(failed)  (* both checks *)
    ELSE
      IF Crc(img) # Number(w, 0) THEN Fail(name, "pixels differ, crc", Crc(img)) END;
      IF Crc75(img) # Number(w75, 0) THEN Fail(name, "encoded and decoded again it differs, crc", Crc75(img)) END
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

(* JPEGTest.Run list *)
PROCEDURE Run*;
VAR A: Texts.Reader; name: ARRAY Max OF CHAR; line: ARRAY 256 OF CHAR; f: Files.File; R: Files.Rider;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, name) THEN out.String("usage: JPEGTest.Run jpegsuite.list"); out.Ln; RETURN END;
  f := Files.Old(name);
  IF f = NIL THEN out.String("FAIL no "); out.String(name); out.Ln; RETURN END;
  checks := 0; failed := 0; Files.Set(R, f, 0);
  WHILE Line(R, line) DO Case(line) END;
  out.String("JPEGTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

PROCEDURE PutInt(VAR W: Files.Rider; x: LONGINT);
VAR d: ARRAY 12 OF CHAR; i: LONGINT;
BEGIN
  IF x < 0 THEN Files.Write(W, "-"); x := -x END;
  i := 0; REPEAT d[i] := CHR(x MOD 10 + ORD("0")); x := x DIV 10; INC(i) UNTIL x = 0;
  WHILE i > 0 DO DEC(i); Files.Write(W, d[i]) END
END PutInt;

(* JPEGTest.Write names list: write the list for the pictures named in the file names *)
PROCEDURE Write*;
VAR A: Texts.Reader; names, list: ARRAY Max OF CHAR; name: ARRAY 256 OF CHAR; f, g: Files.File; R, W: Files.Rider;
  img: JPEG0.Image; res, i: LONGINT;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, names) OR ~Texts.Arg(A, list) THEN out.String("usage: JPEGTest.Write names list"); out.Ln; RETURN END;
  f := Files.Old(names);
  IF f = NIL THEN out.String(names); out.String(" not found"); out.Ln; RETURN END;
  g := Files.New(list); Files.Set(W, g, 0); Files.Set(R, f, 0);
  WHILE Line(R, name) DO
    IF name # "" THEN
      Decode(name, img, res);
      i := 0; WHILE name[i] # 0X DO Files.Write(W, name[i]); INC(i) END; Files.Write(W, " ");
      IF res = JPEG0.ok THEN PutInt(W, Crc(img)); Files.Write(W, " "); PutInt(W, Crc75(img))
      ELSE Files.Write(W, "!"); PutInt(W, res)
      END;
      Files.Write(W, 0AX)
    END
  END;
  Files.Register(g); Files.Close(g)
END Write;

END JPEGTest.
