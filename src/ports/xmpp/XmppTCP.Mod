MODULE XmppTCP;

(* Linux TCP and verified TLS 1.3 transport using VOC's Internet and TLS modules.
   The dial host is separate from the service domain used for SNI and validation. *)

IMPORT SYSTEM, Msg, S := LongStrings, Internet, Sockets, TLS := TLS13Live,
  Bytes := TLSBytes, Wire := XmppWire, Items := XmppItems, IDNA;

CONST connectionError = 1; ioError = 2; tlsError = 3; invalidAddress = 4;

TYPE
  Transport* = POINTER TO TransportDesc;
  TransportDesc* = RECORD (Wire.TransportDesc)
    fd: Internet.Socket;
    tls: TLS.State;
    verifiedDomain: Items.Bytes;
    serviceDomain: Items.Bytes;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
  VAR template: ARRAY 96 OF CHAR;
BEGIN
  CASE message.code OF
  | connectionError: template := "XMPP TCP connection or socket timeout setup failed"
  | tlsError: template := "XMPP TLS authentication or record operation failed"
  | invalidAddress: template := "Invalid XMPP TCP host, numeric port, service domain or operation timeout"
  ELSE template := "XMPP TCP read or write failed"
  END;
  S.Long(template, text)
END GetTemplate;

PROCEDURE Error(t: Transport; code: SHORTINT);
BEGIN
  IF t.res = NIL THEN
    t.res := Msg.New(context, code);
    IF code = tlsError THEN t.res.SetStringAttrib("detail", Msg.GetStringPtr(TLS.lastError)) END
  END
END Error;

PROCEDURE (t: Transport) AuthenticatedFor*(domain: ARRAY OF CHAR): BOOLEAN;
  VAR unicodeName, asciiName: IDNA.String; result: LONGINT;
BEGIN
  IF ~t.tls.connected OR ~t.tls.handshakeDone OR (t.verifiedDomain = NIL) THEN RETURN FALSE END;
  IDNA.Names(domain, unicodeName, asciiName, result);
  RETURN (result = 0) & (asciiName^ = t.verifiedDomain^)
END AuthenticatedFor;

PROCEDURE (t: Transport) DomainName*(domain: ARRAY OF CHAR; VAR canonical: Items.Bytes): BOOLEAN;
  VAR unicodeName, asciiName: IDNA.String; result: LONGINT;
BEGIN
  canonical := NIL; IDNA.Names(domain, unicodeName, asciiName, result);
  IF result # 0 THEN RETURN FALSE END;
  canonical := Items.Copy8(unicodeName^); RETURN TRUE
END DomainName;

PROCEDURE (t: Transport) StartTLS*(domain: ARRAY OF CHAR): BOOLEAN;
  VAR fd: Internet.Socket; unicodeName, asciiName: IDNA.String; result: LONGINT;
BEGIN
  IF (t.res # NIL) OR (t.fd < 0) OR t.tls.connected THEN RETURN FALSE END;
  IDNA.Names(domain, unicodeName, asciiName, result);
  IF (result # 0) OR (asciiName^ # t.serviceDomain^) THEN Error(t, invalidAddress); RETURN FALSE END;
  fd := t.fd; t.fd := -1;
  IF ~TLS.Start(asciiName^, fd, t.tls) THEN Error(t, tlsError); RETURN FALSE END;
  t.verifiedDomain := Items.Copy8(asciiName^); RETURN TRUE
END StartTLS;

PROCEDURE (t: Transport) Read*(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
  VAR ok: BOOLEAN;
BEGIN
  ASSERT(LEN(bytes) > 0); count := 0;
  IF t.res # NIL THEN RETURN FALSE END;
  IF t.tls.handshakeDone THEN
    ok := TLS.ReadApp(t.tls, bytes, count);
    IF ~ok & ~t.tls.closeNotify THEN Error(t, tlsError); RETURN FALSE END;
    RETURN TRUE
  END;
  IF t.fd < 0 THEN Error(t, ioError); RETURN FALSE END;
  count := LEN(bytes); ok := Internet.ReadBuf(t.fd, bytes, count);
  IF ~ok THEN count := 0; Error(t, ioError) END;
  RETURN ok
END Read;

PROCEDURE (t: Transport) WriteBytes*(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
  VAR block: Bytes.Buffer; i, n: LONGINT; ok: BOOLEAN;
BEGIN
  ASSERT((start >= 0) & (start <= LEN(bytes)) & (count >= 0) & (count <= LEN(bytes)-start));
  t.bytesWritten := 0;
  IF t.res # NIL THEN RETURN END;
  WHILE t.bytesWritten < count DO
    n := count-t.bytesWritten; IF n > 16384 THEN n := 16384 END;
    Bytes.SetLen(block, n);
    FOR i := 0 TO n-1 DO block.data[i] := SYSTEM.VAL(CHAR, bytes[start+t.bytesWritten+i]) END;
    IF t.tls.handshakeDone THEN ok := TLS.WriteAppBuffer(t.tls, block)
    ELSIF t.fd >= 0 THEN ok := Internet.WriteBytes(t.fd, block.data, n)
    ELSE ok := FALSE
    END;
    FOR i := 0 TO n-1 DO block.data[i] := 0X END;
    IF ~ok THEN Error(t, ioError); RETURN END;
    INC(t.bytesWritten, n)
  END
END WriteBytes;

PROCEDURE (t: Transport) Close*;
BEGIN
  IF t.tls.connected THEN TLS.Disconnect(t.tls) END;
  IF t.fd >= 0 THEN Internet.Disconnect(t.fd); t.fd := -1 END;
  t.verifiedDomain := NIL
END Close;

PROCEDURE Address(host, port: ARRAY OF CHAR; timeout: LONGINT): BOOLEAN;
  VAR i, n, length: LONGINT;
BEGIN
  length := S.Length8(host);
  IF (length = 0) OR (length > 253) OR (timeout <= 0) OR (timeout > 600000) THEN RETURN FALSE END;
  FOR i := 0 TO length-1 DO IF (host[i] <= " ") OR (host[i] >= 7FX) THEN RETURN FALSE END END;
  length := S.Length8(port); IF (length = 0) OR (length > 5) THEN RETURN FALSE END;
  n := 0;
  FOR i := 0 TO length-1 DO
    IF (port[i] < "0") OR (port[i] > "9") THEN RETURN FALSE END;
    n := n*10+ORD(port[i])-ORD("0")
  END;
  RETURN (n > 0) & (n <= 65535)
END Address;

PROCEDURE Open*(host, port, serviceDomain: ARRAY OF CHAR; directTLS: BOOLEAN;
                timeoutMilliseconds: LONGINT; VAR error: Msg.Msg): Transport;
  VAR t: Transport; socket: Sockets.Socket; address: Sockets.Address;
    unicodeName, asciiName, dialUnicode, dialASCII: IDNA.String; result: LONGINT; dial: Items.Bytes;
BEGIN
  error := NIL;
  IDNA.Names(serviceDomain, unicodeName, asciiName, result);
  IF result # 0 THEN error := Msg.New(context, invalidAddress); RETURN NIL END;
  IF Sockets.ParseAddress(host, address) THEN dial := Items.Copy8(host)
  ELSE
    IDNA.Names(host, dialUnicode, dialASCII, result);
    IF result # 0 THEN error := Msg.New(context, invalidAddress); RETURN NIL END;
    dial := Items.Copy8(dialASCII^)
  END;
  IF ~Address(dial^, port, timeoutMilliseconds) THEN
    error := Msg.New(context, invalidAddress); RETURN NIL
  END;
  NEW(t); t.fd := -1; TLS.Init(t.tls); t.serviceDomain := Items.Copy8(asciiName^);
  IF ~Internet.Connect(dial^, port, t.fd) THEN Error(t, connectionError)
  ELSE
    NEW(socket); socket.fd := t.fd; socket.res := 0;
    Sockets.SetTimeout(socket, timeoutMilliseconds);
    IF socket.res # 0 THEN Error(t, connectionError)
    ELSIF directTLS THEN
      IF ~t.StartTLS(serviceDomain) THEN Error(t, tlsError) END
    END
  END;
  IF t.res # NIL THEN error := t.res; t.Close; RETURN NIL END;
  RETURN t
END Open;

BEGIN
  NEW(context); Msg.InitContext(context, "XmppTCP")
END XmppTCP.
