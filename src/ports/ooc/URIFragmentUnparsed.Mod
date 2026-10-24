(* 	$Id: Unparsed.Mod,v 1.2 2000/07/28 15:12:57 mva Exp $	 *)
MODULE URIFragmentUnparsed;
(*  Implements class for unparsed fragment identifiers.
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
  String := URIString, CharClass := URICharClass, Error := URIError;

TYPE
  Fragment* = POINTER TO FragmentDesc;
  FragmentDesc = RECORD
  (**Unparsed fragment identifier of an URI reference.  A fragment identifier
     is the component in an URI reference following the crosshatch character
     @samp{#}.  The format of the fragment identifier is interpreted by the
     user agent after the URI document has been retrieved.  That it, it depends
     on the document, and @emph{not} on the URI scheme being used.  *)
    (URI.FragmentDesc)
    unparsed-: String.StringPtr;
    (**Holds the fragment identifier of a URI @emph{without} any modifications.
       In particular, escaped characters are @emph{not} replaced with their
       character value.  Interpretation of special characters and escaped
       characters is up to the user agent.  *)
  END;


CONST
  illegalFragmentChar = 1;

VAR
  fragContext: Error.Context;


PROCEDURE Init* (frag: Fragment; unparsed: String.StringPtr);
(**Initializes unparsed fragment identifier.

   @precond
   @oparam{unparsed} is not @code{NIL}.
   @end precond *)
  BEGIN
    ASSERT (unparsed # NIL);
    frag. unparsed := unparsed
  END Init;

PROCEDURE New* (unparsed: String.StringPtr): Fragment;
(**Creates new unparsed fragment identifier.

   @precond
   @oparam{unparsed} is not @code{NIL}.
   @end precond *)
  VAR
    frag: Fragment;
  BEGIN
    NEW (frag);
    Init (frag, unparsed);
    RETURN frag
  END New;

PROCEDURE (frag: Fragment) Clone* (): URI.Fragment;
  VAR
    copy: Fragment;
  BEGIN
    NEW (copy);
    frag. Copy (copy);
    RETURN copy
  END Clone;

PROCEDURE (frag: Fragment) Copy* (dest: URI.Fragment);
  BEGIN
    (*frag. Copy^ (dest); procedure is abstract in super class *)
    WITH dest: Fragment DO
      dest. unparsed := String.Copy (frag. unparsed^)
    END
  END Copy;

PROCEDURE (frag: Fragment) ParseFragment* (str: URI.StringPtr; offset: URI.Offset): Error.Msg;
  VAR
    i: URI.Offset;
  BEGIN
    i := 0;
    WHILE CharClass.SkipURIC (str^, i) DO END;
    IF (str[i] # 0X) THEN
      RETURN Error.New (fragContext, illegalFragmentChar, i+offset)
    ELSE
      frag. unparsed := str;
      RETURN NIL
    END
  END ParseFragment;

PROCEDURE (frag: Fragment) WriteXML* (w: TextRider.Writer);
  BEGIN
    w. WriteChar (CC.eol); w. WriteString ("<fragment-unparsed>");
    w. WriteString (frag. unparsed^);
    w. WriteString ("</fragment-unparsed>")
  END WriteXML;

PROCEDURE (frag: Fragment) Append* (VAR str: ARRAY OF CHAR);
  BEGIN
    String.Append ("#", str);
    String.Append (frag. unparsed^, str)
  END Append;

BEGIN
  fragContext := Error.NewContext ("URI:Fragment:Unparsed");
  fragContext. SetString (illegalFragmentChar,
    "Illegal character in fragment component");
END URIFragmentUnparsed.
