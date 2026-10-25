MODULE TestCodecs;

IMPORT
  Out, Codec := XML:UnicodeCodec,
  XML:UnicodeCodec:Latin1, XML:UnicodeCodec:ASCII,
  XML:UnicodeCodec:UTF16, XML:UnicodeCodec:UTF8;

<* Assertions:=TRUE *>

TYPE
  LStringPtr = POINTER TO ARRAY OF LONGCHAR;
  StringPtr = POINTER TO ARRAY OF CHAR;

CONST
  errorEncode = "3F";
  errorDecode = "FFFD";

PROCEDURE HexToInt (ch: CHAR): LONGINT;
  BEGIN
    CASE ch OF
    | "0" .. "9": RETURN ORD(ch)-ORD("0")
    | "a" .. "f": RETURN ORD(ch)-(ORD("a")-10)
    | "A" .. "F": RETURN ORD(ch)-(ORD("A")-10)
    END
  END HexToInt;

PROCEDURE ToLString (str: ARRAY OF CHAR): LStringPtr;
  VAR
    i, j, c, val: LONGINT;
    s: LStringPtr;
  BEGIN
    i := 0; c := 0;
    WHILE (str[i] # 0X) DO
      IF (str[i] # " ") THEN
        INC (c)
      END;
      INC (i)
    END;
    
    ASSERT (c MOD 4 = 0);
    NEW (s, c DIV 4);
    
    i := 0; j := 0; c := 0; val := 0;
    WHILE (str[i] # 0X) DO
      IF (str[i] # " ") THEN
        val := val*16 + HexToInt (str[i]);
        INC (c);
        IF (c = 4) THEN
          s[j] := LONGCHR (val);
          c := 0;
          val := 0;
          INC (j)
        END
      END;
      INC (i)
    END;
    ASSERT (c = 0);
    ASSERT (j = LEN (s^));
    RETURN s
  END ToLString;

PROCEDURE ToString (str: ARRAY OF CHAR): StringPtr;
  VAR
    i, j, c, val: LONGINT;
    s: StringPtr;
  BEGIN
    i := 0; c := 0;
    WHILE (str[i] # 0X) DO
      IF (str[i] # " ") THEN
        INC (c)
      END;
      INC (i)
    END;
    
    ASSERT (c MOD 2 = 0);
    NEW (s, c DIV 2);
    
    i := 0; j := 0; c := 0; val := 0;
    WHILE (str[i] # 0X) DO
      IF (str[i] # " ") THEN
        val := val*16 + HexToInt (str[i]);
        INC (c);
        IF (c = 2) THEN
          s[j] := CHR (val);
          c := 0;
          val := 0;
          INC (j)
        END
      END;
      INC (i)
    END;
    ASSERT (c = 0);
    ASSERT (j = LEN (s^));
    RETURN s
  END ToString;

PROCEDURE WriteBytes (VAR ptr: ARRAY OF CHAR; s, e: LONGINT);
  VAR
    i: LONGINT;
  BEGIN
    i := s;
    WHILE (i # e) DO
      Out.Char (" ");
      Out.Hex (ORD (ptr[i]), 2);
      INC (i)
    END
  END WriteBytes;

PROCEDURE WriteBytesL (VAR ptr: ARRAY OF LONGCHAR; s, e: LONGINT);
  VAR
    i: LONGINT;
  BEGIN
    i := s;
    WHILE (i # e) DO
      Out.Char (" ");
      Out.Hex (ORD (ptr[i]), 4);
      INC (i)
    END
  END WriteBytesL;


PROCEDURE Decode (f: Codec.Factory; source, dest: ARRAY OF CHAR;
                  bom: BOOLEAN; errors: LONGINT);
  VAR
    sptr: StringPtr;
    dptr, dptrResult: LStringPtr;
    codec: Codec.Codec;
    i, sourceDone, destDone, bomDone: LONGINT;
  
  PROCEDURE Decode (VAR source: ARRAY OF CHAR;
                    sourceStart, sourceEnd: LONGINT;
                    VAR dest: ARRAY OF LONGCHAR;
                    destStart, destEnd: LONGINT;
                    VAR sourceDone, destDone: LONGINT);
    BEGIN
      ASSERT (sourceStart < sourceEnd);
      ASSERT (destEnd-destStart >= Codec.maxUCS2EncodingLength);
      IF (sourceEnd # LEN (source)) THEN
        ASSERT (sourceEnd-sourceStart >= Codec.maxUTF8EncodingLength)
      END;

      codec. Decode (source, sourceStart, sourceEnd,
                     dest, destStart, destEnd,
                     sourceDone, destDone);
      IF (sourceDone # sourceEnd) THEN
        Out.String ("[PARTIAL] ")
      END;
      Out.String ("Result bytes: ");
      WriteBytesL (dest, destStart, destDone); Out.Ln;
      IF (sourceDone = sourceEnd) THEN
        Out.Ln
      END;

      ASSERT (sourceStart < sourceDone);
      ASSERT (sourceDone <= sourceEnd);
      ASSERT (destStart < destDone);
      ASSERT (destDone <= destEnd);
      ASSERT ((sourceDone > sourceEnd-Codec.maxUTF8EncodingLength) OR
              (destDone > destEnd-Codec.maxUCS2EncodingLength));
      IF (sourceEnd-sourceStart < Codec.maxUTF8EncodingLength) THEN
        ASSERT (sourceDone = sourceEnd)
      END
    END Decode;
  
  BEGIN
    Out.String ("Byte sequence source: "); Out.String (source); Out.Ln;
    Out.String ("Decoded Unicode chars: "); Out.String (dest); Out.Ln;
    
    sptr := ToString (source);
    dptr := ToLString (dest);
    NEW (dptrResult, LEN (dptr^));
    ASSERT (LEN (sptr^) # 0);
    ASSERT (LEN (dptr^) # 0);
    
    IF bom THEN
      codec := f. NewCodecBOM (sptr^, 0, LEN (sptr^), bomDone)
    ELSE
      codec := f. NewCodec(); bomDone := 0
    END;
    Decode (sptr^, bomDone, LEN (sptr^),
            dptrResult^, 0, LEN (dptr^)+Codec.maxUCS2EncodingLength-1,
            sourceDone, destDone);
    IF (sourceDone # LEN (sptr^)) THEN
      Decode (sptr^, sourceDone, LEN (sptr^),
              dptrResult^, destDone, LEN (dptr^)+Codec.maxUCS2EncodingLength-1,
              sourceDone, destDone)
    END;
    
    ASSERT (sourceDone = LEN (sptr^));
    ASSERT (destDone = LEN (dptr^));
    ASSERT (codec. invalidChars = errors);
    i := 0;
    WHILE (i # LEN (dptr^)) & (dptr[i] = dptrResult[i]) DO
      INC (i)
    END;
    ASSERT (i = LEN (dptr^))
  END Decode;

PROCEDURE Encode (f: Codec.Factory; source, dest: ARRAY OF CHAR;
                  bom: BOOLEAN; errors: LONGINT);
  VAR
    sptr: LStringPtr;
    dptr, dptrResult: StringPtr;
    codec: Codec.Codec;
    i, sourceDone, destDone, bomDone: LONGINT;
    
  PROCEDURE Encode (VAR source: ARRAY OF LONGCHAR;
                    sourceStart, sourceEnd: LONGINT;
                    VAR dest: ARRAY OF CHAR;
                    destStart, destEnd: LONGINT;
                    VAR sourceDone, destDone: LONGINT);
    BEGIN
      ASSERT (sourceStart < sourceEnd);
      ASSERT (destEnd-destStart >= Codec.maxUTF8EncodingLength);
      IF (sourceEnd # LEN (source)) THEN
        ASSERT (sourceEnd-sourceStart >= Codec.maxUCS2EncodingLength)
      END;

      codec. Encode (source, sourceStart, sourceEnd,
                     dest, destStart, destEnd,
                     sourceDone, destDone);
      IF (sourceDone # sourceEnd) THEN
        Out.String ("[PARTIAL] ")
      END;
      Out.String ("Result bytes: ");
      WriteBytes (dest, destStart, destDone); Out.Ln;
      IF (sourceDone = sourceEnd) THEN
        Out.Ln
      END;

      ASSERT (sourceStart < sourceDone);
      ASSERT (sourceDone <= sourceEnd);
      ASSERT (destStart < destDone);
      ASSERT (destDone <= destEnd);
      ASSERT ((sourceDone > sourceEnd-Codec.maxUCS2EncodingLength) OR
              (destDone > destEnd-Codec.maxUTF8EncodingLength));
      IF (sourceEnd-sourceStart < Codec.maxUCS2EncodingLength) THEN
        ASSERT (sourceDone = sourceEnd)
      END
    END Encode;
  
  BEGIN
    Out.String ("Unicode source: "); Out.String (source); Out.Ln;
    Out.String ("Encoded bytes : "); Out.String (dest); Out.Ln;
    
    sptr := ToLString (source);
    dptr := ToString (dest);
    NEW (dptrResult, LEN (dptr^));
    ASSERT (LEN (sptr^) # 0);
    ASSERT (LEN (dptr^) # 0);
    
    codec := f. NewCodec();
    IF bom THEN
      codec. EncodeBOM (dptrResult^, 0,
                        LEN (dptr^)+Codec.maxUTF8EncodingLength-1, bomDone)
    ELSE
      bomDone := 0
    END;
    Encode (sptr^, 0, LEN (sptr^),
            dptrResult^, bomDone, LEN (dptr^)+Codec.maxUTF8EncodingLength-1,
             sourceDone, destDone);
    IF (sourceDone # LEN (sptr^)) THEN
      Encode (sptr^, sourceDone, LEN (sptr^),
              dptrResult^, destDone, LEN (dptr^)+Codec.maxUTF8EncodingLength-1,
              sourceDone, destDone)
    END;
    
    ASSERT (sourceDone = LEN (sptr^));
    ASSERT (destDone = LEN (dptr^));
    ASSERT (codec. invalidChars = errors);
    i := 0;
    WHILE (i # LEN (dptr^)) & (dptr[i] = dptrResult[i]) DO
      INC (i)
    END;
    ASSERT (i = LEN (dptr^))
  END Encode;

BEGIN
  (* LATIN1 *)
  Encode (Latin1.factory, "0020", "20", FALSE, 0);
  Encode (Latin1.factory, "0000", "00", FALSE, 0);
  Encode (Latin1.factory, "00FF", "FF", FALSE, 0);
  Encode (Latin1.factory, "0000 00FF", "00 FF", FALSE, 0);
  Encode (Latin1.factory, "0000 00FF", "00 FF", TRUE, 0);
  Encode (Latin1.factory, "0100", errorEncode, FALSE, 1);
  Encode (Latin1.factory, "1000 FFFF", errorEncode+errorEncode, FALSE, 2);
  Encode (Latin1.factory, "1000 0020 FFFF", errorEncode+" 20 "+errorEncode, FALSE, 2);
  Encode (Latin1.factory, "D800 DC00 0020", errorEncode+" 20", FALSE, 1);
  Encode (Latin1.factory, "0020 D800 DC00", "20 "+errorEncode, FALSE, 1);
  Encode (Latin1.factory, "0020 D800 D800 0020", "20 "+errorEncode+" "+errorEncode+" 20", FALSE, 2);
  Encode (Latin1.factory, "0020 D800 D800", "20 "+errorEncode+" "+errorEncode, FALSE, 2);
  Encode (Latin1.factory, "0020 DC00 D800", "20 "+errorEncode+" "+errorEncode, FALSE, 2);
  Encode (Latin1.factory, "0020 0100", "20 "+errorEncode, FALSE, 1);
  Encode (Latin1.factory, "0020 D800", "20 "+errorEncode, FALSE, 1);
  Encode (Latin1.factory, "0020 DC00", "20 "+errorEncode, FALSE, 1);
  
  Decode (Latin1.factory, "20", "0020", FALSE, 0);
  Decode (Latin1.factory, "00", "0000", FALSE, 0);
  Decode (Latin1.factory, "FF", "00FF", FALSE, 0);
  Decode (Latin1.factory, "FF", "00FF", TRUE, 0);
  
  (* ASCII *)
  Encode (ASCII.factory, "0020", "20", FALSE, 0);
  Encode (ASCII.factory, "0000", "00", FALSE, 0);
  Encode (ASCII.factory, "007F", "7F", FALSE, 0);
  Encode (ASCII.factory, "0000 007F", "00 7F", FALSE, 0);
  Encode (ASCII.factory, "0080", errorEncode, FALSE, 1);
  Encode (ASCII.factory, "1000 FFFF", errorEncode+" "+errorEncode, FALSE, 2);
  Encode (ASCII.factory, "1000 0020 FFFF", errorEncode+" 20 "+errorEncode, FALSE, 2);
  Encode (ASCII.factory, "D800 DC00 0020", errorEncode+" 20", FALSE, 1);
  Encode (ASCII.factory, "0020 D800 DC00", "20 "+errorEncode, FALSE, 1);
  Encode (ASCII.factory, "0020 D800 D800 0020", "20 "+errorEncode+" "+errorEncode+" 20", FALSE, 2);
  Encode (ASCII.factory, "0020 D800 D800", "20 "+errorEncode+" "+errorEncode, FALSE, 2);
  Encode (ASCII.factory, "0020 DC00 D800", "20 "+errorEncode+" "+errorEncode, FALSE, 2);
  Encode (ASCII.factory, "0020 0100", "20 "+errorEncode, FALSE, 1);
  Encode (ASCII.factory, "0020 D800", "20 "+errorEncode, FALSE, 1);
  Encode (ASCII.factory, "0020 DC00", "20 "+errorEncode, FALSE, 1);
  
  Decode (ASCII.factory, "20", "0020", FALSE, 0);
  Decode (ASCII.factory, "00", "0000", FALSE, 0);
  Decode (ASCII.factory, "7F", "007F", FALSE, 0);
  Decode (ASCII.factory, "80", errorDecode, FALSE, 1);
  Decode (ASCII.factory, "80 20 FF", errorDecode+" 0020 "+errorDecode, FALSE, 2);
  
  (* UTF-16 *)
  Encode (UTF16.factoryBE, "D808 DF45 003D 0052 0061",
                           "D808 DF45 003D 0052 0061", FALSE, 0);
  Encode (UTF16.factoryLE, "D808 DF45 003D 0052 0061",
                           "08D8 45DF 3D00 5200 6100", FALSE, 0);
  Encode (UTF16.factoryLE, "D808 0020",
                           errorEncode+"00 2000", FALSE, 1);
  Encode (UTF16.factoryLE, "D808 E000",
                           errorEncode+"00 00E0", FALSE, 1);
  Encode (UTF16.factoryLE, "D808 D808",
                           errorEncode+"00 "+errorEncode+"00", FALSE, 2);
  Encode (UTF16.factoryLE, "DC08 D808",
                           errorEncode+"00 "+errorEncode+"00", FALSE, 2);
  Encode (UTF16.factoryLE, "DC08",
                           errorEncode+"00", FALSE, 1);
  Encode (UTF16.factoryLE, "FFFE",
                           errorEncode+"00", FALSE, 1);
  Encode (UTF16.factoryLE, "FFFF",
                           errorEncode+"00", FALSE, 1);
  
  Encode (UTF16.factoryBE, "D808 0020",
                           "00"+errorEncode+" 0020", FALSE, 1);
  Encode (UTF16.factoryBE, "D808 E000",
                           "00"+errorEncode+" E000", FALSE, 1);
  Encode (UTF16.factoryBE, "D808 D808",
                           "00"+errorEncode+" 00"+errorEncode, FALSE, 2);
  Encode (UTF16.factoryBE, "DC08 D808",
                           "00"+errorEncode+" 00"+errorEncode, FALSE, 2);
  Encode (UTF16.factoryBE, "DC08",
                           "00"+errorEncode, FALSE, 1);
  
  Encode (UTF16.factoryLE, "D808 DF45 003D 0052 0061",
                           "08D8 45DF 3D00 5200 6100", TRUE, 0);
  Encode (UTF16.factory, "D808 DF45 003D 0052 0061",
                         "FEFF D808 DF45 003D 0052 0061", TRUE, 0);

  Decode (UTF16.factoryBE, "D808 DF45 003D 0052 0061",
                           "D808 DF45 003D 0052 0061", FALSE, 0);
  Decode (UTF16.factoryLE, "08D8 DF",
                           errorDecode, FALSE, 1);
  Decode (UTF16.factoryBE, "D808 DF",
                           errorDecode, FALSE, 1);
  Decode (UTF16.factoryLE, "2000 D0",
                           "0020 "+errorDecode, FALSE, 1);
  Decode (UTF16.factoryBE, "2000 D9",
                           "2000 "+errorDecode, FALSE, 1);
  Decode (UTF16.factoryLE, "00DC",
                           errorDecode, FALSE, 1);
  Decode (UTF16.factoryBE, "DC00",
                           errorDecode, FALSE, 1);
  Decode (UTF16.factoryBE, "FFFE",
                           errorDecode, FALSE, 1);
  Decode (UTF16.factoryBE, "FFFF",
                           errorDecode, FALSE, 1);
                           
  Decode (UTF16.factoryLE, "08D8 45DF 3D00 5200 6100",
                           "D808 DF45 003D 0052 0061", FALSE, 0);
  Decode (UTF16.factoryLE, "08D8 45DF 3D00 5200 6100",
                           "D808 DF45 003D 0052 0061", TRUE, 0);
  Decode (UTF16.factory, "D808 DF45 003D 0052 0061",
                         "D808 DF45 003D 0052 0061", FALSE, 0);
  Decode (UTF16.factory, "FEFF D808 DF45 003D 0052 0061",
                         "FEFF D808 DF45 003D 0052 0061", FALSE, 0);
  Decode (UTF16.factory, "FEFF D808 DF45 003D 0052 0061",
                         "D808 DF45 003D 0052 0061", TRUE, 0);
  Decode (UTF16.factory, "FFFE 08D8 45DF 3D00 5200 6100",
                         "D808 DF45 003D 0052 0061", TRUE, 0);
  
  (* UTF-8 *)
  Encode (UTF8.factory, "0041 2262 0391 002E", "41 E2 89 A2 CE 91 2E", FALSE, 0);
  Encode (UTF8.factory, "D55C AD6D C5B4", "ED 95 9C EA B5 AD EC 96 B4", FALSE, 0);
  Encode (UTF8.factory, "65E5 672C 8A9E", "E6 97 A5 E6 9C AC E8 AA 9E", FALSE, 0);
  Encode (UTF8.factory, "D800 DC00 007F", "F0 90 80 80 7F", FALSE, 0);
  Encode (UTF8.factory, "DBFF DFFD 007F", "F4 8F BF BD 7F", FALSE, 0);
  Encode (UTF8.factory, "0020 0800 0020", "20 E0 A0 80 20", FALSE, 0);
  Encode (UTF8.factory, "0020 0800", "20 E0 A0 80", FALSE, 0);
  Encode (UTF8.factory, "0020 FFFD 0020", "20 EF BF BD 20", FALSE, 0);
  Encode (UTF8.factory, "0020 FFFD", "20 EF BF BD", FALSE, 0);
  Encode (UTF8.factory, "0020 D800 0020", "20 "+errorEncode+" 20", FALSE, 1);
  Encode (UTF8.factory, "0020 DC00 0020", "20 "+errorEncode+" 20", FALSE, 1);
  Encode (UTF8.factory, "0020 D800", "20 "+errorEncode, FALSE, 1);
  Encode (UTF8.factory, "D800", errorEncode, FALSE, 1);
  Encode (UTF8.factory, "FFFE", errorEncode, FALSE, 1);
  Encode (UTF8.factory, "FFFF", errorEncode, FALSE, 1);
  
  Decode (UTF8.factory, "41 E2 89 A2 CE 91 2E", "0041 2262 0391 002E", FALSE, 0);
  Decode (UTF8.factory, "ED 95 9C EA B5 AD EC 96 B4", "D55C AD6D C5B4", FALSE, 0);
  Decode (UTF8.factory, "E6 97 A5 E6 9C AC E8 AA 9E", "65E5 672C 8A9E", FALSE, 0);
  Decode (UTF8.factory, "F0 90 80 80 7F", "D800 DC00 007F", FALSE, 0);
  Decode (UTF8.factory, "F4 8F BF BD 7F", "DBFF DFFD 007F", FALSE, 0);
  Decode (UTF8.factory, "20 E0 A0 80 20", "0020 0800 0020", FALSE, 0);
  Decode (UTF8.factory, "20 E0 A0 80", "0020 0800", FALSE, 0);
  Decode (UTF8.factory, "20 EF BF BD 20", "0020 FFFD 0020", FALSE, 0);
  Decode (UTF8.factory, "20 EF BF BD", "0020 FFFD", FALSE, 0);
  Decode (UTF8.factory, "20 80 80 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 80 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 D0 C0 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 C0 80 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 FE 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 FF 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 ED A0 80 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 ED BF BF 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 E0 9F BF 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 F0 8F BF BF 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 F8 87 BF BF BF 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 FC 83 BF BF BF BF 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 E0 C0 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "20 E0 00 20", "0020 "+errorDecode+" 0020", FALSE, 1);
  Decode (UTF8.factory, "41 E2 89", "0041 "+errorDecode, FALSE, 1);
  Decode (UTF8.factory, "41 E2", "0041 "+errorDecode, FALSE, 1);
  Decode (UTF8.factory, "F4 8F BF", errorDecode, FALSE, 1); 
  Decode (UTF8.factory, "EF BF BE", errorDecode, FALSE, 1); 
  Decode (UTF8.factory, "EF BF BF", errorDecode, FALSE, 1); 
END TestCodecs.
