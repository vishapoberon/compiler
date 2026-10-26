MODULE TestAgenaNames;
IMPORT agena, Out;
VAR input, output: ARRAY 1100 OF CHAR; small: ARRAY 4 OF CHAR; i: LONGINT;

PROCEDURE Check(text, expected: ARRAY OF CHAR);
BEGIN
  COPY(text, input); agena.ToASCII(input, output); ASSERT(output = expected)
END Check;

BEGIN
  Check("norayr.am", "norayr.am"); Check("Norayr.AM", "norayr.am");
  Check("սոնա.հայ", "xn--y9a5bft.xn--y9a3aq");
  Check("ՍՈՆԱ.ՀԱՅ", "xn--y9a5bft.xn--y9a3aq");
  Check("փետուր.նակագին.հայ", "xn--29a2bufjc.xn--y9aag6ar4bf.xn--y9a3aq");
  Check("bücher.example", "xn--bcher-kva.example"); Check("日本語.jp", "xn--wgv71a119e.jp");
  Check("ծոց.հայ", "xn--cbbu1a.xn--y9a3aq");
  Check("é.example", "xn--9ca.example"); Check("faß.de", "xn--fa-hia.de");
  Check("xn--cbbu1a.xn--y9a3aq", "xn--cbbu1a.xn--y9a3aq");
  Check("", ""); Check("a..b", ""); Check("a.example.", "");
  Check("xn--abc", ""); Check("a＠b.example", ""); Check("אa.example", "");
  Check("a‍b.example", ""); Check("123.א", "");
  input[0] := 0C0X; input[1] := 80X; input[2] := 0X;
  agena.ToASCII(input, output); ASSERT(output[0] = 0X);
  FOR i := 0 TO 63 DO input[i] := "a" END; input[64] := 0X;
  agena.ToASCII(input, output); ASSERT(output[0] = 0X);
  input := "localhost"; agena.ToASCII(input, small); ASSERT(small[0] = 0X);
  agena.ToASCII(input, input); ASSERT(input = "localhost");
  Out.String("Agena checked domain-name API passed"); Out.Ln
END TestAgenaNames.
