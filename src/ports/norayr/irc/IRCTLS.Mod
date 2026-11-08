MODULE IRCTLS;
(* SPDX-License-Identifier: LGPL-3.0-only *)
IMPORT IRC, IRCTCP, TLS := TLS13Live;

TYPE
  Secure = POINTER TO SecureDesc;
  SecureDesc = RECORD(IRC.TransportDesc)
    tcp: IRC.Transport;
    tls: TLS.State;
    host: ARRAY 256 OF CHAR;
    begun: BOOLEAN
  END;

PROCEDURE Close(t: IRC.Transport);
BEGIN
  WITH t: Secure DO
    TLS.CloseNow(t.tls); t.tcp.Close(t.tcp); t.secure := FALSE; t.begun := FALSE
  END
END Close;

PROCEDURE Open(t: IRC.Transport; host: ARRAY OF CHAR; port, timeout: LONGINT): BOOLEAN;
BEGIN
  WITH t: Secure DO
    Close(t); COPY(host, t.host);
    RETURN t.tcp.Open(t.tcp, host, port, timeout)
  END
END Open;

PROCEDURE Poll(t: IRC.Transport): INTEGER;
VAR result: INTEGER; fd: LONGINT;
BEGIN
  WITH t: Secure DO
    IF ~t.begun THEN
      result := t.tcp.Poll(t.tcp);
      IF result # IRC.Connected THEN RETURN result END;
      fd := IRCTCP.TakeDescriptor(t.tcp);
      IF ~TLS.Begin(t.host, fd, t.tls) THEN RETURN IRC.Failed END;
      t.begun := TRUE
    END;
    result := TLS.PollHandshake(t.tls);
    IF result = 1 THEN t.secure := TRUE; RETURN IRC.Connected END;
    IF result < 0 THEN RETURN IRC.Failed END;
    RETURN IRC.Pending
  END
END Poll;

PROCEDURE Read(t: IRC.Transport; VAR bytes: ARRAY OF CHAR; offset, count: LONGINT): LONGINT;
BEGIN
  WITH t: Secure DO RETURN TLS.ReadSome(t.tls, bytes, offset, count) END
END Read;

PROCEDURE Write(t: IRC.Transport; VAR bytes: ARRAY OF CHAR; offset, count: LONGINT): LONGINT;
BEGIN
  WITH t: Secure DO RETURN TLS.WriteSome(t.tls, bytes, offset, count) END
END Write;

PROCEDURE New*(): IRC.Transport;
VAR t: Secure;
BEGIN
  NEW(t); t.tcp := IRCTCP.New(); TLS.Init(t.tls); t.secure := FALSE; t.begun := FALSE;
  t.Open := Open; t.Poll := Poll; t.Read := Read; t.Write := Write; t.Close := Close;
  RETURN t
END New;

END IRCTLS.
