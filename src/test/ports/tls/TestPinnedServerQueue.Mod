MODULE TestPinnedServerQueue;
IMPORT Args, Out, Platform, TLS13Server, TLS := TLS13Live, TLSBytes, TLSIdentity;
VAR id: TLSIdentity.Identity; states: ARRAY 2 OF TLS.State; pins: ARRAY 2 OF TLSBytes.Buffer;
  pending: ARRAY 2 OF TLS13Server.Pending; results: ARRAY 2 OF INTEGER;
  cert, key, hex, arg, mode: ARRAY 4096 OF CHAR; data: ARRAY 32 OF CHAR;
  i, j, fd, n, started, first: LONGINT;

PROCEDURE Digit(c: CHAR): LONGINT;
BEGIN IF c <= "9" THEN RETURN ORD(c)-ORD("0") END; RETURN ORD(c)-ORD("a")+10 END Digit;

BEGIN
  Args.Get(1, cert); Args.Get(2, key); Args.Get(7, mode);
  IF ~TLSIdentity.Load(cert, key, id) THEN HALT(1) END;
  FOR j := 0 TO 1 DO
    Args.Get(SHORT(3+j*2), hex); Args.Get(SHORT(4+j*2), arg); TLSBytes.Init(pins[j]); i := 0;
    WHILE hex[i] # 0X DO TLSBytes.AppendByte(pins[j], Digit(hex[i])*16+Digit(hex[i+1])); INC(i, 2) END;
    fd := 0; i := 0;
    WHILE (arg[i] >= "0") & (arg[i] <= "9") DO fd := fd*10+ORD(arg[i])-ORD("0"); INC(i) END;
    TLS.Init(states[j]); pending[j] := NIL;
    IF ~TLS13Server.BeginEd25519(fd, id, pins[j], pending[j]) THEN HALT(2) END;
    results[j] := 0
  END;
  started := Platform.Time(); first := 0;
  IF mode = "stalled" THEN first := 1 END;
  REPEAT
    FOR j := 0 TO 1 DO
      IF results[j] = 0 THEN results[j] := TLS13Server.PollEd25519(pending[j], states[j]) END;
      IF results[j] < 0 THEN Out.String(TLS13Server.lastError); Out.Ln; HALT(3) END
    END;
    Platform.Delay(1);
    IF Platform.Time()-started > 15000 THEN HALT(4) END
  UNTIL (results[1] = 1) & ((first = 1) OR (results[0] = 1));
  IF first = 1 THEN
    IF (results[0] # 0) OR states[0].handshakeDone OR states[0].peerAuthenticated THEN HALT(5) END;
    TLS13Server.ClosePending(pending[0]); TLS13Server.ClosePending(pending[0])
  END;
  FOR j := first TO 1 DO
    IF (pending[j] # NIL) OR ~states[j].peerAuthenticated OR ~states[j].identitySent THEN HALT(6) END;
    REPEAT
      n := TLS.ReadSome(states[j], data, 0, LEN(data)-1); Platform.Delay(1);
      IF Platform.Time()-started > 15000 THEN HALT(7) END
    UNTIL n # -2;
    IF n <= 0 THEN HALT(8) END;
    data[n] := 0X; IF data # "hello" THEN HALT(9) END;
    data := "world";
    REPEAT
      n := TLS.WriteSome(states[j], data, 0, 5); Platform.Delay(1);
      IF Platform.Time()-started > 15000 THEN HALT(10) END
    UNTIL n # -2;
    IF n # 5 THEN HALT(11) END;
    TLS.CloseNow(states[j])
  END;
  TLSIdentity.Clear(id); Out.String("PASS pinned server concurrency "); Out.String(mode); Out.Ln
END TestPinnedServerQueue.
