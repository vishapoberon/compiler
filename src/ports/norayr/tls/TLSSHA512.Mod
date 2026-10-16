MODULE TLSSHA512;
(* SHA-512 and SHA-384 (FIPS 180-4) with 32 bit integers only: a 64 bit word is a pair of LONGINT,
   hi and lo (bit patterns); sums carry from lo to hi by an unsigned comparison (the sign bit
   flipped), shifts and rotations through SYSTEM.LSH on the halves. *)
IMPORT SYSTEM, TLSBytes;

CONST
  MinInt = -2147483647 - 1;

VAR
  KH, KL: ARRAY 80 OF LONGINT;
  IV512H, IV512L, IV384H, IV384L: ARRAY 8 OF LONGINT;

(* a < b as unsigned 32 bit numbers *)
PROCEDURE ULess(a, b: LONGINT): BOOLEAN;
BEGIN RETURN TLSBytes.Xor32(a, MinInt) < TLSBytes.Xor32(b, MinInt)
END ULess;

(* (h, l) := (h, l) + (bh, bl) modulo 2^64 *)
PROCEDURE Add(VAR h, l: LONGINT; bh, bl: LONGINT);
VAR lo: LONGINT;
BEGIN
  lo := TLSBytes.Add32(l, bl);
  h := TLSBytes.Add32(h, bh);
  IF ULess(lo, l) THEN h := TLSBytes.Add32(h, 1) END;
  l := lo
END Add;

(* (rh, rl) := (h, l) rotated right by n, 0 < n < 64 *)
PROCEDURE Rotr(h, l, n: LONGINT; VAR rh, rl: LONGINT);
VAR t: LONGINT;
BEGIN
  IF n >= 32 THEN t := h; h := l; l := t; DEC(n, 32) END;
  IF n = 0 THEN rh := h; rl := l
  ELSE
    rh := TLSBytes.Or32(SYSTEM.LSH(h, -n), SYSTEM.LSH(l, 32 - n));
    rl := TLSBytes.Or32(SYSTEM.LSH(l, -n), SYSTEM.LSH(h, 32 - n))
  END
END Rotr;

(* (rh, rl) := (h, l) shifted right by n, 0 < n < 32 *)
PROCEDURE Shr(h, l, n: LONGINT; VAR rh, rl: LONGINT);
BEGIN
  rh := SYSTEM.LSH(h, -n);
  rl := TLSBytes.Or32(SYSTEM.LSH(l, -n), SYSTEM.LSH(h, 32 - n))
END Shr;

(* x rotated by a, b and c (c a shift if shift), xored *)
PROCEDURE Sigma(h, l, a, b, c: LONGINT; shift: BOOLEAN; VAR rh, rl: LONGINT);
VAR ah, al, bh, bl, ch, cl: LONGINT;
BEGIN
  Rotr(h, l, a, ah, al); Rotr(h, l, b, bh, bl);
  IF shift THEN Shr(h, l, c, ch, cl) ELSE Rotr(h, l, c, ch, cl) END;
  rh := TLSBytes.Xor32(TLSBytes.Xor32(ah, bh), ch);
  rl := TLSBytes.Xor32(TLSBytes.Xor32(al, bl), cl)
END Sigma;

PROCEDURE Get32(VAR b: ARRAY OF CHAR; i: LONGINT): LONGINT;
VAR v: LONGINT;
BEGIN
  v := LONG(ORD(b[i])); IF v >= 128 THEN v := v - 256 END;
  v := v * 256 + LONG(ORD(b[i+1])); v := v * 256 + LONG(ORD(b[i+2]));
  RETURN v * 256 + LONG(ORD(b[i+3]))
END Get32;

PROCEDURE Block(VAR block: ARRAY OF CHAR; VAR HH, HL: ARRAY OF LONGINT);
VAR
  WH, WL: ARRAY 80 OF LONGINT;
  ah, al, bh, bl, ch, cl, dh, dl, eh, el, fh, fl, gh, gl, hh, hl: LONGINT;
  t1h, t1l, t2h, t2l, sh, sl, xh, xl: LONGINT;
  i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 16 DO WH[i] := Get32(block, 8*i); WL[i] := Get32(block, 8*i + 4); INC(i) END;
  WHILE i < 80 DO
    Sigma(WH[i-2], WL[i-2], 19, 61, 6, TRUE, sh, sl);
    Sigma(WH[i-15], WL[i-15], 1, 8, 7, TRUE, xh, xl);
    Add(sh, sl, WH[i-7], WL[i-7]); Add(sh, sl, xh, xl); Add(sh, sl, WH[i-16], WL[i-16]);
    WH[i] := sh; WL[i] := sl; INC(i)
  END;
  ah := HH[0]; al := HL[0]; bh := HH[1]; bl := HL[1]; ch := HH[2]; cl := HL[2]; dh := HH[3]; dl := HL[3];
  eh := HH[4]; el := HL[4]; fh := HH[5]; fl := HL[5]; gh := HH[6]; gl := HL[6]; hh := HH[7]; hl := HL[7];
  i := 0;
  WHILE i < 80 DO
    (* t1 := h + S1(e) + Ch(e, f, g) + K[i] + W[i] *)
    Sigma(eh, el, 14, 18, 41, FALSE, sh, sl);
    t1h := hh; t1l := hl; Add(t1h, t1l, sh, sl);
    xh := TLSBytes.Xor32(TLSBytes.And32(eh, fh), TLSBytes.And32(TLSBytes.Not32(eh), gh));
    xl := TLSBytes.Xor32(TLSBytes.And32(el, fl), TLSBytes.And32(TLSBytes.Not32(el), gl));
    Add(t1h, t1l, xh, xl); Add(t1h, t1l, KH[i], KL[i]); Add(t1h, t1l, WH[i], WL[i]);
    (* t2 := S0(a) + Maj(a, b, c) *)
    Sigma(ah, al, 28, 34, 39, FALSE, t2h, t2l);
    xh := TLSBytes.Xor32(TLSBytes.Xor32(TLSBytes.And32(ah, bh), TLSBytes.And32(ah, ch)), TLSBytes.And32(bh, ch));
    xl := TLSBytes.Xor32(TLSBytes.Xor32(TLSBytes.And32(al, bl), TLSBytes.And32(al, cl)), TLSBytes.And32(bl, cl));
    Add(t2h, t2l, xh, xl);
    hh := gh; hl := gl; gh := fh; gl := fl; fh := eh; fl := el;
    eh := dh; el := dl; Add(eh, el, t1h, t1l);
    dh := ch; dl := cl; ch := bh; cl := bl; bh := ah; bl := al;
    ah := t1h; al := t1l; Add(ah, al, t2h, t2l);
    INC(i)
  END;
  Add(HH[0], HL[0], ah, al); Add(HH[1], HL[1], bh, bl); Add(HH[2], HL[2], ch, cl); Add(HH[3], HL[3], dh, dl);
  Add(HH[4], HL[4], eh, el); Add(HH[5], HL[5], fh, fl); Add(HH[6], HL[6], gh, gl); Add(HH[7], HL[7], hh, hl)
END Block;

(* the hash of msg from the initial value (IH, IL), words 0..words-1 of the result in out *)
PROCEDURE Hash(VAR msg: TLSBytes.Buffer; VAR IH, IL: ARRAY OF LONGINT; words: LONGINT; VAR out: TLSBytes.Buffer);
VAR HH, HL: ARRAY 8 OF LONGINT; block: ARRAY 128 OF CHAR; pos, i, n: LONGINT; tmp: TLSBytes.Buffer;
BEGIN
  i := 0; WHILE i < 8 DO HH[i] := IH[i]; HL[i] := IL[i]; INC(i) END;
  pos := 0;
  WHILE pos + 128 <= msg.len DO
    i := 0; WHILE i < 128 DO block[i] := msg.data[pos + i]; INC(i) END;
    Block(block, HH, HL); INC(pos, 128)
  END;
  TLSBytes.Init(tmp);
  i := pos; WHILE i < msg.len DO TLSBytes.AppendByte(tmp, ORD(msg.data[i])); INC(i) END;
  TLSBytes.AppendByte(tmp, 128);
  WHILE tmp.len MOD 128 # 112 DO TLSBytes.AppendByte(tmp, 0) END;
  TLSBytes.PutBE64(tmp, 0, 0); TLSBytes.PutBE64(tmp, 0, msg.len * 8);  (* msg.len <= TLSBytes.MaxLen *)
  pos := 0;
  WHILE pos < tmp.len DO
    i := 0; WHILE i < 128 DO block[i] := tmp.data[pos + i]; INC(i) END;
    Block(block, HH, HL); INC(pos, 128)
  END;
  TLSBytes.Init(out); n := 0;
  WHILE n < words DO TLSBytes.PutBE32(out, HH[n]); TLSBytes.PutBE32(out, HL[n]); INC(n) END
END Hash;

(** out := SHA-512(msg), 64 bytes *)
PROCEDURE Digest512*(VAR msg, out: TLSBytes.Buffer);
BEGIN Hash(msg, IV512H, IV512L, 8, out)
END Digest512;

(** out := SHA-384(msg), 48 bytes *)
PROCEDURE Digest384*(VAR msg, out: TLSBytes.Buffer);
BEGIN Hash(msg, IV384H, IV384L, 6, out)
END Digest384;

PROCEDURE InitConstants;
BEGIN
  KH[0] := 1116352408; KL[0] := -685199838; KH[1] := 1899447441; KL[1] := 602891725;
  KH[2] := -1245643825; KL[2] := -330482897; KH[3] := -373957723; KL[3] := -2121671748;
  KH[4] := 961987163; KL[4] := -213338824; KH[5] := 1508970993; KL[5] := -1241133031;
  KH[6] := -1841331548; KL[6] := -1357295717; KH[7] := -1424204075; KL[7] := -630357736;
  KH[8] := -670586216; KL[8] := -1560083902; KH[9] := 310598401; KL[9] := 1164996542;
  KH[10] := 607225278; KL[10] := 1323610764; KH[11] := 1426881987; KL[11] := -704662302;
  KH[12] := 1925078388; KL[12] := -226784913; KH[13] := -2132889090; KL[13] := 991336113;
  KH[14] := -1680079193; KL[14] := 633803317; KH[15] := -1046744716; KL[15] := -815192428;
  KH[16] := -459576895; KL[16] := -1628353838; KH[17] := -272742522; KL[17] := 944711139;
  KH[18] := 264347078; KL[18] := -1953704523; KH[19] := 604807628; KL[19] := 2007800933;
  KH[20] := 770255983; KL[20] := 1495990901; KH[21] := 1249150122; KL[21] := 1856431235;
  KH[22] := 1555081692; KL[22] := -1119749164; KH[23] := 1996064986; KL[23] := -2096016459;
  KH[24] := -1740746414; KL[24] := -295247957; KH[25] := -1473132947; KL[25] := 766784016;
  KH[26] := -1341970488; KL[26] := -1728372417; KH[27] := -1084653625; KL[27] := -1091629340;
  KH[28] := -958395405; KL[28] := 1034457026; KH[29] := -710438585; KL[29] := -1828018395;
  KH[30] := 113926993; KL[30] := -536640913; KH[31] := 338241895; KL[31] := 168717936;
  KH[32] := 666307205; KL[32] := 1188179964; KH[33] := 773529912; KL[33] := 1546045734;
  KH[34] := 1294757372; KL[34] := 1522805485; KH[35] := 1396182291; KL[35] := -1651133473;
  KH[36] := 1695183700; KL[36] := -1951439906; KH[37] := 1986661051; KL[37] := 1014477480;
  KH[38] := -2117940946; KL[38] := 1206759142; KH[39] := -1838011259; KL[39] := 344077627;
  KH[40] := -1564481375; KL[40] := 1290863460; KH[41] := -1474664885; KL[41] := -1136513023;
  KH[42] := -1035236496; KL[42] := -789014639; KH[43] := -949202525; KL[43] := 106217008;
  KH[44] := -778901479; KL[44] := -688958952; KH[45] := -694614492; KL[45] := 1432725776;
  KH[46] := -200395387; KL[46] := 1467031594; KH[47] := 275423344; KL[47] := 851169720;
  KH[48] := 430227734; KL[48] := -1194143544; KH[49] := 506948616; KL[49] := 1363258195;
  KH[50] := 659060556; KL[50] := -544281703; KH[51] := 883997877; KL[51] := -509917016;
  KH[52] := 958139571; KL[52] := -976659869; KH[53] := 1322822218; KL[53] := -482243893;
  KH[54] := 1537002063; KL[54] := 2003034995; KH[55] := 1747873779; KL[55] := -692930397;
  KH[56] := 1955562222; KL[56] := 1575990012; KH[57] := 2024104815; KL[57] := 1125592928;
  KH[58] := -2067236844; KL[58] := -1578062990; KH[59] := -1933114872; KL[59] := 442776044;
  KH[60] := -1866530822; KL[60] := 593698344; KH[61] := -1538233109; KL[61] := -561857047;
  KH[62] := -1090935817; KL[62] := -1295615723; KH[63] := -965641998; KL[63] := -479046869;
  KH[64] := -903397682; KL[64] := -366583396; KH[65] := -779700025; KL[65] := 566280711;
  KH[66] := -354779690; KL[66] := -840897762; KH[67] := -176337025; KL[67] := -294727304;
  KH[68] := 116418474; KL[68] := 1914138554; KH[69] := 174292421; KL[69] := -1563912026;
  KH[70] := 289380356; KL[70] := -1090974290; KH[71] := 460393269; KL[71] := 320620315;
  KH[72] := 685471733; KL[72] := 587496836; KH[73] := 852142971; KL[73] := 1086792851;
  KH[74] := 1017036298; KL[74] := 365543100; KH[75] := 1126000580; KL[75] := -1676669620;
  KH[76] := 1288033470; KL[76] := -885112138; KH[77] := 1501505948; KL[77] := -60457430;
  KH[78] := 1607167915; KL[78] := 987167468; KH[79] := 1816402316; KL[79] := 1246189591;

  IV512H[0] := 1779033703; IV512L[0] := -205731576; IV512H[1] := -1150833019; IV512L[1] := -2067093701;
  IV512H[2] := 1013904242; IV512L[2] := -23791573; IV512H[3] := -1521486534; IV512L[3] := 1595750129;
  IV512H[4] := 1359893119; IV512L[4] := -1377402159; IV512H[5] := -1694144372; IV512L[5] := 725511199;
  IV512H[6] := 528734635; IV512L[6] := -79577749; IV512H[7] := 1541459225; IV512L[7] := 327033209;

  IV384H[0] := -876896931; IV384L[0] := -1056596264; IV384H[1] := 1654270250; IV384L[1] := 914150663;
  IV384H[2] := -1856437926; IV384L[2] := 812702999; IV384H[3] := 355462360; IV384L[3] := -150054599;
  IV384H[4] := 1731405415; IV384L[4] := -4191439; IV384H[5] := -1900787065; IV384L[5] := 1750603025;
  IV384H[6] := -619958771; IV384L[6] := 1694076839; IV384H[7] := 1203062813; IV384L[7] := -1090891868;
END InitConstants;

BEGIN
  InitConstants
END TLSSHA512.
