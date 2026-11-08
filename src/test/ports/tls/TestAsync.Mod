MODULE TestAsync;
IMPORT TLS := TLS13Live, Internet, Args, Platform, Out;
VAR s: TLS.State; fd: Internet.Socket; host, port, mode: ARRAY 256 OF CHAR;
  data: ARRAY 1024 OF CHAR; result: INTEGER; n, started: LONGINT; ok: BOOLEAN;
BEGIN
  Args.Get(1, host); Args.Get(2, port); Args.Get(3, mode); TLS.Init(s);
  IF ~Internet.Connect(host, port, fd) THEN HALT(1) END;
  IF mode = "blocking" THEN
    ok := TLS.Start(host, fd, s); IF ~ok THEN HALT(4) END
  ELSE
    IF ~TLS.Begin(host, fd, s) THEN HALT(2) END;
    started := Platform.Time();
    REPEAT
      result := TLS.PollHandshake(s); Platform.Delay(1);
      IF Platform.Time() - started > 30000 THEN TLS.CloseNow(s); HALT(3) END
    UNTIL result # 0;
    IF result < 0 THEN
      Out.String(TLS.lastError); Out.Ln;
      IF mode = "reject" THEN HALT(0) ELSE HALT(4) END
    END;
    IF mode = "reject" THEN TLS.CloseNow(s); HALT(7) END
  END;
  data := "hello";
  IF mode = "blocking" THEN
    ok := TLS.WriteAppString(s, data); IF ~ok THEN HALT(5) END;
    ok := TLS.ReadApp(s, data, n); IF ~ok THEN HALT(6) END
  ELSE
    REPEAT n := TLS.WriteSome(s, data, 0, 5); Platform.Delay(1) UNTIL n # -2;
    IF n # 5 THEN HALT(5) END;
    REPEAT n := TLS.ReadSome(s, data, 0, LEN(data) - 1); Platform.Delay(1) UNTIL n # -2;
    IF n <= 0 THEN Out.String(TLS.lastError); Out.Ln; HALT(6) END
  END;
  data[n] := 0X; ASSERT(data = "world"); TLS.CloseNow(s);
  Out.String("PASS: TLS transport "); Out.String(mode); Out.Ln
END TestAsync.
