(*      $Id: EntityResolver.Mod,v 1.3 2000/07/23 17:43:43 mva Exp $   *)
MODULE XMLEntityResolver;
(*  Locates and opens external entities for the XML parser.
    Copyright (C) 2000  Michael van Acken

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with OOC. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT
  LongStrings, Msg, URI, Parser := URIParser, CharClass := URICharClass,
  URIError, DTD := XMLDTD, Codec := XMLUnicodeCodec, UTF8 := XMLUnicodeCodecUTF8;


TYPE
  Resolver* = POINTER TO ResolverDesc;
  ResolverDesc* = RECORD
  END;

CONST invalidSystemIdentifier = 1;
VAR resolverContext: URIError.Context;


PROCEDURE NormalizeURI* (uri: DTD.String): DTD.StringURI;
(**Normalizes a Unicode string representing a URI to a legal URI.  First,
   the Unicode string is encoded into a UTF-8 byte sequence.  Then, any
   resulting bytes that are not reserved, unreserved, @samp{#}, or @samp{%}
   are replaced with URI escape sequences.  In particular, all non-ASCII
   bytes are escaped. Returns NIL for malformed UTF-16 or excessive length. *)
  VAR
    len16, i, j, previous: LONGINT;
    codec: Codec.Codec;
    str8, result: DTD.StringURI;
    srcDone, destDone: LONGINT;

  PROCEDURE ToHex (i: LONGINT): CHAR;
    BEGIN
      IF (i < 10) THEN
        RETURN CHR (i+ORD ("0"))
      ELSE
        RETURN CHR (i+(ORD ("A")-10))
      END
    END ToHex;

  BEGIN
    IF uri = NIL THEN RETURN NIL END;
    len16 := LongStrings.Length (uri^);
    IF len16 > (MAX (LONGINT)-19) DIV 18 THEN RETURN NIL END;
    NEW (str8, Codec.maxUTF8EncodingLength*(len16+1));
    codec := UTF8.factory. NewCodec();
    srcDone := 0; destDone := 0;
    WHILE srcDone < len16 DO
      previous := srcDone;
      codec. Encode (uri^, srcDone, len16, str8^, destDone, LEN (str8^),
                     srcDone, destDone);
      IF (codec. invalidChars # 0) OR (srcDone = previous) THEN RETURN NIL END
    END;

    (* encode every non-ASCII character and some other characters in the
       UTF-8 string to %HH *)
    NEW (result, 3*destDone+1);
    i := 0; j := 0;
    WHILE i < destDone DO
      IF (str8[i] >= 80X) OR
         ~(CharClass.IsReserved (str8[i]) OR
           CharClass.IsUnreserved (str8[i]) OR
           (str8[i] = "#") OR
           (str8[i] = "%")) THEN
        result[j] := "%";
        result[j+1] := ToHex (ORD (str8[i]) DIV 16);
        result[j+2] := ToHex (ORD (str8[i]) MOD 16);
        INC (j, 3)
      ELSE
        result[j] := str8[i]; INC (j)
      END;
      INC (i)
    END;
    result[j] := 0X;
    RETURN result
  END NormalizeURI;


PROCEDURE (r: Resolver) GetURI* (public, system: DTD.String; baseURI: URI.URI;
                                 VAR uri: URI.URI; VAR res: Msg.Msg);
(**Interprets the public or system identifier of an external entity and
   constructs an URI for it.  On success, the URI of the document is returned
   in @oparam{uri}, and @code{NIL} in @oparam{res}.  On failure, @oparam{res}
   holds an error message.
   
   The default implementation ignores the public identifier and uses the
   URI in @oparam{system}.  An relative system identifier is expanded relative
   to @oparam{baseURI}.  Both @oparam{uri} and @oparam{res} are set to 
   @code{NIL} if no system identifier is present, which is permitted for
   notation declarations.  *)
  VAR
    str8: DTD.StringURI;
  BEGIN
    IF (system = NIL) THEN               (* notation declaration *)
      uri := NIL; res := NIL;
      RETURN
    END;
    
    str8 := NormalizeURI (system);
    IF str8 = NIL THEN
      uri := NIL; res := Msg.New (resolverContext, invalidSystemIdentifier);
      RETURN
    END;
    IF (baseURI # NIL) & (baseURI IS URI.HierarchicalURI) THEN
      uri := Parser.NewURI (str8^, baseURI(URI.HierarchicalURI), res)
    ELSE
      uri := Parser.NewURI (str8^, NIL, res)
    END
  END GetURI;
  
PROCEDURE New* (): Resolver;
  VAR
    er: Resolver;
  BEGIN
    NEW (er);
    RETURN er
  END New;

BEGIN
  resolverContext := URIError.NewContext ("XMLEntityResolver");
  resolverContext. SetString (invalidSystemIdentifier,
    "Malformed or oversized UTF-16 system identifier")
END XMLEntityResolver.
