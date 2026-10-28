MODULE TestAsyncSockets;

IMPORT S := Sockets, Out;

VAR checks: LONGINT;

PROCEDURE Check(value: BOOLEAN);
BEGIN
  INC(checks);
  IF ~value THEN Out.String("TestAsyncSockets failed: "); Out.Int(checks, 0); Out.Ln; HALT(1) END
END Check;

PROCEDURE Pair(VAR listener, client, peer: S.Socket);
  VAR address: S.Address; endpoint: S.Endpoint; i: LONGINT;
BEGIN
  Check(S.ParseAddress("::1", address));
  listener := S.ListenNonblocking(address, 0, 4); Check(listener # NIL);
  Check(S.LocalEndpoint(listener, endpoint)); Check(endpoint.port > 0);
  Check((endpoint.address.family = S.Inet6) & (endpoint.scope = 0));
  Check(S.AcceptNonblocking(listener, endpoint) = NIL); Check(S.WouldBlock(listener.res));
  Check(S.LocalEndpoint(listener, endpoint));
  client := S.ConnectFrom(address, address, endpoint.port); Check(client # NIL);
  peer := NIL; i := 0;
  WHILE (peer = NIL) & (i < 100000) DO peer := S.AcceptNonblocking(listener, endpoint); INC(i) END;
  Check(peer # NIL); Check(S.ConnectError(client) = 0);
  Check(S.LocalEndpoint(client, endpoint)); Check(endpoint.scope = 0);
  Check(endpoint.address.addr[15] = 1X);
  Check(S.PeerEndpoint(peer, endpoint)); Check(endpoint.scope = 0);
  Check(endpoint.address.addr[15] = 1X)
END Pair;

PROCEDURE Run;
  VAR listener, client, peer, owner: S.Socket; address, other: S.Address; endpoint: S.Endpoint;
    data, input: ARRAY 65536 OF CHAR; i, n, sent, received, fd: LONGINT;
BEGIN
  Check(S.ParseAddress("::1", address)); Check(S.ParseAddress("127.0.0.1", other));
  Check(S.ListenNonblocking(address, -1, 4) = NIL);
  Check(S.ListenNonblocking(address, 65536, 4) = NIL);
  Check(S.ConnectFrom(address, other, 80) = NIL);
  Check(S.ConnectFrom(address, address, 0) = NIL);
  Check(S.ReadDescriptor(-1, data, 0, 1) < 0);
  Check(S.WriteDescriptor(-1, data, 0, 1) < 0);
  Check(S.PollConnect(NIL) < 0); Check(~S.SetBlocking(NIL, TRUE));
  Check(S.ConnectFromPort(address, address, -1, 80) = NIL);
  Check(S.ConnectFromPort(address, address, 65536, 80) = NIL);
  Pair(listener, client, peer);
  Check(S.PollConnect(client) = 0);
  Check(S.SetBlocking(client, TRUE)); Check(S.SetBlocking(client, FALSE));
  Check(S.ReceiveSome(peer, input, 0, LEN(input)) < 0); Check(S.WouldBlock(peer.res));
  Check(S.SendSome(client, data, -1, 1) < 0);
  Check(S.SendSome(client, data, 0, -1) < 0);
  Check(S.SendSome(client, data, LEN(data), 1) < 0);
  Check(S.SendSome(client, data, 1, MAX(LONGINT)) < 0);
  Check(S.SendSome(client, data, LEN(data), 0) = 0);
  FOR i := 0 TO 255 DO data[i] := CHR(i) END;
  sent := 0;
  WHILE sent < 256 DO
    n := S.SendSome(client, data, sent, 256-sent); Check(n > 0); INC(sent, n)
  END;
  received := 0; i := 0;
  WHILE (received < sent) & (i < 100000) DO
    n := S.ReceiveSome(peer, input, received, sent-received);
    IF n > 0 THEN INC(received, n) ELSE Check(S.WouldBlock(n) OR S.Interrupted(n)) END;
    INC(i)
  END;
  Check(received = sent);
  FOR i := 0 TO 255 DO Check(input[i] = data[i]) END;
  sent := 0; i := 0; n := 1;
  WHILE (n > 0) & (i < 1024) DO
    n := S.SendSome(client, data, 0, LEN(data));
    IF n > 0 THEN INC(sent, n) END; INC(i)
  END;
  Check(sent > 0); Check(S.WouldBlock(n));
  Check(S.AbortDescriptor(client.fd)); S.Close(client);
  i := 0; n := 1;
  WHILE (n >= 0) & (i < 100000) DO
    n := S.ReceiveSome(peer, input, 0, LEN(input)); INC(i);
    IF S.WouldBlock(n) OR S.Interrupted(n) THEN n := 1 END
  END;
  Check((n < 0) & ~S.WouldBlock(n)); S.Close(peer); S.Close(listener);
  Check(~S.LocalEndpoint(listener, endpoint));
  Pair(listener, client, peer);
  fd := S.Release(client); Check((fd >= 0) & (client.fd = -1)); S.Close(client);
  Check(S.WriteDescriptor(fd, data, 0, 1) = 1);
  n := -1; i := 0;
  WHILE (n < 0) & (i < 100000) DO n := S.ReceiveSome(peer, input, 0, 1); INC(i) END;
  Check((n = 1) & (input[0] = data[0]));
  NEW(owner); owner.fd := fd; owner.res := 0; S.Close(owner);
  Check(S.WriteDescriptor(fd, data, 0, 1) < 0); S.Close(peer); S.Close(listener);
  listener := S.ListenAt(address, 0, 4); Check(listener # NIL);
  Check(S.LocalAddress(listener, address, fd)); client := S.Connect(address, fd); Check(client # NIL);
  peer := S.Accept(listener, other, fd); Check(peer # NIL);
  Check(S.SendString(client, "blocking API preserved") = 22);
  S.SetTimeout(peer, 1000); n := S.Receive(peer, input, LEN(input));
  Check(n = 22); input[n] := 0X; Check(input = "blocking API preserved");
  S.Close(client); S.Close(peer); S.Close(listener)
END Run;

BEGIN
  checks := 0; Run;
  Out.String("TestAsyncSockets checks passed: "); Out.Int(checks, 0); Out.Ln
END TestAsyncSockets.
