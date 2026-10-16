MODULE TLSAESGCM;
IMPORT TLSBytes;

CONST
  BlockLen = 16;
  KeyLen = 16;
  RoundKeyLen = 176;
  TagLen* = 16;

TYPE
  Block = ARRAY 16 OF CHAR;
  RoundKeys = ARRAY 176 OF CHAR;

VAR
  SBox: ARRAY 256 OF CHAR;
  RCon: ARRAY 10 OF CHAR;

PROCEDURE XorC(a, b: CHAR): CHAR;
BEGIN
  RETURN CHR(TLSBytes.XorByte(ORD(a), ORD(b)))
END XorC;

PROCEDURE Byte(x: LONGINT): CHAR;
BEGIN
  RETURN TLSBytes.Byte(x)
END Byte;

PROCEDURE RotWord(VAR t: ARRAY OF CHAR);
VAR x: CHAR;
BEGIN
  x := t[0]; t[0] := t[1]; t[1] := t[2]; t[2] := t[3]; t[3] := x
END RotWord;

PROCEDURE SubWord(VAR t: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 4 DO t[i] := SBox[ORD(t[i])]; INC(i) END
END SubWord;

PROCEDURE ExpandKey(VAR key: TLSBytes.Buffer; VAR rk: RoundKeys);
VAR i, bytesGenerated, rci: LONGINT; temp: ARRAY 4 OF CHAR;
BEGIN
  IF key.len # 16 THEN HALT(60) END;
  i := 0;
  WHILE i < 16 DO rk[i] := key.data[i]; INC(i) END;
  bytesGenerated := 16; rci := 0;
  WHILE bytesGenerated < RoundKeyLen DO
    i := 0;
    WHILE i < 4 DO temp[i] := rk[bytesGenerated - 4 + i]; INC(i) END;
    IF bytesGenerated MOD 16 = 0 THEN
      RotWord(temp); SubWord(temp); temp[0] := XorC(temp[0], RCon[rci]); INC(rci)
    END;
    i := 0;
    WHILE i < 4 DO
      rk[bytesGenerated] := XorC(rk[bytesGenerated - 16], temp[i]);
      INC(bytesGenerated); INC(i)
    END
  END
END ExpandKey;

PROCEDURE AddRoundKey(VAR state: Block; VAR rk: RoundKeys; round: LONGINT);
VAR i, off: LONGINT;
BEGIN
  off := round * 16; i := 0;
  WHILE i < 16 DO state[i] := XorC(state[i], rk[off+i]); INC(i) END
END AddRoundKey;

PROCEDURE SubBytes(VAR state: Block);
VAR i: LONGINT;
BEGIN
  i := 0; WHILE i < 16 DO state[i] := SBox[ORD(state[i])]; INC(i) END
END SubBytes;

PROCEDURE ShiftRows(VAR s: Block);
VAR t: Block;
BEGIN
  t[0] := s[0];   t[4] := s[4];   t[8]  := s[8];   t[12] := s[12];
  t[1] := s[5];   t[5] := s[9];   t[9]  := s[13];  t[13] := s[1];
  t[2] := s[10];  t[6] := s[14];  t[10] := s[2];   t[14] := s[6];
  t[3] := s[15];  t[7] := s[3];   t[11] := s[7];   t[15] := s[11];
  s := t
END ShiftRows;

PROCEDURE XT(x: CHAR): CHAR;
VAR v: LONGINT;
BEGIN
  v := ORD(x);
  IF v < 128 THEN RETURN Byte(v * 2)
  ELSE RETURN XorC(Byte((v * 2) MOD 256), Byte(27))
  END
END XT;

PROCEDURE M2(x: CHAR): CHAR;
BEGIN
  RETURN XT(x)
END M2;

PROCEDURE M3(x: CHAR): CHAR;
BEGIN
  RETURN XorC(XT(x), x)
END M3;

PROCEDURE MixColumns(VAR s: Block);
VAR c, i: LONGINT; a0, a1, a2, a3: CHAR;
BEGIN
  c := 0;
  WHILE c < 4 DO
    i := c * 4;
    a0 := s[i]; a1 := s[i+1]; a2 := s[i+2]; a3 := s[i+3];
    s[i]   := XorC(XorC(XorC(M2(a0), M3(a1)), a2), a3);
    s[i+1] := XorC(XorC(XorC(a0, M2(a1)), M3(a2)), a3);
    s[i+2] := XorC(XorC(XorC(a0, a1), M2(a2)), M3(a3));
    s[i+3] := XorC(XorC(XorC(M3(a0), a1), a2), M2(a3));
    INC(c)
  END
END MixColumns;

PROCEDURE AES128EncryptBlock*(VAR key: TLSBytes.Buffer; VAR input: ARRAY OF CHAR; VAR dst: ARRAY OF CHAR);
VAR rk: RoundKeys; state: Block; round, i: LONGINT;
BEGIN
  ExpandKey(key, rk);
  i := 0; WHILE i < 16 DO state[i] := input[i]; INC(i) END;
  AddRoundKey(state, rk, 0);
  round := 1;
  WHILE round < 10 DO
    SubBytes(state); ShiftRows(state); MixColumns(state); AddRoundKey(state, rk, round);
    INC(round)
  END;
  SubBytes(state); ShiftRows(state); AddRoundKey(state, rk, 10);
  i := 0; WHILE i < 16 DO dst[i] := state[i]; INC(i) END
END AES128EncryptBlock;

PROCEDURE AES128EncryptBlockBuffer*(VAR key, plain, cipher: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  IF plain.len # 16 THEN HALT(61) END;
  cipher.len := 16;
  AES128EncryptBlock(key, plain.data, cipher.data)
END AES128EncryptBlockBuffer;

PROCEDURE Inc32(VAR b: Block);
VAR i, v: LONGINT; carry: BOOLEAN;
BEGIN
  i := 15; carry := TRUE;
  WHILE (i >= 12) & carry DO
    v := ORD(b[i]) + 1;
    IF v = 256 THEN b[i] := 0X; carry := TRUE ELSE b[i] := CHR(v); carry := FALSE END;
    DEC(i)
  END
END Inc32;

PROCEDURE MakeCounterBlock(VAR nonce: TLSBytes.Buffer; counter: LONGINT; VAR b: Block);
VAR i: LONGINT;
BEGIN
  IF nonce.len # 12 THEN HALT(62) END;
  i := 0; WHILE i < 12 DO b[i] := nonce.data[i]; INC(i) END;
  b[12] := TLSBytes.Byte(counter DIV 16777216);
  b[13] := TLSBytes.Byte(counter DIV 65536);
  b[14] := TLSBytes.Byte(counter DIV 256);
  b[15] := TLSBytes.Byte(counter)
END MakeCounterBlock;

PROCEDURE AES128CTR*(VAR key, msg, nonce: TLSBytes.Buffer; counterStart: LONGINT; VAR dst: TLSBytes.Buffer);
VAR pos, i, n: LONGINT; cb, stream: Block;
BEGIN
  TLSBytes.Init(dst);
  MakeCounterBlock(nonce, counterStart, cb);
  pos := 0;
  WHILE pos < msg.len DO
    AES128EncryptBlock(key, cb, stream);
    n := msg.len - pos; IF n > 16 THEN n := 16 END;
    i := 0;
    WHILE i < n DO TLSBytes.AppendChar(dst, XorC(msg.data[pos+i], stream[i])); INC(i) END;
    pos := pos + n; Inc32(cb)
  END
END AES128CTR;

PROCEDURE XorBlock(VAR a, b: Block);
VAR i: LONGINT;
BEGIN
  i := 0; WHILE i < 16 DO a[i] := XorC(a[i], b[i]); INC(i) END
END XorBlock;

PROCEDURE ClearBlock(VAR b: Block);
VAR i: LONGINT;
BEGIN
  i := 0; WHILE i < 16 DO b[i] := 0X; INC(i) END
END ClearBlock;

PROCEDURE ShiftRightBlock(VAR v: Block);
VAR i, cur, carry, nextCarry: LONGINT;
BEGIN
  carry := 0; i := 0;
  WHILE i < 16 DO
    cur := ORD(v[i]);
    nextCarry := cur MOD 2;
    v[i] := CHR((cur DIV 2) + carry * 128);
    carry := nextCarry;
    INC(i)
  END
END ShiftRightBlock;

PROCEDURE GFMult(VAR x, y, z: Block);
VAR v: Block; i, j: LONGINT; lsb: BOOLEAN;
BEGIN
  ClearBlock(z);
  i := 0; WHILE i < 16 DO v[i] := y[i]; INC(i) END;
  i := 0;
  WHILE i < 16 DO
    j := 7;
    WHILE j >= 0 DO
      IF ((ORD(x[i]) DIV ASH(1, j)) MOD 2) # 0 THEN XorBlock(z, v) END;
      lsb := (ORD(v[15]) MOD 2) # 0;
      ShiftRightBlock(v);
      IF lsb THEN v[0] := XorC(v[0], 0E1X) END;
      DEC(j)
    END;
    INC(i)
  END
END GFMult;

PROCEDURE GHASHBlocks(VAR h: Block; VAR data: TLSBytes.Buffer; VAR y: Block);
VAR pos, i, n: LONGINT; block, tmp: Block;
BEGIN
  ClearBlock(y); pos := 0;
  WHILE pos < data.len DO
    ClearBlock(block);
    n := data.len - pos; IF n > 16 THEN n := 16 END;
    i := 0; WHILE i < n DO block[i] := data.data[pos+i]; INC(i) END;
    XorBlock(y, block); GFMult(y, h, tmp);
    i := 0; WHILE i < 16 DO y[i] := tmp[i]; INC(i) END;
    pos := pos + n
  END
END GHASHBlocks;

PROCEDURE BuildGHASHInput(VAR aad, cipher: TLSBytes.Buffer; VAR data: TLSBytes.Buffer);
VAR pad, i: LONGINT;
BEGIN
  TLSBytes.Init(data);
  TLSBytes.Append(data, aad);
  pad := (16 - (aad.len MOD 16)) MOD 16;
  i := 0; WHILE i < pad DO TLSBytes.AppendByte(data, 0); INC(i) END;
  TLSBytes.Append(data, cipher);
  pad := (16 - (cipher.len MOD 16)) MOD 16;
  i := 0; WHILE i < pad DO TLSBytes.AppendByte(data, 0); INC(i) END;
  TLSBytes.PutBE64(data, 0, aad.len * 8);  (* lengths in bits; the buffers are at most TLSBytes.MaxLen *)
  TLSBytes.PutBE64(data, 0, cipher.len * 8)
END BuildGHASHInput;

PROCEDURE CalcTag(VAR key, nonce, aad, cipher: TLSBytes.Buffer; VAR tag: Block);
VAR zero, h, j0, ej0, s: Block; gdata: TLSBytes.Buffer; i: LONGINT;
BEGIN
  IF nonce.len # 12 THEN HALT(63) END;
  ClearBlock(zero); AES128EncryptBlock(key, zero, h);
  BuildGHASHInput(aad, cipher, gdata);
  GHASHBlocks(h, gdata, s);
  i := 0; WHILE i < 12 DO j0[i] := nonce.data[i]; INC(i) END;
  j0[12] := 0X; j0[13] := 0X; j0[14] := 0X; j0[15] := 1X;
  AES128EncryptBlock(key, j0, ej0);
  i := 0; WHILE i < 16 DO tag[i] := XorC(ej0[i], s[i]); INC(i) END
END CalcTag;

PROCEDURE AES128GCMEncrypt*(VAR key, msg, nonce, aad: TLSBytes.Buffer; VAR dst: TLSBytes.Buffer);
VAR cipher: TLSBytes.Buffer; tag: Block; i: LONGINT;
BEGIN
  AES128CTR(key, msg, nonce, 2, cipher);
  CalcTag(key, nonce, aad, cipher, tag);
  TLSBytes.Copy(cipher, dst);
  i := 0; WHILE i < 16 DO TLSBytes.AppendChar(dst, tag[i]); INC(i) END
END AES128GCMEncrypt;

PROCEDURE AES128GCMDecrypt*(VAR key, packet, nonce, aad: TLSBytes.Buffer; VAR plain: TLSBytes.Buffer): BOOLEAN;
VAR cipher, got, want: TLSBytes.Buffer; tag: Block; i: LONGINT;
BEGIN
  IF packet.len < 16 THEN RETURN FALSE END;
  TLSBytes.Slice(packet, 0, packet.len - 16, cipher);
  TLSBytes.Slice(packet, packet.len - 16, 16, got);
  CalcTag(key, nonce, aad, cipher, tag);
  TLSBytes.Init(want); i := 0; WHILE i < 16 DO TLSBytes.AppendChar(want, tag[i]); INC(i) END;
  IF ~TLSBytes.EqualConstTime(got, want) THEN RETURN FALSE END;
  AES128CTR(key, cipher, nonce, 2, plain);
  RETURN TRUE
END AES128GCMDecrypt;

PROCEDURE InitConstants;
BEGIN
  SBox[0] := 063X; SBox[1] := 07CX; SBox[2] := 077X; SBox[3] := 07BX; SBox[4] := 0F2X; SBox[5] := 06BX; SBox[6] := 06FX; SBox[7] := 0C5X;
  SBox[8] := 030X; SBox[9] := 001X; SBox[10] := 067X; SBox[11] := 02BX; SBox[12] := 0FEX; SBox[13] := 0D7X; SBox[14] := 0ABX; SBox[15] := 076X;
  SBox[16] := 0CAX; SBox[17] := 082X; SBox[18] := 0C9X; SBox[19] := 07DX; SBox[20] := 0FAX; SBox[21] := 059X; SBox[22] := 047X; SBox[23] := 0F0X;
  SBox[24] := 0ADX; SBox[25] := 0D4X; SBox[26] := 0A2X; SBox[27] := 0AFX; SBox[28] := 09CX; SBox[29] := 0A4X; SBox[30] := 072X; SBox[31] := 0C0X;
  SBox[32] := 0B7X; SBox[33] := 0FDX; SBox[34] := 093X; SBox[35] := 026X; SBox[36] := 036X; SBox[37] := 03FX; SBox[38] := 0F7X; SBox[39] := 0CCX;
  SBox[40] := 034X; SBox[41] := 0A5X; SBox[42] := 0E5X; SBox[43] := 0F1X; SBox[44] := 071X; SBox[45] := 0D8X; SBox[46] := 031X; SBox[47] := 015X;
  SBox[48] := 004X; SBox[49] := 0C7X; SBox[50] := 023X; SBox[51] := 0C3X; SBox[52] := 018X; SBox[53] := 096X; SBox[54] := 005X; SBox[55] := 09AX;
  SBox[56] := 007X; SBox[57] := 012X; SBox[58] := 080X; SBox[59] := 0E2X; SBox[60] := 0EBX; SBox[61] := 027X; SBox[62] := 0B2X; SBox[63] := 075X;
  SBox[64] := 009X; SBox[65] := 083X; SBox[66] := 02CX; SBox[67] := 01AX; SBox[68] := 01BX; SBox[69] := 06EX; SBox[70] := 05AX; SBox[71] := 0A0X;
  SBox[72] := 052X; SBox[73] := 03BX; SBox[74] := 0D6X; SBox[75] := 0B3X; SBox[76] := 029X; SBox[77] := 0E3X; SBox[78] := 02FX; SBox[79] := 084X;
  SBox[80] := 053X; SBox[81] := 0D1X; SBox[82] := 000X; SBox[83] := 0EDX; SBox[84] := 020X; SBox[85] := 0FCX; SBox[86] := 0B1X; SBox[87] := 05BX;
  SBox[88] := 06AX; SBox[89] := 0CBX; SBox[90] := 0BEX; SBox[91] := 039X; SBox[92] := 04AX; SBox[93] := 04CX; SBox[94] := 058X; SBox[95] := 0CFX;
  SBox[96] := 0D0X; SBox[97] := 0EFX; SBox[98] := 0AAX; SBox[99] := 0FBX; SBox[100] := 043X; SBox[101] := 04DX; SBox[102] := 033X; SBox[103] := 085X;
  SBox[104] := 045X; SBox[105] := 0F9X; SBox[106] := 002X; SBox[107] := 07FX; SBox[108] := 050X; SBox[109] := 03CX; SBox[110] := 09FX; SBox[111] := 0A8X;
  SBox[112] := 051X; SBox[113] := 0A3X; SBox[114] := 040X; SBox[115] := 08FX; SBox[116] := 092X; SBox[117] := 09DX; SBox[118] := 038X; SBox[119] := 0F5X;
  SBox[120] := 0BCX; SBox[121] := 0B6X; SBox[122] := 0DAX; SBox[123] := 021X; SBox[124] := 010X; SBox[125] := 0FFX; SBox[126] := 0F3X; SBox[127] := 0D2X;
  SBox[128] := 0CDX; SBox[129] := 00CX; SBox[130] := 013X; SBox[131] := 0ECX; SBox[132] := 05FX; SBox[133] := 097X; SBox[134] := 044X; SBox[135] := 017X;
  SBox[136] := 0C4X; SBox[137] := 0A7X; SBox[138] := 07EX; SBox[139] := 03DX; SBox[140] := 064X; SBox[141] := 05DX; SBox[142] := 019X; SBox[143] := 073X;
  SBox[144] := 060X; SBox[145] := 081X; SBox[146] := 04FX; SBox[147] := 0DCX; SBox[148] := 022X; SBox[149] := 02AX; SBox[150] := 090X; SBox[151] := 088X;
  SBox[152] := 046X; SBox[153] := 0EEX; SBox[154] := 0B8X; SBox[155] := 014X; SBox[156] := 0DEX; SBox[157] := 05EX; SBox[158] := 00BX; SBox[159] := 0DBX;
  SBox[160] := 0E0X; SBox[161] := 032X; SBox[162] := 03AX; SBox[163] := 00AX; SBox[164] := 049X; SBox[165] := 006X; SBox[166] := 024X; SBox[167] := 05CX;
  SBox[168] := 0C2X; SBox[169] := 0D3X; SBox[170] := 0ACX; SBox[171] := 062X; SBox[172] := 091X; SBox[173] := 095X; SBox[174] := 0E4X; SBox[175] := 079X;
  SBox[176] := 0E7X; SBox[177] := 0C8X; SBox[178] := 037X; SBox[179] := 06DX; SBox[180] := 08DX; SBox[181] := 0D5X; SBox[182] := 04EX; SBox[183] := 0A9X;
  SBox[184] := 06CX; SBox[185] := 056X; SBox[186] := 0F4X; SBox[187] := 0EAX; SBox[188] := 065X; SBox[189] := 07AX; SBox[190] := 0AEX; SBox[191] := 008X;
  SBox[192] := 0BAX; SBox[193] := 078X; SBox[194] := 025X; SBox[195] := 02EX; SBox[196] := 01CX; SBox[197] := 0A6X; SBox[198] := 0B4X; SBox[199] := 0C6X;
  SBox[200] := 0E8X; SBox[201] := 0DDX; SBox[202] := 074X; SBox[203] := 01FX; SBox[204] := 04BX; SBox[205] := 0BDX; SBox[206] := 08BX; SBox[207] := 08AX;
  SBox[208] := 070X; SBox[209] := 03EX; SBox[210] := 0B5X; SBox[211] := 066X; SBox[212] := 048X; SBox[213] := 003X; SBox[214] := 0F6X; SBox[215] := 00EX;
  SBox[216] := 061X; SBox[217] := 035X; SBox[218] := 057X; SBox[219] := 0B9X; SBox[220] := 086X; SBox[221] := 0C1X; SBox[222] := 01DX; SBox[223] := 09EX;
  SBox[224] := 0E1X; SBox[225] := 0F8X; SBox[226] := 098X; SBox[227] := 011X; SBox[228] := 069X; SBox[229] := 0D9X; SBox[230] := 08EX; SBox[231] := 094X;
  SBox[232] := 09BX; SBox[233] := 01EX; SBox[234] := 087X; SBox[235] := 0E9X; SBox[236] := 0CEX; SBox[237] := 055X; SBox[238] := 028X; SBox[239] := 0DFX;
  SBox[240] := 08CX; SBox[241] := 0A1X; SBox[242] := 089X; SBox[243] := 00DX; SBox[244] := 0BFX; SBox[245] := 0E6X; SBox[246] := 042X; SBox[247] := 068X;
  SBox[248] := 041X; SBox[249] := 099X; SBox[250] := 02DX; SBox[251] := 00FX; SBox[252] := 0B0X; SBox[253] := 054X; SBox[254] := 0BBX; SBox[255] := 016X;
  RCon[0] := 001X; RCon[1] := 002X; RCon[2] := 004X; RCon[3] := 008X; RCon[4] := 010X;
  RCon[5] := 020X; RCon[6] := 040X; RCon[7] := 080X; RCon[8] := 01BX; RCon[9] := 036X
END InitConstants;

BEGIN
  InitConstants
END TLSAESGCM.
