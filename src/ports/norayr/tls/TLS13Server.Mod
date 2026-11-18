MODULE TLS13Server;
(** The server side of TLS 1.3 (RFC 8446), for Gemini and HTTPS servers. The server has a
  certificate chain and a private key (Load); Accept makes the handshake on a connection
  that the caller accepted, and gives a TLS13Live.State, which is then read and written as a
  client connection is (ReadAppMax, WriteAppString, Disconnect).
  One cipher suite, TLS_AES_128_GCM_SHA256; the key exchange X25519 or P-256, with a
  HelloRetryRequest when the client offered a key share of neither; a certificate with an ECDSA
  P-256 key (CertificateVerify ecdsa_secp256r1_sha256), an RSA key (rsa_pss_rsae_sha256), or
  an Ed25519 key (ed25519), see
  TLSIdentity. No PSK, so no session tickets and no early data. Accept does not request client
  certificates; BeginEd25519/PollEd25519 require a manually pinned Ed25519 client identity.
  Several servers on one port (virtual hosts): AcceptBy, with a procedure that
  gives the certificate for the host name the client asks for (SNI). A client that does not wait (a missing ClientHello) blocks Accept: the caller
  sets a timeout on the socket first. *)
IMPORT Out, Internet, Linux0 := unixNet, SYSTEM,
  TLSBytes, TLS13Random, TLSX25519, TLSECDSA, TLSIdentity, TLS13Keys, TLS13Records, TLS13Finished,
  TLS13Application, TLS13Live, Sockets, TLS13Auth, TLSNow, TLSX509Validity;

CONST
  MaxChain* = 8;              (** certificates in a chain *)
  MaxRecord = 16640; MaxPlain = 16384;
  ClientHello = 1; ServerHello = 2; EncryptedExtensions = 8; Certificate = 11;
  CertificateVerify = 15; Finished = 20; MessageHash = 254;
  ExtServerName = 0; ExtSupportedGroups = 10; ExtSignatureAlgorithms = 13;
  ExtSupportedVersions = 43; ExtKeyShare = 51;
  X25519 = 1DH; P256 = 17H; EcdsaP256Sha256 = 403H; RsaPssRsaeSha256 = 804H; Ed25519 = 807H; AES128GCM = 1301H;
  (* alerts *)
  UnexpectedMessage = 10; BadRecordMac = 20; RecordOverflow = 22; HandshakeFailure = 40; IllegalParameter = 47;
  DecodeError = 50; DecryptError = 51; ProtocolVersion = 70; InternalError = 80;
  MissingExtension = 109; UnrecognizedName = 112;

TYPE
  Identity* = TLSIdentity.Identity;  (** a certificate chain and its key (TLSIdentity.Load) *)

  Chooser* = PROCEDURE (VAR name: ARRAY OF CHAR): Identity;
    (** the certificate for the host name a client asks for (SNI, in lower case; "" when it
      names none), NIL to refuse it (alert unrecognized_name) *)

  Hello = RECORD  (* what a ClientHello offers *)
    sidLen, shareLen, group: LONGINT;          (* group: of the key share taken, 0: none *)
    sid: ARRAY 32 OF CHAR;
    share: ARRAY 65 OF CHAR;
    tls13, aes, nullComp, ecdsa, rsapss, ed25519, x25519, p256: BOOLEAN;
    host: ARRAY 256 OF CHAR
  END;

  Pending* = POINTER TO PendingDesc;
  PendingDesc = RECORD
    fd*: Internet.Socket;
    name*: ARRAY 256 OF CHAR;
    id: Identity;
    pin, spki, wire, output, message, transcript: TLSBytes.Buffer;
    clientKey, clientIV, serverKey, serverIV, clientFinished: TLSBytes.Buffer;
    clientSecret, serverSecret: TLSBytes.Buffer;
    hello: Hello;
    sid: ARRAY 32 OF CHAR;
    sidLen, requestedGroup, phase, have, need, outPos, clientSeq, serverSeq, authStage: LONGINT;
    ccsSeen, ccsSent: BOOLEAN
  END;


VAR
  verbose*: BOOLEAN;                (** progress messages *)
  lastError*: ARRAY 128 OF CHAR;    (** why the last Load or Accept failed *)
  serverName*: ARRAY 256 OF CHAR;   (** the host name the last client asked for (SNI), or "" *)
  alertDesc: LONGINT;               (* the alert for the failure, 0: none *)
  encrypted: BOOLEAN;               (* alerts go with the handshake key of the server: *)
  hsKey, hsIV: TLSBytes.Buffer; hsSeq: LONGINT;
  single: Identity;                 (* the identity of Accept *)

PROCEDURE Fail(desc: LONGINT; why: ARRAY OF CHAR);
BEGIN
  IF lastError = "" THEN COPY(why, lastError); alertDesc := desc END;
  IF verbose THEN Out.String("TLS13Server: "); Out.String(why); Out.Ln END
END Fail;

PROCEDURE Wipe(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0; WHILE i < b.len DO b.data[i] := 0X; INC(i) END;
  b.len := 0
END Wipe;

(* ----- the certificate and the key ----- *)

(** id := the certificates of the PEM file certFile (the leaf first, then the chain to a root,
  not needed) and the private key (Ed25519, ECDSA P-256 or RSA) of the PEM file keyFile; FALSE if they
  cannot be read or do not belong together (lastError says why) *)
PROCEDURE Load*(certFile, keyFile: ARRAY OF CHAR; VAR id: Identity): BOOLEAN;
BEGIN
  IF TLSIdentity.Load(certFile, keyFile, id) THEN lastError := ""; RETURN TRUE END;
  COPY(TLSIdentity.lastError, lastError); RETURN FALSE
END Load;

(* ----- records ----- *)

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

PROCEDURE ReadRecord(fd: Internet.Socket; VAR rec: TLSBytes.Buffer): BOOLEAN;
VAR n: LONGINT;
BEGIN
  TLSBytes.SetLen(rec, 5);
  IF ~ReadExact(fd, rec, 0, 5) THEN Fail(0, "the client closed the connection"); RETURN FALSE END;
  n := TLSBytes.GetBE16(rec, 3);
  IF (n < 1) OR (n > MaxRecord) THEN Fail(RecordOverflow, "a record of a wrong length"); RETURN FALSE END;
  TLSBytes.SetLen(rec, 5 + n);
  IF ~ReadExact(fd, rec, 5, n) THEN Fail(0, "the client closed the connection"); RETURN FALSE END;
  RETURN TRUE
END ReadRecord;

PROCEDURE IsCCS(VAR rec: TLSBytes.Buffer): BOOLEAN;
BEGIN
  RETURN (rec.len = 6) & (ORD(rec.data[0]) = TLS13Records.ChangeCipherSpec) & (ORD(rec.data[5]) = 1)
END IsCCS;

PROCEDURE Write(fd: Internet.Socket; VAR b: TLSBytes.Buffer): BOOLEAN;
BEGIN
  IF ~Internet.WriteBytes(fd, b.data, b.len) THEN Fail(0, "writing to the client failed"); RETURN FALSE END;
  RETURN TRUE
END Write;

PROCEDURE PlainRecord(type: LONGINT; VAR payload, rec: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(rec); TLSBytes.AppendByte(rec, type); TLSBytes.AppendByte(rec, 3); TLSBytes.AppendByte(rec, 3);
  TLSBytes.PutBE16(rec, payload.len); TLSBytes.Append(rec, payload)
END PlainRecord;

(* the dummy change_cipher_spec of the middlebox compatibility mode (RFC 8446 D.4) *)
PROCEDURE SendCCS(fd: Internet.Socket): BOOLEAN;
VAR one, rec: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(one); TLSBytes.AppendByte(one, 1);
  PlainRecord(TLS13Records.ChangeCipherSpec, one, rec);
  RETURN Write(fd, rec)
END SendCCS;

PROCEDURE SendAlert(fd: Internet.Socket; desc: LONGINT);
VAR alert, rec: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(alert); TLSBytes.AppendByte(alert, 2); TLSBytes.AppendByte(alert, desc);
  IF encrypted THEN TLS13Records.ProtectRecord(hsKey, hsIV, hsSeq, TLS13Records.Alert, alert, rec); INC(hsSeq)
  ELSE PlainRecord(TLS13Records.Alert, alert, rec)
  END;
  IF Internet.WriteBytes(fd, rec.data, rec.len) & verbose THEN Out.String("TLS13Server: sent alert "); Out.Int(desc, 0); Out.Ln END
END SendAlert;

(* msg := the next handshake message of the client in plain records (skipping change_cipher_spec);
   it may span several records, and nothing may follow it *)
PROCEDURE ReadPlainMessage(fd: Internet.Socket; VAR msg: TLSBytes.Buffer): BOOLEAN;
VAR rec: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLSBytes.Init(msg);
  REPEAT
    IF ~ReadRecord(fd, rec) THEN RETURN FALSE END;
    IF ~IsCCS(rec) THEN
      IF ORD(rec.data[0]) = TLS13Records.Alert THEN Fail(0, "the client sent an alert"); RETURN FALSE END;
      IF ORD(rec.data[0]) # TLS13Records.Handshake THEN Fail(UnexpectedMessage, "a record that is not a handshake record"); RETURN FALSE END;
      IF msg.len + rec.len - 5 > TLSBytes.MaxLen THEN Fail(DecodeError, "a ClientHello too long"); RETURN FALSE END;
      i := 5; WHILE i < rec.len DO TLSBytes.AppendChar(msg, rec.data[i]); INC(i) END;
      IF (msg.len >= 4) & (4 + TLSBytes.GetBE24(msg, 1) > TLSBytes.MaxLen) THEN Fail(DecodeError, "a ClientHello too long"); RETURN FALSE END
    END
  UNTIL (msg.len >= 4) & (msg.len >= 4 + TLSBytes.GetBE24(msg, 1));
  IF msg.len # 4 + TLSBytes.GetBE24(msg, 1) THEN Fail(UnexpectedMessage, "more data after the ClientHello"); RETURN FALSE END;
  RETURN TRUE
END ReadPlainMessage;

(* ----- the ClientHello ----- *)

(* does the list of 16 bit values m[p..e) contain v? *)
PROCEDURE Has16(VAR m: TLSBytes.Buffer; p, e, v: LONGINT): BOOLEAN;
BEGIN
  WHILE p + 1 < e DO IF TLSBytes.GetBE16(m, p) = v THEN RETURN TRUE END; INC(p, 2) END;
  RETURN FALSE
END Has16;

(* h := what the ClientHello m offers; FALSE if m is malformed *)
PROCEDURE ParseHello(VAR m: TLSBytes.Buffer; VAR h: Hello): BOOLEAN;
VAR p, end, n, type, len, e, k, g, l, i: LONGINT; seen: SET;
BEGIN
  h.sidLen := 0; h.shareLen := 0; h.group := 0; h.host := "";
  h.tls13 := FALSE; h.aes := FALSE; h.nullComp := FALSE; h.ecdsa := FALSE; h.rsapss := FALSE; h.x25519 := FALSE; h.p256 := FALSE;
  h.ed25519 := FALSE;
  IF (m.len < 4 + 35) OR (ORD(m.data[0]) # ClientHello) THEN RETURN FALSE END;
  end := m.len; p := 4 + 2 + 32;                  (* legacy_version, random *)
  n := ORD(m.data[p]); INC(p);                    (* legacy_session_id *)
  IF (n > 32) OR (p + n + 2 > end) THEN RETURN FALSE END;
  i := 0; WHILE i < n DO h.sid[i] := m.data[p + i]; INC(i) END;
  h.sidLen := n; INC(p, n);
  n := TLSBytes.GetBE16(m, p); INC(p, 2);         (* cipher_suites *)
  IF ODD(n) OR (p + n + 1 > end) THEN RETURN FALSE END;
  h.aes := Has16(m, p, p + n, AES128GCM); INC(p, n);
  n := ORD(m.data[p]); INC(p);                    (* legacy_compression_methods *)
  IF p + n > end THEN RETURN FALSE END;
  i := 0; WHILE i < n DO IF m.data[p + i] = 0X THEN h.nullComp := TRUE END; INC(i) END;
  INC(p, n);
  IF p = end THEN RETURN TRUE END;                (* no extensions: not TLS 1.3 *)
  IF p + 2 > end THEN RETURN FALSE END;
  n := TLSBytes.GetBE16(m, p); INC(p, 2);
  IF p + n # end THEN RETURN FALSE END;
  seen := {};
  WHILE p < end DO
    IF p + 4 > end THEN RETURN FALSE END;
    type := TLSBytes.GetBE16(m, p); len := TLSBytes.GetBE16(m, p + 2); INC(p, 4);
    e := p + len;
    IF e > end THEN RETURN FALSE END;
    k := -1;
    IF type = ExtServerName THEN k := 0 ELSIF type = ExtSupportedGroups THEN k := 1
    ELSIF type = ExtSignatureAlgorithms THEN k := 2 ELSIF type = ExtSupportedVersions THEN k := 3
    ELSIF type = ExtKeyShare THEN k := 4
    END;
    IF k >= 0 THEN
      IF k IN seen THEN RETURN FALSE END;         (* each extension once (RFC 8446 4.2) *)
      INCL(seen, k)
    END;
    IF type = ExtSupportedVersions THEN
      IF (len < 1) OR (1 + ORD(m.data[p]) # len) THEN RETURN FALSE END;
      h.tls13 := Has16(m, p + 1, e, 304H)
    ELSIF (type = ExtSupportedGroups) OR (type = ExtSignatureAlgorithms) THEN
      IF (len < 2) OR (2 + TLSBytes.GetBE16(m, p) # len) THEN RETURN FALSE END;
      IF type = ExtSignatureAlgorithms THEN
        h.ecdsa := Has16(m, p + 2, e, EcdsaP256Sha256); h.rsapss := Has16(m, p + 2, e, RsaPssRsaeSha256);
        h.ed25519 := Has16(m, p + 2, e, Ed25519)
      ELSE h.x25519 := Has16(m, p + 2, e, X25519); h.p256 := Has16(m, p + 2, e, P256)
      END
    ELSIF type = ExtKeyShare THEN
      IF (len < 2) OR (2 + TLSBytes.GetBE16(m, p) # len) THEN RETURN FALSE END;
      k := p + 2;
      WHILE k < e DO
        IF k + 4 > e THEN RETURN FALSE END;
        g := TLSBytes.GetBE16(m, k); l := TLSBytes.GetBE16(m, k + 2); INC(k, 4);
        IF k + l > e THEN RETURN FALSE END;
        IF (g = X25519) & (l = 32) & (h.group # X25519) OR (g = P256) & (l = 65) & (h.group = 0) THEN
          h.group := g; h.shareLen := l;
          i := 0; WHILE i < l DO h.share[i] := m.data[k + i]; INC(i) END
        END;
        INC(k, l)
      END
    ELSIF type = ExtServerName THEN   (* a list of names; the host_name (0) taken *)
      IF (len < 2) OR (2 + TLSBytes.GetBE16(m, p) # len) THEN RETURN FALSE END;
      k := p + 2;
      WHILE k < e DO
        IF k + 3 > e THEN RETURN FALSE END;
        g := ORD(m.data[k]); l := TLSBytes.GetBE16(m, k + 1); INC(k, 3);
        IF k + l > e THEN RETURN FALSE END;
        IF (g = 0) & (l > 0) & (l < LEN(h.host)) THEN
          i := 0; WHILE i < l DO h.host[i] := m.data[k + i]; INC(i) END;
          h.host[l] := 0X
        END;
        INC(k, l)
      END
    END;
    p := e
  END;
  RETURN TRUE
END ParseHello;

(* the fields of a ServerHello or HelloRetryRequest; share: the key share of the server, or none
   (a HelloRetryRequest names only the group) *)
PROCEDURE BuildServerHello(VAR random: TLSBytes.Buffer; VAR h: Hello; group: LONGINT; VAR share, msg: TLSBytes.Buffer);
VAR body: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLSBytes.Init(body);
  TLSBytes.AppendByte(body, 3); TLSBytes.AppendByte(body, 3);
  TLSBytes.Append(body, random);
  TLSBytes.AppendByte(body, h.sidLen);
  i := 0; WHILE i < h.sidLen DO TLSBytes.AppendChar(body, h.sid[i]); INC(i) END;
  TLSBytes.PutBE16(body, AES128GCM); TLSBytes.AppendByte(body, 0);
  IF share.len > 0 THEN TLSBytes.PutBE16(body, 6 + 8 + share.len) ELSE TLSBytes.PutBE16(body, 6 + 6) END;
  TLSBytes.PutBE16(body, ExtSupportedVersions); TLSBytes.PutBE16(body, 2); TLSBytes.PutBE16(body, 304H);
  TLSBytes.PutBE16(body, ExtKeyShare);
  IF share.len > 0 THEN
    TLSBytes.PutBE16(body, 4 + share.len); TLSBytes.PutBE16(body, group); TLSBytes.PutBE16(body, share.len);
    TLSBytes.Append(body, share)
  ELSE TLSBytes.PutBE16(body, 2); TLSBytes.PutBE16(body, group)
  END;
  TLSBytes.Init(msg); TLSBytes.AppendByte(msg, ServerHello); TLSBytes.PutBE24(msg, body.len); TLSBytes.Append(msg, body)
END BuildServerHello;

(* the reasons to refuse a ClientHello h; first: the first one (a HelloRetryRequest may follow) *)
PROCEDURE CheckHello(VAR h: Hello; first: BOOLEAN): BOOLEAN;
BEGIN
  IF ~h.tls13 THEN Fail(ProtocolVersion, "the client does not offer TLS 1.3")
  ELSIF ~h.aes THEN Fail(HandshakeFailure, "the client does not offer TLS_AES_128_GCM_SHA256")
  ELSIF ~h.nullComp THEN Fail(IllegalParameter, "no null compression in the ClientHello")
  ELSIF ~h.ecdsa & ~h.rsapss & ~h.ed25519 THEN Fail(HandshakeFailure, "the client accepts no supported signature scheme")
  ELSIF (h.group = 0) & ~(first & (h.x25519 OR h.p256)) THEN Fail(HandshakeFailure, "no key exchange in common (X25519, P-256)")
  ELSE RETURN TRUE
  END;
  RETURN FALSE
END CheckHello;

(* ----- the handshake ----- *)

PROCEDURE AppendCertificate(id: Identity; VAR msg: TLSBytes.Buffer);
VAR list: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLSBytes.Init(list); i := 0;
  WHILE i < id.n DO
    TLSBytes.PutBE24(list, id.certs[i].len); TLSBytes.Append(list, id.certs[i]); TLSBytes.PutBE16(list, 0); INC(i)
  END;
  TLSBytes.AppendByte(msg, Certificate); TLSBytes.PutBE24(msg, 1 + 3 + list.len);
  TLSBytes.AppendByte(msg, 0);  (* certificate_request_context *)
  TLSBytes.PutBE24(msg, list.len); TLSBytes.Append(msg, list)
END AppendCertificate;

(* the CertificateVerify for the transcript th, with the key of id *)
PROCEDURE AppendCertificateVerify(id: Identity; VAR th, msg: TLSBytes.Buffer): BOOLEAN;
VAR hash, content, sig: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLS13Keys.HashMessages(th, hash);
  TLSBytes.Init(content);
  i := 0; WHILE i < 64 DO TLSBytes.AppendByte(content, 20H); INC(i) END;
  TLSBytes.AppendString(content, "TLS 1.3, server CertificateVerify");
  TLSBytes.AppendByte(content, 0); TLSBytes.Append(content, hash);
  IF ~TLSIdentity.Sign(id, content, sig) THEN Fail(InternalError, "signing failed"); RETURN FALSE END;
  TLSBytes.AppendByte(msg, CertificateVerify); TLSBytes.PutBE24(msg, 4 + sig.len);
  TLSBytes.PutBE16(msg, TLSIdentity.Scheme(id)); TLSBytes.PutBE16(msg, sig.len); TLSBytes.Append(msg, sig);
  RETURN TRUE
END AppendCertificateVerify;

(* shared := the secret of the key exchange with the share of h; pub: our share *)
PROCEDURE KeyExchange(VAR h: Hello; VAR pub, shared: TLSBytes.Buffer): BOOLEAN;
VAR priv, peer: TLSBytes.Buffer; a, b, c: ARRAY 32 OF CHAR; i, tries: LONGINT; zero: BOOLEAN;
BEGIN
  TLSBytes.Init(pub); TLSBytes.Init(shared);
  IF h.group = X25519 THEN
    IF ~TLS13Random.Fill(a, 32) THEN Fail(InternalError, "no random bytes"); RETURN FALSE END;
    TLSX25519.ScalarMultBase(b, a); TLSBytes.AppendOpen(pub, b, 32);
    i := 0; WHILE i < 32 DO b[i] := h.share[i]; INC(i) END;
    TLSX25519.ScalarMult(c, a, b);
    zero := TRUE; i := 0;
    WHILE i < 32 DO IF c[i] # 0X THEN zero := FALSE END; a[i] := 0X; INC(i) END;
    IF zero THEN Fail(IllegalParameter, "the X25519 share of the client is a point of small order"); RETURN FALSE END;
    TLSBytes.AppendOpen(shared, c, 32);
    i := 0; WHILE i < 32 DO c[i] := 0X; INC(i) END
  ELSE
    tries := 0;
    REPEAT
      INC(tries); TLSBytes.SetLen(priv, 32);
      IF ~TLS13Random.Fill(priv.data, 32) THEN Fail(InternalError, "no random bytes"); RETURN FALSE END
    UNTIL TLSECDSA.ECDHPublic(TLSECDSA.P256, priv, pub) OR (tries = 8);
    TLSBytes.Init(peer); TLSBytes.AppendOpen(peer, h.share, 65);
    IF (pub.len # 65) OR ~TLSECDSA.ECDH(TLSECDSA.P256, priv, peer, shared) THEN
      Wipe(priv); Fail(IllegalParameter, "the P-256 share of the client is not a point of the curve"); RETURN FALSE
    END;
    Wipe(priv)
  END;
  RETURN TRUE
END KeyExchange;

(* the client Finished, in records protected with key, iv: msg *)
PROCEDURE ReadFinished(fd: Internet.Socket; VAR key, iv, msg: TLSBytes.Buffer): BOOLEAN;
VAR rec, plain: TLSBytes.Buffer; seq, type: LONGINT; ccs: BOOLEAN;
BEGIN
  TLSBytes.Init(msg); seq := 0; ccs := FALSE;
  REPEAT
    IF ~ReadRecord(fd, rec) THEN RETURN FALSE END;
    IF IsCCS(rec) THEN
      IF ccs OR (msg.len > 0) THEN Fail(UnexpectedMessage, "a second change_cipher_spec"); RETURN FALSE END;
      ccs := TRUE
    ELSE
      IF ~TLS13Records.OpenRecord(key, iv, seq, rec, type, plain) THEN Fail(BadRecordMac, "a record of the client did not decrypt"); RETURN FALSE END;
      INC(seq);
      IF type = TLS13Records.Alert THEN Fail(0, "the client sent an alert"); RETURN FALSE END;
      IF type # TLS13Records.Handshake THEN Fail(UnexpectedMessage, "no Finished from the client"); RETURN FALSE END;
      IF msg.len + plain.len > 4 + TLS13Finished.VerifyDataLen THEN Fail(UnexpectedMessage, "no Finished from the client"); RETURN FALSE END;
      TLSBytes.Append(msg, plain)
    END
  UNTIL msg.len = 4 + TLS13Finished.VerifyDataLen;
  RETURN TRUE
END ReadFinished;

(* b := the bytes of the hex digits h1 h2 (upper case) *)
PROCEDURE HexBytes(h1, h2: ARRAY OF CHAR; VAR b: TLSBytes.Buffer);
VAR h: ARRAY 72 OF CHAR; i, hi, lo: LONGINT;
BEGIN
  COPY(h1, h); i := 0; WHILE h[i] # 0X DO INC(i) END;
  hi := 0; WHILE h2[hi] # 0X DO h[i] := h2[hi]; INC(i); INC(hi) END;
  h[i] := 0X;
  TLSBytes.Init(b); i := 0;
  WHILE h[i] # 0X DO
    hi := ORD(h[i]) - ORD("0"); IF hi > 9 THEN hi := ORD(h[i]) - ORD("A") + 10 END;
    lo := ORD(h[i+1]) - ORD("0"); IF lo > 9 THEN lo := ORD(h[i+1]) - ORD("A") + 10 END;
    TLSBytes.AppendByte(b, hi * 16 + lo); INC(i, 2)
  END
END HexBytes;

PROCEDURE Handshake(fd: Internet.Socket; choose: Chooser; VAR s: TLS13Live.State): BOOLEAN;
VAR
  h: Hello; msg, th, random, pub, shared, hash, none, flight, part, rec, hrrRandom: TLSBytes.Buffer;
  cHsKey, cHsIV, sHsKey, sHsIV, cFinKey, sFinKey, hsSecret, master, cSecret, sSecret: TLSBytes.Buffer;
  group, pos, n, i: LONGINT; ccsSent: BOOLEAN; sid: ARRAY 32 OF CHAR; sidLen: LONGINT; id: Identity;
BEGIN
  TLSBytes.Init(none); ccsSent := FALSE;
  IF ~ReadPlainMessage(fd, msg) THEN RETURN FALSE END;
  IF ~ParseHello(msg, h) THEN Fail(DecodeError, "a malformed ClientHello"); RETURN FALSE END;
  i := 0;
  WHILE h.host[i] # 0X DO
    IF (h.host[i] >= "A") & (h.host[i] <= "Z") THEN h.host[i] := CHR(ORD(h.host[i]) + 32) END; INC(i)
  END;
  COPY(h.host, serverName);
  IF ~CheckHello(h, TRUE) THEN RETURN FALSE END;
  id := choose(serverName);
  IF id = NIL THEN Fail(UnrecognizedName, "no certificate for the host name the client asks for"); RETURN FALSE END;
  IF (TLSIdentity.Scheme(id) = EcdsaP256Sha256) & ~h.ecdsa OR
     (TLSIdentity.Scheme(id) = RsaPssRsaeSha256) & ~h.rsapss OR
     (TLSIdentity.Scheme(id) = Ed25519) & ~h.ed25519 THEN
    Fail(HandshakeFailure, "the client does not accept the signatures of the certificate"); RETURN FALSE
  END;
  TLSBytes.Copy(msg, th);
  IF h.group = 0 THEN  (* a HelloRetryRequest for a group we have (RFC 8446 4.1.4) *)
    IF h.x25519 THEN group := X25519 ELSE group := P256 END;
    IF verbose THEN Out.String("TLS13Server: HelloRetryRequest, group "); Out.Int(group, 0); Out.Ln END;
    HexBytes("CF21AD74E59A6111BE1D8C021E65B891", "C2A211167ABB8C5E079E09E2C8A8339C", hrrRandom);
    BuildServerHello(hrrRandom, h, group, none, msg);
    TLS13Keys.HashMessages(th, hash);
    TLSBytes.Init(th); TLSBytes.AppendByte(th, MessageHash); TLSBytes.PutBE24(th, hash.len); TLSBytes.Append(th, hash);
    TLSBytes.Append(th, msg);
    PlainRecord(TLS13Records.Handshake, msg, rec);
    IF ~Write(fd, rec) THEN RETURN FALSE END;
    IF h.sidLen > 0 THEN IF ~SendCCS(fd) THEN RETURN FALSE END; ccsSent := TRUE END;
    sidLen := h.sidLen; i := 0; WHILE i < sidLen DO sid[i] := h.sid[i]; INC(i) END;
    IF ~ReadPlainMessage(fd, msg) THEN RETURN FALSE END;
    IF ~ParseHello(msg, h) THEN Fail(DecodeError, "a malformed second ClientHello"); RETURN FALSE END;
    IF ~CheckHello(h, FALSE) THEN RETURN FALSE END;
    IF h.group # group THEN Fail(IllegalParameter, "the second ClientHello has not the key share asked for"); RETURN FALSE END;
    i := 0; WHILE (i < sidLen) & (h.sid[i] = sid[i]) DO INC(i) END;
    IF (h.sidLen # sidLen) OR (i # sidLen) THEN Fail(IllegalParameter, "the second ClientHello changed the session id"); RETURN FALSE END;
    TLSBytes.Append(th, msg)
  END;
  IF ~KeyExchange(h, pub, shared) THEN RETURN FALSE END;
  TLSBytes.SetLen(random, 32);
  IF ~TLS13Random.Fill(random.data, 32) THEN Fail(InternalError, "no random bytes"); RETURN FALSE END;
  BuildServerHello(random, h, h.group, pub, msg);
  TLSBytes.Append(th, msg);
  PlainRecord(TLS13Records.Handshake, msg, rec);
  IF ~Write(fd, rec) THEN RETURN FALSE END;
  IF (h.sidLen > 0) & ~ccsSent THEN IF ~SendCCS(fd) THEN RETURN FALSE END END;

  TLS13Keys.HashMessages(th, hash);
  TLS13Keys.HandshakeKeys(shared, hash, cHsKey, cHsIV, sHsKey, sHsIV, cFinKey, sFinKey);
  TLS13Keys.HandshakeSecret(shared, hsSecret); Wipe(shared);
  TLSBytes.Copy(sHsKey, hsKey); TLSBytes.Copy(sHsIV, hsIV); hsSeq := 0; encrypted := TRUE;

  (* EncryptedExtensions (none), Certificate, CertificateVerify, Finished *)
  TLSBytes.Init(flight);
  TLSBytes.AppendByte(flight, EncryptedExtensions); TLSBytes.PutBE24(flight, 2); TLSBytes.PutBE16(flight, 0);
  AppendCertificate(id, flight);
  TLSBytes.Append(th, flight); pos := flight.len;
  IF ~AppendCertificateVerify(id, th, flight) THEN RETURN FALSE END;
  TLSBytes.Slice(flight, pos, flight.len - pos, part); TLSBytes.Append(th, part);
  TLS13Keys.HashMessages(th, hash);
  TLS13Finished.BuildFinishedMessage(sFinKey, hash, msg);
  TLSBytes.Append(flight, msg); TLSBytes.Append(th, msg);
  pos := 0;
  WHILE pos < flight.len DO
    n := flight.len - pos; IF n > MaxPlain THEN n := MaxPlain END;
    TLSBytes.Slice(flight, pos, n, part);
    TLS13Records.ProtectRecord(sHsKey, sHsIV, hsSeq, TLS13Records.Handshake, part, rec); INC(hsSeq);
    IF ~Write(fd, rec) THEN RETURN FALSE END;
    INC(pos, n)
  END;
  TLS13Keys.MasterSecret(hsSecret, master); Wipe(hsSecret);
  TLS13Application.ApplicationTrafficSecrets(master, th, cSecret, sSecret); Wipe(master);

  IF ~ReadFinished(fd, cHsKey, cHsIV, msg) THEN RETURN FALSE END;
  TLS13Keys.HashMessages(th, hash);
  IF ~TLS13Finished.VerifyFinishedMessage(msg, cFinKey, hash) THEN Fail(DecryptError, "the Finished of the client does not verify"); RETURN FALSE END;
  TLS13Live.Accepted(s, fd, sSecret, cSecret);
  Wipe(cSecret); Wipe(sSecret); Wipe(cHsKey); Wipe(cHsIV); Wipe(sHsKey); Wipe(sHsIV); Wipe(cFinKey); Wipe(sFinKey);
  Wipe(hsKey); Wipe(hsIV); encrypted := FALSE;
  RETURN TRUE
END Handshake;

(** the handshake of TLS 1.3 on fd, a connection the caller accepted, as the server with the
  certificate and key that choose gives for the host name the client asks for; then s is the
  connection (TLS13Live: ReadAppMax, WriteAppString, Disconnect, which also closes fd). FALSE if
  the handshake failed: an alert is sent, fd is closed, and lastError says why. serverName is
  the host name the client asked for, in lower case. *)
PROCEDURE AcceptBy*(fd: Internet.Socket; choose: Chooser; VAR s: TLS13Live.State): BOOLEAN;
BEGIN
  lastError := ""; serverName := ""; alertDesc := 0; encrypted := FALSE; hsSeq := 0;
  TLS13Live.Init(s);
  IF Handshake(fd, choose, s) THEN RETURN TRUE END;
  IF alertDesc > 0 THEN SendAlert(fd, alertDesc) END;
  Wipe(hsKey); Wipe(hsIV); encrypted := FALSE;
  Internet.Disconnect(fd);
  TLS13Live.Init(s);
  RETURN FALSE
END AcceptBy;

PROCEDURE Single(VAR name: ARRAY OF CHAR): Identity;
BEGIN RETURN single
END Single;

(** AcceptBy with the certificate and key id for any host name *)
PROCEDURE Accept*(fd: Internet.Socket; id: Identity; VAR s: TLS13Live.State): BOOLEAN;
BEGIN
  IF id = NIL THEN lastError := ""; Fail(InternalError, "no certificate (Load)"); Internet.Disconnect(fd); RETURN FALSE END;
  single := id;
  RETURN AcceptBy(fd, Single, s)
END Accept;

(** Closes an incomplete nonblocking server handshake and clears its transient secrets. *)
PROCEDURE ClosePending*(VAR p: Pending);
BEGIN
  IF p = NIL THEN RETURN END;
  IF p.fd >= 0 THEN Internet.Disconnect(p.fd) END;
  p.fd := -1; p.id := NIL;
  Wipe(p.pin); Wipe(p.spki); Wipe(p.wire); Wipe(p.output); Wipe(p.message); Wipe(p.transcript);
  Wipe(p.clientKey); Wipe(p.clientIV); Wipe(p.serverKey); Wipe(p.serverIV); Wipe(p.clientFinished);
  Wipe(p.clientSecret); Wipe(p.serverSecret); p := NIL
END ClosePending;

(** Begins a nonblocking, mutually authenticated Ed25519 server upgrade. Both the local
    identity and the peer's exact 32-byte raw key pin are required. Takes ownership of fd,
    including on failure. Use an inactive pending handle; keep id valid until completion. *)
PROCEDURE BeginEd25519*(fd: Internet.Socket; id: Identity; VAR pin: TLSBytes.Buffer; VAR p: Pending): BOOLEAN;
VAR socket: Sockets.Socket; publicKey, spki: TLSBytes.Buffer; now: TLSX509Validity.Time;
BEGIN
  p := NIL; lastError := ""; TLSNow.Current(now);
  IF (fd < 0) OR (pin.len # 32) OR (id = NIL) OR (id.kind # TLSIdentity.Ed25519) OR (id.n # 1) OR
     (id.certs[0].len > MaxPlain-13) OR ~TLSIdentity.PublicKey(id^, publicKey) OR
     ~TLS13Auth.PinnedEd25519(id.certs[0], publicKey, now, TRUE, spki) THEN
    IF fd >= 0 THEN Internet.Disconnect(fd) END;
    COPY("invalid local Ed25519 identity or peer pin", lastError); RETURN FALSE
  END;
  NEW(socket); socket.fd := fd;
  IF ~Sockets.SetBlocking(socket, FALSE) THEN
    Internet.Disconnect(fd); COPY("cannot make the TLS socket nonblocking", lastError); RETURN FALSE
  END;
  NEW(p); p.fd := fd; p.id := id; TLSBytes.Copy(pin, p.pin);
  p.phase := 0; p.have := 0; p.need := 5; p.outPos := 0;
  p.clientSeq := 0; p.serverSeq := 0; p.authStage := 0; p.ccsSeen := FALSE; p.ccsSent := FALSE;
  RETURN TRUE
END BeginEd25519;

(** Whether the pending handshake has bytes awaiting a writable socket. *)
PROCEDURE WantsWrite*(p: Pending): BOOLEAN;
BEGIN RETURN (p # NIL) & (p.outPos < p.output.len)
END WantsWrite;

PROCEDURE PendingRecord(p: Pending): INTEGER;
VAR n: LONGINT;
BEGIN
  TLSBytes.SetLen(p.wire, p.need);
  n := Sockets.ReadDescriptor(p.fd, p.wire.data, p.have, p.need-p.have);
  IF Sockets.WouldBlock(n) OR Sockets.Interrupted(n) THEN RETURN 0 END;
  IF n <= 0 THEN Fail(0, "the client closed the connection"); RETURN -1 END;
  INC(p.have, n);
  IF p.have < p.need THEN RETURN 0 END;
  IF p.need = 5 THEN
    n := TLSBytes.GetBE16(p.wire, 3);
    IF (n < 1) OR (n > MaxRecord) OR (p.wire.data[1] # 3X) OR
       ((p.wire.data[2] # 3X) & ((p.phase # 0) OR (p.wire.data[2] # 1X))) THEN
      Fail(DecodeError, "an invalid TLS record header"); RETURN -1
    END;
    p.need := 5+n; RETURN 0
  END;
  p.have := 0; p.need := 5; RETURN 1
END PendingRecord;

PROCEDURE PendingFlush(p: Pending): INTEGER;
VAR n: LONGINT;
BEGIN
  IF p.outPos < p.output.len THEN
    n := Sockets.WriteDescriptor(p.fd, p.output.data, p.outPos, p.output.len-p.outPos);
    IF Sockets.WouldBlock(n) OR Sockets.Interrupted(n) THEN RETURN 0 END;
    IF n <= 0 THEN Fail(0, "writing to the client failed"); RETURN -1 END;
    INC(p.outPos, n);
    IF p.outPos < p.output.len THEN RETURN 0 END
  END;
  Wipe(p.output); p.outPos := 0; RETURN 1
END PendingFlush;

PROCEDURE PendingCCS(p: Pending);
VAR one, record: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(one); TLSBytes.AppendByte(one, 1);
  PlainRecord(TLS13Records.ChangeCipherSpec, one, record); TLSBytes.Append(p.output, record); p.ccsSent := TRUE
END PendingCCS;

PROCEDURE PendingRetry(p: Pending);
VAR random, none, message, hash: TLSBytes.Buffer; i: LONGINT;
BEGIN
  IF p.hello.x25519 THEN p.requestedGroup := X25519 ELSE p.requestedGroup := P256 END;
  HexBytes("CF21AD74E59A6111BE1D8C021E65B891", "C2A211167ABB8C5E079E09E2C8A8339C", random);
  TLSBytes.Init(none); BuildServerHello(random, p.hello, p.requestedGroup, none, message);
  TLS13Keys.HashMessages(p.transcript, hash); TLSBytes.Init(p.transcript);
  TLSBytes.AppendByte(p.transcript, MessageHash); TLSBytes.PutBE24(p.transcript, hash.len); TLSBytes.Append(p.transcript, hash);
  TLSBytes.Append(p.transcript, message); PlainRecord(TLS13Records.Handshake, message, p.output);
  IF p.hello.sidLen > 0 THEN PendingCCS(p) END;
  p.sidLen := p.hello.sidLen;
  FOR i := 0 TO p.sidLen-1 DO p.sid[i] := p.hello.sid[i] END;
  p.phase := 1
END PendingRetry;

PROCEDURE PendingFlight(p: Pending): BOOLEAN;
VAR public, shared, random, message, hash, flight, part, record, serverFinished, secret, master: TLSBytes.Buffer;
  pos, n: LONGINT;
BEGIN
  IF ~KeyExchange(p.hello, public, shared) THEN RETURN FALSE END;
  TLSBytes.SetLen(random, 32);
  IF ~TLS13Random.Fill(random.data, 32) THEN Wipe(shared); Fail(InternalError, "no random bytes"); RETURN FALSE END;
  BuildServerHello(random, p.hello, p.hello.group, public, message);
  IF p.transcript.len+message.len > TLSBytes.MaxLen THEN
    Wipe(shared); Fail(DecodeError, "the handshake transcript is too long"); RETURN FALSE
  END;
  TLSBytes.Append(p.transcript, message); PlainRecord(TLS13Records.Handshake, message, p.output);
  IF (p.hello.sidLen > 0) & ~p.ccsSent THEN PendingCCS(p) END;
  TLS13Keys.HashMessages(p.transcript, hash);
  TLS13Keys.HandshakeKeys(shared, hash, p.clientKey, p.clientIV, p.serverKey, p.serverIV, p.clientFinished, serverFinished);
  TLS13Keys.HandshakeSecret(shared, secret); Wipe(shared);
  TLSBytes.Init(flight); TLSBytes.AppendByte(flight, EncryptedExtensions); TLSBytes.PutBE24(flight, 2); TLSBytes.PutBE16(flight, 0);
  TLS13Auth.Request(message); TLSBytes.Append(flight, message);
  IF ~TLS13Auth.Present(p.id, message) THEN Wipe(secret); Wipe(serverFinished); RETURN FALSE END;
  TLSBytes.Append(flight, message);
  IF p.transcript.len+flight.len+72+36 > TLSBytes.MaxLen THEN
    Wipe(secret); Wipe(serverFinished); Fail(DecodeError, "the handshake transcript is too long"); RETURN FALSE
  END;
  TLSBytes.Append(p.transcript, flight);
  IF ~TLS13Auth.Sign(p.id, p.transcript, TRUE, message) THEN Wipe(secret); Wipe(serverFinished); RETURN FALSE END;
  TLSBytes.Append(flight, message); TLSBytes.Append(p.transcript, message);
  TLS13Keys.HashMessages(p.transcript, hash); TLS13Finished.BuildFinishedMessage(serverFinished, hash, message);
  Wipe(serverFinished); TLSBytes.Append(flight, message); TLSBytes.Append(p.transcript, message);
  pos := 0;
  WHILE pos < flight.len DO
    n := flight.len-pos; IF n > MaxPlain THEN n := MaxPlain END;
    TLSBytes.Slice(flight, pos, n, part);
    TLS13Records.ProtectRecord(p.serverKey, p.serverIV, p.serverSeq, TLS13Records.Handshake, part, record); INC(p.serverSeq);
    TLSBytes.Append(p.output, record); INC(pos, n)
  END;
  TLS13Keys.MasterSecret(secret, master); Wipe(secret);
  TLS13Application.ApplicationTrafficSecrets(master, p.transcript, p.clientSecret, p.serverSecret); Wipe(master);
  p.phase := 3; RETURN TRUE
END PendingFlight;

PROCEDURE PendingHello(p: Pending): BOOLEAN;
VAR i: LONGINT;
BEGIN
  IF ~ParseHello(p.message, p.hello) OR (p.message.data[4] # 3X) OR (p.message.data[5] # 3X) THEN
    Fail(DecodeError, "a malformed ClientHello"); RETURN FALSE
  END;
  IF ~CheckHello(p.hello, p.phase = 0) THEN RETURN FALSE END;
  IF ~p.hello.ed25519 THEN Fail(HandshakeFailure, "the client does not accept Ed25519 signatures"); RETURN FALSE END;
  i := 0;
  WHILE p.hello.host[i] # 0X DO
    IF (p.hello.host[i] >= "A") & (p.hello.host[i] <= "Z") THEN p.hello.host[i] := CHR(ORD(p.hello.host[i])+32) END;
    INC(i)
  END;
  IF p.phase = 0 THEN
    COPY(p.hello.host, p.name); TLSBytes.Copy(p.message, p.transcript)
  ELSE
    IF (p.hello.group # p.requestedGroup) OR (p.hello.sidLen # p.sidLen) OR (p.hello.host # p.name) THEN
      Fail(IllegalParameter, "the second ClientHello changed a negotiated parameter"); RETURN FALSE
    END;
    FOR i := 0 TO p.sidLen-1 DO
      IF p.hello.sid[i] # p.sid[i] THEN Fail(IllegalParameter, "the second ClientHello changed the session id"); RETURN FALSE END
    END;
    IF p.transcript.len+p.message.len > TLSBytes.MaxLen THEN Fail(DecodeError, "the handshake transcript is too long"); RETURN FALSE END;
    TLSBytes.Append(p.transcript, p.message)
  END;
  Wipe(p.message);
  IF p.hello.group = 0 THEN PendingRetry(p); RETURN TRUE END;
  RETURN PendingFlight(p)
END PendingHello;

PROCEDURE PendingPlain(p: Pending): INTEGER;
VAR result: INTEGER; i, total: LONGINT;
BEGIN
  result := PendingRecord(p); IF result # 1 THEN RETURN result END;
  IF IsCCS(p.wire) & (p.phase = 2) & ~p.ccsSeen & (p.message.len = 0) THEN p.ccsSeen := TRUE; RETURN 0 END;
  IF (p.wire.data[0] # 16X) OR (p.wire.len > MaxPlain+5) OR (p.message.len+p.wire.len-5 > TLSBytes.MaxLen) THEN
    Fail(UnexpectedMessage, "expected a plaintext ClientHello"); RETURN -1
  END;
  FOR i := 5 TO p.wire.len-1 DO TLSBytes.AppendChar(p.message, p.wire.data[i]) END;
  IF p.message.len < 4 THEN RETURN 0 END;
  total := 4+TLSBytes.GetBE24(p.message, 1);
  IF (total > TLSBytes.MaxLen) OR (p.message.len > total) THEN Fail(DecodeError, "an invalid ClientHello length"); RETURN -1 END;
  IF p.message.len < total THEN RETURN 0 END;
  IF ~PendingHello(p) THEN RETURN -1 END;
  RETURN 0
END PendingPlain;

PROCEDURE PendingAuth(p: Pending): INTEGER;
VAR result: INTEGER; plain, message, certificate, hash: TLSBytes.Buffer;
  now: TLSX509Validity.Time; type, total, i: LONGINT;
BEGIN
  result := PendingRecord(p); IF result # 1 THEN RETURN result END;
  IF IsCCS(p.wire) & ~p.ccsSeen & (p.authStage = 0) & (p.message.len = 0) THEN p.ccsSeen := TRUE; RETURN 0 END;
  IF (p.wire.data[0] # 17X) OR (p.clientSeq = MAX(LONGINT)) OR
     ~TLS13Records.OpenRecord(p.clientKey, p.clientIV, p.clientSeq, p.wire, type, plain) THEN
    Fail(BadRecordMac, "the client handshake record did not decrypt"); RETURN -1
  END;
  INC(p.clientSeq);
  IF (type # TLS13Records.Handshake) OR (plain.len < 1) OR (plain.len > MaxPlain) OR
     (p.message.len+plain.len > TLSBytes.MaxLen) THEN
    Fail(UnexpectedMessage, "expected client authentication before application data"); RETURN -1
  END;
  TLSBytes.Append(p.message, plain);
  WHILE p.message.len >= 4 DO
    total := 4+TLSBytes.GetBE24(p.message, 1);
    IF total > TLSBytes.MaxLen THEN Fail(DecodeError, "a client handshake message is too long"); RETURN -1 END;
    IF p.message.len < total THEN RETURN 0 END;
    IF p.transcript.len+total > TLSBytes.MaxLen THEN Fail(DecodeError, "the handshake transcript is too long"); RETURN -1 END;
    TLSBytes.Slice(p.message, 0, total, message);
    CASE p.authStage OF
    | 0:
        TLSNow.Current(now);
        IF ~TLS13Auth.Certificate(message, certificate) OR ~TLS13Auth.PinnedEd25519(certificate, p.pin, now, FALSE, p.spki) THEN
          Fail(HandshakeFailure, "the client does not match the pinned Ed25519 identity"); RETURN -1
        END
    | 1:
        IF ~TLS13Auth.Verify(message, p.transcript, p.spki, FALSE) THEN Fail(DecryptError, "the client CertificateVerify did not verify"); RETURN -1 END
    | 2:
        TLS13Keys.HashMessages(p.transcript, hash);
        IF ~TLS13Finished.VerifyFinishedMessage(message, p.clientFinished, hash) THEN Fail(DecryptError, "the client Finished did not verify"); RETURN -1 END
    ELSE Fail(UnexpectedMessage, "data after the client Finished"); RETURN -1
    END;
    TLSBytes.Append(p.transcript, message); INC(p.authStage);
    FOR i := total TO p.message.len-1 DO p.message.data[i-total] := p.message.data[i] END;
    DEC(p.message.len, total);
    IF p.authStage = 3 THEN
      IF p.message.len # 0 THEN Fail(UnexpectedMessage, "data after the client Finished"); RETURN -1 END;
      RETURN 1
    END
  END;
  RETURN 0
END PendingAuth;

(** Advances a nonblocking Ed25519 server handshake: 0 would block, 1 authenticated, -1 failed.
    On success, the established connection is transferred to an inactive TLS13Live state.
    On completion or failure, p is released; failures close fd and set lastError.
    The caller owns deadlines and must close pending handshakes when they expire. *)
PROCEDURE PollEd25519*(VAR p: Pending; VAR s: TLS13Live.State): INTEGER;
VAR result: INTEGER;
BEGIN
  IF p = NIL THEN RETURN -1 END;
  lastError := ""; alertDesc := 0; result := 0;
  CASE p.phase OF
  | 0, 2: result := PendingPlain(p)
  | 1, 3:
      result := PendingFlush(p);
      IF result = 1 THEN INC(p.phase); result := 0 END
  | 4:
      result := PendingAuth(p);
      IF result = 1 THEN
        TLS13Live.Accepted(s, p.fd, p.serverSecret, p.clientSecret); p.fd := -1;
        IF ~TLS13Live.UseNonblocking(s) THEN
          TLS13Live.CloseNow(s); ClosePending(p); COPY("cannot enable resumable TLS application I/O", lastError); RETURN -1
        END;
        s.peerAuthenticated := TRUE; s.identitySent := TRUE; COPY(p.name, serverName); ClosePending(p); RETURN 1
      END
  ELSE result := -1
  END;
  IF result < 0 THEN
    IF lastError = "" THEN COPY("the Ed25519 server handshake failed", lastError) END;
    ClosePending(p); RETURN -1
  END;
  RETURN 0
END PollEd25519;

BEGIN
  verbose := FALSE; lastError := ""; serverName := ""; alertDesc := 0; encrypted := FALSE;
  TLSBytes.Init(hsKey); TLSBytes.Init(hsIV); hsSeq := 0; single := NIL
END TLS13Server.
