MODULE XMLUnicodeCodec;

IMPORT
  Strings, Unicode := oocUnicode;


CONST
  decodeError* = 0FFFDH;
  (**This character is used to replace incoming characters whose value is
     unknown or unrepresentable in Unicode.  This character is assigned the
     Unicode name "REPLACEMENT CHARACTER".  *)
  encodeError* = "?";
  (**This character is used to replace outgoing characters whose value cannot
     be represented by the used encoding scheme.  It is assumed, that all
     character encodings know the question mark character (Unicode Ux003F).  *)
  byteOrderMark* = 0FEFFH;
  (**The Unicode byte order mark.  Also known as
     @samp{ZERO WIDTH NO-BREAK SPACE}.  *)

CONST
  bomNotApplicable* = 0;
  (**Byte order markers are not applicable to the encoding.  This is the case
     if the encoding
     
     @itemize
     @item
     maps all characters to single bytes (like @samp{US-ASCII} or
     @samp{ISO-8859-1}),
     
     @item
     is byte order independent (like @samp{UTF-8}), or
     
     @item
     defines the byte order explicitly and @emph{requires} that the document
     does not start with a byte order mark (like @samp{UTF-16LE} and
     @samp{UTF-16BE}).
     @end itemize
     
     All instances of UxFEFF are passed to the application, regardless of
     their position in the document.  Therefore, if a document using such
     an encoding begins with UxFEFF, this character is reported to the
     application as @samp{ZERO WIDTH NO-BREAK SPACE}.  *)
   bomOptional* = 1;
   (**A document using this encoding @emph{may} begin with a byte order mark.
      Without a byte order mark, a encoding specific default byte order is
      assumed.  An example is @samp{UTF-16}, which defaults to big endian
      byte order in the absence of a byte order mark.  If a document begins
      with a byte order mark, then this first character should not be
      reported to the application.  *)
   bomRequired* = 2;
   (**The encoding requires that the document begins with a byte order mark.
      The BOM should not be passed to the application.  Currently, no codec
      implementation uses this variant.  *)

CONST
  maxUTF8EncodingLength* = 6;
  (**Maximum length of the character encodings of all possible UCS-4 
     (@emph{not} just Unicode!) characters, for all known encodings.
     Currently, the longest encoding in UTF-8 needs 6 bytes.  *)
  maxUCS2EncodingLength* = 2;
  (**Maximum length of any UCS-4 character, encoded with Unicode codes.
     In the worst case, a pair of high and low surrogate codes must be
     used.  *)
  
TYPE
  Char* = Unicode.LONGCHAR;

  Factory* = POINTER TO FactoryDesc;
  FactoryDesc* = RECORD
    bom-: SHORTINT;
    (**This flag describes how the generated codes deal with byte order
       markers.  It can be one of @oconst{bomNotApplicable},
       @oconst{bomOptional}, or @oconst{bomRequired}.  *)
  END;

TYPE
  Codec* = POINTER TO CodecDesc;
  CodecDesc* = RECORD
    invalidChars*: LONGINT;
    bom-: SHORTINT;
    (**This is a copy of the creating factory's @ofield{Factory.bom}.  *)
  END;
 

TYPE
  Node = POINTER TO NodeDesc;
  NodeDesc = RECORD
    next: Node;
    name: POINTER TO ARRAY OF CHAR;
    factory: Factory;
  END;
  
VAR
  factoryList: Node;
  

PROCEDURE Init* (codec: Codec; bom: SHORTINT);
  BEGIN
    codec. invalidChars := 0;
    codec. bom := bom;
  END Init;

PROCEDURE (codec: Codec) Decode* (VAR source: ARRAY OF CHAR;
                                             sourceStart, sourceEnd: LONGINT;
                                             VAR dest: ARRAY OF Char;
                                             destStart, destEnd: LONGINT;
                                             VAR sourceDone,destDone: LONGINT);
(**Decodes the bytes in @samp{@oparam{source}[@oparam{sourceStart}, 
   @oparam{sourceEnd}[} into the Unicode sequence
   @samp{@oparam{dest}[@oparam{destStart}, @oparam{destEnd}[}.
   
   @precond
   @itemize
   @item
   @oparam{sourceStart} < @oparam{sourceEnd}, and the character sequence
   @samp{@oparam{source}[@oparam{sourceStart}, @oparam{sourceEnd}[} holds
   the characters that are to be decoded.
   
   @item
   @oparam{destEnd}-@oparam{destStart} >= @oconst{maxUCS2EncodingLength}.  In
   other words, there must be enough room in the destination sequence
   @samp{@oparam{dest}[@oparam{destStart}, @oparam{destEnd}[} to hold at
   least one UCS-4 character, possibly split into a high and low surrogate
   pair.
   
   @item
   @oparam{sourceStart} is the value of @oparam{sourceDone} of a previous
   call to this procedure (or @oproc{Factory.NewCodecBOM}), @strong{or}
   the address of @samp{source[sourceStart]} is aligned on a 4-byte boundary.
   This ensures, that the decoder functions can access the source sequence
   in chunks of 2 and 4 bytes, without needing to worry about the alignment
   of memory accesses.
   
   @item
   @oparam{sourceEnd}-@oparam{sourceStart} >= @oconst{maxUTF8EncodingLength},
   @strong{or} @oparam{sourceEnd} designates the end of the byte sequence
   being decoded.  This means, that at least one complete character is encoded
   in the input sequence, or the input sequence ends with a possibly 
   incomplete character.
   @end itemize
   @end precond
   
   @postcond
   @itemize
   @item
   @oparam{sourceStart} < @oparam{sourceDone} <= @oparam{sourceEnd} and
   @oparam{destStart} < @oparam{destDone} <= @oparam{destEnd}.  This means,
   that at least one character has been decoded.
   
   @item
   @oparam{sourceDone} > @oparam{sourceEnd}-@oconst{maxUTF8EncodingLength}
   @emph{or}
   @oparam{destDone} > @oparam{destEnd}-@oconst{maxUCS2EncodingLength}.
   This implies, that the decoding algorithm continues until it gets near
   the end of the source or destination buffer.  But the implementation of the
   decoding algorithm can be set up in such a way, that it stops when the
   input or output sequence of the next character @emph{may} not fit into the
   buffers.  It must not decode the maximum number of bytes that fit into
   the buffers.
   
   @item
   If the procedure was started with
   @oparam{sourceEnd}-@oparam{sourceStart} < @oconst{maxUTF8EncodingLength},
   and if there is enough room in the destination buffer to store the
   whole result, then all remaining bytes in the source sequence have been
   decoded and @oparam{sourceDone} equals @oparam{sourceEnd}.
   
   @item
   Every malformed character, and every decoded character code that can
   not be mapped onto a Unicode character (i.e., one or two UCS-2 values),
   is replaced with @oconst{decodeError}, and 
   the counter @ofield{codec.invalidChars} is incremented by one.  The
   output of the decoding function contains only valid characters.  That is,
   all surrogate codes are properly paired, and the character codes U+FFFE
   and U+FFFF are replaced with @oconst{decodeError}.
   
   @item 
   @samp{@oparam{dest}[@oparam{destStart}, @oparam{destDone}[} holds the
   result of decoding 
   @samp{@oparam{source}[@oparam{sourceStart}, @oparam{sourceDone}[}.
   @end itemize
   @end postcond *)
  BEGIN HALT (127)
  END Decode;

PROCEDURE (codec: Codec) Encode* (VAR source: ARRAY OF Char;
                                             sourceStart, sourceEnd: LONGINT;
                                             VAR dest: ARRAY OF CHAR;
                                             destStart, destEnd: LONGINT;
                                             VAR sourceDone,destDone: LONGINT);
(**Encodes the Unicode characters in
   @samp{@oparam{source}[@oparam{sourceStart}, 
   @oparam{sourceEnd}[} into the byte sequence
   @samp{@oparam{dest}[@oparam{destStart}, @oparam{destEnd}[}.
   
   @precond
   @itemize
   @item
   @oparam{sourceStart} < @oparam{sourceEnd}, and the Unicode character
   sequence @samp{@oparam{source}[@oparam{sourceStart}, @oparam{sourceEnd}[}
   holds the characters that are to be decoded.
   
   @item
   @oparam{destEnd}-@oparam{destStart} >= @oconst{maxUTF8EncodingLength}.  In
   other words, there must be enough room in the destination sequence
   @samp{@oparam{dest}[@oparam{destStart}, @oparam{destEnd}[} to hold at
   least one UCS-4 character, possibly encoded as a sequence of 6 bytes.
   
   @item
   @oparam{destStart} is the value of @oparam{destDone} of a previous
   call to this procedure (or @oproc{Factory.NewCodecBOM}), @strong{or}
   the address of @samp{dest[destStart]} is aligned on a 4-byte boundary.
   This ensures, that the encoder functions can access the destination sequence
   in chunks of 2 and 4 bytes, without needing to worry about the alignment
   of memory accesses.
   
   @item
   @oparam{sourceEnd}-@oparam{sourceStart} >= @oconst{maxUCS2EncodingLength},
   @strong{or} @oparam{sourceEnd} designates the end of the character sequence
   being decoded.  This means, that at least one complete character is 
   in the input sequence, or the input sequence ends with a possibly 
   incomplete character.
   @end itemize
   @end precond
   
   @postcond
   @itemize
   @item
   @oparam{sourceStart} < @oparam{sourceDone} <= @oparam{sourceEnd} and
   @oparam{destStart} < @oparam{destDone} <= @oparam{destEnd}.  This means,
   that at least one character has been encoded.
   
   @item
   @oparam{sourceDone} > @oparam{sourceEnd}-@oconst{maxUCS2EncodingLength}
   @emph{or}
   @oparam{destDone} > @oparam{destEnd}-@oconst{maxUTF8EncodingLength}.
   This implies, that the encoding algorithm continues until it gets near
   the end of the source or destination buffer.  But the implementation of the
   encoding algorithm can be set up in such a way, that it stops when the
   input or output sequence of the next character @emph{may} not fit into
   the buffers.  It must not decode the maximum number of bytes that fit
   into the buffers.
   
   @item
   If the procedure was started with
   @oparam{sourceEnd}-@oparam{sourceStart} < @oconst{maxUCS2EncodingLength},
   and if there is enough room in the destination buffer to store the
   whole result, then all remaining bytes in the source sequence have been
   encoded and @oparam{sourceDone} equals @oparam{sourceEnd}.
   
   @item
   Every malformed character, and every character code that can not be
   mapped onto a valid encoding, is replaced with @oconst{encodeError},
   and the counter @ofield{codec.invalidChars} is
   incremented by one.  Out of range Unicode characters encoded as a
   (high, low) surrogate pair are recognized as a @emph{single}
   invalid character.  The character codes U+FFFE and U+FFFF are also mapped
   to @oconst{encodeError}.
   
   @item 
   @samp{@oparam{dest}[@oparam{destStart}, @oparam{destDone}[} holds the
   result of encoding 
   @samp{@oparam{source}[@oparam{sourceStart}, @oparam{sourceDone}[}.
   @end itemize
   @end postcond *)
  BEGIN HALT (127)
  END Encode;

PROCEDURE (codec: Codec) EncodeBOM* (VAR dest: ARRAY OF CHAR;
                                     destStart, destEnd: LONGINT;
                                     VAR destDone: LONGINT);
(**Appends a byte order mark to @oparam{dest}.  If the field @ofield{codec.bom}
   is @oconst{bomNotApplicable}, nothing is done and @oparam{destDone} is set
   to @oparam{destStart}.  Otherwise, the codec-specific encoding of the
   byte order mark is appended to @oparam{dest}, and @oparam{destDone} is set
   to the position after the mark.

   @precond
   @oparam{destEnd}-@oparam{destStart} >= @oconst{maxUTF8EncodingLength}.  In
   other words, there must be enough room in the destination sequence
   @samp{@oparam{dest}[@oparam{destStart}, @oparam{destEnd}[} to hold at
   least one UCS-4 character, possibly encoded as a sequence of 6 bytes.
   @end precond  *)
  VAR
    source: ARRAY maxUCS2EncodingLength OF Char;
    sourceDone: LONGINT;
  BEGIN
    IF (codec. bom = bomNotApplicable) THEN
      destDone := destStart
    ELSE
      source[0] := byteOrderMark;
      codec. Encode (source, 0, 1,
                     dest, destStart, destEnd, sourceDone, destDone);
      ASSERT (sourceDone = 1)
    END
  END EncodeBOM;


PROCEDURE InitFactory* (f: Factory; bom: SHORTINT);
(**Initializes factory @oparam{f} with the byte order characteristic 
   @oparam{bom}.  *)
  BEGIN
    f. bom := bom
  END InitFactory;

PROCEDURE (f: Factory) NewCodec* (): Codec;
(**Creates a new codec from factory @oparam{f}.  This should not be called for
   factories with an @ofield{Factory.bom} of @oconst{bomOptional} or
   @oconst{bomRequired}.  *)
  BEGIN HALT (127); RETURN NIL
  END NewCodec;

PROCEDURE (f: Factory) NewCodecBOM* (VAR source: ARRAY OF CHAR;
                                               sourceStart, sourceEnd: LONGINT;
                                               VAR sourceDone: LONGINT): Codec;
(**Creates a new codec from factoriy @oparam{f}, taking the byte order 
   mark into account.  The exact behaviour of this procedure depends on
   the value of @ofield{f.bom}.
   
   @table @oconst
   @item bomNotApplicable
   Any byte order mark is ignored, and @oparam{sourceDone} is set to 
   @oparam{sourceStart}.
   
   @item bomOptional
   If the @oparam{source} begins with a byte order mark, it is removed from
   the input and the correspondig codec is returned, and the parameter
   @oparam{sourceDone} is set after the end of the byte order mark.  If
   there is no byte order mark, @oparam{sourceDone} is set to
   @oparam{sourceStart} and the default codec is returned.
   
   @item bomRequired
   In the presence of a byte order mark, this is just like
   @oconst{bomOptional}, but without a byter order mark the returned 
   codec's @ofield{Codec.invalidChars} counter is set to one and 
   @oparam{sourceDone} is set to @oparam{sourceStart}.
   @end table
   
   @precond
   @oparam{sourceEnd}-@oparam{sourceStart} >= @oconst{maxUTF8EncodingLength},
   @strong{or} @oparam{sourceEnd} designates the end of the byte sequence
   being decoded.  This means, that at least one complete character is encoded
   in the input sequence, or the input sequence ends with a possibly 
   incomplete character.
   @end precond  *)
  BEGIN HALT (127); RETURN NIL
  END NewCodecBOM;

PROCEDURE (f: Factory) GetEncodingName* (VAR name: ARRAY OF CHAR);
(**Returns the preferred MIME name for the factory's encoding.  *)
  BEGIN HALT (127)
  END GetEncodingName;


PROCEDURE Register* (name: ARRAY OF CHAR; factory: Factory);
(* Registers codec factory @oparam{factory} under the given name.  Case is notd
   distinguished in the encoding name.  If a factory is already registered
   under @oparam{name}, the old entry is replaced.  *)
   
  PROCEDURE ScanList (VAR l: Node);
    BEGIN
      IF (l = NIL) THEN
        NEW (l);
        NEW (l. name, Strings.Length (name)+1);
        COPY (name, l. name^);
        l. factory := factory;
        l. next := NIL
      ELSIF (l. name^ = name) THEN
        l. factory := factory
      ELSE
        ScanList (l. next)
      END
    END ScanList;
  
  BEGIN
    Strings.Cap (name);
    ScanList (factoryList)
  END Register;

PROCEDURE Unregister* (name: ARRAY OF CHAR);
(* Removes codec factory for @oparam{name} from the internal list.  Case is of
   no importance for @oparam{name}.  Nothing is done if no factory
   @oparam{name} is known.  *)
   
  PROCEDURE ScanList (VAR l: Node);
    BEGIN
      IF (l # NIL) THEN
        IF  (l. name^ = name) THEN
          l := l. next
        ELSE
          ScanList (l. next)
        END
      END
    END ScanList;
  
  BEGIN
    Strings.Cap (name);
    ScanList (factoryList)
  END Unregister;

PROCEDURE GetFactory* (name: ARRAY OF CHAR): Factory;
(* Fetches a codec factory for the given name.  Case is not distinguished.  
   If no matching codec is registered, return @code{NIL}.  *)
  VAR
    n: Node;
  BEGIN
    Strings.Cap (name);
    n := factoryList;
    WHILE (n # NIL) & (n. name^ # name) DO
      n := n. next
    END;
    IF (n # NIL) THEN
      RETURN n. factory
    ELSE
      RETURN NIL
    END
  END GetFactory;

BEGIN
  factoryList := NIL
END XMLUnicodeCodec.
