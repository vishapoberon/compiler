MODULE TestAsyncRecords;
IMPORT TLS := TLS13Live, B := TLSBytes, Keys := TLS13Keys, Records := TLS13Records,
  HKDF := TLSHKDF, Sockets, Platform, Out;
VAR listener, peer, accepted: Sockets.Socket; local: Sockets.Address; endpoint, remote: Sockets.Endpoint;
  state: TLS.State; a, b, keyA, ivA, keyB, ivB, plain, record, empty, next: B.Buffer;
  received: B.Buffer; bytes: ARRAY 128 OF CHAR; n, i, kind, started: LONGINT; ok: BOOLEAN;

PROCEDURE Send(at, count: LONGINT);
VAR n, done: LONGINT;
BEGIN
  done := 0;
  WHILE done < count DO
    n := Sockets.SendSome(peer, record.data, at + done, count - done);
    ASSERT(n > 0); INC(done, n)
  END
END Send;

PROCEDURE Pump;
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO 9 DO n := TLS.ReadSome(state, bytes, 0, LEN(bytes)); ASSERT(n = -2) END
END Pump;

PROCEDURE GetRecord;
VAR count, need, n, started: LONGINT;
BEGIN
  count := 0; need := 5; started := Platform.Time();
  WHILE count < need DO
    n := Sockets.ReceiveSome(peer, received.data, count, need - count);
    IF n > 0 THEN INC(count, n)
    ELSE ASSERT(Sockets.WouldBlock(n)); Platform.Delay(1)
    END;
    IF count = 5 THEN need := 5 + LONG(ORD(received.data[3])) * 256 + ORD(received.data[4]) END;
    ASSERT(Platform.Time() - started < 3000)
  END;
  received.len := need
END GetRecord;

BEGIN
  Sockets.AnyAddress(Sockets.Inet4, local); listener := Sockets.ListenNonblocking(local, 0, 2);
  ASSERT(listener # NIL); ASSERT(Sockets.LocalEndpoint(listener, endpoint));
  ASSERT(Sockets.ParseAddress("127.0.0.1", endpoint.address));
  peer := Sockets.ConnectFrom(local, endpoint.address, endpoint.port); ASSERT(peer # NIL);
  started := Platform.Time();
  REPEAT n := Sockets.PollConnect(peer); ASSERT(n >= 0); Platform.Delay(1);
    ASSERT(Platform.Time() - started < 3000)
  UNTIL n = 0;
  accepted := Sockets.AcceptNonblocking(listener, remote); ASSERT(accepted # NIL); Sockets.Close(listener);
  B.SetLen(a, 32); B.SetLen(b, 32);
  FOR i := 0 TO 31 DO a.data[i] := CHR(i); b.data[i] := CHR(i + 32) END;
  TLS.Accepted(state, Sockets.Release(accepted), a, b); ASSERT(TLS.UseNonblocking(state));
  Keys.TrafficKey(a, keyA); Keys.TrafficIV(a, ivA); Keys.TrafficKey(b, keyB); Keys.TrafficIV(b, ivB);
  B.Init(plain); B.AppendString(plain, "abc");
  Records.ProtectRecord(keyB, ivB, 0, Records.ApplicationData, plain, record);
  Send(0, 2); Pump; Send(2, 3); Pump; Send(5, 1); Pump; Send(6, record.len - 6);
  REPEAT n := TLS.ReadSome(state, bytes, 0, LEN(bytes)) UNTIL n # -2;
  ASSERT(n = 3); ASSERT(bytes[0] = "a"); ASSERT(bytes[2] = "c");

  B.Init(plain); B.AppendByte(plain, 24); B.PutBE24(plain, 1); B.AppendByte(plain, 1);
  Records.ProtectRecord(keyB, ivB, 1, Records.Handshake, plain, record); Send(0, record.len);
  started := Platform.Time();
  REPEAT
    n := TLS.ReadSome(state, bytes, 0, LEN(bytes)); ASSERT(n = -2); Platform.Delay(1);
    ASSERT(Platform.Time() - started < 3000)
  UNTIL state.serverAppSeq = 0;
  REPEAT n := TLS.FlushOutput(state); Platform.Delay(1) UNTIL n # 0;
  ASSERT(n = 1);
  B.Init(empty); HKDF.ExpandLabel(b, "traffic upd", empty, 32, next); B.Copy(next, b);
  Keys.TrafficKey(b, keyB); Keys.TrafficIV(b, ivB);
  ASSERT(B.EqualConstTime(keyB, state.serverAppKey)); ASSERT(state.serverAppSeq = 0);
  GetRecord;
  ASSERT(Records.OpenRecord(keyA, ivA, 0, received, kind, plain)); ASSERT(kind = Records.Handshake);
  ASSERT(plain.len = 5); ASSERT(ORD(plain.data[4]) = 0);
  HKDF.ExpandLabel(a, "traffic upd", empty, 32, next); B.Copy(next, a);
  Keys.TrafficKey(a, keyA); Keys.TrafficIV(a, ivA);
  ASSERT(B.EqualConstTime(keyA, state.clientAppKey));
  bytes := "after update";
  REPEAT n := TLS.WriteSome(state, bytes, 0, 12) UNTIL n # -2;
  ASSERT(n = 12); GetRecord;
  ASSERT(Records.OpenRecord(keyA, ivA, 0, received, kind, plain)); ASSERT(kind = Records.ApplicationData);
  ASSERT(plain.len = 12);
  B.Init(plain); B.AppendByte(plain, 1); B.AppendByte(plain, 0);
  Records.ProtectRecord(keyB, ivB, 0, Records.Alert, plain, record); Send(0, record.len);
  REPEAT n := TLS.ReadSome(state, bytes, 0, LEN(bytes)) UNTIL n # -2;
  ASSERT(n = 0); ASSERT(state.closeNotify);
  TLS.CloseNow(state); Sockets.Close(peer);
  Out.String("PASS: partial TLS records, KeyUpdate request/response, new keys and close_notify"); Out.Ln
END TestAsyncRecords.
