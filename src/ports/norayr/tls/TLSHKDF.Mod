MODULE TLSHKDF;
IMPORT TLSBytes, TLSSHA256;

PROCEDURE Extract*(VAR salt, ikm: TLSBytes.Buffer; VAR out: TLSSHA256.Digest);
BEGIN
  TLSSHA256.HMAC(salt, ikm, out)
END Extract;

PROCEDURE Expand*(VAR prk, info: TLSBytes.Buffer; outLen: LONGINT; VAR out: TLSBytes.Buffer);
VAR
  t, input, prk0: TLSBytes.Buffer;
  d: TLSSHA256.Digest;
  n, i, c: LONGINT;
BEGIN
  TLSBytes.Init(out); TLSBytes.Init(t);
  n := (outLen + 31) DIV 32;
  c := 1;
  WHILE c <= n DO
    TLSBytes.Init(input);
    TLSBytes.Append(input, t);
    TLSBytes.Append(input, info);
    TLSBytes.AppendByte(input, c);
    TLSBytes.Copy(prk, prk0);
    TLSSHA256.HMAC(prk0, input, d);
    TLSBytes.Init(t);
    i := 0; WHILE i < 32 DO TLSBytes.AppendByte(t, ORD(d[i])); INC(i) END;
    i := 0;
    WHILE (i < 32) & (out.len < outLen) DO TLSBytes.AppendByte(out, ORD(t.data[i])); INC(i) END;
    INC(c)
  END
END Expand;

PROCEDURE ExpandLabel*(VAR secret: TLSBytes.Buffer; label: ARRAY OF CHAR; VAR context: TLSBytes.Buffer; outLen: LONGINT; VAR out: TLSBytes.Buffer);
VAR info, full: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(full);
  TLSBytes.AppendString(full, "tls13 ");
  TLSBytes.AppendString(full, label);

  TLSBytes.Init(info);
  TLSBytes.PutBE16(info, outLen);
  TLSBytes.AppendByte(info, full.len);
  TLSBytes.Append(info, full);
  TLSBytes.AppendByte(info, context.len);
  TLSBytes.Append(info, context);
  Expand(secret, info, outLen, out)
END ExpandLabel;

PROCEDURE DeriveSecret*(VAR secret: TLSBytes.Buffer; label: ARRAY OF CHAR; VAR messagesHash: TLSBytes.Buffer; VAR out: TLSBytes.Buffer);
BEGIN
  ExpandLabel(secret, label, messagesHash, 32, out)
END DeriveSecret;

END TLSHKDF.
