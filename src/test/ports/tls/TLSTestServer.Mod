MODULE TLSTestServer;  (* the private keys of a server: a P-256 key as SEC 1 and as PKCS #8 DER gives the
  same scalar, whose public point is the one in the key; a P-384 key and broken DER are refused *)

IMPORT TLSBytes, TLSIdentity, Out;

VAR
  fails, checks: LONGINT;
  id: TLSIdentity.IdentityDesc;

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("a") + 10 END
END Hex;

PROCEDURE Add(VAR b: TLSBytes.Buffer; x: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(x) - 1) & (x[i] # 0X) DO TLSBytes.AppendByte(b, Hex(x[i]) * 16 + Hex(x[i+1])); INC(i, 2) END
END Add;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" (case "); Out.Int(checks, 0); Out.String(")"); Out.Ln END
END Check;

PROCEDURE Equal(VAR a, b: TLSBytes.Buffer): BOOLEAN;
VAR i: LONGINT;
BEGIN
  IF a.len # b.len THEN RETURN FALSE END;
  i := 0; WHILE (i < a.len) & (a.data[i] = b.data[i]) DO INC(i) END;
  RETURN i = a.len
END Equal;

PROCEDURE Key(VAR der: TLSBytes.Buffer): BOOLEAN;
BEGIN RETURN TLSIdentity.ParseKey(der, id)
END Key;

PROCEDURE Run*;
VAR der, pub, point: TLSBytes.Buffer;
BEGIN
  fails := 0; checks := 0;
  TLSBytes.Init(der);
  Add(der, "30770201010420d7876596fcbd9e05f262102ceb9ea33f0361aa2bdb1dafc111");
  Add(der, "89d068860ced38a00a06082a8648ce3d030107a14403420004d9e95c4736396b");
  Add(der, "3d6bf1d1d9ccab028d5c00aecf2ef19724ecf58a3966169e05455cd9a10ecf93");
  Add(der, "7d196aa376873a7c48dda642db244b06ccbaf1d66c538b3100");
  TLSBytes.Slice(der, der.len - 65, 65, point);
  Check("SEC 1", Key(der) & (id.kind = TLSIdentity.EC));
  Check("public point", TLSIdentity.PublicKey(id, pub) & Equal(pub, point));
  der.data[50] := 1X;  (* the curve OID changed *)
  Check("SEC 1 wrong curve", ~Key(der));
  TLSBytes.Init(der);
  Add(der, "308187020100301306072a8648ce3d020106082a8648ce3d030107046d306b02");
  Add(der, "01010420d7876596fcbd9e05f262102ceb9ea33f0361aa2bdb1dafc11189d068");
  Add(der, "860ced38a14403420004d9e95c4736396b3d6bf1d1d9ccab028d5c00aecf2ef1");
  Add(der, "9724ecf58a3966169e05455cd9a10ecf937d196aa376873a7c48dda642db244b");
  Add(der, "06ccbaf1d66c538b3100");
  Check("PKCS 8", Key(der) & TLSIdentity.PublicKey(id, pub) & Equal(pub, point));
  der.len := der.len - 20;
  Check("PKCS 8 cut", ~Key(der));
  TLSBytes.Init(der);
  Add(der, "3081a4020101043070155d9f776af6a2bb317a94a476066dfc7616c557274401");
  Add(der, "715d58345a341a8f0f703df279452bb6da24029bcd1e4181a00706052b810400");
  Add(der, "22a16403620004714f70a52acfb3cab4ac3f210afc5ff20f5e5301d160c518c9");
  Add(der, "9e1b216ea4df842b35704a22dd79f2fe8417e037ce0a0f1fd9fc26e6d5028c16");
  Add(der, "7eab428da11ad7d86fd94457054c48d9fd3b973740828a69f7b7d68baa60733d");
  Add(der, "d539efec6ed761");
  Check("P-384", ~Key(der));
  Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END Run;

BEGIN
  Run
END TLSTestServer.
