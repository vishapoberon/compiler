MODULE TestEd25519Server;
IMPORT Args, Out, TLS13Server, TLS13Live;
VAR id: TLS13Server.Identity; state: TLS13Live.State;
  cert, key, arg, mode: ARRAY 4096 OF CHAR; fd, i, n: LONGINT; data: ARRAY 16 OF CHAR;
BEGIN
  Args.Get(1, cert); Args.Get(2, key); Args.Get(3, arg); Args.Get(4, mode);
  fd := 0; i := 0;
  WHILE (arg[i] >= "0") & (arg[i] <= "9") DO fd := fd*10+ORD(arg[i])-ORD("0"); INC(i) END;
  IF ~TLS13Server.Load(cert, key, id) THEN HALT(1) END;
  IF ~TLS13Server.Accept(fd, id, state) THEN
    Out.String(TLS13Server.lastError); Out.Ln;
    IF mode = "reject" THEN HALT(0) ELSE HALT(2) END
  END;
  IF mode = "reject" THEN TLS13Live.CloseNow(state); HALT(3) END;
  IF ~TLS13Live.ReadApp(state, data, n) OR (n # 5) OR (data # "hello") THEN HALT(4) END;
  IF ~TLS13Live.WriteAppString(state, "world") THEN HALT(5) END;
  TLS13Live.Disconnect(state)
END TestEd25519Server.
