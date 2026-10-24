(* 	$Id: Unparsed.Mod,v 1.1.1.2 2000/07/10 20:31:53 mva Exp $	 *)
MODULE URIQueryUnparsed;
(*  Implements class for unparsed query components.
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
  Error := URIError, String := URIString, CharClass := URICharClass;


TYPE
  Query* = POINTER TO QueryDesc;
  QueryDesc = RECORD
  (**Unparsed query component of an URI.  *)
    (URI.QueryDesc)
    unparsed-: URI.StringPtr;
    (**Holds the query substring of a URI @emph{without} any modifications.
       In particular, escaped characters are @emph{not} replaced with their
       character value.  This field is never @code{NIL}.  *)
  END;


CONST
  illegalQueryChar = 1;

VAR
  queryContext: Error.Context;


PROCEDURE Init* (query: Query; unparsed: URI.StringPtr);
  BEGIN
    URI.InitQuery (query);
    ASSERT (unparsed # NIL);
    query. unparsed := unparsed
  END Init;

PROCEDURE New* (unparsed: URI.StringPtr): Query;
  VAR
    query: Query;
  BEGIN
    NEW (query);
    Init (query, unparsed);
    RETURN query
  END New;

PROCEDURE (query: Query) Clone* (): URI.Query;
  VAR
    copy: Query;
  BEGIN
    NEW (copy);
    query. Copy (copy);
    RETURN copy
  END Clone;

PROCEDURE (query: Query) Copy* (dest: URI.Query);
  BEGIN
    (*query. Copy^ (dest); procedure is abstract in super class *)
    WITH dest: Query DO
      dest. unparsed := String.Copy (query. unparsed^)
    END
  END Copy;

PROCEDURE (query: Query) ParseQuery* (str: URI.StringPtr; offset: URI.Offset): Error.Msg;
  VAR
    i: URI.Offset;
  BEGIN
    i := 0;
    WHILE CharClass.SkipURIC (str^, i) DO END;
    IF (str[i] # 0X) THEN
      RETURN Error.New (queryContext, illegalQueryChar, i+offset)
    ELSE
      query. unparsed := str;
      RETURN NIL
    END
  END ParseQuery;

PROCEDURE (query: Query) WriteXML* (w: TextRider.Writer);
  BEGIN
    w. WriteChar (CC.eol); w. WriteString ("<query-unparsed>");
    w. WriteString (query. unparsed^);
    w. WriteString ("</query-unparsed>");
  END WriteXML;

PROCEDURE (query: Query) Append* (VAR str: ARRAY OF CHAR);
  BEGIN
    String.Append ("?", str);
    String.Append (query. unparsed^, str)
  END Append;

BEGIN
  queryContext := Error.NewContext ("URI:Query:Unparsed");
  queryContext. SetString (illegalQueryChar,
    "Illegal character in query component");
END URIQueryUnparsed.
