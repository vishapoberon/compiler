MODULE XmppConnections;

(* Transport-independent event delivery and checked stanza output. The caller
   owns socket/TLS I/O and retains the unconsumed part of each input buffer. *)

IMPORT Channel, Msg, S := LongStrings, T := XmppTypes,
  Items := XmppItems, XML := XmppXmlStream, Gen := XmppXmlGen;

TYPE
  Owner* = POINTER TO OwnerDesc;
  OwnerDesc* = RECORD END;
  Connection* = POINTER TO ConnectionDesc;
  ConnectionDesc* = RECORD
    stream-: XML.Stream;
    writeError-: Msg.Msg;
    readBytes-, wroteBytes-: HUGEINT;
    owner: Owner;
    output: Channel.Writer;
    reported: BOOLEAN;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (context: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN S.Long("XMPP output writer made no progress", text) END GetTemplate;

PROCEDURE (owner: Owner) Opened*(header: Items.Item);
BEGIN END Opened;

PROCEDURE (owner: Owner) UpdateRead*(item: Items.Item);
BEGIN END UpdateRead;

PROCEDURE (owner: Owner) UpdateWrite*(item: Items.Item);
BEGIN END UpdateWrite;

PROCEDURE (owner: Owner) UpdateError*(error: Msg.Msg);
BEGIN END UpdateError;

PROCEDURE (owner: Owner) Closed*;
BEGIN END Closed;

PROCEDURE (c: Connection) Feed*(VAR bytes: ARRAY OF CHAR; start, count: LONGINT;
                              VAR consumed: LONGINT): SHORTINT;
  VAR event: SHORTINT;
BEGIN
  event := c.stream.Feed(bytes, start, count, consumed); INC(c.readBytes, consumed);
  IF event = XML.opened THEN c.owner.Opened(c.stream.header)
  ELSIF event = XML.stanza THEN c.owner.UpdateRead(c.stream.item)
  ELSIF event = XML.closed THEN
    IF ~c.reported THEN c.reported := TRUE; c.owner.Closed END
  ELSIF event = XML.failed THEN
    IF ~c.reported THEN c.reported := TRUE; c.owner.UpdateError(c.stream.error) END
  END;
  RETURN event
END Feed;

PROCEDURE (c: Connection) Restart*(): BOOLEAN;
BEGIN
  IF ~c.stream.Restart() THEN RETURN FALSE END;
  c.reported := FALSE; RETURN TRUE
END Restart;

PROCEDURE (c: Connection) Finish*(): BOOLEAN;
BEGIN
  IF ~c.stream.Finish() THEN
    IF ~c.reported THEN c.reported := TRUE; c.owner.UpdateError(c.stream.error) END;
    RETURN FALSE
  END;
  RETURN TRUE
END Finish;

PROCEDURE Write(c: Connection; bytes: Items.Bytes; length: LONGINT; VAR error: Msg.Msg);
  VAR pos, count: LONGINT;
BEGIN
  ASSERT(c.output # NIL);
  error := c.writeError; IF error # NIL THEN RETURN END;
  pos := 0;
  WHILE pos < length DO
    c.output.WriteBytes(bytes^, pos, length-pos); count := c.output.bytesWritten;
    ASSERT((count >= 0) & (count <= length-pos)); INC(c.wroteBytes, count);
    IF c.output.res # NIL THEN error := c.output.res; c.writeError := error; RETURN END;
    IF count = 0 THEN
      error := Msg.New(context, 1); c.writeError := error; RETURN
    END;
    INC(pos, count)
  END
END Write;

PROCEDURE (c: Connection) WriteData*(item: Items.Item; VAR error: Msg.Msg);
  VAR bytes: Items.Bytes; length: LONGINT;
BEGIN
  error := c.writeError; IF error # NIL THEN RETURN END;
  Gen.Encode(item, 1024*1024, bytes, length, error);
  IF error # NIL THEN RETURN END;
  Write(c, bytes, length, error); IF error # NIL THEN RETURN END;
  c.owner.UpdateWrite(item)
END WriteData;

PROCEDURE (c: Connection) WritePrivate*(item: Items.Item; VAR error: Msg.Msg);
(* Protocol credentials bypass output hooks; scrub the published byte buffer. *)
  VAR bytes: Items.Bytes; length, i: LONGINT;
BEGIN
  error := c.writeError; IF error # NIL THEN RETURN END;
  Gen.Encode(item, 16384, bytes, length, error);
  IF error = NIL THEN Write(c, bytes, length, error) END;
  IF bytes # NIL THEN FOR i := 0 TO LEN(bytes^)-1 DO bytes[i] := 0X END END
END WritePrivate;

PROCEDURE (c: Connection) OpenStream*(to, from, id, lang: ARRAY OF T.CodeUnit; VAR error: Msg.Msg);
  VAR bytes: Items.Bytes; length: LONGINT;
BEGIN
  error := c.writeError; IF error # NIL THEN RETURN END;
  Gen.OpenStream(to, from, id, lang, bytes, length, error);
  IF error = NIL THEN Write(c, bytes, length, error) END
END OpenStream;

PROCEDURE (c: Connection) CloseStream*(VAR error: Msg.Msg);
  VAR bytes: Items.Bytes;
BEGIN bytes := Gen.CloseStream(); Write(c, bytes, S.Length8(bytes^), error) END CloseStream;

PROCEDURE New*(owner: Owner; output: Channel.Writer): Connection;
  VAR c: Connection;
BEGIN
  ASSERT(owner # NIL); NEW(c); c.owner := owner; c.output := output; c.stream := XML.New();
  RETURN c
END New;

BEGIN
  NEW(context); Msg.InitContext(context, "XmppConnections")
END XmppConnections.
