MODULE HaldPrepare;
IMPORT Args, Files, Out, Strings, PNG0, JPEG0, HaldClut;
TYPE Name = ARRAY 4096 OF CHAR;
VAR input, lutName, directory, size, path: Name;
  source, lut, pixels: PNG0.Image;
  width, height, range: LONGINT;
  argument: INTEGER;

PROCEDURE Fail(name, message: ARRAY OF CHAR);
BEGIN
  Out.String(name); Out.String(": "); Out.String(message); Out.Ln; HALT(1)
END Fail;

PROCEDURE Load(name: ARRAY OF CHAR): PNG0.Image;
VAR file: Files.File; reader: Files.Rider; image: PNG0.Image; jpg: JPEG0.Image;
  signature: ARRAY 2 OF CHAR; message: ARRAY 128 OF CHAR; result, i: LONGINT;
BEGIN
  file := Files.Old(name);
  IF file = NIL THEN Fail(name, "cannot open image") END;
  Files.Set(reader, file, 0); Files.ReadBytes(reader, signature, 2);
  IF reader.res # 0 THEN Fail(name, "incomplete image signature") END;
  Files.Set(reader, file, 0);
  IF (signature[0] = 0FFX) & (signature[1] = 0D8X) THEN
    JPEG0.Decode(reader, jpg, result);
    IF result # JPEG0.ok THEN JPEG0.Message(result, message); Fail(name, message) END;
    image := PNG0.NewImage(jpg.width, jpg.height);
    FOR i := 0 TO LEN(jpg.pix^)-1 DO image.pix[i] := jpg.pix[i] END
  ELSE
    PNG0.Decode(reader, image, result);
    IF result # PNG0.ok THEN PNG0.Message(result, message); Fail(name, message) END
  END;
  Files.Close(file); RETURN image
END Load;

PROCEDURE Axis(index, sourceSize, targetSize: LONGINT; VAR low, high, fraction: LONGINT);
VAR position, last: HUGEINT;
BEGIN
  position := index;
  position := ((2 * position + 1) * sourceSize - targetSize) * 128 DIV targetSize;
  last := sourceSize; last := (last-1) * 256;
  IF position <= 0 THEN low := 0; high := 0; fraction := 0
  ELSIF position >= last THEN low := sourceSize-1; high := low; fraction := 0
  ELSE low := SHORT(position DIV 256); high := low+1; fraction := SHORT(position MOD 256)
  END
END Axis;

PROCEDURE Resize(image: PNG0.Image; width, height: LONGINT): PNG0.Image;
VAR result: PNG0.Image;
  x, y, x0, x1, y0, y1, fx, fy, a, b, c, d, target, channel, top, bottom: LONGINT;
BEGIN
  IF (width = image.width) & (height = image.height) THEN RETURN image END;
  result := PNG0.NewImage(width, height);
  IF result.pix = NIL THEN Fail(size, "image dimensions exceed the pixel limit") END;
  result.alpha := image.alpha;
  FOR y := 0 TO height-1 DO
    Axis(y, image.height, height, y0, y1, fy);
    FOR x := 0 TO width-1 DO
      Axis(x, image.width, width, x0, x1, fx);
      a := 4 * (y0 * image.width + x0); b := 4 * (y0 * image.width + x1);
      c := 4 * (y1 * image.width + x0); d := 4 * (y1 * image.width + x1);
      target := 4 * (y * width + x);
      FOR channel := 0 TO 3 DO
        top := (ORD(image.pix[a+channel]) * (256-fx) + ORD(image.pix[b+channel]) * fx + 128) DIV 256;
        bottom := (ORD(image.pix[c+channel]) * (256-fx) + ORD(image.pix[d+channel]) * fx + 128) DIV 256;
        result.pix[target+channel] := CHR((top * (256-fy) + bottom * fy + 128) DIV 256)
      END
    END
  END;
  RETURN result
END Resize;

PROCEDURE Dimension(text: ARRAY OF CHAR; VAR index: LONGINT): LONGINT;
VAR value, digit, start: LONGINT;
BEGIN
  value := 0; start := index;
  WHILE (text[index] >= "0") & (text[index] <= "9") DO
    digit := ORD(text[index])-ORD("0");
    IF value > (PNG0.MaxPixels-digit) DIV 10 THEN Fail(text, "dimension exceeds the pixel limit") END;
    value := value*10 + digit; INC(index)
  END;
  IF (index = start) OR (value = 0) THEN Fail(text, "dimensions must be positive integers") END;
  RETURN value
END Dimension;

PROCEDURE Dimensions(text: ARRAY OF CHAR; VAR width, height: LONGINT);
VAR index: LONGINT;
BEGIN
  IF text = "native" THEN width := source.width; height := source.height
  ELSIF text = "1080p" THEN width := 1920; height := 1080
  ELSIF text = "4K" THEN width := 3840; height := 2160
  ELSE
    index := 0; width := Dimension(text, index);
    IF text[index] # "x" THEN Fail(text, "expected native, 1080p, 4K or WIDTHxHEIGHT") END;
    INC(index); height := Dimension(text, index);
    IF text[index] # 0X THEN Fail(text, "unexpected characters after dimensions") END
  END;
  IF width > PNG0.MaxPixels DIV height THEN Fail(text, "image dimensions exceed the pixel limit") END
END Dimensions;

PROCEDURE Save(name: ARRAY OF CHAR; image: PNG0.Image);
VAR file: Files.File; writer: Files.Rider;
BEGIN
  IF Strings.Length(directory) + Strings.Length(name) + 7 > LEN(path) THEN
    Fail(directory, "output path is too long")
  END;
  COPY(directory, path); Strings.Append("/", path); Strings.Append(name, path); Strings.Append(".rgba", path);
  file := Files.New(path);
  IF file = NIL THEN Fail(path, "cannot create output") END;
  Files.Set(writer, file, 0); Files.WriteBytes(writer, image.pix^, LEN(image.pix^));
  IF writer.res # 0 THEN Fail(path, "cannot write output") END;
  Files.Register(file); Files.Close(file)
END Save;

BEGIN
  Args.Get(1, input); Args.Get(2, lutName); Args.Get(3, directory);
  IF (input = "") OR (lutName = "") OR (directory = "") THEN
    Out.String("usage: HaldPrepare input.jpg|png lut.png output-directory [native|1080p|4K|WIDTHxHEIGHT ...]");
    Out.Ln; HALT(1)
  END;
  source := Load(input); lut := Load(lutName); range := HaldClut.CubeRange(lut.width, lut.height);
  IF range = 0 THEN Fail(lutName, "pixel count must be a colour cube of range 2 or larger") END;
  Save("lut", lut); Out.String("cube "); Out.Int(range, 0); Out.Ln;
  Out.String("preparation oberon-bilinear256-v1"); Out.Ln;
  argument := 4; Args.Get(argument, size);
  IF size = "" THEN size := "native" END;
  WHILE size # "" DO
    Dimensions(size, width, height); pixels := Resize(source, width, height); Save(size, pixels);
    Out.String("image "); Out.String(size); Out.Char(" "); Out.Int(width, 0);
    Out.Char(" "); Out.Int(height, 0); Out.Ln;
    INC(argument); size := ""; Args.Get(argument, size)
  END
END HaldPrepare.
