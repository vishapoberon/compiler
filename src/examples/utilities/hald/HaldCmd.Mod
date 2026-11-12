MODULE HaldCmd;
IMPORT Args, Files, Out, Platform, PNG0, JPEG0, HaldClut;
VAR input, lutName, output, option: ARRAY 4096 OF CHAR;
  source, lut, target: PNG0.Image;
  range, repeats, pass, start, elapsed: LONGINT;

PROCEDURE Fail(name, message: ARRAY OF CHAR);
BEGIN
  Out.String(name); Out.String(": "); Out.String(message); Out.Ln; HALT(1)
END Fail;

PROCEDURE Load(name: ARRAY OF CHAR): PNG0.Image;
VAR f: Files.File; reader: Files.Rider; image: PNG0.Image; jpg: JPEG0.Image;
  signature: ARRAY 2 OF CHAR; message: ARRAY 128 OF CHAR; result, i: LONGINT;
BEGIN
  f := Files.Old(name);
  IF f = NIL THEN Fail(name, "cannot open image") END;
  Files.Set(reader, f, 0); Files.ReadBytes(reader, signature, 2); Files.Set(reader, f, 0);
  IF (signature[0] = 0FFX) & (signature[1] = 0D8X) THEN
    JPEG0.Decode(reader, jpg, result);
    IF result # JPEG0.ok THEN JPEG0.Message(result, message); Fail(name, message) END;
    image := PNG0.NewImage(jpg.width, jpg.height);
    FOR i := 0 TO LEN(jpg.pix^)-1 DO image.pix[i] := jpg.pix[i] END
  ELSE
    PNG0.Decode(reader, image, result);
    IF result # PNG0.ok THEN PNG0.Message(result, message); Fail(name, message) END
  END;
  Files.Close(f); RETURN image
END Load;

PROCEDURE Save(image: PNG0.Image; name: ARRAY OF CHAR);
VAR f: Files.File; writer: Files.Rider; result: LONGINT; message: ARRAY 128 OF CHAR;
BEGIN
  f := Files.New(name);
  IF f = NIL THEN Fail(name, "cannot create image") END;
  Files.Set(writer, f, 0); PNG0.Encode(writer, image, 6, result);
  IF result # PNG0.ok THEN PNG0.Message(result, message); Fail(name, message) END;
  Files.Register(f); Files.Close(f)
END Save;

PROCEDURE Number(value: ARRAY OF CHAR): LONGINT;
VAR i, number: LONGINT;
BEGIN
  i := 0; number := 0;
  WHILE (value[i] >= "0") & (value[i] <= "9") & (number <= 1000) DO
    number := number*10 + ORD(value[i])-ORD("0"); INC(i)
  END;
  IF (i = 0) OR (value[i] # 0X) OR (number < 1) OR (number > 1000) THEN
    Fail(value, "repetitions must be in 1..1000")
  END;
  RETURN number
END Number;

BEGIN
  Args.Get(1, input); Args.Get(2, lutName); Args.Get(3, output); Args.Get(4, option);
  IF (input = "") OR (lutName = "") OR (output = "") THEN
    Out.String("usage: HaldCmd input.jpg|png lut.png output.png|- [repetitions]"); Out.Ln; HALT(1)
  END;
  repeats := 1; IF option # "" THEN repeats := Number(option) END;
  source := Load(input); lut := Load(lutName); range := HaldClut.CubeRange(lut.width, lut.height);
  IF range = 0 THEN Fail(lutName, "pixel count must be a colour cube of range 2 or larger") END;
  target := PNG0.NewImage(source.width, source.height); target.alpha := source.alpha;
  HaldClut.Apply(source.pix^, lut.pix^, range, target.pix^);
  FOR pass := 1 TO repeats DO
    start := Platform.Time();
    HaldClut.Apply(source.pix^, lut.pix^, range, target.pix^);
    elapsed := Platform.Time()-start;
    Out.String("conversion ms: "); Out.Int(elapsed, 0); Out.Ln
  END;
  IF output # "-" THEN Save(target, output) END;
  Out.Int(source.width, 0); Out.String(" x "); Out.Int(source.height, 0);
  Out.String(", cube range "); Out.Int(range, 0); Out.Ln
END HaldCmd.
