(* 	$Id: Error.Mod,v 1.2 2000/07/31 14:24:18 mva Exp $	 *)
MODULE URIError;
(*  Error handling for URI parser.
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
  Ascii, LongStrings, M := Msg, Str := URIString;


TYPE
  Msg* = M.Msg;
  Code* = M.Code;
  String* = M.String;
  StringPtr* = M.StringPtr;
  LString* = M.LString;
  LStringPtr* = M.LStringPtr;

TYPE
  Mapping = POINTER TO MappingDesc;
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


PROCEDURE (context: Context) GetTemplate* (msg: Msg; VAR templ: LString);
  VAR
    m: Mapping;
  PROCEDURE AppendLine (text: ARRAY OF CHAR);
    VAR suffix: ARRAY 128 OF M.LChar;
    BEGIN
      suffix[0] := ORD (Ascii.lf); suffix[1] := 0;
      LongStrings.Append (suffix, templ);
      LongStrings.Long (text, suffix);
      LongStrings.Append (suffix, templ)
    END AppendLine;
  BEGIN
    m := context. mapping;
    WHILE (m # NIL) & (m. code # msg. code) DO
      m := m. next
    END;
    IF (m # NIL) THEN
      LongStrings.Assign (m. text^, templ)
    ELSE
      LongStrings.Long ("--unknown error code--", templ);
      AppendLine ("msg_context=${MSG_CONTEXT}");
      AppendLine ("msg_code=${MSG_CODE}")
    END;
    IF (msg. GetAttribute ("uri") # NIL) THEN
      AppendLine ("uri=${uri}")
    END;
    IF (msg. GetAttribute ("uri_pos") # NIL) THEN
      AppendLine ("uri_pos=${uri_pos}")
    END;
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

PROCEDURE NewContext* (id: M.String): Context;
(**Creates a new error context, using the id @oparam{id}.  @oparam{id} should
   be a module name.  *)
  VAR
    c: Context;
  BEGIN
    NEW (c);
    M.InitContext (c, id);
    c. mapping := NIL;
    RETURN c
  END NewContext;


PROCEDURE SetURIString* (msg: Msg; VAR str: Str.String);
(**Sets the attribute @samp{uri} of @oparam{msg} to @oparam{str}.  *)
  BEGIN
    msg. SetStringAttrib ("uri", M.GetStringPtr (str));
  END SetURIString;

PROCEDURE New* (context: Context; code: Code; pos: Str.Offset): Msg;
(**Creates a new error message.  The message's context is @oparam{context}, its
   error code @oparam{code}.  The attribute @samp{uri_pos} is set to
   @oparam{pos}.  *)
  VAR
    msg: M.Msg;
  BEGIN
    msg := M.New (context, code);
    msg. SetIntAttrib ("uri_pos", pos);
    RETURN msg
  END New;

END URIError.
