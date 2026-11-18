MODULE TLSTestCertRequest;
IMPORT Out, TLSBytes, TLS13EncHandshake, TLSSig;
VAR checks, failures, i: LONGINT; saw, finished: BOOLEAN;
  extensions, message, partial, transcript, key, context, chunk: TLSBytes.Buffer;

PROCEDURE Check(ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(failures); Out.String("FAIL certificate request case "); Out.Int(checks, 0); Out.Ln END
END Check;

PROCEDURE Digit(c: CHAR): LONGINT;
BEGIN IF c <= "9" THEN RETURN ORD(c)-ORD("0") END; RETURN ORD(c)-ORD("a")+10 END Digit;

PROCEDURE Extension(typ: LONGINT; hex: ARRAY OF CHAR);
VAR value: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLSBytes.Init(value); i := 0;
  WHILE hex[i] # 0X DO TLSBytes.AppendByte(value, Digit(hex[i])*16+Digit(hex[i+1])); INC(i, 2) END;
  TLSBytes.PutBE16(extensions, typ); TLSBytes.PutBE16(extensions, value.len); TLSBytes.Append(extensions, value)
END Extension;

PROCEDURE Build(contextLength: LONGINT);
BEGIN
  TLSBytes.Init(message); TLSBytes.AppendByte(message, TLS13EncHandshake.CertificateRequest);
  TLSBytes.PutBE24(message, 3+contextLength+extensions.len); TLSBytes.AppendByte(message, contextLength);
  IF contextLength > 0 THEN TLSBytes.AppendByte(message, 1) END;
  TLSBytes.PutBE16(message, extensions.len); TLSBytes.Append(message, extensions)
END Build;

PROCEDURE Start;
VAR ee: TLSBytes.Buffer;
BEGIN
  TLS13EncHandshake.ResetState;
  TLSBytes.Init(partial); TLSBytes.Init(transcript); TLSBytes.Init(key);
  TLS13EncHandshake.BuildEmptyEncryptedExtensions(ee);
  Check(TLS13EncHandshake.ProcessServerHandshakeBuffered(ee, partial, transcript, key, saw, finished))
END Start;

PROCEDURE Process(): BOOLEAN;
BEGIN
  RETURN TLS13EncHandshake.ProcessServerHandshakeBuffered(message, partial, transcript, key, saw, finished)
END Process;

PROCEDURE Reject;
BEGIN Start; Check(~Process()); Check(~TLS13EncHandshake.CertificateRequested(context)) END Reject;

BEGIN
  TLSBytes.Init(extensions); Extension(13, "000408070403"); Build(0); Start;
  Check(~TLS13EncHandshake.CertificateRequested(context)); Check(~TLS13EncHandshake.SignatureRequested(TLSSig.Ed25519));
  Check(Process()); Check(TLS13EncHandshake.CertificateRequested(context) & (context.len = 0));
  Check(TLS13EncHandshake.SignatureRequested(TLSSig.Ed25519));
  Check(TLS13EncHandshake.SignatureRequested(TLSSig.EcdsaP256Sha256));
  Check(~TLS13EncHandshake.SignatureRequested(TLSSig.RsaPssRsaeSha256));
  Check(~Process());
  Start;
  FOR i := 0 TO message.len-1 DO
    TLSBytes.Slice(message, i, 1, chunk);
    Check(TLS13EncHandshake.ProcessServerHandshakeBuffered(chunk, partial, transcript, key, saw, finished));
    Check(TLS13EncHandshake.CertificateRequested(context) = (i = message.len-1))
  END;
  Check(TLS13EncHandshake.SignatureRequested(TLSSig.Ed25519));
  TLSBytes.Init(extensions); Build(0); Reject;
  Extension(50, "00020807"); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(13, "00020807"); Build(1); Reject;
  TLSBytes.Init(extensions); Extension(13, ""); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(13, "0000"); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(13, "000108"); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(13, "00040807"); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(13, "0002080700"); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(13, "00020807"); Extension(13, "00020403"); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(65535, ""); Extension(13, "00020807"); Build(0); Start;
  Check(Process()); Check(TLS13EncHandshake.SignatureRequested(TLSSig.Ed25519));
  Extension(65535, ""); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(13, "00020807"); Extension(50, "0000"); Build(0); Reject;
  TLSBytes.Init(extensions); Extension(13, "00020807"); Extension(50, "00020403"); Build(0); Start; Check(Process());
  message.data[6] := CHR(ORD(message.data[6])+1); Reject;
  TLSBytes.Init(extensions); Extension(13, "00020807"); Build(0);
  message.data[10] := CHR(ORD(message.data[10])+1); Reject;
  Start; Check(~TLS13EncHandshake.SignatureRequested(TLSSig.Ed25519));
  TLSBytes.Init(extensions); Extension(13, "00020807"); Build(0); Start;
  TLSBytes.SetLen(transcript, TLSBytes.MaxLen); Check(~Process());
  Start; TLSBytes.SetLen(partial, TLSBytes.MaxLen); Check(~Process());
  Start; TLSBytes.Init(message); TLSBytes.AppendByte(message, TLS13EncHandshake.CertificateRequest);
  TLSBytes.PutBE24(message, TLSBytes.MaxLen); Check(~Process());
  Check(~TLS13EncHandshake.CertificateRequested(context));
  Out.String("TLSTestCertRequest: "); Out.Int(checks, 0); Out.String(" checks, ");
  Out.Int(failures, 0); Out.String(" failed"); Out.Ln;
  IF failures # 0 THEN HALT(1) END
END TLSTestCertRequest.
