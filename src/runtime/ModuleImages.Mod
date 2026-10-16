MODULE ModuleImages;

  (* Inspect the public ELF format in an already mapped native image.
     These offsets are ELF32/ELF64 format offsets, not libc structure layouts. *)
  IMPORT SYSTEM, Platform;

  PROCEDURE Byte(address: SYSTEM.ADDRESS): LONGINT;
    VAR ch: CHAR;
  BEGIN SYSTEM.GET(address, ch); RETURN ORD(ch) END Byte;

  PROCEDURE Word(address: SYSTEM.ADDRESS; bytes: INTEGER): SYSTEM.ADDRESS;
    VAR i: INTEGER; value: SYSTEM.ADDRESS;
  BEGIN
    value := 0;
    IF Platform.LittleEndian THEN
      FOR i := bytes - 1 TO 0 BY -1 DO value := ASH(value, 8) + Byte(address + i) END
    ELSE
      FOR i := 0 TO bytes - 1 DO value := ASH(value, 8) + Byte(address + i) END
    END;
    RETURN value
  END Word;

  PROCEDURE Segments(base: SYSTEM.ADDRESS; VAR table: SYSTEM.ADDRESS;
                     VAR count, stride: LONGINT): BOOLEAN;
    VAR offset: SYSTEM.ADDRESS; class: LONGINT;
  BEGIN
    IF base = 0 THEN RETURN FALSE END;
    IF (Byte(base) # 7FH) OR (Byte(base + 1) # ORD("E")) OR
        (Byte(base + 2) # ORD("L")) OR (Byte(base + 3) # ORD("F")) THEN RETURN FALSE END;
    class := Byte(base + 4);
    IF Platform.LittleEndian THEN
      IF Byte(base + 5) # 1 THEN RETURN FALSE END
    ELSIF Byte(base + 5) # 2 THEN RETURN FALSE
    END;
    IF (class = 2) & (SIZE(SYSTEM.ADDRESS) = 8) THEN
      offset := Word(base + 32, 8); stride := SHORT(Word(base + 54, 2)); count := SHORT(Word(base + 56, 2));
      IF stride # 56 THEN RETURN FALSE END
    ELSIF (class = 1) & (SIZE(SYSTEM.ADDRESS) = 4) THEN
      offset := Word(base + 28, 4); stride := SHORT(Word(base + 42, 2)); count := SHORT(Word(base + 44, 2));
      IF stride # 32 THEN RETURN FALSE END
    ELSE RETURN FALSE
    END;
    IF (offset <= 0) OR (count = 0) THEN RETURN FALSE END;
    table := base + offset; RETURN TRUE
  END Segments;

  PROCEDURE Executable*(base: SYSTEM.ADDRESS): BOOLEAN;
    VAR table: SYSTEM.ADDRESS; count, stride, i: LONGINT;
  BEGIN
    IF ~Segments(base, table, count, stride) THEN RETURN FALSE END;
    FOR i := 0 TO count - 1 DO
      IF Word(table + i * stride, 4) = 3 THEN RETURN TRUE END (* PT_INTERP *)
    END;
    RETURN FALSE
  END Executable;

  PROCEDURE Unloadable*(base: SYSTEM.ADDRESS; VAR error: ARRAY OF CHAR): BOOLEAN;
    VAR table, segment, dynamic, size, cursor, tag, flags: SYSTEM.ADDRESS;
      count, stride, i: LONGINT; width: INTEGER;
  BEGIN
    IF ~Segments(base, table, count, stride) THEN
      COPY("cannot inspect native module ownership", error); RETURN FALSE
    END;
    width := SIZE(SYSTEM.ADDRESS);
    FOR i := 0 TO count - 1 DO
      segment := table + i * stride;
      IF Word(segment, 4) = 2 THEN (* PT_DYNAMIC *)
        IF width = 8 THEN dynamic := base + Word(segment + 16, 8); size := Word(segment + 40, 8)
        ELSE dynamic := base + Word(segment + 8, 4); size := Word(segment + 20, 4)
        END;
        cursor := 0;
        LOOP
          IF cursor + 2 * width > size THEN EXIT END;
          tag := Word(dynamic + cursor, width);
          IF tag = 0 THEN EXIT END; (* DT_NULL *)
          flags := Word(dynamic + cursor + width, width);
          IF (tag = 6FFFFFFBH) & ODD(flags DIV 8) THEN (* DT_FLAGS_1 / DF_1_NODELETE *)
            COPY("native library is marked NODELETE", error); RETURN FALSE
          END;
          INC(cursor, 2 * width)
        END
      END
    END;
    RETURN TRUE
  END Unloadable;

END ModuleImages.
