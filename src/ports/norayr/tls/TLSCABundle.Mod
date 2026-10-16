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

(** the bundle named by the environment variable SSL_CERT_FILE (as for OpenSSL), else DefaultPath *)
PROCEDURE LoadDefault*(VAR b: Bundle): BOOLEAN;
VAR path: ARRAY 512 OF CHAR;
BEGIN
  Kernel.GetConfig("SSL_CERT_FILE", path);
  IF path = "" THEN COPY(DefaultPath, path) END;
  RETURN Load(path, b)
END LoadDefault;

END TLSCABundle.
