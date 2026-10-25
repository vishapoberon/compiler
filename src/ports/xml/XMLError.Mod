(* 	$Id: Error.Mod,v 1.5 2001/03/24 12:23:34 mva Exp $	 *)
MODULE XMLError;
(*  Creates lists of error messages and converts them to text.
    Copyright (C) 2000, 2001  Michael van Acken

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
  Ascii, Channel, LongStrings, M := Msg,
  URI, File := URISchemeFile, Buffer := XMLUnicodeBuffer,
  UTF8 := XMLUnicodeCodecUTF8;
  
  
TYPE
  Msg* = M.Msg;
  Code* = M.Code;
  Char* = M.Char;
  LChar* = M.LChar;
  String* = M.String;
  StringPtr* = M.StringPtr;
  LString* = M.LString;
  LStringPtr* = M.LStringPtr;
  
TYPE
  Mapping* = POINTER TO MappingDesc;
  MappingDesc = RECORD
    next: Mapping;
    code: Code;
    text: LStringPtr;
  END;

TYPE
  Context* = POINTER TO ContextDesc;
  ContextDesc* = RECORD
    (M.ContextDesc)
    mapping: Mapping;
  END;

TYPE
  List* = POINTER TO ListDesc;
  ListDesc = RECORD
    (M.MsgListDesc)
    cwdURI: URI.HierarchicalURI;
  END;


VAR
  errMsgLineBase*: LONGINT;
  (**Line number used to refer to the first line in a file in an error message.
     The default is @samp{0}.  Most programs count lines beginning at @samp{1},
     so you might want to change this before calling the XML parser.  *)
  errMsgColumnBase*: LONGINT;
  (**Column number used to refer to the first character of a line in an error
     message.  The default is @samp{0}.  *)
  errMsgCharPosBase*: LONGINT;
  (**Character position used to refer to the first character of a file in an
     error message.  The default is @samp{0}.  *)


PROCEDURE InitContext* (c: Context; id: M.String);
  BEGIN
    M.InitContext (c, id);
    c. mapping := NIL
  END InitContext;

PROCEDURE NewContext* (id: M.String): Context;
(**Creates a new error context, using the id @oparam{id}.  @oparam{id} should
   be a module name.  *)
  VAR
    c: Context;
  BEGIN
    NEW (c);
    InitContext (c, id);
    RETURN c
  END NewContext;

PROCEDURE (context: Context) WriteTemplate* (msg: M.Msg; msgText: M.LString; VAR templ: M.LString);
  VAR
    entityName: M.Attribute;
    prefix: ARRAY 128 OF M.LChar;
    len: LONGINT;
  BEGIN
    entityName := msg. GetAttribute ("entity_name");
    IF (entityName = NIL) THEN
      templ[0] := 0
    ELSE
      LongStrings.Long ("While expanding entity `", templ);
      LongStrings.Append (entityName(M.LStringAttribute). string^, templ);
      LongStrings.Append8 ("': ", templ)
    END;
    
    LongStrings.Append (msgText, templ);
    LongStrings.Long ("line=${line}, column=${column}", prefix);
    len := LongStrings.Length (prefix); prefix[len] := ORD (Ascii.lf); prefix[len+1] := 0;
    LongStrings.Append8 ("${char}: ", prefix);
    LongStrings.Insert (prefix, 0, templ)
  END WriteTemplate;

PROCEDURE (context: Context) GetTemplate* (msg: Msg; VAR templ: LString);
  VAR
    m: Mapping;
    unknown: ARRAY 128 OF M.LChar;
  BEGIN
    m := context. mapping;
    WHILE (m # NIL) & (m. code # msg. code) DO
      m := m. next
    END;
    IF (m # NIL) THEN
      context. WriteTemplate (msg, m. text^, templ)
    ELSE
      LongStrings.Long ("--unknown error code; msg_context=${MSG_CONTEXT}; msg_code=${MSG_CODE}--", unknown);
      context. WriteTemplate (msg, unknown, templ)
    END
  END GetTemplate;

PROCEDURE (context: Context) SetString* (code: Code; str: String);
(**Maps the error code @oparam{code} onto the error text @oparam{str}.  If a
   mapping for @oparam{code} exists, it is replaced with the new one.  *)
  PROCEDURE Append (VAR mlist: Mapping);
    VAR
      str16: ARRAY 1024 OF M.LChar;
    BEGIN
      IF (mlist = NIL) THEN
        NEW (mlist);
        mlist. next := NIL;
        mlist. code := code;
        LongStrings.Long (str, str16);
        mlist. text := M.GetLStringPtr (str16)
      ELSIF (mlist. code = code) THEN
        LongStrings.Long (str, str16);
        mlist. text := M.GetLStringPtr (str16)
      ELSE
        Append (mlist. next)
      END
    END Append;
  
  BEGIN
    Append (context. mapping)
  END SetString;

PROCEDURE New* (context: Context; code: Code): Msg;
  BEGIN
    RETURN M.New (context, code)
  END New;

PROCEDURE NewList*(): List;
(**Creates new error list.  *)
  VAR
    list: List;
  BEGIN
    NEW (list);
    M.InitMsgList (list);
    list. cwdURI := File.GetCwd();
    RETURN list
  END NewList;


PROCEDURE (errList: List) Write* (ch: Channel.Channel);
(**Writes UTF-8 diagnostics to a writable channel, grouping messages by file.
   File headings use names relative to the current working directory. *)
  VAR
    output: Buffer.Output;
    msg, prev: Msg;
    text: ARRAY 8*1024 OF M.LChar;
    name: ARRAY 4096 OF CHAR;
    newline: ARRAY 2 OF CHAR;
    uriAttr: M.Attribute;
    uri, relative, prevURI: URI.URI;
  
  PROCEDURE DistanceOk (m0, m1: M.Msg): BOOLEAN;
    VAR
      p0, p1: M.Attribute;
    BEGIN
      IF (m0 = NIL) THEN
        RETURN TRUE
      ELSE
        p0 := m0. GetAttribute ("char");
        p1 := m1. GetAttribute ("char");
        IF (p0 # NIL) & (p1 # NIL) &
           (p0 IS M.IntAttribute) &
           (p1 IS M.IntAttribute) &
           (ABS (p0(M.IntAttribute). int - p1(M.IntAttribute). int) < 16) THEN
          RETURN FALSE
        ELSE
          RETURN TRUE
        END
      END
    END DistanceOk;
  
  BEGIN
    output := Buffer.NewOutput (ch. NewWriter(), UTF8.factory, FALSE);
    newline[0] := Ascii.lf; newline[1] := 0X;
    prev := NIL; prevURI := NIL;
    msg := errList. msgList;
    WHILE (msg # NIL) DO
      uri := NIL;
      uriAttr := msg. GetAttribute ("baseURI");
      IF (uriAttr # NIL) & (uriAttr IS URI.URIAttribute) THEN
        uri := uriAttr(URI.URIAttribute). uri
      END;
      IF (uri # prevURI) OR DistanceOk (prev, msg) THEN
        IF (uri # NIL) & (uri # prevURI) THEN
          relative := uri. MakeRelative (errList. cwdURI);
          relative. GetString (name);
          output. Write8 ("In file "); output. Write8 (name);
          output. Write8 (": "); output. Write8 (newline)
        END;
        msg. GetLText (text);
        output. Write16 (text); output. Write8 (newline);
        prev := msg; prevURI := uri
      END;
      msg := msg. nextMsg
    END;
    output. Flush
  END Write;

BEGIN
  errMsgLineBase := 0; errMsgColumnBase := 0; errMsgCharPosBase := 0;
END XMLError.
