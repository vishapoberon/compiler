MODULE cobweb;  (** an HTTP/1.1 server for the files of a directory, plain or over the TLS 1.3 of src/lib/tls *)

(* cobweb.Serve dir [port] [/tls cert.pem key.pem] [/host name] [/n count] [/queue n] [/timeout s]
   serves the files below dir, on port 8080 (plain) or 8443 (/tls) by default. GET and HEAD; one
   request per connection (Connection: close). A directory gives its index.html, or a list of its
   files when it has none; a directory named without a slash at the end is redirected (301) to the
   name with it. Names starting with a dot, and .. in a path, are not served (404). /host answers
   only requests for that host (421 for others); /n ends after count connections (tests).
   One connection at a time, each with a timeout (10 seconds); connections that arrive meanwhile
   wait in the queue of the listening socket (16). cobweb.SetQueueLen n and cobweb.SetTimeout s
   change them for the next Serve of this loksh (the shell, the desktop), /queue and /timeout for
   one Serve. Ctrl+C stops the server and closes its socket.
   The certificate of /tls must have an ECDSA P-256 key (TLS13Server). *)

(* VOC port: native metadata/UTC dates, no FATFiles stack, and VOC command cleanup. *)
IMPORT NetHost, Files, Sockets, TLSBytes, TLS13Live, TLS13Server, Texts := PortArgs, out := Out, Oberon;

CONST
  DefaultPort = 8080; DefaultTLSPort = 8443;
  DefaultTimeout = 10;    (* s *)
  DefaultQueue = 16;
  MaxHead = 8192;         (* the request line and the header fields *)
  Chunk = 16384;
  NameLen = 256;
  PathLen = 1024;

TYPE
  State = POINTER TO TLS13Live.State;  (* 300 KB: on the heap *)
  Entry = POINTER TO EntryDesc;
  EntryDesc = RECORD name: ARRAY NameLen OF CHAR; dir: BOOLEAN; next: Entry END;
  Request = RECORD
    method: ARRAY 16 OF CHAR;
    target: ARRAY PathLen OF CHAR;   (* as sent *)
    path: ARRAY PathLen OF CHAR;     (* %-decoded, without the query *)
    host: ARRAY 256 OF CHAR;         (* of the Host field, without the port *)
    head: BOOLEAN
  END;

VAR
  listener: Sockets.Socket;
  conn: Sockets.Socket;     (* the connection being served (plain) *)
  s: State;                 (* the connection being served (TLS) *)
  tls: BOOLEAN;
  entries: Entry;           (* the entries of a directory Collect gathers *)
  root: ARRAY PathLen OF CHAR;
  listenOn: ARRAY 64 OF CHAR;  (* VOC: optional explicit listen address *)
  host: ARRAY 256 OF CHAR;  (* the host to serve, "" for any *)
  queueLen, timeout: LONGINT;
  ok: BOOLEAN;              (* the client still takes data *)

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
  j := Len(a);
  WHILE (i > 0) & (j < LEN(a) - 1) DO DEC(i); a[j] := d[i]; INC(j) END;
  a[j] := 0X
END AppendInt;

PROCEDURE Lower(c: CHAR): CHAR;
BEGIN
  IF (c >= "A") & (c <= "Z") THEN RETURN CHR(ORD(c) + 32) END;
  RETURN c
END Lower;

PROCEDURE SameName(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (a[i] # 0X) & (Lower(a[i]) = Lower(b[i])) DO INC(i) END;
  RETURN Lower(a[i]) = Lower(b[i])
END SameName;

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

(* name, %-encoded for a link *)
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

(* text with & < > " as HTML entities, appended to b *)
PROCEDURE AppendHTML(VAR b: TLSBytes.Buffer; VAR text: ARRAY OF CHAR);
VAR i: LONGINT; c: CHAR;
BEGIN
  i := 0;
  WHILE text[i] # 0X DO
    c := text[i];
    IF c = "&" THEN TLSBytes.AppendString(b, "&amp;")
    ELSIF c = "<" THEN TLSBytes.AppendString(b, "&lt;")
    ELSIF c = ">" THEN TLSBytes.AppendString(b, "&gt;")
    ELSIF c = 22X THEN TLSBytes.AppendString(b, "&quot;")
    ELSE TLSBytes.AppendChar(b, c)
    END;
    INC(i)
  END
END AppendHTML;

(* ----- the connection: plain or TLS ----- *)

PROCEDURE SendBuffer(VAR b: TLSBytes.Buffer);
BEGIN
  IF ~ok OR (b.len = 0) THEN RETURN END;
  IF tls THEN ok := TLS13Live.WriteAppBuffer(s^, b)
  ELSE ok := Sockets.Send(conn, b.data, b.len) = b.len
  END
END SendBuffer;

(* up to max bytes of the request into buf; n = 0 at the end *)
PROCEDURE Receive(VAR buf: ARRAY OF CHAR; max: LONGINT; VAR n: LONGINT);
BEGIN
  IF tls THEN
    IF ~TLS13Live.ReadAppMax(s^, buf, max, n) THEN n := 0 END
  ELSE
    n := Sockets.Receive(conn, buf, max); IF n < 0 THEN n := 0 END
  END
END Receive;

(* ----- answers ----- *)

PROCEDURE Reason(status: LONGINT; VAR r: ARRAY OF CHAR);
BEGIN
  CASE status OF
    200: COPY("OK", r) | 301: COPY("Moved Permanently", r) | 400: COPY("Bad Request", r)
  | 403: COPY("Forbidden", r) | 404: COPY("Not Found", r) | 405: COPY("Method Not Allowed", r)
  | 414: COPY("URI Too Long", r) | 421: COPY("Misdirected Request", r)
  | 431: COPY("Request Header Fields Too Large", r) | 500: COPY("Internal Server Error", r)
  | 505: COPY("HTTP Version Not Supported", r)
  ELSE COPY("Error", r)
  END
END Reason;

PROCEDURE Field(VAR h: TLSBytes.Buffer; name, value: ARRAY OF CHAR);
BEGIN
  TLSBytes.AppendString(h, name); TLSBytes.AppendString(h, ": "); TLSBytes.AppendString(h, value);
  TLSBytes.AppendChar(h, 0DX); TLSBytes.AppendChar(h, 0AX)
END Field;

PROCEDURE Two(VAR a: ARRAY OF CHAR; x: LONGINT);
BEGIN
  IF x < 10 THEN Append(a, "0") END; AppendInt(a, x)
END Two;

(* the time now, in seconds since 1970 (the clock is UTC) *)
PROCEDURE Now(): LONGINT;
BEGIN RETURN NetHost.Now()
END Now;

(* d := the Unix time t as an HTTP date: Sun, 06 Nov 1994 08:49:37 GMT *)
PROCEDURE HTTPDate(t: LONGINT; VAR d: ARRAY OF CHAR);
VAR date, time, wd: LONGINT; days, months: ARRAY 40 OF CHAR; i: LONGINT;
BEGIN
  days := "ThuFriSatSunMonTueWed"; months := "JanFebMarAprMayJunJulAugSepOctNovDec";
  wd := t DIV 86400 MOD 7;
  NetHost.UTC(t, date, time);
  d[0] := days[wd * 3]; d[1] := days[wd * 3 + 1]; d[2] := days[wd * 3 + 2]; d[3] := 0X;
  Append(d, ", "); Two(d, date MOD 32); Append(d, " ");
  i := Len(d); d[i] := months[(date DIV 32 MOD 16 - 1) * 3]; d[i + 1] := months[(date DIV 32 MOD 16 - 1) * 3 + 1];
  d[i + 2] := months[(date DIV 32 MOD 16 - 1) * 3 + 2]; d[i + 3] := 0X;
  Append(d, " "); AppendInt(d, date DIV 512 + 1900); Append(d, " ");
  Two(d, time DIV 4096); Append(d, ":"); Two(d, time DIV 64 MOD 64); Append(d, ":"); Two(d, time MOD 64);
  Append(d, " GMT")
END HTTPDate;

(* the status line and the fields of an answer with a body of length bytes *)
PROCEDURE Head(status: LONGINT; type: ARRAY OF CHAR; length, mtime: LONGINT; location: ARRAY OF CHAR);
VAR h: TLSBytes.Buffer; r: ARRAY 64 OF CHAR; n: ARRAY 16 OF CHAR; d: ARRAY 40 OF CHAR;
BEGIN
  TLSBytes.Init(h); TLSBytes.AppendString(h, "HTTP/1.1 ");
  n := ""; AppendInt(n, status); TLSBytes.AppendString(h, n); TLSBytes.AppendChar(h, " ");
  Reason(status, r); TLSBytes.AppendString(h, r); TLSBytes.AppendChar(h, 0DX); TLSBytes.AppendChar(h, 0AX);
  Field(h, "Server", "cobweb");
  HTTPDate(Now(), d); Field(h, "Date", d);
  IF mtime > 0 THEN HTTPDate(mtime, d); Field(h, "Last-Modified", d) END;
  IF location[0] # 0X THEN Field(h, "Location", location) END;
  IF status = 405 THEN Field(h, "Allow", "GET, HEAD") END;
  Field(h, "Content-Type", type);
  n := ""; AppendInt(n, length); Field(h, "Content-Length", n);
  Field(h, "Connection", "close");
  TLSBytes.AppendChar(h, 0DX); TLSBytes.AppendChar(h, 0AX);
  SendBuffer(h)
END Head;

(* an answer with a short text body (errors, redirects) *)
PROCEDURE Error(VAR req: Request; status: LONGINT; location: ARRAY OF CHAR);
VAR b: TLSBytes.Buffer; r: ARRAY 64 OF CHAR; n: ARRAY 16 OF CHAR;
BEGIN
  TLSBytes.Init(b); n := ""; AppendInt(n, status); TLSBytes.AppendString(b, n); TLSBytes.AppendChar(b, " ");
  Reason(status, r); TLSBytes.AppendString(b, r); TLSBytes.AppendChar(b, 0AX);
  Head(status, "text/plain; charset=utf-8", b.len, 0, location);
  IF ~req.head THEN SendBuffer(b) END
END Error;

PROCEDURE MimeType(VAR name, mime: ARRAY OF CHAR);
BEGIN
  IF EndsWith(name, ".html") OR EndsWith(name, ".htm") THEN COPY("text/html; charset=utf-8", mime)
  ELSIF EndsWith(name, ".css") THEN COPY("text/css; charset=utf-8", mime)
  ELSIF EndsWith(name, ".js") OR EndsWith(name, ".mjs") THEN COPY("text/javascript; charset=utf-8", mime)
  ELSIF EndsWith(name, ".json") THEN COPY("application/json", mime)
  ELSIF EndsWith(name, ".txt") OR EndsWith(name, ".mod") THEN COPY("text/plain; charset=utf-8", mime)
  ELSIF EndsWith(name, ".md") THEN COPY("text/markdown; charset=utf-8", mime)
  ELSIF EndsWith(name, ".gmi") THEN COPY("text/gemini; charset=utf-8", mime)
  ELSIF EndsWith(name, ".xml") THEN COPY("application/xml", mime)
  ELSIF EndsWith(name, ".atom") THEN COPY("application/atom+xml", mime)
  ELSIF EndsWith(name, ".rss") THEN COPY("application/rss+xml", mime)
  ELSIF EndsWith(name, ".png") THEN COPY("image/png", mime)
  ELSIF EndsWith(name, ".jpg") OR EndsWith(name, ".jpeg") THEN COPY("image/jpeg", mime)
  ELSIF EndsWith(name, ".gif") THEN COPY("image/gif", mime)
  ELSIF EndsWith(name, ".webp") THEN COPY("image/webp", mime)
  ELSIF EndsWith(name, ".svg") THEN COPY("image/svg+xml", mime)
  ELSIF EndsWith(name, ".ico") THEN COPY("image/vnd.microsoft.icon", mime)
  ELSIF EndsWith(name, ".woff2") THEN COPY("font/woff2", mime)
  ELSIF EndsWith(name, ".woff") THEN COPY("font/woff", mime)
  ELSIF EndsWith(name, ".wasm") THEN COPY("application/wasm", mime)
  ELSIF EndsWith(name, ".pdf") THEN COPY("application/pdf", mime)
  ELSIF EndsWith(name, ".gz") THEN COPY("application/gzip", mime)
  ELSIF EndsWith(name, ".zip") THEN COPY("application/zip", mime)
  ELSE COPY("application/octet-stream", mime)
  END
END MimeType;

(* the file f; its descriptor is closed after *)
PROCEDURE SendFile(VAR req: Request; f: Files.File; VAR name: ARRAY OF CHAR);
VAR b: TLSBytes.Buffer; r: Files.Rider; n, left: LONGINT; mime: ARRAY 64 OF CHAR;
BEGIN
  MimeType(name, mime); Head(200, mime, Files.Length(f), NetHost.MTime(name), "");
  IF ~req.head THEN
    left := Files.Length(f); Files.Set(r, f, 0);
    WHILE ok & (left > 0) DO
      n := left; IF n > Chunk THEN n := Chunk END;
      Files.ReadBytes(r, b.data, n); b.len := n; SendBuffer(b); DEC(left, n)
    END
  END;
  Files.Close(f)
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

(* an HTML list of the files in the directory path (ending with /) *)
PROCEDURE SendList(VAR req: Request; list: Entry);
VAR b: TLSBytes.Buffer; enc: ARRAY 3 * NameLen OF CHAR;
BEGIN
  TLSBytes.Init(b);
  TLSBytes.AppendString(b, "<!DOCTYPE html>"); TLSBytes.AppendChar(b, 0AX);
  TLSBytes.AppendString(b, "<html><head><meta charset=utf-8><title>"); AppendHTML(b, req.path);
  TLSBytes.AppendString(b, "</title></head><body><h1>"); AppendHTML(b, req.path);
  TLSBytes.AppendString(b, "</h1><ul>"); TLSBytes.AppendChar(b, 0AX);
  IF req.path[1] # 0X THEN TLSBytes.AppendString(b, "<li><a href=../>../</a></li>"); TLSBytes.AppendChar(b, 0AX) END;
  WHILE (list # NIL) & (b.len < TLSBytes.MaxLen - 2 * NameLen - 64) DO
    Encode(list.name, enc);
    TLSBytes.AppendString(b, "<li><a href="); TLSBytes.AppendChar(b, 22X); TLSBytes.AppendString(b, enc);
    IF list.dir THEN TLSBytes.AppendChar(b, "/") END;
    TLSBytes.AppendChar(b, 22X); TLSBytes.AppendChar(b, ">"); AppendHTML(b, list.name);
    IF list.dir THEN TLSBytes.AppendChar(b, "/") END;
    TLSBytes.AppendString(b, "</a></li>"); TLSBytes.AppendChar(b, 0AX);
    list := list.next
  END;
  TLSBytes.AppendString(b, "</ul></body></html>"); TLSBytes.AppendChar(b, 0AX);
  Head(200, "text/html; charset=utf-8", b.len, 0, "");
  IF ~req.head THEN SendBuffer(b) END
END SendList;

(* ----- requests ----- *)

(* head := the request line and the header fields, up to the empty line; status: 0, or the
   status of the error *)
PROCEDURE ReadHead(VAR head: ARRAY OF CHAR; VAR status: LONGINT);
VAR buf: ARRAY 2048 OF CHAR; n, got, i: LONGINT;
BEGIN
  n := 0; status := 0; head[0] := 0X;
  LOOP
    Receive(buf, 2048, got);
    IF got = 0 THEN status := 400; RETURN END;
    i := 0;
    WHILE i < got DO
      IF n >= MaxHead THEN status := 431; RETURN END;
      head[n] := buf[i]; INC(n); INC(i);
      IF (n >= 4) & (head[n - 1] = 0AX) & (head[n - 2] = 0DX) & (head[n - 3] = 0AX) & (head[n - 4] = 0DX) OR
         (n >= 2) & (head[n - 1] = 0AX) & (head[n - 2] = 0AX) THEN
        head[n] := 0X; RETURN  (* a body (none for GET and HEAD) is not read *)
      END
    END
  END
END ReadHead;

(* req := the request in head; status: 0, or the status of the error *)
PROCEDURE Parse(VAR head: ARRAY OF CHAR; VAR req: Request; VAR status: LONGINT);
VAR i, j, a, b, k: LONGINT; name: ARRAY 32 OF CHAR;
BEGIN
  status := 0; req.method := ""; req.target := ""; req.path := ""; req.host := ""; req.head := FALSE;
  i := 0; j := 0;
  WHILE (head[i] > " ") & (j < LEN(req.method) - 1) DO req.method[j] := head[i]; INC(i); INC(j) END;
  req.method[j] := 0X;
  IF head[i] # " " THEN status := 400; RETURN END;
  INC(i); j := 0;
  WHILE head[i] > " " DO
    IF j >= LEN(req.target) - 1 THEN status := 414; RETURN END;
    req.target[j] := head[i]; INC(i); INC(j)
  END;
  req.target[j] := 0X;
  IF (head[i] # " ") OR (j = 0) THEN status := 400; RETURN END;
  INC(i);
  IF (head[i] # "H") OR (head[i + 1] # "T") OR (head[i + 2] # "T") OR (head[i + 3] # "P") OR (head[i + 4] # "/") THEN
    status := 400; RETURN
  END;
  IF head[i + 5] # "1" THEN status := 505; RETURN END;
  WHILE (head[i] # 0X) & (head[i] # 0AX) DO INC(i) END;
  (* the header fields: only Host is used *)
  WHILE head[i] = 0AX DO
    INC(i); j := 0;
    WHILE (head[i] # ":") & (head[i] > " ") & (j < LEN(name) - 1) DO name[j] := head[i]; INC(i); INC(j) END;
    name[j] := 0X;
    IF head[i] = ":" THEN
      INC(i); WHILE (head[i] = " ") OR (head[i] = 09X) DO INC(i) END;
      IF SameName(name, "host") THEN
        j := 0;
        WHILE (head[i] > " ") & (head[i] # ":") & (j < LEN(req.host) - 1) DO req.host[j] := head[i]; INC(i); INC(j) END;
        req.host[j] := 0X
      END
    END;
    WHILE (head[i] # 0X) & (head[i] # 0AX) DO INC(i) END
  END;
  req.head := req.method = "HEAD";
  IF (req.method # "GET") & ~req.head THEN status := 405; RETURN END;
  (* the path: origin form /a/b?q, or absolute form http://host/a/b *)
  i := 0;
  IF req.target[0] # "/" THEN
    WHILE (req.target[i] # 0X) & (req.target[i] # ":") DO INC(i) END;
    IF (req.target[i] # ":") OR (req.target[i + 1] # "/") OR (req.target[i + 2] # "/") THEN status := 400; RETURN END;
    INC(i, 3); j := 0;
    WHILE (req.target[i] # 0X) & (req.target[i] # "/") & (req.target[i] # ":") & (req.target[i] # "?") DO
      IF j < LEN(req.host) - 1 THEN req.host[j] := req.target[i]; INC(j) END; INC(i)
    END;
    req.host[j] := 0X;
    WHILE (req.target[i] # 0X) & (req.target[i] # "/") & (req.target[i] # "?") DO INC(i) END
  END;
  j := 0;
  IF req.target[i] # "/" THEN req.path[0] := "/"; j := 1 END;
  WHILE (req.target[i] # 0X) & (req.target[i] # "?") & (req.target[i] # "#") & (j < LEN(req.path) - 1) DO
    IF req.target[i] = "%" THEN
      a := Hex(req.target[i + 1]); IF a >= 0 THEN b := Hex(req.target[i + 2]) ELSE b := -1 END;
      IF (b < 0) OR (a * 16 + b = 0) THEN status := 400; RETURN END;
      req.path[j] := CHR(a * 16 + b); INC(i, 3)
    ELSE req.path[j] := req.target[i]; INC(i)
    END;
    INC(j)
  END;
  req.path[j] := 0X;
  k := 0;
  WHILE req.path[k] # 0X DO
    IF (req.path[k] = "/") & (req.path[k + 1] = ".") THEN status := 404; RETURN END;  (* hidden names, .. *)
    INC(k)
  END
END Parse;

(* answers the request; status: the status sent *)
PROCEDURE Answer(VAR req: Request; VAR status: LONGINT);
VAR file, index, location: ARRAY PathLen + 32 OF CHAR; i: LONGINT; list: Entry; f: Files.File; full: NetHost.FileName; flags: SET;
BEGIN
  IF (host[0] # 0X) & ~SameName(req.host, host) THEN status := 421; Error(req, 421, ""); RETURN END;
  COPY(root, file); Append(file, req.path);
  IF ~NetHost.Exists(file, full, flags) THEN status := 404; Error(req, status, "")
  ELSIF NetHost.Directory IN flags THEN
    IF req.path[Len(req.path) - 1] # "/" THEN
      status := 301; COPY(req.target, location);
      i := 0; WHILE (location[i] # 0X) & (location[i] # "?") DO INC(i) END;
      location[i] := 0X; Append(location, "/"); Error(req, 301, location)
    ELSE
      COPY(file, index); Append(index, "index.html");
      IF NetHost.Exists(index, full, flags) & ~(NetHost.Directory IN flags) THEN f := Files.Old(index) ELSE f := NIL END;
      status := 200;
      IF f # NIL THEN SendFile(req, f, index)
      ELSE ReadDir(file, list); SendList(req, list)
      END
    END
  ELSE
    f := Files.Old(file);
    IF f = NIL THEN status := 403; Error(req, status, "")  (* there, but it cannot be read *)
    ELSE status := 200; SendFile(req, f, file)
    END
  END
END Answer;

(* ----- the server ----- *)

PROCEDURE Close;
BEGIN
  IF (s # NIL) & s.connected THEN TLS13Live.Disconnect(s^) END;
  IF conn # NIL THEN Sockets.Close(conn); conn := NIL END;
  IF listener # NIL THEN Sockets.Close(listener); listener := NIL END
END Close;

PROCEDURE Int(VAR a: ARRAY OF CHAR; VAR v: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0; v := 0;
  WHILE (a[i] >= "0") & (a[i] <= "9") & (v < 1000000) DO v := v * 10 + ORD(a[i]) - ORD("0"); INC(i) END;
  RETURN (i > 0) & (a[i] = 0X)
END Int;

PROCEDURE Usage;
BEGIN
  out.String("usage: cobweb.Serve dir [port] [/tls cert.pem key.pem] [/host name] [/n count] [/queue n] [/timeout s]"); out.Ln;
  out.String("  serves the files below dir over HTTP (port 8080) or HTTPS (/tls, port 8443);"); out.Ln;
  out.String("  cobweb.Help tells more"); out.Ln
END Usage;

(* one connection: c accepted, served, closed *)
PROCEDURE Connection(c: Sockets.Socket; id: TLS13Server.Identity; VAR addr: ARRAY OF CHAR);
VAR head: ARRAY MaxHead + 1 OF CHAR; req: Request; status: LONGINT;
BEGIN
  ok := TRUE; req.target := ""; req.method := ""; req.head := FALSE;
  IF tls THEN
    IF ~TLS13Server.Accept(c.fd, id, s^) THEN
      out.String(addr); out.String(" handshake failed: "); out.String(TLS13Server.lastError); out.Ln; RETURN
    END
  ELSE conn := c
  END;
  ReadHead(head, status);
  IF status = 0 THEN Parse(head, req, status) END;
  IF status = 0 THEN Answer(req, status)
  ELSIF head[0] # 0X THEN Error(req, status, "")  (* nothing for a client that sent nothing *)
  END;
  IF tls THEN TLS13Live.Disconnect(s^) ELSE Sockets.Close(conn); conn := NIL END;
  out.String(addr); out.Char(" "); out.Int(status, 0); out.Char(" ");
  IF req.method[0] = 0X THEN out.Char("-") ELSE out.String(req.method); out.Char(" "); out.String(req.target) END;
  out.Ln
END Connection;

(** serves the files below dir on port, over HTTPS with the certificate in cert and its key in
  key (PEM files), or over HTTP if cert is ""; count connections (-1: without end); hostName:
  the only host answered, "" for any; queue: the connections that may wait, secs: the seconds a
  client may take (0: no limit). Ctrl+C stops it. For programs and tests; cobweb.Serve is the
  command. *)
PROCEDURE Start*(dir, cert, key, hostName: ARRAY OF CHAR; port, count, queue, secs: LONGINT);
VAR served, peerPort: LONGINT; id: TLS13Server.Identity; c: Sockets.Socket; peer, address: Sockets.Address; addr: ARRAY 64 OF CHAR;
BEGIN
  COPY(dir, root); COPY(hostName, host); tls := cert[0] # 0X;
  WHILE (Len(root) > 1) & (root[Len(root) - 1] = "/") DO root[Len(root) - 1] := 0X END;
  id := NIL;
  IF tls & ~TLS13Server.Load(cert, key, id) THEN out.String("cobweb: "); out.String(TLS13Server.lastError); out.Ln; RETURN END;
  Close; Oberon.OnStop(Close);
  IF tls & (s = NIL) THEN NEW(s); TLS13Live.Init(s^) END;
  IF listenOn = "" THEN listener := Sockets.Listen(Sockets.Inet6, port, queue)
  ELSIF Sockets.ParseAddress(listenOn, address) THEN listener := Sockets.ListenAt(address, port, queue)
  ELSE out.String("cobweb: invalid listen address"); out.Ln; RETURN
  END;
  IF listener = NIL THEN out.String("cobweb: cannot listen on port "); out.Int(port, 0); out.Ln; RETURN END;
  out.String("cobweb: serving "); out.String(root); out.String(" on port "); out.Int(port, 0);
  IF tls THEN out.String(" (https)") ELSE out.String(" (http)") END;
  out.Ln;
  served := 0;
  WHILE served # count DO
    c := Sockets.Accept(listener, peer, peerPort);
    IF c # NIL THEN
      INC(served);
      Sockets.AddressToString(peer, addr);
      Sockets.SetTimeout(c, secs * 1000);
      Connection(c, id, addr)
    END
  END;
  Close
END Start;

PROCEDURE Serve*;
VAR
  A: Texts.Reader; arg, dir, cert, key: ARRAY PathLen OF CHAR; hostName: ARRAY 256 OF CHAR;
  port, count, queue, secs: LONGINT;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, dir) THEN Usage; RETURN END;
  port := -1; count := -1; hostName := ""; cert := ""; key := ""; queue := queueLen; secs := timeout; listenOn := "";
  WHILE Texts.Arg(A, arg) DO
    IF arg = "/tls" THEN IF ~Texts.Arg(A, cert) OR ~Texts.Arg(A, key) THEN Usage; RETURN END
    ELSIF arg = "/listen" THEN IF ~Texts.Arg(A, listenOn) THEN Usage; RETURN END
    ELSIF arg = "/host" THEN IF ~Texts.Arg(A, hostName) THEN Usage; RETURN END
    ELSIF arg = "/n" THEN IF ~Texts.Arg(A, arg) OR ~Int(arg, count) THEN Usage; RETURN END
    ELSIF arg = "/queue" THEN IF ~Texts.Arg(A, arg) OR ~Int(arg, queue) OR (queue < 1) THEN Usage; RETURN END
    ELSIF arg = "/timeout" THEN IF ~Texts.Arg(A, arg) OR ~Int(arg, secs) THEN Usage; RETURN END
    ELSIF ~Int(arg, port) OR (port < 1) OR (port > 65535) THEN Usage; RETURN
    END
  END;
  IF port < 0 THEN IF cert[0] # 0X THEN port := DefaultTLSPort ELSE port := DefaultPort END END;
  Start(dir, cert, key, hostName, port, count, queue, secs)
END Serve;

PROCEDURE NumArg(usage: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN;
VAR A: Texts.Reader; arg: ARRAY 32 OF CHAR;
BEGIN
  Texts.OpenArgs(A);
  IF Texts.Arg(A, arg) & Int(arg, n) THEN RETURN TRUE END;
  out.String("usage: cobweb."); out.String(usage); out.Ln;
  RETURN FALSE
END NumArg;

(** cobweb.SetQueueLen n: the connections that may wait while one is served, for the next Serve *)
PROCEDURE SetQueueLen*;
VAR n: LONGINT;
BEGIN
  IF NumArg("SetQueueLen n   (connections waiting while one is served)", n) & (n > 0) THEN queueLen := n END;
  out.String("cobweb: queue "); out.Int(queueLen, 0); out.Ln
END SetQueueLen;

(** cobweb.SetTimeout s: the seconds a client may take, for the next Serve (0: no limit) *)
PROCEDURE SetTimeout*;
VAR n: LONGINT;
BEGIN
  IF NumArg("SetTimeout s   (seconds a client may take, 0: no limit)", n) THEN timeout := n END;
  out.String("cobweb: timeout "); out.Int(timeout, 0); out.String(" s"); out.Ln
END SetTimeout;

PROCEDURE Help*;
BEGIN
  out.String("cobweb, an HTTP server"); out.Ln; out.Ln;
  out.String("  cobweb.Serve dir [port] [/tls cert.pem key.pem] [/host name] [/n count]"); out.Ln;
  out.String("               [/queue n] [/timeout s] [/listen address]"); out.Ln;
  out.String("    serves the files below dir: over HTTP on port 8080, or with /tls over HTTPS"); out.Ln;
  out.String("    on port 8443. GET and HEAD, one request per connection. A directory gives"); out.Ln;
  out.String("    its index.html, or a list of its files; names starting with a dot are not"); out.Ln;
  out.String("    served. /host name answers only requests for that host; /n count ends after"); out.Ln;
  out.String("    count connections. Each request is logged: the client, the status, the request."); out.Ln;
  out.String("    One client is served at a time; the others wait in a queue (16), each client"); out.Ln;
  out.String("    has 10 seconds. /queue n and /timeout s change them for one Serve;"); out.Ln;
  out.String("    cobweb.SetQueueLen n and cobweb.SetTimeout s for the next Serve in this loksh."); out.Ln;
  out.String("    Ctrl+C stops the server."); out.Ln; out.Ln;
  out.String("  The certificate of /tls needs an ECDSA P-256 key, from a CA (Let's Encrypt:"); out.Ln;
  out.String("  certbot --key-type ecdsa) or self-signed, made with openssl:"); out.Ln; out.Ln;
  out.String("    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes"); out.Ln;
  out.String("      -keyout key.pem -out cert.pem -days 3650 -subj /CN=example.org"); out.Ln; out.Ln;
  out.String("  Examples:"); out.Ln;
  out.String("    loksh cobweb.Serve /home/me/site"); out.Ln;
  out.String("    loksh cobweb.Serve /home/me/site 443 /tls fullchain.pem privkey.pem"); out.Ln;
  out.String("    loksh fetch.Show http://localhost:8080/"); out.Ln
END Help;

BEGIN
  listener := NIL; conn := NIL; s := NIL; queueLen := DefaultQueue; timeout := DefaultTimeout; listenOn := ""
END cobweb.
