(* ETH Oberon, Copyright 1990-2003 Computer Systems Institute, ETH Zurich, CH-8092 Zurich.
Refer to the license.txt file provided with this distribution. *)

MODULE DES;  (** JSS  **)

(*
Implements the DES encryption method.

This is a pretty straight rewrite of the Java version of the algorithm supplied in the VNC
package from Olivetti and Oracle Research Laboratory, which is turn is based on a version by
Dave Zimmerman <dzimm@widget.com>, copyright 1996 Widget Workshop, Inc.

The Java version was Copyright (C) 1998 Olivetti and Oracle Research Laboratory

G…nter Feldmann reports that this DES implementation is not compatible with others.
For an implementation compatible with SSH and OpenSSH, use his cryptDES module instead.
*)

IMPORT
  BIT (*, Out*), TwoComplement;

VAR
  encryptKeys,
    decryptKeys : ARRAY 32 OF LONGINT;

  tempints : ARRAY 2 OF LONGINT;

  byteBit : ARRAY 8 OF LONGINT;

  bigByte : ARRAY 24 OF LONGINT;

  pc1 : ARRAY 56 OF LONGINT;

  totrot : ARRAY 16 OF LONGINT;

  pc2 : ARRAY 48 OF LONGINT;

  SP1,
    SP2,
    SP3,
    SP4,
    SP5,
    SP6,
    SP7,
    SP8 : ARRAY 64 OF LONGINT;

  PROCEDURE RotateRight*(L : LONGINT;n : SHORTINT) : LONGINT;

  (*
    This rotates L right by n places, corresponding to the J++ >>>
    operator, but doesn't move any set bits in at the high end of
    the word

    The original version:

      RETURN L DIV BIT.LLSH(1,n)

    doesn't work when L is negative, hence this rather convoluted one
  *)

  BEGIN
    RETURN BIT.LROT(BIT.LAND(L,-BIT.LLSH(1,n)),-n)
  END RotateRight;

  PROCEDURE SetKey*(key : ARRAY OF CHAR);

    PROCEDURE DESKey(    encrypting : BOOLEAN;
                      VAR KnL : ARRAY OF LONGINT);

    VAR
      keyBlock : ARRAY 8 OF LONGINT;

      i,j,m,l,n : LONGINT;

      pc1m,
        pcr : ARRAY 56 OF LONGINT;

      kn : ARRAY 32 OF LONGINT;

      PROCEDURE cookey;

      VAR
        raw0,raw1 : LONGINT;

        rawi,KnLi : LONGINT;

        i : INTEGER;

      BEGIN
        rawi := 0;KnLi := 0;
        FOR i := 0 TO 15 DO (* Java code has for (i=0, rawi=0,KnLi=0;i<16;i++) *)
          raw0 := kn[rawi];INC(rawi); (* Java code has raw0 = raw[rawi++]  etc *)
          raw1 := kn[rawi];INC(rawi);
          KnL[KnLi] := BIT.LLSH(BIT.LAND(raw0,00FC0000H),6);
          KnL[KnLi] := BIT.LOR(KnL[KnLi],BIT.LLSH(BIT.LAND(raw0,00000FC0H),10));
          KnL[KnLi] := BIT.LOR(KnL[KnLi],RotateRight(BIT.LAND(raw1,00FC0000H),10));
          KnL[KnLi] := BIT.LOR(KnL[KnLi],RotateRight(BIT.LAND(raw1,00000FC0H),6));INC(KnLi);

          KnL[KnLi] := BIT.LLSH(BIT.LAND(raw0,0003F000H),12);
          KnL[KnLi] := BIT.LOR(KnL[KnLi],BIT.LLSH(BIT.LAND(raw0,0000003FH),16));
          KnL[KnLi] := BIT.LOR(KnL[KnLi],RotateRight(BIT.LAND(raw1,0003F000H),4));
          KnL[KnLi] := BIT.LOR(KnL[KnLi],BIT.LAND(raw1,0000003FH));INC(KnLi)
        END
      END cookey;

    BEGIN
      FOR j := 0 TO 7 DO
        keyBlock[j] := ORD(key[j])
      END;
      FOR j := 0 TO 55 DO
        l := pc1[j];m := BIT.LAND(l,7);DEC(l,m);
        IF BIT.LAND(keyBlock[RotateRight(l, 3)],byteBit[m]) # 0H THEN
          pc1m[j] :=  1
        ELSE
          pc1m[j] := 0
        END
      END;
      FOR i := 0 TO 15 DO
        IF encrypting THEN
          m := BIT.LLSH(i,1)
        ELSE
          m := BIT.LLSH(15 - i,1)
        END;
        n := m + 1;
        kn[m] := 0;kn[n] := 0;
        FOR j := 0 TO 27 DO
          l := j + totrot[i];
          IF l < 28 THEN
            pcr[j] := pc1m[l]
          ELSE
            pcr[j] := pc1m[l - 28]
          END
        END;
        FOR j := 28 TO 55 DO
          l := j + totrot[i];
          IF l < 56 THEN
            pcr[j] := pc1m[l]
          ELSE
            pcr[j] := pc1m[l - 28]
          END;
        END;
        FOR j := 0 TO 23 DO
          IF pcr[pc2[j]] # 0 THEN
            kn[m] := BIT.LOR(kn[m],bigByte[j])
          END;
          IF pcr[pc2[j + 24]] # 0 THEN
            kn[n] := BIT.LOR(kn[n],bigByte[j])
          END;
        END
      END;
      cookey
    END DESKey;

  BEGIN
    DESKey(TRUE,encryptKeys);
    DESKey(FALSE,decryptKeys)
  END SetKey;

  PROCEDURE squashBytesToInts(inBytes : ARRAY OF CHAR;inOffset : INTEGER;
                            VAR outInts : ARRAY OF LONGINT; outOffset : INTEGER;Length : INTEGER);

  VAR
    i : INTEGER;

  BEGIN
    FOR i := 0 TO Length - 1 DO
      outInts[outOffset + i] := ASH(ORD(inBytes[inOffset + (i * 4)]),24) +
                          ASH(ORD(inBytes[inOffset + (i * 4) + 1]),16) +
                          ASH(ORD(inBytes[inOffset + (i * 4) + 2]),8) +
                          ORD(inBytes[inOffset + (i * 4) + 3])
    END
  END squashBytesToInts;

  PROCEDURE spreadIntsToBytes(inInts : ARRAY OF LONGINT;inOffset : INTEGER;
                              VAR outBytes : ARRAY OF CHAR; outOffset : INTEGER;Length : INTEGER);

  VAR
    i : INTEGER;

  BEGIN
    FOR i := 0 TO Length - 1 DO
      outBytes[outOffset + (i * 4)      ] := CHR(BIT.LAND(RotateRight(inInts[inOffset + i], 24),0FFH));
      outBytes[outOffset + (i * 4) + 1] := CHR(BIT.LAND(RotateRight(inInts[inOffset + i], 16),0FFH));
      outBytes[outOffset + (i * 4) + 2] := CHR(BIT.LAND(RotateRight(inInts[inOffset + i], 8),0FFH));
      outBytes[outOffset + (i * 4) + 3] := CHR(BIT.LAND(inInts[inOffset + i],0FFH))
    END
  END spreadIntsToBytes;


  PROCEDURE des(    inInts : ARRAY OF LONGINT;
                VAR outInts : ARRAY OF LONGINT;
                    keys : ARRAY OF LONGINT);

  VAR
    fval,
      work,
      right,
      leftt : LONGINT;

    round : LONGINT;

    keysi : LONGINT;

  BEGIN
    keysi := 0;
    leftt := inInts[0];
    right := inInts[1];

    work := BIT.LAND(BIT.LXOR(RotateRight(leftt, 4),right),0F0F0F0FH);
    right := BIT.LXOR(right,work);
    leftt := BIT.LXOR(leftt,BIT.LLSH(work,4));

    work := BIT.LAND(BIT.LXOR(RotateRight(leftt, 16),right),0000FFFFH);
    right := BIT.LXOR(right,work);
    leftt := BIT.LXOR(leftt,BIT.LLSH(work,16));

    work := BIT.LAND(BIT.LXOR(RotateRight(right, 2),leftt),33333333H);
    leftt := BIT.LXOR(leftt,work);
    right := BIT.LXOR(right,BIT.LLSH(work,2));

    work := BIT.LAND(BIT.LXOR(RotateRight(right, 8),leftt),00FF00FFH);
    leftt := BIT.LXOR(leftt,work);
    right := BIT.LXOR(right,BIT.LLSH(work,8));
    right := BIT.LOR(BIT.LLSH(right,1),BIT.LAND(RotateRight(right, 31),1));
    work := BIT.LAND(BIT.LXOR(leftt, right), TwoComplement.FromHugeIntToSigned(0AAAAAAAAH));
    leftt := BIT.LXOR(leftt,work);
    right := BIT.LXOR(right,work);
    leftt := BIT.LOR(BIT.LLSH(leftt,1),BIT.LAND(RotateRight(leftt, 31),1));

    FOR round := 0 TO 7 DO

      work := BIT.LOR(BIT.LLSH(right,28),RotateRight(right, 4));
      work := BIT.LXOR(work,keys[keysi]);
      INC(keysi);

      fval := SP7[BIT.LAND(work,0000003FH)];
      fval := BIT.LOR(fval,SP5[BIT.LAND(RotateRight(work, 8),0000003FH)]);
      fval := BIT.LOR(fval,SP3[BIT.LAND(RotateRight(work, 16),0000003FH)]);
      fval := BIT.LOR(fval,SP1[BIT.LAND(RotateRight(work, 24),0000003FH)]);
      work := BIT.LXOR(right,keys[keysi]);INC(keysi);

      fval := BIT.LOR(fval,SP8[BIT.LAND(work,0000003FH)]);
      fval := BIT.LOR(fval,SP6[BIT.LAND(RotateRight(work, 8),0000003FH)]);
      fval := BIT.LOR(fval,SP4[BIT.LAND(RotateRight(work, 16),0000003FH)]);
      fval := BIT.LOR(fval,SP2[BIT.LAND(RotateRight(work, 24),0000003FH)]);

      leftt := BIT.LXOR(leftt,fval);


      work := BIT.LOR(BIT.LLSH(leftt,28),RotateRight(leftt, 4));

      work := BIT.LXOR(work,keys[keysi]);INC(keysi);

      fval := SP7[BIT.LAND(work,0000003FH)];
      fval := BIT.LOR(fval,SP5[BIT.LAND(RotateRight(work, 8),0000003FH)]);
      fval := BIT.LOR(fval,SP3[BIT.LAND(RotateRight(work, 16),0000003FH)]);
      fval := BIT.LOR(fval,SP1[BIT.LAND(RotateRight(work, 24),0000003FH)]);

      work := BIT.LXOR(leftt,keys[keysi]);INC(keysi);

      fval := BIT.LOR(fval,SP8[BIT.LAND(work,0000003FH)]);
      fval := BIT.LOR(fval,SP6[BIT.LAND(RotateRight(work, 8),0000003FH)]);
      fval := BIT.LOR(fval,SP4[BIT.LAND(RotateRight(work, 16),0000003FH)]);
      fval := BIT.LOR(fval,SP2[BIT.LAND(RotateRight(work, 24),0000003FH)]);

      right := BIT.LXOR(right,fval)
    END;

    right := BIT.LOR(BIT.LLSH(right,31),RotateRight(right, 1));
    work := BIT.LAND(BIT.LXOR(leftt,right), TwoComplement.FromHugeIntToSigned(0AAAAAAAAH));
    leftt := BIT.LXOR(leftt,work);
    right := BIT.LXOR(right,work);
    leftt := BIT.LOR(BIT.LLSH(leftt,31),RotateRight(leftt, 1));
    work := BIT.LAND(BIT.LXOR(RotateRight(leftt, 8),right),00FF00FFH);
    right := BIT.LXOR(right,work);
    leftt := BIT.LXOR(leftt,BIT.LLSH(work,8));
    work := BIT.LAND(BIT.LXOR(RotateRight(leftt, 2),right),33333333H);
    right := BIT.LXOR(right,work);
    leftt := BIT.LXOR(leftt,BIT.LLSH(work,2));
    work := BIT.LAND(BIT.LXOR(RotateRight(right, 16),leftt),0000FFFFH);
    leftt := BIT.LXOR(leftt,work);
    right := BIT.LXOR(right,BIT.LLSH(work,16));
    work := BIT.LAND(BIT.LXOR(RotateRight(right, 4),leftt),0F0F0F0FH);
    leftt := BIT.LXOR(leftt,work);
    right := BIT.LXOR(right,BIT.LLSH(work,4));

    outInts[0] := right;
    outInts[1] := leftt
  END des;


  PROCEDURE encrypt*(     clearText : ARRAY OF CHAR;
                          clearOff : INTEGER;
                     VAR cipherText : ARRAY OF CHAR;
                          cipherOff : INTEGER);

  BEGIN
    squashBytesToInts(clearText,clearOff,tempints,0,2);
    des(tempints,tempints,encryptKeys);
    spreadIntsToBytes(tempints,0,cipherText,cipherOff,2)
  END encrypt;

  PROCEDURE decrypt*(     cipherText : ARRAY OF CHAR;

                          cipherOff : INTEGER;
                     VAR clearText : ARRAY OF CHAR;
                          clearOff : INTEGER);

  BEGIN
    squashBytesToInts(cipherText,cipherOff,tempints,0,2);
    des(tempints,tempints,decryptKeys);
    spreadIntsToBytes(tempints,0,clearText,clearOff,2)
  END decrypt;

(*
  PROCEDURE Test*;

  (**
    Running the DesCipher.Java code through the J++ compiler, if we set off with a key of "Elephant",
    and run the plain text "Hello, this is a" (16 bytes in all), through the encrypt function, we should get
    the byte sequence
      -74   ,-80   ,-113   ,-45   ,-104   ,52   ,119   ,10   ,55   ,-123   ,11   ,-15   ,120   ,-24   ,7   ,-76
    Currently we get
        106,   183,   10,   233,   64,   35,   251,   249,   96,   98,   199,   102,   227,   238,   207
    After putting in the RotateRight function we get
        239,   236,   90,   79,   79,   97,   57,   17,  212,   213,   115,   6,   89,   250,   81,   236,   223
    After correcting the values of the bigByte array to what they should have been, we find that the
    SetKey procedure now works. Also the SquashBytesToInts is OK, and (we assume!) the SpreadIntsToBytes.
    After correcting the Java code test harness and getting RotateRight to work correctly with negative numbers
    we get

     182, 176,  143,  211,  152,  52,  119,  10,  55, 133, 11, 241, 120, 232, 7, 180

     which allowing for the sign is correct!

  *)

  VAR
    cyphered : ARRAY 16 OF CHAR;

    i : INTEGER;

  BEGIN
    SetKey("Elephant");
    encrypt("Hello, this is a",0,cyphered,0);
    encrypt("Hello, this is a",8,cyphered,8);

    FOR i := 0 TO 15 DO
      Out.String("cyphered[");Out.Int(i,0);Out.String("]=");
      Out.Int(ORD(cyphered[i]),0);
      Out.Ln
    END
  END Test;
*)

BEGIN
  byteBit[0] := 01H;byteBit[1] := 02H;byteBit[2] := 04H;byteBit[3] := 08H;
  byteBit[4] := 10H;byteBit[5] := 20H;byteBit[6] := 40H;byteBit[7] := 80H;

  bigByte[0] := 800000H;bigByte[1] := 400000H;bigByte[2] := 200000H;bigByte[3] := 100000H;
  bigByte[4] := 080000H;bigByte[5] := 040000H;bigByte[6] := 020000H;bigByte[7] := 010000H;
  bigByte[8] := 008000H;bigByte[9] := 004000H;bigByte[10] := 002000H;bigByte[11] := 001000H;
  bigByte[12] := 000800H;bigByte[13] := 000400H;bigByte[14] := 000200H;bigByte[15] := 000100H;
  bigByte[16] := 000080H;bigByte[17] := 000040H;bigByte[18] := 000020H;bigByte[19] := 000010H;
  bigByte[20] := 000008H;bigByte[21] := 000004H;bigByte[22] := 000002H;bigByte[23] := 000001H;

  pc1[0] :=  56;pc1[1] :=  48;pc1[2] :=  40;pc1[3] :=  32;pc1[4]:=  24;pc1[5] :=  16;pc1[6] :=  8;
  pc1[7] :=  0;pc1[8] :=  57;pc1[9] :=  49;pc1[10] :=  41;pc1[11]:=  33;pc1[12] :=  25;pc1[13] :=  17;
  pc1[14] :=  9;pc1[15] :=  1;pc1[16] :=  58;pc1[17] :=  50;pc1[18]:=  42;pc1[19] :=  34;pc1[20] :=  26;
  pc1[21] :=  18;pc1[22] :=  10;pc1[23] :=  2;pc1[24] :=  59;pc1[25]:=  51;pc1[26] :=  43;pc1[27] :=  35;
  pc1[28] :=  62;pc1[29] :=  54;pc1[30] :=  46;pc1[31] :=  38;pc1[32]:=  30;pc1[33] :=  22;pc1[34] :=  14;
  pc1[35] :=  6;pc1[36] :=  61;pc1[37] :=  53;pc1[38] :=  45;pc1[39]:=  37;pc1[40] :=  29;pc1[41] :=  21;
  pc1[42] :=  13;pc1[43] :=  5;pc1[44] :=  60;pc1[45] :=  52;pc1[46]:=  44;pc1[47] :=  36;pc1[48] :=  28;
  pc1[49] :=  20;pc1[50] :=  12;pc1[51] :=  4;pc1[52] :=  27;pc1[53]:=  19;pc1[54] :=  11;pc1[55] :=  3;

  totrot[0] := 1;totrot[1] := 2;totrot[2] := 4;totrot[3] := 6;totrot[4] := 8;totrot[5] := 10;totrot[6] := 12;
  totrot[7] := 14;totrot[8] := 15;totrot[9] := 17;totrot[10] := 19;totrot[11] := 21;totrot[12] := 23;totrot[13] := 25;
  totrot[14] := 27;totrot[15] := 28;

  pc2[0] :=  13;pc2[1] :=  16;pc2[2] :=  10;pc2[3] :=  23;pc2[4]:=  0;pc2[5] :=  4;pc2[6] :=  2;
  pc2[7] :=  27;pc2[8] :=  14;pc2[9] :=  5;pc2[10] :=  20;pc2[11]:=  9;pc2[12] :=  22;pc2[13] :=  18;
  pc2[14] :=  11;pc2[15] :=  3;pc2[16] :=  25;pc2[17] :=  7;pc2[18]:=  15;pc2[19] :=  6;pc2[20] :=  26;
  pc2[21] :=  19;pc2[22] :=  12;pc2[23] :=  1;pc2[24] :=  40;pc2[25]:=  51;pc2[26] :=  30;pc2[27] :=  36;
  pc2[28] :=  46;pc2[29] :=  54;pc2[30] :=  29;pc2[31] :=  39;pc2[32]:=  50;pc2[33] :=  44;pc2[34] :=  32;
  pc2[35] :=  47;pc2[36] :=  43;pc2[37] :=  48;pc2[38] :=  38;pc2[39]:=  55;pc2[40] :=  33;pc2[41] :=  52;
  pc2[42] :=  45;pc2[43] :=  41;pc2[44] :=  49;pc2[45] :=  35;pc2[46]:=  28;pc2[47] :=  31;

    SP1[0] := 01010400H; SP1[1] := 00000000H; SP1[2] := 00010000H; SP1[3] := 01010404H;
  SP1[4] := 01010004H; SP1[5] := 00010404H; SP1[6] := 00000004H; SP1[7] := 00010000H;
  SP1[8] := 00000400H; SP1[9] := 01010400H; SP1[10] := 01010404H; SP1[11] := 00000400H;
  SP1[12] := 01000404H; SP1[13] := 01010004H; SP1[14] := 01000000H; SP1[15] := 00000004H;
  SP1[16] := 00000404H; SP1[17] := 01000400H; SP1[18] := 01000400H; SP1[19] := 00010400H;
  SP1[20] := 00010400H; SP1[21] := 01010000H; SP1[22] := 01010000H; SP1[23] := 01000404H;
  SP1[24] := 00010004H; SP1[25] := 01000004H; SP1[26] := 01000004H; SP1[27] := 00010004H;
  SP1[28] := 00000000H; SP1[29] := 00000404H; SP1[30] := 00010404H; SP1[31] := 01000000H;
  SP1[32] := 00010000H; SP1[33] := 01010404H; SP1[34] := 00000004H; SP1[35] := 01010000H;
  SP1[36] := 01010400H; SP1[37] := 01000000H; SP1[38] := 01000000H; SP1[39] := 00000400H;
  SP1[40] := 01010004H; SP1[41] := 00010000H; SP1[42] := 00010400H; SP1[43] := 01000004H;
  SP1[44] := 00000400H; SP1[45] := 00000004H; SP1[46] := 01000404H; SP1[47] := 00010404H;
  SP1[48] := 01010404H; SP1[49] := 00010004H; SP1[50] := 01010000H; SP1[51] := 01000404H;
  SP1[52] := 01000004H; SP1[53] := 00000404H; SP1[54] := 00010404H; SP1[55] := 01010400H;
  SP1[56] := 00000404H; SP1[57] := 01000400H; SP1[58] := 01000400H; SP1[59] := 00000000H;
  SP1[60] := 00010004H; SP1[61] := 00010400H; SP1[62] := 00000000H; SP1[63] := 01010004H;

  SP2[0] := TwoComplement.FromHugeIntToSigned(80108020H); SP2[1] := TwoComplement.FromHugeIntToSigned(80008000H); SP2[2] := 00008000H; SP2[3] := 00108020H;
    SP2[4] := 00100000H; SP2[5] := 00000020H; SP2[6] := TwoComplement.FromHugeIntToSigned(80100020H); SP2[7] := TwoComplement.FromHugeIntToSigned(80008020H);
    SP2[8] := TwoComplement.FromHugeIntToSigned(80000020H); SP2[9] := TwoComplement.FromHugeIntToSigned(80108020H); SP2[10] := TwoComplement.FromHugeIntToSigned(80108000H); SP2[11] := TwoComplement.FromHugeIntToSigned(80000000H);
    SP2[12] := TwoComplement.FromHugeIntToSigned(80008000H); SP2[13] := 00100000H; SP2[14] := 00000020H; SP2[15] := TwoComplement.FromHugeIntToSigned(80100020H);
    SP2[16] := 00108000H; SP2[17] := 00100020H; SP2[18] := TwoComplement.FromHugeIntToSigned(80008020H); SP2[19] := 00000000H;
    SP2[20] := TwoComplement.FromHugeIntToSigned(80000000H); SP2[21] := 00008000H; SP2[22] := 00108020H; SP2[23] := TwoComplement.FromHugeIntToSigned(80100000H);
    SP2[24] := 00100020H; SP2[25] := TwoComplement.FromHugeIntToSigned(80000020H); SP2[26] := 00000000H; SP2[27] := 00108000H;
    SP2[28] := 00008020H; SP2[29] := TwoComplement.FromHugeIntToSigned(80108000H); SP2[30] := TwoComplement.FromHugeIntToSigned(80100000H); SP2[31] := 00008020H;
    SP2[32] := 00000000H; SP2[33] := 00108020H; SP2[34] := TwoComplement.FromHugeIntToSigned(80100020H); SP2[35] := 00100000H;
    SP2[36] := TwoComplement.FromHugeIntToSigned(80008020H); SP2[37] := TwoComplement.FromHugeIntToSigned(80100000H); SP2[38] := TwoComplement.FromHugeIntToSigned(80108000H); SP2[39] := 00008000H;
    SP2[40] := TwoComplement.FromHugeIntToSigned(80100000H); SP2[41] := TwoComplement.FromHugeIntToSigned(80008000H); SP2[42] := 00000020H; SP2[43] := TwoComplement.FromHugeIntToSigned(80108020H);
    SP2[44] := 00108020H; SP2[45] := 00000020H; SP2[46] := 00008000H; SP2[47] := TwoComplement.FromHugeIntToSigned(80000000H);
    SP2[48] := 00008020H; SP2[49] := TwoComplement.FromHugeIntToSigned(80108000H); SP2[50] := 00100000H; SP2[51] := TwoComplement.FromHugeIntToSigned(80000020H);
    SP2[52] := 00100020H; SP2[53] := TwoComplement.FromHugeIntToSigned(80008020H); SP2[54] := TwoComplement.FromHugeIntToSigned(80000020H); SP2[55] := 00100020H;
    SP2[56] := 00108000H; SP2[57] := 00000000H; SP2[58] := TwoComplement.FromHugeIntToSigned(80008000H); SP2[59] := 00008020H;
    SP2[60] := TwoComplement.FromHugeIntToSigned(80000000H); SP2[61] := TwoComplement.FromHugeIntToSigned(80100020H); SP2[62] := TwoComplement.FromHugeIntToSigned(80108020H); SP2[63] := 00108000H;




  SP3[0] := 00000208H; SP3[1] := 08020200H; SP3[2] := 00000000H; SP3[3] := 08020008H;
  SP3[4] := 08000200H; SP3[5] := 00000000H; SP3[6] := 00020208H; SP3[7] := 08000200H;
  SP3[8] := 00020008H; SP3[9] := 08000008H; SP3[10] := 08000008H; SP3[11] := 00020000H;
  SP3[12] := 08020208H; SP3[13] := 00020008H; SP3[14] := 08020000H; SP3[15] := 00000208H;
  SP3[16] := 08000000H; SP3[17] := 00000008H; SP3[18] := 08020200H; SP3[19] := 00000200H;
  SP3[20] := 00020200H; SP3[21] := 08020000H; SP3[22] := 08020008H; SP3[23] := 00020208H;
  SP3[24] := 08000208H; SP3[25] := 00020200H; SP3[26] := 00020000H; SP3[27] := 08000208H;
  SP3[28] := 00000008H; SP3[29] := 08020208H; SP3[30] := 00000200H; SP3[31] := 08000000H;
  SP3[32] := 08020200H; SP3[33] := 08000000H; SP3[34] := 00020008H; SP3[35] := 00000208H;
  SP3[36] := 00020000H; SP3[37] := 08020200H; SP3[38] := 08000200H; SP3[39] := 00000000H;
  SP3[40] := 00000200H; SP3[41] := 00020008H; SP3[42] := 08020208H; SP3[43] := 08000200H;
  SP3[44] := 08000008H; SP3[45] := 00000200H; SP3[46] := 00000000H; SP3[47] := 08020008H;
  SP3[48] := 08000208H; SP3[49] := 00020000H; SP3[50] := 08000000H; SP3[51] := 08020208H;
  SP3[52] := 00000008H; SP3[53] := 00020208H; SP3[54] := 00020200H; SP3[55] := 08000008H;
  SP3[56] := 08020000H; SP3[57] := 08000208H; SP3[58] := 00000208H; SP3[59] := 08020000H;
  SP3[60] := 00020208H; SP3[61] := 00000008H; SP3[62] := 08020008H; SP3[63] := 00020200H;

  SP4[0] := 00802001H; SP4[1] := 00002081H; SP4[2] := 00002081H; SP4[3] := 00000080H;
  SP4[4] := 00802080H; SP4[5] := 00800081H; SP4[6] := 00800001H; SP4[7] := 00002001H;
  SP4[8] := 00000000H; SP4[9] := 00802000H; SP4[10] := 00802000H; SP4[11] := 00802081H;
  SP4[12] := 00000081H; SP4[13] := 00000000H; SP4[14] := 00800080H; SP4[15] := 00800001H;
  SP4[16] := 00000001H; SP4[17] := 00002000H; SP4[18] := 00800000H; SP4[19] := 00802001H;
  SP4[20] := 00000080H; SP4[21] := 00800000H; SP4[22] := 00002001H; SP4[23] := 00002080H;
  SP4[24] := 00800081H; SP4[25] := 00000001H; SP4[26] := 00002080H; SP4[27] := 00800080H;
  SP4[28] := 00002000H; SP4[29] := 00802080H; SP4[30] := 00802081H; SP4[31] := 00000081H;
  SP4[32] := 00800080H; SP4[33] := 00800001H; SP4[34] := 00802000H; SP4[35] := 00802081H;
  SP4[36] := 00000081H; SP4[37] := 00000000H; SP4[38] := 00000000H; SP4[39] := 00802000H;
  SP4[40] := 00002080H; SP4[41] := 00800080H; SP4[42] := 00800081H; SP4[43] := 00000001H;
  SP4[44] := 00802001H; SP4[45] := 00002081H; SP4[46] := 00002081H; SP4[47] := 00000080H;
  SP4[48] := 00802081H; SP4[49] := 00000081H; SP4[50] := 00000001H; SP4[51] := 00002000H;
  SP4[52] := 00800001H; SP4[53] := 00002001H; SP4[54] := 00802080H; SP4[55] := 00800081H;
  SP4[56] := 00002001H; SP4[57] := 00002080H; SP4[58] := 00800000H; SP4[59] := 00802001H;
  SP4[60] := 00000080H; SP4[61] := 00800000H; SP4[62] := 00002000H; SP4[63] := 00802080H;

  SP5[0] := 00000100H; SP5[1] := 02080100H; SP5[2] := 02080000H; SP5[3] := 42000100H;
  SP5[4] := 00080000H; SP5[5] := 00000100H; SP5[6] := 40000000H; SP5[7] := 02080000H;
  SP5[8] := 40080100H; SP5[9] := 00080000H; SP5[10] := 02000100H; SP5[11] := 40080100H;
  SP5[12] := 42000100H; SP5[13] := 42080000H; SP5[14] := 00080100H; SP5[15] := 40000000H;
  SP5[16] := 02000000H; SP5[17] := 40080000H; SP5[18] := 40080000H; SP5[19] := 00000000H;
  SP5[20] := 40000100H; SP5[21] := 42080100H; SP5[22] := 42080100H; SP5[23] := 02000100H;
  SP5[24] := 42080000H; SP5[25] := 40000100H; SP5[26] := 00000000H; SP5[27] := 42000000H;
  SP5[28] := 02080100H; SP5[29] := 02000000H; SP5[30] := 42000000H; SP5[31] := 00080100H;
  SP5[32] := 00080000H; SP5[33] := 42000100H; SP5[34] := 00000100H; SP5[35] := 02000000H;
  SP5[36] := 40000000H; SP5[37] := 02080000H; SP5[38] := 42000100H; SP5[39] := 40080100H;
  SP5[40] := 02000100H; SP5[41] := 40000000H; SP5[42] := 42080000H; SP5[43] := 02080100H;
  SP5[44] := 40080100H; SP5[45] := 00000100H; SP5[46] := 02000000H; SP5[47] := 42080000H;
  SP5[48] := 42080100H; SP5[49] := 00080100H; SP5[50] := 42000000H; SP5[51] := 42080100H;
  SP5[52] := 02080000H; SP5[53] := 00000000H; SP5[54] := 40080000H; SP5[55] := 42000000H;
  SP5[56] := 00080100H; SP5[57] := 02000100H; SP5[58] := 40000100H; SP5[59] := 00080000H;
  SP5[60] := 00000000H; SP5[61] := 40080000H; SP5[62] := 02080100H; SP5[63] := 40000100H;

  SP6[0] := 20000010H; SP6[1] := 20400000H; SP6[2] := 00004000H; SP6[3] := 20404010H;
  SP6[4] := 20400000H; SP6[5] := 00000010H; SP6[6] := 20404010H; SP6[7] := 00400000H;
  SP6[8] := 20004000H; SP6[9] := 00404010H; SP6[10] := 00400000H; SP6[11] := 20000010H;
  SP6[12] := 00400010H; SP6[13] := 20004000H; SP6[14] := 20000000H; SP6[15] := 00004010H;
  SP6[16] := 00000000H; SP6[17] := 00400010H; SP6[18] := 20004010H; SP6[19] := 00004000H;
  SP6[20] := 00404000H; SP6[21] := 20004010H; SP6[22] := 00000010H; SP6[23] := 20400010H;
  SP6[24] := 20400010H; SP6[25] := 00000000H; SP6[26] := 00404010H; SP6[27] := 20404000H;
  SP6[28] := 00004010H; SP6[29] := 00404000H; SP6[30] := 20404000H; SP6[31] := 20000000H;
  SP6[32] := 20004000H; SP6[33] := 00000010H; SP6[34] := 20400010H; SP6[35] := 00404000H;
  SP6[36] := 20404010H; SP6[37] := 00400000H; SP6[38] := 00004010H; SP6[39] := 20000010H;
  SP6[40] := 00400000H; SP6[41] := 20004000H; SP6[42] := 20000000H; SP6[43] := 00004010H;
  SP6[44] := 20000010H; SP6[45] := 20404010H; SP6[46] := 00404000H; SP6[47] := 20400000H;
  SP6[48] := 00404010H; SP6[49] := 20404000H; SP6[50] := 00000000H; SP6[51] := 20400010H;
  SP6[52] := 00000010H; SP6[53] := 00004000H; SP6[54] := 20400000H; SP6[55] := 00404010H;
  SP6[56] := 00004000H; SP6[57] := 00400010H; SP6[58] := 20004010H; SP6[59] := 00000000H;
  SP6[60] := 20404000H; SP6[61] := 20000000H; SP6[62] := 00400010H; SP6[63] := 20004010H;

  SP7[0] := 00200000H; SP7[1] := 04200002H; SP7[2] := 04000802H; SP7[3] := 00000000H;
  SP7[4] := 00000800H; SP7[5] := 04000802H; SP7[6] := 00200802H; SP7[7] := 04200800H;
  SP7[8] := 04200802H; SP7[9] := 00200000H; SP7[10] := 00000000H; SP7[11] := 04000002H;
  SP7[12] := 00000002H; SP7[13] := 04000000H; SP7[14] := 04200002H; SP7[15] := 00000802H;
  SP7[16] := 04000800H; SP7[17] := 00200802H; SP7[18] := 00200002H; SP7[19] := 04000800H;
  SP7[20] := 04000002H; SP7[21] := 04200000H; SP7[22] := 04200800H; SP7[23] := 00200002H;
  SP7[24] := 04200000H; SP7[25] := 00000800H; SP7[26] := 00000802H; SP7[27] := 04200802H;
  SP7[28] := 00200800H; SP7[29] := 00000002H; SP7[30] := 04000000H; SP7[31] := 00200800H;
  SP7[32] := 04000000H; SP7[33] := 00200800H; SP7[34] := 00200000H; SP7[35] := 04000802H;
  SP7[36] := 04000802H; SP7[37] := 04200002H; SP7[38] := 04200002H; SP7[39] := 00000002H;
  SP7[40] := 00200002H; SP7[41] := 04000000H; SP7[42] := 04000800H; SP7[43] := 00200000H;
  SP7[44] := 04200800H; SP7[45] := 00000802H; SP7[46] := 00200802H; SP7[47] := 04200800H;
  SP7[48] := 00000802H; SP7[49] := 04000002H; SP7[50] := 04200802H; SP7[51] := 04200000H;
  SP7[52] := 00200800H; SP7[53] := 00000000H; SP7[54] := 00000002H; SP7[55] := 04200802H;
  SP7[56] := 00000000H; SP7[57] := 00200802H; SP7[58] := 04200000H; SP7[59] := 00000800H;
  SP7[60] := 04000002H; SP7[61] := 04000800H; SP7[62] := 00000800H; SP7[63] := 00200002H;

  SP8[0] := 10001040H; SP8[1] := 00001000H; SP8[2] := 00040000H; SP8[3] := 10041040H;
  SP8[4] := 10000000H; SP8[5] := 10001040H; SP8[6] := 00000040H; SP8[7] := 10000000H;
  SP8[8] := 00040040H; SP8[9] := 10040000H; SP8[10] := 10041040H; SP8[11] := 00041000H;
  SP8[12] := 10041000H; SP8[13] := 00041040H; SP8[14] := 00001000H; SP8[15] := 00000040H;
  SP8[16] := 10040000H; SP8[17] := 10000040H; SP8[18] := 10001000H; SP8[19] := 00001040H;
  SP8[20] := 00041000H; SP8[21] := 00040040H; SP8[22] := 10040040H; SP8[23] := 10041000H;
  SP8[24] := 00001040H; SP8[25] := 00000000H; SP8[26] := 00000000H; SP8[27] := 10040040H;
  SP8[28] := 10000040H; SP8[29] := 10001000H; SP8[30] := 00041040H; SP8[31] := 00040000H;
  SP8[32] := 00041040H; SP8[33] := 00040000H; SP8[34] := 10041000H; SP8[35] := 00001000H;
  SP8[36] := 00000040H; SP8[37] := 10040040H; SP8[38] := 00001000H; SP8[39] := 00041040H;
  SP8[40] := 10001000H; SP8[41] := 00000040H; SP8[42] := 10000040H; SP8[43] := 10040000H;
  SP8[44] := 10040040H; SP8[45] := 10000000H; SP8[46] := 00040000H; SP8[47] := 10001040H;
  SP8[48] := 00000000H; SP8[49] := 10041040H; SP8[50] := 00040040H; SP8[51] := 10000040H;
  SP8[52] := 10040000H; SP8[53] := 10001000H; SP8[54] := 10001040H; SP8[55] := 00000000H;
  SP8[56] := 10041040H; SP8[57] := 00041000H; SP8[58] := 00041000H; SP8[59] := 00001040H;
  SP8[60] := 00001040H; SP8[61] := 00040040H; SP8[62] := 10000000H; SP8[63] := 10041000H
END DES.

DES.Test
ÛBIER1aBañ`:ZÿÿÿÿCOberon10.Scn.Fnt05.01.03  21:37:28TimeStamps.New€
