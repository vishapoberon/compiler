MODULE TestTLSListener;
IMPORT Args, Sockets, TLS13Server, TLS13Live, Out;
VAR cert, key, arg: ARRAY 1024 OF CHAR; port, i, peerPort, got: LONGINT;
  id: TLS13Server.Identity; state: TLS13Live.State;
  address, peer: Sockets.Address; listener, connection: Sockets.Socket;
  request: ARRAY 32 OF CHAR;
BEGIN
  Args.Get(1, cert); Args.Get(2, key); Args.Get(3, arg);
  port := 0; i := 0;
  WHILE (arg[i] >= "0") & (arg[i] <= "9") DO port := port * 10 + ORD(arg[i]) - ORD("0"); INC(i) END;
  ASSERT(TLS13Server.Load(cert, key, id));
  ASSERT(Sockets.ParseAddress("127.0.0.1", address));
  listener := Sockets.ListenAt(address, port, 1); ASSERT(listener # NIL);
  Out.String("ready"); Out.Ln;
  connection := Sockets.Accept(listener, peer, peerPort); ASSERT(connection # NIL);
  Sockets.SetTimeout(connection, 10000);
  ASSERT(TLS13Server.Accept(connection.fd, id, state));
  ASSERT(TLS13Live.ReadAppMax(state, request, 4, got));
  ASSERT(got = 4); ASSERT(request = "ping");
  ASSERT(TLS13Live.WriteAppString(state, "pong"));
  TLS13Live.Disconnect(state);
  Sockets.Close(listener);
  Out.String("TLS listener passed"); Out.Ln
END TestTLSListener.
