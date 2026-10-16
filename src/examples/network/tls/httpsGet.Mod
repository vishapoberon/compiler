MODULE httpsGet;  (* httpsGet host port path [file]: GET over TLS 1.3, the status line, the body
  size and whether it is complete; the body saved in file if it is complete *)
IMPORT httpsPure, strTypes, Files, Args, Out;
VAR host, port, path, name: ARRAY 256 OF CHAR; h: httpsPure.TLSClient; b: strTypes.pstring;
  f: Files.File; r: Files.Rider; i: LONGINT;
BEGIN
  Args.Get(1, host); Args.Get(2, port); Args.Get(3, path); Args.Get(4, name);
  IF path = "" THEN COPY("/", path) END;
  h := httpsPure.Create(host, port, path);
  b := h.Get(h);
  IF (b = NIL) OR (h.rspnFirstLine = NIL) THEN Out.String("failed"); Out.Ln
  ELSE
    Out.String(h.rspnFirstLine^); Out.String(", "); Out.Int(h.rspnContentLength, 0); Out.String(" bytes");
    IF h.rspnComplete THEN Out.String(", complete") ELSE Out.String(", incomplete") END;
    IF h.rspnComplete & (name # "") THEN
      f := Files.New(name); Files.Set(r, f, 0);
      i := 0; WHILE i < h.rspnContentLength DO Files.Write(r, h.rspnBody[i]); INC(i) END;
      Files.Register(f); Out.String(", saved in "); Out.String(name)
    END;
    Out.Ln
  END
END httpsGet.
