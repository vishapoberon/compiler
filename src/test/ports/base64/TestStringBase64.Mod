MODULE TestStringBase64;
IMPORT Base64 := StringBase64, Out;
VAR encoded, decoded: ARRAY 64 OF CHAR;
    source: ARRAY 8 OF CHAR;

PROCEDURE Check(plain, expected: ARRAY OF CHAR);
BEGIN
  Base64.EncodeString(plain, encoded); ASSERT(encoded = expected);
  Base64.DecodeString(encoded, decoded); ASSERT(decoded = plain)
END Check;

BEGIN
  Base64.fixToIncludeEOL := FALSE;
  Check('', ''); Check('f', 'Zg=='); Check('fo', 'Zm8=');
  Check('foo', 'Zm9v'); Check('foob', 'Zm9vYg==');
  Check('fooba', 'Zm9vYmE='); Check('foobar', 'Zm9vYmFy');
  Check('Aladdin:open sesame', 'QWxhZGRpbjpvcGVuIHNlc2FtZQ==');
  source[0] := 0FFX; source[1] := 0FFX; source[2] := 0FFX; source[3] := 0X;
  Check(source, '////');
  Base64.fixToIncludeEOL := TRUE;
  source := 'f'; Base64.EncodeString(source, encoded);
  ASSERT(encoded = 'Zgo='); ASSERT(source = 'f');
  Out.String('string base64 tests passed'); Out.Ln
END TestStringBase64.
