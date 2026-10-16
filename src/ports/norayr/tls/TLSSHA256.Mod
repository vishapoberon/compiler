MODULE TLSSHA256;
(* 32 bit words as LONGINT bit patterns, with the word operations of TLSBytes *)
IMPORT TLSBytes;

TYPE
  Digest* = ARRAY 32 OF CHAR;

CONST
  BlockLen = 64;

VAR
  K: ARRAY 64 OF LONGINT;
  IV: ARRAY 8 OF LONGINT;

PROCEDURE Add2(a, b: LONGINT): LONGINT;
BEGIN
  RETURN TLSBytes.Add32(a, b)
END Add2;

PROCEDURE Add4(a, b, c, d: LONGINT): LONGINT;
BEGIN
  RETURN TLSBytes.Add32(TLSBytes.Add32(a, b), TLSBytes.Add32(c, d))
END Add4;

PROCEDURE Add5(a, b, c, d, e: LONGINT): LONGINT;
BEGIN
  RETURN TLSBytes.Add32(Add4(a, b, c, d), e)
END Add5;

PROCEDURE And32(a, b: LONGINT): LONGINT;
BEGIN
  RETURN TLSBytes.And32(a, b)
END And32;

PROCEDURE Xor32(a, b: LONGINT): LONGINT;
BEGIN
  RETURN TLSBytes.Xor32(a, b)
END Xor32;

PROCEDURE Not32(a: LONGINT): LONGINT;
BEGIN
  RETURN TLSBytes.Not32(a)
END Not32;

PROCEDURE SHR32(x: LONGINT; n: INTEGER): LONGINT;
BEGIN
  RETURN TLSBytes.Shr32(x, n)
END SHR32;

PROCEDURE ROTR32(x: LONGINT; n: INTEGER): LONGINT;
BEGIN
  RETURN TLSBytes.Rotr32(x, n)
END ROTR32;

PROCEDURE Ch(x, y, z: LONGINT): LONGINT;
BEGIN
  RETURN Xor32(And32(x, y), And32(Not32(x), z))
END Ch;

PROCEDURE Maj(x, y, z: LONGINT): LONGINT;
BEGIN
  RETURN Xor32(Xor32(And32(x, y), And32(x, z)), And32(y, z))
END Maj;

PROCEDURE BigS0(x: LONGINT): LONGINT;
BEGIN
  RETURN Xor32(Xor32(ROTR32(x, 2), ROTR32(x, 13)), ROTR32(x, 22))
END BigS0;

PROCEDURE BigS1(x: LONGINT): LONGINT;
BEGIN
  RETURN Xor32(Xor32(ROTR32(x, 6), ROTR32(x, 11)), ROTR32(x, 25))
END BigS1;

PROCEDURE SmallS0(x: LONGINT): LONGINT;
BEGIN
  RETURN Xor32(Xor32(ROTR32(x, 7), ROTR32(x, 18)), SHR32(x, 3))
END SmallS0;

PROCEDURE SmallS1(x: LONGINT): LONGINT;
BEGIN
  RETURN Xor32(Xor32(ROTR32(x, 17), ROTR32(x, 19)), SHR32(x, 10))
END SmallS1;

PROCEDURE ProcessBlock(VAR block: ARRAY OF CHAR; VAR H: ARRAY OF LONGINT);
VAR
  W: ARRAY 64 OF LONGINT;
  a,b,c,d,e,f,g,h,t1,t2,v: LONGINT;
  i: INTEGER;
BEGIN
  i := 0;
  WHILE i < 16 DO  (* big endian words; the first byte 80H or more makes them negative *)
    v := LONG(ORD(block[4*i]));
    IF v >= 128 THEN v := v - 256 END;
    v := v * 256 + LONG(ORD(block[4*i+1]));
    v := v * 256 + LONG(ORD(block[4*i+2]));
    W[i] := v * 256 + LONG(ORD(block[4*i+3]));
    INC(i)
  END;
  WHILE i < 64 DO
    W[i] := Add4(SmallS1(W[i-2]), W[i-7], SmallS0(W[i-15]), W[i-16]);
    INC(i)
  END;

  a := H[0]; b := H[1]; c := H[2]; d := H[3]; e := H[4]; f := H[5]; g := H[6]; h := H[7];
  i := 0;
  WHILE i < 64 DO
    t1 := Add5(h, BigS1(e), Ch(e,f,g), K[i], W[i]);
    t2 := Add2(BigS0(a), Maj(a,b,c));
    h := g; g := f; f := e; e := Add2(d, t1);
    d := c; c := b; b := a; a := Add2(t1, t2);
    INC(i)
  END;
  H[0] := Add2(H[0], a); H[1] := Add2(H[1], b); H[2] := Add2(H[2], c); H[3] := Add2(H[3], d);
  H[4] := Add2(H[4], e); H[5] := Add2(H[5], f); H[6] := Add2(H[6], g); H[7] := Add2(H[7], h)
END ProcessBlock;

PROCEDURE DigestBuffer*(VAR msg: TLSBytes.Buffer; VAR out: Digest);
VAR
  H: ARRAY 8 OF LONGINT;
  block: ARRAY 64 OF CHAR;
  pos, i: LONGINT;
  rem: LONGINT;
  tmp: TLSBytes.Buffer;
BEGIN
  i := 0; WHILE i < 8 DO H[i] := IV[i]; INC(i) END;
  pos := 0;
  WHILE pos + 64 <= msg.len DO
    i := 0; WHILE i < 64 DO block[i] := msg.data[pos+i]; INC(i) END;
    ProcessBlock(block, H);
    pos := pos + 64
  END;

  TLSBytes.Init(tmp);
  i := pos; WHILE i < msg.len DO TLSBytes.AppendByte(tmp, ORD(msg.data[i])); INC(i) END;
  TLSBytes.AppendByte(tmp, 128);
  rem := tmp.len MOD 64;
  WHILE rem # 56 DO TLSBytes.AppendByte(tmp, 0); rem := tmp.len MOD 64 END;
  TLSBytes.PutBE64(tmp, 0, msg.len * 8);  (* msg.len <= TLSBytes.MaxLen *)

  pos := 0;
  WHILE pos < tmp.len DO
    i := 0; WHILE i < 64 DO block[i] := tmp.data[pos+i]; INC(i) END;
    ProcessBlock(block, H);
    pos := pos + 64
  END;

  tmp.len := 0;
  i := 0; WHILE i < 8 DO TLSBytes.PutBE32(tmp, H[i]); INC(i) END;
  i := 0; WHILE i < 32 DO out[i] := tmp.data[i]; INC(i) END
END DigestBuffer;

PROCEDURE DigestOpen*(VAR data: ARRAY OF CHAR; n: LONGINT; VAR out: Digest);
VAR b: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(b); TLSBytes.AppendOpen(b, data, n); DigestBuffer(b, out)
END DigestOpen;

PROCEDURE HMAC*(VAR key, msg: TLSBytes.Buffer; VAR out: Digest);
VAR
  k0, ipad, opad, inner, outer: TLSBytes.Buffer;
  kd, id: Digest;
  i: LONGINT;
BEGIN
  TLSBytes.Init(k0);
  IF key.len > 64 THEN
    DigestBuffer(key, kd);
    i := 0; WHILE i < 32 DO TLSBytes.AppendByte(k0, ORD(kd[i])); INC(i) END
  ELSE
    TLSBytes.Copy(key, k0)
  END;
  WHILE k0.len < 64 DO TLSBytes.AppendByte(k0, 0) END;

  TLSBytes.Init(ipad); TLSBytes.Init(opad);
  i := 0;
  WHILE i < 64 DO
    TLSBytes.AppendByte(ipad, Xor32(ORD(k0.data[i]), 54));
    TLSBytes.AppendByte(opad, Xor32(ORD(k0.data[i]), 92));
    INC(i)
  END;

  TLSBytes.Copy(ipad, inner); TLSBytes.Append(inner, msg); DigestBuffer(inner, id);
  TLSBytes.Copy(opad, outer);
  i := 0; WHILE i < 32 DO TLSBytes.AppendByte(outer, ORD(id[i])); INC(i) END;
  DigestBuffer(outer, out)
END HMAC;

PROCEDURE DigestToBuffer*(VAR d: Digest; VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(b); i := 0; WHILE i < 32 DO TLSBytes.AppendByte(b, ORD(d[i])); INC(i) END
END DigestToBuffer;

PROCEDURE InitConstants;
BEGIN
  IV[0] := 1779033703; IV[1] := -1150833019; IV[2] := 1013904242; IV[3] := -1521486534;
  IV[4] := 1359893119; IV[5] := -1694144372; IV[6] := 528734635; IV[7] := 1541459225;
  K[0] := 1116352408; K[1] := 1899447441; K[2] := -1245643825; K[3] := -373957723;
  K[4] := 961987163; K[5] := 1508970993; K[6] := -1841331548; K[7] := -1424204075;
  K[8] := -670586216; K[9] := 310598401; K[10] := 607225278; K[11] := 1426881987;
  K[12] := 1925078388; K[13] := -2132889090; K[14] := -1680079193; K[15] := -1046744716;
  K[16] := -459576895; K[17] := -272742522; K[18] := 264347078; K[19] := 604807628;
  K[20] := 770255983; K[21] := 1249150122; K[22] := 1555081692; K[23] := 1996064986;
  K[24] := -1740746414; K[25] := -1473132947; K[26] := -1341970488; K[27] := -1084653625;
  K[28] := -958395405; K[29] := -710438585; K[30] := 113926993; K[31] := 338241895;
  K[32] := 666307205; K[33] := 773529912; K[34] := 1294757372; K[35] := 1396182291;
  K[36] := 1695183700; K[37] := 1986661051; K[38] := -2117940946; K[39] := -1838011259;
  K[40] := -1564481375; K[41] := -1474664885; K[42] := -1035236496; K[43] := -949202525;
  K[44] := -778901479; K[45] := -694614492; K[46] := -200395387; K[47] := 275423344;
  K[48] := 430227734; K[49] := 506948616; K[50] := 659060556; K[51] := 883997877;
  K[52] := 958139571; K[53] := 1322822218; K[54] := 1537002063; K[55] := 1747873779;
  K[56] := 1955562222; K[57] := 2024104815; K[58] := -2067236844; K[59] := -1933114872;
  K[60] := -1866530822; K[61] := -1538233109; K[62] := -1090935817; K[63] := -965641998
END InitConstants;

BEGIN
  InitConstants
END TLSSHA256.
