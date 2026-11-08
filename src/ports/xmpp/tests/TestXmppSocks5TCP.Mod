MODULE TestXmppSocks5TCP;

IMPORT Out, Msg, Platform, Sockets, K := XmppSocks5, TCP := XmppSocks5TCP;

CONST destination = "416781edf1ae50bad01cb8509ba35b43952bc345";
VAR checks: LONGINT;

PROCEDURE Check(ok: BOOLEAN; label: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("SOCKS5 TCP check failed: "); Out.String(label); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE Listen(VAR address: Sockets.Address; VAR port: LONGINT): Sockets.Socket;
  VAR listener: Sockets.Socket; text: ARRAY 16 OF CHAR;
BEGIN
  text := "127.0.0.1"; ASSERT(Sockets.ParseAddress(text, address)); listener := Sockets.ListenNonblocking(address, 0, 1);
  ASSERT((listener # NIL) & Sockets.LocalAddress(listener, address, port)); RETURN listener
END Listen;

PROCEDURE Exchange(mode: LONGINT);
  VAR listener, server, released: Sockets.Socket; address: Sockets.Address; peer: Sockets.Endpoint;
    client: TCP.Client; error: Msg.Msg; request, reply: ARRAY 50 OF CHAR; hash: ARRAY 41 OF CHAR;
    port, turns, phase, have, sent, need, n, i, descriptor: LONGINT; state: SHORTINT;
BEGIN
  hash := destination; listener := Listen(address, port); client := TCP.OpenAddress(address, port, destination, 1000, error);
  ASSERT((client # NIL) & (error = NIL)); Check(client.Release() = NIL, "retaining socket during negotiation");
  server := NIL; phase := 0; have := 0; sent := 0; turns := 0;
  REPEAT
    INC(turns); ASSERT(turns < 2000); state := client.Step();
    IF server = NIL THEN server := Sockets.AcceptNonblocking(listener, peer) END;
    IF server # NIL THEN
      IF (phase = 0) OR (phase = 2) THEN
        IF phase = 0 THEN need := 3 ELSE need := 47 END;
        n := Sockets.ReceiveSome(server, request, have, need-have);
        IF n > 0 THEN INC(have, n) END;
        IF have = need THEN
          ASSERT((request[0] = 5X) & (request[1] = 1X) & (request[2] = 0X));
          IF phase = 0 THEN reply[0] := 5X; reply[1] := 0X; need := 2
          ELSE
            ASSERT((request[3] = 3X) & (request[4] = CHR(40)) & (request[45] = 0X) & (request[46] = 0X));
            FOR i := 0 TO 39 DO ASSERT(request[5+i] = hash[i]) END;
            FOR i := 0 TO 46 DO reply[i] := request[i] END; reply[1] := 0X;
            reply[47] := 0X; reply[48] := 0FFX; reply[49] := 80X; need := 50;
            IF mode = 2 THEN reply[1] := 5X END;
            IF mode = 3 THEN need := 20 END
          END;
          INC(phase); sent := 0
        END
      ELSIF (phase = 1) OR (phase = 3) THEN
        n := need-sent; IF (mode = 0) & ((phase = 1) OR (sent < 46)) THEN n := 1 END;
        n := Sockets.SendSome(server, reply, sent, n); IF n > 0 THEN INC(sent, n) END;
        IF sent = need THEN
          INC(phase); have := 0;
          IF (mode = 3) & (phase = 4) THEN Sockets.Close(server) END
        END
      END
    END;
    Platform.Delay(1); client.Tick(1)
  UNTIL (state = TCP.ready) OR (state = TCP.failed);
  IF mode < 2 THEN
    Check(state = TCP.ready, "completing fragmented or coalesced local handshake");
    descriptor := client.Descriptor(); released := client.Release();
    Check((released # NIL) & (released.fd = descriptor) & (client.Descriptor() = -1) & (client.Release() = NIL), "transferring socket ownership once");
    client.Cancel; Check(released.fd = descriptor, "preserving handed-off socket on cancellation");
    have := 0; turns := 0;
    REPEAT
      n := Sockets.ReceiveSome(released, request, have, 3-have); IF n > 0 THEN INC(have, n) END;
      INC(turns); ASSERT(turns < 1000); Platform.Delay(1)
    UNTIL have = 3;
    Check((request[0] = 0X) & (request[1] = 0FFX) & (request[2] = 80X), "preserving binary payload queued after handshake");
    Sockets.Close(released)
  ELSE
    Check((state = TCP.failed) & (client.Descriptor() = -1) & (client.error # NIL), "closing malformed or truncated negotiation");
    IF mode = 2 THEN Check(client.error.code = TCP.protocolError, "reporting refused SOCKS5 negotiation")
    ELSE Check(client.error.code = TCP.ioError, "reporting truncated SOCKS5 negotiation") END
  END;
  Sockets.Close(server); Sockets.Close(listener)
END Exchange;

PROCEDURE Failures;
  VAR listener: Sockets.Socket; address: Sockets.Address; port, i: LONGINT; client: TCP.Client; error: Msg.Msg; state: SHORTINT;
    host: ARRAY 254 OF CHAR;
BEGIN
  listener := Listen(address, port); client := TCP.Open("127.0.0.1", port, destination, 10, error); ASSERT(client # NIL);
  client.Tick(10); Check((client.state = TCP.failed) & (client.error.code = TCP.timedOut) & (client.Descriptor() = -1), "enforcing caller-driven deadline");
  client.Cancel; Check(client.error.code = TCP.timedOut, "preserving terminal error");
  client := TCP.OpenAddress(address, port, destination, 10, error); ASSERT(client # NIL); client.Cancel;
  Check((client.state = TCP.failed) & (client.error.code = TCP.cancelled) & (client.Descriptor() = -1), "cancelling owned socket");
  Sockets.Close(listener); client := TCP.OpenAddress(address, port, destination, 100, error);
  IF client # NIL THEN
    REPEAT state := client.Step(); Platform.Delay(1); client.Tick(1) UNTIL state = TCP.failed;
    error := client.error
  END;
  Check((error # NIL) & (error.code = TCP.connectError), "reporting refused TCP connection");
  Check(TCP.OpenAddress(address, 0, destination, 1, error) = NIL, "rejecting invalid port");
  Check(TCP.OpenAddress(address, port, destination, 0, error) = NIL, "rejecting invalid deadline");
  host := "[::1"; Check(TCP.Open(host, port, destination, 1, error) = NIL, "rejecting unmatched bracket");
  host := "::12345"; Check(TCP.Open(host, port, destination, 1, error) = NIL, "bounding IPv6 groups");
  FOR i := 0 TO 252 DO host[i] := "9" END; host[253] := 0X;
  Check(TCP.Open(host, port, destination, 1, error) = NIL, "bounding numeric parsing before overflow");
  host := "::ffff:9999.1.1.1"; Check(TCP.Open(host, port, destination, 1, error) = NIL, "rejecting invalid embedded IPv4")
END Failures;

BEGIN
  Exchange(0); Exchange(1); Exchange(2); Exchange(3); Failures;
  Out.String("XMPP SOCKS5 TCP checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppSocks5TCP.
