MODULE TLS13Live;
IMPORT SYSTEM, Linux0 := unixNet, Out,
       Internet, TLSBytes, TLS13Random, TLSX25519,
       TLS13Handshake, TLS13Keys, TLS13Records,
       TLS13EncHandshake, TLS13ClientFinished, TLS13Application,
       TLSCABundle, TLSX509Validity, TLSNow, TLSX509Chain, TLSHKDF, TLSECDSA, TLSX509, TLSSHA256, TLSIdentity;

CONST
  MaxRecord = 16640;          (* 2^14 + 256, the longest TLSCiphertext (RFC 8446 5.2) *)
  MaxPlain = 16384;           (* 2^14 *)
  CloseNotify = 0; UserCanceled = 90;           (* alert descriptions *)
  NewSessionTicket = 4; KeyUpdate = 24;         (* post-handshake messages *)
  SecretLen = 32;             (* SHA-256 *)
  (* the alerts we send when we give up (RFC 8446 6.2) *)
  UnexpectedMessage = 10; BadRecordMac = 20; RecordOverflow = 22; HandshakeFailure = 40;
  BadCertificate = 42; CertificateExpired = 45; IllegalParameter = 47; UnknownCA = 48;
  DecodeError = 50; DecryptError = 51; InternalError = 80;

TYPE
  Chain = POINTER TO ChainDesc;
  ChainDesc = RECORD
    certs: ARRAY 8 OF TLSBytes.Buffer;
    ca: TLSCABundle.Bundle;
    leaf: TLSX509.CertInfo
  END;

  State* = RECORD
    fd*: Internet.Socket;
    connected*: BOOLEAN;
    handshakeDone*: BOOLEAN;
    clientAppKey*, clientAppIV*, serverAppKey*, serverAppIV*: TLSBytes.Buffer;
    clientAppSeq*, serverAppSeq*: LONGINT;
    closeNotify*: BOOLEAN;  (** the server ended the connection properly (close_notify) *)
    alert: LONGINT;         (* the alert for a failure after the handshake, 0: none *)
    clientAppSecret, serverAppSecret: TLSBytes.Buffer;  (* for KeyUpdate *)
    postHs: TLSBytes.Buffer;  (* post-handshake message bytes not yet complete *)
    pending: TLSBytes.Buffer;
    pendingPos: LONGINT
  END;

VAR
  verbose*: BOOLEAN;  (** hex dumps of the records and progress messages *)
  lastError*: ARRAY 128 OF CHAR;  (** why the last Connect failed *)
  (* on the heap: 1.3 MB of locals was too much for the stack of polpo (8 MB with the rest), and
     as module variables too far for the PC relative addresses of its ARMv7 compiler *)
  chain: Chain;
  alertDesc: LONGINT;  (* the alert for a failed handshake, 0: none *)
  pinMode: BOOLEAN; pinWant: ARRAY 65 OF CHAR;  (* ConnectPinned: the key expected, "" on first use *)
  keyPin*: ARRAY 65 OF CHAR;  (** SHA-256 of the SubjectPublicKeyInfo of the last server, in hex *)
  certPin*: ARRAY 65 OF CHAR;  (** SHA-256 of the certificate of the last server, in hex (the
    fingerprint Gemini clients show and pin) *)
  identity: TLSIdentity.Identity;  (* presented when a server asks for a certificate *)
  identitySent*: BOOLEAN;  (** the last server asked for a certificate and got the identity *)
  pinned*: BOOLEAN;  (** the last ConnectPinned accepted the server by keyPin, not by a CA *)
  hsKeys: BOOLEAN;     (* the client handshake key is in clientAppKey, IV: alerts are encrypted *)

PROCEDURE Init*(VAR s: State);
BEGIN
  s.fd := -1;
  s.connected := FALSE;
  s.handshakeDone := FALSE;
  s.clientAppSeq := 0;
  s.serverAppSeq := 0;
  s.closeNotify := FALSE; s.alert := 0;
  TLSBytes.Init(s.clientAppSecret); TLSBytes.Init(s.serverAppSecret); TLSBytes.Init(s.postHs);
  TLSBytes.Init(s.pending);
  s.pendingPos := 0
END Init;

PROCEDURE HexDigit(n: LONGINT): CHAR;
BEGIN
  IF n < 10 THEN RETURN CHR(ORD("0") + n) END;
  RETURN CHR(ORD("A") + n - 10)
END HexDigit;

PROCEDURE DumpBuffer(label: ARRAY OF CHAR; VAR b: TLSBytes.Buffer);
VAR i, v: LONGINT;
BEGIN
  IF ~verbose THEN RETURN END;
  Out.String(label); Out.String(" len="); Out.Int(b.len, 0); Out.String(" hex=");
  i := 0;
  WHILE i < b.len DO
    v := ORD(b.data[i]);
    Out.Char(HexDigit(v DIV 16)); Out.Char(HexDigit(v MOD 16));
    INC(i)
  END;
  IF verbose THEN Out.Ln END;
END DumpBuffer;

PROCEDURE DumpRecordInfo(label: ARRAY OF CHAR; VAR rec: TLSBytes.Buffer);
VAR ct, ln, level, descr: LONGINT;
BEGIN
  IF ~verbose THEN RETURN END;
  DumpBuffer(label, rec);
  IF rec.len >= 5 THEN
    ct := ORD(rec.data[0]); ln := TLSBytes.GetBE16(rec, 3);
    IF verbose THEN Out.String("  content_type="); Out.Int(ct, 0) END;
    IF verbose THEN Out.String(" version="); Out.Int(ORD(rec.data[1]), 0); Out.Char("."); Out.Int(ORD(rec.data[2]), 0) END;
    IF verbose THEN Out.String(" length="); Out.Int(ln, 0); Out.Ln END;
    IF (ct = 21) & (rec.len >= 7) THEN
      level := ORD(rec.data[5]); descr := ORD(rec.data[6]);
      IF verbose THEN Out.String("  TLS alert level="); Out.Int(level, 0) END;
      IF verbose THEN Out.String(" description="); Out.Int(descr, 0); Out.Ln END;
    END
  END
END DumpRecordInfo;

PROCEDURE ReadExact(fd: Internet.Socket; VAR b: TLSBytes.Buffer; pos, n: LONGINT): BOOLEAN;
VAR got, r: LONGINT;
BEGIN
  got := 0;
  WHILE got < n DO
    r := Linux0.Read0(fd, SYSTEM.ADR(b.data[pos + got]), n - got);
    IF r <= 0 THEN RETURN FALSE END;
    INC(got, r)
  END;
  RETURN TRUE
END ReadExact;

PROCEDURE WriteAll(fd: Internet.Socket; VAR b: TLSBytes.Buffer): BOOLEAN;
BEGIN
  IF b.len = 0 THEN RETURN TRUE END;
  RETURN Internet.WriteBytes(fd, b.data, b.len)
END WriteAll;

PROCEDURE ReadRecord(fd: Internet.Socket; VAR rec: TLSBytes.Buffer): BOOLEAN;
VAR n: LONGINT;
BEGIN
  TLSBytes.SetLen(rec, 5);
  IF ~ReadExact(fd, rec, 0, 5) THEN RETURN FALSE END;
  n := TLSBytes.GetBE16(rec, 3);
  IF (n < 0) OR (n > MaxRecord) THEN COPY("a record longer than 2^14 + 256 bytes", lastError); alertDesc := RecordOverflow; RETURN FALSE END;
  TLSBytes.SetLen(rec, 5 + n);
  IF n > 0 THEN RETURN ReadExact(fd, rec, 5, n) END;
  RETURN TRUE
END ReadRecord;

PROCEDURE IsCCS(VAR rec: TLSBytes.Buffer): BOOLEAN;
BEGIN
  RETURN (rec.len = 6) & (ORD(rec.data[0]) = TLS13Records.ChangeCipherSpec) &
         (ORD(rec.data[1]) = 3) & (ORD(rec.data[2]) = 3) &
         (TLSBytes.GetBE16(rec, 3) = 1) & (ORD(rec.data[5]) = 1)
END IsCCS;

PROCEDURE NextNonCCS(fd: Internet.Socket; VAR rec: TLSBytes.Buffer): BOOLEAN;
BEGIN
  REPEAT
    IF ~ReadRecord(fd, rec) THEN RETURN FALSE END
  UNTIL ~IsCCS(rec);
  RETURN TRUE
END NextNonCCS;

PROCEDURE FillBufferRandom(VAR b: TLSBytes.Buffer; n: LONGINT): BOOLEAN;
BEGIN
  TLSBytes.SetLen(b, n);
  RETURN TLS13Random.Fill(b.data, n)
END FillBufferRandom;

PROCEDURE CopyArrayToBuffer(VAR a: ARRAY OF CHAR; n: LONGINT; VAR b: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(b);
  TLSBytes.AppendOpen(b, a, n)
END CopyArrayToBuffer;


PROCEDURE Wipe(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0; WHILE i < b.len DO b.data[i] := 0X; INC(i) END;
  b.len := 0
END Wipe;

PROCEDURE Fail(why: ARRAY OF CHAR);
BEGIN
  COPY(why, lastError); Out.String("TLS13Live: "); Out.String(why); Out.Ln
END Fail;

(* rec is a plain alert of the server instead of its hello: fail with its reason *)
(* give up the handshake with the alert desc *)
PROCEDURE Abort(desc: LONGINT; why: ARRAY OF CHAR);
BEGIN
  alertDesc := desc; Fail(why)
END Abort;

(* give up the connection s with the alert desc (sent by Disconnect) *)
PROCEDURE AbortS(VAR s: State; desc: LONGINT; why: ARRAY OF CHAR);
BEGIN
  s.alert := desc; Fail(why)
END AbortS;

(* the fatal alert desc to the server: encrypted with the key of the client (clientAppKey: its
   handshake key during the handshake) if encrypted, else plain *)
PROCEDURE SendAlert(VAR s: State; desc: LONGINT; encrypted: BOOLEAN);
VAR alert, rec: TLSBytes.Buffer; ok: BOOLEAN;
BEGIN
  TLSBytes.Init(alert); TLSBytes.AppendByte(alert, 2); TLSBytes.AppendByte(alert, desc);
  IF encrypted THEN
    TLS13Records.ProtectRecord(s.clientAppKey, s.clientAppIV, s.clientAppSeq, TLS13Records.Alert, alert, rec);
    INC(s.clientAppSeq)
  ELSE
    TLSBytes.Init(rec); TLSBytes.AppendByte(rec, TLS13Records.Alert); TLSBytes.AppendByte(rec, 3); TLSBytes.AppendByte(rec, 3);
    TLSBytes.PutBE16(rec, 2); TLSBytes.Append(rec, alert)
  END;
  ok := WriteAll(s.fd, rec);
  IF verbose THEN Out.String("TLS13Live: sent alert "); Out.Int(desc, 0); Out.Ln END
END SendAlert;

PROCEDURE RefusedByAlert(VAR rec: TLSBytes.Buffer): BOOLEAN;
BEGIN
  IF (rec.len # 7) OR (ORD(rec.data[0]) # TLS13Records.Alert) THEN RETURN FALSE END;
  IF ORD(rec.data[6]) = 70 THEN Fail("the server does not speak TLS 1.3 (alert protocol_version)")
  ELSIF ORD(rec.data[6]) = 40 THEN Fail("no parameters in common with the server (alert handshake_failure)")
  ELSIF ORD(rec.data[6]) = 112 THEN Fail("the server does not know this host name (alert unrecognized_name)")
  ELSE Fail("the server refused the handshake (an alert)")
  END;
  RETURN TRUE
END RefusedByAlert;

(* keyPin := the SHA-256 of the key of the leaf in chain.certs[0], hex; "" if it is malformed *)
(* hex := the 32 bytes of d in hex *)
PROCEDURE Hex32(VAR d: TLSSHA256.Digest; VAR hex: ARRAY OF CHAR);
VAR i, v: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO
    v := ORD(d[i]) DIV 16; IF v < 10 THEN hex[2*i] := CHR(ORD("0") + v) ELSE hex[2*i] := CHR(ORD("a") + v - 10) END;
    v := ORD(d[i]) MOD 16; IF v < 10 THEN hex[2*i+1] := CHR(ORD("0") + v) ELSE hex[2*i+1] := CHR(ORD("a") + v - 10) END;
    INC(i)
  END;
  hex[64] := 0X
END Hex32;

(** the certificate and key (TLSIdentity.Load) a server that asks for one gets in the next
  connections, NIL for none (an empty Certificate) *)
PROCEDURE SetIdentity*(id: TLSIdentity.Identity);
BEGIN identity := id
END SetIdentity;

PROCEDURE KeyPin;
VAR d: TLSSHA256.Digest; i, v: LONGINT;
BEGIN
  keyPin := ""; certPin := "";
  TLSSHA256.DigestBuffer(chain.certs[0], d); Hex32(d, certPin);
  IF TLSX509.ParseCertificate(chain.certs[0], chain.leaf) THEN
    TLSSHA256.DigestBuffer(chain.leaf.spki, d);
    i := 0;
    WHILE i < 32 DO
      v := ORD(d[i]) DIV 16; IF v < 10 THEN keyPin[2*i] := CHR(ORD("0") + v) ELSE keyPin[2*i] := CHR(ORD("a") + v - 10) END;
      v := ORD(d[i]) MOD 16; IF v < 10 THEN keyPin[2*i+1] := CHR(ORD("0") + v) ELSE keyPin[2*i+1] := CHR(ORD("a") + v - 10) END;
      INC(i)
    END;
    keyPin[64] := 0X
  END
END KeyPin;

PROCEDURE CheckCapturedCertificateChain(host: ARRAY OF CHAR): BOOLEAN;
VAR
  i, n: LONGINT;
  now: TLSX509Validity.Time;
  res: TLSX509Chain.Result;
  ok: BOOLEAN;
BEGIN
  IF chain = NIL THEN NEW(chain) END;
  n := TLS13EncHandshake.CapturedCertCount();
  IF verbose THEN Out.String("TLS13Live: captured cert count="); Out.Int(n, 0); Out.Ln END;
  i := 0;
  WHILE i < LEN(chain.certs) DO TLSBytes.Init(chain.certs[i]); INC(i) END;
  i := 0;
  WHILE (i < n) & (i < LEN(chain.certs)) DO
    IF ~TLS13EncHandshake.GetCapturedCert(i, chain.certs[i]) THEN Abort(BadCertificate, "a certificate could not be read"); RETURN FALSE END;
    INC(i)
  END;

  IF verbose THEN Out.String("TLS13Live: hostname verified = ") END;
  IF verbose THEN IF TLS13EncHandshake.HostnameOK() THEN Out.String("OK") ELSE Out.String("FAIL") END END;
  IF verbose THEN Out.Ln END;

  IF ~TLSCABundle.LoadDefault(chain.ca) THEN
    Abort(InternalError, "the CA bundle could not be loaded (SSL_CERT_FILE or /etc/ssl/certs/ca-certificates.crt)");
    RETURN FALSE
  END;
  IF verbose THEN Out.String("TLS13Live: loaded CA bundle bytes="); Out.Int(chain.ca.len, 0); Out.Ln END;

  TLSNow.Current(now);
  IF verbose THEN Out.String("TLS13Live: current time "); Out.Int(now.year, 0); Out.Char("-"); Out.Int(now.month, 0); Out.Char("-"); Out.Int(now.day, 0); Out.Char(" "); Out.Int(now.hour, 0); Out.Char(":"); Out.Int(now.minute, 0); Out.Char(":"); Out.Int(now.second, 0); Out.Ln END;

  ok := TLSX509Chain.CheckChainWithPEMBundle(chain.certs, n, chain.ca.text, now, res);
  IF verbose THEN Out.String("TLS13Live: chain trusted = "); IF ok THEN Out.String("OK") ELSE Out.String("FAIL") END; Out.Ln END;
  IF verbose THEN Out.String("TLS13Live: chain depth="); Out.Int(res.depth, 0) END;
  IF verbose THEN Out.String(" rootFound="); IF res.rootFound THEN Out.String("true") ELSE Out.String("false") END END;
  IF verbose THEN Out.String(" rootTrusted="); IF res.rootTrusted THEN Out.String("true") ELSE Out.String("false") END END;
  IF verbose THEN Out.String(" sigsOK="); IF res.allSignaturesOK THEN Out.String("true") ELSE Out.String("false") END END;
  IF verbose THEN Out.String(" timesOK="); IF res.allTimesOK THEN Out.String("true") ELSE Out.String("false") END END;
  IF verbose THEN Out.String(" namesOK="); IF res.allNamesOK THEN Out.String("true") ELSE Out.String("false") END END;
  IF verbose THEN Out.String(" failedAt="); Out.Int(res.failedAt, 0); Out.Ln END;

  KeyPin();
  IF pinMode & (~ok OR ~TLS13EncHandshake.HostnameOK()) THEN  (* not by a CA: trust on first use *)
    IF ~TLS13EncHandshake.CertificateVerifyOK() THEN Abort(DecryptError, "CertificateVerify did not verify"); RETURN FALSE END;
    IF keyPin = "" THEN Abort(BadCertificate, "the certificate of the server is malformed"); RETURN FALSE END;
    IF (pinWant # "") & (pinWant # keyPin) THEN
      Abort(BadCertificate, "the key of the server is not the one seen before (trust on first use)"); RETURN FALSE
    END;
    pinned := TRUE; RETURN TRUE
  END;
  IF ~ok THEN
    IF ~res.leafParsed THEN Abort(BadCertificate, "the certificate of the server is malformed")
    ELSIF ~res.allTimesOK THEN Abort(CertificateExpired, "a certificate of the chain is expired or not yet valid")
    ELSIF ~res.allSignaturesOK THEN Abort(BadCertificate, "a signature of the certificate chain does not verify")
    ELSIF ~res.constraintsOK THEN Abort(BadCertificate, "the certificate chain breaks a constraint (CA, key usage, path length or names)")
    ELSE Abort(UnknownCA, "the certificate chain is not trusted (no known root)")
    END;
    RETURN FALSE
  END;
  IF ~TLS13EncHandshake.HostnameOK() THEN Abort(BadCertificate, "the certificate is not for this host name"); RETURN FALSE END;
  IF ~TLS13EncHandshake.CertificateVerifyOK() THEN Abort(DecryptError, "CertificateVerify did not verify"); RETURN FALSE END;
  RETURN TRUE
END CheckCapturedCertificateChain;

PROCEDURE Handshake(host, port: ARRAY OF CHAR; VAR s: State): BOOLEAN;
VAR
  privArr, pubArr, sharedArr: ARRAY 32 OF CHAR;
  i: LONGINT;
  clientRandom, clientPub, clientHelloMsg, clientHelloRec: TLSBytes.Buffer;
  rec, serverHelloMsg, serverPub, shared, th, serverFrag: TLSBytes.Buffer;
  cHsKey, cHsIV, sHsKey, sHsIV, cFinKey, sFinKey: TLSBytes.Buffer;
  hsSecret, masterSecret, clientFinishedRec, clientFinishedMsg, thServerFinished: TLSBytes.Buffer;
  thClient, reqCtx, certMsg, list, sig: TLSBytes.Buffer;  (* the transcript for our Finished, a certificate request *)
  sawFinished, finishedOK, zero: BOOLEAN;
  group, tries: LONGINT; cookie, p256Priv, p256Pub, h: TLSBytes.Buffer;
  serverHSSeq, clientHSSeq: LONGINT;
  why: ARRAY 128 OF CHAR;
BEGIN
  Init(s); lastError := ""; alertDesc := 0; hsKeys := FALSE; pinned := FALSE; keyPin := ""; certPin := ""; identitySent := FALSE;
  TLS13EncHandshake.verbose := verbose;
  TLS13EncHandshake.ResetState;
  TLS13EncHandshake.SetExpectedHost(host);
  IF ~Internet.Connect(host, port, s.fd) THEN RETURN FALSE END;
  s.connected := TRUE;

  IF ~TLS13Random.Fill(privArr, 32) THEN RETURN FALSE END;
  TLSX25519.ScalarMultBase(pubArr, privArr);
  IF ~FillBufferRandom(clientRandom, 32) THEN RETURN FALSE END;
  CopyArrayToBuffer(pubArr, 32, clientPub);

  TLS13Handshake.BuildClientHelloMessage(host, clientRandom, clientPub, clientHelloMsg);
  TLS13Handshake.BuildPlainHandshakeRecord(clientHelloMsg, clientHelloRec);
  DumpBuffer("client hello msg", clientHelloMsg);
  DumpRecordInfo("client hello rec", clientHelloRec);
  IF ~WriteAll(s.fd, clientHelloRec) THEN Out.String("TLS13Live: write ClientHello failed"); Out.Ln; RETURN FALSE END;

  TLSBytes.Copy(clientHelloMsg, th);  (* temporary transcript storage *)

  IF ~NextNonCCS(s.fd, rec) THEN Out.String("TLS13Live: failed reading first server record"); Out.Ln; RETURN FALSE END;
  DumpRecordInfo("first server record", rec);
  IF RefusedByAlert(rec) THEN RETURN FALSE END;
  IF ~TLS13Handshake.GetRecordPayload(rec, serverHelloMsg) THEN Abort(UnexpectedMessage, "the first record of the server is not a ServerHello"); RETURN FALSE END;
  DumpBuffer("server hello msg", serverHelloMsg);
  group := TLS13Handshake.GroupX25519;
  IF TLS13Handshake.IsHelloRetryRequest(serverHelloMsg) THEN
    IF ~TLS13Handshake.CheckHelloRetryRequest(serverHelloMsg, clientRandom, group, group, cookie, why) THEN Abort(IllegalParameter, why); RETURN FALSE END;
    IF verbose THEN Out.String("TLS13Live: HelloRetryRequest, group="); Out.Int(group, 0); Out.Ln END;
    (* the transcript: message_hash with the hash of the first ClientHello, then the HelloRetryRequest (RFC 8446 4.4.1) *)
    TLS13Keys.HashMessages(clientHelloMsg, h);
    TLSBytes.Init(th); TLSBytes.AppendByte(th, 254); TLSBytes.PutBE24(th, h.len); TLSBytes.Append(th, h);
    TLSBytes.Append(th, serverHelloMsg);
    IF group = TLS13Handshake.GroupP256 THEN
      tries := 0;
      REPEAT
        INC(tries);
        IF ~FillBufferRandom(p256Priv, 32) THEN RETURN FALSE END
      UNTIL TLSECDSA.ECDHPublic(TLSECDSA.P256, p256Priv, p256Pub) OR (tries = 8);
      IF p256Pub.len # 65 THEN Fail("no P-256 key"); RETURN FALSE END;
      TLS13Handshake.BuildClientHello2(host, clientRandom, group, p256Pub, cookie, clientHelloMsg)
    ELSE  (* only a cookie: the same key share *)
      TLS13Handshake.BuildClientHello2(host, clientRandom, group, clientPub, cookie, clientHelloMsg)
    END;
    TLS13Handshake.BuildPlainHandshakeRecord(clientHelloMsg, clientHelloRec);
    TLSBytes.Append(th, clientHelloMsg);
    IF ~WriteAll(s.fd, clientHelloRec) THEN Fail("writing the second ClientHello failed"); RETURN FALSE END;
    IF ~NextNonCCS(s.fd, rec) OR RefusedByAlert(rec) OR ~TLS13Handshake.GetRecordPayload(rec, serverHelloMsg) THEN
      Abort(UnexpectedMessage, "no ServerHello after the HelloRetryRequest"); RETURN FALSE
    END;
    DumpBuffer("server hello msg", serverHelloMsg)
  END;
  IF ~TLS13Handshake.CheckServerHelloGroup(serverHelloMsg, clientRandom, group, serverPub, why) THEN Abort(IllegalParameter, why); RETURN FALSE END;  (* the session id we sent is clientRandom *)
  TLSBytes.Append(th, serverHelloMsg);
  DumpBuffer("server pub", serverPub);

  IF group = TLS13Handshake.GroupP256 THEN
    IF ~TLSECDSA.ECDH(TLSECDSA.P256, p256Priv, serverPub, shared) THEN Abort(IllegalParameter, "the P-256 key share of the server is not a point of the curve"); RETURN FALSE END;
    Wipe(p256Priv); i := 0; WHILE i < 32 DO privArr[i] := 0X; INC(i) END
  ELSE
    TLSX25519.ScalarMult(sharedArr, privArr, serverPub.data);
    CopyArrayToBuffer(sharedArr, 32, shared);
    i := 0; zero := TRUE; WHILE i < 32 DO IF sharedArr[i] # 0X THEN zero := FALSE END; INC(i) END;
    IF zero THEN Abort(IllegalParameter, "the X25519 shared secret is zero (a small order point)"); RETURN FALSE END  (* RFC 7748 6.1 *)
  END;

  TLS13Keys.HashMessages(th, clientRandom); (* reusing clientRandom as transcript hash *)
  TLS13Keys.HandshakeKeys(shared, clientRandom, cHsKey, cHsIV, sHsKey, sHsIV, cFinKey, sFinKey);
  TLS13Keys.HandshakeSecret(shared, hsSecret);
  TLSBytes.Copy(cHsKey, s.clientAppKey); TLSBytes.Copy(cHsIV, s.clientAppIV); s.clientAppSeq := 0; hsKeys := TRUE;
  i := 0; WHILE i < 32 DO privArr[i] := 0X; sharedArr[i] := 0X; shared.data[i] := 0X; INC(i) END;  (* no longer needed *)

  serverHSSeq := 0;
  TLSBytes.Init(serverFrag);
  sawFinished := FALSE; finishedOK := FALSE;
  WHILE ~sawFinished DO
    IF ~NextNonCCS(s.fd, rec) THEN Out.String("TLS13Live: failed reading encrypted handshake record"); Out.Ln; RETURN FALSE END;
    DumpRecordInfo("encrypted server hs rec", rec);
    IF ~TLS13EncHandshake.OpenServerHandshakeRecordBuf(sHsKey, sHsIV, serverHSSeq, rec, serverFrag, th, sFinKey, sawFinished, finishedOK) THEN
      IF (TLS13EncHandshake.CapturedCertCount() > 0) & ~TLS13EncHandshake.CertificateVerifyOK() THEN Abort(DecryptError, "CertificateVerify did not verify")
      ELSE Abort(HandshakeFailure, "the encrypted handshake failed (decryption, order of messages or Finished)")
      END;
      RETURN FALSE
    END;
    IF verbose THEN Out.String("  buffered hs fragment bytes="); Out.Int(serverFrag.len, 0); Out.Ln END;
    INC(serverHSSeq)
  END;
  IF ~finishedOK THEN Abort(DecryptError, "the Finished of the server does not verify"); RETURN FALSE END;

  IF verbose THEN Out.String("TLS13Live: server Finished OK, transcript len="); Out.Int(th.len, 0); Out.Ln END;

  IF ~CheckCapturedCertificateChain(host) THEN RETURN FALSE END;

  (* TLS 1.3 application traffic secrets are derived from the
     transcript ending at the server Finished.  The client Finished is
     built using this transcript too, but it is not included in
     client/server_application_traffic_secret_0. *)
  TLSBytes.Copy(th, thServerFinished);

  clientHSSeq := 0;
  TLSBytes.Copy(thServerFinished, thClient);
  IF TLS13EncHandshake.CertificateRequested(reqCtx) THEN
    (* RFC 8446 4.4.2: our Certificate echoing the request context, empty without an identity;
       with one its CertificateVerify (4.4.3); the Finished covers them *)
    TLSBytes.Init(list); i := 0;
    WHILE (identity # NIL) & (i < identity.n) DO
      TLSBytes.PutBE24(list, identity.certs[i].len); TLSBytes.Append(list, identity.certs[i]); TLSBytes.PutBE16(list, 0); INC(i)
    END;
    TLSBytes.Init(certMsg); TLSBytes.AppendByte(certMsg, TLS13EncHandshake.Certificate);
    TLSBytes.PutBE24(certMsg, 1 + reqCtx.len + 3 + list.len);
    TLSBytes.AppendByte(certMsg, reqCtx.len); TLSBytes.Append(certMsg, reqCtx); TLSBytes.PutBE24(certMsg, list.len);
    TLSBytes.Append(certMsg, list);
    TLS13Records.ProtectRecord(cHsKey, cHsIV, clientHSSeq, TLS13Records.Handshake, certMsg, rec);
    IF ~WriteAll(s.fd, rec) THEN Fail("writing the client Certificate failed"); RETURN FALSE END;
    TLSBytes.Append(thClient, certMsg); INC(clientHSSeq); s.clientAppSeq := clientHSSeq;
    IF identity # NIL THEN
      TLS13Keys.HashMessages(thClient, h);
      TLSBytes.Init(list); i := 0; WHILE i < 64 DO TLSBytes.AppendByte(list, 20H); INC(i) END;
      TLSBytes.AppendString(list, "TLS 1.3, client CertificateVerify"); TLSBytes.AppendByte(list, 0); TLSBytes.Append(list, h);
      IF ~TLSIdentity.Sign(identity, list, sig) THEN Abort(InternalError, "signing the client CertificateVerify failed"); RETURN FALSE END;
      TLSBytes.Init(certMsg); TLSBytes.AppendByte(certMsg, 15);  (* CertificateVerify *)
      TLSBytes.PutBE24(certMsg, 4 + sig.len); TLSBytes.PutBE16(certMsg, TLSIdentity.Scheme(identity));
      TLSBytes.PutBE16(certMsg, sig.len); TLSBytes.Append(certMsg, sig);
      TLS13Records.ProtectRecord(cHsKey, cHsIV, clientHSSeq, TLS13Records.Handshake, certMsg, rec);
      IF ~WriteAll(s.fd, rec) THEN Fail("writing the client CertificateVerify failed"); RETURN FALSE END;
      TLSBytes.Append(thClient, certMsg); INC(clientHSSeq); s.clientAppSeq := clientHSSeq;
      identitySent := TRUE
    END;
    IF verbose THEN
      Out.String("TLS13Live: the server asked for a client certificate, ");
      IF identity # NIL THEN Out.String("sent it") ELSE Out.String("sent none") END; Out.Ln
    END
  END;
  IF verbose THEN Out.String("TLS13Live: building client Finished"); Out.Ln END;
  TLS13ClientFinished.BuildClientFinishedRecord(cHsKey, cHsIV, clientHSSeq, thClient, cFinKey, clientFinishedRec, clientFinishedMsg);
  DumpBuffer("client finished msg", clientFinishedMsg);
  DumpRecordInfo("client finished rec", clientFinishedRec);

  IF verbose THEN Out.String("TLS13Live: deriving master secret"); Out.Ln END;
  TLS13Keys.MasterSecret(hsSecret, masterSecret);
  IF verbose THEN Out.String("TLS13Live: deriving application keys from server-Finished transcript"); Out.Ln END;
  TLS13Application.ApplicationTrafficSecrets(masterSecret, thServerFinished, s.clientAppSecret, s.serverAppSecret);
  TLS13Keys.TrafficKey(s.clientAppSecret, s.clientAppKey); TLS13Keys.TrafficIV(s.clientAppSecret, s.clientAppIV);
  TLS13Keys.TrafficKey(s.serverAppSecret, s.serverAppKey); TLS13Keys.TrafficIV(s.serverAppSecret, s.serverAppIV);
  Wipe(hsSecret); Wipe(masterSecret);
  IF verbose THEN Out.String("TLS13Live: application keys ready"); Out.Ln END;

  IF verbose THEN Out.String("TLS13Live: appending client Finished to transcript"); Out.Ln END;
  TLS13ClientFinished.AppendClientFinished(th, clientFinishedMsg);
  IF verbose THEN Out.String("TLS13Live: transcript len after client Finished="); Out.Int(th.len, 0); Out.Ln END;
  IF verbose THEN Out.String("TLS13Live: writing client Finished"); Out.Ln END;
  IF ~WriteAll(s.fd, clientFinishedRec) THEN Out.String("TLS13Live: write client Finished failed"); Out.Ln; RETURN FALSE END;
  s.clientAppSeq := 0;
  s.serverAppSeq := 0;
  TLSBytes.Init(s.pending); s.pendingPos := 0;
  s.handshakeDone := TRUE;
  RETURN TRUE
END Handshake;

(** a TLS 1.3 connection to host: the server authenticated (a trusted chain for the host name,
  CertificateVerify and Finished); FALSE and nothing open otherwise (lastError says why) *)
PROCEDURE Connect*(host, port: ARRAY OF CHAR; VAR s: State): BOOLEAN;
BEGIN
  IF Handshake(host, port, s) THEN RETURN TRUE END;
  IF lastError = "" THEN COPY("no connection", lastError) END;
  IF s.connected & (alertDesc > 0) THEN SendAlert(s, alertDesc, hsKeys) END;
  IF s.connected THEN Internet.Disconnect(s.fd) END;
  Init(s);
  RETURN FALSE
END Connect;

(** Connect, for protocols that trust on first use (Gemini): a server not verified by a CA (its
  chain, or the host name) is accepted if CertificateVerify shows that it has the key whose
  SHA-256 is pin (hex), or any key if pin is ""; then pinned is set. keyPin is the key to keep. *)
PROCEDURE ConnectPinned*(host, port: ARRAY OF CHAR; VAR s: State; pin: ARRAY OF CHAR): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  pinMode := TRUE; COPY(pin, pinWant);
  ok := Connect(host, port, s);
  pinMode := FALSE;
  RETURN ok
END ConnectPinned;

(* the alert close_notify to the server; FALSE if it could not be written *)
PROCEDURE SendCloseNotify(VAR s: State): BOOLEAN;
VAR alert, rec: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(alert); TLSBytes.AppendByte(alert, 1); TLSBytes.AppendByte(alert, CloseNotify);
  TLS13Records.ProtectRecord(s.clientAppKey, s.clientAppIV, s.clientAppSeq, TLS13Records.Alert, alert, rec);
  INC(s.clientAppSeq);
  RETURN WriteAll(s.fd, rec)
END SendCloseNotify;

(** close the connection, with close_notify after a handshake; the keys are cleared *)
PROCEDURE Disconnect*(VAR s: State);
BEGIN
  IF s.connected & s.handshakeDone & (s.clientAppSeq < MAX(LONGINT)) THEN
    IF s.alert > 0 THEN SendAlert(s, s.alert, TRUE)  (* a failure: its alert instead of close_notify *)
    ELSIF ~SendCloseNotify(s) & verbose THEN Out.String("TLS13Live: close_notify not sent"); Out.Ln
    END
  END;
  IF s.connected THEN Internet.Disconnect(s.fd) END;
  Wipe(s.clientAppKey); Wipe(s.clientAppIV); Wipe(s.serverAppKey); Wipe(s.serverAppIV);
  Wipe(s.clientAppSecret); Wipe(s.serverAppSecret);
  Init(s)
END Disconnect;

(** s is the server end of the connection fd, after a handshake made by TLS13Server: s writes
  with the server application secret and reads with the client one. The names of the fields
  are those of the client: "client" is what s writes, "server" what it reads. *)
PROCEDURE Accepted*(VAR s: State; fd: Internet.Socket; VAR serverSecret, clientSecret: TLSBytes.Buffer);
BEGIN
  Init(s); s.fd := fd; s.connected := TRUE;
  TLSBytes.Copy(serverSecret, s.clientAppSecret); TLSBytes.Copy(clientSecret, s.serverAppSecret);
  TLS13Keys.TrafficKey(s.clientAppSecret, s.clientAppKey); TLS13Keys.TrafficIV(s.clientAppSecret, s.clientAppIV);
  TLS13Keys.TrafficKey(s.serverAppSecret, s.serverAppKey); TLS13Keys.TrafficIV(s.serverAppSecret, s.serverAppIV);
  s.handshakeDone := TRUE
END Accepted;

(** plain to the server, in records of at most 2^14 bytes *)
PROCEDURE WriteAppBuffer*(VAR s: State; VAR plain: TLSBytes.Buffer): BOOLEAN;
VAR rec, part: TLSBytes.Buffer; pos, n: LONGINT;
BEGIN
  IF ~s.handshakeDone THEN RETURN FALSE END;
  pos := 0;
  REPEAT
    n := plain.len - pos; IF n > MaxPlain THEN n := MaxPlain END;
    IF s.clientAppSeq = MAX(LONGINT) THEN Fail("too many records with one key"); RETURN FALSE END;
    TLSBytes.Slice(plain, pos, n, part);
    IF verbose THEN Out.String("TLS13Live: protecting application data len="); Out.Int(n, 0); Out.String(" seq="); Out.Int(s.clientAppSeq, 0); Out.Ln END;
    TLS13Application.ProtectApplicationData(s.clientAppKey, s.clientAppIV, s.clientAppSeq, part, rec);
    DumpRecordInfo("application write rec", rec);
    IF ~WriteAll(s.fd, rec) THEN RETURN FALSE END;
    INC(s.clientAppSeq); INC(pos, n)
  UNTIL pos >= plain.len;
  RETURN TRUE
END WriteAppBuffer;

PROCEDURE WriteAppString*(VAR s: State; str: ARRAY OF CHAR): BOOLEAN;
VAR b: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(b);
  TLSBytes.AppendString(b, str);
  RETURN WriteAppBuffer(s, b)
END WriteAppString;

(* the next traffic secret (RFC 8446 7.2) *)
PROCEDURE NextSecret(VAR secret: TLSBytes.Buffer);
VAR empty, next: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(empty);
  TLSHKDF.ExpandLabel(secret, "traffic upd", empty, SecretLen, next);
  Wipe(secret); TLSBytes.Copy(next, secret); Wipe(next)
END NextSecret;

(* our KeyUpdate (update_not_requested), then our keys are the next ones *)
PROCEDURE SendKeyUpdate(VAR s: State): BOOLEAN;
VAR msg, rec: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(msg);
  TLSBytes.AppendByte(msg, KeyUpdate); TLSBytes.AppendByte(msg, 0); TLSBytes.AppendByte(msg, 0);
  TLSBytes.AppendByte(msg, 1); TLSBytes.AppendByte(msg, 0);
  TLS13Records.ProtectRecord(s.clientAppKey, s.clientAppIV, s.clientAppSeq, TLS13Records.Handshake, msg, rec);
  IF ~WriteAll(s.fd, rec) THEN Fail("writing KeyUpdate failed"); RETURN FALSE END;
  NextSecret(s.clientAppSecret);
  TLS13Keys.TrafficKey(s.clientAppSecret, s.clientAppKey); TLS13Keys.TrafficIV(s.clientAppSecret, s.clientAppIV);
  s.clientAppSeq := 0;
  RETURN TRUE
END SendKeyUpdate;

(* handshake messages after the handshake, from the record plain: NewSessionTicket is not used,
   KeyUpdate changes the keys of the server (and ours if asked); anything else is refused *)
PROCEDURE PostHandshake(VAR s: State; VAR plain: TLSBytes.Buffer): BOOLEAN;
VAR type, len: LONGINT; rest: TLSBytes.Buffer;
BEGIN
  IF plain.len = 0 THEN AbortS(s, UnexpectedMessage, "an empty handshake record"); RETURN FALSE END;
  IF s.postHs.len + plain.len > TLSBytes.MaxLen THEN Fail("a post-handshake message too long"); RETURN FALSE END;
  TLSBytes.Append(s.postHs, plain);
  WHILE s.postHs.len >= 4 DO
    type := ORD(s.postHs.data[0]); len := TLSBytes.GetBE24(s.postHs, 1);
    IF 4 + len > TLSBytes.MaxLen THEN Fail("a post-handshake message too long"); RETURN FALSE END;
    IF s.postHs.len < 4 + len THEN RETURN TRUE END;  (* continued in the next record *)
    IF type = NewSessionTicket THEN
      IF verbose THEN Out.String("TLS13Live: NewSessionTicket (not used)"); Out.Ln END
    ELSIF type = KeyUpdate THEN
      IF (len # 1) OR (ORD(s.postHs.data[4]) > 1) THEN AbortS(s, DecodeError, "a malformed KeyUpdate"); RETURN FALSE END;
      IF s.postHs.len # 5 THEN AbortS(s, UnexpectedMessage, "KeyUpdate not at the end of a record"); RETURN FALSE END;
      IF verbose THEN Out.String("TLS13Live: KeyUpdate, request="); Out.Int(ORD(s.postHs.data[4]), 0); Out.Ln END;
      NextSecret(s.serverAppSecret);
      TLS13Keys.TrafficKey(s.serverAppSecret, s.serverAppKey); TLS13Keys.TrafficIV(s.serverAppSecret, s.serverAppIV);
      s.serverAppSeq := 0;
      IF (ORD(s.postHs.data[4]) = 1) & ~SendKeyUpdate(s) THEN RETURN FALSE END
    ELSE
      AbortS(s, UnexpectedMessage, "an unexpected handshake message after the handshake"); RETURN FALSE
    END;
    TLSBytes.Slice(s.postHs, 4 + len, s.postHs.len - 4 - len, rest); TLSBytes.Copy(rest, s.postHs)
  END;
  RETURN TRUE
END PostHandshake;

(* the next application data of the server in s.pending; FALSE at the end (s.closeNotify if
   the server closed properly, else lastError says why) *)
PROCEDURE ReadNextApplicationPlain(VAR s: State): BOOLEAN;
VAR rec, plain: TLSBytes.Buffer; innerType: LONGINT;
BEGIN
  IF s.closeNotify THEN RETURN FALSE END;
  LOOP
    IF ~ReadRecord(s.fd, rec) THEN
      IF lastError = "" THEN Fail("the connection ended without close_notify (it may be cut)")
      ELSE AbortS(s, RecordOverflow, lastError)
      END;
      RETURN FALSE
    END;
    DumpRecordInfo("application read rec", rec);
    IF IsCCS(rec) THEN AbortS(s, UnexpectedMessage, "change_cipher_spec after the handshake"); RETURN FALSE END;
    IF s.serverAppSeq = MAX(LONGINT) THEN Fail("too many records with one key"); RETURN FALSE END;
    IF ~TLS13Records.OpenRecord(s.serverAppKey, s.serverAppIV, s.serverAppSeq, rec, innerType, plain) THEN
      AbortS(s, BadRecordMac, "an application record did not decrypt"); RETURN FALSE
    END;
    IF plain.len > MaxPlain THEN AbortS(s, RecordOverflow, "a record longer than 2^14 bytes"); RETURN FALSE END;
    IF verbose THEN Out.String("TLS13Live: app inner type="); Out.Int(innerType, 0); Out.String(" plain len="); Out.Int(plain.len, 0); Out.Ln END;
    INC(s.serverAppSeq);
    IF (innerType # TLS13Records.Handshake) & (s.postHs.len > 0) THEN
      AbortS(s, UnexpectedMessage, "a handshake message interrupted by another record"); RETURN FALSE
    END;
    IF innerType = TLS13Records.ApplicationData THEN
      TLSBytes.Copy(plain, s.pending);
      s.pendingPos := 0;
      RETURN TRUE
    ELSIF innerType = TLS13Records.Handshake THEN
      IF ~PostHandshake(s, plain) THEN RETURN FALSE END
    ELSIF innerType = TLS13Records.Alert THEN
      IF plain.len # 2 THEN AbortS(s, DecodeError, "a malformed alert"); RETURN FALSE END;
      IF ORD(plain.data[1]) = CloseNotify THEN s.closeNotify := TRUE; RETURN FALSE
      ELSIF ORD(plain.data[1]) # UserCanceled THEN Fail("the server sent an alert"); RETURN FALSE
      END
    ELSE
      AbortS(s, UnexpectedMessage, "an unexpected record type"); RETURN FALSE
    END
  END
END ReadNextApplicationPlain;

PROCEDURE ReadAppMax*(VAR s: State; VAR out: ARRAY OF CHAR; max: LONGINT; VAR n: LONGINT): BOOLEAN;
VAR cap: LONGINT;
BEGIN
  n := 0;
  IF ~s.handshakeDone THEN RETURN FALSE END;
  cap := max;
  IF cap < 0 THEN cap := LEN(out) END;
  IF cap > LEN(out) THEN cap := LEN(out) END;
  WHILE n < cap DO
    IF s.pendingPos >= s.pending.len THEN
      IF n > 0 THEN
        IF n < LEN(out) THEN out[n] := 0X END;
        RETURN TRUE
      END;
      IF ~ReadNextApplicationPlain(s) THEN RETURN FALSE END
    END;
    WHILE (n < cap) & (s.pendingPos < s.pending.len) DO
      out[n] := s.pending.data[s.pendingPos];
      INC(n); INC(s.pendingPos)
    END
  END;
  IF n < LEN(out) THEN out[n] := 0X END;
  RETURN n > 0
END ReadAppMax;

PROCEDURE ReadApp*(VAR s: State; VAR out: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN;
BEGIN
  RETURN ReadAppMax(s, out, LEN(out), n)
END ReadApp;

BEGIN
  verbose := FALSE; alertDesc := 0; hsKeys := FALSE; chain := NIL; pinMode := FALSE; pinned := FALSE; keyPin := "";
  certPin := ""; identity := NIL; identitySent := FALSE
END TLS13Live.
