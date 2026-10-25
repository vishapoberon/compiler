MODULE XMLUnicodeBuffer;

IMPORT
  Limits := XMLLimits,
  SYSTEM, Channel, Msg, LongStrings, Unicode := oocUnicode,
  InputBuffer := XMLInputBuffer, Codec := XMLUnicodeCodec;


TYPE
  Char* = Unicode.LONGCHAR;
  (**Character type used to represent the Unicode input data.  *)
  CharArray* = POINTER TO ARRAY OF Char;
  (**Character array of arbitrary length.  This type is used for the 
     character data of the input buffer.  *)
  CharPos* = LONGINT;
  (**UTF-16 code-unit position. The first code unit has position 0. *)
     
CONST
  markerEOB* = 0FFFEH;
  (**This is the character value that is used to mark the end of the Unicode
     buffer.  It is the first non-input character after the last valid document
     character in the buffer.  Because this character code is never produced
     by the Unicode decoders, testing against this character code gives
     a definitive answer.  Calling @oproc{Input.NextBlock} will replace
     the character with a valid character from the input document, or with
     @oconst{markerEOD}.  *)
  markerEOD* = 0FFFFH;
  (**This character value marks the end of the document.  It is the first
     non-input character after the last valid document character in the buffer.
     This character is never emitted by the Unicode decoders, and it is
     never replaced with another value.  *)
  markerError* = Codec.decodeError;
  (**This character is inserted into the processor output for characters that
     are not valid in XML.  *)
    
TYPE
  Input* = POINTER TO InputDesc;
  InputDesc = RECORD
    byteBuffer: InputBuffer.Buffer;
    byteEndOfData: BOOLEAN;
    bomSkip: LONGINT;
    codecFactory-: Codec.Factory;
    codec-: Codec.Codec;
    autoDetectedCodec-: BOOLEAN;
    
    chars-: CharArray;
    (**Character data from input channel.  *)
    offsetFromPos0-: CharPos;
    (**Offset of @samp{chars[0]} from the beginning of the input text.  *)
    endOfBuffer-: CharPos;
    (**Number of valid characters in @ofield{chars}.  All index values in the
       range [0..@ofield{endOfBuffer}-1] hold valid characters.  The value
       of @samp{chars[endOfBuffer]} is @oconst{markerEOB}.  *)
    discardable*: CharPos;
    (**The client can define here how many code units that have been read into
       the buffer will not be inspected again later, and can therefore be
       discarded by @oproc{Input.NextBlock}.  Possible values for this field
       are [0..@ofield{endOfBuffer}].  *)
    errList-: Msg.MsgList;
    (**Error messages are appended to this list.  *)
  END;

CONST
  charsPerRead = 4*1024;
  (* always read a multiple of @oconst{charsPerRead} characters from the input
     channel, >= Codec.maxUCS2EncodingLength *)
  offsetSizeOfBuffer = 32;
  sizeOfInputBuffer* = 4*charsPerRead-offsetSizeOfBuffer;(* must not be zero *)
  (* initial size of input buffer; the buffer will be extended when
     required; minumum is 4 bytes *)
  
(*CONST
  (* to test the buffer handling of the parser, set `charsPerRead' to 2
     and `sizeOfInputBuffer' successively to 4, 5, 6, 7; for each setting, run
     the full set of tests  *)
  charsPerRead = 2;
  sizeOfInputBuffer = 4;*)


CONST
  sizeOutputByteBuffer = 8*1024;
  sizeOutputUnicodeBuffer = sizeOutputByteBuffer;

TYPE
  Output* = POINTER TO OutputDesc;
  OutputDesc* = RECORD
    codecFactory-: Codec.Factory;
    codec-: Codec.Codec;
    (**Any encoding errors are signalled by incrementing
       @ofield{Codec.Codec.invalidChars}.  *)
    writer-: Channel.Writer;
    (**Write errors will set the field @ofield{Channel.Writer.res} to 
       something that isn't @oconst{Channel.done}.  *)
    
    byteBuffer: POINTER TO ARRAY sizeOutputByteBuffer OF CHAR;
    byteStart, byteEnd: LONGINT;
     unicodeBuffer: POINTER TO ARRAY sizeOutputUnicodeBuffer OF Char;
    unicodeEnd: LONGINT;
  END;


PROCEDURE AutodetectEnc (input: Input; VAR enc: ARRAY OF CHAR): LONGINT;
(* Do autodetection of used character encoding.  The guess should be good
   enough to get the parser through the encoding declaration, that may 
   revise the decision made here.  This procedure is based on Appendix F of
   the XML 1.0 Technical Report (more precisely, on the errata E44 that should
   go into the report's second edition).
   
   Bugfix: The UTF-16 rules with byte order mark in E44 break for the test file
   xmltest/valid/ext-sa/014.ent, which begins with 2 byte order marks; this is
   perfectly valid, therefore the implementation was changed from
     "FE FF 00 ##" and "FF FE ## 00"
   to
     ("FE FF 00 ##" or "FE FF ## 00" or "FE FF ## ##") and
     ("FF FE 00 ##" or "FF FE ## 00" or "FF FE ## ##")

   Result: An encoding identifier in @oparam{enc}, and the number of characters
     that make up the byte order mark (BOM), and that should be skipped in
     the input stream.  *)
  VAR
    skip: LONGINT;
    str: ARRAY 16 OF CHAR;
    x: InputBuffer.CharArray;
  BEGIN
    ASSERT (input. byteBuffer. offsetFromPos0 = 0);
    str := "UTF-8"; skip := 0; 
    x := input. byteBuffer. chars;
    IF (input. byteBuffer. endOfBuffer >= 4) THEN
      CASE x[0] OF
      | 000X:
        IF (x[1] = 0X) THEN
          IF (x[2] = 0X) & (x[3] = 3CX) THEN  (* UCS-4, 1234 order *)
            str := "UCS-4-1234"
          ELSIF (x[2] = 3CX) & (x[3] = 0X) THEN  (* UCS-4, 2143 order *)
            str := "UCS-4-2143"
          ELSIF (x[2] = 0FEX) & (x[3] = 0FFX) THEN(* UCS-4, 1234 order, BOM *)
            str := "UCS-4-1234"; skip := 4
          ELSIF (x[2] = 0FFX) & (x[3] = 0FEX) THEN(* UCS-4, 2143 order, BOM *)
            str := "UCS-4-2143"; skip := 4
          END
        ELSIF (x[1] = 3CX) & (x[2] = 0X) & (x[3] = 0X) THEN
          (* UCS-4, 3412 order *)
          str := "UCS-4-3412"
        ELSIF (x[1] = 3CX) & (x[2] = 0X) & (x[3] = 3FX) THEN  (* UTF-16LE *)
            str := "UTF-16BE"
        END
      | 03CX:
        IF (x[1] = 0X) THEN
          IF (x[2] = 0X) & (x[3] = 0X) THEN  (* UTF-16, 4321 order *)
            str := "UCS-4-4321"
          ELSIF (x[2] = 3FX) & (x[3] = 0X) THEN  (* UTF-16, little endian *)
            str := "UTF-16LE"
          END
        ELSIF (x[1] = 3FX) & (x[2] = 78X) & (x[3] = 6DX) THEN
          str := "UTF-8"
        END
      | 04CX:
        IF (x[1] = 6FX) & (x[2] = 0A7X) & (x[3] = 94X) THEN
          (* some variant of EBCDIC, code page can only be determined from
             encoding declaration *)
          str := "EBCDIC"
        END
      | 0EFX:
        IF (x[1] = 0BBX) & (x[2] = 0BFX) THEN
          (* UTF-8, with byte order mark *)
          str := "UTF-8"; skip := 3
        END
      | 0FEX:
        IF (x[1] = 0FFX) THEN
          IF (x[2] # 0X) OR (x[3] # 0X) THEN
            (* UTF-16 big endian, with byte order mark *)
            str := "UTF-16BE"; skip := 2
          ELSIF (x[2] = 0X) & (x[3] = 0X) THEN(* UCS-4, 3412 order, BOM *)
            str := "UCS-4-3412"; skip := 4
          END
        END
      | 0FFX:
        IF (x[1] = 0FEX) THEN
          IF (x[2] # 0X) OR (x[3] # 0X) THEN
            (* UTF-16 little endian, with byte order mark *)
            str := "UTF-16LE"; skip := 2
          ELSIF (x[2] = 0X) & (x[3] = 0X) THEN(* UCS-4, 4321 order, BOM *)
            str := "UCS-4-4321"; skip := 4
          END
        END
      ELSE  (* use default *)
      END
    ELSIF input. byteBuffer. endOfBuffer >= 2 THEN
      IF (x[0] = 0FEX) & (x[1] = 0FFX) THEN str := "UTF-16BE"; skip := 2
      ELSIF (x[0] = 0FFX) & (x[1] = 0FEX) THEN str := "UTF-16LE"; skip := 2
      ELSIF (input. byteBuffer. endOfBuffer >= 3) &
            (x[0] = 0EFX) & (x[1] = 0BBX) & (x[2] = 0BFX) THEN skip := 3
      END
    END;
    COPY (str, enc);
    RETURN skip
  END AutodetectEnc;
    

(*PROCEDURE WriteBuffer (in: Input);
  VAR
    i: LONGINT;
  BEGIN
    Out.String ("UNICODE BUFFER >>>");
    FOR i := 0 TO in. endOfBuffer-1 DO
      IF (in. chars[i] > 0FFX) THEN
        Out.Char("?")
      ELSE
        Out.Char(SHORT (in. chars[i]))
      END
    END;
    Out.String ("<<< EOB");
    Out.Ln;
  END WriteBuffer;*)

PROCEDURE (in: Input) NextBlock* (): BOOLEAN;
(**Tries to read additional data from @oparam{in}'s channel.  If at least one
   character could be read, result is @code{TRUE}.  @code{FALSE} means
   that not a single character was added to the buffer, either because the end
   of the file was reached, or because of a read error.  In the latter case,
   an message is added to @oparam{in}'s error list.
   
   A call to this buffer may change the fields @ofield{Input.chars},
   @ofield{Input.offsetFromPos0}, and @ofield{Input.endOfBuffer}.  If
   part of the buffer is discarded, @ofield{Input.discardable} is 
   set to zero.  *)
  VAR
    len, i: CharPos;
    nChars: CharArray;
  BEGIN
    IF (in. chars[in. endOfBuffer] = markerEOD) THEN
      RETURN FALSE
    END;
    (* Preserve a possibly incomplete encoded character until more bytes or
       the actual end of the stream are available. *)
    WHILE ~in. byteEndOfData &
          (in. byteBuffer. endOfBuffer-in. byteBuffer. discardable < Codec.maxUTF8EncodingLength) DO
      in. byteEndOfData := ~in. byteBuffer. NextBlock()
    END;
    
    ASSERT (in. chars[in. endOfBuffer] = markerEOB);
    ASSERT ((0 <= in. discardable) & (in. discardable <= in. endOfBuffer));
    IF (in. discardable >= charsPerRead) THEN
      (* move data to beginning of buffer *)
      len := in. endOfBuffer - in. discardable;
      (* Code-unit copies also handle overlapping ranges. *)
      FOR i := 0 TO len DO in. chars[i] := in. chars[in. discardable+i] END;
      ASSERT (in. offsetFromPos0 <= MAX (LONGINT)-in. discardable);
      INC (in. offsetFromPos0, in. discardable);
      in. endOfBuffer := len;
      in. discardable := 0
    END;
    ASSERT (in. chars[in. endOfBuffer] = markerEOB);

    IF (LEN (in. chars^)-in. endOfBuffer <= charsPerRead) THEN
      (* extend buffer so that it can hold in. endOfBuffer+charsPerRead+1 
         bytes *)
      len := LEN (in. chars^);
      REPEAT
        IF len <= MAX (LONGINT) DIV 2 THEN
          len := len*2
        ELSE
          ASSERT (len <= MAX (LONGINT)-charsPerRead);
          INC (len, charsPerRead)
        END
      UNTIL (len-in. endOfBuffer > charsPerRead);
      NEW (nChars, len);
      FOR i := 0 TO in. endOfBuffer DO nChars[i] := in. chars[i] END;
      in. chars := nChars
    END;
    
    IF (in. byteBuffer. discardable # in. byteBuffer. endOfBuffer) THEN
      (* append additional input to the buffer; at least one character
         is decoded *)
      in. codec. Decode (in. byteBuffer. chars^,
                     in. byteBuffer. discardable, in. byteBuffer. endOfBuffer,
                     in. chars^,
                     in. endOfBuffer, LEN (in. chars^)-1,
                     in. byteBuffer. discardable, in. endOfBuffer);
      in. chars[in. endOfBuffer] := markerEOB;
      RETURN TRUE
    ELSE                                 (* no further input *)
      in. chars[in. endOfBuffer] := markerEOD;
      RETURN FALSE
    END
  END NextBlock;

PROCEDURE (in: Input) Close*;
(**Closes the channel associated with buffer @oparam{in}.  Afterwards, no
   further operations are permitted on @oparam{in}, except for reading the
   field @ofield{Input.errList}.  *)
  BEGIN
    in. byteBuffer. Close;
    in. byteBuffer := NIL;
    in. codec := NIL;
    in. chars := NIL;
  END Close;

PROCEDURE (in: Input) SetCodec* (cf: Codec.Factory; autoDetect: BOOLEAN);
(* pre: in.byteBuffer.offsetFromPos0=0 *)
  VAR
    dummy: BOOLEAN;
    name: ARRAY 32 OF CHAR;
  BEGIN
    ASSERT (in. byteBuffer. offsetFromPos0 = 0);
    ASSERT (cf # NIL);
    in. codecFactory := cf;
    in. codec := cf. NewCodecBOM
      (in. byteBuffer. chars^, 0, in. byteBuffer. endOfBuffer,
        in. byteBuffer. discardable);
    cf. GetEncodingName (name);
    IF (name = "UTF-8") & (in. byteBuffer. endOfBuffer >= 3) &
       (in. byteBuffer. chars[0] = 0EFX) & (in. byteBuffer. chars[1] = 0BBX) &
       (in. byteBuffer. chars[2] = 0BFX) THEN in. bomSkip := 3 END;
    IF in. bomSkip > in. byteBuffer. discardable THEN
      in. byteBuffer. discardable := in. bomSkip
    END;
    in. chars[0] := markerEOB;
    in. discardable := 0;
    in. offsetFromPos0 := 0;
    in. endOfBuffer := 0;
    dummy := in. NextBlock();
    in. autoDetectedCodec := autoDetect
  END SetCodec;

PROCEDURE InitInput* (input: Input; new: BOOLEAN;
                      reader: Channel.Reader; codecFactory: Codec.Factory;
                      errList: Msg.MsgList);
  VAR
    encoding: ARRAY 256 OF CHAR;
    skip: LONGINT;
    autoDetect: BOOLEAN;
    progress: BOOLEAN;
    error: Msg.Msg;
    context: Msg.Context;
  BEGIN
    IF new THEN
      input. byteBuffer := InputBuffer.New (reader, errList);
      NEW (input. chars, sizeOfInputBuffer);
    ELSE
      HALT (127);
      (*input. byteBuffer. Reset (reader, errList)*)
    END;
    
    input. byteEndOfData := FALSE;
    input. bomSkip := 0;
    input. errList := errList;
    WHILE ~input. byteEndOfData & (input. byteBuffer. endOfBuffer < 4) DO
      progress := input. byteBuffer. NextBlock();
      input. byteEndOfData := ~progress
    END;
    
    autoDetect := FALSE;
    IF (codecFactory = NIL) THEN
      skip := AutodetectEnc (input, encoding);
      input. bomSkip := skip;
      codecFactory := Codec.GetFactory (encoding);
      IF codecFactory = NIL THEN
        NEW (context); Msg.InitContext (context, "XMLUnicodeBuffer");
        error := Msg.New (context, Channel.invalidFormat);
        error. SetStringAttrib ("encoding", Msg.GetStringPtr (encoding));
        errList. Append (error);
        input. codecFactory := NIL; input. codec := NIL;
        input. autoDetectedCodec := TRUE;
        input. discardable := 0; input. offsetFromPos0 := 0; input. endOfBuffer := 0;
        input. chars[0] := markerEOD;
        RETURN
      END;
      autoDetect := TRUE
    END;
    
    input. SetCodec (codecFactory, autoDetect);
  END InitInput;

(*PROCEDURE (input: Input) Reset* (reader: Channel.Reader; 
                                 codecFactory: Codec.Factory;
                                 errList: Msg.MsgList);
(**Resets the buffer @oparam{input} to its initial state.  This has the same
   effect as calling @oproc{NewInput} with the same parameters, except that
   some of the resources allocated by @oparam{input} are reused.

   Note: This method does not change the state of the reader @oparam{reader}.
   For example, if the reader should continue reading a file from its
   beginning, then it must be positioned @emph{before} this method is called.  *)
  BEGIN
    InitInput (input, FALSE, reader, codecFactory, errList)
  END Reset;*)

PROCEDURE NewInput* (reader: Channel.Reader; codecFactory: Codec.Factory;
                     errList: Msg.MsgList): Input;
(**Create new input buffer for reader @oparam{reader} and try to read the first
    block of data from it.  Returns an initialized input buffer with up to
    @oconst{sizeOfInputBuffer} characters of input. An unsupported detected
    encoding is reported in errList; the returned input is at end of document
    with NIL codec and codecFactory. Check errList before using codec metadata. *)
  VAR
    input: Input;
  BEGIN
    NEW (input);
    InitInput (input, TRUE, reader, codecFactory, errList);
    RETURN input
  END NewInput;

(* ------------------------------------------------------------------------ *)

PROCEDURE FlushBytes (out: Output);
  VAR count: LONGINT; context: Msg.Context;
  BEGIN
    WHILE (out. byteStart < out. byteEnd) & (out. writer. res = Channel.done) DO
      count := out. byteEnd-out. byteStart;
      out. writer. WriteBytes (out. byteBuffer^, out. byteStart, count);
      ASSERT ((0 <= out. writer. bytesWritten) & (out. writer. bytesWritten <= count));
      INC (out. byteStart, out. writer. bytesWritten);
      IF (out. writer. bytesWritten = 0) & (out. writer. res = Channel.done) THEN
        NEW (context); Msg.InitContext (context, "XMLUnicodeBuffer");
        out. writer. res := Msg.New (context, Channel.writeError)
      END
    END;
    IF out. byteStart = out. byteEnd THEN out. byteStart := 0; out. byteEnd := 0 END
  END FlushBytes;

PROCEDURE Encode (out: Output; all: BOOLEAN);
  VAR
    start, limit, i, len, done, written: LONGINT;
  BEGIN
    start := 0;
    limit := out. unicodeEnd;
    IF ~all & (limit > 0) & (0D800H <= out. unicodeBuffer[limit-1]) &
       (out. unicodeBuffer[limit-1] < 0DC00H) THEN
      DEC (limit) (* hold a possible split surrogate pair until the next write *)
    END;
    LOOP
      IF (start >= limit) OR (out. writer. res # Channel.done) THEN EXIT END;
      IF (LEN (out. byteBuffer^)-out. byteEnd < Codec.maxUTF8EncodingLength) THEN
        FlushBytes (out)
      END;
      IF out. writer. res # Channel.done THEN EXIT END;
      out. codec. Encode (out. unicodeBuffer^, start, limit,
                        out. byteBuffer^, out. byteEnd, LEN (out. byteBuffer^),
                         done, written);
      ASSERT ((start < done) & (done <= limit));
      ASSERT ((out. byteEnd < written) & (written <= LEN (out. byteBuffer^)));
      start := done; out. byteEnd := written
    END;
    len := out. unicodeEnd-start;
    FOR i := 0 TO len-1 DO out. unicodeBuffer[i] := out. unicodeBuffer[start+i] END;
    out. unicodeEnd := len
  END Encode;

PROCEDURE (out: Output) Write16I* (VAR str: ARRAY OF Char;
                                          start, end: CharPos);
(**Appends code units from [start..end[. The source is treated as read-only. *)
  VAR
    len: LONGINT;
  BEGIN
    ASSERT ((0 <= start) & (start <= end) & (end <= LEN (str)));
    LOOP
      IF (start >= end) OR (out. writer. res # Channel.done) THEN EXIT END;
      IF out. unicodeEnd = LEN (out. unicodeBuffer^) THEN Encode (out, FALSE) END;
      IF out. writer. res # Channel.done THEN EXIT END;
      len := LEN (out. unicodeBuffer^)-out. unicodeEnd;
      IF len > end-start THEN len := end-start END;
      SYSTEM.MOVE (SYSTEM.ADR (str[start]),
                   SYSTEM.ADR (out. unicodeBuffer[out. unicodeEnd]),
                   len*SIZE (Char));
      INC (out. unicodeEnd, len); INC (start, len)
    END
  END Write16I;

PROCEDURE (out: Output) Write8I* (VAR str: ARRAY OF CHAR;
                                   start, end: CharPos);
(**Widens Latin-1 octets from [start..end[. The source is treated as read-only. *)
  VAR
    pos, len: LONGINT;
  BEGIN
    ASSERT ((0 <= start) & (start <= end) & (end <= LEN (str)));
    LOOP
      IF (start >= end) OR (out. writer. res # Channel.done) THEN EXIT END;
      IF out. unicodeEnd = LEN (out. unicodeBuffer^) THEN Encode (out, FALSE) END;
      IF out. writer. res # Channel.done THEN EXIT END;
      len := LEN (out. unicodeBuffer^)-out. unicodeEnd;
      IF len > end-start THEN len := end-start END;
      pos := 0;
      WHILE pos < len DO
        out. unicodeBuffer[out. unicodeEnd+pos] := ORD (str[start]);
        INC (pos);
        INC (start)
      END;
      INC (out. unicodeEnd, len)
    END
  END Write8I;

PROCEDURE (out: Output) Write16* (VAR str: ARRAY OF Char);
  BEGIN
    out. Write16I (str, 0, LongStrings.Length (str))
  END Write16;

PROCEDURE (out: Output) Write8* (str: ARRAY OF CHAR);
  BEGIN
    out. Write8I (str, 0, LongStrings.Length8 (str))
  END Write8;

PROCEDURE (out: Output) SetLimits* (limits: Limits.Budget);
(**Applies an optional output-byte budget to buffered and subsequent output. *)
  BEGIN out. writer := Limits.WrapWriter (out. writer, limits) END SetLimits;

PROCEDURE (out: Output) Flush*;
(**Flushes the contents of the output buffer to the channel.  Then, flush is
   called on the channel itself.  *)
  BEGIN
    Encode (out, TRUE);
    FlushBytes (out);
    out. writer. base. Flush
  END Flush;

PROCEDURE InitOutput* (out: Output; new: BOOLEAN;
                       writer: Channel.Writer;
                       codecFactory: Codec.Factory; createBOM: BOOLEAN);
  BEGIN
    IF new THEN
      NEW (out. byteBuffer);
      NEW (out. unicodeBuffer);
    END;
    
    out. codecFactory := codecFactory;
    out. codec := codecFactory. NewCodec();
    out. writer := writer;
    out. byteStart := 0; out. byteEnd := 0;
    out. unicodeEnd := 0;
    
    IF createBOM THEN
      out. codec. EncodeBOM (out. byteBuffer^, out. byteEnd,
                             LEN (out. byteBuffer^), out. byteEnd)
    END
  END InitOutput;

(*PROCEDURE (output: Output) Reset* (writer: Channel.Writer; 
                                   codecFactory: Codec.Factory;
                                   createBOM: BOOLEAN);
(**Resets the buffer @oparam{output} to its initial state.  This has the same
   effect as calling @oproc{NewOutput} with the same parameters, except that
   some of the resources allocated by @oparam{output} are reused.

   Note: This method does not change the state of the writer @oparam{writer}.
   For example, if the writer should continue writing to the beginning of a
   file, then it should be positioned @emph{before} this method is called.  *)
  BEGIN
    InitOutput (output, FALSE, writer, codecFactory, createBOM)
  END Reset;*)

PROCEDURE NewOutput* (writer: Channel.Writer; codecFactory: Codec.Factory;
                      createBOM: BOOLEAN): Output;
(**Creates new output buffer for writer @oparam{writer}.  *)
  VAR
    output: Output;
  BEGIN
    NEW (output);
    InitOutput (output, TRUE, writer, codecFactory, createBOM);
    RETURN output
  END NewOutput;

BEGIN
  ASSERT (charsPerRead >= Codec.maxUCS2EncodingLength)
  END XMLUnicodeBuffer.
