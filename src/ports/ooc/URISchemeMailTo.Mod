(* 	$Id: MailTo.Mod,v 1.1.1.2 2000/07/10 20:31:53 mva Exp $	 *)
MODULE URISchemeMailTo;
(*  Implementation of the "mailto" URI scheme.
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
  URI0 := URI, String := URIString, Opaque := URISchemeOpaque;


TYPE
  URI* = POINTER TO URIDesc;
  URIDesc = RECORD
  (**This class implements the @samp{mailto:} URI scheme.  Note: Syntax checks
     on the mail address are not implemented yet.  *)
    (Opaque.GenericDesc)
  END;


PROCEDURE Init* (mailto: URI; schemeId, opaque: URI0.StringPtr);
  BEGIN
    Opaque.Init (mailto, schemeId, opaque)
  END Init;

PROCEDURE New* (schemeId, opaque: URI0.StringPtr): URI;
  VAR
    mailto: URI;
  BEGIN
    NEW (mailto);
    Init (mailto, schemeId, opaque);
    RETURN mailto
  END New;

PROCEDURE (mailto: URI) Clone* (): URI0.URI;
  VAR
    copy: URI;
  BEGIN
    NEW (copy);
    mailto. Copy (copy);
    RETURN copy
  END Clone;

PROCEDURE NewPrototype*(): URI;
  BEGIN
    RETURN New (String.Copy ("mailto"), String.Copy (""))
  END NewPrototype;

BEGIN
  URI0.RegisterScheme (NewPrototype())
END URISchemeMailTo.
