MODULE TLSCABundle;
IMPORT Files, Kernel, TLSBytes;

CONST
  MaxBundle* = 1048576;
  DefaultPath* = "/etc/ssl/certs/ca-certificates.crt";

TYPE
  Bundle* = RECORD
    len*: LONGINT;
    text*: ARRAY MaxBundle OF CHAR
  END;
  Text = POINTER TO ARRAY OF CHAR;

VAR
  kept: Text; keptLen: LONGINT;  (* the bundle LoadDefault read, from keptPath *)
  keptPath: ARRAY 512 OF CHAR;

PROCEDURE Init*(VAR b: Bundle);
BEGIN
  b.len := 0; b.text[0] := 0X
END Init;

(** the file path into b (it is read as it is, the bytes and nothing else); FALSE if it is not there or
   too large *)
PROCEDURE Load*(path: ARRAY OF CHAR; VAR b: Bundle): BOOLEAN;
VAR f: Files.File; r: Files.Rider; n: LONGINT;
BEGIN
  Init(b);
  f := Files.Old(path);
  IF f = NIL THEN RETURN FALSE END;
  n := Files.Length(f);
  IF n >= MaxBundle - 1 THEN RETURN FALSE END;
  Files.Set(r, f, 0); Files.ReadBytes(r, b.text, n);
  IF r.res # 0 THEN RETURN FALSE END;
  b.len := n; b.text[n] := 0X;
  RETURN TRUE
END Load;

(** the bundle named by the environment variable SSL_CERT_FILE (as for OpenSSL), else DefaultPath; the
   file is read once and kept for the next connections, which then open no file *)
PROCEDURE LoadDefault*(VAR b: Bundle): BOOLEAN;
VAR path: ARRAY 512 OF CHAR; i: LONGINT;
BEGIN
  Kernel.GetConfig("SSL_CERT_FILE", path);
  IF path = "" THEN COPY(DefaultPath, path) END;
  IF (kept # NIL) & (path = keptPath) THEN
    i := 0; WHILE i < keptLen DO b.text[i] := kept[i]; INC(i) END;
    b.len := keptLen; b.text[keptLen] := 0X;
    RETURN TRUE
  END;
  IF ~Load(path, b) THEN RETURN FALSE END;
  NEW(kept, b.len + 1); i := 0; WHILE i < b.len DO kept[i] := b.text[i]; INC(i) END;
  keptLen := b.len; COPY(path, keptPath);
  RETURN TRUE
END LoadDefault;

BEGIN
  kept := NIL; keptLen := 0; keptPath := ""
END TLSCABundle.
