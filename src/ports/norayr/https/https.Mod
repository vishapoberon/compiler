MODULE https;  (** downloads by URL: http:// with http, https:// with TLS 1.3 in Oberon (httpsPure) *)

(* url: http[s]://host[:port][/path]; host is a name, an IPv4 address or [an IPv6 address].
   https is TLS_AES_128_GCM_SHA256 with X25519: the certificate chain up to a root of the CA
   bundle (SSL_CERT_FILE, else /etc/ssl/certs/ca-certificates.crt), the host name,
   CertificateVerify and Finished are checked; the connection is refused otherwise.
   A body is complete (h.rspnComplete) when it has its Content-Length or its last chunk, and a
   TLS connection that ended without close_notify is not complete. The same as fetch in polpo. *)

IMPORT http, httpsPure, Files, Out;

(** splits url; secure is TRUE for https; port is 443 or 80 when the url has none *)
PROCEDURE Split*(url: ARRAY OF CHAR; VAR host, port, path: ARRAY OF CHAR; VAR secure: BOOLEAN): BOOLEAN;
VAR i, j: LONGINT;
BEGIN
  i := 0; secure := FALSE;
  WHILE (url[i] # 0X) & (url[i] # ":") DO INC(i) END;
  IF (url[i] = ":") & (url[i + 1] = "/") & (url[i + 2] = "/") THEN
    IF (i >= 4) & (CAP(url[0]) = "H") & (CAP(url[1]) = "T") & (CAP(url[2]) = "T") & (CAP(url[3]) = "P")
      & ((i = 4) OR (i = 5) & (CAP(url[4]) = "S")) THEN secure := i = 5
    ELSE RETURN FALSE
    END;
    INC(i, 3)
  ELSE i := 0
  END;
  j := 0;
  IF url[i] = "[" THEN  (* [IPv6] *)
    INC(i);
    WHILE (url[i] # 0X) & (url[i] # "]") & (j < LEN(host) - 1) DO host[j] := url[i]; INC(i); INC(j) END;
    IF url[i] = "]" THEN INC(i) END
  ELSE
    WHILE (url[i] # 0X) & (url[i] # ":") & (url[i] # "/") & (j < LEN(host) - 1) DO
      host[j] := url[i]; INC(i); INC(j)
    END
  END;
  host[j] := 0X; j := 0;
  IF url[i] = ":" THEN
    INC(i);
    WHILE (url[i] >= "0") & (url[i] <= "9") & (j < LEN(port) - 1) DO port[j] := url[i]; INC(i); INC(j) END
  END;
  IF j # 0 THEN port[j] := 0X ELSIF secure THEN COPY("443", port) ELSE COPY("80", port) END;
  j := 0;
  IF url[i] # "/" THEN path[0] := "/"; j := 1 END;
  WHILE (url[i] # 0X) & (j < LEN(path) - 1) DO path[j] := url[i]; INC(i); INC(j) END;
  path[j] := 0X;
  RETURN host[0] # 0X
END Split;

(** a client for url, http or https; NIL if url is not http[s]://host... *)
PROCEDURE Create*(url: ARRAY OF CHAR): http.Client;
VAR host, port, path: ARRAY 1024 OF CHAR; secure: BOOLEAN; h: http.Client;
BEGIN
  h := NIL;
  IF Split(url, host, port, path, secure) THEN
    IF secure THEN h := httpsPure.Create(host, port, path) ELSE h := http.Create(host, port, path) END
  END;
  RETURN h
END Create;

(** GET url; FALSE if the url is bad, the connection or the TLS handshake failed or nothing came
  back; h has the answer: h.rspnFirstLine, h.rspnBody, h.rspnContentLength, h.rspnComplete *)
PROCEDURE Get*(url: ARRAY OF CHAR; VAR h: http.Client): BOOLEAN;
BEGIN
  h := Create(url);
  RETURN (h # NIL) & (h.Get(h) # NIL) & (h.rspnFirstLine # NIL)
END Get;

(** writes the body of h to the file name, only when it is complete *)
PROCEDURE Save*(h: http.Client; name: ARRAY OF CHAR): BOOLEAN;
VAR f: Files.File; r: Files.Rider; i: LONGINT;
BEGIN
  IF (h = NIL) OR ~h.rspnComplete OR (h.rspnBody = NIL) THEN RETURN FALSE END;
  f := Files.New(name);
  IF f = NIL THEN RETURN FALSE END;
  Files.Set(r, f, 0); i := 0;
  WHILE i < h.rspnContentLength DO Files.Write(r, h.rspnBody[i]); INC(i) END;
  Files.Register(f);
  RETURN TRUE
END Save;

(** prints the status line, the body size and whether it is complete *)
PROCEDURE Report*(h: http.Client);
BEGIN
  IF (h = NIL) OR (h.rspnFirstLine = NIL) THEN Out.String("no answer")
  ELSE
    Out.String(h.rspnFirstLine^); Out.String(", "); Out.Int(h.rspnContentLength, 0); Out.String(" bytes");
    IF h.rspnComplete THEN Out.String(", complete") ELSE Out.String(", incomplete") END
  END
END Report;

END https.
