MODULE TLSTestIP;  (* IP addresses as host names: TLSX509Names.ParseIP (IPv4, IPv6 with "::" and an
  IPv4 tail, malformed ones refused) and iPAddress entries of subjectAltName *)

IMPORT TLSBytes, TLSX509Names, Out;

VAR
  fails, checks: LONGINT;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.Ln END
END Check;

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("a") + 10 END
END Hex;

PROCEDURE Bytes(x: ARRAY OF CHAR; VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(b); i := 0;
  WHILE (i < LEN(x) - 1) & (x[i] # 0X) DO TLSBytes.AppendByte(b, Hex(x[i]) * 16 + Hex(x[i+1])); INC(i, 2) END
END Bytes;

PROCEDURE Good(s, want: ARRAY OF CHAR);
VAR a, w: TLSBytes.Buffer;
BEGIN
  Bytes(want, w);
  Check(s, TLSX509Names.ParseIP(s, a) & TLSBytes.EqualConstTime(a, w))
END Good;

PROCEDURE Bad(s: ARRAY OF CHAR);
VAR a: TLSBytes.Buffer;
BEGIN
  Check(s, ~TLSX509Names.ParseIP(s, a))
END Bad;

(* a GeneralName: tag, the value bytes *)
PROCEDURE Name(VAR san: TLSBytes.Buffer; tag: LONGINT; VAR v: TLSBytes.Buffer);
BEGIN
  TLSBytes.AppendByte(san, tag); TLSBytes.AppendByte(san, v.len); TLSBytes.Append(san, v)
END Name;

PROCEDURE Text(s: ARRAY OF CHAR; VAR b: TLSBytes.Buffer);
BEGIN TLSBytes.Init(b); TLSBytes.AppendString(b, s)
END Text;

PROCEDURE Run;
VAR names, san, v: TLSBytes.Buffer; dns: BOOLEAN;
BEGIN
  Good("1.2.3.4", "01020304"); Good("0.0.0.0", "00000000"); Good("255.255.255.255", "ffffffff");
  Good("::1", "00000000000000000000000000000001"); Good("::", "00000000000000000000000000000000");
  Good("2001:db8::1", "20010db8000000000000000000000001"); Good("1::", "00010000000000000000000000000000");
  Good("fe80::1:2", "fe800000000000000000000000010002"); Good("1:2:3:4:5:6:7:8", "00010002000300040005000600070008");
  Good("::ffff:192.0.2.1", "00000000000000000000ffffc0000201"); Good("1:2:3:4:5:6:1.2.3.4", "00010002000300040005000601020304");
  Good("ABCD::Ef", "abcd00000000000000000000000000ef");
  Bad(""); Bad("1.2.3"); Bad("1.2.3.4.5"); Bad("256.1.1.1"); Bad("01.2.3.4"); Bad("1..2.3"); Bad("1.2.3.4.");
  Bad("example.com"); Bad(":::"); Bad("1:2:3:4:5:6:7:8:9"); Bad("1::2::3"); Bad("12345::"); Bad("1:2:3:4:5:6:7::8");
  Bad(":1:2"); Bad("1:"); Bad("g::1"); Bad("::1.2.3"); Bad("1.2.3.4::"); Bad("1:2:3:4:5:6:7:1.2.3.4");
  (* subjectAltName { dNSName www.example.test, dNSName 10.0.0.1, iPAddress 127.0.0.1, iPAddress ::1 } *)
  TLSBytes.Init(names);
  Text("www.example.test", v); Name(names, TLSX509Names.DNSNameTag, v);
  Text("10.0.0.1", v); Name(names, TLSX509Names.DNSNameTag, v);
  Bytes("7f000001", v); Name(names, TLSX509Names.IPAddressTag, v);
  Bytes("00000000000000000000000000000001", v); Name(names, TLSX509Names.IPAddressTag, v);
  TLSBytes.Init(san); TLSBytes.AppendByte(san, 30H); TLSBytes.AppendByte(san, names.len); TLSBytes.Append(san, names);
  Check("127.0.0.1", TLSX509Names.SubjectAltNameMatches(san, "127.0.0.1", dns));
  Check("::1", TLSX509Names.SubjectAltNameMatches(san, "::1", dns));
  Check("0:0:0:0:0:0:0:1", TLSX509Names.SubjectAltNameMatches(san, "0:0:0:0:0:0:0:1", dns));
  Check("127.0.0.2 not", ~TLSX509Names.SubjectAltNameMatches(san, "127.0.0.2", dns));
  Check("10.0.0.1 only as a dNSName: not", ~TLSX509Names.SubjectAltNameMatches(san, "10.0.0.1", dns));
  Check("www.example.test", TLSX509Names.SubjectAltNameMatches(san, "www.example.test", dns) & dns);
  Check("www.example.test.", TLSX509Names.SubjectAltNameMatches(san, "www.example.test.", dns));
  Check("WWW.Example.TEST", TLSX509Names.SubjectAltNameMatches(san, "WWW.Example.TEST", dns));
  Check("other.example.test not", ~TLSX509Names.SubjectAltNameMatches(san, "other.example.test", dns));
  Out.String("TLSTestIP: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END Run;

BEGIN
  fails := 0; checks := 0; Run
END TLSTestIP.
