(* 	$Id: CurrentDoc.Mod,v 1.1.1.2 2000/07/10 20:31:53 mva Exp $	 *)
MODULE URISchemeCurrentDoc;
(*  Implements degenerate case of "current document" URI.
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
  TextRider, CharClass, URI;


TYPE
  CurrentDoc* = POINTER TO CurrentDocDesc;
  CurrentDocDesc = RECORD
  (**This class implements the special case of the @samp{current document}
     URI.  It is used whenever an URI consists of just the empty string.  *)
    (URI.URIDesc)
  END;


PROCEDURE Init* (uri: CurrentDoc);
  BEGIN
    URI.InitURI (uri, NIL)
  END Init;

PROCEDURE New* (): CurrentDoc;
  VAR
    uri: CurrentDoc;
  BEGIN
    NEW (uri);
    Init (uri);
    RETURN uri
  END New;

PROCEDURE (uri: CurrentDoc) Clone* (): URI.URI;
  VAR
    copy: CurrentDoc;
  BEGIN
    NEW (copy);
    uri. Copy (copy);
    RETURN copy
  END Clone;

PROCEDURE (uri: CurrentDoc) Copy* (dest: URI.URI);
  BEGIN
    uri. Copy^ (dest)
  END Copy;

PROCEDURE (uri: CurrentDoc) WriteXML* (w: TextRider.Writer);
  BEGIN
    w. WriteChar (CharClass.eol); w. WriteString ("<current-document/>")
  END WriteXML;

PROCEDURE (uri: CurrentDoc) GetString* (VAR str: ARRAY OF CHAR);
  BEGIN
    COPY ("", str)
  END GetString;

END URISchemeCurrentDoc.
