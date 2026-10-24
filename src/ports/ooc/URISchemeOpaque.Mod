(* 	$Id: Opaque.Mod,v 1.1.1.1 2000/07/10 15:24:44 mva Exp $	 *)
MODULE URISchemeOpaque;
(*  Implementation of the generic opaque URI.
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
  TextRider, CC := CharClass, URI,
  Error := URIError, CharClass := URICharClass, String := URIString;


TYPE
  Generic* = POINTER TO GenericDesc;
  GenericDesc* = RECORD
  (**This class implements the generic opaque URI.  *)
    (URI.OpaqueURIDesc)
    opaque-: URI.StringPtr;
  END;


CONST
  illegalOpaqueChar = 1;

VAR
  opaqueContext: Error.Context;


PROCEDURE Init* (uri: Generic; schemeId, opaque: URI.StringPtr);
  BEGIN
    URI.InitOpaqueURI (uri, schemeId);
    ASSERT (opaque # NIL);
    uri. opaque := opaque
  END Init;

PROCEDURE New* (schemeId, opaque: URI.StringPtr): Generic;
  VAR
    uri: Generic;
  BEGIN
    NEW (uri);
    Init (uri, schemeId, opaque);
    RETURN uri
  END New;

PROCEDURE (uri: Generic) Clone* (): URI.URI;
  VAR
    copy: Generic;
  BEGIN
    NEW (copy);
    uri. Copy (copy);
    RETURN copy
  END Clone;

PROCEDURE (uri: Generic) Copy* (dest: URI.URI);
  BEGIN
    uri. Copy^ (dest);
    WITH dest: Generic DO
      dest. opaque := String.Copy (uri. opaque^)
    END
  END Copy;

PROCEDURE IsValidOpaqueStr (str: URI.String): URI.Offset;
  VAR
    i: URI.Offset;
  BEGIN
    IF (str[0] = "/") THEN
      RETURN 0
    ELSE
      i := 0;
      WHILE CharClass.SkipURIC (str, i) DO END;
      IF (str[i] = 0X) THEN
        RETURN -1
      ELSE
        RETURN i
      END
    END
  END IsValidOpaqueStr;

PROCEDURE (uri: Generic) ParseOpaquePart* (str: URI.StringPtr; offset: URI.Offset): Error.Msg;
  VAR
    pos: URI.Offset;
  BEGIN
    pos := IsValidOpaqueStr (str^);
    IF (pos < 0) THEN
      uri. opaque := String.Unescape (str);
      RETURN NIL
    ELSE
      RETURN Error.New (opaqueContext, illegalOpaqueChar, pos+offset)
    END
  END ParseOpaquePart;

PROCEDURE (uri: Generic) WriteXML* (w: TextRider.Writer);
  BEGIN
    w. WriteChar (CC.eol); w. WriteString ("<opaque-uri>");
    IF (uri. schemeId # NIL) THEN
      w. WriteChar (CC.eol); w. WriteString ("<scheme>");
      w. WriteString (uri. schemeId^);
      w. WriteString ("</scheme>")
    END;
    w. WriteChar (CC.eol); w. WriteString ("<opaque-part>");
    w. WriteString (uri. opaque^);
    w. WriteString ("</opaque-part>");
    w. WriteChar (CC.eol); w. WriteString ("</opaque-uri>")
  END WriteXML;

PROCEDURE (uri: Generic) GetString* (VAR str: ARRAY OF CHAR);
  BEGIN
    COPY ("", str);
    uri. AppendScheme (str);
    String.AppendEscaped (uri. opaque^, CharClass.reserved, str)
  END GetString;

BEGIN
  opaqueContext := Error.NewContext ("URI:Scheme:Opaque");
  opaqueContext. SetString (illegalOpaqueChar,
    "Illegal character for opaque component of an URI");
END URISchemeOpaque.
