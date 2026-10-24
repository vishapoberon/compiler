(*	$Id: Memory.Mod,v 1.4 2000/12/08 21:41:23 mva Exp $	*)
MODULE IOMemory;
(*  Implementation of a simple file system in memory.
    Copyright (C) 1999-2001  Michael van Acken

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
  Ch := Channel, Msg, Time, LongStrings, SYSTEM;


CONST
  noLength* = Ch.noLength;
  noPosition* = Ch.noPosition;

  done* = Ch.done;
  channelClosed* = Ch.channelClosed;
  noModTime* = Ch.noModTime;
  noReadAccess* = Ch.noReadAccess;
  noWriteAccess* = Ch.noWriteAccess;
  outOfRange* = Ch.outOfRange;
  readAfterEnd* = Ch.readAfterEnd;

  accessDenied* = Ch.freeErrorCode;
  (**Access to the file was denied.  For this class, this means that a call to
     @oproc{New}, @oproc{Old}, or @oproc{Tmp} did not specify any access
     method.  *)
  noSuchFile* = Ch.freeErrorCode+1;
  (**The file named in a call to @oproc{Old} does not exist.  *)

CONST
  (* possible elements for `flags' parameter of New/Old/Tmp: *)
  read* = 0;
  (**Open file for read access.  *)
  write* = 1;
  (**Open file for write access.  *)
  (* note: at least one of the above flags has to be set; otherwise you'll
     get an `access denied' error *)


CONST
  slack = 32;

TYPE
  File* = POINTER TO FileDesc;
  Data* = POINTER TO ARRAY OF CHAR;
  Name = POINTER TO ARRAY OF CHAR;
  FileDesc = RECORD
  (**A file instance in memory.  This module does not implement a hierarchical
     file system.  Names are unstructured character sequences, as far as this
     module is concerned.  To use the URI module @omodule{*URI:Scheme:Memory},
     which interprets names as path components separated by slash characters
     @samp{/}, all file names must begin with a slash @samp{/}.  *)
    next: File;
    name: Name;
    length-: LONGINT;
    (**Length of the file in bytes.  *)
    dataLength: LONGINT;                 (* equals LEN(data^) *)
    openCount: LONGINT;
    data-: Data;
    (**Data of the file.  The bytes in the interval @samp{[0..@ofield{length}[}
       make up its content.  *)
  END;

  Channel* = POINTER TO ChannelDesc;
  ChannelDesc* = RECORD
  (**A channel for a given instance of @otype{File}.  *)
    (Ch.ChannelDesc)
    file-: File;
    (**Any read or write operations are performed on this object.  *)
  END;
  Reader* = POINTER TO ReaderDesc;
  ReaderDesc* = RECORD
  (**A reader on an instance of @otype{File}.  *)
    (Ch.ReaderDesc)
    pos: LONGINT;
  END;
  Writer* = POINTER TO WriterDesc;
  WriterDesc* = RECORD
  (**A writer on an instance of @otype{File}.  *)
    (Ch.WriterDesc)
    pos: LONGINT;
  END;

VAR
  fileList: File;


TYPE
  ErrorContext = POINTER TO ErrorContextDesc;
  ErrorContextDesc = RECORD
    (Ch.ErrorContextDesc)
  END;

VAR
  errorContext: ErrorContext;

PROCEDURE GetError (code: Msg.Code): Msg.Msg;
  BEGIN
    RETURN Msg.New (errorContext, code)
  END GetError;

PROCEDURE (context: ErrorContext) GetTemplate* (msg: Msg.Msg; VAR templ: Msg.LString);
  VAR
    str: ARRAY 128 OF CHAR;
  BEGIN
    CASE msg. code OF
    | accessDenied: str := "Access denied"
    | noSuchFile: str := "The named file does not exist"
    ELSE
      str := ""; context. GetTemplate^ (msg, templ)
    END;
    IF (str # "") THEN
      LongStrings.Long (str, templ)
    END
  END GetTemplate;


PROCEDURE NewFile (VAR name: ARRAY OF CHAR): File;
  VAR
    b: File;
  BEGIN
    NEW (b);
    b. next := NIL;
    NEW (b. name, LongStrings.Length8 (name)+1);
    COPY (name, b. name^);
    b. length := 0;
    b. dataLength := 512-slack;
    b. openCount := 0;
    NEW (b. data, 512-slack);
    RETURN b
  END NewFile;

PROCEDURE ExtendFile (b: File; newLen: LONGINT);
  VAR
    i: LONGINT;
    newData: Data;
  BEGIN
    ASSERT (newLen >= 0);
    i := b. dataLength;
    WHILE (i < newLen) DO
      IF i > (MAX (LONGINT)-slack) DIV 2 THEN i := newLen
      ELSE i := 2*i+slack END
    END;
    newLen := i;
    NEW (newData, newLen);
    SYSTEM.MOVE (SYSTEM.ADR (b. data[0]),
                 SYSTEM.ADR (newData[0]),
                 b. length);
    b. dataLength := newLen;
    b. data := newData
  END ExtendFile;

PROCEDURE CopyBytes (VAR source, dest: ARRAY OF SYSTEM.BYTE;
                     sourceStart, destStart, count: LONGINT);
  VAR sourceAddr, destAddr: SYSTEM.ADDRESS; i: LONGINT;
  BEGIN
    IF count = 0 THEN RETURN END;
    sourceAddr := SYSTEM.ADR (source[sourceStart]);
    destAddr := SYSTEM.ADR (dest[destStart]);
    IF (destAddr > sourceAddr) & (destAddr-sourceAddr < count) THEN
      FOR i := count-1 TO 0 BY -1 DO dest[destStart+i] := source[sourceStart+i] END
    ELSIF (sourceAddr >= destAddr) & (sourceAddr-destAddr < count) THEN
      FOR i := 0 TO count-1 DO dest[destStart+i] := source[sourceStart+i] END
    ELSE
      SYSTEM.MOVE (sourceAddr, destAddr, count)
    END
  END CopyBytes;

PROCEDURE FindFile (VAR name: ARRAY OF CHAR): File;
  VAR
    ptr: File;
  BEGIN
    ptr := fileList;
    WHILE (ptr # NIL) & (ptr. name^ # name) DO
      ptr := ptr. next
    END;
    RETURN ptr
  END FindFile;

PROCEDURE InsertFile (b: File);
(* Insert `b' in list of files.  List is sorted lexicographically, if a
   file of the same name is already registered it will be replaced with `b'.
   pre: b.name#NIL, b.next=NIL *)
  VAR
    ptr, pred: File;
  BEGIN
    IF (fileList = NIL) THEN  (* emtpy list *)
      fileList := b
    ELSIF (b. name^ = fileList. name^) THEN  (* need to replace head *)
      b. next := fileList. next;
      fileList := b
    ELSIF (b. name^ < fileList. name^) THEN  (* first element of list *)
      b. next := fileList;
      fileList := b
    ELSE
      pred := fileList;
      ptr := fileList. next;
      WHILE (ptr # NIL) & (b. name^ > ptr. name^) DO
        pred := ptr; ptr := ptr. next
      END;
      IF (ptr = NIL) THEN  (* end of list *)
        pred. next := b
      ELSIF (ptr. name^ = b. name^) THEN  (* need to replace `ptr' *)
        b. next := ptr. next;
        pred. next := b
      ELSE  (* b.name^ < ptr.name^: insert before `ptr' *)
        b. next := ptr;
        pred. next := b
      END
    END
  END InsertFile;



PROCEDURE (r: Reader) Pos* (): LONGINT;
  BEGIN
    IF r. positionable THEN
      RETURN r. pos
    ELSE
      RETURN noPosition
    END
  END Pos;

PROCEDURE (r: Reader) Available* (): LONGINT;
  BEGIN
    IF r. base. open THEN
      IF r. pos >= r. base(Channel). file. length THEN RETURN 0 END;
      RETURN r. base(Channel). file. length-r. pos
    ELSE
      RETURN -1
    END
  END Available;

PROCEDURE (r: Reader) SetPos* (newPos: LONGINT);
  BEGIN
    IF (r. res = done) THEN
      IF ~r. base. open THEN
        r. res := GetError (channelClosed)
      ELSIF r. positionable & (newPos >= 0) THEN
        r. pos := newPos
      ELSE
        r. res := GetError (outOfRange)
      END
    END
  END SetPos;

PROCEDURE (r: Reader) ReadByte* (VAR x: SYSTEM.BYTE);
  VAR
    b: File;
  BEGIN
    r. bytesRead := 0;
    IF (r. res = done) THEN
      b := r. base(Channel). file;
      IF ~r. base. open THEN
        r. res := GetError (channelClosed);
        r. bytesRead := 0
      ELSIF (r. pos < b. length) THEN
        x := SYSTEM.VAL (SYSTEM.BYTE, b. data[r. pos]);
        r. bytesRead := 1;
        INC (r. pos)
      ELSE
        r. res := GetError (readAfterEnd);
        r. bytesRead := 0
      END
    END
  END ReadByte;

PROCEDURE (r: Reader) ReadBytes* (VAR x: ARRAY OF SYSTEM.BYTE;
                                  start: LONGINT; n: LONGINT);
  VAR
    b: File;
  BEGIN
    r. bytesRead := 0;
    IF (r. res = done) THEN
      b := r. base(Channel). file;
      IF ~r. base. open THEN
        r. res := GetError (channelClosed);
        r. bytesRead := 0
      ELSIF (start < 0) OR (start > LEN (x)) OR (n < 0) OR (n > LEN (x)-start) THEN
        r. res := GetError (outOfRange)
      ELSIF (n = 0) THEN
        r. bytesRead := 0
      ELSIF (r. pos <= b. length) & (n <= b. length-r. pos) THEN
        CopyBytes (b. data^, x, r. pos, start, n);
        r. bytesRead := n;
        INC (r. pos, n)
      ELSIF (r. pos < b. length) THEN
        n := b. length - r. pos;
        CopyBytes (b. data^, x, r. pos, start, n);
        r. bytesRead := n;
        INC (r. pos, n);
        r. res := GetError (readAfterEnd)
      ELSE
        r. res := GetError (readAfterEnd);
        r. bytesRead := 0
      END
    END
  END ReadBytes;



PROCEDURE (w: Writer) Pos* (): LONGINT;
  BEGIN
    IF w. positionable THEN
      RETURN w. pos
    ELSE
      RETURN noPosition
    END
  END Pos;

PROCEDURE (w: Writer) SetPos* (newPos: LONGINT);
  BEGIN
    IF (w. res = done) THEN
      IF ~w. base. open THEN
        w. res := GetError (channelClosed)
      ELSIF w. positionable & (newPos >= 0) THEN
        w. pos := newPos
      ELSE
        w. res := GetError (outOfRange)
      END
    END
  END SetPos;

PROCEDURE (w: Writer) Truncate* (newLength: LONGINT);
  VAR
    i: LONGINT;
    b: File;
  BEGIN
    IF (w. res = done) THEN
      IF ~w. base. open THEN w. res := GetError (channelClosed); RETURN END;
      IF newLength < 0 THEN w. res := GetError (outOfRange); RETURN END;
      b := w. base(Channel). file;
      IF (newLength > b. length) THEN
        IF (newLength > b. dataLength) THEN
          ExtendFile (b, newLength)
        END;
        FOR i := b. length TO newLength-1 DO
          b. data[i] := 0X
        END
      END;
      b. length := newLength
    END
  END Truncate;

PROCEDURE (w: Writer) WriteByte* (x: SYSTEM.BYTE);
  VAR
    b: File;
  BEGIN
    w. bytesWritten := 0;
    IF (w. res = done) THEN
      b := w. base(Channel). file;
      IF ~w. base. open THEN
        w. res := GetError (channelClosed);
        w. bytesWritten := 0
      ELSIF w. pos = MAX (LONGINT) THEN
        w. res := GetError (outOfRange)
      ELSE
        IF (w. pos >= b. dataLength) THEN
          ExtendFile (b, w. pos+1)
        END;
        IF (w. pos > b. length) THEN
          w. Truncate (w. pos)
        END;
        b. data[w. pos] := SYSTEM.VAL (CHAR, x);
        w. bytesWritten := 1;
        INC (w. pos);
        IF (w. pos > b. length) THEN
          INC (b. length)
        END
      END
    END
  END WriteByte;

PROCEDURE (w: Writer) WriteBytes* (VAR x: ARRAY OF SYSTEM.BYTE;
                                   start: LONGINT; n: LONGINT);
  VAR
    b: File;
  BEGIN
    w. bytesWritten := 0;
    IF (w. res = done) THEN
      b := w. base(Channel). file;
      IF ~w. base. open THEN
        w. res := GetError (channelClosed);
        w. bytesWritten := 0
      ELSIF (start < 0) OR (start > LEN (x)) OR (n < 0) OR (n > LEN (x)-start) OR
            (n > MAX (LONGINT)-w. pos) THEN
        w. res := GetError (outOfRange)
      ELSIF (n = 0) THEN
        w. bytesWritten := 0
      ELSE
        IF (w. pos+n > b. dataLength) THEN
          ExtendFile (b, w. pos+n)
        END;
        IF (w. pos > b. length) THEN
          w. Truncate (w. pos)
        END;
        CopyBytes (x, b. data^, start, w. pos, n);
        w. bytesWritten := n;
        INC (w. pos, n);
        IF (w. pos > b. length) THEN
          b. length := w. pos
        END
      END
    END
  END WriteBytes;




PROCEDURE (ch: Channel) NewReader* (): Ch.Reader;
  VAR
    r: Reader;
  BEGIN
    IF ~ch. open THEN
      ch. res := GetError (channelClosed);
      RETURN NIL
    ELSIF ch. readable THEN
      NEW (r);
      r. base := ch;
      r. bytesRead := -1;
      r. positionable := TRUE;
      r. pos := 0;
      r. ClearError;
      ch. ClearError;
      RETURN r
    ELSE
      ch. res := GetError (noReadAccess);
      RETURN NIL
    END
  END NewReader;

PROCEDURE (ch: Channel) NewWriter* (): Ch.Writer;
  VAR
    w: Writer;
  BEGIN
    IF ~ch. open THEN
      ch. res := GetError (channelClosed);
      RETURN NIL
    ELSIF ch. writable THEN
      NEW (w);
      w. base := ch;
      w. bytesWritten := -1;
      w. positionable := TRUE;
      w. pos := 0;
      w. ClearError;
      ch. ClearError;
      RETURN w
    ELSE
      ch. res := GetError (noWriteAccess);
      RETURN NIL
    END
  END NewWriter;

PROCEDURE (ch: Channel) Length*(): LONGINT;
  BEGIN
    IF ch. open THEN
      RETURN ch. file. length
    ELSE
      RETURN noLength
    END
  END Length;

PROCEDURE (ch: Channel) Fingerprint* (VAR key: ARRAY OF SYSTEM.BYTE;
                                      start, end: LONGINT);
(**Generates fingerprint value over the data of @oparam{ch}, over the byte
   range @samp{[start..end[}.  The argument passed to @oparam{key} must be a
   @code{LONGINT} variable.  To fingerprint the whole file, use a
   @oparam{start} value of @samp{0} and an @oparam{end} of
   @samp{ch.file.length}.

   See @cite{Structured Programming(1993) 14: 136-147}.

   @precond
   @samp{LEN(key) = fpSize}
   @end precond *)
  CONST
    fpSize = SIZE(LONGINT);
  VAR
    pos: LONGINT;
    i, j, bit, new, old: LONGINT;
    byte: CHAR;
  BEGIN
    ASSERT (LEN (key) = fpSize);
    ASSERT ((0 <= start) & (start <= end) & (end <= ch. file. length));
    FOR i := 0 TO fpSize-1 DO
      key[i] := 0
    END;
    i := 0; j := 0;
    (* calculate fp *)
    FOR pos := start TO end-1 DO
      byte := SYSTEM.VAL (CHAR, ch. file. data[pos]);
      old := ORD (SYSTEM.VAL (CHAR, key[i]));
      new := ORD (byte);
      FOR bit := 1 TO j DO new := (2*new) MOD 256 + new DIV 128 END;
      key[i] := SYSTEM.VAL (SYSTEM.BYTE, CHR ((old+new) MOD 256));
      INC (i);
      IF (i = fpSize) THEN
        j := (j + 1) MOD 8; i := 0
      END
    END
  END Fingerprint;

PROCEDURE (ch: Channel) Flush*;
  BEGIN
    IF ~ch. open THEN
      ch. res := GetError (channelClosed)
    ELSE
      ch. ClearError
    END
  END Flush;

PROCEDURE (ch: Channel) GetModTime* (VAR mtime: Time.TimeStamp);
  BEGIN
    ch. res := GetError (noModTime)
  END GetModTime;

PROCEDURE (ch: Channel) Register*;
(**Registers the file under @oparam{ch} under the name passed to @oproc{Tmp}.
   Afterwards, the file can be accessed with @oproc{Old}.  *)
  BEGIN
    IF ~ch. open THEN ch. res := GetError (channelClosed); RETURN END;
    InsertFile (ch. file);
    ch. ClearError
  END Register;

PROCEDURE (ch: Channel) Close*;
  BEGIN
    IF ch. open THEN
      DEC (ch. file. openCount);
      ch. open := FALSE;
      ch. ClearError
    ELSE
      ch. res := GetError (channelClosed)
    END
  END Close;

PROCEDURE (ch: Channel) CopyToWriter* (writer: Ch.Writer);
(**Copies the file under @oparam{ch} to the given writer @oparam{writer}.  *)
  VAR pos, length: LONGINT;
  BEGIN
    IF ch. open & ~ch. readable THEN
      ch. res := GetError (noReadAccess)
    ELSIF ch. open THEN
      pos := 0; length := ch. file. length;
      WHILE (pos < length) & (writer. res = done) DO
        writer. WriteBytes (ch. file. data^, pos, length-pos);
        ASSERT ((0 <= writer. bytesWritten) & (writer. bytesWritten <= length-pos));
        INC (pos, writer. bytesWritten);
        IF (writer. bytesWritten = 0) & (writer. res = done) THEN
          writer. res := GetError (Ch.writeError)
        END
      END;
      ch. res := writer. res
    ELSE
      ch. res := GetError (channelClosed)
    END
  END CopyToWriter;


PROCEDURE Exists* (name: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    RETURN (FindFile (name) # NIL)
  END Exists;



PROCEDURE Attach (b: File; flags: SET): Channel;
  VAR
    channel: Channel;
  BEGIN
    NEW (channel);
    channel. ClearError;
    channel. readable := read IN flags;
    channel. writable := write IN flags;
    channel. open := TRUE;
    channel. file := b;
    INC (b. openCount);
    RETURN channel
  END Attach;

PROCEDURE New* (name: ARRAY OF CHAR; flags: SET; VAR res: Msg.Msg): Channel;
(**Creates a new file under the given @oparam{name}.  On success a channel on
   the new is returned and @oparam{res} is set to @oconst{done}.  Otherwise,
   result is @code{NIL} and @oparam{res} and will indicate the problem.

   Note that in terms of the Oberon System this procedure combines the
   procedures New and Register.  *)
  VAR
    b: File;
  BEGIN
    IF (flags*{read, write} # {}) THEN
      b := FindFile (name);
      IF (b # NIL) THEN
        b. length := 0
      ELSE
        b := NewFile (name);
        InsertFile (b)
      END;
      res := done;
      RETURN Attach (b, flags)
    ELSE
      res := GetError (accessDenied);
      RETURN NIL
    END
  END New;

PROCEDURE Old* (name: ARRAY OF CHAR; flags: SET; VAR res: Msg.Msg): Channel;
(**Opens a channel on an existing file.  On success the new channel is returned
   and @oparam{res} is set to @oconst{done}.  Otherwise, result is @code{NIL}
   and @oparam{res} will indicate the problem.  *)

  VAR
    b: File;
  BEGIN
    IF (flags*{read, write} # {}) THEN
      b := FindFile (name);
      IF (b = NIL) THEN
        res := GetError (noSuchFile);
        RETURN NIL
      ELSE
        res := done;
        RETURN Attach (b, flags)
      END
    ELSE
      res := GetError (accessDenied);
      RETURN NIL
    END
  END Old;

PROCEDURE Tmp* (name: ARRAY OF CHAR; flags: SET; VAR res: Msg.Msg): Channel;
(**Creates a temporary file that can be registered later on.  On success the
   channel on the file is returned and @oparam{res} is set to @oconst{done}.
   Otherwise result is @code{NIL} and @oparam{res} will indicate the problem.*)
  VAR
    b: File;
  BEGIN
    IF (flags*{read, write} # {}) THEN
      b := NewFile (name);
      res := done;
      RETURN Attach (b, flags)
    ELSE
      res := GetError (accessDenied);
      RETURN NIL
    END
  END Tmp;

BEGIN
  NEW (errorContext);
  Msg.InitContext (errorContext, "IOMemory");
  fileList := NIL
END IOMemory.
