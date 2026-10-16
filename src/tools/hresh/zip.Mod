MODULE zip;  (** zip commands, ported from Polpo's loksh module *)

(* zip.Directory archive.zip
   zip.Add archive.zip file ...
   zip.Extract archive.zip [file ...]
   zip.Delete archive.zip file ... *)

IMPORT Files, Zip, texts := CommandArgs, out := Out, ArchivePaths;

CONST MaxFiles = 128;
TYPE Name = ARRAY 256 OF CHAR;
VAR res*: LONGINT;

PROCEDURE Args(VAR archive: ARRAY OF CHAR; VAR files: ARRAY OF Name; VAR n: INTEGER): BOOLEAN;
VAR r: texts.Reader; extra: Name;
BEGIN
  texts.OpenArgs(r); n := 0;
  IF ~texts.Arg(r, archive) THEN RETURN FALSE END;
  WHILE (n < LEN(files)) & texts.Arg(r, files[n]) DO INC(n) END;
  IF texts.Arg(r, extra) THEN RETURN FALSE END;
  RETURN r.valid
END Args;

PROCEDURE Error(archive, entry: ARRAY OF CHAR; code: LONGINT);
BEGIN
  res := code;
  out.String("zip: "); out.String(archive);
  IF entry # "" THEN out.String(", "); out.String(entry) END;
  out.String(": ");
  IF code = Zip.FileError THEN out.String("no such file")
  ELSIF code = Zip.NotZipArchiveError THEN out.String("not a zip archive")
  ELSIF code = Zip.EntryNotFound THEN out.String("no such entry")
  ELSIF code = Zip.EntryAlreadyExists THEN out.String("the entry exists")
  ELSIF code = Zip.NotSupportedError THEN out.String("unsupported format or encrypted")
  ELSIF code = Zip.DataError THEN out.String("damaged")
  ELSIF code = Zip.BadName THEN out.String("unsafe or invalid name")
  ELSE out.String("error "); out.Int(code, 0) END;
  out.Ln
END Error;

PROCEDURE Directory*;
VAR archive, none: Name; files: ARRAY 1 OF Name; n: INTEGER;
  arc: Zip.Archive; e: Zip.Entry; code: LONGINT;
BEGIN
  res := 1;
  IF ~Args(archive, files, n) OR (n # 0) THEN out.String("usage: zip.Directory archive.zip"); out.Ln; RETURN END;
  arc := Zip.OpenArchive(archive, code); none := "";
  IF arc = NIL THEN Error(archive, none, code); RETURN END;
  e := Zip.FirstEntry(arc);
  WHILE e # NIL DO
    out.String(e.name); out.String("  "); out.Int(e.uncompSize, 0);
    out.String(" bytes, "); out.Int(e.compSize, 0); out.String(" compressed"); out.Ln;
    e := Zip.NextEntry(e)
  END;
  out.String("zip: "); out.Int(arc.nofEntries, 0); out.String(" entries"); out.Ln; res := 0
END Directory;

PROCEDURE Add*;
VAR archive, none: Name; files: ARRAY MaxFiles OF Name; n, i: INTEGER;
  arc: Zip.Archive; code: LONGINT; f: Files.File; r: Files.Rider;
BEGIN
  res := 1;
  IF ~Args(archive, files, n) OR (n = 0) THEN out.String("usage: zip.Add archive.zip file ..."); out.Ln; RETURN END;
  FOR i := 0 TO n - 1 DO
    IF ~ArchivePaths.Safe(files[i]) OR ArchivePaths.SameFile(archive, files[i]) THEN
      Error(archive, files[i], Zip.BadName); RETURN
    END
  END;
  none := ""; arc := Zip.CreateArchive(archive, code);
  IF arc = NIL THEN Error(archive, none, code); RETURN END;
  res := 0; i := 0;
  WHILE i < n DO
    f := Files.Old(files[i]);
    IF f = NIL THEN Error(archive, files[i], Zip.FileError)
    ELSE
      Files.Set(r, f, 0);
      Zip.AddEntry(arc, files[i], r, Files.Length(f), Zip.DefaultCompression, Zip.DefaultStrategy, code);
      IF code = Zip.Ok THEN out.String("zip: added "); out.String(files[i]); out.Ln
      ELSE Error(archive, files[i], code) END
    END;
    INC(i)
  END
END Add;

PROCEDURE ExtractOne(arc: Zip.Archive; e: Zip.Entry; VAR archive: ARRAY OF CHAR);
VAR f: Files.File; r: Files.Rider; code, i: LONGINT; directory: BOOLEAN;
BEGIN
  i := 0; WHILE (i < LEN(e.name)) & (e.name[i] # 0X) DO INC(i) END;
  directory := (i > 0) & (e.name[i-1] = "/");
  IF ArchivePaths.SameFile(archive, e.name) OR ~ArchivePaths.Prepare(e.name, directory) THEN
    Error(archive, e.name, Zip.BadName); RETURN
  END;
  IF directory THEN RETURN END;
  f := Files.New(e.name); Files.Set(r, f, 0); Zip.ExtractEntry(arc, e, r, code);
  IF code = Zip.Ok THEN
    Files.Register(f); out.String("zip: extracted "); out.String(e.name); out.Ln
  ELSE Error(archive, e.name, code) END
END ExtractOne;

PROCEDURE Extract*;
VAR archive, none: Name; files: ARRAY MaxFiles OF Name; n, i: INTEGER;
  arc: Zip.Archive; e: Zip.Entry; code: LONGINT;
BEGIN
  res := 1;
  IF ~Args(archive, files, n) THEN out.String("usage: zip.Extract archive.zip [file ...]"); out.Ln; RETURN END;
  none := ""; arc := Zip.OpenArchive(archive, code);
  IF arc = NIL THEN Error(archive, none, code); RETURN END;
  res := 0;
  IF n = 0 THEN
    e := Zip.FirstEntry(arc);
    WHILE e # NIL DO ExtractOne(arc, e, archive); e := Zip.NextEntry(e) END
  ELSE
    i := 0;
    WHILE i < n DO
      e := Zip.GetEntry(arc, files[i], code);
      IF e = NIL THEN Error(archive, files[i], code) ELSE ExtractOne(arc, e, archive) END;
      INC(i)
    END
  END
END Extract;

PROCEDURE Delete*;
VAR archive, none: Name; files: ARRAY MaxFiles OF Name; n, i: INTEGER;
  arc: Zip.Archive; e: Zip.Entry; code: LONGINT;
BEGIN
  res := 1;
  IF ~Args(archive, files, n) OR (n = 0) THEN out.String("usage: zip.Delete archive.zip file ..."); out.Ln; RETURN END;
  none := ""; arc := Zip.OpenArchive(archive, code);
  IF arc = NIL THEN Error(archive, none, code); RETURN END;
  res := 0; i := 0;
  WHILE i < n DO
    e := Zip.GetEntry(arc, files[i], code);
    IF e = NIL THEN Error(archive, files[i], code)
    ELSE
      Zip.DeleteEntry(arc, e, code);
      IF code = Zip.Ok THEN out.String("zip: deleted "); out.String(files[i]); out.Ln
      ELSE Error(archive, files[i], code) END
    END;
    INC(i)
  END
END Delete;

END zip.
