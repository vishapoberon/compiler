MODULE png;  (** PNG pictures in the console: information, conversion to and from PPM and PAM *)

IMPORT Files, Texts := PictureArgs, out := Out, PNG0;

CONST Max = 256;

PROCEDURE Ln(s: ARRAY OF CHAR);
BEGIN out.String(s); out.Ln
END Ln;

PROCEDURE Help*;
BEGIN
  Ln("png: PNG pictures (PNG0: every kind of PNG read, 8-bit RGB and RGBA written)");
  Ln("  png.Info file ...            size, bits per sample, colour type, interlace");
  Ln("  png.ToPPM in.png out.ppm     the picture as PPM (P6), without its alpha");
  Ln("  png.ToPAM in.png out.pam     the picture as PAM (P7, RGB_ALPHA), with its alpha");
  Ln("  png.FromPNM in out.png [level]");
  Ln("                               a PPM (P6) or PAM (P7, RGB or RGB_ALPHA) picture as PNG;");
  Ln("                               level 0 to 9, the zlib compression (default 6)");
  Ln("  png.Copy in.png out.png [level]   read and write again (RGB, or RGBA with alpha)");
  Ln("examples:");
  Ln("  png.Info picture.png");
  Ln("  png.ToPPM picture.png picture.ppm");
  Ln("  png.FromPNM picture.ppm picture.png 9")
END Help;

PROCEDURE Fail(name: ARRAY OF CHAR; res: LONGINT);
VAR s: ARRAY 64 OF CHAR;
BEGIN
  PNG0.Message(res, s); out.String(name); out.String(": "); Ln(s)
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

(* decode the PNG file name; NIL after saying why not *)
PROCEDURE Load(VAR name: ARRAY OF CHAR): PNG0.Image;
VAR f: Files.File; R: Files.Rider; img: PNG0.Image; res: LONGINT;
BEGIN
  f := Files.Old(name);
  IF f = NIL THEN out.String(name); Ln(" not found"); RETURN NIL END;
  Files.Set(R, f, 0); PNG0.Decode(R, img, res); Files.Close(f);
  IF res # PNG0.ok THEN Fail(name, res); RETURN NIL END;
  RETURN img
END Load;

(** png.Info file ... *)
PROCEDURE Info*;
VAR A: Texts.Reader; name: ARRAY Max OF CHAR; f: Files.File; R: Files.Rider; info: PNG0.Info; res: LONGINT; any: BOOLEAN;
BEGIN
  Texts.OpenArgs(A); any := FALSE;
  WHILE Texts.Arg(A, name) DO
    any := TRUE; f := Files.Old(name);
    IF f = NIL THEN out.String(name); Ln(" not found")
    ELSE
      Files.Set(R, f, 0); PNG0.ReadInfo(R, info, res); Files.Close(f);
      IF res # PNG0.ok THEN Fail(name, res)
      ELSE
        out.String(name); out.String(": "); out.Int(info.width, 0); out.String(" x "); out.Int(info.height, 0);
        out.String(", "); out.Int(info.depth, 0); out.String(" bits, ");
        CASE info.colorType OF
          0: out.String("grey") | 2: out.String("RGB") | 3: out.String("palette")
        | 4: out.String("grey and alpha") | 6: out.String("RGB and alpha")
        END;
        IF info.interlaced THEN out.String(", interlaced") END;
        out.Ln
      END
    END
  END;
  IF ~any THEN Ln("usage: png.Info file ...  (size, bits per sample, colour type, interlace)") END
END Info;

(* write img as PPM (alpha FALSE) or PAM *)
PROCEDURE Write(img: PNG0.Image; VAR name: ARRAY OF CHAR; alpha: BOOLEAN);
VAR f: Files.File; W: Files.Rider; i, n: LONGINT;
BEGIN
  f := Files.New(name); Files.Set(W, f, 0);
  IF alpha THEN
    Str(W, "P7"); Files.Write(W, 0AX); Str(W, "WIDTH "); Int(W, img.width); Files.Write(W, 0AX);
    Str(W, "HEIGHT "); Int(W, img.height); Files.Write(W, 0AX); Str(W, "DEPTH 4"); Files.Write(W, 0AX);
    Str(W, "MAXVAL 255"); Files.Write(W, 0AX); Str(W, "TUPLTYPE RGB_ALPHA"); Files.Write(W, 0AX);
    Str(W, "ENDHDR"); Files.Write(W, 0AX);
    Files.WriteBytes(W, img.pix^, img.width * img.height * 4)
  ELSE
    Str(W, "P6"); Files.Write(W, 0AX); Int(W, img.width); Files.Write(W, " "); Int(W, img.height); Files.Write(W, 0AX);
    Str(W, "255"); Files.Write(W, 0AX);
    i := 0; n := img.width * img.height * 4;
    WHILE i < n DO Files.Write(W, img.pix[i]); Files.Write(W, img.pix[i + 1]); Files.Write(W, img.pix[i + 2]); INC(i, 4) END
  END;
  Files.Register(f); Files.Close(f)
END Write;

PROCEDURE Convert(alpha: BOOLEAN);
VAR A: Texts.Reader; src, dst: ARRAY Max OF CHAR; img: PNG0.Image;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, src) OR ~Texts.Arg(A, dst) THEN
    IF alpha THEN Ln("usage: png.ToPAM in.png out.pam  (the picture as PAM with its alpha)")
    ELSE Ln("usage: png.ToPPM in.png out.ppm  (the picture as PPM, without its alpha)")
    END;
    RETURN
  END;
  img := Load(src);
  IF img # NIL THEN
    Write(img, dst, alpha);
    out.String(dst); out.String(": "); out.Int(img.width, 0); out.String(" x "); out.Int(img.height, 0); out.Ln
  END
END Convert;

(** png.ToPPM in.png out.ppm *)
PROCEDURE ToPPM*;
BEGIN Convert(FALSE)
END ToPPM;

(** png.ToPAM in.png out.pam *)
PROCEDURE ToPAM*;
BEGIN Convert(TRUE)
END ToPAM;

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
  WHILE (s[i] >= "0") & (s[i] <= "9") DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END;
  IF (i = 0) OR (s[i] # 0X) THEN RETURN -1 END;
  RETURN n
END Num;

(* read a PPM (P6) or PAM (P7) picture of 8-bit samples; NIL after saying why not *)
PROCEDURE ReadPNM(VAR name: ARRAY OF CHAR): PNG0.Image;
VAR f: Files.File; R: Files.Rider; w: ARRAY 32 OF CHAR; width, height, depth, maxval, i, n: LONGINT;
  img: PNG0.Image;
BEGIN
  f := Files.Old(name);
  IF f = NIL THEN out.String(name); Ln(" not found"); RETURN NIL END;
  Files.Set(R, f, 0); Word(R, w); width := -1; height := -1; depth := 3; maxval := -1;
  IF w = "P6" THEN
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
  ELSE out.String(name); Ln(": not a PPM (P6) or PAM (P7) picture"); RETURN NIL
  END;
  IF (width <= 0) OR (height <= 0) OR (maxval # 255) OR (depth # 3) & (depth # 4) OR (width > PNG0.MaxPixels DIV height) THEN
    out.String(name); Ln(": only 8-bit RGB or RGB_ALPHA pictures"); RETURN NIL
  END;
  img := PNG0.NewImage(width, height); img.alpha := depth = 4;
  i := 0; n := width * height;
  WHILE i < n DO
    Files.Read(R, img.pix[4 * i]); Files.Read(R, img.pix[4 * i + 1]); Files.Read(R, img.pix[4 * i + 2]);
    IF depth = 4 THEN Files.Read(R, img.pix[4 * i + 3]) ELSE img.pix[4 * i + 3] := 0FFX END;
    INC(i)
  END;
  IF R.eof THEN out.String(name); Ln(": the picture data ends early"); RETURN NIL END;
  RETURN img
END ReadPNM;

PROCEDURE Save(img: PNG0.Image; VAR name: ARRAY OF CHAR; level: LONGINT);
VAR f: Files.File; W: Files.Rider; res: LONGINT;
BEGIN
  f := Files.New(name); Files.Set(W, f, 0);
  PNG0.Encode(W, img, level, res);
  IF res # PNG0.ok THEN Fail(name, res)
  ELSE
    Files.Register(f); out.String(name); out.String(": "); out.Int(Files.Length(f), 0); Ln(" bytes")
  END;
  Files.Close(f)
END Save;

PROCEDURE Level(VAR A: Texts.Reader): LONGINT;
VAR s: ARRAY 16 OF CHAR; n: LONGINT;
BEGIN
  IF Texts.Arg(A, s) THEN n := Num(s); IF (n >= 0) & (n <= 9) THEN RETURN n END END;
  RETURN 6
END Level;

(** png.FromPNM in out.png [level] *)
PROCEDURE FromPNM*;
VAR A: Texts.Reader; src, dst: ARRAY Max OF CHAR; img: PNG0.Image;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, src) OR ~Texts.Arg(A, dst) THEN
    Ln("usage: png.FromPNM in out.png [level]  (a PPM or PAM picture as PNG; level 0 to 9)"); RETURN
  END;
  img := ReadPNM(src);
  IF img # NIL THEN Save(img, dst, Level(A)) END
END FromPNM;

(** png.Copy in.png out.png [level] *)
PROCEDURE Copy*;
VAR A: Texts.Reader; src, dst: ARRAY Max OF CHAR; img: PNG0.Image;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, src) OR ~Texts.Arg(A, dst) THEN
    Ln("usage: png.Copy in.png out.png [level]  (read and write again; level 0 to 9)"); RETURN
  END;
  img := Load(src);
  IF img # NIL THEN Save(img, dst, Level(A)) END
END Copy;

END png.
