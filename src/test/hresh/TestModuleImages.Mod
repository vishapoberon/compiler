MODULE TestModuleImages;
  IMPORT SYSTEM, Platform, ModuleImages, Out;
  VAR image: ARRAY 1024 OF CHAR; base, segment, dynamic: SYSTEM.ADDRESS;
    error: ARRAY 256 OF CHAR; i, width: INTEGER;

  PROCEDURE Write(offset, value: SYSTEM.ADDRESS; bytes: INTEGER);
    VAR i, index: INTEGER;
  BEGIN
    FOR i := 0 TO bytes - 1 DO
      IF Platform.LittleEndian THEN index := i ELSE index := bytes - 1 - i END;
      SYSTEM.PUT(base + offset + index, CHR(value MOD 256)); value := value DIV 256
    END
  END Write;

BEGIN
  base := SYSTEM.ADR(image); width := SIZE(SYSTEM.ADDRESS);
  FOR i := 0 TO LEN(image) - 1 DO image[i] := 0X END;
  ASSERT(~ModuleImages.Executable(base)); ASSERT(~ModuleImages.Unloadable(base, error));
  image[0] := 7FX; image[1] := "E"; image[2] := "L"; image[3] := "F";
  IF Platform.LittleEndian THEN image[5] := 1X ELSE image[5] := 2X END;
  segment := 128; dynamic := 256;
  IF width = 8 THEN
    image[4] := 2X; Write(32, segment, 8); Write(54, 56, 2); Write(56, 1, 2);
    Write(segment + 16, dynamic, 8); Write(segment + 40, 32, 8)
  ELSE
    image[4] := 1X; Write(28, segment, 4); Write(42, 32, 2); Write(44, 1, 2);
    Write(segment + 8, dynamic, 4); Write(segment + 20, 16, 4)
  END;
  Write(segment, 3, 4); ASSERT(ModuleImages.Executable(base));
  Write(segment, 2, 4); ASSERT(~ModuleImages.Executable(base));
  ASSERT(ModuleImages.Unloadable(base, error));
  Write(dynamic, 6FFFFFFBH, width); Write(dynamic + width, 8, width);
  ASSERT(~ModuleImages.Unloadable(base, error)); ASSERT(error = "native library is marked NODELETE");
  Write(dynamic + width, 0, width); ASSERT(ModuleImages.Unloadable(base, error));
  image[5] := 0X; ASSERT(~ModuleImages.Unloadable(base, error));
  image[4] := 0X; ASSERT(~ModuleImages.Unloadable(base, error));
  Out.String("Oberon ELF image tests passed"); Out.Ln
END TestModuleImages.
