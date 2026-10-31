MODULE PictureMemoryTest;

(* Memory-only picture I/O and bounded codec entry points. *)

IMPORT Files, PNG0, JPEG0, GIF0, Heap, Out, Args;

VAR checks: LONGINT; phase: ARRAY 256 OF CHAR;

PROCEDURE Check(value: BOOLEAN);
BEGIN
  INC(checks);
  IF ~value THEN
    Out.String("FAIL PictureMemoryTest: "); Out.String(phase); Out.String(" check "); Out.Int(checks, 0); Out.Ln;
    HALT(1)
  END
END Check;

PROCEDURE Equal(a, b: ARRAY OF CHAR; length: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN
  IF (length < 0) OR (length > LEN(a)) OR (length > LEN(b)) THEN RETURN FALSE END;
  FOR i := 0 TO length - 1 DO IF a[i] # b[i] THEN RETURN FALSE END END;
  RETURN TRUE
END Equal;

PROCEDURE Fill(VAR bytes: ARRAY OF CHAR);
VAR i, seed: LONGINT;
BEGIN
  seed := 1;
  FOR i := 0 TO LEN(bytes) - 1 DO seed := (seed * 75 + 74) MOD 65537; bytes[i] := CHR(seed MOD 256) END
END Fill;

PROCEDURE MemoryFiles;
VAR f, other: Files.File; r, s: Files.Rider; src, dst, bytes: Files.Bytes;
  i, n, t, d, descriptors: LONGINT; c: CHAR; name: ARRAY 256 OF CHAR; chunk: ARRAY 4 OF CHAR;
  flag: BOOLEAN; short: INTEGER; number: LONGINT; real: REAL; set: SET;
BEGIN
  phase := "memory file boundaries"; descriptors := Heap.FileCount;
  Check(Files.NewMemory(-1) = NIL); Check(Files.FromBytes("abc", -1) = NIL);
  Check(Files.FromBytes("abc", 5) = NIL);
  f := Files.NewMemory(0); Check(Files.IsMemory(f) & ~Files.MemoryFailed(f));
  bytes := Files.MemoryData(f, n); Check((bytes # NIL) & (n = 0));
  Files.Set(r, f, 0); Files.Read(r, c); Check(r.eof & (c = 0X));
  Files.Write(r, "x"); Check((r.res = 1) & Files.MemoryFailed(f) & (Files.Length(f) = 0));
  Check(Files.MemoryData(f, n) = NIL); Check(n = 0);

  f := Files.NewMemory(4); Files.Set(r, f, 0); Files.Write(r, "a"); Files.Write(r, "b");
  chunk := "cde"; Files.WriteBytes(r, chunk, 3); Check((r.res = 3) & Files.MemoryFailed(f) & (Files.Length(f) = 2));
  Files.Set(r, f, 0); Files.Write(r, "X"); Check((r.res = 1) & Files.MemoryFailed(f));
  Files.Set(r, f, 0); Files.Read(r, c); Check(c = "a");
  Files.Purge(f); Check(~Files.MemoryFailed(f) & (Files.Length(f) = 0));
  Files.Write(r, "z"); Check((r.res = 0) & (Files.Length(f) = 1));
  bytes := Files.MemoryData(f, n); Check((n = 1) & (bytes[0] = "z"));

  NEW(src, 65537); NEW(dst, 65540); Fill(src^);
  f := Files.NewMemory(LEN(src^)); Files.Set(r, f, 0);
  FOR i := 0 TO LEN(src^) - 1 DO Files.Write(r, src[i]) END;
  Check((Files.Pos(r) = LEN(src^)) & (Files.Length(f) = LEN(src^)) & ~Files.MemoryFailed(f));
  Files.Set(s, f, 0); Files.ReadBytes(s, dst^, LEN(src^));
  Check((s.res = 0) & ~s.eof & Equal(src^, dst^, LEN(src^)));
  Files.Set(s, f, 4095); Files.Write(s, 0FFX); Files.Set(r, f, 4095); Files.Read(r, c); Check(c = 0FFX);
  Files.Set(s, f, 65535); Files.ReadBytes(s, dst^, 5);
  Check(s.eof & (s.res = 3) & (dst[0] = src[65535]) & (dst[1] = src[65536]));
  Files.Set(s, f, MAX(LONGINT)); Check(Files.Pos(s) = 65537);
  Files.Set(s, f, -1); Check(Files.Pos(s) = 0);
  Files.Close(f); Files.Register(f); Files.GetDate(f, t, d); Check((t = 0) & (d = 0));
  Files.GetName(f, name); Check(name = "");
  other := Files.FromBytes(src^, LEN(src^)); Check(Files.IsMemory(other));
  c := src[0]; src[0] := CHR((ORD(c) + 1) MOD 256);
  Files.Set(s, other, 0); Files.Read(s, src[0]); Check(src[0] = c);
  f := Files.NewMemory(LEN(src^)); Files.Set(r, f, 0); Files.WriteBytes(r, src^, LEN(src^));
  Files.Set(s, f, 0); Files.ReadBytes(s, dst^, LEN(src^)); Check(Equal(src^, dst^, LEN(src^)));
  f := Files.NewMemory(1024); Files.Set(r, f, 0);
  Files.WriteBool(r, TRUE); Files.WriteInt(r, -12345); Files.WriteLInt(r, -123456789);
  Files.WriteReal(r, 1.5); Files.WriteSet(r, {0, 7, 31}); Files.WriteString(r, "memory");
  Check(~Files.MemoryFailed(f)); Files.Set(s, f, 0);
  Files.ReadBool(s, flag); Check(flag); Files.ReadInt(s, short); Check(short = -12345);
  Files.ReadLInt(s, number); Check(number = -123456789); Files.ReadReal(s, real); Check(real = 1.5);
  Files.ReadSet(s, set); Check(set = {0, 7, 31}); Files.ReadString(s, name); Check(name = "memory");
  f := Files.NewMemory(2); Files.Set(r, f, 0); Files.WriteLInt(r, 1234);
  Check(Files.MemoryFailed(f) & (Files.Length(f) = 0));
  Check(Heap.FileCount = descriptors)
END MemoryFiles;

PROCEDURE PNG;
VAR img, decoded, riderImage, bad: PNG0.Image; info: PNG0.Info; data, copy, encoded: Files.Bytes;
  f: Files.File; r: Files.Rider; n, m, res, i: LONGINT; saved: ARRAY 4 OF CHAR;
BEGIN
  phase := "PNG memory round trips and alpha";
  img := PNG0.NewImage(256, 192); img.alpha := TRUE; Fill(img.pix^);
  img.pix[3] := 0X; img.pix[7] := 80X; img.pix[11] := 0FFX;
  PNG0.EncodeBytes(img, 6, 524288, data, n, res); Check((res = PNG0.ok) & (n > 16384) & (data # NIL));
  PNG0.ReadInfoBytes(data^, n, info, res); Check((res = PNG0.ok) & (info.width = 256) & (info.height = 192) & (info.colorType = 6));
  PNG0.DecodeBytes(data^, n, 256 * 192, decoded, res); Check((res = PNG0.ok) & (decoded # NIL) & decoded.alpha);
  Check(Equal(img.pix^, decoded.pix^, 256 * 192 * 4));
  f := Files.FromBytes(data^, n); Files.Set(r, f, 0); PNG0.Decode(r, riderImage, res);
  Check((res = PNG0.ok) & Equal(decoded.pix^, riderImage.pix^, 256 * 192 * 4));
  f := Files.NewMemory(524288); Files.Set(r, f, 0); PNG0.Encode(r, img, 6, res); copy := Files.MemoryData(f, m);
  Check((res = PNG0.ok) & (m = n) & Equal(data^, copy^, n));

  phase := "PNG limits and malformed buffers";
  PNG0.DecodeBytes(data^, n, 256 * 192 - 1, decoded, res); Check((res = PNG0.tooLarge) & (decoded = NIL));
  PNG0.DecodeBytes(data^, n, 0, decoded, res); Check((res = PNG0.tooLarge) & (decoded = NIL));
  PNG0.DecodeBytes(data^, n, PNG0.MaxPixels + 1, decoded, res); Check((res = PNG0.tooLarge) & (decoded = NIL));
  PNG0.DecodeBytes(data^, -1, PNG0.MaxPixels, decoded, res); Check((res = PNG0.badFormat) & (decoded = NIL));
  PNG0.DecodeBytes(data^, LEN(data^) + 1, PNG0.MaxPixels, decoded, res); Check((res = PNG0.badFormat) & (decoded = NIL));
  PNG0.DecodeBytes(data^, 5, PNG0.MaxPixels, decoded, res); Check((res # PNG0.ok) & (decoded = NIL));
  PNG0.EncodeBytes(img, 6, n - 1, encoded, m, res); Check((res = PNG0.tooLarge) & (encoded = NIL) & (m = 0));
  PNG0.EncodeBytes(img, 6, n, encoded, m, res); Check((res = PNG0.ok) & (m = n) & Equal(data^, encoded^, n));
  PNG0.EncodeBytes(img, 6, 0, encoded, m, res); Check((res = PNG0.tooLarge) & (encoded = NIL) & (m = 0));
  data[n - 1] := CHR((ORD(data[n - 1]) + 1) MOD 256);
  PNG0.DecodeBytes(data^, n, PNG0.MaxPixels, decoded, res); Check((res = PNG0.badCRC) & (decoded = NIL));
  FOR i := 0 TO 3 DO saved[i] := data[33 + i] END;
  data[33] := 7FX; data[34] := 0FFX; data[35] := 0FFX; data[36] := 0E0X;
  PNG0.DecodeBytes(data^, n, PNG0.MaxPixels, decoded, res); Check((res = PNG0.badFormat) & (decoded = NIL));
  FOR i := 0 TO 3 DO data[33 + i] := saved[i] END;
  NEW(bad); bad.width := 2; bad.height := 2; NEW(bad.pix, 3);
  PNG0.EncodeBytes(bad, 6, 4096, encoded, m, res); Check((res = PNG0.noImage) & (encoded = NIL) & (m = 0));
  bad.width := MAX(LONGINT); bad.height := MAX(LONGINT);
  PNG0.EncodeBytes(bad, 6, 4096, encoded, m, res); Check((res = PNG0.tooLarge) & (encoded = NIL) & (m = 0))
END PNG;

PROCEDURE JPEG;
VAR img, decoded, riderImage, bad: JPEG0.Image; info: JPEG0.Info; data, copy, encoded: Files.Bytes;
  f: Files.File; r: Files.Rider; n, m, res: LONGINT;
BEGIN
  phase := "JPEG memory round trips";
  img := JPEG0.NewImage(160, 160); Fill(img.pix^);
  JPEG0.EncodeBytes(img, 95, 524288, data, n, res); Check((res = JPEG0.ok) & (n > 16384) & (data # NIL));
  JPEG0.ReadInfoBytes(data^, n, info, res); Check((res = JPEG0.ok) & (info.width = 160) & (info.height = 160));
  JPEG0.DecodeBytes(data^, n, 160 * 160, decoded, res); Check((res = JPEG0.ok) & (decoded # NIL));
  f := Files.FromBytes(data^, n); Files.Set(r, f, 0); JPEG0.Decode(r, riderImage, res);
  Check((res = JPEG0.ok) & Equal(decoded.pix^, riderImage.pix^, 160 * 160 * 4));
  f := Files.NewMemory(524288); Files.Set(r, f, 0); JPEG0.Encode(r, img, 95, res); copy := Files.MemoryData(f, m);
  Check((res = JPEG0.ok) & (m = n) & Equal(data^, copy^, n));

  phase := "JPEG limits and malformed buffers";
  JPEG0.DecodeBytes(data^, n, 160 * 160 - 1, decoded, res); Check((res = JPEG0.tooLarge) & (decoded = NIL));
  JPEG0.DecodeBytes(data^, n, 0, decoded, res); Check((res = JPEG0.tooLarge) & (decoded = NIL));
  JPEG0.DecodeBytes(data^, -1, JPEG0.MaxPixels, decoded, res); Check((res = JPEG0.badFormat) & (decoded = NIL));
  JPEG0.DecodeBytes(data^, LEN(data^) + 1, JPEG0.MaxPixels, decoded, res); Check((res = JPEG0.badFormat) & (decoded = NIL));
  JPEG0.DecodeBytes(data^, 5, JPEG0.MaxPixels, decoded, res); Check((res # JPEG0.ok) & (decoded = NIL));
  JPEG0.EncodeBytes(img, 95, n - 1, encoded, m, res); Check((res = JPEG0.tooLarge) & (encoded = NIL) & (m = 0));
  JPEG0.EncodeBytes(img, 95, n, encoded, m, res); Check((res = JPEG0.ok) & (m = n) & Equal(data^, encoded^, n));
  JPEG0.EncodeBytes(img, 95, -1, encoded, m, res); Check((res = JPEG0.tooLarge) & (encoded = NIL) & (m = 0));
  NEW(bad); bad.width := 2; bad.height := 2; NEW(bad.pix, 3);
  JPEG0.EncodeBytes(bad, 95, 4096, encoded, m, res); Check((res = JPEG0.noImage) & (encoded = NIL) & (m = 0));
  bad.width := 65535; bad.height := 65535;
  JPEG0.EncodeBytes(bad, 95, 4096, encoded, m, res); Check((res = JPEG0.tooLarge) & (encoded = NIL) & (m = 0))
END JPEG;

PROCEDURE GIF;
VAR img, decoded, riderImage, bad: GIF0.Image; info: GIF0.Info; data, copy, encoded: Files.Bytes;
  f: Files.File; r: Files.Rider; n, m, res, at, i, colors: LONGINT;
BEGIN
  phase := "GIF memory round trips and transparency";
  img := GIF0.NewImage(8, 8); Fill(img.pix^); img.alpha := TRUE;
  img.pix[3] := 0X; img.pix[7] := 0FFX;
  GIF0.EncodeBytes(img, 65536, data, n, res); Check((res = GIF0.ok) & (n > 0) & (data # NIL));
  GIF0.ReadInfoBytes(data^, n, info, res); Check((res = GIF0.ok) & (info.width = 8) & (info.height = 8) & (info.images = 1));
  GIF0.DecodeBytes(data^, n, 64, decoded, res); Check((res = GIF0.ok) & (decoded # NIL) & decoded.alpha);
  Check((decoded.pix[3] = 0X) & (decoded.pix[7] = 0FFX));
  f := Files.FromBytes(data^, n); Files.Set(r, f, 0); GIF0.Decode(r, riderImage, res);
  Check((res = GIF0.ok) & Equal(decoded.pix^, riderImage.pix^, 8 * 8 * 4));
  f := Files.NewMemory(65536); Files.Set(r, f, 0); GIF0.Encode(r, img, res); copy := Files.MemoryData(f, m);
  Check((res = GIF0.ok) & (m = n) & Equal(data^, copy^, n));

  phase := "GIF limits and malformed buffers";
  GIF0.DecodeBytes(data^, n, 63, decoded, res); Check((res = GIF0.tooLarge) & (decoded = NIL));
  GIF0.DecodeBytes(data^, n, 0, decoded, res); Check((res = GIF0.tooLarge) & (decoded = NIL));
  GIF0.DecodeBytes(data^, -1, GIF0.MaxPixels, decoded, res); Check((res = GIF0.badFormat) & (decoded = NIL));
  GIF0.DecodeBytes(data^, LEN(data^) + 1, GIF0.MaxPixels, decoded, res); Check((res = GIF0.badFormat) & (decoded = NIL));
  GIF0.DecodeBytes(data^, 5, GIF0.MaxPixels, decoded, res); Check((res # GIF0.ok) & (decoded = NIL));
  GIF0.EncodeBytes(img, n - 1, encoded, m, res); Check((res = GIF0.tooLarge) & (encoded = NIL) & (m = 0));
  GIF0.EncodeBytes(img, n, encoded, m, res); Check((res = GIF0.ok) & (m = n) & Equal(data^, encoded^, n));
  GIF0.EncodeBytes(img, 0, encoded, m, res); Check((res = GIF0.tooLarge) & (encoded = NIL) & (m = 0));
  colors := 2; FOR i := 1 TO ORD(data[10]) MOD 8 DO colors := colors * 2 END;
  at := 13 + colors * 3;
  IF data[at] = 21X THEN INC(at, 8) END;
  Check(data[at] = 2CX);
  data[6] := 1X; data[7] := 0X; data[8] := 1X; data[9] := 0X;
  data[at + 1] := 64X; data[at + 2] := 0X;
  GIF0.DecodeBytes(data^, n, 64, decoded, res); Check((res = GIF0.tooLarge) & (decoded = NIL));
  NEW(bad); bad.width := 2; bad.height := 2; NEW(bad.pix, 3);
  GIF0.EncodeBytes(bad, 4096, encoded, m, res); Check((res = GIF0.noImage) & (encoded = NIL) & (m = 0));
  bad.width := 65535; bad.height := 65535;
  GIF0.EncodeBytes(bad, 4096, encoded, m, res); Check((res = GIF0.tooLarge) & (encoded = NIL) & (m = 0))
END GIF;

PROCEDURE Run*;
VAR descriptors: LONGINT;
BEGIN
  checks := 0; descriptors := Heap.FileCount;
  MemoryFiles; PNG; JPEG; GIF; Heap.GC(TRUE);
  phase := "memory-only resource ownership"; Check(Heap.FileCount = descriptors);
  Out.String("PictureMemoryTest: "); Out.Int(checks, 0); Out.String(" checks, 0 failed"); Out.Ln
END Run;

PROCEDURE Load(name: ARRAY OF CHAR; VAR data: Files.Bytes; VAR length: LONGINT): Files.File;
VAR f: Files.File; r: Files.Rider;
BEGIN
  f := Files.Old(name); Check(f # NIL); length := Files.Length(f);
  Check((length >= 0) & (length <= 16777216));
  IF length = 0 THEN NEW(data, 1) ELSE NEW(data, length) END;
  Files.Set(r, f, 0); Files.ReadBytes(r, data^, length); Check(r.res = 0);
  RETURN f
END Load;

PROCEDURE Fixture(kind, name: ARRAY OF CHAR);
VAR f: Files.File; r: Files.Rider; data: Files.Bytes; length, a, b: LONGINT;
  p, pc: PNG0.Image; j, jc: JPEG0.Image; g, gc: GIF0.Image;
  pi, pic: PNG0.Info; ji, jic: JPEG0.Info; gi, gic: GIF0.Info;
BEGIN
  COPY(name, phase); f := Load(name, data, length); Files.Set(r, f, 0);
  IF kind = "png" THEN
    PNG0.ReadInfo(r, pi, a); PNG0.ReadInfoBytes(data^, length, pic, b); Check(a = b);
    IF a = PNG0.ok THEN
      Check((pi.width = pic.width) & (pi.height = pic.height) & (pi.depth = pic.depth) &
        (pi.colorType = pic.colorType) & (pi.interlaced = pic.interlaced))
    END;
    Files.Set(r, f, 0); PNG0.Decode(r, p, a); PNG0.DecodeBytes(data^, length, PNG0.MaxPixels, pc, b); Check(a = b);
    IF a = PNG0.ok THEN
      Check((pc # NIL) & (p.width = pc.width) & (p.height = pc.height) & (p.alpha = pc.alpha));
      Check(Equal(p.pix^, pc.pix^, p.width * p.height * 4))
    ELSE Check(pc = NIL)
    END
  ELSIF kind = "jpeg" THEN
    JPEG0.ReadInfo(r, ji, a); JPEG0.ReadInfoBytes(data^, length, jic, b); Check(a = b);
    IF a = JPEG0.ok THEN
      Check((ji.width = jic.width) & (ji.height = jic.height) & (ji.components = jic.components) & (ji.progressive = jic.progressive))
    END;
    Files.Set(r, f, 0); JPEG0.Decode(r, j, a); JPEG0.DecodeBytes(data^, length, JPEG0.MaxPixels, jc, b); Check(a = b);
    IF a = JPEG0.ok THEN
      Check((jc # NIL) & (j.width = jc.width) & (j.height = jc.height));
      Check(Equal(j.pix^, jc.pix^, j.width * j.height * 4))
    ELSE Check(jc = NIL)
    END
  ELSE
    Check(kind = "gif"); GIF0.ReadInfo(r, gi, a); GIF0.ReadInfoBytes(data^, length, gic, b); Check(a = b);
    IF a = GIF0.ok THEN
      Check((gi.width = gic.width) & (gi.height = gic.height) & (gi.colors = gic.colors) &
        (gi.images = gic.images) & (gi.interlaced = gic.interlaced) & (gi.transparent = gic.transparent))
    END;
    Files.Set(r, f, 0); GIF0.Decode(r, g, a); GIF0.DecodeBytes(data^, length, GIF0.MaxPixels, gc, b); Check(a = b);
    IF a = GIF0.ok THEN
      Check((gc # NIL) & (g.width = gc.width) & (g.height = gc.height) & (g.alpha = gc.alpha));
      Check(Equal(g.pix^, gc.pix^, g.width * g.height * 4))
    ELSE Check(gc = NIL)
    END
  END;
  Files.Close(f)
END Fixture;

(* Compare the new byte-array API with the rider API on every preserved input. *)
PROCEDURE RunFixtures*;
VAR f: Files.File; r: Files.Rider; kind, list, line, name: ARRAY 256 OF CHAR; i: LONGINT;
BEGIN
  checks := 0; phase := "fixture arguments";
  Args.Get(1, kind); Args.Get(2, list); f := Files.Old(list); Check(f # NIL); Files.Set(r, f, 0);
  WHILE ~r.eof DO
    Files.ReadLine(r, line); i := 0;
    WHILE (line[i] # 0X) & (line[i] > " ") & (i < LEN(name) - 1) DO name[i] := line[i]; INC(i) END;
    name[i] := 0X;
    IF (i > 0) & (name[0] # "#") THEN Fixture(kind, name) END
  END;
  Files.Close(f);
  Out.String("PictureMemoryFixtures "); Out.String(kind); Out.String(": "); Out.Int(checks, 0); Out.String(" checks, 0 failed"); Out.Ln
END RunFixtures;

PROCEDURE RunFiles*;
VAR f, old: Files.File; r: Files.Rider; data, copy: Files.Bytes; res: INTEGER; i: LONGINT;
BEGIN
  checks := 0; phase := "ordinary file compatibility"; NEW(data, 65537); NEW(copy, 65537); Fill(data^);
  f := Files.New("picture-file-compatibility.bin"); Check(~Files.IsMemory(f)); Files.Set(r, f, 0);
  Files.WriteBytes(r, data^, LEN(data^)); Files.Register(f); Files.Close(f);
  Check((r.res = 0) & (Files.Length(f) = LEN(data^)));
  old := Files.Old("picture-file-compatibility.bin"); Check(old # NIL); Files.Set(r, old, 0);
  Files.ReadBytes(r, copy^, LEN(copy^)); Check((r.res = 0) & Equal(data^, copy^, LEN(data^)));
  Files.Set(r, old, 4095); Files.Write(r, 0FFX); Files.Close(old); Files.Set(r, old, 4095);
  Files.Read(r, copy[0]); Check(copy[0] = 0FFX);
  Files.Purge(old); Check(Files.Length(old) = 0); Files.Set(r, old, 0);
  FOR i := 0 TO 255 DO Files.Write(r, CHR(i)) END; Files.Close(old); Files.Set(r, old, 0);
  FOR i := 0 TO 255 DO Files.Read(r, copy[i]); Check(copy[i] = CHR(i)) END;
  Files.Delete("picture-file-compatibility.bin", res);
  Check(Files.Old("picture-file-compatibility.bin") = NIL);
  Out.String("PictureFileCompatibility: "); Out.Int(checks, 0); Out.String(" checks, 0 failed"); Out.Ln
END RunFiles;

END PictureMemoryTest.
