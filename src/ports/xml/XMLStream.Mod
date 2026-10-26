MODULE XMLStream;

(* Incremental UTF-8 element streams. Each event is checked by XMLParser with
   the opening element as its namespace context. A frame contains at most one
   complete child element. Wire positions and limits count bytes. *)

IMPORT Msg, S := LongStrings, Channel, Mem := IOMemory,
  D := XMLDTD, B := XMLBuilder, P := XMLParser,
  NS := XMLBuilderNamespaces, UTF8 := XMLUnicodeCodecUTF8, Limits := XMLLimits;

CONST
  needInput* = 0; opened* = 1; stanza* = 2; closed* = 3; failed* = 4;
  badMarkup* = 1; restrictedXML* = 2; frameLimit* = 3; truncated* = 4; badXML* = 5;
  defaultHeaderBytes* = 16384; defaultStanzaBytes* = 1024*1024;
  defaultNesting* = 64;
  data = 0; afterLT = 1; tag = 2; declaration = 3; cdata = 4; pi = 5;

TYPE
  Bytes = POINTER TO ARRAY OF CHAR;
  Stream* = POINTER TO StreamDesc;
  StreamDesc* = RECORD
    event-: SHORTINT;
    error-: Msg.Msg;
    parser-: P.Parser;
    maxHeaderBytes-, maxStanzaBytes-, maxNesting-: LONGINT;
    buffer, prefix, suffix: Bytes;
    length, prefixLength, suffixLength, mode, depth, tokenStart: LONGINT;
    quote: CHAR;
    endTag, started, ended, seenDeclaration: BOOLEAN;
  END;
  Probe = POINTER TO ProbeDesc;
  ProbeDesc = RECORD (B.BuilderDesc)
    document: D.ExternalEntity;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR template: Msg.LString);
  VAR text: ARRAY 96 OF CHAR;
BEGIN
  CASE message.code OF
  | badMarkup: text := "Invalid XML element stream markup"
  | restrictedXML: text := "Element streams require XML 1.0 UTF-8 and prohibit DTDs, comments and processing instructions"
  | frameLimit: text := "XML element stream frame or nesting limit exceeded"
  | truncated: text := "XML element stream ended before its closing tag"
  ELSE text := "Invalid XML element stream frame"
  END;
  S.Long(text, template)
END GetTemplate;

PROCEDURE (s: Stream) Fail(code: SHORTINT);
BEGIN
  IF s.error = NIL THEN s.error := Msg.New(context, code) END;
  s.event := failed
END Fail;

PROCEDURE White(byte: CHAR): BOOLEAN;
BEGIN RETURN (byte = " ") OR (byte = 9X) OR (byte = 0AX) OR (byte = 0DX) END White;

PROCEDURE Append(s: Stream; byte: CHAR): BOOLEAN;
  VAR maximum, capacity, i: LONGINT; buffer: Bytes;
BEGIN
  IF s.started THEN maximum := s.maxStanzaBytes ELSE maximum := s.maxHeaderBytes END;
  IF s.length = maximum THEN s.Fail(frameLimit); RETURN FALSE END;
  IF s.length = LEN(s.buffer^) THEN
    capacity := LEN(s.buffer^)*2;
    IF capacity > maximum THEN capacity := maximum END;
    NEW(buffer, capacity);
    FOR i := 0 TO s.length-1 DO buffer[i] := s.buffer[i] END;
    s.buffer := buffer
  END;
  s.buffer[s.length] := byte; INC(s.length); RETURN TRUE
END Append;

PROCEDURE (b: Probe) StartDocument(document: D.ExternalEntity);
BEGIN b.document := document END StartDocument;

PROCEDURE Parse(s: Stream; kind: SHORTINT; builder: B.Builder): BOOLEAN;
  VAR ch: Mem.Channel; writer: Channel.Writer; res: Msg.Msg;
    budget: Limits.Budget; n: LONGINT;
BEGIN
  ch := Mem.Tmp("", {Mem.read, Mem.write}, res);
  IF res # NIL THEN s.error := res; s.Fail(badXML); RETURN FALSE END;
  writer := ch.NewWriter();
  writer.WriteBytes(s.prefix^, 0, s.prefixLength);
  n := s.prefixLength;
  IF kind # opened THEN
    writer.WriteBytes(s.buffer^, 0, s.length); INC(n, s.length)
  END;
  IF kind # closed THEN
    writer.WriteBytes(s.suffix^, 0, s.suffixLength); INC(n, s.suffixLength)
  END;
  IF writer.res # NIL THEN
    s.error := writer.res; s.Fail(badXML); ch.Close; RETURN FALSE
  END;
  budget := Limits.New(); budget.maxInputBytes := n;
  budget.maxNesting := s.maxNesting+1;
  budget.maxExpandedUnits := 4*n+1024; budget.maxWork := 8*n+1024;
  budget.maxAttributeUnits := n;
  s.parser := P.NewChannelLimited(ch, NIL, UTF8.factory, NIL, NS.New(builder), budget);
  s.parser.followExternalRef := FALSE; s.parser.enforceQNames := TRUE;
  s.parser.ParseDocument; ch.Close;
  IF s.parser.errList.msgCount # 0 THEN
    s.error := s.parser.errList.msgList; s.Fail(badXML); RETURN FALSE
  END;
  RETURN TRUE
END Parse;

PROCEDURE UTF8Name(name: D.String): BOOLEAN;
BEGIN
  RETURN (name = NIL) OR ((S.Length(name^) = 5) &
    ((name[0] = ORD("U")) OR (name[0] = ORD("u"))) &
    ((name[1] = ORD("T")) OR (name[1] = ORD("t"))) &
    ((name[2] = ORD("F")) OR (name[2] = ORD("f"))) &
    (name[3] = ORD("-")) & (name[4] = ORD("8")))
END UTF8Name;

PROCEDURE Opening(s: Stream; builder: B.Builder): BOOLEAN;
  VAR first, end, i, n: LONGINT; probe: Probe;
BEGIN
  IF s.buffer[s.length-2] = "/" THEN s.Fail(badMarkup); RETURN FALSE END;
  first := s.tokenStart+1; end := first;
  WHILE (end < s.length-1) & ~White(s.buffer[end]) DO INC(end) END;
  n := end-first;
  IF n = 0 THEN s.Fail(badMarkup); RETURN FALSE END;
  NEW(s.suffix, n+3); s.suffixLength := n+3;
  s.suffix[0] := "<"; s.suffix[1] := "/";
  FOR i := 0 TO n-1 DO s.suffix[i+2] := s.buffer[first+i] END;
  s.suffix[n+2] := ">";
  NEW(s.prefix, s.length); s.prefixLength := s.length;
  FOR i := 0 TO s.length-1 DO s.prefix[i] := s.buffer[i] END;
  NEW(probe); B.Init(probe);
  IF ~Parse(s, opened, probe) THEN RETURN FALSE END;
  IF ((probe.document.version # NIL) & ~S.Equal8(probe.document.version^, "1.0")) OR
     ~UTF8Name(probe.document.encoding) OR (probe.document.standalone # D.standaloneNotPresent) THEN
    s.Fail(restrictedXML); RETURN FALSE
  END;
  RETURN Parse(s, opened, builder)
END Opening;

PROCEDURE Event(s: Stream; kind: SHORTINT; builder: B.Builder): SHORTINT;
  VAR ok: BOOLEAN;
BEGIN
  s.event := kind;
  IF kind = opened THEN ok := Opening(s, builder)
  ELSE ok := Parse(s, kind, builder)
  END;
  IF ~ok THEN RETURN failed END;
  s.started := TRUE; s.ended := kind = closed;
  s.length := 0; s.mode := data; s.quote := 0X;
  RETURN kind
END Event;

PROCEDURE (s: Stream) Feed*(VAR bytes: ARRAY OF CHAR; start, count: LONGINT;
                          builder: B.Builder; VAR consumed: LONGINT): SHORTINT;
(* Stops at one event. Only the reported consumed bytes belong to this call.
   Builder callbacks describe a synthetic document with the stream root around
   the stanza. Accept their results only after a successful event is returned. *)
  VAR byte: CHAR; end, pos, n: LONGINT; expected: ARRAY 10 OF CHAR;
BEGIN
  ASSERT((start >= 0) & (start <= LEN(bytes)) & (count >= 0) & (count <= LEN(bytes)-start));
  ASSERT(builder # NIL);
  consumed := 0;
  IF s.error # NIL THEN RETURN failed END;
  IF s.ended THEN RETURN closed END;
  s.event := needInput; pos := start; end := start+count;
  WHILE pos < end DO
    byte := bytes[pos]; INC(pos); INC(consumed);
    IF (s.mode = data) & (s.depth = 0) & s.started & White(byte) THEN
      (* Inter-stanza keepalive whitespace needs no retained storage. *)
    ELSE
      IF ~Append(s, byte) THEN RETURN failed END;
      CASE s.mode OF
      | data:
        IF byte = "<" THEN
          s.tokenStart := s.length-1; s.mode := afterLT
        ELSIF s.depth = 0 THEN
          IF ~s.started & (s.length <= 3) &
             (((s.length = 1) & (byte = 0EFX)) OR
              ((s.length = 2) & (s.buffer[0] = 0EFX) & (byte = 0BBX)) OR
              ((s.length = 3) & (s.buffer[0] = 0EFX) & (s.buffer[1] = 0BBX) & (byte = 0BFX))) THEN
          ELSIF ~White(byte) THEN s.Fail(badMarkup)
          END
        END
      | afterLT:
        s.quote := 0X; s.endTag := FALSE;
        IF byte = "?" THEN
          IF s.started OR s.seenDeclaration THEN s.Fail(restrictedXML)
          ELSE s.mode := pi
          END
        ELSIF byte = "!" THEN
          IF s.depth = 0 THEN s.Fail(restrictedXML) ELSE s.mode := declaration END
        ELSIF byte = "/" THEN
          IF ~s.started THEN s.Fail(badMarkup)
          ELSE s.mode := tag; s.endTag := TRUE
          END
        ELSIF (byte = ">") OR (byte = "<") OR White(byte) THEN s.Fail(badMarkup)
        ELSE s.mode := tag
        END
      | tag:
        IF s.quote # 0X THEN
          IF byte = s.quote THEN s.quote := 0X END
        ELSIF (byte = '"') OR (byte = "'") THEN s.quote := byte
        ELSIF byte = "<" THEN s.Fail(badMarkup)
        ELSIF byte = ">" THEN
          IF ~s.started THEN RETURN Event(s, opened, builder)
          ELSIF s.endTag THEN
            IF s.depth = 0 THEN RETURN Event(s, closed, builder) END;
            DEC(s.depth);
            IF s.depth = 0 THEN RETURN Event(s, stanza, builder) END
          ELSIF s.buffer[s.length-2] # "/" THEN
            INC(s.depth);
            IF s.depth > s.maxNesting THEN s.Fail(frameLimit) END
          ELSIF s.depth = 0 THEN RETURN Event(s, stanza, builder)
          END;
          s.mode := data
        END
      | declaration:
        expected := "<![CDATA["; n := s.length-s.tokenStart;
        IF (n > 9) OR (byte # expected[n-1]) THEN s.Fail(restrictedXML)
        ELSIF n = 9 THEN s.mode := cdata
        END
      | cdata:
        IF (byte = ">") & (s.buffer[s.length-2] = "]") & (s.buffer[s.length-3] = "]") THEN
          s.mode := data
        END
      | pi:
        IF (byte = ">") & (s.buffer[s.length-2] = "?") THEN
          expected := "<?xml"; n := s.tokenStart;
          IF (s.length-n < 8) OR (s.buffer[n] # expected[0]) OR
             (s.buffer[n+1] # expected[1]) OR (s.buffer[n+2] # expected[2]) OR
             (s.buffer[n+3] # expected[3]) OR (s.buffer[n+4] # expected[4]) OR
             ~White(s.buffer[n+5]) THEN s.Fail(restrictedXML)
          ELSE s.seenDeclaration := TRUE; s.mode := data
          END
        END
      ELSE s.Fail(badMarkup)
      END;
      IF s.error # NIL THEN RETURN failed END
    END
  END;
  RETURN needInput
END Feed;

PROCEDURE (s: Stream) Finish*(): BOOLEAN;
(* A clean transport end requires the explicit closing stream element. *)
BEGIN
  IF (s.error = NIL) & ~s.ended THEN s.Fail(truncated) END;
  RETURN s.error = NIL
END Finish;

PROCEDURE (s: Stream) Restart*(): BOOLEAN;
(* Call only after handling a completed event, before feeding the new stream.
   Partial frames and failed streams cannot be restarted. *)
BEGIN
  IF (s.error # NIL) OR (s.length # 0) OR (s.mode # data) THEN RETURN FALSE END;
  s.event := needInput; s.parser := NIL; s.prefix := NIL; s.suffix := NIL;
  s.prefixLength := 0; s.suffixLength := 0; s.depth := 0;
  s.started := FALSE; s.ended := FALSE; s.seenDeclaration := FALSE;
  RETURN TRUE
END Restart;

PROCEDURE New*(maxHeaderBytes, maxStanzaBytes, maxNesting: LONGINT): Stream;
  VAR s: Stream;
BEGIN
  ASSERT((maxHeaderBytes > 0) & (maxHeaderBytes <= 65536));
  ASSERT((maxStanzaBytes > 0) & (maxStanzaBytes <= 16*1024*1024));
  ASSERT((maxNesting > 0) & (maxNesting < 128));
  NEW(s); s.maxHeaderBytes := maxHeaderBytes; s.maxStanzaBytes := maxStanzaBytes;
  s.maxNesting := maxNesting; NEW(s.buffer, 64);
  s.length := 0; s.mode := data; s.error := NIL;
  IF ~s.Restart() THEN HALT(99) END;
  RETURN s
END New;

BEGIN
  NEW(context); Msg.InitContext(context, "XMLStream")
END XMLStream.
