MODULE GIFTest;  (* loksh GIFTest.Run gifsuite.list: GIF0 on the pictures of gifsuite.tgz *)

(* gifsuite.tgz has pictures ImageMagick made: of 2, 7, 16, 64 and 256 colours, interlaced, with a
  transparent colour, the first frame of an animation, 1 by 1, and palette pictures of PngSuite; and
  pictures to refuse or to read in part: not GIF, no image, a code size of 12, a picture cut short.
  gifsuite.list has a line for each: "name crc" for a picture to decode, crc the CRC-32 of its pixels as
  GIF0 decodes them (8-bit RGBA; equal to those of ImageMagick, -coalesce of the first frame), "name !res"
  for one GIF0 must refuse with the result res. Each picture decoded is encoded again and the copy
  decoded: it must have the same pixels. Two pictures made here have 4096 colours, one of them with
  transparent pixels: encoded, they must keep at most 256 colours, their transparency, and be near the
  original (a mean difference of the components below 6).

  GIFTest.Write names list writes the list for the pictures named in the file names (one a line) as
  GIF0 decodes them now. *)

IMPORT Files, Texts := PictureArgs, out := Out, Zlib, GIF0;

CONST Max = 128;

VAR checks, failed: LONGINT;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(failed); out.String("FAIL "); out.String(what); out.Ln END
END Check;

PROCEDURE Fail(VAR name: ARRAY OF CHAR; what: ARRAY OF CHAR; x: LONGINT);
BEGIN
  INC(failed); out.String("FAIL "); out.String(name); out.String(": "); out.String(what); out.String(" ");
  out.Int(x, 0); out.Ln
END Fail;

PROCEDURE Decode(VAR name: ARRAY OF CHAR; VAR img: GIF0.Image; VAR res: LONGINT);
VAR f: Files.File; R: Files.Rider;
BEGIN
  img := NIL; f := Files.Old(name);
  IF f = NIL THEN res := -1 ELSE Files.Set(R, f, 0); GIF0.Decode(R, img, res); Files.Close(f) END
END Decode;

PROCEDURE Crc(img: GIF0.Image): LONGINT;
BEGIN RETURN Zlib.CRC32(0, img.pix^, 0, img.width * img.height * 4)
END Crc;

(* img encoded into a file in memory and decoded again; NIL if that fails *)
PROCEDURE Again(img: GIF0.Image): GIF0.Image;
VAR f: Files.File; R: Files.Rider; copy: GIF0.Image; res: LONGINT;
BEGIN
  f := Files.New(""); Files.Set(R, f, 0); GIF0.Encode(R, img, res);
  IF res # GIF0.ok THEN RETURN NIL END;
  Files.Set(R, f, 0); GIF0.Decode(R, copy, res);
  IF (res # GIF0.ok) OR (copy.width # img.width) OR (copy.height # img.height) THEN RETURN NIL END;
  RETURN copy
END Again;

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
VAR i, res: LONGINT; name, w: ARRAY Max OF CHAR; img, copy: GIF0.Image;
BEGIN
  i := 0; Word(line, i, name); Word(line, i, w);
  IF (name = "") OR (name[0] = "#") THEN RETURN END;
  Decode(name, img, res);
  IF w[0] = "!" THEN
    INC(checks);
    IF res # Number(w, 1) THEN Fail(name, "refused with", res) END
  ELSE
    INC(checks, 2);
    IF res # GIF0.ok THEN Fail(name, "not decoded, result", res); INC(failed)  (* both checks *)
    ELSE
      IF Crc(img) # Number(w, 0) THEN Fail(name, "pixels differ, crc", Crc(img)) END;
      copy := Again(img);
      IF (copy = NIL) OR (Crc(copy) # Crc(img)) THEN Fail(name, "encoded and decoded again it differs", 0) END
    END
  END
END Case;

(* a picture of 64 by 64 pixels of 4096 colours; transparent, a square of 20 by 20 has alpha 0 *)
PROCEDURE Gradient(transparent: BOOLEAN): GIF0.Image;
VAR img: GIF0.Image; x, y, p: LONGINT;
BEGIN
  img := GIF0.NewImage(64, 64); y := 0;
  WHILE y < 64 DO
    x := 0;
    WHILE x < 64 DO
      p := (y * 64 + x) * 4;
      img.pix[p] := CHR(x * 4); img.pix[p + 1] := CHR(y * 4); img.pix[p + 2] := CHR(((x DIV 8) * 8 + y DIV 8) * 4);
      IF transparent & (x >= 20) & (x < 40) & (y >= 20) & (y < 40) THEN img.pix[p + 3] := 0X; img.alpha := TRUE
      ELSE img.pix[p + 3] := 0FFX
      END;
      INC(x)
    END;
    INC(y)
  END;
  RETURN img
END Gradient;

(* encoded, img keeps its transparency, at most 256 colours and a mean difference of the components
  (times 10) below 60 *)
PROCEDURE Quantized(transparent: BOOLEAN);
VAR img, copy: GIF0.Image; i, j, n, sum, colours, c, h: LONGINT; set: ARRAY 1024 OF LONGINT; ok: BOOLEAN;
BEGIN
  img := Gradient(transparent); copy := Again(img); ok := copy # NIL;
  IF ok THEN
    i := 0; WHILE i < 1024 DO set[i] := -1; INC(i) END;
    n := 64 * 64; sum := 0; colours := 0; i := 0;
    WHILE i < n DO
      IF img.pix[4 * i + 3] # copy.pix[4 * i + 3] THEN ok := FALSE
      ELSIF copy.pix[4 * i + 3] = 0FFX THEN
        j := 0; WHILE j < 3 DO INC(sum, ABS(ORD(img.pix[4 * i + j]) - ORD(copy.pix[4 * i + j]))); INC(j) END;
        c := (LONG(ORD(copy.pix[4 * i])) * 256 + ORD(copy.pix[4 * i + 1])) * 256 + ORD(copy.pix[4 * i + 2]);
        h := c MOD 1021;
        WHILE (set[h] # -1) & (set[h] # c) DO h := (h + 1) MOD 1024 END;
        IF (set[h] = -1) & (colours < 1000) THEN set[h] := c; INC(colours) END
      END;
      INC(i)
    END;
    out.String("4096 colours"); IF transparent THEN out.String(", transparent") END;
    out.String(": "); out.Int(colours, 0); out.String(" colours, mean difference "); out.Int(sum * 10 DIV (3 * n), 0);
    out.String(" / 10"); out.Ln;
    ok := ok & (colours <= 256) & (sum * 10 DIV (3 * n) < 60)
  END;
  IF transparent THEN Check("4096 colours with transparency encoded", ok) ELSE Check("4096 colours encoded", ok) END
END Quantized;

PROCEDURE Line(VAR R: Files.Rider; VAR s: ARRAY OF CHAR): BOOLEAN;
VAR c: CHAR; i: LONGINT;
BEGIN
  i := 0; Files.Read(R, c);
  IF R.eof THEN RETURN FALSE END;
  WHILE ~R.eof & (c # 0AX) DO IF i < LEN(s) - 1 THEN s[i] := c; INC(i) END; Files.Read(R, c) END;
  s[i] := 0X; RETURN TRUE
END Line;

(* GIFTest.Run list *)
PROCEDURE Run*;
VAR A: Texts.Reader; name: ARRAY Max OF CHAR; line: ARRAY 256 OF CHAR; f: Files.File; R: Files.Rider;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, name) THEN out.String("usage: GIFTest.Run gifsuite.list"); out.Ln; RETURN END;
  f := Files.Old(name);
  IF f = NIL THEN out.String("FAIL no "); out.String(name); out.Ln; RETURN END;
  checks := 0; failed := 0; Files.Set(R, f, 0);
  WHILE Line(R, line) DO Case(line) END;
  Quantized(FALSE); Quantized(TRUE);
  out.String("GIFTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

PROCEDURE PutInt(VAR W: Files.Rider; x: LONGINT);
VAR d: ARRAY 12 OF CHAR; i: LONGINT;
BEGIN
  IF x < 0 THEN Files.Write(W, "-"); x := -x END;
  i := 0; REPEAT d[i] := CHR(x MOD 10 + ORD("0")); x := x DIV 10; INC(i) UNTIL x = 0;
  WHILE i > 0 DO DEC(i); Files.Write(W, d[i]) END
END PutInt;

(* GIFTest.Write names list: write the list for the pictures named in the file names *)
PROCEDURE Write*;
VAR A: Texts.Reader; names, list: ARRAY Max OF CHAR; name: ARRAY 256 OF CHAR; f, g: Files.File; R, W: Files.Rider;
  img: GIF0.Image; res, i: LONGINT;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, names) OR ~Texts.Arg(A, list) THEN out.String("usage: GIFTest.Write names list"); out.Ln; RETURN END;
  f := Files.Old(names);
  IF f = NIL THEN out.String(names); out.String(" not found"); out.Ln; RETURN END;
  g := Files.New(list); Files.Set(W, g, 0); Files.Set(R, f, 0);
  WHILE Line(R, name) DO
    IF name # "" THEN
      Decode(name, img, res);
      i := 0; WHILE name[i] # 0X DO Files.Write(W, name[i]); INC(i) END; Files.Write(W, " ");
      IF res = GIF0.ok THEN PutInt(W, Crc(img)) ELSE Files.Write(W, "!"); PutInt(W, res) END;
      Files.Write(W, 0AX)
    END
  END;
  Files.Register(g); Files.Close(g)
END Write;

END GIFTest.
