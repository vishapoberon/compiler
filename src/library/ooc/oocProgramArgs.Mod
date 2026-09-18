(* oo2c 1.x command-line arguments represented as a read-only channel. *)
MODULE oocProgramArgs;

IMPORT
  Host := oocProgramArgsHost, Channel0 := oocChannel,
  CharClass := oocCharClass, Time := oocTime, Msg := oocMsg;

CONST
  done* = Channel0.done;
  outOfRange* = Channel0.outOfRange;
  readAfterEnd* = Channel0.readAfterEnd;
  channelClosed* = Channel0.channelClosed;
  noWriteAccess* = Channel0.noWriteAccess;
  noModTime* = Channel0.noModTime;

TYPE
  Channel* = POINTER TO ChannelDesc;
  ChannelDesc = RECORD
    (Channel0.ChannelDesc)
  END;

  Reader = POINTER TO ReaderDesc;
  ReaderDesc = RECORD
    (Channel0.ReaderDesc)
    argument, offset, position: LONGINT
  END;

  ErrorContext = POINTER TO ErrorContextDesc;
  ErrorContextDesc* = RECORD
    (Channel0.ErrorContextDesc)
  END;

VAR
  args-: Channel;
  errorContext: ErrorContext;

PROCEDURE GetError(code: Msg.Code): Msg.Msg;
BEGIN
  RETURN Msg.New(errorContext, code)
END GetError;

PROCEDURE (r: Reader) Pos* (): LONGINT;
BEGIN
  RETURN r.position
END Pos;

PROCEDURE (r: Reader) Available* (): LONGINT;
  VAR available: LONGINT;
BEGIN
  IF ~r.base.open THEN RETURN -1 END;
  available := r.base.Length()-r.position;
  IF available > 0 THEN RETURN available ELSE RETURN 0 END
END Available;

PROCEDURE (r: Reader) SetPos* (newPos: LONGINT);
  VAR argument, length, remaining: LONGINT;
BEGIN
  IF r.res = done THEN
    IF newPos < 0 THEN
      r.res := GetError(outOfRange)
    ELSIF ~r.base.open THEN
      r.res := GetError(channelClosed)
    ELSE
      argument := 0;
      remaining := newPos;
      WHILE (argument < Host.Count()) & (remaining > Host.Length(argument)) DO
        DEC(remaining, Host.Length(argument)+1);
        INC(argument)
      END;
      IF argument = Host.Count() THEN
        r.offset := 0
      ELSE
        length := Host.Length(argument);
        IF remaining > length THEN remaining := length END;
        r.offset := remaining
      END;
      r.argument := argument;
      r.position := newPos
    END
  END
END SetPos;

PROCEDURE (r: Reader) ReadByte* (VAR x: Host.Byte);
  VAR length: LONGINT;
BEGIN
  r.bytesRead := 0;
  IF r.res = done THEN
    IF ~r.base.open THEN
      r.res := GetError(channelClosed)
    ELSIF r.argument >= Host.Count() THEN
      r.res := GetError(readAfterEnd)
    ELSE
      length := Host.Length(r.argument);
      IF r.offset = length THEN
        x := CharClass.eol;
        INC(r.argument);
        r.offset := 0
      ELSE
        Host.Get(r.argument, r.offset, x);
        IF Host.IsEol(x) THEN x := " " END;
        INC(r.offset)
      END;
      INC(r.position);
      r.bytesRead := 1
    END
  END
END ReadByte;

PROCEDURE (r: Reader) ReadBytes* (VAR x: ARRAY OF Host.Byte; start, n: LONGINT);
  VAR count: LONGINT;
BEGIN
  ASSERT((n >= 0) & (start >= 0) & (start+n <= LEN(x)));
  count := 0;
  WHILE (count < n) & (r.res = done) DO
    r.ReadByte(x[start+count]);
    IF r.res = done THEN INC(count) END
  END;
  r.bytesRead := count
END ReadBytes;

PROCEDURE (ch: Channel) Length* (): LONGINT;
  VAR argument, length: LONGINT;
BEGIN
  argument := 0;
  length := 0;
  WHILE argument < Host.Count() DO
    INC(length, Host.Length(argument)+1);
    INC(argument)
  END;
  RETURN length
END Length;

PROCEDURE (ch: Channel) ArgNumber* (): LONGINT;
BEGIN
  IF Host.Count() > 0 THEN RETURN Host.Count()-1 ELSE RETURN 0 END
END ArgNumber;

PROCEDURE (ch: Channel) GetModTime* (VAR mtime: Time.TimeStamp);
BEGIN
  ch.res := GetError(noModTime)
END GetModTime;

PROCEDURE (ch: Channel) NewReader* (): Channel0.Reader;
  VAR r: Reader;
BEGIN
  IF ch.open THEN
    NEW(r);
    r.base := ch;
    r.res := done;
    r.bytesRead := 0;
    r.positionable := TRUE;
    r.argument := 0;
    r.offset := 0;
    r.position := 0;
    ch.res := done;
    RETURN r
  ELSE
    ch.res := GetError(channelClosed);
    RETURN NIL
  END
END NewReader;

PROCEDURE (ch: Channel) Flush*;
BEGIN
  IF ch.open THEN ch.res := done ELSE ch.res := GetError(channelClosed) END
END Flush;

PROCEDURE (ch: Channel) Close*;
BEGIN
  ch.open := FALSE;
  ch.res := done
END Close;

BEGIN
  NEW(errorContext);
  Msg.InitContext(errorContext, "OOC:Core:ProgramArgs");
  NEW(args);
  args.res := done;
  args.readable := TRUE;
  args.writable := FALSE;
  args.open := TRUE
END oocProgramArgs.
