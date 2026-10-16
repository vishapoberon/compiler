MODULE gzip;  (** gzip commands, ported from Polpo's loksh module *)

(* gzip.Compress file [file.gz]
   gzip.Decompress file.gz [file]
   Keeping the input; renaming temporary output only after stream and checksum checks. *)

IMPORT Files, GZReaders, GZWriters, texts := CommandArgs, out := Out, ArchivePaths;

CONST BufLen = 8192;
TYPE Name = ARRAY 256 OF CHAR;
VAR res*: LONGINT;

PROCEDURE Len(VAR s: ARRAY OF CHAR): LONGINT;
VAR i: LONGINT;
BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END; RETURN i END Len;

PROCEDURE Args(VAR a, b: ARRAY OF CHAR): BOOLEAN;
VAR r: texts.Reader; extra: Name; have, more: BOOLEAN;
BEGIN
  texts.OpenArgs(r); b[0] := 0X;
  have := texts.Arg(r, a); more := texts.Arg(r, b);
  more := texts.Arg(r, extra);
  RETURN have & ~more & r.valid
END Args;

PROCEDURE Compress*;
VAR in, name: Name; f, g: Files.File; r: Files.Rider; w: GZWriters.Writer;
  buf: ARRAY BufLen OF CHAR; n, written, total, status: LONGINT;
BEGIN
  res := 1;
  IF ~Args(in, name) THEN out.String("usage: gzip.Compress file [file.gz]"); out.Ln; RETURN END;
  IF name = "" THEN
    COPY(in, name); n := Len(name);
    IF n + 3 >= LEN(name) THEN out.String("gzip: output name too long"); out.Ln; RETURN END;
    name[n] := "."; name[n+1] := "g"; name[n+2] := "z"; name[n+3] := 0X
  END;
  f := Files.Old(in);
  IF f = NIL THEN out.String("gzip: no "); out.String(in); out.Ln; RETURN END;
  IF ArchivePaths.SameFile(in, name) THEN out.String("gzip: input and output are the same file"); out.Ln; RETURN END;
  g := Files.New(name); GZWriters.Open(w, GZWriters.DefaultCompression, GZWriters.DefaultStrategy, g);
  Files.Set(r, f, 0); total := 0; status := w.res;
  LOOP
    IF status # GZWriters.Ok THEN EXIT END;
    Files.ReadBytes(r, buf, BufLen); n := BufLen - r.res;
    IF n <= 0 THEN EXIT END;
    GZWriters.WriteBytes(w, buf, 0, n, written); INC(total, written); status := w.res;
    IF written # n THEN status := GZWriters.DataError END;
    IF r.res # 0 THEN EXIT END
  END;
  GZWriters.Close(w);
  IF (status = GZWriters.Ok) & (w.res = GZWriters.Ok) THEN
    Files.Register(g); res := 0;
    out.String("gzip: "); out.String(name); out.String(", "); out.Int(total, 0);
    out.String(" bytes to "); out.Int(Files.Length(g), 0)
  ELSE out.String("gzip: compression failed")
  END;
  out.Ln
END Compress;

PROCEDURE Decompress*;
VAR in, name: Name; f, g: Files.File; w, header: Files.Rider; r: GZReaders.Reader;
  buf: ARRAY BufLen OF CHAR; n, total, i, status: LONGINT; a, b: CHAR;
BEGIN
  res := 1;
  IF ~Args(in, name) THEN out.String("usage: gzip.Decompress file.gz [file]"); out.Ln; RETURN END;
  IF name = "" THEN
    COPY(in, name); i := Len(name);
    IF (i > 3) & (name[i-3] = ".") & (name[i-2] = "g") & (name[i-1] = "z") THEN name[i-3] := 0X
    ELSE out.String("gzip: name the output (input has no .gz suffix)"); out.Ln; RETURN END
  END;
  f := Files.Old(in);
  IF f = NIL THEN out.String("gzip: no "); out.String(in); out.Ln; RETURN END;
  IF ArchivePaths.SameFile(in, name) THEN out.String("gzip: input and output are the same file"); out.Ln; RETURN END;
  Files.Set(header, f, 0); Files.Read(header, a); Files.Read(header, b);
  IF header.eof OR (a # 1FX) OR (b # 8BX) THEN out.String("gzip: not a gzip file"); out.Ln; RETURN END;
  GZReaders.Open(r, f);
  IF r.res # GZReaders.Ok THEN out.String("gzip: invalid header"); out.Ln; RETURN END;
  g := Files.New(name); Files.Set(w, g, 0); total := 0;
  REPEAT
    GZReaders.ReadBytes(r, buf, 0, BufLen, n);
    IF n > 0 THEN Files.WriteBytes(w, buf, n); INC(total, n) END
  UNTIL (r.res # GZReaders.Ok) OR (n = 0);
  status := r.res; GZReaders.Close(r);
  IF (status = GZReaders.StreamEnd) & (r.res = GZReaders.Ok) THEN
    Files.Register(g); res := 0;
    out.String("gzip: "); out.String(name); out.String(", "); out.Int(total, 0); out.String(" bytes")
  ELSE out.String("gzip: "); out.String(in); out.String(" is damaged") END;
  out.Ln
END Decompress;

END gzip.
