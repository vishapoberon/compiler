MODULE TestIRC;
(* SPDX-License-Identifier: LGPL-3.0-only *)
IMPORT IRC, Strings := oocStrings, Platform, Out;

TYPE Fake = POINTER TO FakeDesc;
  FakeDesc = RECORD(IRC.TransportDesc)
    input, output: ARRAY 16384 OF CHAR;
    readAt, written: LONGINT;
    blocked: BOOLEAN;
    opens: INTEGER
  END;
VAR config: IRC.Config; client: IRC.Client; t: Fake; message: IRC.Message;
  i, messages, errors: INTEGER; value: ARRAY 128 OF CHAR; eol: ARRAY 3 OF CHAR;

PROCEDURE Open(transport: IRC.Transport; host: ARRAY OF CHAR; port, timeout: LONGINT): BOOLEAN;
BEGIN WITH transport: Fake DO INC(transport.opens); RETURN TRUE END END Open;
PROCEDURE Poll(transport: IRC.Transport): INTEGER;
BEGIN RETURN IRC.Connected END Poll;
PROCEDURE Close(transport: IRC.Transport);
BEGIN END Close;
PROCEDURE Read(transport: IRC.Transport; VAR data: ARRAY OF CHAR; offset, count: LONGINT): LONGINT;
BEGIN
  WITH transport: Fake DO
    IF transport.input[transport.readAt] = 0X THEN RETURN IRC.WouldBlock END;
    data[offset] := transport.input[transport.readAt]; INC(transport.readAt); RETURN 1
  END
END Read;
PROCEDURE Write(transport: IRC.Transport; VAR data: ARRAY OF CHAR; offset, count: LONGINT): LONGINT;
BEGIN
  WITH transport: Fake DO
    IF transport.blocked THEN RETURN IRC.WouldBlock END;
    ASSERT(transport.written < LEN(transport.output) - 1);
    transport.output[transport.written] := data[offset]; INC(transport.written);
    transport.output[transport.written] := 0X; RETURN 1
  END
END Write;
PROCEDURE State(c: IRC.Client; state, error: INTEGER; detail: ARRAY OF CHAR);
BEGIN IF error # 0 THEN INC(errors) END END State;
PROCEDURE Message(c: IRC.Client; VAR m: IRC.Message);
BEGIN INC(messages) END Message;
PROCEDURE Input(text: ARRAY OF CHAR);
BEGIN COPY(text, t.input); t.readAt := 0 END Input;
PROCEDURE Pump;
VAR i: INTEGER;
BEGIN FOR i := 0 TO 1000 DO IRC.Poll(client) END END Pump;
PROCEDURE Contains(pattern: ARRAY OF CHAR): BOOLEAN;
VAR found: BOOLEAN; pos: INTEGER;
BEGIN Strings.FindNext(pattern, t.output, 0, found, pos); RETURN found END Contains;

BEGIN
  eol[0] := IRC.CR; eol[1] := IRC.LF; eol[2] := 0X;
  ASSERT(IRC.Parse("@time=now;label=a\sb\:c\\d;flag :nick!u@h privmsg #one :hello there", message));
  ASSERT(message.command = "PRIVMSG"); ASSERT(message.count = 2); ASSERT(message.trailing);
  ASSERT(message.params[1]^ = "hello there"); ASSERT(message.raw^ = "@time=now;label=a\sb\:c\\d;flag :nick!u@h privmsg #one :hello there");
  ASSERT(IRC.Tag(message, "label", value)); ASSERT(value = "a b;c\d");
  ASSERT(IRC.Tag(message, "flag", value)); ASSERT(value = "");
  ASSERT(~IRC.Tag(message, "missing", value));
  ASSERT(IRC.Parse(":s 999 nick :", message)); ASSERT(message.params[1]^ = "");
  ASSERT(~IRC.Parse(":", message)); ASSERT(~IRC.Parse("@tag", message));
  ASSERT(~IRC.Parse("12A x", message)); ASSERT(~IRC.Parse("", message));
  ASSERT(~IRC.Parse("CMD 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16", message));

  NEW(t); t.Open := Open; t.Poll := Poll; t.Read := Read; t.Write := Write; t.Close := Close;
  t.input := ""; t.output := ""; t.readAt := 0; t.written := 0; t.opens := 0; t.blocked := FALSE; t.secure := FALSE;
  IRC.DefaultConfig(config); config.host := "test"; config.port := 6667;
  config.nick := "probe"; config.user := "user"; config.realName := "test";
  config.retryDelay := 0; messages := 0; errors := 0;
  client := IRC.New(config, t, Message, State); ASSERT(IRC.Start(client)); Pump;
  ASSERT(Contains("CAP LS 302")); ASSERT(client.state = IRC.Registering);
  Input(":s CAP * LS :"); Strings.Append(eol, t.input); Pump;
  ASSERT(Contains("CAP END"));
  Input(":s 001 probe :welcome"); Strings.Append(eol, t.input); Pump;
  ASSERT(client.state = IRC.Ready); ASSERT(t.opens = 1);
  ASSERT(IRC.Privmsg(client, "bob", "hello")); Pump; ASSERT(Contains("PRIVMSG bob :hello"));
  COPY("PRIVMSG bob :a", value); Strings.Append(eol, value); ASSERT(~IRC.SendRaw(client, value));
  ASSERT(IRC.SameName(client, "[a]", "{A}"));
  Input(":s 005 probe CASEMAPPING=ascii CHANTYPES=! NICKLEN=12 :supported");
  Strings.Append(eol, t.input); Pump;
  ASSERT(~IRC.SameName(client, "[a]", "{A}")); ASSERT(IRC.IsChannel(client, "!room")); ASSERT(client.nickLength = 12);
  t.blocked := TRUE;
  FOR i := 0 TO IRC.QueueLimit - 9 DO ASSERT(IRC.Privmsg(client, "bob", "queued")) END;
  ASSERT(~IRC.Privmsg(client, "bob", "overflow"));
  Input("PING :priority"); Strings.Append(eol, t.input); Pump;
  t.blocked := FALSE; Pump; ASSERT(Contains("PONG :priority"));
  IRC.Stop(client); i := t.opens; Pump; ASSERT(t.opens = i); ASSERT(client.state = IRC.Stopped);
  config.replyTimeout := 500;
  client := IRC.New(config, t, Message, State); ASSERT(IRC.Start(client)); Pump;
  Input(":s CAP * LS :"); Strings.Append(eol, t.input); Pump;
  Input(":s 001 probe :welcome"); Strings.Append(eol, t.input); Pump;
  ASSERT(client.state = IRC.Ready); t.blocked := TRUE;
  ASSERT(IRC.Privmsg(client, "bob", "blocked write")); IRC.Poll(client);
  Platform.Delay(550); IRC.Poll(client); ASSERT(client.state = IRC.Waiting);
  IRC.Stop(client); t.blocked := FALSE;
  config.saslUser := "account"; config.saslPassword := "secret";
  client := IRC.New(config, t, Message, State); ASSERT(IRC.Start(client)); Pump;
  ASSERT(client.state = IRC.Stopped); ASSERT(errors > 0);
  client := IRC.New(config, NIL, NIL, State); ASSERT(~IRC.Start(client));
  Out.String("PASS: parser, tags, partial I/O, queue bounds, lifecycle, ISUPPORT and SASL policy"); Out.Ln
END TestIRC.
