(* 	$Id: File.Mod,v 1.3 2000/07/28 15:15:21 mva Exp $	 *)
MODULE URISchemeFile;
(*  Implementation of the "file" URI scheme.
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
  Msg, Channel, Files := oocFiles, FilesHost,
  URI0 := URI, Error := URIError, CharClass := URICharClass, String := URIString,
  Hierarchical := URISchemeHierarchical, ServerBased := URIAuthorityServerBased,
  Parser := URIParser;


TYPE
  URI* = POINTER TO URIDesc;
  URIDesc = RECORD
  (**This class implements the @samp{file:} URI scheme.  It uses
     @otype{ServerBased.Authority} for its authority component, and does
     not support a query part.  *)
    (Hierarchical.GenericDesc)
  END;

  LocalAuthority = POINTER TO LocalAuthorityDesc;
  LocalAuthorityDesc = RECORD (ServerBased.AuthorityDesc) END;

PROCEDURE (auth: LocalAuthority) ParseAuthority* (str: URI0.StringPtr;
                                                offset: URI0.Offset): Error.Msg;
  BEGIN
    IF str^ = "" THEN RETURN NIL END;
    RETURN auth. ParseAuthority^ (str, offset)
  END ParseAuthority;


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
  VAR auth: LocalAuthority;
  BEGIN
    NEW (auth);
    ServerBased.Init (auth, NIL, String.Copy (""), -1, -1);
    RETURN auth
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
    filePath: ARRAY 4096 OF CHAR;
    segm: Hierarchical.Segment;
    length: LONGINT;
  BEGIN
    IF (file. authority # NIL) &
       ((file. authority(ServerBased.Authority). userinfo # NIL) OR
        (file. authority(ServerBased.Authority). port # -1) OR
        ((file. authority(ServerBased.Authority). host^ # "") &
         (file. authority(ServerBased.Authority). host^ # "localhost"))) THEN
      RETURN file. GetChannel^ (mode, res)
    END;
    length := 0; segm := file. pathList;
    WHILE segm # NIL DO
      INC (length, String.Length (segm. string^)+1);
      IF length >= LEN (filePath) THEN RETURN file. GetChannel^ (mode, res) END;
      segm := segm. next
    END;
    file. GetPath (filePath);
    CASE mode OF
    | URI0.channelNew:
      RETURN Files.New (filePath, {Files.read, Files.write}, res)
    | URI0.channelTmp:
      RETURN Files.Tmp (filePath, {Files.read, Files.write}, res)
    | URI0.channelOld:
      RETURN Files.Old (filePath, {Files.read}, res)
    ELSE
      RETURN file. GetChannel^ (mode, res)
    END
  END GetChannel;

PROCEDURE NewPrototype*(): URI;
  BEGIN
    RETURN New (String.Copy ("file"), NIL, NIL)
  END NewPrototype;


PROCEDURE GetCwd*(): URI;
(**Creates an absolute file URI for the current working directory.  If the
   current working directory cannot be determined, the value @code{NIL} is
   returned.  *)
  VAR
    uri: URI0.URI;
    path: ARRAY 4096 OF CHAR;
    uriString: URI0.StringPtr;
    res: Msg.Msg;
  BEGIN
    FilesHost.CurrentDirectory (path);
    IF (path[0] # 0X) THEN
      NEW (uriString, 3*String.Length (path)+7);
      COPY ("file:", uriString^);
      String.AppendEscaped (path, ":@&=+$,/", uriString^);
      IF (uriString[String.Length (uriString^)-1] # "/") THEN
        String.Append ("/", uriString^)
      END;
      uri := Parser.NewURI (uriString^, NIL, res);
      IF uri # NIL THEN RETURN uri(URI) END
    END;
    RETURN NIL
  END GetCwd;

PROCEDURE ToURI* (filePath: ARRAY OF CHAR): URI;
(**Constructs a @samp{file:} URI for a given file path.  Characters that
   are not valid within an URI are escaped.  *)
  VAR
    uri: URI0.URI;
    uriString: URI0.StringPtr;
    length: LONGINT;
    res: Msg.Msg;
  BEGIN
    length := String.Length (filePath);
    IF (length = 0) OR (length > (MAX (LONGINT)-6) DIV 3) THEN RETURN NIL END;
    NEW (uriString, 3*length+6);
    IF (filePath[0] = "/") THEN
      COPY ("file:", uriString^);
      String.AppendEscaped (filePath, ":@&=+$,/", uriString^);
      uri := Parser.NewURI (uriString^, NIL, res)
    ELSE
      uriString[0] := 0X;
      String.AppendEscaped (filePath, "@&=+$,/", uriString^);
      uri := Parser.NewURI (uriString^, GetCwd(), res)
    END;
    IF (uri = NIL) THEN
      RETURN NIL
    ELSE
      RETURN uri(URI)
    END
  END ToURI;

BEGIN
  URI0.RegisterScheme (NewPrototype())
END URISchemeFile.
