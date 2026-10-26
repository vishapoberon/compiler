MODULE TestIDNA;
IMPORT IDNA, Out;
VAR checks: LONGINT;

PROCEDURE Check(input, unicode, ascii: ARRAY OF CHAR);
  VAR u, a: IDNA.String; result: LONGINT;
BEGIN
  IDNA.Names(input, u, a, result);
  IF (result # 0) OR (u = NIL) OR (a = NIL) THEN Out.String("IDNA conversion failed: "); Out.String(input); Out.Ln
  ELSIF (u^ # unicode) OR (a^ # ascii) THEN Out.String("IDNA name differs: "); Out.String(input); Out.Ln
  END;
  ASSERT((result = 0) & (u # NIL) & (a # NIL)); ASSERT((u^ = unicode) & (a^ = ascii)); INC(checks)
END Check;

PROCEDURE Reject(input: ARRAY OF CHAR);
  VAR u, a: IDNA.String; result: LONGINT;
BEGIN
  IDNA.Names(input, u, a, result);
  IF (result = 0) OR (u # NIL) OR (a # NIL) THEN Out.String("IDNA accepted invalid name: "); Out.String(input); Out.Ln END;
  ASSERT((result # 0) & (u = NIL) & (a = NIL)); INC(checks)
END Reject;

PROCEDURE Cases;
  VAR text: ARRAY 1100 OF CHAR; unterminated: ARRAY 3 OF CHAR; i: LONGINT;
BEGIN
  Check("example.org", "example.org", "example.org");
  Check("EXAMPLE.org", "example.org", "example.org");
  Check("ծոց.հայ", "ծոց.հայ", "xn--cbbu1a.xn--y9a3aq");
  Check("ԾՈՑ.ՀԱՅ", "ծոց.հայ", "xn--cbbu1a.xn--y9a3aq");
  Check("xn--cbbu1a.xn--y9a3aq", "ծոց.հայ", "xn--cbbu1a.xn--y9a3aq");
  Check("faß.de", "faß.de", "xn--fa-hia.de");
  Check("é.example", "é.example", "xn--9ca.example");
  Check("例子.测试", "例子.测试", "xn--fsqu00a.xn--0zwm56d");
  Check("XN--CBBU1A.XN--Y9A3AQ", "ծոց.հայ", "xn--cbbu1a.xn--y9a3aq");
  Check("ｅｘａｍｐｌｅ。org", "example.org", "example.org");
  Reject(""); Reject("example.org."); Reject("a..b"); Reject("-a.example"); Reject("a-.example");
  Reject("a_b.example"); Reject("user@example.org"); Reject("example.org:5222"); Reject("a/b");
  Reject("xn--"); Reject("xn--abc.example"); Reject("😀.example"); Reject("́a.example"); Reject("אa.example");
  Reject("a‍b.example"); Reject("a‌b.example"); Reject("a b.example"); Reject("a\b.example");
  Reject("a%00b.example"); Reject("a＠b.example"); Reject("a／b.example"); Reject("a：b.example");
  text[0] := 0C0X; text[1] := 80X; text[2] := 0X; Reject(text);
  text[0] := 0EDX; text[1] := 0A0X; text[2] := 80X; text[3] := 0X; Reject(text);
  text[0] := 0F0X; text[1] := 0X; Reject(text);
  FOR i := 0 TO LEN(unterminated)-1 DO unterminated[i] := "a" END; Reject(unterminated);
  FOR i := 0 TO 63 DO text[i] := "a" END; text[64] := 0X; Reject(text);
  FOR i := 0 TO LEN(text)-2 DO text[i] := "a" END; text[LEN(text)-1] := 0X; Reject(text)
END Cases;

BEGIN checks := 0; Cases; Out.String("IDNA UTF-8 name checks passed: "); Out.Int(checks, 0); Out.Ln
END TestIDNA.
