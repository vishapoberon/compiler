MODULE httpsPure;

IMPORT Out, http, strTypes, strUtils, TLS13Live;

TYPE
   PureTLSSocket = POINTER TO PureTLSSocketDesc;
   PureTLSSocketDesc = RECORD(http.transportDesc)
     tls*: TLS13Live.State
   END;

   TLSClient* = POINTER TO TLSClientDesc;
   TLSClientDesc* = RECORD(http.ClientDesc)
     crtpath*    : ARRAY 256 OF CHAR;
     pers*       : ARRAY 128 OF CHAR;
   setCertPath*  : PROCEDURE (VAR h: TLSClient; path: ARRAY OF CHAR);
   setPers*      : PROCEDURE (VAR h: TLSClient; pers: ARRAY OF CHAR);
      Init*      : PROCEDURE (VAR h: TLSClient);
   END;

PROCEDURE init(VAR h: TLSClient);
BEGIN
  (* Pure Oberon TLS state is initialized in Connect.  crtpath is kept for
     compatibility with the old mbedtls-based https module; the CA bundle is
     SSL_CERT_FILE or TLSCABundle.DefaultPath, and TLS13Live refuses a server
     it cannot verify. *)
END init;

PROCEDURE setcertpath(VAR h: TLSClient; path: ARRAY OF CHAR);
BEGIN
  COPY(path, h^.crtpath)
END setcertpath;

PROCEDURE setpers(VAR h: TLSClient; str: ARRAY OF CHAR);
BEGIN
  COPY(str, h^.pers)
END setpers;

PROCEDURE connector(VAR h: http.Client): BOOLEAN;
BEGIN
  h.connectionFlag := FALSE;
  IF h^.trn IS PureTLSSocket THEN
    h^.connectionFlag := TLS13Live.Connect(h^.host^, h^.port^, h^.trn(PureTLSSocket).tls)
  ELSE
    Out.String("httpsPure client is not initialized with pure tls socket"); Out.Ln;
    HALT(100)
  END;
  RETURN h^.connectionFlag
END connector;

PROCEDURE disconnector(VAR h: http.Client);
BEGIN
  IF h^.trn IS PureTLSSocket THEN
    TLS13Live.Disconnect(h^.trn(PureTLSSocket).tls)
  ELSE
    Out.String("httpsPure client is not initialized with pure tls socket"); Out.Ln;
    HALT(100)
  END
END disconnector;

PROCEDURE writer(VAR h: http.Client; buf: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF h^.trn IS PureTLSSocket THEN
    h^.connectionFlag := TLS13Live.WriteAppString(h^.trn(PureTLSSocket).tls, buf)
  ELSE
    Out.String("httpsPure client is not initialized with pure tls socket"); Out.Ln;
    HALT(100)
  END;
  RETURN h^.connectionFlag
END writer;

(* toRead < 0: what is there, at most LEN(buf)-1 bytes; else exactly toRead bytes (as http
   expects of Read); then 0X *)
PROCEDURE reader(VAR h: http.Client; VAR buf: ARRAY OF CHAR; toRead: LONGINT): BOOLEAN;
VAR n, got, i: LONGINT; tmp: ARRAY 4096 OF CHAR; t: PureTLSSocket; ok: BOOLEAN;
BEGIN
  IF h^.trn IS PureTLSSocket THEN
    t := h^.trn(PureTLSSocket);
    IF toRead < 0 THEN
      ok := TLS13Live.ReadAppMax(t.tls, buf, LEN(buf) - 1, n)
    ELSE
      IF toRead > LEN(buf) - 1 THEN toRead := LEN(buf) - 1 END;
      got := 0; ok := TRUE;
      WHILE ok & (got < toRead) DO
        n := toRead - got; IF n > LEN(tmp) THEN n := LEN(tmp) END;
        ok := TLS13Live.ReadAppMax(t.tls, tmp, n, n);
        i := 0; WHILE i < n DO buf[got + i] := tmp[i]; INC(i) END;
        INC(got, n)
      END;
      buf[got] := 0X
    END;
    h^.connectionFlag := ok;
    IF ~ok THEN h^.endClean := t.tls.closeNotify END  (* the end: proper only with close_notify *)
  ELSE
    Out.String("httpsPure client is not initialized with pure tls socket"); Out.Ln;
    HALT(100)
  END;
  RETURN h^.connectionFlag
END reader;

PROCEDURE readBuf(VAR h: http.Client; VAR buf: ARRAY OF CHAR; VAR haveRead: LONGINT): BOOLEAN;
VAR max: LONGINT;
BEGIN
  IF h^.trn IS PureTLSSocket THEN
    max := haveRead;
    IF max < 0 THEN max := LEN(buf) END;
    IF max > LEN(buf) THEN max := LEN(buf) END;
    h^.connectionFlag := TLS13Live.ReadAppMax(h^.trn(PureTLSSocket).tls, buf, max, haveRead);
    IF ~h^.connectionFlag THEN h^.endClean := h^.trn(PureTLSSocket).tls.closeNotify END
  ELSE
    Out.String("httpsPure client is not initialized with pure tls socket"); Out.Ln;
    HALT(100)
  END;
  RETURN h^.connectionFlag
END readBuf;

PROCEDURE Create*(host, port, path: ARRAY OF CHAR): TLSClient;
VAR
  hs: TLSClient;
  socket: PureTLSSocket;
  c: http.Client;
BEGIN
  NEW(hs);
  hs^.eol[0] := 0DX;  hs^.eol[1] := 0AX; hs^.null[0] := 0X;
  strUtils.string2pstring(host, hs^.host);
  strUtils.string2pstring(port, hs^.port);
  strUtils.string2pstring(path, hs^.path);
  strUtils.string2pstring(http.defUserAgent, hs^.userAgent);
  strUtils.string2pstring(http.defHttpVersion, hs^.version);

  hs^.Get := http.get;
  hs^.setUserAgent := http.setuseragent;
  hs^.clearState := http.clearstate;
  hs^.Save := http.save;
  http.formReqHeader(hs);

  c := hs; http.clearstate(c);

  NEW(socket);
  TLS13Live.Init(socket^.tls);
  hs^.trn := socket;
  hs.Connect := connector;
  hs.Disconnect := disconnector;
  hs.Read := reader;
  hs.ReadBuf := readBuf;
  hs.Write := writer;

  hs.appendHeader := http.appendHdrLine;
  hs.appendAuthHdr := http.appendUserPasswdHdr;

  hs.setCertPath := setcertpath;
  hs.setPers     := setpers;
  hs.setCertPath(hs, "/etc/ssl/certs/ca-certificates.crt");
  hs.setPers(hs, "oberon_pure_tls13_client");
  hs.Init := init;
  RETURN hs
END Create;

END httpsPure.
