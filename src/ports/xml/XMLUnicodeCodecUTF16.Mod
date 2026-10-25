MODULE XMLUnicodeCodecUTF16;

IMPORT
  UC := XMLUnicodeCodec;


(* Notes:

This module is based on Internet Draft <draft-hoffman-utf16.txt>,
"UTF-16, an encoding of ISO 10646", dated April 19, 1999.

A leading byte order mark is always passed to the application if the
NewCodec() function is used.  For detection of the optional byte order
mark, use NewCodecBOM().

Please check file ../Codec.Mod for the specifications.

*)


TYPE
  Codec = POINTER TO CodecDesc;
  CodecDesc = RECORD
    (UC.CodecDesc)
    bigEndian: BOOLEAN;
  END;

TYPE
  Factory* = POINTER TO FactoryDesc;
  FactoryDesc = RECORD
    (UC.FactoryDesc)
  END;

TYPE
  FactoryLE* = POINTER TO FactoryLEDesc;
  FactoryLEDesc = RECORD
    (UC.FactoryDesc)
  END;

TYPE
  FactoryBE* = POINTER TO FactoryBEDesc;
  FactoryBEDesc = RECORD
    (UC.FactoryDesc)
  END;


VAR
  factory-: Factory;
  factoryLE-: FactoryLE;
  factoryBE-: FactoryBE;


PROCEDURE InitBE (codec: Codec; bom: SHORTINT);
  BEGIN
    UC.Init (codec, bom);
    codec. bigEndian := TRUE
  END InitBE;

PROCEDURE NewBE (bom: SHORTINT): Codec;
  VAR
    c: Codec;
  BEGIN
    NEW (c);
    InitBE (c, bom);
    RETURN c
  END NewBE;

PROCEDURE InitLE (codec: Codec; bom: SHORTINT);
  BEGIN
    UC.Init (codec, bom);
    codec. bigEndian := FALSE
  END InitLE;

PROCEDURE NewLE (bom: SHORTINT): Codec;
  VAR
    c: Codec;
  BEGIN
    NEW (c);
    InitLE (c, bom);
    RETURN c
  END NewLE;


PROCEDURE (codec: Codec) Decode* (VAR source: ARRAY OF CHAR;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR dest: ARRAY OF UC.Char;
                                  destStart, destEnd: LONGINT;
                                  VAR sourceDone, destDone: LONGINT);
  VAR
    i, j, cval, testSourceEnd, testDestEnd, low, high: LONGINT;
  
  CONST
    offsetSource = UC.maxUTF8EncodingLength-1;
    offsetDest = UC.maxUCS2EncodingLength-1;
    
  PROCEDURE BytesPerEncoding (highChar: CHAR): LONGINT;
    BEGIN
      IF (0D8X <= highChar) & (highChar < 0DCX) THEN
        RETURN 4
      ELSE
        RETURN 2
      END
    END BytesPerEncoding;
  
  BEGIN
    IF codec. bigEndian THEN
      low := 1; high := 0
    ELSE
      low := 0; high := 1
    END;
    
    (* adjust the interval ends to save some tiresome out of bounds checks
       in the main loop *)
    testSourceEnd := sourceEnd-offsetSource;
    testDestEnd := destEnd-offsetDest;
    
    (* iterate over all characters in the source interval *)
    i := sourceStart; j := destStart;
    WHILE (i < testSourceEnd) & (j < testDestEnd) DO
      cval := LONG (ORD (source[i+high]))*256 + ORD (source[i+low]);
      IF (cval < 0D800H) OR (cval >= 0E000H) & (cval < 0FFFEH) THEN
        (* a Unicode character encoded in 2 bytes *)
         dest[j] := cval; INC (i, 2); INC (j)
      ELSIF (cval < 0DC00H) &
            (0DCX <= source[i+2+high]) & (source[i+2+high] < 0E0X) THEN
        (* a Unicode character encoded as a (high, low) surrogate pair *)
        dest[j] := cval;
        dest[j+1] := LONG (ORD (source[i+2+high]))*256 + ORD (source[i+2+low]);
        INC (i, 4); INC (j, 2)
      ELSE
        (* error: character from low surrogate area, or invalid FFFE or FFFF *)
        INC (codec. invalidChars);
        dest[j] := UC.decodeError; INC (i, 2); INC (j)
      END
    END;
    
    IF (i = sourceStart) THEN
      (* if we did not decode a single character until now, then we _must_ 
         inspect the characters that we excluded above for convenience reasons;
         the pre condition guarantees us, that we can decode at least one
         character *)
      WHILE (i+1 < sourceEnd) &
            (i+BytesPerEncoding (source[i+high]) <= sourceEnd) DO
        INC (i, BytesPerEncoding (source[i+high]))
      END;
      IF (i # sourceStart) THEN
        (* try to decode all the complete characters left in source *)
        codec. Decode (source, sourceStart, i+offsetSource,
                       dest, j, destEnd+offsetDest,
                       sourceDone, destDone)
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
  END Decode;

PROCEDURE (codec: Codec) Encode* (VAR source: ARRAY OF UC.Char;
                                    sourceStart, sourceEnd: LONGINT;
                                    VAR dest: ARRAY OF CHAR;
                                    destStart, destEnd: LONGINT;
                                    VAR sourceDone, destDone: LONGINT);
  VAR
    i, j, testSourceEnd, testDestEnd, low, high: LONGINT;
    
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
    IF codec. bigEndian THEN
      low := 1; high := 0
    ELSE
      low := 0; high := 1
    END;
    
    (* adjust the interval ends to save some tiresome out of bounds checks
       in the main loop *)
    testSourceEnd := sourceEnd-offsetSource;
    testDestEnd := destEnd-offsetDest;
    
    (* iterate over all characters in the source interval *)
    i := sourceStart; j := destStart;
    WHILE (i < testSourceEnd) & (j < testDestEnd) DO
      IF (source[i] < 0) OR (source[i] > 0FFFFH) THEN
        INC (codec. invalidChars);
        dest[j+high] := 0X; dest[j+low] := UC.encodeError;
        INC (i); INC (j, 2)
      ELSE
        dest[j+high] := CHR (source[i] DIV 256);
        dest[j+low] := CHR (source[i] MOD 256);
        IF (source[i] < 0D800H) OR
           (source[i] >= 0E000H) & (source[i] < 0FFFEH) THEN
          INC (i); INC (j, 2)
        ELSIF (source[i] < 0DC00H) &
              (0DC00H <= source[i+1]) & (source[i+1] < 0E000H) THEN
          dest[j+2+high] := CHR (source[i+1] DIV 256);
          dest[j+2+low] := CHR (source[i+1] MOD 256);
          INC (i, 2); INC (j, 4)
        ELSE
          INC (codec. invalidChars);
          dest[j+high] := CHR (ORD (UC.encodeError) DIV 256);
          dest[j+low] := CHR (ORD (UC.encodeError) MOD 256);
          INC (i); INC (j, 2)
        END
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
        dest[destDone+high] := CHR (ORD (UC.encodeError) DIV 256);
        dest[destDone+low] := CHR (ORD (UC.encodeError) MOD 256);
        INC (destDone, 2);
        sourceDone := sourceEnd
      END
    ELSE
      sourceDone := i; destDone := j
    END
  END Encode;



PROCEDURE InitFactory (f: Factory);
  BEGIN
    UC.InitFactory (f, UC.bomOptional)
  END InitFactory;

PROCEDURE (f: Factory) NewCodec* (): UC.Codec;
  BEGIN
    RETURN NewBE (f. bom)
  END NewCodec;

PROCEDURE (f: Factory) NewCodecBOM* (VAR source: ARRAY OF CHAR;
                                     sourceStart, sourceEnd: LONGINT;
                                     VAR sourceDone: LONGINT): UC.Codec;
  BEGIN
    IF (sourceStart+1 < sourceEnd) THEN
      IF (source[sourceStart] = 0FFX) &
         (source[sourceStart+1] = 0FEX) THEN
        sourceDone := sourceStart+2;
        RETURN NewLE (f. bom)
      ELSIF (source[sourceStart] = 0FEX) &
            (source[sourceStart+1] = 0FFX) THEN
        sourceDone := sourceStart+2;
        RETURN NewBE (f. bom)
      END
    END;
    (* default: no byte order mark, assume big endian *)
    sourceDone := sourceStart;
    RETURN NewBE (f. bom)
  END NewCodecBOM;

PROCEDURE (f: Factory) GetEncodingName* (VAR name: ARRAY OF CHAR);
  BEGIN
    COPY ("UTF-16", name)
  END GetEncodingName;


PROCEDURE InitFactoryLE (f: FactoryLE);
  BEGIN
    UC.InitFactory (f, UC.bomNotApplicable)
  END InitFactoryLE;

PROCEDURE (f: FactoryLE) NewCodec* (): UC.Codec;
  BEGIN
    RETURN NewLE (f. bom)
  END NewCodec;

PROCEDURE (f: FactoryLE) NewCodecBOM* (VAR source: ARRAY OF CHAR;
                                       sourceStart, sourceEnd: LONGINT;
                                       VAR sourceDone: LONGINT): UC.Codec;
  VAR
    codec: UC.Codec;
  BEGIN
    sourceDone := sourceStart;
    codec := NewLE (f. bom);
    IF (sourceStart+1 < sourceEnd) THEN
      IF (source[sourceStart] = 0FEX) &
         (source[sourceStart+1] = 0FFX) THEN (* swapped BOM? *)
        INC (codec. invalidChars)
      ELSIF (source[sourceStart] = 0FFX) &
            (source[sourceStart+1] = 0FEX) THEN
        INC (sourceDone, 2)
      END
    END;
    RETURN codec
  END NewCodecBOM;

PROCEDURE (f: FactoryLE) GetEncodingName* (VAR name: ARRAY OF CHAR);
  BEGIN
    COPY ("UTF-16LE", name)
  END GetEncodingName;


PROCEDURE InitFactoryBE (f: FactoryBE);
  BEGIN
    UC.InitFactory (f, UC.bomNotApplicable)
  END InitFactoryBE;

PROCEDURE (f: FactoryBE) NewCodec* (): UC.Codec;
  BEGIN
    RETURN NewBE (f. bom)
  END NewCodec;

PROCEDURE (f: FactoryBE) NewCodecBOM* (VAR source: ARRAY OF CHAR;
                                       sourceStart, sourceEnd: LONGINT;
                                       VAR sourceDone: LONGINT): UC.Codec;
  VAR
    codec: UC.Codec;
  BEGIN
    sourceDone := sourceStart;
    codec := NewBE (f. bom);
    IF (sourceStart+1 < sourceEnd) THEN
      IF (source[sourceStart] = 0FFX) &
         (source[sourceStart+1] = 0FEX) THEN (* swapped BOM? *)
        INC (codec. invalidChars)
      ELSIF (source[sourceStart] = 0FEX) &
            (source[sourceStart+1] = 0FFX) THEN
        INC (sourceDone, 2)
      END
    END;
    RETURN codec
  END NewCodecBOM;

PROCEDURE (f: FactoryBE) GetEncodingName* (VAR name: ARRAY OF CHAR);
  BEGIN
    COPY ("UTF-16BE", name)
  END GetEncodingName;

BEGIN
  NEW (factory);
  InitFactory (factory);
  UC.Register ("UTF-16", factory);
  
  NEW (factoryLE);
  InitFactoryLE (factoryLE);
  UC.Register ("UTF-16LE", factoryLE);
  
  NEW (factoryBE);
  InitFactoryBE (factoryBE);
  UC.Register ("UTF-16BE", factoryBE);
END XMLUnicodeCodecUTF16.
