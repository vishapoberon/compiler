MODULE jpeg;  (** JPEG pictures in the console: information, conversion to and from PPM *)

IMPORT Files, Texts := PictureArgs, out := Out, JPEG0;

CONST Max = 256;

PROCEDURE Ln(s: ARRAY OF CHAR);
BEGIN out.String(s); out.Ln
END Ln;

PROCEDURE Help*;
BEGIN
  Ln("jpeg: JPEG pictures (JPEG0: baseline and progressive read, baseline written)");
  Ln("  jpeg.Info file ...           size, components, baseline or progressive");
  Ln("  jpeg.ToPPM in.jpg out.ppm    the picture as PPM (P6)");
  Ln("  jpeg.FromPNM in out.jpg [quality]");
  Ln("                               a PPM (P6), PGM (P5) or PAM (P7) picture as JPEG;");
  Ln("                               quality 1 to 100 (default 75); grey pictures stay grey");
  Ln("  jpeg.Copy in.jpg out.jpg [quality]   read and write again");
  Ln("examples:");
  Ln("  jpeg.Info picture.jpg");
  Ln("  jpeg.ToPPM picture.jpg picture.ppm");
  Ln("  jpeg.FromPNM picture.ppm picture.jpg 90")
END Help;

PROCEDURE Fail(name: ARRAY OF CHAR; res: LONGINT);
VAR s: ARRAY 64 OF CHAR;
BEGIN
  JPEG0.Message(res, s); out.String(name); out.String(": "); Ln(s)
END Fail;

PROCEDURE Int(VAR W: Files.Rider; x: LONGINT);
VAR d: ARRAY 12 OF CHAR; i: LONGINT;
BEGIN
  i := 0; REPEAT d[i] := CHR(x MOD 10 + ORD("0")); x := x DIV 10; INC(i) UNTIL x = 0;
  WHILE i > 0 DO DEC(i); Files.Write(W, d[i]) END
END Int;

PROCEDURE Str(VAR W: Files.Rider; s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN i := 0; WHILE s[i] # 0X DO Files.Write(W, s[i]); INC(i) END
END Str;

(* decode the JPEG file name; NIL after saying why not *)
PROCEDURE Load(VAR name: ARRAY OF CHAR): JPEG0.Image;
VAR f: Files.File; R: Files.Rider; img: JPEG0.Image; res: LONGINT;
BEGIN
  f := Files.Old(name);
  IF f = NIL THEN out.String(name); Ln(" not found"); RETURN NIL END;
  Files.Set(R, f, 0); JPEG0.Decode(R, img, res); Files.Close(f);
  IF res # JPEG0.ok THEN Fail(name, res); RETURN NIL END;
  RETURN img
END Load;

(** jpeg.Info file ... *)
PROCEDURE Info*;
VAR A: Texts.Reader; name: ARRAY Max OF CHAR; f: Files.File; R: Files.Rider; info: JPEG0.Info; res: LONGINT; any: BOOLEAN;
BEGIN
  Texts.OpenArgs(A); any := FALSE;
  WHILE Texts.Arg(A, name) DO
    any := TRUE; f := Files.Old(name);
    IF f = NIL THEN out.String(name); Ln(" not found")
    ELSE
      Files.Set(R, f, 0); JPEG0.ReadInfo(R, info, res); Files.Close(f);
      IF (res # JPEG0.ok) & (res # JPEG0.unsupported) THEN Fail(name, res)
      ELSE
        out.String(name); out.String(": "); out.Int(info.width, 0); out.String(" x "); out.Int(info.height, 0);
        CASE info.components OF
          1: out.String(", grey") | 3: out.String(", colour") | 4: out.String(", CMYK")
        ELSE out.String(", "); out.Int(info.components, 0); out.String(" components")
        END;
        IF res = JPEG0.unsupported THEN out.String(", a kind of JPEG that is not supported")
        ELSIF info.progressive THEN out.String(", progressive")
        ELSE out.String(", baseline")
        END;
        out.Ln
      END
    END
  END;
  IF ~any THEN Ln("usage: jpeg.Info file ...  (size, components, baseline or progressive)") END
END Info;

(** jpeg.ToPPM in.jpg out.ppm *)
PROCEDURE ToPPM*;
VAR A: Texts.Reader; src, dst: ARRAY Max OF CHAR; img: JPEG0.Image; f: Files.File; W: Files.Rider; i, n: LONGINT;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, src) OR ~Texts.Arg(A, dst) THEN Ln("usage: jpeg.ToPPM in.jpg out.ppm  (the picture as PPM)"); RETURN END;
  img := Load(src);
  IF img # NIL THEN
    f := Files.New(dst); Files.Set(W, f, 0);
    Str(W, "P6"); Files.Write(W, 0AX); Int(W, img.width); Files.Write(W, " "); Int(W, img.height); Files.Write(W, 0AX);
    Str(W, "255"); Files.Write(W, 0AX);
    i := 0; n := img.width * img.height * 4;
    WHILE i < n DO Files.Write(W, img.pix[i]); Files.Write(W, img.pix[i + 1]); Files.Write(W, img.pix[i + 2]); INC(i, 4) END;
    Files.Register(f); Files.Close(f);
    out.String(dst); out.String(": "); out.Int(img.width, 0); out.String(" x "); out.Int(img.height, 0); out.Ln
  END
END ToPPM;

(* the next word of the header of a PNM file *)
PROCEDURE Word(VAR R: Files.Rider; VAR w: ARRAY OF CHAR);
VAR c: CHAR; i: LONGINT;
BEGIN
  Files.Read(R, c);
  LOOP
    WHILE ~R.eof & ((c = " ") OR (c = 09X) OR (c = 0AX) OR (c = 0DX)) DO Files.Read(R, c) END;
    IF c # "#" THEN EXIT END;
    WHILE ~R.eof & (c # 0AX) DO Files.Read(R, c) END
  END;
  i := 0;
  WHILE ~R.eof & (c > " ") DO IF i < LEN(w) - 1 THEN w[i] := c; INC(i) END; Files.Read(R, c) END;
  w[i] := 0X
END Word;

PROCEDURE Num(VAR s: ARRAY OF CHAR): LONGINT;
VAR i, n: LONGINT;
BEGIN
  n := 0; i := 0;
  WHILE (s[i] >= "0") & (s[i] <= "9") & (n < 1000000) DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END;
  IF (i = 0) OR (s[i] # 0X) THEN RETURN -1 END;
  RETURN n
END Num;

(* read a PPM (P6), PGM (P5) or PAM (P7) picture of 8-bit samples; NIL after saying why not *)
PROCEDURE ReadPNM(VAR name: ARRAY OF CHAR): JPEG0.Image;
VAR f: Files.File; R: Files.Rider; w: ARRAY 32 OF CHAR; width, height, depth, maxval, i, n: LONGINT;
  img: JPEG0.Image; c: CHAR;
BEGIN
  f := Files.Old(name);
  IF f = NIL THEN out.String(name); Ln(" not found"); RETURN NIL END;
  Files.Set(R, f, 0); Word(R, w); width := -1; height := -1; depth := 3; maxval := -1;
  IF (w = "P6") OR (w = "P5") THEN
    IF w = "P5" THEN depth := 1 END;
    Word(R, w); width := Num(w); Word(R, w); height := Num(w); Word(R, w); maxval := Num(w)
  ELSIF w = "P7" THEN
    LOOP
      Word(R, w);
      IF R.eof OR (w = "ENDHDR") THEN EXIT
      ELSIF w = "WIDTH" THEN Word(R, w); width := Num(w)
      ELSIF w = "HEIGHT" THEN Word(R, w); height := Num(w)
      ELSIF w = "DEPTH" THEN Word(R, w); depth := Num(w)
      ELSIF w = "MAXVAL" THEN Word(R, w); maxval := Num(w)
      ELSIF w = "TUPLTYPE" THEN Word(R, w)
      END
    END
  ELSE out.String(name); Ln(": not a PPM, PGM or PAM picture"); RETURN NIL
  END;
  IF (width <= 0) OR (height <= 0) OR (maxval # 255) OR (depth < 1) OR (depth > 4) OR (width > JPEG0.MaxPixels DIV height) THEN
    out.String(name); Ln(": only 8-bit grey, RGB or RGB_ALPHA pictures"); RETURN NIL
  END;
  img := JPEG0.NewImage(width, height);
  i := 0; n := width * height;
  WHILE i < n DO
    IF depth <= 2 THEN Files.Read(R, c); img.pix[4 * i] := c; img.pix[4 * i + 1] := c; img.pix[4 * i + 2] := c
    ELSE Files.Read(R, img.pix[4 * i]); Files.Read(R, img.pix[4 * i + 1]); Files.Read(R, img.pix[4 * i + 2])
    END;
    IF (depth = 2) OR (depth = 4) THEN Files.Read(R, c) END;  (* the alpha goes *)
    INC(i)
  END;
  IF R.eof THEN out.String(name); Ln(": the picture data ends early"); RETURN NIL END;
  RETURN img
END ReadPNM;

PROCEDURE Save(img: JPEG0.Image; VAR name: ARRAY OF CHAR; quality: LONGINT);
VAR f: Files.File; W: Files.Rider; res: LONGINT;
BEGIN
  f := Files.New(name); Files.Set(W, f, 0);
  JPEG0.Encode(W, img, quality, res);
  IF res # JPEG0.ok THEN Fail(name, res)
  ELSE
    Files.Register(f); out.String(name); out.String(": "); out.Int(Files.Length(f), 0); Ln(" bytes")
  END;
  Files.Close(f)
END Save;

PROCEDURE Quality(VAR A: Texts.Reader): LONGINT;
VAR s: ARRAY 16 OF CHAR; n: LONGINT;
BEGIN
  IF Texts.Arg(A, s) THEN n := Num(s); IF (n >= 1) & (n <= 100) THEN RETURN n END END;
  RETURN 75
END Quality;

(** jpeg.FromPNM in out.jpg [quality] *)
PROCEDURE FromPNM*;
VAR A: Texts.Reader; src, dst: ARRAY Max OF CHAR; img: JPEG0.Image;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, src) OR ~Texts.Arg(A, dst) THEN
    Ln("usage: jpeg.FromPNM in out.jpg [quality]  (a PPM, PGM or PAM picture as JPEG; quality 1 to 100)"); RETURN
  END;
  img := ReadPNM(src);
  IF img # NIL THEN Save(img, dst, Quality(A)) END
END FromPNM;

(** jpeg.Copy in.jpg out.jpg [quality] *)
PROCEDURE Copy*;
VAR A: Texts.Reader; src, dst: ARRAY Max OF CHAR; img: JPEG0.Image;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, src) OR ~Texts.Arg(A, dst) THEN
    Ln("usage: jpeg.Copy in.jpg out.jpg [quality]  (read and write again; quality 1 to 100)"); RETURN
  END;
  img := Load(src);
  IF img # NIL THEN Save(img, dst, Quality(A)) END
END Copy;

END jpeg.
