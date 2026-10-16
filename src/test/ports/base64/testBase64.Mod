MODULE testBase64;
IMPORT Out, Base64 := StringBase64;

VAR src, dst,dst2: ARRAY 128 OF CHAR;

BEGIN
COPY("mypassword", src);
Base64.EncodeString(src, dst);
Out.String(dst); Out.Ln;

Base64.DecodeString(dst, dst2);
Out.String(dst2); Out.Ln;

END testBase64.
