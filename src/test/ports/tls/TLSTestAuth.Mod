MODULE TLSTestAuth;
IMPORT Out, TLSBytes, TLSIdentity, TLSCertGen, TLS13Auth, TLSNow, TLSX509Validity;
VAR checks, failures, i: LONGINT; seed: ARRAY 32 OF CHAR;
  cert, pin, spki, message, parsed, transcript, saved: TLSBytes.Buffer;
  now, later: TLSX509Validity.Time; id: TLSIdentity.Identity;

PROCEDURE Check(ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(failures); Out.String("FAIL TLS authentication case "); Out.Int(checks, 0); Out.Ln END
END Check;

BEGIN
  FOR i := 0 TO 31 DO seed[i] := CHR(i) END;
  Check(TLSCertGen.Ed25519SelfSigned("peer", seed, 1, cert));
  Check(TLSIdentity.FromEd25519(seed, cert, id)); Check(TLSIdentity.PublicKey(id^, pin));
  TLSNow.Current(now); later := now; INC(later.year, 10);
  Check(TLS13Auth.PinnedEd25519(cert, pin, now, TRUE, spki));
  Check(TLS13Auth.PinnedEd25519(cert, pin, now, FALSE, spki));
  Check(~TLS13Auth.PinnedEd25519(cert, pin, later, TRUE, spki) & (spki.len = 0));
  later := now; DEC(later.year, 1);
  Check(~TLS13Auth.PinnedEd25519(cert, pin, later, TRUE, spki));
  pin.data[0] := CHR(ORD(pin.data[0])+1); Check(~TLS13Auth.PinnedEd25519(cert, pin, now, TRUE, spki));
  pin.data[0] := CHR(ORD(pin.data[0])-1); DEC(pin.len); Check(~TLS13Auth.PinnedEd25519(cert, pin, now, TRUE, spki)); INC(pin.len);
  TLSBytes.Copy(cert, saved); TLSBytes.AppendByte(cert, 0); Check(~TLS13Auth.PinnedEd25519(cert, pin, now, TRUE, spki));
  TLSBytes.Copy(saved, cert); cert.data[cert.len-1] := CHR(ORD(cert.data[cert.len-1])+1);
  Check(~TLS13Auth.PinnedEd25519(cert, pin, now, TRUE, spki)); TLSBytes.Copy(saved, cert);
  Check(TLS13Auth.PinnedEd25519(cert, pin, now, TRUE, spki));
  Check(TLS13Auth.Present(id, message)); Check(TLS13Auth.Certificate(message, parsed)); Check(TLSBytes.EqualConstTime(parsed, cert));
  TLSBytes.Copy(message, saved);
  FOR i := 0 TO saved.len-1 DO message.len := i; Check(~TLS13Auth.Certificate(message, parsed) & (parsed.len = 0)) END;
  TLSBytes.Copy(saved, message); TLSBytes.AppendByte(message, 0); Check(~TLS13Auth.Certificate(message, parsed));
  TLSBytes.Copy(saved, message); message.data[4] := 1X; Check(~TLS13Auth.Certificate(message, parsed));
  TLSBytes.Copy(saved, message); message.data[7] := CHR(ORD(message.data[7])+1); Check(~TLS13Auth.Certificate(message, parsed));
  TLSBytes.Copy(saved, message); message.data[message.len-1] := 1X; Check(~TLS13Auth.Certificate(message, parsed));
  TLSBytes.Init(transcript); TLSBytes.AppendString(transcript, "TLS authentication transcript");
  Check(TLS13Auth.Sign(id, transcript, TRUE, message)); Check(TLS13Auth.Verify(message, transcript, spki, TRUE));
  Check(~TLS13Auth.Verify(message, transcript, spki, FALSE));
  TLSBytes.Copy(message, saved);
  FOR i := 0 TO 71 DO message.len := i; Check(~TLS13Auth.Verify(message, transcript, spki, TRUE)) END;
  TLSBytes.Copy(saved, message); message.data[5] := 4X; Check(~TLS13Auth.Verify(message, transcript, spki, TRUE));
  TLSBytes.Copy(saved, message); message.data[message.len-1] := CHR(ORD(message.data[message.len-1])+1);
  Check(~TLS13Auth.Verify(message, transcript, spki, TRUE));
  TLSBytes.Copy(saved, message); TLSBytes.AppendByte(transcript, 0); Check(~TLS13Auth.Verify(message, transcript, spki, TRUE));
  Check(TLS13Auth.Sign(id, transcript, FALSE, message)); Check(TLS13Auth.Verify(message, transcript, spki, FALSE));
  Check(~TLS13Auth.Verify(message, transcript, spki, TRUE));
  TLS13Auth.Request(message); Check((message.len = 15) & (message.data[0] = 0DX) & (message.data[14] = 7X));
  TLSIdentity.Clear(id); Check(~TLS13Auth.Sign(id, transcript, TRUE, message) & (message.len = 0));
  Check(~TLS13Auth.Present(id, message) & (message.len = 0));
  Out.String("TLSTestAuth: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(failures, 0); Out.String(" failed"); Out.Ln;
  IF failures # 0 THEN HALT(100) END
END TLSTestAuth.
