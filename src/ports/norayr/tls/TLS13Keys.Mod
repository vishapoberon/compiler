MODULE TLS13Keys;
IMPORT TLSBytes, TLSSHA256, TLSHKDF;

CONST
  HashLen* = 32;
  AES128KeyLen* = 16;
  GCMIVLen* = 12;

PROCEDURE ZeroHash*(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(b);
  i := 0; WHILE i < HashLen DO TLSBytes.AppendByte(b, 0); INC(i) END
END ZeroHash;

PROCEDURE EmptyTranscriptHash*(VAR b: TLSBytes.Buffer);
VAR empty: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSBytes.Init(empty);
  TLSSHA256.DigestBuffer(empty, d);
  TLSSHA256.DigestToBuffer(d, b)
END EmptyTranscriptHash;

PROCEDURE HashMessages*(VAR messages: TLSBytes.Buffer; VAR out: TLSBytes.Buffer);
VAR d: TLSSHA256.Digest;
BEGIN
  TLSSHA256.DigestBuffer(messages, d);
  TLSSHA256.DigestToBuffer(d, out)
END HashMessages;

PROCEDURE InitialEarlySecretNoPSK*(VAR earlySecret: TLSBytes.Buffer);
VAR zeroSalt, zeroIKM: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  ZeroHash(zeroSalt);
  ZeroHash(zeroIKM);
  TLSHKDF.Extract(zeroSalt, zeroIKM, d);
  TLSSHA256.DigestToBuffer(d, earlySecret)
END InitialEarlySecretNoPSK;

PROCEDURE DeriveSecret*(VAR secret: TLSBytes.Buffer; label: ARRAY OF CHAR; VAR transcriptHash: TLSBytes.Buffer; VAR out: TLSBytes.Buffer);
BEGIN
  TLSHKDF.DeriveSecret(secret, label, transcriptHash, out)
END DeriveSecret;

PROCEDURE DerivedSecret*(VAR secret: TLSBytes.Buffer; VAR out: TLSBytes.Buffer);
VAR emptyHash: TLSBytes.Buffer;
BEGIN
  EmptyTranscriptHash(emptyHash);
  DeriveSecret(secret, "derived", emptyHash, out)
END DerivedSecret;

PROCEDURE HandshakeSecret*(VAR sharedSecret: TLSBytes.Buffer; VAR out: TLSBytes.Buffer);
VAR early, derived: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  IF sharedSecret.len # HashLen THEN HALT(130) END;
  InitialEarlySecretNoPSK(early);
  DerivedSecret(early, derived);
  TLSHKDF.Extract(derived, sharedSecret, d);
  TLSSHA256.DigestToBuffer(d, out)
END HandshakeSecret;

PROCEDURE TrafficKey*(VAR trafficSecret: TLSBytes.Buffer; VAR key: TLSBytes.Buffer);
VAR empty: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(empty);
  TLSHKDF.ExpandLabel(trafficSecret, "key", empty, AES128KeyLen, key)
END TrafficKey;

PROCEDURE TrafficIV*(VAR trafficSecret: TLSBytes.Buffer; VAR iv: TLSBytes.Buffer);
VAR empty: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(empty);
  TLSHKDF.ExpandLabel(trafficSecret, "iv", empty, GCMIVLen, iv)
END TrafficIV;

PROCEDURE FinishedKey*(VAR trafficSecret: TLSBytes.Buffer; VAR key: TLSBytes.Buffer);
VAR empty: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(empty);
  TLSHKDF.ExpandLabel(trafficSecret, "finished", empty, HashLen, key)
END FinishedKey;

PROCEDURE HandshakeTrafficSecrets*(VAR sharedSecret, transcriptHash: TLSBytes.Buffer; VAR clientSecret, serverSecret: TLSBytes.Buffer);
VAR hs: TLSBytes.Buffer;
BEGIN
  IF transcriptHash.len # HashLen THEN HALT(131) END;
  HandshakeSecret(sharedSecret, hs);
  DeriveSecret(hs, "c hs traffic", transcriptHash, clientSecret);
  DeriveSecret(hs, "s hs traffic", transcriptHash, serverSecret)
END HandshakeTrafficSecrets;

PROCEDURE HandshakeKeys*(VAR sharedSecret, transcriptHash: TLSBytes.Buffer;
                         VAR clientKey, clientIV, serverKey, serverIV, clientFinishedKey, serverFinishedKey: TLSBytes.Buffer);
VAR cSec, sSec: TLSBytes.Buffer;
BEGIN
  HandshakeTrafficSecrets(sharedSecret, transcriptHash, cSec, sSec);
  TrafficKey(cSec, clientKey);
  TrafficIV(cSec, clientIV);
  FinishedKey(cSec, clientFinishedKey);
  TrafficKey(sSec, serverKey);
  TrafficIV(sSec, serverIV);
  FinishedKey(sSec, serverFinishedKey)
END HandshakeKeys;

PROCEDURE MasterSecret*(VAR handshakeSecret: TLSBytes.Buffer; VAR masterSecret: TLSBytes.Buffer);
VAR derived, zeroIKM: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  IF handshakeSecret.len # HashLen THEN HALT(132) END;
  DerivedSecret(handshakeSecret, derived);
  ZeroHash(zeroIKM);
  TLSHKDF.Extract(derived, zeroIKM, d);
  TLSSHA256.DigestToBuffer(d, masterSecret)
END MasterSecret;

END TLS13Keys.
