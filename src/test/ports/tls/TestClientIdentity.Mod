MODULE TestClientIdentity;
IMPORT Args, Out, Platform, Strings, TLS := TLS13Live, TLSIdentity;
VAR id: TLSIdentity.Identity; state: TLS.State;
  cert, key, arg, mode, expected, data: ARRAY 4096 OF CHAR;
  fd, i, n, sent, started, length: LONGINT; result: INTEGER;
BEGIN
  Args.Get(1, cert); Args.Get(2, key); Args.Get(3, arg); Args.Get(4, mode); Args.Get(5, expected);
  IF ~TLSIdentity.Load(cert, key, id) THEN HALT(1) END;
  TLS.SetIdentity(id); fd := 0; i := 0;
  WHILE (arg[i] >= "0") & (arg[i] <= "9") DO fd := fd*10+ORD(arg[i])-ORD("0"); INC(i) END;
  TLS.Init(state);
  IF mode = "blocking" THEN
    IF ~TLS.Start("localhost", fd, state) THEN Out.String(TLS.lastError); Out.Ln; HALT(2) END
  ELSE
    IF ~TLS.Begin("localhost", fd, state) THEN HALT(3) END;
    started := Platform.Time();
    REPEAT
      result := TLS.PollHandshake(state); Platform.Delay(1);
      IF Platform.Time()-started > 15000 THEN TLS.CloseNow(state); HALT(4) END
    UNTIL result # 0;
    IF result < 0 THEN Out.String(TLS.lastError); Out.Ln; HALT(5) END
  END;
  IF TLS.identitySent # (expected = "sent") THEN TLS.CloseNow(state); HALT(6) END;
  data := "GET / HTTP/1.0"; length := 14;
  data[length] := 0DX; data[length+1] := 0AX; data[length+2] := 0DX; data[length+3] := 0AX;
  INC(length, 4); data[length] := 0X;
  IF mode = "blocking" THEN
    IF ~TLS.WriteAppString(state, data) OR ~TLS.ReadAppMax(state, data, LEN(data)-1, n) THEN HALT(7) END
  ELSE
    sent := 0; started := Platform.Time();
    REPEAT
      n := TLS.WriteSome(state, data, sent, length-sent);
      IF n > 0 THEN INC(sent, n) ELSIF n # -2 THEN HALT(8) END;
      Platform.Delay(1);
      IF Platform.Time()-started > 15000 THEN TLS.CloseNow(state); HALT(9) END
    UNTIL sent = length;
    REPEAT
      n := TLS.ReadSome(state, data, 0, LEN(data)-1); Platform.Delay(1);
      IF Platform.Time()-started > 15000 THEN TLS.CloseNow(state); HALT(10) END
    UNTIL n # -2;
    IF n <= 0 THEN HALT(11) END
  END;
  data[n] := 0X;
  IF Strings.Pos("HTTP/1.0 200", data, 0) # 0 THEN HALT(12) END;
  TLS.CloseNow(state); Out.String("PASS client identity "); Out.String(expected); Out.Ln
END TestClientIdentity.
