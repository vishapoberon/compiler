(*      $Id: Locator.Mod,v 1.5 2000/07/31 18:37:07 mva Exp $   *)
MODULE XMLLocator;
(*  Provides access to position information for XML parser callbacks.
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
  Buffer := XMLUnicodeBuffer, Error := XMLError, DTD := XMLDTD;

TYPE
  Locator* = POINTER TO Position;
  Position* = RECORD
    charIndex*: Buffer.CharPos;
    (**The character index of the starting position associated with a callback
       event, counting UTF-16 code units.  This position is relative
       to the beginning of the current file (document entity, external DTD
       subset, or external entity), and begins with character index 0.

       Please note that this number may differ from the number of Unicode
       characters before the given index, if the file contains characters with
       code values over 0xFFFF, which are encoded as two UTF-16 code units.

       For a character position reported in an error message, the actual value
       is incremented by @ovar{Error.errMsgCharPosBase}.  *)
    line*: Buffer.CharPos;
    (**Line number of the character.  Counting begins at zero.  For a line
       number reported in an error message, the actual value is incremented by
       @ovar{Error.errMsgLineBase}.  *)
    column*: Buffer.CharPos;
    (**Column number of the character.  Counting begins at zero.  Currently,
       surrogate pairs are counted as two separate characters.  For a column
       number reported in an error message, the actual value is incremented by
       @ovar{Error.errMsgColumnBase}.  *)
    
    entity*: DTD.ExternalEntity;
    (**The current file entity (document entity, external DTD subset, or
       external entity).  Using this reference, the public identifier, the
       system identifier, and the base URI can be determined.  *)
    inInternalEntity*: DTD.InternalEntity;
    (**If the parsing is within the replacement text of an internal entity,
       this field refers to the innermost entity.  It is @code{NIL} as long
       as the parser is working on the top-most file level.  *)
  END;

TYPE
  ErrorListener* = POINTER TO ErrorListenerDesc;
  ErrorListenerDesc* = RECORD
  (**Using the @otype{ErrorListener} instance provided by the parser, builders
     and applications can add their own error messages to a document.  *)
  END;

PROCEDURE (el: ErrorListener) Error* (context: Error.Context;
                                                 code: Error.Code;
                                                 fatalError: BOOLEAN;
                                                 pos: Position): Error.Msg;
(**Adds a new error message to the parser error list.  @oparam{context} and
   @oparam{code} determine the message text.  If @oparam{fatalError} is
   @code{TRUE}, then the parser should stop reporting any events to the
   application.  @oparam{pos} indicates the position of the error.  It should
   be taken from a locator.  *)
  BEGIN HALT (127); RETURN NIL
  END Error;
  
END XMLLocator.
