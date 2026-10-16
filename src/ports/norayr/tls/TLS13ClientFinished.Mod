MODULE TLS13ClientFinished;
IMPORT TLSBytes, TLS13Keys, TLS13Finished, TLS13Records;

PROCEDURE BuildClientFinishedMessage*(VAR transcript, clientFinishedKey: TLSBytes.Buffer; VAR finishedMsg: TLSBytes.Buffer);
VAR th: TLSBytes.Buffer;
BEGIN
  TLS13Keys.HashMessages(transcript, th);
  TLS13Finished.BuildFinishedMessage(clientFinishedKey, th, finishedMsg)
END BuildClientFinishedMessage;

PROCEDURE BuildClientFinishedRecord*(VAR clientKey, clientIV: TLSBytes.Buffer; seq: LONGINT;
                                    VAR transcript, clientFinishedKey: TLSBytes.Buffer;
                                    VAR record, finishedMsg: TLSBytes.Buffer);
BEGIN
  BuildClientFinishedMessage(transcript, clientFinishedKey, finishedMsg);
  TLS13Records.ProtectRecord(clientKey, clientIV, seq, TLS13Records.Handshake, finishedMsg, record)
END BuildClientFinishedRecord;

PROCEDURE AppendClientFinished*(VAR transcript, finishedMsg: TLSBytes.Buffer);
BEGIN
  TLSBytes.Append(transcript, finishedMsg)
END AppendClientFinished;

PROCEDURE AppendClientFinishedRecord*(VAR clientKey, clientIV: TLSBytes.Buffer; seq: LONGINT;
                                             VAR transcript, clientFinishedKey: TLSBytes.Buffer;
                                             VAR record: TLSBytes.Buffer);
VAR finishedMsg: TLSBytes.Buffer;
BEGIN
  BuildClientFinishedRecord(clientKey, clientIV, seq, transcript, clientFinishedKey, record, finishedMsg);
  AppendClientFinished(transcript, finishedMsg)
END AppendClientFinishedRecord;

END TLS13ClientFinished.
