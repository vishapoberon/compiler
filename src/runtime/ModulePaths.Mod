MODULE ModulePaths;

  (* Shared-module filenames and search paths; no native loader calls. *)
  IMPORT Platform, Heap;

  TYPE Visitor* = PROCEDURE(name: ARRAY OF CHAR);

  PROCEDURE Length*(s: ARRAY OF CHAR): LONGINT;
    VAR n: LONGINT;
  BEGIN
    n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END;
    RETURN n
  END Length;

  PROCEDURE Append*(s: ARRAY OF CHAR; VAR target: ARRAY OF CHAR): BOOLEAN;
    VAR i, n, count: LONGINT;
  BEGIN
    n := Length(target); count := Length(s);
    IF (count = LEN(s)) OR (n + count >= LEN(target)) THEN RETURN FALSE END;
    FOR i := 0 TO count DO target[n + i] := s[i] END;
    RETURN TRUE
  END Append;

  PROCEDURE Identifier*(name: ARRAY OF CHAR): BOOLEAN;
    VAR i: LONGINT; ch: CHAR;
  BEGIN
    IF LEN(name) = 0 THEN RETURN FALSE END;
    ch := name[0];
    IF ~(((ch >= "A") & (ch <= "Z")) OR ((ch >= "a") & (ch <= "z"))) THEN RETURN FALSE END;
    i := 1;
    WHILE (i < LEN(name)) & (name[i] # 0X) DO
      ch := name[i];
      IF ~(((ch >= "A") & (ch <= "Z")) OR ((ch >= "a") & (ch <= "z")) OR
          ((ch >= "0") & (ch <= "9")) OR (ch = "_")) THEN RETURN FALSE END;
      INC(i)
    END;
    RETURN (i < LEN(name)) & (i < SIZE(Heap.ModuleName))
  END Identifier;

  (* -1 marks an exhausted cursor; empty components denote the current directory.
     Components that do not fit in directory are skipped. *)
  PROCEDURE Directory*(search: ARRAY OF CHAR; VAR cursor: LONGINT;
                       VAR directory: ARRAY OF CHAR): BOOLEAN;
    VAR start, n, i: LONGINT;
  BEGIN
    WHILE (cursor >= 0) & (cursor < LEN(search)) DO
      start := cursor;
      WHILE (cursor < LEN(search)) & (search[cursor] # 0X) & (search[cursor] # ":") DO INC(cursor) END;
      n := cursor - start;
      IF (cursor = LEN(search)) OR (search[cursor] = 0X) THEN cursor := -1 ELSE INC(cursor) END;
      IF (n < LEN(directory)) & (n > 0) THEN
        FOR i := 0 TO n - 1 DO directory[i] := search[start + i] END;
        directory[n] := 0X; RETURN TRUE
      ELSIF (n = 0) & (LEN(directory) > 1) THEN COPY(".", directory); RETURN TRUE
      END
    END;
    RETURN FALSE
  END Directory;

  PROCEDURE Library*(directory, name, model: ARRAY OF CHAR;
                     VAR file: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    file[0] := 0X;
    RETURN Append(directory, file) & Append("/libvoc-", file) &
      Append(name, file) & Append("-", file) & Append(model, file) & Append(".so", file)
  END Library;

  PROCEDURE SymbolPath*(model, root: ARRAY OF CHAR; VAR search: ARRAY OF CHAR);
    VAR base: ARRAY 4096 OF CHAR; valid: BOOLEAN;
  BEGIN
    IF Platform.getEnv("VOC_SYM_PATH", search) THEN RETURN END;
    IF ~Platform.getEnv("VOCROOT", base) THEN COPY(root, base) END;
    search[0] := 0X;
    valid := Append(base, search) & Append("/modular/", search);
    IF model = "O2" THEN valid := valid & Append("2", search)
    ELSIF model = "OC" THEN valid := valid & Append("C", search)
    ELSE valid := valid & Append("V", search)
    END;
    IF ~valid OR ~Append("/sym", search) THEN search[0] := 0X END
  END SymbolPath;

  PROCEDURE Readable(file: ARRAY OF CHAR): BOOLEAN;
    VAR handle: Platform.FileHandle; error: Platform.ErrorCode;
  BEGIN
    IF Platform.OldRO(file, handle) # 0 THEN RETURN FALSE END;
    error := Platform.Close(handle); RETURN error = 0
  END Readable;

  PROCEDURE FindSymbol*(name, search, symbols: ARRAY OF CHAR;
                        VAR file: ARRAY OF CHAR): BOOLEAN;
    VAR directory: ARRAY 4096 OF CHAR; cursor: LONGINT; pass: INTEGER; valid: BOOLEAN;
  BEGIN
    IF ~Identifier(name) THEN RETURN FALSE END;
    FOR pass := 0 TO 1 DO
      cursor := 0;
      LOOP
        IF pass = 0 THEN valid := Directory(search, cursor, directory)
        ELSE valid := Directory(symbols, cursor, directory)
        END;
        IF ~valid THEN EXIT END;
        file[0] := 0X;
        IF Append(directory, file) & Append("/", file) & Append(name, file) &
            Append(".sym", file) & Readable(file) THEN RETURN TRUE END
      END
    END;
    RETURN FALSE
  END FindSymbol;

  PROCEDURE EnumerateDirectory(directory, model: ARRAY OF CHAR;
                               visit: Visitor; symbols: BOOLEAN);
    VAR handle: Platform.DirectoryHandle; entry: ARRAY 4096 OF CHAR;
      name: Heap.ModuleName; suffix: ARRAY 32 OF CHAR; head: ARRAY 8 OF CHAR;
      n, prefix, tail, i: LONGINT; done, valid: BOOLEAN; error: Platform.ErrorCode;
  BEGIN
    IF Platform.OpenDirectory(directory, handle) # 0 THEN RETURN END;
    IF symbols THEN suffix := ".sym"; prefix := 0
    ELSE suffix := "-"; valid := Append(model, suffix) & Append(".so", suffix); prefix := 7
    END;
    tail := Length(suffix); head := "libvoc-";
    LOOP
      error := Platform.ReadDirectory(handle, entry, done);
      IF (error # 0) OR done THEN EXIT END;
      n := Length(entry) - prefix - tail;
      IF (n > 0) & (n < LEN(name)) THEN
        valid := TRUE;
        IF ~symbols THEN
          i := 0;
          WHILE (i < prefix) & valid DO valid := entry[i] = head[i]; INC(i) END
        END;
        i := 0;
        WHILE (i < tail) & valid DO valid := entry[prefix + n + i] = suffix[i]; INC(i) END;
        IF valid THEN
          FOR i := 0 TO n - 1 DO name[i] := entry[prefix + i] END; name[n] := 0X;
          IF Identifier(name) & (symbols OR (name # "core")) THEN visit(name) END
        END
      END
    END;
    error := Platform.CloseDirectory(handle)
  END EnumerateDirectory;

  PROCEDURE Enumerate*(search, symbols, model: ARRAY OF CHAR; visit: Visitor);
    VAR directory: ARRAY 4096 OF CHAR; cursor: LONGINT;
  BEGIN
    cursor := 0;
    WHILE Directory(search, cursor, directory) DO
      EnumerateDirectory(directory, model, visit, FALSE);
      EnumerateDirectory(directory, model, visit, TRUE)
    END;
    cursor := 0;
    WHILE Directory(symbols, cursor, directory) DO EnumerateDirectory(directory, model, visit, TRUE) END
  END Enumerate;

END ModulePaths.
