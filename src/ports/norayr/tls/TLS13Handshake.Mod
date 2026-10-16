MODULE TLS13Handshake;
IMPORT TLSBytes;

CONST
  HandshakeRecord* = 22;
  LegacyMajor = 3;
  LegacyMinor = 3;

  ClientHello* = 1;
  ServerHello* = 2;
  Finished* = 20;

  TLS13Major = 3;
  TLS13Minor = 4;

  CipherTLSAES128GCMSHA256Hi* = 19;  (* 0x13 *)
  CipherTLSAES128GCMSHA256Lo* = 1;   (* 0x01 *)

  ExtServerName = 0;
  ExtSupportedGroups = 10;
  ExtSignatureAlgorithms = 13;
  ExtSupportedVersions = 43;
  ExtKeyShare = 51;
  ExtCookie = 44;

  GroupX25519* = 1DH; GroupP256* = 17H;  (** named groups: x25519, secp256r1 *)

  GroupX25519Hi = 0;
  GroupX25519Lo = 29;                (* 0x001d *)
  SigRsaPssRsaeSha256Hi = 8;
  SigRsaPssRsaeSha256Lo = 4;

PROCEDURE StringLen(s: ARRAY OF CHAR): LONGINT;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END;
  RETURN i
END StringLen;

PROCEDURE AppendHost(VAR b: TLSBytes.Buffer; host: ARRAY OF CHAR);
VAR i, n: LONGINT;
BEGIN
  n := StringLen(host); i := 0;
  WHILE i < n DO TLSBytes.AppendByte(b, ORD(host[i])); INC(i) END
END AppendHost;

PROCEDURE AppendExtension(VAR dst: TLSBytes.Buffer; extType: LONGINT; VAR data: TLSBytes.Buffer);
BEGIN
  TLSBytes.PutBE16(dst, extType);
  TLSBytes.PutBE16(dst, data.len);
  TLSBytes.Append(dst, data)
END AppendExtension;

PROCEDURE MakeSNI(host: ARRAY OF CHAR; VAR extData: TLSBytes.Buffer);
VAR n: LONGINT;
BEGIN
  n := StringLen(host);
  TLSBytes.Init(extData);
  TLSBytes.PutBE16(extData, 1 + 2 + n);  (* server_name_list length *)
  TLSBytes.AppendByte(extData, 0);       (* host_name *)
  TLSBytes.PutBE16(extData, n);
  AppendHost(extData, host)
END MakeSNI;

(* host is an IP address, not a name: only digits and dots (IPv4), or a colon (IPv6); RFC 6066 3
   allows no address in server_name *)
PROCEDURE IsAddress(host: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT; digitsDots: BOOLEAN;
BEGIN
  i := 0; digitsDots := TRUE;
  WHILE (i < LEN(host)) & (host[i] # 0X) DO
    IF host[i] = ":" THEN RETURN TRUE END;
    IF ~((host[i] >= "0") & (host[i] <= "9") OR (host[i] = ".")) THEN digitsDots := FALSE END;
    INC(i)
  END;
  RETURN digitsDots & (i > 0)
END IsAddress;

PROCEDURE MakeSupportedVersions(VAR extData: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(extData);
  TLSBytes.AppendByte(extData, 2);
  TLSBytes.AppendByte(extData, TLS13Major);
  TLSBytes.AppendByte(extData, TLS13Minor)
END MakeSupportedVersions;

PROCEDURE MakeSignatureAlgorithms(VAR extData: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(extData);
  (* the schemes TLSSig verifies: ECDSA and RSA-PSS for CertificateVerify; RSA PKCS#1 v1.5 only
     for certificates (without signature_algorithms_cert this list covers both, RFC 8446 4.2.3) *)
  TLSBytes.PutBE16(extData, 18);
  TLSBytes.AppendByte(extData, 4); TLSBytes.AppendByte(extData, 3);  (* ecdsa_secp256r1_sha256 *)
  TLSBytes.AppendByte(extData, 5); TLSBytes.AppendByte(extData, 3);  (* ecdsa_secp384r1_sha384 *)
  TLSBytes.AppendByte(extData, 6); TLSBytes.AppendByte(extData, 3);  (* ecdsa_secp521r1_sha512 *)
  TLSBytes.AppendByte(extData, 8); TLSBytes.AppendByte(extData, 4);  (* rsa_pss_rsae_sha256 *)
  TLSBytes.AppendByte(extData, 8); TLSBytes.AppendByte(extData, 5);  (* rsa_pss_rsae_sha384 *)
  TLSBytes.AppendByte(extData, 8); TLSBytes.AppendByte(extData, 6);  (* rsa_pss_rsae_sha512 *)
  TLSBytes.AppendByte(extData, 4); TLSBytes.AppendByte(extData, 1);  (* rsa_pkcs1_sha256 *)
  TLSBytes.AppendByte(extData, 5); TLSBytes.AppendByte(extData, 1);  (* rsa_pkcs1_sha384 *)
  TLSBytes.AppendByte(extData, 6); TLSBytes.AppendByte(extData, 1)   (* rsa_pkcs1_sha512 *)
END MakeSignatureAlgorithms;

(* x25519 first (its key share is in the first ClientHello), secp256r1 after a HelloRetryRequest *)
PROCEDURE MakeSupportedGroups(VAR extData: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(extData);
  TLSBytes.PutBE16(extData, 4);
  TLSBytes.PutBE16(extData, GroupX25519);
  TLSBytes.PutBE16(extData, GroupP256)
END MakeSupportedGroups;

(* the key share of group: x25519 32 bytes, secp256r1 65 (04 x y) *)
PROCEDURE ShareLen(group: LONGINT): LONGINT;
BEGIN
  IF group = GroupX25519 THEN RETURN 32 ELSIF group = GroupP256 THEN RETURN 65 END;
  RETURN 0
END ShareLen;

PROCEDURE MakeClientKeyShare(group: LONGINT; VAR pubKey: TLSBytes.Buffer; VAR extData: TLSBytes.Buffer);
BEGIN
  IF pubKey.len # ShareLen(group) THEN HALT(90) END;
  TLSBytes.Init(extData);
  TLSBytes.PutBE16(extData, 2 + 2 + pubKey.len);  (* client_shares vector length *)
  TLSBytes.PutBE16(extData, group);
  TLSBytes.PutBE16(extData, pubKey.len);
  TLSBytes.Append(extData, pubKey)
END MakeClientKeyShare;

(* a ClientHello with the key share pubKey of group; cookie: the extension data of the cookie of
   a HelloRetryRequest, echoed (none if empty) *)
PROCEDURE BuildHello(host: ARRAY OF CHAR; VAR random: TLSBytes.Buffer; group: LONGINT;
  VAR pubKey, cookie: TLSBytes.Buffer; VAR msg: TLSBytes.Buffer);
VAR body, exts, e: TLSBytes.Buffer;
BEGIN
  IF random.len # 32 THEN HALT(91) END;
  IF pubKey.len # ShareLen(group) THEN HALT(92) END;

  TLSBytes.Init(exts);
  IF ~IsAddress(host) THEN MakeSNI(host, e); AppendExtension(exts, ExtServerName, e) END;
  MakeSupportedVersions(e); AppendExtension(exts, ExtSupportedVersions, e);
  MakeSignatureAlgorithms(e); AppendExtension(exts, ExtSignatureAlgorithms, e);
  MakeSupportedGroups(e); AppendExtension(exts, ExtSupportedGroups, e);
  MakeClientKeyShare(group, pubKey, e); AppendExtension(exts, ExtKeyShare, e);
  IF cookie.len > 0 THEN AppendExtension(exts, ExtCookie, cookie) END;

  TLSBytes.Init(body);
  TLSBytes.AppendByte(body, LegacyMajor);
  TLSBytes.AppendByte(body, LegacyMinor);
  TLSBytes.Append(body, random);
  (*
     TLS 1.3 compatibility mode: many real servers expect a non-empty
     legacy_session_id and will echo it in ServerHello. It is not secret.
  *)
  TLSBytes.AppendByte(body, 32);        (* legacy_session_id length *)
  TLSBytes.Append(body, random);        (* reuse random bytes as opaque session id *)
  TLSBytes.PutBE16(body, 2);            (* cipher_suites length *)
  TLSBytes.AppendByte(body, CipherTLSAES128GCMSHA256Hi);
  TLSBytes.AppendByte(body, CipherTLSAES128GCMSHA256Lo);
  TLSBytes.AppendByte(body, 1);         (* compression_methods length *)
  TLSBytes.AppendByte(body, 0);         (* null compression *)
  TLSBytes.PutBE16(body, exts.len);
  TLSBytes.Append(body, exts);

  TLSBytes.Init(msg);
  TLSBytes.AppendByte(msg, ClientHello);
  TLSBytes.PutBE24(msg, body.len);
  TLSBytes.Append(msg, body)
END BuildHello;

(** the first ClientHello: the x25519 key share pubKey (32 bytes) *)
PROCEDURE BuildClientHelloMessage*(host: ARRAY OF CHAR; VAR random, pubKey: TLSBytes.Buffer; VAR msg: TLSBytes.Buffer);
VAR none: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(none);
  BuildHello(host, random, GroupX25519, pubKey, none, msg)
END BuildClientHelloMessage;

(** the ClientHello after a HelloRetryRequest: the same random and session id, the key share
  pubKey of group, the cookie of the HelloRetryRequest *)
PROCEDURE BuildClientHello2*(host: ARRAY OF CHAR; VAR random: TLSBytes.Buffer; group: LONGINT;
  VAR pubKey, cookie: TLSBytes.Buffer; VAR msg: TLSBytes.Buffer);
BEGIN
  BuildHello(host, random, group, pubKey, cookie, msg)
END BuildClientHello2;

PROCEDURE BuildPlainHandshakeRecord*(VAR handshakeMsg: TLSBytes.Buffer; VAR record: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(record);
  TLSBytes.AppendByte(record, HandshakeRecord);
  TLSBytes.AppendByte(record, LegacyMajor);
  TLSBytes.AppendByte(record, LegacyMinor);
  TLSBytes.PutBE16(record, handshakeMsg.len);
  TLSBytes.Append(record, handshakeMsg)
END BuildPlainHandshakeRecord;

PROCEDURE BuildClientHelloRecord*(host: ARRAY OF CHAR; VAR random, pubKey: TLSBytes.Buffer; VAR record: TLSBytes.Buffer);
VAR msg: TLSBytes.Buffer;
BEGIN
  BuildClientHelloMessage(host, random, pubKey, msg);
  BuildPlainHandshakeRecord(msg, record)
END BuildClientHelloRecord;

PROCEDURE ExtractServerHelloKeyShare*(VAR msg: TLSBytes.Buffer; VAR pubKey: TLSBytes.Buffer): BOOLEAN;
VAR bodyLen, pos, endPos, sidLen, extLen, extEnd, et, el, keyLen: LONGINT;
BEGIN
  TLSBytes.Init(pubKey);
  IF msg.len < 4 THEN RETURN FALSE END;
  IF ORD(msg.data[0]) # ServerHello THEN RETURN FALSE END;
  bodyLen := TLSBytes.GetBE24(msg, 1);
  IF bodyLen # msg.len - 4 THEN RETURN FALSE END;

  pos := 4;
  IF pos + 2 + 32 + 1 > msg.len THEN RETURN FALSE END;
  INC(pos, 2);                         (* legacy_version *)
  INC(pos, 32);                        (* random *)
  sidLen := ORD(msg.data[pos]); INC(pos);
  IF pos + sidLen + 2 + 1 + 2 > msg.len THEN RETURN FALSE END;
  INC(pos, sidLen);                    (* session_id_echo *)
  IF (ORD(msg.data[pos]) # CipherTLSAES128GCMSHA256Hi) OR (ORD(msg.data[pos+1]) # CipherTLSAES128GCMSHA256Lo) THEN RETURN FALSE END;
  INC(pos, 2);                         (* cipher suite *)
  IF ORD(msg.data[pos]) # 0 THEN RETURN FALSE END;
  INC(pos);                            (* compression method *)
  extLen := TLSBytes.GetBE16(msg, pos); INC(pos, 2);
  extEnd := pos + extLen;
  IF extEnd # msg.len THEN RETURN FALSE END;

  WHILE pos + 4 <= extEnd DO
    et := TLSBytes.GetBE16(msg, pos);
    el := TLSBytes.GetBE16(msg, pos + 2);
    INC(pos, 4);
    IF pos + el > extEnd THEN RETURN FALSE END;
    IF et = ExtKeyShare THEN
      IF el < 4 THEN RETURN FALSE END;
      IF (ORD(msg.data[pos]) # GroupX25519Hi) OR (ORD(msg.data[pos+1]) # GroupX25519Lo) THEN RETURN FALSE END;
      keyLen := TLSBytes.GetBE16(msg, pos + 2);
      IF keyLen # 32 THEN RETURN FALSE END;
      IF keyLen + 4 # el THEN RETURN FALSE END;
      TLSBytes.Slice(msg, pos + 4, keyLen, pubKey);
      RETURN TRUE
    END;
    INC(pos, el)
  END;
  RETURN FALSE
END ExtractServerHelloKeyShare;

(** the ServerHello msg answers our ClientHello (with session id sid) the way RFC 8446 requires:
  TLS 1.3 (supported_versions 0x0304), TLS_AES_128_GCM_SHA256, no compression, our session id
  echoed, an X25519 key share (in pubKey), no extension we did not offer, none twice; a
  HelloRetryRequest is not accepted. why: the reason when FALSE *)
(** msg is a HelloRetryRequest: a ServerHello with the random SHA-256("HelloRetryRequest") *)
PROCEDURE IsHelloRetryRequest*(VAR msg: TLSBytes.Buffer): BOOLEAN;
CONST hrr = "CF21AD74E59A6111BE1D8C021E65B891C2A211167ABB8C5E079E09E2C8A8339C";
VAR i, v: LONGINT; h: ARRAY 65 OF CHAR;
BEGIN
  IF (msg.len < 4 + 2 + 32) OR (ORD(msg.data[0]) # ServerHello) THEN RETURN FALSE END;
  h := hrr; i := 0;
  WHILE i < 32 DO
    v := ORD(h[2*i]) - ORD("0"); IF v > 9 THEN v := v - 7 END;
    v := v * 16 + ORD(h[2*i+1]) - ORD("0"); IF ORD(h[2*i+1]) > ORD("9") THEN v := v - 7 END;
    IF ORD(msg.data[6 + i]) # v THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END IsHelloRetryRequest;

(* the fields before the extensions of a ServerHello or HelloRetryRequest: version, session id
   echo, cipher suite, compression; pos: the first extension *)
PROCEDURE HelloStart(VAR msg, sid: TLSBytes.Buffer; VAR pos: LONGINT; VAR why: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  COPY("malformed ServerHello", why);
  IF (msg.len < 4 + 2 + 32 + 1) OR (ORD(msg.data[0]) # ServerHello) OR (TLSBytes.GetBE24(msg, 1) # msg.len - 4) THEN RETURN FALSE END;
  IF (ORD(msg.data[4]) # LegacyMajor) OR (ORD(msg.data[5]) # LegacyMinor) THEN RETURN FALSE END;
  pos := 38;
  IF (ORD(msg.data[pos]) # sid.len) OR (pos + 1 + sid.len + 3 + 2 > msg.len) THEN COPY("session id not echoed", why); RETURN FALSE END;
  i := 0;
  WHILE i < sid.len DO IF msg.data[pos + 1 + i] # sid.data[i] THEN COPY("session id not echoed", why); RETURN FALSE END; INC(i) END;
  INC(pos, 1 + sid.len);
  IF (ORD(msg.data[pos]) # CipherTLSAES128GCMSHA256Hi) OR (ORD(msg.data[pos+1]) # CipherTLSAES128GCMSHA256Lo) THEN
    COPY("cipher suite not offered", why); RETURN FALSE
  END;
  IF ORD(msg.data[pos + 2]) # 0 THEN RETURN FALSE END;
  INC(pos, 3);
  IF TLSBytes.GetBE16(msg, pos) + pos + 2 # msg.len THEN RETURN FALSE END;
  INC(pos, 2);
  RETURN TRUE
END HelloStart;

(** the ServerHello msg answers our ClientHello: TLS 1.3, the session id sid echoed, our cipher
  suite, a key share of group (pubKey), only the extensions we offered, once each; not a
  HelloRetryRequest, not a downgrade; why says what is wrong *)
PROCEDURE CheckServerHelloGroup*(VAR msg, sid: TLSBytes.Buffer; group: LONGINT; VAR pubKey: TLSBytes.Buffer; VAR why: ARRAY OF CHAR): BOOLEAN;
VAR pos, et, el, keyLen: LONGINT; sawVersions, sawKeyShare: BOOLEAN;
BEGIN
  TLSBytes.Init(pubKey);
  IF IsHelloRetryRequest(msg) THEN COPY("an unexpected HelloRetryRequest", why); RETURN FALSE END;
  (* a TLS 1.2 or older server marks the random (RFC 8446 4.1.3): a downgrade *)
  IF (msg.len >= 38) & (msg.data[30] = 44X) & (msg.data[31] = 4FX) & (msg.data[32] = 57X) & (msg.data[33] = 4EX) &
     (msg.data[34] = 47X) & (msg.data[35] = 52X) & (msg.data[36] = 44X) THEN
    COPY("the server does not speak TLS 1.3 (downgrade marker)", why); RETURN FALSE
  END;
  IF ~HelloStart(msg, sid, pos, why) THEN RETURN FALSE END;
  sawVersions := FALSE; sawKeyShare := FALSE;
  WHILE pos < msg.len DO
    COPY("malformed ServerHello", why);
    IF pos + 4 > msg.len THEN RETURN FALSE END;
    et := TLSBytes.GetBE16(msg, pos); el := TLSBytes.GetBE16(msg, pos + 2); INC(pos, 4);
    IF pos + el > msg.len THEN RETURN FALSE END;
    IF et = ExtSupportedVersions THEN
      IF sawVersions OR (el # 2) OR (ORD(msg.data[pos]) # TLS13Major) OR (ORD(msg.data[pos+1]) # TLS13Minor) THEN
        COPY("not TLS 1.3", why); RETURN FALSE
      END;
      sawVersions := TRUE
    ELSIF et = ExtKeyShare THEN
      keyLen := ShareLen(group);
      IF sawKeyShare OR (el < 4) OR (TLSBytes.GetBE16(msg, pos) # group) THEN COPY("key share not of the group offered", why); RETURN FALSE END;
      IF (TLSBytes.GetBE16(msg, pos + 2) # keyLen) OR (el # 4 + keyLen) THEN RETURN FALSE END;
      TLSBytes.Slice(msg, pos + 4, keyLen, pubKey); sawKeyShare := TRUE
    ELSE
      COPY("an extension we did not offer", why); RETURN FALSE
    END;
    INC(pos, el)
  END;
  IF ~sawVersions THEN COPY("not TLS 1.3 (no supported_versions)", why); RETURN FALSE END;
  IF ~sawKeyShare THEN COPY("no key share", why); RETURN FALSE END;
  RETURN TRUE
END CheckServerHelloGroup;

(** CheckServerHelloGroup for x25519 *)
PROCEDURE CheckServerHello*(VAR msg, sid, pubKey: TLSBytes.Buffer; VAR why: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN CheckServerHelloGroup(msg, sid, GroupX25519, pubKey, why)
END CheckServerHello;

(** the HelloRetryRequest msg (RFC 8446 4.1.4) after a ClientHello with a key share of offered:
  TLS 1.3, sid echoed, our cipher suite, and a group we support other than offered (group) or a
  cookie (the extension data to echo, else empty), nothing else; why says what is wrong *)
PROCEDURE CheckHelloRetryRequest*(VAR msg, sid: TLSBytes.Buffer; offered: LONGINT; VAR group: LONGINT;
  VAR cookie: TLSBytes.Buffer; VAR why: ARRAY OF CHAR): BOOLEAN;
VAR pos, et, el: LONGINT; sawVersions, sawKeyShare, sawCookie: BOOLEAN;
BEGIN
  TLSBytes.Init(cookie); group := offered;
  IF ~IsHelloRetryRequest(msg) OR ~HelloStart(msg, sid, pos, why) THEN RETURN FALSE END;
  sawVersions := FALSE; sawKeyShare := FALSE; sawCookie := FALSE;
  WHILE pos < msg.len DO
    COPY("malformed HelloRetryRequest", why);
    IF pos + 4 > msg.len THEN RETURN FALSE END;
    et := TLSBytes.GetBE16(msg, pos); el := TLSBytes.GetBE16(msg, pos + 2); INC(pos, 4);
    IF pos + el > msg.len THEN RETURN FALSE END;
    IF et = ExtSupportedVersions THEN
      IF sawVersions OR (el # 2) OR (ORD(msg.data[pos]) # TLS13Major) OR (ORD(msg.data[pos+1]) # TLS13Minor) THEN
        COPY("not TLS 1.3", why); RETURN FALSE
      END;
      sawVersions := TRUE
    ELSIF et = ExtKeyShare THEN
      IF sawKeyShare OR (el # 2) THEN RETURN FALSE END;
      group := TLSBytes.GetBE16(msg, pos);
      IF (ShareLen(group) = 0) OR (group = offered) THEN COPY("HelloRetryRequest for a group not offered", why); RETURN FALSE END;
      sawKeyShare := TRUE
    ELSIF et = ExtCookie THEN
      IF sawCookie OR (el < 3) OR (TLSBytes.GetBE16(msg, pos) # el - 2) THEN RETURN FALSE END;
      TLSBytes.Slice(msg, pos, el, cookie); sawCookie := TRUE
    ELSE
      COPY("an extension we did not offer", why); RETURN FALSE
    END;
    INC(pos, el)
  END;
  IF ~sawVersions THEN COPY("not TLS 1.3 (no supported_versions)", why); RETURN FALSE END;
  IF ~sawKeyShare & ~sawCookie THEN COPY("a HelloRetryRequest that changes nothing", why); RETURN FALSE END;
  RETURN TRUE
END CheckHelloRetryRequest;

PROCEDURE IsPlainHandshakeRecord*(VAR record: TLSBytes.Buffer): BOOLEAN;
BEGIN
  RETURN (record.len >= 5) & (ORD(record.data[0]) = HandshakeRecord) & (ORD(record.data[1]) = LegacyMajor) & (ORD(record.data[2]) = LegacyMinor)
END IsPlainHandshakeRecord;

PROCEDURE GetRecordPayload*(VAR record, payload: TLSBytes.Buffer): BOOLEAN;
VAR len: LONGINT;
BEGIN
  TLSBytes.Init(payload);
  IF ~IsPlainHandshakeRecord(record) THEN RETURN FALSE END;
  len := TLSBytes.GetBE16(record, 3);
  IF len # record.len - 5 THEN RETURN FALSE END;
  TLSBytes.Slice(record, 5, len, payload);
  RETURN TRUE
END GetRecordPayload;

END TLS13Handshake.
