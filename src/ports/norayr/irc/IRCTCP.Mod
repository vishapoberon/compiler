MODULE IRCTCP;
(* SPDX-License-Identifier: LGPL-3.0-only *)
IMPORT IRC, Sockets, DNS;

TYPE
  TCP* = POINTER TO TCPDesc;
  TCPDesc* = RECORD(IRC.TransportDesc)
    socket: Sockets.Socket;
    addresses: ARRAY 8 OF Sockets.Address;
    count, next, port: LONGINT
  END;

PROCEDURE Close(t: IRC.Transport);
BEGIN
  WITH t: TCP DO Sockets.Close(t.socket); t.socket := NIL; t.secure := FALSE END
END Close;

PROCEDURE Dial(t: TCP): BOOLEAN;
VAR local: Sockets.Address;
BEGIN
  WHILE t.next < t.count DO
    Sockets.AnyAddress(t.addresses[t.next].family, local);
    t.socket := Sockets.ConnectFrom(local, t.addresses[t.next], t.port); INC(t.next);
    IF t.socket # NIL THEN RETURN TRUE END
  END;
  RETURN FALSE
END Dial;

PROCEDURE Open(t: IRC.Transport; host: ARRAY OF CHAR; port, timeout: LONGINT): BOOLEAN;
BEGIN
  WITH t: TCP DO
    Close(t); t.port := port; t.next := 0;
    DNS.Lookup(host, DNS.Any, t.addresses, t.count);
    RETURN Dial(t)
  END
END Open;

PROCEDURE Poll(t: IRC.Transport): INTEGER;
VAR result: LONGINT;
BEGIN
  WITH t: TCP DO
    IF t.socket = NIL THEN RETURN IRC.Failed END;
    result := Sockets.PollConnect(t.socket);
    IF result = 0 THEN RETURN IRC.Connected END;
    IF result < 0 THEN
      Sockets.Close(t.socket); t.socket := NIL;
      IF ~Dial(t) THEN RETURN IRC.Failed END
    END;
    RETURN IRC.Pending
  END
END Poll;

PROCEDURE Read(t: IRC.Transport; VAR bytes: ARRAY OF CHAR; offset, count: LONGINT): LONGINT;
VAR n: LONGINT;
BEGIN
  WITH t: TCP DO n := Sockets.ReceiveSome(t.socket, bytes, offset, count) END;
  IF Sockets.WouldBlock(n) OR Sockets.Interrupted(n) THEN RETURN IRC.WouldBlock END;
  IF n < 0 THEN RETURN -1 END;
  RETURN n
END Read;

PROCEDURE Write(t: IRC.Transport; VAR bytes: ARRAY OF CHAR; offset, count: LONGINT): LONGINT;
VAR n: LONGINT;
BEGIN
  WITH t: TCP DO n := Sockets.SendSome(t.socket, bytes, offset, count) END;
  IF Sockets.WouldBlock(n) OR Sockets.Interrupted(n) THEN RETURN IRC.WouldBlock END;
  IF n < 0 THEN RETURN -1 END;
  RETURN n
END Write;

PROCEDURE TakeDescriptor*(t: IRC.Transport): LONGINT;
BEGIN
  WITH t: TCP DO RETURN Sockets.Release(t.socket) END
END TakeDescriptor;

PROCEDURE New*(): IRC.Transport;
VAR t: TCP;
BEGIN
  NEW(t); t.socket := NIL; t.secure := FALSE;
  t.Open := Open; t.Poll := Poll; t.Read := Read; t.Write := Write; t.Close := Close;
  RETURN t
END New;

END IRCTCP.
