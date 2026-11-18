MODULE TestPinnedClient;
IMPORT Args, Out, Platform, TLS := TLS13Live, TLSBytes, TLSIdentity;
VAR id: TLSIdentity.Identity; state: TLS.State; pin: TLSBytes.Buffer;
  cert, key, hex, arg, expected: ARRAY 4096 OF CHAR; data: ARRAY 32 OF CHAR;
  i, fd, started, n: LONGINT; result: INTEGER; begun: BOOLEAN;

PROCEDURE Digit(c: CHAR): LONGINT;
BEGIN IF c <= "9" THEN RETURN ORD(c)-ORD("0") END; RETURN ORD(c)-ORD("a")+10 END Digit;

BEGIN
  Args.Get(1, cert); Args.Get(2, key); Args.Get(3, hex); Args.Get(4, arg); Args.Get(5, expected);
  IF ~TLSIdentity.Load(cert, key, id) THEN HALT(1) END;
  TLSBytes.Init(pin); i := 0;
  WHILE hex[i] # 0X DO TLSBytes.AppendByte(pin, Digit(hex[i])*16+Digit(hex[i+1])); INC(i, 2) END;
  fd := 0; i := 0;
  WHILE (arg[i] >= "0") & (arg[i] <= "9") DO fd := fd*10+ORD(arg[i])-ORD("0"); INC(i) END;
  TLS.Init(state); begun := TLS.BeginEd25519("localhost", fd, id, pin, state);
  IF expected = "begin-reject" THEN
    IF begun OR state.connected OR state.handshakeDone OR state.peerAuthenticated OR (state.fd # -1) THEN HALT(2) END;
    HALT(0)
  END;
  IF ~begun THEN Out.String(TLS.lastError); Out.Ln; HALT(3) END;
  TLS.SetIdentity(NIL); pin.data[0] := CHR((ORD(pin.data[0])+1) MOD 256);
  data := "hello";
  IF state.handshakeDone OR state.peerAuthenticated OR state.identitySent OR
     (TLS.WriteSome(state, data, 0, 5) # -1) OR (TLS.ReadSome(state, data, 0, 5) # -1) THEN HALT(4) END;
  started := Platform.Time();
  REPEAT
    result := TLS.PollHandshake(state); Platform.Delay(1);
    IF Platform.Time()-started > 15000 THEN TLS.CloseNow(state); HALT(5) END
  UNTIL result # 0;
  IF expected = "reject" THEN
    IF (result # -1) OR state.connected OR state.handshakeDone OR state.peerAuthenticated OR state.identitySent OR
       (state.fd # -1) OR (TLS.WriteSome(state, data, 0, 5) # -1) OR (TLS.ReadSome(state, data, 0, 5) # -1) THEN HALT(6) END;
    Out.String(TLS.lastError); Out.Ln; HALT(0)
  END;
  IF (result # 1) OR ~state.peerAuthenticated OR ~state.identitySent THEN Out.String(TLS.lastError); Out.Ln; HALT(7) END;
  REPEAT
    n := TLS.WriteSome(state, data, 0, 5); Platform.Delay(1);
    IF Platform.Time()-started > 15000 THEN TLS.CloseNow(state); HALT(8) END
  UNTIL n # -2;
  IF n # 5 THEN HALT(9) END;
  REPEAT
    n := TLS.ReadSome(state, data, 0, LEN(data)-1); Platform.Delay(1);
    IF Platform.Time()-started > 15000 THEN TLS.CloseNow(state); HALT(10) END
  UNTIL n # -2;
  IF n <= 0 THEN HALT(11) END;
  data[n] := 0X; IF data # "world" THEN HALT(12) END;
  TLS.CloseNow(state); TLSIdentity.Clear(id); Out.String("PASS pinned client"); Out.Ln
END TestPinnedClient.
