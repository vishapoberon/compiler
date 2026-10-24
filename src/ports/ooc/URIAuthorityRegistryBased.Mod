(* 	$Id: RegistryBased.Mod,v 1.2 2000/07/31 14:24:36 mva Exp $	 *)
MODULE URIAuthorityRegistryBased;
(*  Implements class for registry-based authority components.
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
  CC := CharClass, TextRider, URI,
  CharClass := URICharClass, String := URIString, Error := URIError;

TYPE
  Authority* = POINTER TO AuthorityDesc;
  AuthorityDesc* = RECORD
  (**Registry-based authority component of an URI.  This is similar to
     @otype{*URI:Authority:Unparsed.Authority}, except for that the given
     authority name must not be empty, and that any escaped characters are
     replaced by their value.  *)
    (URI.AuthorityDesc)
    regName-: URI.StringPtr;
    (**Holds the authority substring of a URI.  Escaped characters are
       replaced with their character value.  *)
  END;


CONST
  illegalRegNameChar = 1;
  emptyRegName = 2;

VAR
  regNameContext: Error.Context;


PROCEDURE Init* (auth: Authority; regName: URI.StringPtr);
  BEGIN
    auth. regName := regName
  END Init;

PROCEDURE New* (regName: URI.StringPtr): Authority;
  VAR
    auth: Authority;
  BEGIN
    NEW (auth);
    Init (auth, regName);
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
      dest. regName := String.Copy (auth. regName^)
    END
  END Copy;

PROCEDURE (auth: Authority) ParseAuthority* (str: URI.StringPtr; offset: URI.Offset): Error.Msg;
  VAR
    i: URI.Offset;
  BEGIN
    i := 0;
    WHILE CharClass.SkipAuthChar (str^, i) DO END;
    IF (i = 0) THEN
      RETURN Error.New (regNameContext, emptyRegName, i+offset)
    ELSIF (str[i] # 0X) THEN
      RETURN Error.New (regNameContext, illegalRegNameChar, i+offset)
    ELSE
      auth. regName := String.Unescape (str);
      RETURN NIL
    END
  END ParseAuthority;

PROCEDURE (auth: Authority) WriteXML* (w: TextRider.Writer);
  BEGIN
    w. WriteChar (CC.eol); w. WriteString ("<authority-registry-based>");
    w. WriteString (auth. regName^);
    w. WriteString ("</authority-registry-based>")
  END WriteXML;

PROCEDURE (auth: Authority) Append* (VAR str: ARRAY OF CHAR);
  BEGIN
    String.Append ("//", str);
    String.AppendEscaped (auth. regName^, "$,;:@&=+", str)
  END Append;

BEGIN
  regNameContext := Error.NewContext ("URI:Authority:RegistryBased");
  regNameContext. SetString (illegalRegNameChar,
    "Illegal character in registry-based naming authority");
  regNameContext. SetString (emptyRegName,
    "Registry-based naming authority must not be empty");
END URIAuthorityRegistryBased.
