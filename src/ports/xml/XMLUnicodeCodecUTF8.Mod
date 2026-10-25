MODULE XMLUnicodeCodecUTF8;

IMPORT
  UC := XMLUnicodeCodec;


(* Notes:

This module is based on RFC 2279 "UTF-8, a transformation format of
ISO 10646".

UCS-4 characters values >0x10FFFF, 0xFFFE, and 0xFFFF are reported as
errors during decoding or encoding.

Please check file ../Codec.Mod for the specifications.

*)


TYPE
  Codec = POINTER TO CodecDesc;
  CodecDesc = RECORD
    (UC.CodecDesc)
  END;

TYPE
  Factory* = POINTER TO FactoryDesc;
  FactoryDesc = RECORD
    (UC.FactoryDesc)
  END;

VAR
  factory-: Factory;


PROCEDURE Init (codec: Codec; bom: SHORTINT);
  BEGIN
    UC.Init (codec, bom)
  END Init;

PROCEDURE New (bom: SHORTINT): Codec;
  VAR
    c: Codec;
  BEGIN
    NEW (c);
    Init (c, bom);
    RETURN c
  END New;

PROCEDURE DecodeBytes (codec: Codec; VAR source: ARRAY OF CHAR;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR dest: ARRAY OF UC.Char;
                                  destStart, destEnd: LONGINT;
                                  VAR sourceDone, destDone: LONGINT;
                                  logicalEnd: LONGINT);
  VAR
    i, j, cval, low, bytes, testSourceEnd, testDestEnd: LONGINT;
  
  CONST
    offsetSource = UC.maxUTF8EncodingLength-1;
    offsetDest = UC.maxUCS2EncodingLength-1;
    
  PROCEDURE BytesPerEncoding (ch: CHAR): LONGINT;
    BEGIN
      CASE ch OF
      | 000X .. 07FX: RETURN 1
      | 0C0X .. 0DFX: RETURN 2
      | 0E0X .. 0EFX: RETURN 3
      | 0F0X .. 0F7X: RETURN 4
      | 0F8X .. 0FBX: RETURN 5
      | 0FCX .. 0FDX: RETURN 6
      ELSE
        RETURN 1                         (* invalid *)
      END
    END BytesPerEncoding;
  
  PROCEDURE Invalid (offset: LONGINT);
    BEGIN
      INC (codec. invalidChars);
      dest[j] := UC.decodeError;
      INC (j); INC (i, offset);
      (* Keep upstream's replacement grouping inside the caller's interval,
         independently of the short-buffer fallback's padded loop bound. *)
      WHILE (i < logicalEnd) & (80X <= source[i]) & (source[i] < 0C0X) DO INC (i) END
    END Invalid;
  
  BEGIN
    (* adjust the interval ends to save some tiresome out of bounds checks
       in the main loop *)
    testSourceEnd := sourceEnd-offsetSource;
    testDestEnd := destEnd-offsetDest;
    
    (* iterate over all characters in the source interval *)
    i := sourceStart; j := destStart;
    WHILE (i < testSourceEnd) & (j < testDestEnd) DO
      (* it is expected that input data either consists largely of ASCII
         characters with a low portion of non-ASCII in between, or mostly
         of non-ASCII characters with a low portion of ASCII in betwenn;
         therefore, we decoding into two loops that effectively handle one
         of the "common" cases *)
         
      (* loop over ASCII characters *)
      WHILE (i < testSourceEnd) & (j < testDestEnd) & (source[i] < 80X) DO
        dest[j] := ORD (source[i]);
        INC (i); INC (j)
      END;
      
      (* loop over non-ASCII characters *)
      WHILE (i < testSourceEnd) & (j < testDestEnd) & (source[i] >= 80X) DO
        IF (source[i] < 0C0X) THEN      (* invalid encoding *)
          Invalid (1)
        ELSIF (source[i] < 0E0X) THEN      (* 2 byte encoding *)
          IF (ORD (source[i+1]) DIV 64 # 2) THEN
            Invalid (2)
          ELSE
            dest[j] := (ORD (source[i]) MOD 32)*64 + ORD (source[i+1]) MOD 64;
            IF (dest[j] < 80H) THEN
              dest[j] := UC.decodeError;
              INC (codec. invalidChars)
            END;
            INC (i, 2);
            INC (j)
          END
        ELSIF (source[i] >= 0FEX) THEN     (* invalid encoding 0FEX or 0FFX *)
          Invalid (1)
        ELSE                               (* 3 to 6 byte encoding *)
          (* determine the length of the encoding and the lower bound on
             the range of valid values; initialize `cval' with the bits
             from the first byte; note that the last two cases represent
             valid UCS-4 characters, but the result code cannot be represented
             in the Unicode range [0H, 10FFFFH] *)
          CASE source[i] OF
          | 0E0X .. 0EFX:
            cval := ORD (source[i]) MOD 16; bytes := 2; low :=    0800H;
          | 0F0X .. 0F7X:
            cval := ORD (source[i]) MOD  8; bytes := 3; low :=   10000H;
          | 0F8X .. 0FBX:
            cval := ORD (source[i]) MOD  4; bytes := 4; low :=  200000H;
          | 0FCX .. 0FDX:
            cval := ORD (source[i]) MOD  2; bytes := 5; low := 4000000H;
          ELSE HALT (127) (* guarded above: only E0..FD can reach this CASE *)
          END;

          (* iterate over the octets 2, 3, .., 6 *)
          REPEAT
            INC (i);
            IF (ORD (source[i]) DIV 64 # 2) THEN (* invalid octet *)
              bytes := -1
            ELSE
              cval := cval*64 + ORD (source[i]) MOD 64;
              DEC (bytes)
            END
          UNTIL (bytes <= 0);
          INC (i);

          IF (bytes < 0) OR                (* invalid octet in between *)
             (cval < low) OR               (* value out of range *)
             (0D800H <= cval) & (cval < 0E000H) OR (* surrogate *)
             (cval = 0FFFEH) OR (cval = 0FFFFH) OR (* invalid chars *)
             (cval >= 110000H) THEN        (* out of range for UCS-2 *)
            dest[j] := UC.decodeError;
            INC (codec. invalidChars);
            INC (j)
          ELSIF (cval <= 0FFFFH) THEN      (* encode as single Unicode char *)
            dest[j] := cval;
            INC (j)
          ELSE                             (* split into high/low surrogate *)
            DEC (cval, 10000H);
            dest[j] := 0D800H + cval DIV 1024;
            dest[j+1] := 0DC00H + cval MOD 1024;
            INC (j, 2)
          END
        END
      END
    END;
    
    IF (i = sourceStart) THEN
      (* if we did not decode a single character until now, then we _must_ 
         inspect the characters that we excluded above for convenience reasons;
         the pre condition guarantees us, that we can decode at least one
         character *)
      WHILE (i # sourceEnd) & (i+BytesPerEncoding (source[i]) <= sourceEnd) DO
        INC (i, BytesPerEncoding (source[i]))
      END;
      IF (i # sourceStart) THEN
        (* try to decode all the complete characters left in source *)
        DecodeBytes (codec, source, sourceStart, i+offsetSource,
                        dest, j, destEnd+offsetDest,
                        sourceDone, destDone, logicalEnd)
      ELSE
        sourceDone := i; destDone := destStart
      END;
      
      IF (sourceDone = i) & (sourceDone # sourceEnd) & (destDone# destEnd) THEN
        (* done decoding the complete chars, but there are still some bytes
           left of an incomplete character *)
        INC (codec. invalidChars);
        dest[destDone] := UC.decodeError;
        INC (destDone);
        sourceDone := sourceEnd
      END
    ELSE
      sourceDone := i; destDone := j
    END
  END DecodeBytes;

PROCEDURE (codec: Codec) Decode* (VAR source: ARRAY OF CHAR;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR dest: ARRAY OF UC.Char;
                                  destStart, destEnd: LONGINT;
                                  VAR sourceDone, destDone: LONGINT);
  BEGIN
    DecodeBytes (codec, source, sourceStart, sourceEnd, dest, destStart, destEnd,
                 sourceDone, destDone, sourceEnd)
  END Decode;

PROCEDURE (codec: Codec) Encode* (VAR source: ARRAY OF UC.Char;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR dest: ARRAY OF CHAR;
                                  destStart, destEnd: LONGINT;
                                  VAR sourceDone, destDone: LONGINT);
  VAR
    i, j, cval, testSourceEnd, testDestEnd: LONGINT;
    
  CONST
    offsetSource = UC.maxUCS2EncodingLength-1;
    offsetDest = UC.maxUTF8EncodingLength-1;
    
  PROCEDURE WordsPerEncoding (ch: UC.Char): LONGINT;
    BEGIN
      IF (0D800H <= ch) & (ch < 0DC00H) THEN
        RETURN 2
      ELSE
        RETURN 1
      END
    END WordsPerEncoding;
  
  BEGIN
    (* adjust the interval ends to save some tiresome out of bounds checks
       in the main loop *)
    testSourceEnd := sourceEnd-offsetSource;
    testDestEnd := destEnd-offsetDest;
    
    (* iterate over all characters in the source interval *)
    i := sourceStart; j := destStart;
    WHILE (i < testSourceEnd) & (j < testDestEnd) DO
      IF source[i] < 0 THEN
        INC (codec. invalidChars); dest[j] := UC.encodeError;
        INC (i); INC (j)
      ELSIF (source[i] < 80H) THEN          (* 1 byte encoding *)
        dest[j] := CHR (source[i]);
        INC (i); INC (j)
      ELSIF (source[i] < 0800H) THEN     (* 2 byte encoding *)
        dest[j] := CHR (192+source[i] DIV 64);
        dest[j+1] := CHR (128+source[i] MOD 64);
        INC (i); INC (j, 2)
      ELSIF (0D800H <= source[i]) & (source[i] < 0DC00H) THEN
        (* high level surrogate area: should be followed by low level;
           this is mapped to a 4 byte encoding *)
        IF (0DC00H <= source[i+1]) & (source[i+1] < 0E000H) THEN
          cval := source[i] MOD 1024*1024 + source[i+1] MOD 1024 + 10000H;
          dest[j] := CHR (0F0H + ASH (cval, -3*6));
          dest[j+1] := CHR (ASH (cval, -2*6) MOD 64 + 128);
          dest[j+2] := CHR (ASH (cval, -1*6) MOD 64 + 128);
          dest[j+3] := CHR (cval MOD 64 + 128);
          INC (i, 2); INC (j, 4)
        ELSE  (* high surrogate not followed by low surrogate *)
          INC (codec. invalidChars);
          dest[j] := UC.encodeError;
          INC (i); INC (j)
        END
      ELSIF (0DC00H <= source[i]) & (source[i] < 0E000H) OR
            (source[i] >= 0FFFEH) THEN
        (* character from low surrogate area, or invalid char: error *)
        INC (codec. invalidChars);
        dest[j] := UC.encodeError;
        INC (i); INC (j)
      ELSE                               (* 3 byte encoding *)
        cval := source[i];
        dest[j] := CHR (0E0H + ASH (cval, -2*6));
        dest[j+1] := CHR (ASH (cval, -1*6) MOD 64 + 128);
        dest[j+2] := CHR (cval MOD 64 + 128);
        INC (i); INC (j, 3)
      END
    END;
    
    IF (i = sourceStart) THEN
      (* if we did not encode a single character until now, then we _must_ 
         inspect the characters that we excluded above for convenience reasons;
         the pre condition guarantees us, that we can encode at least one
         character *)
      WHILE (i # sourceEnd) & (i+WordsPerEncoding (source[i]) <= sourceEnd) DO
        INC (i, WordsPerEncoding (source[i]))
      END;
      (* try to encode all the complete characters left in source *)
      IF (i # sourceStart) THEN
        codec. Encode (source, sourceStart, i+offsetSource,
                       dest, destStart, destEnd+offsetDest,
                       sourceDone, destDone)
      ELSE
        sourceDone := i; destDone := destStart
      END;
      
      IF (sourceDone = i) & (sourceDone # sourceEnd) &(destDone # destEnd) THEN
        (* done decoding the complete chars, but there are still some bytes
           left of an incomplete character *)
        INC (codec. invalidChars);
        dest[destDone] := UC.encodeError;
        INC (destDone);
        sourceDone := sourceEnd
      END
    ELSE
      sourceDone := i; destDone := j
    END
  END Encode;


PROCEDURE InitFactory (f: Factory);
  BEGIN
    UC.InitFactory (f, UC.bomNotApplicable)
  END InitFactory;

PROCEDURE (f: Factory) NewCodec* (): UC.Codec;
  BEGIN
    RETURN New (f. bom)
  END NewCodec;

PROCEDURE (f: Factory) NewCodecBOM* (VAR source: ARRAY OF CHAR;
                                     sourceStart, sourceEnd: LONGINT;
                                     VAR sourceDone: LONGINT): UC.Codec;
  VAR
    codec: UC.Codec;
  BEGIN
    sourceDone := sourceStart;
    codec := New(f. bom);
(*    IF (sourceStart+2 < sourceEnd) &
       (source[sourceStart] = 0EFX) &
       (source[sourceStart+1] = 0BBX) &
       (source[sourceStart+2] = 0BFX)THEN (* skip BOM *)
      INC (sourceDone, 3)
    END;*)
    RETURN codec
  END NewCodecBOM;

PROCEDURE (f: Factory) GetEncodingName* (VAR name: ARRAY OF CHAR);
  BEGIN
    COPY ("UTF-8", name)
  END GetEncodingName;

BEGIN
  NEW (factory);
  InitFactory (factory);
  
  UC.Register ("UTF-8", factory);
END XMLUnicodeCodecUTF8.
