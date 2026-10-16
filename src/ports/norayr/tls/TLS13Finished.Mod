MODULE TLS13Finished;
IMPORT TLSBytes, TLSSHA256;

CONST
  FinishedType* = 20;
  VerifyDataLen* = 32;

PROCEDURE ComputeVerifyData*(VAR finishedKey, transcriptHash: TLSBytes.Buffer; VAR verifyData: TLSBytes.Buffer);
VAR d: TLSSHA256.Digest; i: LONGINT;
BEGIN
  IF finishedKey.len # 32 THEN HALT(150) END;
  IF transcriptHash.len # 32 THEN HALT(151) END;
  TLSSHA256.HMAC(finishedKey, transcriptHash, d);
  TLSBytes.Init(verifyData);
  i := 0;
  WHILE i < VerifyDataLen DO
    TLSBytes.AppendByte(verifyData, ORD(d[i])); INC(i)
  END
END ComputeVerifyData;

PROCEDURE BuildFinishedMessage*(VAR finishedKey, transcriptHash: TLSBytes.Buffer; VAR msg: TLSBytes.Buffer);
VAR verifyData: TLSBytes.Buffer;
BEGIN
  ComputeVerifyData(finishedKey, transcriptHash, verifyData);
  TLSBytes.Init(msg);
  TLSBytes.AppendByte(msg, FinishedType);
  TLSBytes.PutBE24(msg, VerifyDataLen);
  TLSBytes.Append(msg, verifyData)
END BuildFinishedMessage;

PROCEDURE VerifyFinishedMessage*(VAR msg, finishedKey, transcriptHash: TLSBytes.Buffer): BOOLEAN;
VAR expected, got: TLSBytes.Buffer; i, n: LONGINT;
BEGIN
  IF msg.len < 4 THEN RETURN FALSE END;
  IF ORD(msg.data[0]) # FinishedType THEN RETURN FALSE END;
  n := TLSBytes.GetBE24(msg, 1);
  IF n # VerifyDataLen THEN RETURN FALSE END;
  IF msg.len # 4 + VerifyDataLen THEN RETURN FALSE END;
  ComputeVerifyData(finishedKey, transcriptHash, expected);
  TLSBytes.Init(got);
  i := 0;
  WHILE i < VerifyDataLen DO
    TLSBytes.AppendByte(got, ORD(msg.data[4+i])); INC(i)
  END;
  RETURN TLSBytes.EqualConstTime(expected, got)
END VerifyFinishedMessage;

PROCEDURE AppendToTranscript*(VAR transcript, finishedMsg: TLSBytes.Buffer);
BEGIN
  TLSBytes.Append(transcript, finishedMsg)
END AppendToTranscript;

END TLS13Finished.
