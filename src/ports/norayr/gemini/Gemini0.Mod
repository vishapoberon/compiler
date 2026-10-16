MODULE Gemini0;  (** the core of Gemini and Spartan clients: requests, answers, links, identities *)

(* No console and no desktop: the frontends (dcs, DCS, Pishmish, gemini, spartan) show what they
   get. Request makes one request: gemini:// over TLS 1.3 (port 1965), spartan:// over plain TCP
   (port 300). Input goes into the query of a Gemini URL (percent-encoded, the whole URL at most
   1024 bytes) and into the data of a Spartan request. The answer is a Response: the status
   (Gemini 10..69; Spartan 2..5), the meta (a type, a prompt, a redirect, an error), and the body
   in chunks, complete when the server ended it properly (close_notify; for Spartan the end of
   the connection). Fetch follows redirects.
   A server is trusted on first use (Tofu, the default): the SHA-256 of its key is kept in
   $HOME/.gemini_hosts ("host:port key") and a different key later is refused; or not checked
   at all (None); or it must have the certificate whose SHA-256 is pin (Pin). A server with a
   chain to a trusted root is accepted in every mode except Pin.
   Identities (client certificates, as servers ask for them with status 60) are pairs <sha256 of
   the certificate>.crt and .key in $XDG_CONFIG_HOME/dcs/idents (default ~/.config/dcs/idents);
   the key is ECDSA P-256 or RSA. *)

(* VOC port: NetHost supplies directory and protected-file services; no FATFiles stack. *)
IMPORT NetHost, Kernel, Files, Internet, TLSBytes, TLSASN1, TLSPEM, TLSCABundle, TLSX509,
  TLSX509Validity, TLSSHA256, TLSIdentity, TLSCertGen, TLS13Live;

CONST
  MaxURL* = 1100;          (** the arrays for URLs; a Gemini request is at most 1024 bytes *)
  MaxMeta* = 1100;
  ChunkSize* = 16384;
  Tofu* = 0; None* = 1; Pin* = 2;  (** how a Gemini server is trusted *)
  Gemini* = 1; Spartan* = 2;       (** protocols *)
  MaxCandidates* = 32;
  NameLen = 256;
  PathLen = 1024;

TYPE
  Chunk* = POINTER TO ChunkDesc;  (** a piece of a body *)
  ChunkDesc* = RECORD
    len*: LONGINT;
    data*: ARRAY ChunkSize OF CHAR;
    next*: Chunk
  END;

  Options* = POINTER TO OptionsDesc;
  OptionsDesc* = RECORD
    trust*: LONGINT;                (** Tofu, None or Pin *)
    pin*: ARRAY 100 OF CHAR;         (** Pin: the SHA-256 of the certificate, hex (colons and case do not matter) *)
    identity*: TLSIdentity.Identity; (** presented when a server asks for a certificate, or NIL *)
    redirects*: LONGINT;            (** Fetch follows at most this many *)
    maxBody*: LONGINT               (** bytes kept of a body *)
  END;

  Response* = POINTER TO ResponseDesc;
  ResponseDesc* = RECORD
    url*: ARRAY MaxURL OF CHAR;     (** what was asked for (the last one after redirects) *)
    protocol*: LONGINT;             (** Gemini or Spartan *)
    status*: LONGINT;               (** Gemini: 10..69; Spartan: 2..5 *)
    meta*: ARRAY MaxMeta OF CHAR;
    body*: Chunk;                   (** a success: the body *)
    length*: LONGINT;
    complete*: BOOLEAN;             (** the body ended properly, nothing is missing *)
    certPin*, keyPin*: ARRAY 65 OF CHAR;  (** the SHA-256 of the certificate and of the key of the server *)
    firstUse*: BOOLEAN;             (** Tofu: the key of the server was seen for the first time and kept *)
    identitySent*: BOOLEAN          (** the server asked for a certificate and got the identity *)
  END;

  Ident* = POINTER TO IdentDesc;  (** an identity in the identities directory *)
  IdentDesc* = RECORD
    fingerprint*: ARRAY 65 OF CHAR;   (** from the name of the files, lower case *)
    cert*, key*: ARRAY PathLen OF CHAR;
    cn*, mail*: ARRAY NameLen OF CHAR;  (** from the subject of the certificate, "" if none *)
    notAfter*: ARRAY 16 OF CHAR;      (** YYYY-MM-DD, "" if unknown *)
    next*: Ident
  END;

  Bundle = POINTER TO TLSCABundle.Bundle;
  Cert = POINTER TO TLSX509.CertInfo;
  State = POINTER TO TLS13Live.State;

VAR
  lastError*: ARRAY 256 OF CHAR;  (** why the last Request, Fetch or identity procedure failed *)
  crtNames: Ident;  (* the .crt files Collect found, for LoadIdents *)
  candidates*: ARRAY MaxCandidates OF Ident;  (** FindIdent: the identities the query matched *)
  nCandidates*: LONGINT;
  s: State;

(* ----- strings ----- *)

PROCEDURE Len(VAR a: ARRAY OF CHAR): LONGINT;
VAR i: LONGINT;
BEGIN i := 0; WHILE (i < LEN(a)) & (a[i] # 0X) DO INC(i) END; RETURN i
END Len;

PROCEDURE Append(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
VAR i, j: LONGINT;
BEGIN
  i := Len(a); j := 0;
  WHILE (j < LEN(b)) & (b[j] # 0X) & (i < LEN(a) - 1) DO a[i] := b[j]; INC(i); INC(j) END;
  a[i] := 0X
END Append;

PROCEDURE AppendInt(VAR a: ARRAY OF CHAR; x: LONGINT);
VAR d: ARRAY 12 OF CHAR; i, j: LONGINT;
BEGIN
  i := 0; REPEAT d[i] := CHR(x MOD 10 + ORD("0")); x := x DIV 10; INC(i) UNTIL x = 0;
  j := Len(a); WHILE (i > 0) & (j < LEN(a) - 1) DO DEC(i); a[j] := d[i]; INC(j) END; a[j] := 0X
END AppendInt;

PROCEDURE Lower(c: CHAR): CHAR;
BEGIN
  IF (c >= "A") & (c <= "Z") THEN RETURN CHR(ORD(c) + 32) END;
  RETURN c
END Lower;

(* does a start with b, ignoring case? *)
PROCEDURE StartsWith(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(b)) & (b[i] # 0X) DO
    IF (i >= LEN(a)) OR (Lower(a[i]) # Lower(b[i])) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END StartsWith;

PROCEDURE Same(VAR a, b: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0; WHILE (a[i] # 0X) & (Lower(a[i]) = Lower(b[i])) DO INC(i) END;
  RETURN Lower(a[i]) = Lower(b[i])
END Same;

(* does a contain b, ignoring case? *)
PROCEDURE Contains(VAR a, b: ARRAY OF CHAR): BOOLEAN;
VAR i, j: LONGINT;
BEGIN
  IF b[0] = 0X THEN RETURN FALSE END;
  i := 0;
  WHILE a[i] # 0X DO
    j := 0; WHILE (b[j] # 0X) & (Lower(a[i + j]) = Lower(b[j])) DO INC(j) END;
    IF b[j] = 0X THEN RETURN TRUE END;
    INC(i)
  END;
  RETURN FALSE
END Contains;

(* hex digits only, in lower case: "AB:cd" -> "abcd" *)
PROCEDURE Normalize(VAR a, b: ARRAY OF CHAR);
VAR i, j: LONGINT; c: CHAR;
BEGIN
  i := 0; j := 0;
  WHILE (a[i] # 0X) & (j < LEN(b) - 1) DO
    c := Lower(a[i]);
    IF (c >= "0") & (c <= "9") OR (c >= "a") & (c <= "f") THEN b[j] := c; INC(j) END;
    INC(i)
  END;
  b[j] := 0X
END Normalize;

PROCEDURE SetError(a, b: ARRAY OF CHAR);
BEGIN COPY(a, lastError); Append(lastError, b)
END SetError;

(* ----- URLs ----- *)

(** the protocol of url: Gemini, Spartan, or 0 for another scheme *)
PROCEDURE Protocol*(VAR url: ARRAY OF CHAR): LONGINT;
BEGIN
  IF StartsWith(url, "gemini://") THEN RETURN Gemini
  ELSIF StartsWith(url, "spartan://") THEN RETURN Spartan
  END;
  RETURN 0
END Protocol;

(** the host (without brackets), the port (the default of the protocol if none) and the path
  with the query (at least "/") of a gemini:// or spartan:// url *)
PROCEDURE Split*(VAR url, host, port, path: ARRAY OF CHAR): BOOLEAN;
VAR i, j: LONGINT;
BEGIN
  host[0] := 0X; port[0] := 0X; path[0] := 0X;
  IF Protocol(url) = Gemini THEN i := 9 ELSIF Protocol(url) = Spartan THEN i := 10 ELSE RETURN FALSE END;
  j := 0;
  IF url[i] = "[" THEN  (* [IPv6] *)
    INC(i);
    WHILE (url[i] # 0X) & (url[i] # "]") & (j < LEN(host) - 1) DO host[j] := url[i]; INC(i); INC(j) END;
    IF url[i] = "]" THEN INC(i) END
  ELSE
    WHILE (url[i] # 0X) & (url[i] # ":") & (url[i] # "/") & (url[i] # "?") & (url[i] # "#") & (j < LEN(host) - 1) DO
      host[j] := url[i]; INC(i); INC(j)
    END
  END;
  host[j] := 0X; j := 0;
  IF url[i] = ":" THEN
    INC(i); WHILE (url[i] >= "0") & (url[i] <= "9") & (j < LEN(port) - 1) DO port[j] := url[i]; INC(i); INC(j) END
  END;
  port[j] := 0X;
  IF j = 0 THEN IF Protocol(url) = Gemini THEN COPY("1965", port) ELSE COPY("300", port) END END;
  j := 0;
  IF url[i] # "/" THEN path[0] := "/"; j := 1 END;
  WHILE (url[i] # 0X) & (url[i] # "#") & (j < LEN(path) - 1) DO path[j] := url[i]; INC(i); INC(j) END;
  path[j] := 0X;
  RETURN host[0] # 0X
END Split;

(* path without "." and ".." segments (RFC 3986 5.2.4) *)
PROCEDURE RemoveDots(VAR path: ARRAY OF CHAR);
VAR out: ARRAY PathLen + 100 OF CHAR; i, j, k: LONGINT; query: ARRAY PathLen + 100 OF CHAR;
BEGIN
  i := 0; WHILE (path[i] # 0X) & (path[i] # "?") DO INC(i) END;
  COPY(path, query); k := 0; WHILE path[i + k] # 0X DO query[k] := path[i + k]; INC(k) END; query[k] := 0X;
  path[i] := 0X;
  i := 0; j := 0;
  WHILE path[i] # 0X DO
    IF (path[i] = "/") & (path[i + 1] = ".") & ((path[i + 2] = "/") OR (path[i + 2] = 0X)) THEN
      INC(i, 2); IF path[i] = 0X THEN out[j] := "/"; INC(j) END
    ELSIF (path[i] = "/") & (path[i + 1] = ".") & (path[i + 2] = ".") & ((path[i + 3] = "/") OR (path[i + 3] = 0X)) THEN
      INC(i, 3); WHILE (j > 0) & (out[j - 1] # "/") DO DEC(j) END; IF j > 0 THEN DEC(j) END;
      IF path[i] = 0X THEN out[j] := "/"; INC(j) END
    ELSE
      out[j] := path[i]; INC(j); INC(i);
      WHILE (path[i] # 0X) & (path[i] # "/") DO out[j] := path[i]; INC(j); INC(i) END
    END
  END;
  out[j] := 0X; IF j = 0 THEN out := "/" END;
  COPY(out, path); Append(path, query)
END RemoveDots;

(** url := target, a link in the page base, made absolute (RFC 3986); FALSE if base is not a
  gemini:// or spartan:// URL *)
PROCEDURE Resolve*(VAR base, target, url: ARRAY OF CHAR): BOOLEAN;
VAR host, port, path, origin: ARRAY MaxURL OF CHAR; scheme: ARRAY 16 OF CHAR; i, k: LONGINT;
BEGIN
  i := 0;
  WHILE (target[i] >= "a") & (target[i] <= "z") OR (target[i] >= "A") & (target[i] <= "Z") OR
        (i > 0) & ((target[i] >= "0") & (target[i] <= "9") OR (target[i] = "+") OR (target[i] = "-") OR (target[i] = ".")) DO INC(i) END;
  IF (i > 0) & (target[i] = ":") THEN COPY(target, url); RETURN TRUE END;  (* absolute, any scheme *)
  IF ~Split(base, host, port, path) THEN RETURN FALSE END;
  IF Protocol(base) = Gemini THEN scheme := "gemini:" ELSE scheme := "spartan:" END;
  IF (target[0] = "/") & (target[1] = "/") THEN COPY(scheme, url); Append(url, target); RETURN TRUE END;
  COPY(scheme, origin); Append(origin, "//");
  k := 0; WHILE (host[k] # 0X) & (host[k] # ":") DO INC(k) END;
  IF host[k] = ":" THEN Append(origin, "[") END;
  Append(origin, host);
  IF host[k] = ":" THEN Append(origin, "]") END;
  IF (Protocol(base) = Gemini) & (port # "1965") OR (Protocol(base) = Spartan) & (port # "300") THEN Append(origin, ":"); Append(origin, port) END;
  IF target[0] = "/" THEN COPY(target, path)
  ELSIF target[0] = 0X THEN (* the same page *)
  ELSIF target[0] = "?" THEN
    i := 0; WHILE (path[i] # 0X) & (path[i] # "?") DO INC(i) END; path[i] := 0X; Append(path, target)
  ELSE
    i := 0; WHILE (path[i] # 0X) & (path[i] # "?") DO INC(i) END; path[i] := 0X;
    i := Len(path); WHILE (i > 0) & (path[i - 1] # "/") DO DEC(i) END; path[i] := 0X;
    Append(path, target)
  END;
  i := 0; WHILE (path[i] # 0X) & (path[i] # "#") DO INC(i) END; path[i] := 0X;
  RemoveDots(path);
  COPY(origin, url); Append(url, path);
  RETURN TRUE
END Resolve;

(** enc := s percent-encoded for a query: letters, digits and - . _ ~ stay, the rest %XX *)
PROCEDURE Encode*(VAR s, enc: ARRAY OF CHAR);
VAR i, j: LONGINT; c: CHAR; hex: ARRAY 17 OF CHAR;
BEGIN
  hex := "0123456789ABCDEF"; i := 0; j := 0;
  WHILE (s[i] # 0X) & (j < LEN(enc) - 4) DO
    c := s[i];
    IF (c >= "a") & (c <= "z") OR (c >= "A") & (c <= "Z") OR (c >= "0") & (c <= "9") OR (c = "-") OR (c = ".") OR (c = "_") OR (c = "~") THEN
      enc[j] := c; INC(j)
    ELSE enc[j] := "%"; enc[j + 1] := hex[ORD(c) DIV 16]; enc[j + 2] := hex[ORD(c) MOD 16]; INC(j, 3)
    END;
    INC(i)
  END;
  enc[j] := 0X
END Encode;

(** the name of a status: "20 success", "51 not found", ...; Spartan: "2 success", ... *)
PROCEDURE StatusName*(protocol, status: LONGINT; VAR name: ARRAY OF CHAR);
BEGIN
  name[0] := 0X; AppendInt(name, status); Append(name, " ");
  IF protocol = Spartan THEN
    CASE status OF 2: Append(name, "success") | 3: Append(name, "redirect") | 4: Append(name, "client error")
    | 5: Append(name, "server error") ELSE Append(name, "(unknown)")
    END
  ELSE
    CASE status OF
      10: Append(name, "input") | 11: Append(name, "sensitive input") | 20: Append(name, "success")
    | 30: Append(name, "temporary redirect") | 31: Append(name, "permanent redirect")
    | 40: Append(name, "temporary failure") | 41: Append(name, "server unavailable") | 42: Append(name, "CGI error")
    | 43: Append(name, "proxy error") | 44: Append(name, "slow down")
    | 50: Append(name, "permanent failure") | 51: Append(name, "not found") | 52: Append(name, "gone")
    | 53: Append(name, "proxy request refused") | 59: Append(name, "bad request")
    | 60: Append(name, "certificate required") | 61: Append(name, "certificate not authorised")
    | 62: Append(name, "certificate not valid")
    ELSE Append(name, "(unknown)")
    END
  END
END StatusName;

(** the kind of a status: 1 input, 2 success, 3 redirect, 4 temporary failure, 5 permanent
  failure, 6 certificate; Spartan's 2..5 map to 2 success, 3 redirect, 5 failures *)
PROCEDURE Kind*(r: Response): LONGINT;
BEGIN
  IF r.protocol = Spartan THEN
    IF r.status >= 4 THEN RETURN 5 END;
    RETURN r.status
  END;
  RETURN r.status DIV 10
END Kind;

PROCEDURE IsNameChar(c: CHAR): BOOLEAN;
BEGIN
  RETURN (c >= "a") & (c <= "z") OR (c >= "A") & (c <= "Z") OR (c >= "0") & (c <= "9") OR
    (c = "-") OR (c = "_") OR (c = ".") OR (c = "~") OR (c = "+") OR (c = "%")
END IsNameChar;

(* name := text with the characters that are not safe in a file name as "-", no leading dots *)
PROCEDURE Sanitize(VAR text, name: ARRAY OF CHAR);
VAR i, j: LONGINT;
BEGIN
  i := 0; j := 0;
  WHILE (text[i] # 0X) & (j < LEN(name) - 1) DO
    IF IsNameChar(text[i]) THEN name[j] := text[i] ELSE name[j] := "-" END;
    INC(i); INC(j)
  END;
  name[j] := 0X;
  i := 0; WHILE name[i] = "." DO INC(i) END;
  IF i > 0 THEN j := 0; WHILE name[i] # 0X DO name[j] := name[i]; INC(i); INC(j) END; name[j] := 0X END
END Sanitize;

(** a file name for url (as dcs makes it): the last segment of the path without the
  query, characters not safe in a name as "-"; the host if the path gives none *)
PROCEDURE NameForURL*(VAR url, name: ARRAY OF CHAR);
VAR host, port, path, last: ARRAY MaxURL OF CHAR; i, j: LONGINT;
BEGIN
  IF ~Split(url, host, port, path) THEN COPY("gemtext", name); RETURN END;
  i := 0; WHILE (path[i] # 0X) & (path[i] # "?") DO INC(i) END; path[i] := 0X;
  i := Len(path); WHILE (i > 0) & (path[i - 1] # "/") DO DEC(i) END;
  j := 0; WHILE path[i] # 0X DO last[j] := path[i]; INC(i); INC(j) END; last[j] := 0X;
  Sanitize(last, name);
  IF name[0] = 0X THEN Sanitize(host, name) END;
  IF name[0] = 0X THEN COPY("gemtext", name) END
END NameForURL;

(* ----- files ----- *)

PROCEDURE Exists*(VAR name: ARRAY OF CHAR): BOOLEAN;
VAR full: NetHost.FileName; flags: SET;
BEGIN RETURN NetHost.Exists(name, full, flags)
END Exists;

(* writes the bytes a[0..n) to the new file name, with mode (as for chmod) if it is not 644; FALSE if it cannot *)
PROCEDURE WriteFile(VAR name: ARRAY OF CHAR; VAR a: ARRAY OF CHAR; n, mode: LONGINT): BOOLEAN;
BEGIN
  RETURN NetHost.WriteFile(name, a, n, mode)
END WriteFile;

(** writes the body of r to the file name, as it arrived; FALSE if it cannot *)
PROCEDURE Save*(r: Response; VAR name: ARRAY OF CHAR): BOOLEAN;
VAR f: Files.File; w: Files.Rider; c: Chunk;
BEGIN
  f := Files.New(name);
  IF f = NIL THEN SetError("cannot write ", name); RETURN FALSE END;
  Files.Set(w, f, 0); c := r.body;
  WHILE c # NIL DO Files.WriteBytes(w, c.data, c.len); c := c.next END;
  Files.Register(f); RETURN TRUE
END Save;

(* makes the directory path and those above it; the new ones for the owner only (0700) *)
PROCEDURE MakeDirs(VAR path: ARRAY OF CHAR);
VAR p: ARRAY PathLen OF CHAR; i: LONGINT; res: INTEGER;
BEGIN
  i := 1;
  WHILE path[i - 1] # 0X DO
    IF (path[i] = "/") OR (path[i] = 0X) THEN
      COPY(path, p); p[i] := 0X; NetHost.CreateDirectory(p, res)  (* new directories are 0700 *)
    END;
    INC(i)
  END
END MakeDirs;

(* ----- trust on first use: $HOME/.gemini_hosts ----- *)

PROCEDURE HostsFile(VAR name: ARRAY OF CHAR);
BEGIN
  Kernel.GetConfig("HOME", name);
  IF name[0] = 0X THEN COPY(".", name) END;
  Append(name, "/.gemini_hosts")
END HostsFile;

(* the key kept for hostport, "" if none *)
PROCEDURE LoadPin(VAR hostport, pin: ARRAY OF CHAR);
VAR name: ARRAY PathLen OF CHAR; b: Bundle; i, k, n: LONGINT;
BEGIN
  pin[0] := 0X; HostsFile(name); NEW(b);
  IF ~TLSCABundle.Load(name, b^) THEN RETURN END;
  i := 0; n := Len(hostport);
  WHILE b.text[i] # 0X DO
    k := 0; WHILE (k < n) & (b.text[i + k] = hostport[k]) DO INC(k) END;
    IF (k = n) & (b.text[i + k] = " ") THEN
      INC(i, k + 1); k := 0;
      WHILE (b.text[i] > " ") & (k < LEN(pin) - 1) DO pin[k] := b.text[i]; INC(i); INC(k) END;
      pin[k] := 0X; RETURN
    END;
    WHILE (b.text[i] # 0X) & (b.text[i] # 0AX) DO INC(i) END;
    IF b.text[i] = 0AX THEN INC(i) END
  END
END LoadPin;

(* adds "hostport pin" to the hosts file *)
PROCEDURE SavePin(VAR hostport, pin: ARRAY OF CHAR);
VAR name: ARRAY PathLen OF CHAR; b: Bundle; line: ARRAY 400 OF CHAR; i, n: LONGINT; ok: BOOLEAN;
BEGIN
  HostsFile(name); NEW(b);
  IF ~TLSCABundle.Load(name, b^) THEN b.len := 0; b.text[0] := 0X END;
  COPY(hostport, line); Append(line, " "); Append(line, pin);
  n := b.len; i := 0;
  WHILE (line[i] # 0X) & (n < TLSCABundle.MaxBundle - 2) DO b.text[n] := line[i]; INC(n); INC(i) END;
  b.text[n] := 0AX; INC(n);
  ok := WriteFile(name, b.text, n, 1A4H)
END SavePin;

(* ----- requests ----- *)

(** the options of a plain request: trust on first use, no identity, 5 redirects, 32 MB *)
PROCEDURE NewOptions*(): Options;
VAR o: Options;
BEGIN
  NEW(o); o.trust := Tofu; o.pin := ""; o.identity := NIL; o.redirects := 5; o.maxBody := 32 * 1024 * 1024;
  RETURN o
END NewOptions;

(* appends n bytes of buf to the body of r *)
PROCEDURE Keep(r: Response; VAR last: Chunk; VAR buf: ARRAY OF CHAR; pos, n, max: LONGINT);
VAR k, i: LONGINT;
BEGIN
  WHILE (n > 0) & (r.length < max) DO
    IF (last = NIL) OR (last.len = ChunkSize) THEN
      IF last = NIL THEN NEW(r.body); last := r.body ELSE NEW(last.next); last := last.next END;
      last.len := 0; last.next := NIL
    END;
    k := ChunkSize - last.len; IF k > n THEN k := n END;
    IF r.length + k > max THEN k := max - r.length END;
    i := 0; WHILE i < k DO last.data[last.len + i] := buf[pos + i]; INC(i) END;
    INC(last.len, k); INC(r.length, k); INC(pos, k); DEC(n, k)
  END
END Keep;

(* the status line in header: status and meta of r; FALSE if it is malformed *)
PROCEDURE Header(r: Response; VAR header: ARRAY OF CHAR): BOOLEAN;
VAR i, j: LONGINT;
BEGIN
  i := 0;
  IF r.protocol = Gemini THEN
    IF (header[0] < "1") OR (header[0] > "6") OR (header[1] < "0") OR (header[1] > "9") THEN RETURN FALSE END;
    r.status := (ORD(header[0]) - ORD("0")) * 10 + ORD(header[1]) - ORD("0"); i := 2
  ELSE
    IF (header[0] < "2") OR (header[0] > "5") THEN RETURN FALSE END;
    r.status := ORD(header[0]) - ORD("0"); i := 1
  END;
  IF header[i] = " " THEN INC(i) END;
  j := 0; WHILE (header[i] # 0X) & (j < LEN(r.meta) - 1) DO r.meta[j] := header[i]; INC(i); INC(j) END;
  r.meta[j] := 0X;
  RETURN TRUE
END Header;

(* reads the answer: the status line, then (a success) the body; spartan: from conn, else s *)
PROCEDURE ReadAnswer(r: Response; conn: Internet.Socket; max: LONGINT): BOOLEAN;
VAR buf: ARRAY 4097 OF CHAR; header: ARRAY MaxMeta + 8 OF CHAR; got, i, hlen: LONGINT; inHeader, ok: BOOLEAN; last: Chunk;
BEGIN
  inHeader := TRUE; hlen := 0; last := NIL;
  LOOP
    IF r.protocol = Gemini THEN ok := TLS13Live.ReadAppMax(s^, buf, 4096, got)
    ELSE got := 0; ok := Internet.ReadBuf(conn, buf, got) & (got > 0)
    END;
    IF ~ok THEN EXIT END;
    i := 0;
    IF inHeader THEN
      WHILE (i < got) & inHeader DO
        IF buf[i] = 0AX THEN inHeader := FALSE
        ELSIF hlen < LEN(header) - 1 THEN header[hlen] := buf[i]; INC(hlen)
        END;
        INC(i)
      END;
      IF ~inHeader THEN
        IF (hlen > 0) & (header[hlen - 1] = 0DX) THEN DEC(hlen) END;
        header[hlen] := 0X;
        IF ~Header(r, header) THEN SetError("a malformed answer: ", header); RETURN FALSE END;
        IF Kind(r) # 2 THEN RETURN TRUE END
      END
    END;
    IF ~inHeader & (i < got) THEN Keep(r, last, buf, i, got - i, max) END
  END;
  IF inHeader THEN SetError("no answer", ""); RETURN FALSE END;
  IF r.protocol = Gemini THEN r.complete := s.closeNotify ELSE r.complete := TRUE END;
  RETURN TRUE
END ReadAnswer;

(* one Gemini request: the line req to host, port; the answer in r *)
PROCEDURE GeminiRequest(VAR host, port, req: ARRAY OF CHAR; o: Options; r: Response): BOOLEAN;
VAR hostport, pin, want: ARRAY 400 OF CHAR; ok: BOOLEAN;
BEGIN
  COPY(host, hostport); Append(hostport, ":"); Append(hostport, port);
  pin := ""; IF o.trust = Tofu THEN LoadPin(hostport, pin) END;
  IF s = NIL THEN NEW(s); TLS13Live.Init(s^) END;
  TLS13Live.SetIdentity(o.identity);
  ok := TLS13Live.ConnectPinned(host, port, s^, pin);
  TLS13Live.SetIdentity(NIL);
  IF ~ok THEN SetError("no connection: ", TLS13Live.lastError); RETURN FALSE END;
  COPY(TLS13Live.certPin, r.certPin); COPY(TLS13Live.keyPin, r.keyPin); r.identitySent := TLS13Live.identitySent;
  IF o.trust = Pin THEN
    Normalize(o.pin, want);
    IF want # TLS13Live.certPin THEN
      TLS13Live.Disconnect(s^); SetError("the certificate is not the pinned one: ", r.certPin); RETURN FALSE
    END
  ELSIF (o.trust = Tofu) & TLS13Live.pinned & (pin[0] = 0X) THEN
    SavePin(hostport, TLS13Live.keyPin); r.firstUse := TRUE
  END;
  IF ~TLS13Live.WriteAppString(s^, req) THEN TLS13Live.Disconnect(s^); SetError("the request could not be sent", ""); RETURN FALSE END;
  ok := ReadAnswer(r, 0, o.maxBody);
  TLS13Live.Disconnect(s^);
  RETURN ok
END GeminiRequest;

(* one Spartan request for path to host, port with the data input; the answer in r *)
PROCEDURE SpartanRequest(VAR host, port, path, input: ARRAY OF CHAR; o: Options; r: Response): BOOLEAN;
VAR conn: Internet.Socket; req: ARRAY MaxURL + 300 OF CHAR; n: LONGINT; ok: BOOLEAN;
BEGIN
  IF ~Internet.Connect(host, port, conn) THEN SetError("no connection to ", host); RETURN FALSE END;
  n := Len(input);
  COPY(host, req); Append(req, " "); Append(req, path); Append(req, " "); AppendInt(req, n);
  Append(req, " "); req[Len(req) - 1] := 0DX; Append(req, " "); req[Len(req) - 1] := 0AX;
  ok := Internet.WriteBytes(conn, req, Len(req));
  IF ok & (n > 0) THEN ok := Internet.WriteBytes(conn, input, n) END;
  IF ~ok THEN Internet.Disconnect(conn); SetError("the request could not be sent", ""); RETURN FALSE END;
  ok := ReadAnswer(r, conn, o.maxBody);
  Internet.Disconnect(conn);
  RETURN ok
END SpartanRequest;

(** one request for url (no redirect followed), with the input (Gemini: the query, replacing one
  in url; Spartan: the data), "" for none; o: NIL for NewOptions(); FALSE (lastError says why) if
  there is no answer, else r has it, whatever its status *)
PROCEDURE Request*(url, input: ARRAY OF CHAR; o: Options; VAR r: Response): BOOLEAN;
VAR host, port, path: ARRAY MaxURL OF CHAR; req, enc: ARRAY 3200 OF CHAR; i: LONGINT;
BEGIN
  lastError := "";
  IF o = NIL THEN o := NewOptions() END;
  NEW(r); COPY(url, r.url); r.protocol := Protocol(url); r.status := 0; r.meta := ""; r.body := NIL; r.length := 0;
  r.complete := FALSE; r.certPin := ""; r.keyPin := ""; r.firstUse := FALSE; r.identitySent := FALSE;
  IF ~Split(r.url, host, port, path) THEN SetError("not a gemini:// or spartan:// URL: ", url); RETURN FALSE END;
  IF r.protocol = Spartan THEN RETURN SpartanRequest(host, port, path, input, o, r) END;
  COPY(r.url, req);
  i := 0; WHILE (req[i] # 0X) & (req[i] # "#") DO INC(i) END; req[i] := 0X;
  IF input[0] # 0X THEN
    i := 0; WHILE (req[i] # 0X) & (req[i] # "?") DO INC(i) END; req[i] := 0X;
    Encode(input, enc); Append(req, "?"); Append(req, enc)
  END;
  IF Len(req) > 1024 THEN SetError("the request is longer than the 1024 bytes Gemini allows", ""); RETURN FALSE END;
  COPY(req, r.url);
  i := Len(req); req[i] := 0DX; req[i + 1] := 0AX; req[i + 2] := 0X;
  RETURN GeminiRequest(host, port, req, o, r)
END Request;

(** Request, following redirects (3x) to Gemini or Spartan URLs, at most o.redirects; r.url is the
  URL of the last request *)
PROCEDURE Fetch*(url, input: ARRAY OF CHAR; o: Options; VAR r: Response): BOOLEAN;
VAR next: ARRAY MaxURL OF CHAR; n: LONGINT;
BEGIN
  IF o = NIL THEN o := NewOptions() END;
  n := 0;
  WHILE Request(url, input, o, r) DO
    IF Kind(r) # 3 THEN RETURN TRUE END;
    INC(n);
    IF n > o.redirects THEN SetError("too many redirects", ""); RETURN FALSE END;
    IF ~Resolve(r.url, r.meta, next) OR (Protocol(next) = 0) THEN SetError("a redirect away from Gemini and Spartan: ", r.meta); RETURN FALSE END;
    COPY(next, url); input[0] := 0X
  END;
  RETURN FALSE
END Fetch;

(** fp := the SHA-256 of the certificate of the server of url (a Gemini URL), whatever it is *)
PROCEDURE Fingerprint*(url: ARRAY OF CHAR; VAR fp: ARRAY OF CHAR): BOOLEAN;
VAR host, port, path: ARRAY MaxURL OF CHAR; ok: BOOLEAN;
BEGIN
  fp[0] := 0X; lastError := "";
  IF (Protocol(url) # Gemini) OR ~Split(url, host, port, path) THEN SetError("not a gemini:// URL: ", url); RETURN FALSE END;
  IF s = NIL THEN NEW(s); TLS13Live.Init(s^) END;
  TLS13Live.SetIdentity(NIL);
  ok := TLS13Live.ConnectPinned(host, port, s^, "");
  IF ~ok THEN SetError("no connection: ", TLS13Live.lastError); RETURN FALSE END;
  COPY(TLS13Live.certPin, fp); TLS13Live.Disconnect(s^);
  RETURN TRUE
END Fingerprint;

(* ----- identities ----- *)

(** dir := the identities directory: $XDG_CONFIG_HOME/dcs/idents, or $HOME/.config/dcs/idents *)
PROCEDURE IdentsDir*(VAR dir: ARRAY OF CHAR);
BEGIN
  Kernel.GetConfig("XDG_CONFIG_HOME", dir);
  IF dir[0] # "/" THEN Kernel.GetConfig("HOME", dir); Append(dir, "/.config") END;
  Append(dir, "/dcs/idents")
END IdentsDir;

(* the value of the attribute with the OID oid (DER bytes) in the Name der, or "" *)
PROCEDURE Attribute(VAR der: TLSBytes.Buffer; oid: ARRAY OF CHAR; olen: LONGINT; VAR value: ARRAY OF CHAR);
VAR pos, lim, spos, slim, apos, alim, i: LONGINT; t, v: TLSASN1.TLV; ok: BOOLEAN;
BEGIN
  value[0] := 0X; pos := 0;
  IF ~TLSASN1.EnterSequence(der, pos, der.len, pos, lim) THEN RETURN END;
  WHILE TLSASN1.EnterSet(der, pos, lim, spos, slim) DO
    WHILE TLSASN1.EnterSequence(der, spos, slim, apos, alim) DO
      IF TLSASN1.ReadTLV(der, apos, alim, t) & (t.tag = TLSASN1.ObjectIdentifier) & (t.len = olen) & TLSASN1.ReadTLV(der, apos, alim, v) THEN
        i := 0; ok := TRUE; WHILE i < olen DO IF der.data[t.val + i] # oid[i] THEN ok := FALSE END; INC(i) END;
        IF ok THEN
          i := 0; WHILE (i < v.len) & (i < LEN(value) - 1) DO value[i] := der.data[v.val + i]; INC(i) END;
          value[i] := 0X; RETURN
        END
      END;
      spos := alim
    END;
    pos := slim
  END
END Attribute;

PROCEDURE Two(VAR a: ARRAY OF CHAR; x: LONGINT);
BEGIN IF x < 10 THEN Append(a, "0") END; AppendInt(a, x)
END Two;

(** cn, mail, notAfter of the identity, from its certificate; FALSE if it cannot be read *)
PROCEDURE ReadDetails*(id: Ident): BOOLEAN;
VAR b: Bundle; der: TLSBytes.Buffer; from: LONGINT; info: Cert; t1, t2: TLSX509Validity.Time; oid: ARRAY 12 OF CHAR;
BEGIN
  id.cn := ""; id.mail := ""; id.notAfter := "";
  NEW(b); NEW(info); from := 0;
  IF ~TLSCABundle.Load(id.cert, b^) OR ~TLSPEM.NextCertificateDER(b.text, from, der) OR ~TLSX509.ParseCertificate(der, info^) THEN RETURN FALSE END;
  oid[0] := 55X; oid[1] := 4X; oid[2] := 3X; Attribute(info.subject, oid, 3, id.cn);  (* 2.5.4.3 *)
  oid[0] := 2AX; oid[1] := 86X; oid[2] := 48X; oid[3] := 86X; oid[4] := 0F7X; oid[5] := 0DX; oid[6] := 1X; oid[7] := 9X; oid[8] := 1X;
  Attribute(info.subject, oid, 9, id.mail);  (* 1.2.840.113549.1.9.1 emailAddress *)
  IF TLSX509Validity.ExtractValidity(info^, t1, t2) & (t2.year > 0) THEN
    AppendInt(id.notAfter, t2.year); Append(id.notAfter, "-"); Two(id.notAfter, t2.month); Append(id.notAfter, "-"); Two(id.notAfter, t2.day)
  END;
  RETURN TRUE
END ReadDetails;

PROCEDURE Collect(name: ARRAY OF CHAR; time, date, size: LONGINT; attr: SET; VAR continue: BOOLEAN);
VAR id: Ident; k: LONGINT;
BEGIN
  k := Len(name);
  IF (k > 4) & (name[k - 4] = ".") & (name[k - 3] = "c") & (name[k - 2] = "r") & (name[k - 1] = "t") THEN
    NEW(id); COPY(name, id.cert); id.next := crtNames; crtNames := id  (* the name for now *)
  END
END Collect;

(** the identities in dir (IdentsDir): every <name>.crt with a <name>.key beside it, sorted by name *)
PROCEDURE LoadIdents*(VAR dir: ARRAY OF CHAR): Ident;
VAR k: LONGINT; res: LONGINT; name: ARRAY NameLen OF CHAR; list, id, p, q, next: Ident; key, pat: ARRAY PathLen OF CHAR;
BEGIN
  list := NIL; crtNames := NIL;
  COPY(dir, pat); Append(pat, "/"); NetHost.Enumerate(pat, Collect, res);
  id := crtNames; crtNames := NIL;
  WHILE id # NIL DO
    next := id.next; COPY(id.cert, name); k := Len(name);
    COPY(dir, id.cert); Append(id.cert, "/"); Append(id.cert, name);
    COPY(id.cert, key); key[Len(key) - 3] := "k"; key[Len(key) - 2] := "e"; key[Len(key) - 1] := "y";
    IF Exists(key) THEN
      COPY(key, id.key); name[k - 4] := 0X; COPY(name, id.fingerprint);
      k := 0; WHILE id.fingerprint[k] # 0X DO id.fingerprint[k] := Lower(id.fingerprint[k]); INC(k) END;
      IF ReadDetails(id) THEN END;
      IF (list = NIL) OR (id.fingerprint < list.fingerprint) THEN id.next := list; list := id
      ELSE p := list; q := list.next; WHILE (q # NIL) & (q.fingerprint < id.fingerprint) DO p := q; q := q.next END; id.next := q; p.next := id
      END
    END;
    id := next
  END;
  RETURN list
END LoadIdents;

(* does id match query in the way kind: 0 fingerprint prefix, 1 common name, 2 mail, 3 part of either *)
PROCEDURE Matches(id: Ident; VAR query: ARRAY OF CHAR; kind: LONGINT): BOOLEAN;
BEGIN
  CASE kind OF
    0: RETURN StartsWith(id.fingerprint, query)
  | 1: RETURN (id.cn[0] # 0X) & Same(id.cn, query)
  | 2: RETURN (id.mail[0] # 0X) & Same(id.mail, query)
  | 3: RETURN Contains(id.cn, query) OR Contains(id.mail, query)
  END;
  RETURN FALSE
END Matches;

(** the identity of list that query names: the first kind of match that finds any decides, from a
  prefix of the fingerprint, the common name, the mail address, to a part of either; NIL if none
  or several match (candidates, nCandidates: the matches, to show) *)
PROCEDURE FindIdent*(list: Ident; query: ARRAY OF CHAR): Ident;
VAR kind: LONGINT; id: Ident;
BEGIN
  nCandidates := 0;
  IF query[0] = 0X THEN RETURN NIL END;
  kind := 0;
  WHILE kind <= 3 DO
    nCandidates := 0; id := list;
    WHILE id # NIL DO
      IF Matches(id, query, kind) & (nCandidates < MaxCandidates) THEN candidates[nCandidates] := id; INC(nCandidates) END;
      id := id.next
    END;
    IF nCandidates = 1 THEN RETURN candidates[0] ELSIF nCandidates > 1 THEN RETURN NIL END;
    INC(kind)
  END;
  RETURN NIL
END FindIdent;

(** id := a new identity in dir: a self-signed certificate for cn (and mail, if not ""), valid
  for years, with a new P-256 key, as <fingerprint>.crt and .key (only for the owner) *)
PROCEDURE NewIdent*(VAR dir: ARRAY OF CHAR; cn, mail: ARRAY OF CHAR; years: LONGINT; VAR id: Ident): BOOLEAN;
VAR certPEM, keyPEM: ARRAY 4096 OF CHAR; der: TLSBytes.Buffer; from, i: LONGINT; d: TLSSHA256.Digest; hex: ARRAY 17 OF CHAR;
BEGIN
  id := NIL; lastError := "";
  IF ~TLSCertGen.SelfSigned(cn, mail, "", years, certPEM, keyPEM) THEN SetError("", TLSCertGen.lastError); RETURN FALSE END;
  from := 0;
  IF ~TLSPEM.NextCertificateDER(certPEM, from, der) THEN SetError("the new certificate cannot be read", ""); RETURN FALSE END;
  NEW(id); TLSSHA256.DigestBuffer(der, d); hex := "0123456789abcdef";
  i := 0; WHILE i < 32 DO id.fingerprint[2 * i] := hex[ORD(d[i]) DIV 16]; id.fingerprint[2 * i + 1] := hex[ORD(d[i]) MOD 16]; INC(i) END;
  id.fingerprint[64] := 0X;
  MakeDirs(dir);
  COPY(dir, id.cert); Append(id.cert, "/"); Append(id.cert, id.fingerprint); COPY(id.cert, id.key);
  Append(id.cert, ".crt"); Append(id.key, ".key");
  IF ~WriteFile(id.key, keyPEM, Len(keyPEM), 180H) OR ~WriteFile(id.cert, certPEM, Len(certPEM), 1A4H) THEN  (* 0600, 0644 *)
    SetError("cannot write the identity in ", dir); id := NIL; RETURN FALSE
  END;
  i := 0; WHILE i < LEN(keyPEM) DO keyPEM[i] := 0X; INC(i) END;
  IF ReadDetails(id) THEN END;
  RETURN TRUE
END NewIdent;

(** the identity (TLSIdentity) of the files cert and key, for Options.identity; NIL (lastError)
  if they cannot be read *)
PROCEDURE LoadIdentity*(cert, key: ARRAY OF CHAR): TLSIdentity.Identity;
VAR id: TLSIdentity.Identity;
BEGIN
  IF TLSIdentity.Load(cert, key, id) THEN RETURN id END;
  SetError("", TLSIdentity.lastError); RETURN NIL
END LoadIdentity;

BEGIN
  s := NIL; lastError := ""; nCandidates := 0
END Gemini0.
