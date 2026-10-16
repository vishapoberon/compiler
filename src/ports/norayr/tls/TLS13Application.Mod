MODULE TLS13Application;
IMPORT TLSBytes, TLS13Keys, TLS13Records;

PROCEDURE ApplicationTrafficSecrets*(VAR masterSecret, transcript: TLSBytes.Buffer;
                                     VAR clientSecret, serverSecret: TLSBytes.Buffer);
VAR th: TLSBytes.Buffer;
BEGIN
  TLS13Keys.HashMessages(transcript, th);
  TLS13Keys.DeriveSecret(masterSecret, "c ap traffic", th, clientSecret);
  TLS13Keys.DeriveSecret(masterSecret, "s ap traffic", th, serverSecret)
END ApplicationTrafficSecrets;

PROCEDURE ApplicationKeys*(VAR masterSecret, transcript: TLSBytes.Buffer;
                           VAR clientKey, clientIV, serverKey, serverIV: TLSBytes.Buffer);
VAR cSec, sSec: TLSBytes.Buffer;
BEGIN
  ApplicationTrafficSecrets(masterSecret, transcript, cSec, sSec);
  TLS13Keys.TrafficKey(cSec, clientKey);
  TLS13Keys.TrafficIV(cSec, clientIV);
  TLS13Keys.TrafficKey(sSec, serverKey);
  TLS13Keys.TrafficIV(sSec, serverIV)
END ApplicationKeys;

PROCEDURE ProtectApplicationData*(VAR key, iv: TLSBytes.Buffer; seq: LONGINT;
                                  VAR payload: TLSBytes.Buffer; VAR record: TLSBytes.Buffer);
BEGIN
  TLS13Records.ProtectRecord(key, iv, seq, TLS13Records.ApplicationData, payload, record)
END ProtectApplicationData;

PROCEDURE ProtectApplicationDataPadded*(VAR key, iv: TLSBytes.Buffer; seq: LONGINT;
                                        paddingLen: LONGINT;
                                        VAR payload: TLSBytes.Buffer; VAR record: TLSBytes.Buffer);
BEGIN
  TLS13Records.ProtectRecordPadded(key, iv, seq, TLS13Records.ApplicationData, paddingLen, payload, record)
END ProtectApplicationDataPadded;

PROCEDURE OpenApplicationData*(VAR key, iv: TLSBytes.Buffer; seq: LONGINT;
                               VAR record: TLSBytes.Buffer; VAR payload: TLSBytes.Buffer): BOOLEAN;
VAR innerType: LONGINT;
BEGIN
  IF ~TLS13Records.OpenRecord(key, iv, seq, record, innerType, payload) THEN RETURN FALSE END;
  RETURN innerType = TLS13Records.ApplicationData
END OpenApplicationData;

END TLS13Application.
