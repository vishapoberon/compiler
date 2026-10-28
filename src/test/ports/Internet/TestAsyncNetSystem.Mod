MODULE TestAsyncNetSystem;

(* Loopback-only regressions; the Python runner supplies pending/refused peers. *)
IMPORT N := NetSystem, S := Sockets, Args, Out, Platform;

VAR checks: LONGINT; ip: N.IPAdr; address: S.Address; ok: BOOLEAN;
  mode: ARRAY 32 OF CHAR;

PROCEDURE Check(name: ARRAY OF CHAR; value: BOOLEAN);
BEGIN
  INC(checks);
  IF ~value THEN
    Out.String("TestAsyncNetSystem failed: "); Out.String(name); Out.Ln; HALT(1)
  END
END Check;

PROCEDURE Port(p: LONGINT): INTEGER;
BEGIN
  IF p >= 32768 THEN DEC(p, 65536) END;
  RETURN SHORT(p)
END Port;

PROCEDURE Argument(index: INTEGER): LONGINT;
VAR text: ARRAY 32 OF CHAR; i, n: LONGINT;
BEGIN
  Args.Get(index, text); i := 0; n := 0;
  WHILE (text[i] >= "0") & (text[i] <= "9") DO
    n := n*10 + ORD(text[i])-ORD("0"); INC(i)
  END;
  Check("port argument", (n > 0) & (n <= 65535)); RETURN n
END Argument;

PROCEDURE Connected(c: N.Connection): BOOLEAN;
VAR i: LONGINT; state: INTEGER;
BEGIN
  state := N.State(c); i := 0;
  WHILE (state = N.waitCon) & (i < 5000) DO
    Platform.Delay(1); state := N.State(c); INC(i)
  END;
  RETURN state = N.inout
END Connected;

PROCEDURE Basic;
VAR listener, reserve, peer, client: S.Socket; endpoint, local: S.Endpoint;
  c, passive, accepted: N.Connection; result, remotePort: INTEGER;
  remoteIP: N.IPAdr; i: LONGINT; byte: CHAR;
BEGIN
  listener := S.ListenNonblocking(address, 0, 4); Check("listener", listener # NIL);
  Check("listener endpoint", S.LocalEndpoint(listener, endpoint));
  reserve := S.ListenNonblocking(address, 0, 4); Check("reserve local port", reserve # NIL);
  Check("reserved endpoint", S.LocalEndpoint(reserve, local));
  N.AsyncOpenConnection(c, Port(local.port), ip, Port(endpoint.port), result);
  Check("busy local port rejected", (result = N.error) & (N.State(c) = N.errorCon));
  N.CloseConnection(c); S.Close(reserve);
  N.AsyncOpenConnection(c, Port(local.port), ip, Port(endpoint.port), result);
  Check("async started", (result = N.done) & (c.res = N.done));
  Check("async completed", Connected(c));
  peer := S.AcceptNonblocking(listener, endpoint); Check("accepted async peer", peer # NIL);
  Check("local port honored", endpoint.port = local.port);
  N.GetPartner(c, remoteIP, remotePort);
  Check("partner address", remoteIP = ip);
  Check("partner port", S.LocalEndpoint(listener, endpoint) & (remotePort = Port(endpoint.port)));
  Check("no data available", (N.Available(c) = 0) & (c.res = N.done));
  Check("peer write", S.SendString(peer, "A") = 1);
  N.Read(c, byte); Check("read after async", (byte = "A") & (c.res = N.done));
  N.Write(c, "B"); Check("write after async", c.res = N.done);
  N.CloseConnection(c); Check("closed", N.State(c) = N.closed);
  N.CloseConnection(c); S.Close(peer); S.Close(listener);
  N.AsyncOpenConnection(c, 0, N.allIP, 1, result);
  Check("broadcast rejected", (result = N.error) & (N.State(c) = N.errorCon));
  N.CloseConnection(c);

  reserve := S.ListenNonblocking(address, 0, 4); Check("passive port reservation", reserve # NIL);
  Check("passive endpoint", S.LocalEndpoint(reserve, local)); S.Close(reserve);
  N.AsyncOpenConnection(passive, Port(local.port), N.anyIP, N.anyport, result);
  Check("passive opened", (result = N.done) & (N.State(passive) = N.listening));
  Check("passive not requested", ~N.Requested(passive));
  client := S.ConnectFrom(address, address, local.port); Check("passive client", client # NIL);
  i := 0;
  WHILE ~N.Requested(passive) & (i < 5000) DO Platform.Delay(1); INC(i) END;
  Check("passive requested", N.Requested(passive));
  N.Accept(passive, accepted, result);
  Check("passive accepted", (result = N.done) & (N.State(accepted) = N.inout));
  N.CloseConnection(accepted); N.CloseConnection(passive); S.Close(client)
END Basic;

PROCEDURE Refused(port: LONGINT);
VAR c: N.Connection; result, state: INTEGER; i: LONGINT; byte: CHAR;
BEGIN
  N.AsyncOpenConnection(c, 0, ip, Port(port), result);
  Check("refusal start result", (result = N.done) OR (result = N.error));
  state := N.State(c); i := 0;
  WHILE (state = N.waitCon) & (i < 5000) DO
    Platform.Delay(1); state := N.State(c); INC(i)
  END;
  Check("refused connection", (state = N.errorCon) & (c.res = N.error));
  FOR i := 1 TO 32 DO
    Check("stable error state", N.State(c) = N.errorCon);
    Check("failed available", (N.Available(c) = 0) & (c.res = N.error))
  END;
  N.Read(c, byte); Check("failed read", c.res = N.error);
  N.Write(c, "x"); Check("failed write", c.res = N.error);
  N.CloseConnection(c); Check("failed connection closed", N.State(c) = N.closed)
END Refused;

PROCEDURE Pending(port, localPort: LONGINT);
VAR c: N.Connection; result: INTEGER; i, attempt: LONGINT; byte: CHAR; probe: S.Socket;
BEGIN
  FOR attempt := 1 TO 4 DO
    N.AsyncOpenConnection(c, Port(localPort), ip, Port(port), result);
    Check("pending started", (result = N.done) & (c.res = N.done));
    FOR i := 1 TO 32 DO
      Check("genuinely pending", N.State(c) = N.waitCon);
      Check("pending available", (N.Available(c) = 0) & (c.res = N.done));
      Platform.Delay(1)
    END;
    N.Read(c, byte); Check("pending read guarded", (c.res = N.error) & (N.State(c) = N.waitCon));
    N.Write(c, "x"); Check("pending write guarded", (c.res = N.error) & (N.State(c) = N.waitCon));
    N.CloseConnection(c); Check("pending canceled", N.State(c) = N.closed);
    N.CloseConnection(c);
    probe := S.ListenNonblocking(address, localPort, 1);
    Check("cancellation released descriptor and port", probe # NIL); S.Close(probe)
  END
END Pending;

PROCEDURE BlockingPeer(port: LONGINT);
VAR c: N.Connection; result: INTEGER; data: ARRAY 65536 OF CHAR;
  reply: ARRAY 8 OF CHAR; i: LONGINT; byte: CHAR;
BEGIN
  N.AsyncOpenConnection(c, 0, ip, Port(port), result);
  Check("blocking test started", result = N.done); Check("blocking test connected", Connected(c));
  N.ReadBytes(c, 0, LEN(reply), reply);
  Check("delayed fragmented exact read", (c.res = N.done) & (reply = "abcdefg"));
  FOR i := 0 TO LEN(data)-1 DO data[i] := "x" END;
  FOR i := 1 TO 128 DO
    N.WriteBytes(c, 0, LEN(data), data); Check("backpressured exact write", c.res = N.done)
  END;
  N.Read(c, byte); Check("peer verified complete write", (c.res = N.done) & (byte = "Y"));
  N.CloseConnection(c)
END BlockingPeer;

PROCEDURE Resume(port: LONGINT);
VAR c: N.Connection; result: INTEGER; byte: CHAR;
BEGIN
  N.AsyncOpenConnection(c, 0, ip, Port(port), result);
  Check("resume started pending", (result = N.done) & (N.State(c) = N.waitCon));
  Check("resume initially empty", (N.Available(c) = 0) & (c.res = N.done));
  Out.String("NetSystem resume pending"); Out.Ln;
  Check("pending became connected", Connected(c));
  N.Write(c, "Q"); Check("resumed write", c.res = N.done);
  N.Read(c, byte); Check("resumed read", (c.res = N.done) & (byte = "R"));
  N.CloseConnection(c)
END Resume;

BEGIN
  checks := 0; N.ToHost("127.0.0.1", ip, ok); Check("IPv4 loopback", ok);
  Check("socket loopback", S.ParseAddress("127.0.0.1", address));
  Args.Get(1, mode);
  IF mode = "pending" THEN Pending(Argument(2), Argument(3))
  ELSIF mode = "refused" THEN Refused(Argument(2))
  ELSIF mode = "blocking" THEN BlockingPeer(Argument(2))
  ELSIF mode = "resume" THEN Resume(Argument(2))
  ELSE Basic
  END;
  Out.String("TestAsyncNetSystem "); Out.String(mode);
  Out.String(" checks passed: "); Out.Int(checks, 0); Out.Ln
END TestAsyncNetSystem.
