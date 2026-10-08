MODULE testDirectories;

  (* Portable Platform directory contract. Pass a fixture directory containing
     'child', 'file.txt' and a 'link' to child. No libc RECORD layout assumptions. *)
  IMPORT Platform, Modules, Out;

  VAR path, name, missing, file, child, link: ARRAY 4096 OF CHAR;
    tiny: ARRAY 1 OF CHAR;
    handle, other: Platform.DirectoryHandle;
    error: Platform.ErrorCode;
    done, foundFile, foundChild, ignored: BOOLEAN;

  PROCEDURE Join(base, part: ARRAY OF CHAR; VAR result: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN
    COPY(base, result); i := 0;
    WHILE result[i] # 0X DO INC(i) END;
    result[i] := "/"; INC(i); j := 0;
    WHILE part[j] # 0X DO result[i] := part[j]; INC(i); INC(j) END;
    result[i] := 0X
  END Join;

BEGIN
  Modules.GetArg(1, path);
  Join(path, "absent", missing); Join(path, "file.txt", file);
  Join(path, "child", child); Join(path, "link", link);
  ASSERT(Platform.IsDirectory(path)); ASSERT(Platform.IsDirectory(child));
  ASSERT(Platform.IsDirectory(link)); ASSERT(~Platform.IsDirectory(file));
  ASSERT(~Platform.IsDirectory(missing));

  handle := 1; error := Platform.OpenDirectory(missing, handle);
  ASSERT(error # 0); ASSERT(handle = 0);
  error := Platform.OpenDirectory(file, handle);
  ASSERT(error # 0); ASSERT(handle = 0);
  error := Platform.CloseDirectory(handle); ASSERT(error = 0);

  error := Platform.OpenDirectory(path, handle); ASSERT(error = 0); ASSERT(handle # 0);
  error := Platform.OpenDirectory(child, other); ASSERT(error = 0); ASSERT(other # 0);
  error := Platform.ReadDirectory(handle, tiny, done);
  ASSERT(error # 0); ASSERT(~done); ASSERT(tiny[0] = 0X);
  error := Platform.CloseDirectory(handle); ASSERT(error = 0); ASSERT(handle = 0);
  error := Platform.CloseDirectory(other); ASSERT(error = 0); ASSERT(other = 0);

  error := Platform.OpenDirectory(path, handle); ASSERT(error = 0);
  foundFile := FALSE; foundChild := FALSE;
  LOOP
    (* A stale errno from stat must not turn normal EOF into a read error. *)
    ignored := Platform.IsDirectory(missing);
    error := Platform.ReadDirectory(handle, name, done); ASSERT(error = 0);
    IF done THEN EXIT END;
    IF name = "file.txt" THEN foundFile := TRUE END;
    IF name = "child" THEN foundChild := TRUE END
  END;
  ASSERT(foundFile & foundChild);
  error := Platform.ReadDirectory(handle, name, done);
  ASSERT((error = 0) & done); ASSERT(name[0] = 0X);
  error := Platform.CloseDirectory(handle); ASSERT(error = 0); ASSERT(handle = 0);
  error := Platform.CloseDirectory(handle); ASSERT(error = 0);
  Out.String("directory API passed"); Out.Ln
END testDirectories.
