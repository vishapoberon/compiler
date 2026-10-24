(* 	$Id: Memory.Mod,v 1.3 2000/07/31 18:20:01 mva Exp $	 *)
MODULE URISchemeMemory;
(*  Implementation of the "memory" URI scheme.
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
  Msg, Channel, Memory := IOMemory, URI0 := URI,
  Error := URIError, CharClass := URICharClass, String := URIString,
  Hierarchical := URISchemeHierarchical, ServerBased := URIAuthorityServerBased,
  Parser := URIParser;


TYPE
  URI* = POINTER TO URIDesc;
  URIDesc = RECORD
  (**This class implements the @samp{memory:} URI scheme.  This is not
     an official URI scheme.  It is used by OOC to access resouces defined by
     the module @omodule{*IO:Memory}.  Similar to the @samp{file:} scheme,
     this one uses @otype{ServerBased.Authority} for its authority component,
     and does not support a query part.  *)
    (Hierarchical.GenericDesc)
  END;


PROCEDURE Init* (file: URI; schemeId: URI0.StringPtr;
                 authority: URI0.Authority; query: URI0.Query);
  BEGIN
    Hierarchical.Init (file, schemeId, authority, query)
  END Init;

PROCEDURE New* (schemeId: URI0.StringPtr;
                authority: URI0.Authority; query: URI0.Query): URI;
  VAR
    file: URI;
  BEGIN
    NEW (file);
    Init (file, schemeId, authority, query);
    RETURN file
  END New;

PROCEDURE (file: URI) NewAuthority* (): URI0.Authority;
  BEGIN
    RETURN ServerBased.New (NIL, String.Copy (""), -1, -1)
  END NewAuthority;

PROCEDURE (file: URI) NewQuery* (): URI0.Query;
  BEGIN
    RETURN NIL
  END NewQuery;

PROCEDURE (file: URI) Clone* (): URI0.URI;
  VAR
    copy: URI;
  BEGIN
    NEW (copy);
    file. Copy (copy);
    RETURN copy
  END Clone;

PROCEDURE (file: URI) GetPath* (VAR filePath: ARRAY OF CHAR);
(**Returns the file path associated with the URI @oparam{file}.  On a Unix 
   system, this is identical to the URI's path component.  *)
  VAR
    segm: Hierarchical.Segment;
  BEGIN
    COPY ("", filePath);
    segm := file. pathList;
    WHILE (segm # NIL) DO
      IF (segm # file. pathList) OR file. absolutePath THEN
        String.Append ("/", filePath)
      END;
      String.Append (segm. string^, filePath);
      segm := segm. next
    END
  END GetPath;

PROCEDURE (file: URI) GetChannel* (mode: URI0.ChannelMode; VAR res: Error.Msg): Channel.Channel;
  VAR
    filePath: URI0.StringPtr;
    segm: Hierarchical.Segment;
    length: LONGINT;
  BEGIN
    length := 0; segm := file. pathList;
    WHILE segm # NIL DO
      INC (length, String.Length (segm. string^)+1);
      segm := segm. next
    END;
    NEW (filePath, length+1);
    file. GetPath (filePath^);
    CASE mode OF
    | URI0.channelNew:
      RETURN Memory.New (filePath^, {Memory.read, Memory.write}, res)
    | URI0.channelTmp:
      RETURN Memory.Tmp (filePath^, {Memory.read, Memory.write}, res)
    | URI0.channelOld:
      RETURN Memory.Old (filePath^, {Memory.read}, res)
    ELSE
      RETURN file. GetChannel^ (mode, res)
    END
  END GetChannel;

PROCEDURE NewPrototype*(): URI;
  BEGIN
    RETURN New (String.Copy ("memory"), NIL, NIL)
  END NewPrototype;


PROCEDURE ToURI* (filePath: ARRAY OF CHAR): URI;
(**Constructs a @samp{memory:} URI for a given file path.  Characters that
   are not valid within an URI are escaped.  *)
  VAR
    uri: URI0.URI;
    uriString: URI0.StringPtr;
    length: LONGINT;
    res: Msg.Msg;
  BEGIN
    length := String.Length (filePath);
    IF (length = 0) OR (length > (MAX (LONGINT)-8) DIV 3) THEN RETURN NIL END;
    NEW (uriString, 3*length+8);
    COPY ("memory:", uriString^);
    String.AppendEscaped (filePath, ":@&=+$,/", uriString^);
    uri := Parser.NewURI (uriString^, NIL, res);
    IF (uri = NIL) THEN
      RETURN NIL
    ELSE
      RETURN uri(URI)
    END
  END ToURI;

BEGIN
  URI0.RegisterScheme (NewPrototype())
END URISchemeMemory.
