(* 	$Id: Unparsed.Mod,v 1.1.1.2 2000/07/10 20:31:53 mva Exp $	 *)
MODULE URIAuthorityUnparsed;
(*  Implements class for unparsed authority components.
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
  Authority* = POINTER TO AuthorityDesc;
  AuthorityDesc = RECORD
  (**Unparsed authority component of an URI.  *)
    (URI.AuthorityDesc)
    unparsed-: URI.StringPtr
    (**Holds the authority substring of a URI @emph{without} any
       modifications.  In particular, escaped characters are @emph{not}
       replaced with their character value.  *)
  END;


CONST
  illegalAuthChar = 1;

VAR
  authContext: Error.Context;


PROCEDURE Init* (auth: Authority; unparsed: URI.StringPtr);
  BEGIN
    URI.InitAuthority (auth);
    ASSERT (unparsed # NIL);
    auth. unparsed := unparsed
  END Init;

PROCEDURE New* (unparsed: URI.StringPtr): Authority;
  VAR
    auth: Authority;
  BEGIN
    NEW (auth);
    Init (auth, unparsed);
    RETURN auth
  END New;

PROCEDURE (auth: Authority) Clone* (): URI.Authority;
  VAR
    copy: Authority;
  BEGIN
    NEW (copy);
    auth. Copy (copy);
    RETURN copy
  END Clone;

PROCEDURE (auth: Authority) Copy* (dest: URI.Authority);
  BEGIN
    (*auth. Copy^ (dest); procedure is abstract in super class *)
    WITH dest: Authority DO
      dest. unparsed := String.Copy (auth. unparsed^)
    END
  END Copy;

PROCEDURE (auth: Authority) ParseAuthority* (str: URI.StringPtr; offset: URI.Offset): Error.Msg;
  VAR
    i: URI.Offset;
  BEGIN
    i := 0;
    WHILE CharClass.SkipAuthChar (str^, i) DO END;
    IF (str[i] # 0X) THEN
      RETURN Error.New (authContext, illegalAuthChar, i+offset)
    ELSE
      auth. unparsed := str;
      RETURN NIL
    END
  END ParseAuthority;

PROCEDURE (auth: Authority) WriteXML* (w: TextRider.Writer);
  BEGIN
    w. WriteChar (CC.eol); w. WriteString ("<authority-unparsed>");
    w. WriteString (auth. unparsed^);
    w. WriteString ("</authority-unparsed>")
  END WriteXML;

PROCEDURE (auth: Authority) Append* (VAR str: ARRAY OF CHAR);
  BEGIN
    String.Append ("//", str);
    String.Append (auth. unparsed^, str)
  END Append;

BEGIN
  authContext := Error.NewContext ("URI:Authority:Unparsed");
  authContext. SetString (illegalAuthChar,
    "Illegal character in authority component");
END URIAuthorityUnparsed.
