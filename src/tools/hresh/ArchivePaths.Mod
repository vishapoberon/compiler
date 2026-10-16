MODULE ArchivePaths;

IMPORT Platform, PlatformNative;

PROCEDURE SameFile*(a, b: ARRAY OF CHAR): BOOLEAN;
VAR x, y: Platform.FileIdentity;
BEGIN
  IF a = b THEN RETURN TRUE END;
  RETURN (Platform.IdentifyByName(a, x) = 0) &
    (Platform.IdentifyByName(b, y) = 0) & Platform.SameFile(x, y)
END SameFile;

(* Archive entry names must stay below the current directory, on Unix or Windows. *)
PROCEDURE Safe*(name: ARRAY OF CHAR): BOOLEAN;
VAR i, start: LONGINT;
BEGIN
  IF (LEN(name) = 0) OR (name[0] = 0X) OR (name[0] = "/") THEN RETURN FALSE END;
  i := 0;
  LOOP
    start := i;
    WHILE (i < LEN(name)) & (name[i] # 0X) & (name[i] # "/") DO
      IF (name[i] = 5CX) OR (name[i] = ":") OR (name[i] < " ") THEN RETURN FALSE END;
      INC(i)
    END;
    IF (i = LEN(name)) OR (i = start) THEN RETURN FALSE END;
    IF (name[start] = ".") & ((i - start = 1) OR
        ((i - start = 2) & (name[start + 1] = "."))) THEN RETURN FALSE END;
    IF name[i] = 0X THEN RETURN TRUE END;
    INC(i);
    IF (i < LEN(name)) & (name[i] = 0X) THEN RETURN TRUE END
  END
END Safe;

PROCEDURE Prepare*(name: ARRAY OF CHAR; directory: BOOLEAN): BOOLEAN;
VAR path: ARRAY 256 OF CHAR; i, n: LONGINT; kind: INTEGER; error: Platform.ErrorCode;
BEGIN
  IF ~Safe(name) THEN RETURN FALSE END;
  n := 0; WHILE (n < LEN(name)) & (name[n] # 0X) DO INC(n) END;
  IF (n = 0) OR (n >= LEN(path)) THEN RETURN FALSE END;
  COPY(name, path);
  IF path[n - 1] = "/" THEN DEC(n); path[n] := 0X; directory := TRUE END;
  (* Do not follow existing symlinks. Extraction assumes other processes do
     not replace checked components; the command host is not a sandbox. *)
  FOR i := 0 TO n DO
    IF (i = n) OR (path[i] = "/") THEN
      path[i] := 0X;
      error := SHORT(PlatformNative.PathKind(path, FALSE, kind));
      IF (i < n) OR directory THEN
        IF error = 0 THEN
          IF kind # 1 THEN RETURN FALSE END
        ELSIF ~Platform.Absent(error) OR (PlatformNative.MakeDirectory(path) # 0) THEN RETURN FALSE
        END
      ELSIF error = 0 THEN
        IF kind # 2 THEN RETURN FALSE END
      ELSIF ~Platform.Absent(error) THEN RETURN FALSE
      END;
      IF i < n THEN path[i] := "/" END
    END
  END;
  RETURN TRUE
END Prepare;

END ArchivePaths.
