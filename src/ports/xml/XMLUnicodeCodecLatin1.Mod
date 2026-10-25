MODULE XMLUnicodeCodecLatin1;

(*
Please check file ../Codec.Mod for the specifications.

Name: ISO_8859-1:1987                                    [RFC1345,KXS2]
MIBenum: 4
Source: ECMA registry
Alias: iso-ir-100
Alias: ISO_8859-1
Alias: ISO-8859-1 (preferred MIME name)
Alias: latin1
Alias: l1
Alias: IBM819
Alias: CP819
Alias: csISOLatin1
*)

IMPORT
  UC := XMLUnicodeCodec;


TYPE
  Codec* = POINTER TO CodecDesc;
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


PROCEDURE (codec: Codec) Decode* (VAR source: ARRAY OF CHAR;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR dest: ARRAY OF UC.Char;
                                  destStart, destEnd: LONGINT;
                                  VAR sourceDone, destDone: LONGINT);
  BEGIN
    IF (sourceEnd-sourceStart > destEnd-destStart) THEN
      sourceEnd := (destEnd-destStart)+sourceStart
    END;
    WHILE (sourceStart # sourceEnd) DO
      dest[destStart] := ORD (source[sourceStart]);
      INC (sourceStart);
      INC (destStart)
    END;
    sourceDone := sourceStart;
    destDone := destStart
  END Decode;

PROCEDURE (codec: Codec) Encode* (VAR source: ARRAY OF UC.Char;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR dest: ARRAY OF CHAR;
                                  destStart, destEnd: LONGINT;
                                  VAR sourceDone, destDone: LONGINT);
  VAR
    i, j, testSourceEnd: LONGINT;
    
  CONST
    offsetSource = UC.maxUCS2EncodingLength-1;

  BEGIN
    (* adjust the interval end to save some tiresome out of bounds checks
       in the main loop *)
    testSourceEnd := sourceEnd-offsetSource;
    
    (* iterate over all characters in the source interval *)
    i := sourceStart; j := destStart;
    WHILE (i < testSourceEnd) & (j # destEnd) DO
      IF (source[i] < 0) OR (source[i] > 0FFH) THEN
        INC (codec. invalidChars);
        dest[j] := UC.encodeError;
        IF (0D800H <= source[i]) & (source[i] < 0DC00H) &
           (0DC00H <= source[i+1]) & (source[i+1] < 0E000H) THEN
          INC (i, 2)                     (* skip over surrogate pair *)
        ELSE
          INC (i)
        END
      ELSE
        dest[j] := CHR (source[i]);
        INC (i)
      END;
      INC (j)
    END;
    
    IF (i = sourceStart) THEN
      (* if we did not encode a single character until now, then we _must_ 
         inspect the characters that we excluded above for convenience reasons;
         the pre condition guarantees us, that we can encode at least one
         character *)
      IF (0 <= source[i]) & (source[i] < 100H) THEN
        dest[j] := CHR (source[i])
      ELSE  (* out of range, or invalid surrogate; either way it's an error *)
        INC (codec. invalidChars);
        dest[j] := UC.encodeError
      END;
      INC (i); INC (j)
    END;
    sourceDone := i; destDone := j
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
  BEGIN
    sourceDone := sourceStart;
    RETURN New (f. bom)
  END NewCodecBOM;

PROCEDURE (f: Factory) GetEncodingName* (VAR name: ARRAY OF CHAR);
  BEGIN
    COPY ("ISO-8859-1", name)
  END GetEncodingName;

BEGIN
  NEW (factory);
  InitFactory (factory);
  
  UC.Register ("ISO_8859-1:1987", factory);
  UC.Register ("iso-ir-100", factory);
  UC.Register ("ISO_8859-1", factory);
  UC.Register ("ISO-8859-1", factory);  (* preferred MIME name *)
  UC.Register ("latin1", factory);
  UC.Register ("l1", factory);
  UC.Register ("IBM819", factory);
  UC.Register ("CP819", factory);
  UC.Register ("csISOLatin1", factory)
END XMLUnicodeCodecLatin1.
