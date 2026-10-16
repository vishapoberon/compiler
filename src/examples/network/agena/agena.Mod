MODULE agena;  (** a Gemini server (gemini://, port 1965) over the TLS 1.3 of src/lib/tls *)

(* agena.Serve dir cert.pem key.pem [port] [/listen addr]... [/host name] [/n count] [/queue n] [/timeout s]
   agena.Serve /config file.toml [port] [/listen addr]... [/n count] [/queue n] [/timeout s]
   serves the files below dir, or those of several servers (virtual hosts) of a configuration
   file: each with its name, certificate, key, directory (root) and index file; the host name
   a client asks for in the handshake (SNI) chooses the server and its certificate, and the host
   of the URL must be that server's. Names may be written in UTF-8 (սոնա.հայ): they are compared
   as clients send them, in punycode (xn--y9a5bft.xn--y9a3aq). [types] of the file adds or
   changes the types of extensions (mp3 = "audio/mpeg"). agena.Help shows an example.
   It listens on every address, IPv4 and IPv6 (one IPv6 socket that also takes IPv4), or on
   those of listen = [...] in the file or of /listen: an IPv4 or IPv6 address (in brackets when a
   port follows), * for any, each with :port or the port of the server; the clients of all of
   them are served one after the other. A request is a URL and CR LF; the answer a status line ("20
   text/gemini", "51 not found", ...) and, for 20, the file. A directory gives its index.gmi, or
   a list of its files when it has none; a directory named without a slash at the end is
   redirected (31) to the name with it. Names starting with a dot, and .. in a path, are not
   served. /host refuses (53) requests for other hosts; /n ends after count connections (tests).
   One connection at a time, each with a timeout (10 seconds); connections that arrive meanwhile
   wait in the queue of the listening socket (16). agena.SetQueueLen n and agena.SetTimeout s
   change them for the next Serve of this loksh (the shell, the desktop), /queue and /timeout
   for one Serve. Ctrl+C stops the server and closes its socket.
   The certificate must have an ECDSA P-256 key (TLS13Server); agena.Help shows how to make one. *)

(* VOC port: no FATFiles stack; use native host metadata and VOC command cleanup. *)
IMPORT SYSTEM, Linux0 := unixNet, Files, NetHost, Sockets, TLSBytes, TLS13Live, TLS13Server, TOML, Texts := PortArgs, out := Out, Oberon;

CONST
  DefaultPort = 1965;
  MaxRequest = 1024;      (* the URL, without CR LF (the Gemini specification) *)
  DefaultTimeout = 10;    (* s *)
  DefaultQueue = 16;
  Chunk = 16384;
  NameLen = 256;
  PathLen = 1024;
  MaxConfig = 65536;
  MaxListen = 16;

TYPE
  State = POINTER TO TLS13Live.State;  (* 300 KB: on the heap *)
  Entry = POINTER TO EntryDesc;
  EntryDesc = RECORD name: ARRAY NameLen OF CHAR; dir: BOOLEAN; next: Entry END;
  Host = POINTER TO HostDesc;  (* a server *)
  HostDesc = RECORD
    name: ARRAY NameLen OF CHAR;   (* in ASCII (punycode), lower case; "" for any (agena.Serve dir) *)
    root: ARRAY PathLen OF CHAR;
    index: ARRAY 64 OF CHAR;
    id: TLS13Server.Identity;
    next: Host
  END;
  Type = POINTER TO TypeDesc;  (* of [types] *)
  TypeDesc = RECORD ext: ARRAY 32 OF CHAR; mime: ARRAY 128 OF CHAR; next: Type END;
  Text = POINTER TO ARRAY MaxConfig OF CHAR;

VAR
  listeners: ARRAY MaxListen OF Sockets.Socket; nListen: LONGINT;
  specs: ARRAY MaxListen OF ARRAY 64 OF CHAR; nSpecs: LONGINT;  (* the addresses to listen on *)
  s: State;               (* the connection being served *)
  hosts: Host;            (* the servers, the first one for clients that name none *)
  entries: Entry;         (* the entries of a directory Collect gathers *)
  current: Host;          (* the server of the connection *)
  byName: BOOLEAN;        (* several servers, chosen by the host name *)
  types: Type;
  queueLen, timeout: LONGINT;  (* the settings: the listen queue, seconds per connection *)

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

PROCEDURE Lower(c: CHAR): CHAR;
BEGIN
  IF (c >= "A") & (c <= "Z") THEN RETURN CHR(ORD(c) + 32) END;
  RETURN c
END Lower;

(* a = b, ignoring the case of letters *)
PROCEDURE SameName(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (a[i] # 0X) & (Lower(a[i]) = Lower(b[i])) DO INC(i) END;
  RETURN Lower(a[i]) = Lower(b[i])
END SameName;

(* does a end with b (b in lower case), ignoring case? *)
PROCEDURE EndsWith(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR): BOOLEAN;
VAR i, j: LONGINT;
BEGIN
  i := Len(a); j := Len(b);
  IF j > i THEN RETURN FALSE END;
  WHILE (j > 0) & (Lower(a[i - 1]) = b[j - 1]) DO DEC(i); DEC(j) END;
  RETURN j = 0
END EndsWith;

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF (c >= "0") & (c <= "9") THEN RETURN ORD(c) - ORD("0")
  ELSIF (c >= "a") & (c <= "f") THEN RETURN ORD(c) - ORD("a") + 10
  ELSIF (c >= "A") & (c <= "F") THEN RETURN ORD(c) - ORD("A") + 10
  END;
  RETURN -1
END Hex;

(* name, %-encoded for a link: letters, digits and - . _ ~ / stay *)
PROCEDURE Encode(VAR name, enc: ARRAY OF CHAR);
VAR i, j: LONGINT; c: CHAR; hex: ARRAY 17 OF CHAR;
BEGIN
  hex := "0123456789ABCDEF"; i := 0; j := 0;
  WHILE (name[i] # 0X) & (j < LEN(enc) - 4) DO
    c := name[i];
    IF (c >= "a") & (c <= "z") OR (c >= "A") & (c <= "Z") OR (c >= "0") & (c <= "9") OR
       (c = "-") OR (c = ".") OR (c = "_") OR (c = "~") OR (c = "/") THEN
      enc[j] := c; INC(j)
    ELSE
      enc[j] := "%"; enc[j + 1] := hex[ORD(c) DIV 16]; enc[j + 2] := hex[ORD(c) MOD 16]; INC(j, 3)
    END;
    INC(i)
  END;
  enc[j] := 0X
END Encode;

(* ----- host names ----- *)

PROCEDURE Digit(d: LONGINT): CHAR;
BEGIN
  IF d < 26 THEN RETURN CHR(ORD("a") + d) END;
  RETURN CHR(ORD("0") + d - 26)
END Digit;

PROCEDURE Adapt(delta, points: LONGINT; first: BOOLEAN): LONGINT;
VAR k: LONGINT;
BEGIN
  IF first THEN delta := delta DIV 700 ELSE delta := delta DIV 2 END;
  delta := delta + delta DIV points; k := 0;
  WHILE delta > 455 DO delta := delta DIV 35; INC(k, 36) END;  (* (36 - 1) * 26 DIV 2 *)
  RETURN k + 36 * delta DIV (delta + 38)
END Adapt;

(* appends to out the punycode (RFC 3492) of the code points cp[0..n) *)
PROCEDURE Punycode(VAR cp: ARRAY OF LONGINT; n: LONGINT; VAR out: ARRAY OF CHAR);
VAR i, j, b, h, m, c, delta, bias, q, k, t: LONGINT;
BEGIN
  j := Len(out); b := 0; i := 0;
  WHILE i < n DO IF cp[i] < 128 THEN out[j] := CHR(cp[i]); INC(j); INC(b) END; INC(i) END;
  IF b > 0 THEN out[j] := "-"; INC(j) END;
  c := 128; delta := 0; bias := 72; h := b;
  WHILE (h < n) & (j < LEN(out) - 8) DO
    m := MAX(LONGINT); i := 0;
    WHILE i < n DO IF (cp[i] >= c) & (cp[i] < m) THEN m := cp[i] END; INC(i) END;
    delta := delta + (m - c) * (h + 1); c := m; i := 0;
    WHILE i < n DO
      IF cp[i] < c THEN INC(delta)
      ELSIF cp[i] = c THEN
        q := delta; k := 36;
        LOOP
          IF k <= bias THEN t := 1 ELSIF k >= bias + 26 THEN t := 26 ELSE t := k - bias END;
          IF q < t THEN EXIT END;
          IF j < LEN(out) - 1 THEN out[j] := Digit(t + (q - t) MOD (36 - t)); INC(j) END;
          q := (q - t) DIV (36 - t); INC(k, 36)
        END;
        IF j < LEN(out) - 1 THEN out[j] := Digit(q); INC(j) END;
        bias := Adapt(delta, h + 1, h = b); delta := 0; INC(h)
      END;
      INC(i)
    END;
    INC(delta); INC(c)
  END;
  out[j] := 0X
END Punycode;

(** out := the host name in (UTF-8) as clients send it: labels with letters beyond ASCII in
  punycode (xn--...), in lower case (ASCII and Armenian capitals are lowered) *)
PROCEDURE ToASCII*(VAR in, out: ARRAY OF CHAR);
VAR cp: ARRAY 64 OF LONGINT; i, n, c, k: LONGINT; ascii: BOOLEAN; label: ARRAY 256 OF CHAR;
BEGIN
  out[0] := 0X; i := 0;
  LOOP
    n := 0; ascii := TRUE;
    WHILE (in[i] # 0X) & (in[i] # ".") DO
      c := ORD(in[i]); INC(i); k := 0;
      IF c >= 0F0H THEN c := c MOD 8; k := 3 ELSIF c >= 0E0H THEN c := c MOD 16; k := 2
      ELSIF c >= 0C0H THEN c := c MOD 32; k := 1
      END;
      WHILE (k > 0) & (ORD(in[i]) >= 80H) & (ORD(in[i]) < 0C0H) DO c := c * 64 + ORD(in[i]) MOD 64; INC(i); DEC(k) END;
      IF (c >= ORD("A")) & (c <= ORD("Z")) THEN INC(c, 20H)
      ELSIF (c >= 531H) & (c <= 556H) THEN INC(c, 30H)  (* Armenian capitals *)
      END;
      IF c >= 128 THEN ascii := FALSE END;
      IF n < LEN(cp) THEN cp[n] := c; INC(n) END
    END;
    label := "";
    IF ascii THEN k := 0; WHILE k < n DO label[k] := CHR(cp[k]); INC(k) END; label[n] := 0X
    ELSE label := "xn--"; Punycode(cp, n, label)
    END;
    Append(out, label);
    IF in[i] # "." THEN EXIT END;
    Append(out, "."); INC(i)
  END
END ToASCII;

(* the server named name (ASCII), NIL if none *)
PROCEDURE FindHost(VAR name: ARRAY OF CHAR): Host;
VAR h: Host;
BEGIN
  h := hosts; WHILE (h # NIL) & (h.name # name) DO h := h.next END;
  RETURN h
END FindHost;

(* the certificate for the host name of the handshake (TLS13Server.Chooser) *)
PROCEDURE Choose(VAR name: ARRAY OF CHAR): TLS13Server.Identity;
BEGIN
  IF ~byName OR (name[0] = 0X) THEN current := hosts ELSE current := FindHost(name) END;
  IF current = NIL THEN RETURN NIL END;
  RETURN current.id
END Choose;

(* ----- answers ----- *)

PROCEDURE Send(str: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN TLS13Live.WriteAppString(s^, str)
END Send;

(* the status line: status meta CR LF *)
PROCEDURE Status(status: LONGINT; meta: ARRAY OF CHAR): BOOLEAN;
VAR line: ARRAY 1100 OF CHAR; n: LONGINT;
BEGIN
  line[0] := CHR(status DIV 10 + ORD("0")); line[1] := CHR(status MOD 10 + ORD("0")); line[2] := " "; line[3] := 0X;
  Append(line, meta); n := Len(line);
  line[n] := 0DX; line[n + 1] := 0AX; line[n + 2] := 0X;
  RETURN Send(line)
END Status;

PROCEDURE MimeType(VAR name, mime: ARRAY OF CHAR);
VAR t: Type; ext: ARRAY 34 OF CHAR;
BEGIN
  t := types;
  WHILE t # NIL DO
    ext := "."; Append(ext, t.ext);
    IF EndsWith(name, ext) THEN COPY(t.mime, mime); RETURN END;
    t := t.next
  END;
  IF EndsWith(name, ".gmi") OR EndsWith(name, ".gemini") THEN COPY("text/gemini; charset=utf-8", mime)
  ELSIF EndsWith(name, ".txt") OR EndsWith(name, ".mod") THEN COPY("text/plain; charset=utf-8", mime)
  ELSIF EndsWith(name, ".md") THEN COPY("text/markdown; charset=utf-8", mime)
  ELSIF EndsWith(name, ".html") OR EndsWith(name, ".htm") THEN COPY("text/html; charset=utf-8", mime)
  ELSIF EndsWith(name, ".xml") OR EndsWith(name, ".atom") THEN COPY("application/xml", mime)
  ELSIF EndsWith(name, ".png") THEN COPY("image/png", mime)
  ELSIF EndsWith(name, ".jpg") OR EndsWith(name, ".jpeg") THEN COPY("image/jpeg", mime)
  ELSIF EndsWith(name, ".gif") THEN COPY("image/gif", mime)
  ELSIF EndsWith(name, ".svg") THEN COPY("image/svg+xml", mime)
  ELSIF EndsWith(name, ".pdf") THEN COPY("application/pdf", mime)
  ELSIF EndsWith(name, ".gz") THEN COPY("application/gzip", mime)
  ELSIF EndsWith(name, ".zip") THEN COPY("application/zip", mime)
  ELSE COPY("application/octet-stream", mime)
  END
END MimeType;

(* the file f, after "20 mime"; its descriptor is closed after *)
PROCEDURE SendFile(f: Files.File; VAR name: ARRAY OF CHAR): BOOLEAN;
VAR b: TLSBytes.Buffer; r: Files.Rider; n, k: LONGINT; mime: ARRAY 64 OF CHAR; ok: BOOLEAN;
BEGIN
  MimeType(name, mime); ok := Status(20, mime);
  n := Files.Length(f); Files.Set(r, f, 0);
  WHILE ok & (n > 0) DO
    k := n; IF k > Chunk THEN k := Chunk END;
    Files.ReadBytes(r, b.data, k); b.len := k; ok := TLS13Live.WriteAppBuffer(s^, b); DEC(n, k)
  END;
  Files.Close(f);
  RETURN ok
END SendFile;

PROCEDURE Collect(name: ARRAY OF CHAR; time, date, size: LONGINT; attr: SET; VAR continue: BOOLEAN);
VAR e, p, q: Entry;
BEGIN
  IF name[0] # "." THEN
    NEW(e); COPY(name, e.name); e.dir := NetHost.SubDir IN attr;
    IF (entries = NIL) OR (e.name < entries.name) THEN e.next := entries; entries := e
    ELSE p := entries; q := entries.next; WHILE (q # NIL) & (q.name < e.name) DO p := q; q := q.next END; e.next := q; p.next := e
    END
  END
END Collect;

(* the entries of the directory dir, sorted, without names starting with a dot *)
PROCEDURE ReadDir(VAR dir: ARRAY OF CHAR; VAR list: Entry);
VAR pat: ARRAY PathLen + 32 OF CHAR; res: LONGINT;
BEGIN
  COPY(dir, pat); IF pat[Len(pat) - 1] # "/" THEN Append(pat, "/") END;
  entries := NIL; NetHost.Enumerate(pat, Collect, res); list := entries; entries := NIL
END ReadDir;

(* a list of the files in the directory path (the URL path, ending with /) *)
PROCEDURE SendList(VAR path: ARRAY OF CHAR; list: Entry): BOOLEAN;
VAR ok: BOOLEAN; nl: ARRAY 2 OF CHAR; enc: ARRAY 3 * NameLen OF CHAR;
BEGIN
  nl[0] := 0AX; nl[1] := 0X;
  ok := Status(20, "text/gemini; charset=utf-8") & Send("# ") & Send(path) & Send(nl) & Send(nl);
  IF path[1] # 0X THEN ok := ok & Send("=> ../ ..") & Send(nl) END;
  WHILE ok & (list # NIL) DO
    Encode(list.name, enc);
    ok := Send("=> ") & Send(enc);
    IF list.dir THEN ok := ok & Send("/") END;
    ok := ok & Send(" ") & Send(list.name);
    IF list.dir THEN ok := ok & Send("/") END;
    ok := ok & Send(nl);
    list := list.next
  END;
  RETURN ok
END SendList;

(* ----- requests ----- *)

(* url := the request, up to CR LF; FALSE if it is longer than MaxRequest or the connection ends *)
PROCEDURE ReadRequest(VAR url: ARRAY OF CHAR): BOOLEAN;
VAR buf: ARRAY MaxRequest + 3 OF CHAR; n, got, i: LONGINT;
BEGIN
  n := 0;
  LOOP
    IF ~TLS13Live.ReadAppMax(s^, buf, MaxRequest + 2 - n, got) THEN RETURN FALSE END;
    i := 0; WHILE i < got DO url[n + i] := buf[i]; INC(i) END;
    INC(n, got); url[n] := 0X;
    IF (n >= 2) & (url[n - 2] = 0DX) & (url[n - 1] = 0AX) THEN url[n - 2] := 0X; RETURN TRUE END;
    IF n >= MaxRequest + 2 THEN url[MaxRequest] := 0X; RETURN FALSE END
  END
END ReadRequest;

(* the host and the %-decoded path of a gemini:// url (without query and fragment);
   status: 0 if fine, else the status for the error *)
PROCEDURE Parse(VAR url, h, path: ARRAY OF CHAR; VAR status: LONGINT);
VAR i, j, a, b: LONGINT;
BEGIN
  status := 0; h[0] := 0X; path[0] := 0X;
  i := 0; WHILE (url[i] # 0X) & (url[i] # ":") & (url[i] # "/") DO INC(i) END;
  IF (url[i] # ":") OR (url[i + 1] # "/") OR (url[i + 2] # "/") THEN status := 59; RETURN END;
  url[i] := 0X;
  IF ~SameName(url, "gemini") THEN url[i] := ":"; status := 53; RETURN END;  (* a proxy request *)
  url[i] := ":"; INC(i, 3); j := 0;
  WHILE (url[i] # 0X) & (url[i] # "/") & (url[i] # ":") & (url[i] # "?") & (url[i] # "#") DO
    IF (url[i] = "%") & (Hex(url[i + 1]) >= 0) & (Hex(url[i + 2]) >= 0) THEN
      IF j < LEN(h) - 1 THEN h[j] := CHR(Hex(url[i + 1]) * 16 + Hex(url[i + 2])); INC(j) END; INC(i, 3)
    ELSE
      IF j < LEN(h) - 1 THEN h[j] := url[i]; INC(j) END; INC(i)
    END
  END;
  h[j] := 0X;
  IF j = 0 THEN status := 59; RETURN END;
  IF url[i] = ":" THEN WHILE (url[i] # 0X) & (url[i] # "/") & (url[i] # "?") & (url[i] # "#") DO INC(i) END END;
  j := 0;
  IF url[i] # "/" THEN path[0] := "/"; j := 1 END;
  WHILE (url[i] # 0X) & (url[i] # "?") & (url[i] # "#") & (j < LEN(path) - 1) DO
    IF url[i] = "%" THEN
      a := Hex(url[i + 1]); IF a >= 0 THEN b := Hex(url[i + 2]) ELSE b := -1 END;
      IF (b < 0) OR (a * 16 + b = 0) THEN status := 59; RETURN END;
      path[j] := CHR(a * 16 + b); INC(i, 3)
    ELSE path[j] := url[i]; INC(i)
    END;
    INC(j)
  END;
  path[j] := 0X;
  (* no hidden names, no .. : a segment may not start with a dot *)
  i := 0;
  WHILE path[i] # 0X DO
    IF (path[i] = "/") & (path[i + 1] = ".") THEN status := 51; RETURN END;
    INC(i)
  END
END Parse;

(* answers the request url; status: the status sent *)
PROCEDURE Answer(VAR url: ARRAY OF CHAR; VAR status: LONGINT);
VAR h, ah: ARRAY 256 OF CHAR; path, file, index, target: ARRAY PathLen + 32 OF CHAR;
  r: LONGINT; list: Entry; ok: BOOLEAN; f: Files.File; full: NetHost.FileName; flags: SET;
BEGIN
  Parse(url, h, path, status);
  IF status = 0 THEN
    ToASCII(h, ah);
    IF byName & (TLS13Server.serverName[0] = 0X) THEN current := FindHost(ah) END;  (* no SNI: by the URL *)
    IF (current = NIL) OR (current.name[0] # 0X) & (current.name # ah) THEN status := 53
    ELSE
      COPY(current.root, file); Append(file, path);
      IF ~NetHost.Exists(file, full, flags) THEN status := 51
      ELSIF NetHost.Directory IN flags THEN
        IF path[Len(path) - 1] # "/" THEN
          status := 31; COPY(url, target);
          r := 0; WHILE (target[r] # 0X) & (target[r] # "?") & (target[r] # "#") DO INC(r) END;
          target[r] := 0X; Append(target, "/"); ok := Status(31, target)
        ELSE
          COPY(file, index); Append(index, current.index);
          IF NetHost.Exists(index, full, flags) & ~(NetHost.Directory IN flags) THEN f := Files.Old(index) ELSE f := NIL END;
          status := 20;
          IF f # NIL THEN ok := SendFile(f, index)
          ELSE ReadDir(file, list); ok := SendList(path, list)
          END
        END
      ELSE
        f := Files.Old(file);
        IF f = NIL THEN status := 51 ELSE status := 20; ok := SendFile(f, file) END
      END
    END
  END;
  IF status = 59 THEN ok := Status(59, "bad request")
  ELSIF status = 53 THEN ok := Status(53, "proxy request refused")
  ELSIF status = 51 THEN ok := Status(51, "not found")
  END
END Answer;

(* ----- the server ----- *)

PROCEDURE Int(VAR a: ARRAY OF CHAR; VAR v: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0; v := 0;
  WHILE (a[i] >= "0") & (a[i] <= "9") & (v < 1000000) DO v := v * 10 + ORD(a[i]) - ORD("0"); INC(i) END;
  RETURN (i > 0) & (a[i] = 0X)
END Int;

PROCEDURE Close;
BEGIN
  IF (s # NIL) & s.connected THEN TLS13Live.Disconnect(s^) END;
  WHILE nListen > 0 DO DEC(nListen); Sockets.Close(listeners[nListen]); listeners[nListen] := NIL END
END Close;

(** listen also on spec in the next Start or StartConfig of this loksh (agena.Serve: /listen, or
  listen = [...] in the file): an IPv4 or IPv6 address, [IPv6]:port, IPv4:port, * or *:port *)
PROCEDURE Listen*(spec: ARRAY OF CHAR);
BEGIN
  IF nSpecs < MaxListen THEN COPY(spec, specs[nSpecs]); INC(nSpecs) END
END Listen;

(* the address a and the port of spec; port: the default *)
PROCEDURE ParseListen(VAR spec: ARRAY OF CHAR; VAR a: Sockets.Address; VAR port: LONGINT): BOOLEAN;
VAR addr, num: ARRAY 64 OF CHAR; i, j, colons: LONGINT;
BEGIN
  i := 0; j := 0; num := "";
  IF spec[0] = "[" THEN  (* [IPv6] or [IPv6]:port *)
    i := 1; WHILE (spec[i] # 0X) & (spec[i] # "]") DO addr[j] := spec[i]; INC(i); INC(j) END;
    addr[j] := 0X;
    IF spec[i] # "]" THEN RETURN FALSE END;
    INC(i);
    IF spec[i] = ":" THEN COPY(spec, num); j := 0; INC(i); WHILE spec[i] # 0X DO num[j] := spec[i]; INC(i); INC(j) END; num[j] := 0X
    ELSIF spec[i] # 0X THEN RETURN FALSE
    END
  ELSE
    colons := 0; WHILE spec[i] # 0X DO IF spec[i] = ":" THEN INC(colons) END; INC(i) END;
    COPY(spec, addr);
    IF colons = 1 THEN  (* IPv4:port or *:port *)
      i := 0; WHILE addr[i] # ":" DO INC(i) END;
      addr[i] := 0X; INC(i); j := 0; WHILE spec[i] # 0X DO num[j] := spec[i]; INC(i); INC(j) END; num[j] := 0X
    END
  END;
  IF num # "" THEN IF ~Int(num, port) OR (port < 1) OR (port > 65535) THEN RETURN FALSE END END;
  IF addr = "*" THEN Sockets.AnyAddress(Sockets.Inet6, a); RETURN TRUE END;
  RETURN Sockets.ParseAddress(addr, a)
END ParseListen;

(* "[a]:port" or "a:port" *)
PROCEDURE ShowAddress(VAR a: Sockets.Address; port: LONGINT);
VAR t: ARRAY 64 OF CHAR;
BEGIN
  Sockets.AddressToString(a, t);
  IF a.family = Sockets.Inet6 THEN out.Char("["); out.String(t); out.Char("]") ELSE out.String(t) END;
  out.Char(":"); out.Int(port, 0)
END ShowAddress;

(* the listening sockets of specs ("*" if none) on port; FALSE (and why) if one cannot be opened *)
PROCEDURE OpenListeners(port, queue: LONGINT): BOOLEAN;
VAR a: Sockets.Address; i, k, p: LONGINT; l: Sockets.Socket;
BEGIN
  IF nSpecs = 0 THEN Listen("*") END;
  i := 0;
  WHILE i < nSpecs DO
    p := port;
    IF ~ParseListen(specs[i], a, p) THEN
      out.String("agena: not an address to listen on: "); out.String(specs[i]); out.Ln; Close; RETURN FALSE
    END;
    l := Sockets.ListenAt(a, p, queue);
    IF l = NIL THEN
      out.String("agena: cannot listen on "); ShowAddress(a, p);
      IF Sockets.res = -98 THEN out.String(": in use (* takes IPv4 and IPv6 already)")
      ELSIF Sockets.res = -99 THEN out.String(": not an address of this machine")
      ELSIF Sockets.res = -13 THEN out.String(": not allowed (a port below 1024 needs root)")
      ELSE out.String(", error "); out.Int(-Sockets.res, 0)
      END;
      out.Ln; Close; RETURN FALSE
    END;
    listeners[nListen] := l; INC(nListen);
    out.String("agena: listening on "); ShowAddress(a, p);
    IF a.family = Sockets.Inet6 THEN  (* the any address :: takes IPv4 too *)
      k := 0; WHILE (k < 16) & (a.addr[k] = 0X) DO INC(k) END;
      IF k = 16 THEN out.String(" (IPv4 and IPv6)") END
    END;
    out.Ln; INC(i)
  END;
  RETURN TRUE
END OpenListeners;

(* the next connection on any of the listening sockets; NIL after an error *)
PROCEDURE NextConnection(VAR peer: Sockets.Address; VAR peerPort: LONGINT): Sockets.Socket;
VAR set: ARRAY 128 OF CHAR; i, n, fd, r: LONGINT;
BEGIN
  IF nListen = 1 THEN RETURN Sockets.Accept(listeners[0], peer, peerPort) END;
  i := 0; WHILE i < LEN(set) DO set[i] := 0X; INC(i) END;
  n := 0; i := 0;
  WHILE i < nListen DO
    fd := listeners[i].fd;
    IF (fd >= 0) & (fd < 1024) THEN set[fd DIV 8] := CHR(ORD(set[fd DIV 8]) + ASH(1, fd MOD 8)); IF fd >= n THEN n := fd + 1 END END;
    INC(i)
  END;
  r := Linux0.Select0(n, SYSTEM.ADR(set[0]), 0, 0, 0);  (* waits without end *)
  IF r <= 0 THEN RETURN NIL END;
  i := 0;
  WHILE i < nListen DO
    fd := listeners[i].fd;
    IF ODD(ASH(ORD(set[fd DIV 8]), -(fd MOD 8))) THEN RETURN Sockets.Accept(listeners[i], peer, peerPort) END;
    INC(i)
  END;
  RETURN NIL
END NextConnection;

PROCEDURE Usage;
BEGIN
  out.String("usage: agena.Serve dir cert.pem key.pem [port] [/listen addr]... [/host name] [/n count] [/queue n] [/timeout s]"); out.Ln;
  out.String("       agena.Serve /config file.toml [port] [/listen addr]... [/n count] [/queue n] [/timeout s]"); out.Ln;
  out.String("  serves the files below dir over Gemini (port 1965); agena.Help tells more"); out.Ln
END Usage;

(* serves the servers of hosts on port: count connections (-1: without end) *)
PROCEDURE Run(port, count, queue, secs: LONGINT);
VAR url: ARRAY MaxRequest + 3 OF CHAR; served, peerPort, status, localPort: LONGINT;
  c: Sockets.Socket; peer, local: Sockets.Address; addr: ARRAY 160 OF CHAR; t: ARRAY 64 OF CHAR; h: Host;
BEGIN
  Close; Oberon.OnStop(Close);
  IF s = NIL THEN NEW(s); TLS13Live.Init(s^) END;
  IF ~OpenListeners(port, queue) THEN nSpecs := 0; RETURN END;
  nSpecs := 0;  (* /listen and Listen are for one run *)
  h := hosts;
  WHILE h # NIL DO
    out.String("agena: serving "); out.String(h.root);
    IF h.name[0] # 0X THEN out.String(" as "); out.String(h.name) END;
    out.Ln; h := h.next
  END;
  served := 0;
  WHILE served # count DO
    c := NextConnection(peer, peerPort);
    IF c # NIL THEN
      INC(served); url[0] := 0X; current := NIL;
      Sockets.AddressToString(peer, addr);
      IF (nListen > 1) & Sockets.LocalAddress(c, local, localPort) THEN  (* the address it came to *)
        Sockets.AddressToString(local, t); Append(addr, " > "); Append(addr, t)
      END;
      Sockets.SetTimeout(c, secs * 1000);
      IF ~TLS13Server.AcceptBy(c.fd, Choose, s^) THEN
        out.String(addr); out.String(" handshake failed: "); out.String(TLS13Server.lastError);
        IF TLS13Server.serverName[0] # 0X THEN out.String(" ("); out.String(TLS13Server.serverName); out.String(")") END
      ELSE
        IF ~ReadRequest(url) THEN
          status := 59; IF Status(59, "bad request") THEN END
        ELSE Answer(url, status)
        END;
        TLS13Live.Disconnect(s^);
        out.String(addr); out.Char(" "); out.Int(status, 0); out.Char(" ");
        IF url[0] = 0X THEN out.Char("-") ELSE out.String(url) END
      END;
      out.Ln
    END
  END;
  Close
END Run;

(* a new server: name in UTF-8 or ASCII ("" for any), the files below root *)
PROCEDURE NewHost(VAR name, root, index, cert, key: ARRAY OF CHAR): BOOLEAN;
VAR h, p: Host;
BEGIN
  NEW(h); ToASCII(name, h.name); COPY(root, h.root); COPY(index, h.index); h.next := NIL;
  WHILE (Len(h.root) > 1) & (h.root[Len(h.root) - 1] = "/") DO h.root[Len(h.root) - 1] := 0X END;
  IF h.index[0] = 0X THEN h.index := "index.gmi" END;
  IF ~TLS13Server.Load(cert, key, h.id) THEN
    out.String("agena: "); out.String(cert); out.String(": "); out.String(TLS13Server.lastError); out.Ln; RETURN FALSE
  END;
  IF hosts = NIL THEN hosts := h ELSE p := hosts; WHILE p.next # NIL DO p := p.next END; p.next := h END;
  RETURN TRUE
END NewHost;

(** serves the files below dir with the certificate in cert and its key in key (PEM files) on
  port, count connections (-1: without end); hostName: the only host answered, "" for any;
  queue: the connections that may wait, secs: the seconds a client may take (0: no limit).
  Ctrl+C stops it. For programs and tests; agena.Serve is the command. *)
PROCEDURE Start*(dir, cert, key, hostName: ARRAY OF CHAR; port, count, queue, secs: LONGINT);
VAR index: ARRAY 4 OF CHAR;
BEGIN
  hosts := NIL; types := NIL; byName := FALSE; index := "";
  IF NewHost(hostName, dir, index, cert, key) THEN Run(port, count, queue, secs) END
END Start;

(* text := the file name; FALSE if it cannot be read or is too long *)
PROCEDURE ReadFile(VAR name: ARRAY OF CHAR; text: Text): BOOLEAN;
VAR f: Files.File; r: Files.Rider; n: LONGINT;
BEGIN
  f := Files.Old(name);
  IF f = NIL THEN RETURN FALSE END;
  n := Files.Length(f);
  IF n >= MaxConfig - 1 THEN Files.Close(f); RETURN FALSE END;
  Files.Set(r, f, 0); Files.ReadBytes(r, text^, n); text[n] := 0X; Files.Close(f);
  RETURN TRUE
END ReadFile;

(* hosts, types, port, queue, secs := those of the configuration file; FALSE (and why) if it is wrong *)
PROCEDURE Configure(VAR file: ARRAY OF CHAR; VAR port, queue, secs: LONGINT): BOOLEAN;
VAR text: Text; doc: TOML.Doc; sec: TOML.Section; f: TOML.Field; it: TOML.Item; t, q: Type; v: LONGINT;
  name, root, index, cert, key: ARRAY PathLen OF CHAR; k: ARRAY 16 OF CHAR;
BEGIN
  hosts := NIL; types := NIL; byName := TRUE;
  NEW(text);
  IF ~ReadFile(file, text) THEN out.String("agena: cannot read "); out.String(file); out.Ln; RETURN FALSE END;
  doc := TOML.Parse(text^);
  IF doc.errors > 0 THEN
    out.String("agena: "); out.String(file); out.Char(":"); out.Int(doc.errorLine, 0); out.String(": ");
    out.String(doc.error); out.Ln; RETURN FALSE
  END;
  k := ""; sec := TOML.GetSection(doc, k);
  IF sec # NIL THEN
    k := "port"; IF TOML.GetField(sec, k, name) & Int(name, v) THEN port := v END;
    k := "queue"; IF TOML.GetField(sec, k, name) & Int(name, v) & (v > 0) THEN queue := v END;
    k := "timeout"; IF TOML.GetField(sec, k, name) & Int(name, v) THEN secs := v END;
    k := "listen"; f := TOML.Find(sec, k);
    IF (f # NIL) & (nSpecs = 0) THEN  (* /listen of the command line wins *)
      IF f.kind = TOML.Array THEN it := f.items; WHILE it # NIL DO Listen(it.value); it := it.next END
      ELSE Listen(f.value)
      END
    END
  END;
  k := "server"; sec := TOML.GetSection(doc, k);
  IF sec = NIL THEN out.String("agena: no [[server]] in "); out.String(file); out.Ln; RETURN FALSE END;
  WHILE sec # NIL DO
    k := "name"; IF ~TOML.GetField(sec, k, name) THEN name := "" END;
    k := "root"; IF ~TOML.GetField(sec, k, root) THEN root := "" END;
    k := "cert"; IF ~TOML.GetField(sec, k, cert) THEN cert := "" END;
    k := "key"; IF ~TOML.GetField(sec, k, key) THEN key := "" END;
    k := "index"; IF ~TOML.GetField(sec, k, index) THEN index := "" END;
    IF (name = "") OR (root = "") OR (cert = "") OR (key = "") THEN
      out.String("agena: a [[server]] needs name, root, cert and key"); out.Ln; RETURN FALSE
    END;
    IF ~NewHost(name, root, index, cert, key) THEN RETURN FALSE END;
    k := "server"; sec := TOML.GetNextSection(sec, k)
  END;
  k := "types"; sec := TOML.GetSection(doc, k);
  IF sec # NIL THEN
    f := sec.first;
    WHILE f # NIL DO
      NEW(t); COPY(f.key, t.ext); COPY(f.value, t.mime); t.next := NIL;
      IF types = NIL THEN types := t ELSE q := types; WHILE q.next # NIL DO q := q.next END; q.next := t END;
      f := f.next
    END
  END;
  RETURN TRUE
END Configure;

(** serves the servers of the configuration file (TOML), count connections (-1: without end);
  port, queue, secs as in Start, unless the file gives them *)
PROCEDURE StartConfig*(file: ARRAY OF CHAR; port, count, queue, secs: LONGINT);
BEGIN
  IF Configure(file, port, queue, secs) THEN Run(port, count, queue, secs) END
END StartConfig;

PROCEDURE Serve*;
VAR
  A: Texts.Reader; arg, dir, cert, key, config: ARRAY PathLen OF CHAR; hostName: ARRAY 256 OF CHAR;
  port, count, queue, secs, p: LONGINT;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, dir) THEN Usage; RETURN END;
  config := "";
  IF dir = "/config" THEN IF ~Texts.Arg(A, config) THEN Usage; RETURN END
  ELSIF ~Texts.Arg(A, cert) OR ~Texts.Arg(A, key) THEN Usage; RETURN
  END;
  port := -1; count := -1; hostName := ""; queue := -1; secs := -1; nSpecs := 0;
  WHILE Texts.Arg(A, arg) DO
    IF (arg = "/host") & (config = "") THEN IF ~Texts.Arg(A, hostName) THEN Usage; RETURN END
    ELSIF arg = "/listen" THEN IF ~Texts.Arg(A, arg) THEN Usage; RETURN END; Listen(arg)
    ELSIF arg = "/n" THEN IF ~Texts.Arg(A, arg) OR ~Int(arg, count) THEN Usage; RETURN END
    ELSIF arg = "/queue" THEN IF ~Texts.Arg(A, arg) OR ~Int(arg, queue) OR (queue < 1) THEN Usage; RETURN END
    ELSIF arg = "/timeout" THEN IF ~Texts.Arg(A, arg) OR ~Int(arg, secs) THEN Usage; RETURN END
    ELSIF ~Int(arg, port) OR (port < 1) OR (port > 65535) THEN Usage; RETURN
    END
  END;
  IF config # "" THEN  (* the options of the command line win over the file *)
    p := DefaultPort; IF queue < 0 THEN queue := queueLen END; IF secs < 0 THEN secs := timeout END;
    IF ~Configure(config, p, queue, secs) THEN nSpecs := 0; RETURN END;
    IF port < 0 THEN port := p END;
    Run(port, count, queue, secs)
  ELSE
    IF port < 0 THEN port := DefaultPort END; IF queue < 0 THEN queue := queueLen END; IF secs < 0 THEN secs := timeout END;
    Start(dir, cert, key, hostName, port, count, queue, secs)
  END
END Serve;

(* n := the number argument of a command; FALSE (and a usage line) if there is none *)
PROCEDURE NumArg(usage: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN;
VAR A: Texts.Reader; arg: ARRAY 32 OF CHAR;
BEGIN
  Texts.OpenArgs(A);
  IF Texts.Arg(A, arg) & Int(arg, n) THEN RETURN TRUE END;
  out.String("usage: agena."); out.String(usage); out.Ln;
  RETURN FALSE
END NumArg;

(** agena.SetQueueLen n: the connections that may wait while one is served, for the next Serve *)
PROCEDURE SetQueueLen*;
VAR n: LONGINT;
BEGIN
  IF NumArg("SetQueueLen n   (connections waiting while one is served)", n) & (n > 0) THEN queueLen := n END;
  out.String("agena: queue "); out.Int(queueLen, 0); out.Ln
END SetQueueLen;

(** agena.SetTimeout s: the seconds a client may take, for the next Serve (0: no limit) *)
PROCEDURE SetTimeout*;
VAR n: LONGINT;
BEGIN
  IF NumArg("SetTimeout s   (seconds a client may take, 0: no limit)", n) THEN timeout := n END;
  out.String("agena: timeout "); out.Int(timeout, 0); out.String(" s"); out.Ln
END SetTimeout;

PROCEDURE Help*;
BEGIN
  out.String("agena, a Gemini server"); out.Ln; out.Ln;
  out.String("  agena.Serve dir cert.pem key.pem [port] [/host name] [/n count] [/queue n] [/timeout s]"); out.Ln;
  out.String("    serves the files below dir to gemini:// clients, on port 1965 by default."); out.Ln;
  out.String("    A directory gives its index.gmi, or a list of its files; names starting with"); out.Ln;
  out.String("    a dot are not served. /host name answers only requests for that host;"); out.Ln;
  out.String("    /n count ends after count connections. Ctrl+C stops the server."); out.Ln;
  out.String("    One client is served at a time; the others wait in a queue (16), each client"); out.Ln;
  out.String("    has 10 seconds. /queue n and /timeout s change them for one Serve;"); out.Ln;
  out.String("    agena.SetQueueLen n and agena.SetTimeout s for the next Serve in this loksh."); out.Ln;
  out.String("    Each request is logged: the client, the status and the URL."); out.Ln; out.Ln;
  out.String("  agena.Serve ... /listen addr   listens on addr instead of every address (IPv4 and"); out.Ln;
  out.String("    IPv6); repeat it for several: 192.0.2.1, 2001:db8::1, [2001:db8::1]:1966, *:1966."); out.Ln; out.Ln;
  out.String("  agena.Serve /config agena.toml [port] [/listen addr]... [/n count] [/queue n] [/timeout s]"); out.Ln;
  out.String("    serves several servers (virtual hosts) on one port; the host name of the"); out.Ln;
  out.String("    handshake (SNI) chooses the server and its certificate, no name the first one."); out.Ln;
  out.String("    agena.toml (names in UTF-8 are fine, index is optional):"); out.Ln; out.Ln;
  out.String("      port = 1965"); out.Ln;
  out.String('      listen = ["*"]   # or ["192.0.2.1", "[2001:db8::1]:1966"]'); out.Ln; out.Ln;
  out.String("      [[server]]"); out.Ln;
  out.String('      name  = "norayr.am"'); out.Ln;
  out.String('      root  = "/srv/gemini/norayr.am/pub"'); out.Ln;
  out.String('      cert  = "/srv/gemini/norayr.am/fullchain.pem"'); out.Ln;
  out.String('      key   = "/srv/gemini/norayr.am/privkey.pem"'); out.Ln;
  out.String('      index = "index.gmi"'); out.Ln; out.Ln;
  out.String("      [[server]]"); out.Ln;
  out.String("      ..."); out.Ln; out.Ln;
  out.String("      [types]"); out.Ln;
  out.String('      mp3 = "audio/mpeg"'); out.Ln;
  out.String('      ogg = "audio/ogg"'); out.Ln; out.Ln;
  out.String("  The certificate needs an ECDSA P-256 key. A self-signed one, as Gemini clients"); out.Ln;
  out.String("  accept it (trust on first use), is made with openssl:"); out.Ln; out.Ln;
  out.String("    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes"); out.Ln;
  out.String("      -keyout key.pem -out cert.pem -days 3650 -subj /CN=example.org"); out.Ln; out.Ln;
  out.String("  Example:"); out.Ln;
  out.String("    loksh agena.Serve /home/me/capsule cert.pem key.pem"); out.Ln;
  out.String("    loksh gemini.Show gemini://localhost/"); out.Ln
END Help;

BEGIN
  s := NIL; queueLen := DefaultQueue; timeout := DefaultTimeout;
  hosts := NIL; current := NIL; types := NIL; byName := FALSE; nListen := 0; nSpecs := 0
END agena.
