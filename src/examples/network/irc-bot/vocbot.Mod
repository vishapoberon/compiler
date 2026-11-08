MODULE vocbot;
(* SPDX-License-Identifier: GPL-3.0-only *)

IMPORT IRC, IRCTCP, IRCTLS, opts, Out, Strings := oocStrings, StringList,
       IntStr, strUtils, strTypes, Files, Platform;

CONST
  delay = 2000; (* spacing between replies, in milliseconds *)
  defListLength = 200;

TYPE
  Name = ARRAY 128 OF CHAR;
  Buffer = ARRAY IRC.MaxLine + 1 OF CHAR;
  Reply = POINTER TO ReplyDesc;
  ReplyDesc = RECORD
    user: Name;
    text: ARRAY 512 OF CHAR;
    next: Reply
  END;

VAR
  history: StringList.TStringList;
  inst: IRC.Client;
  room: Name;
  logfile: Files.File;
  logRider: Files.Rider;
  historyLength, replyCount, lastReply: LONGINT;
  firstReply, finalReply: Reply;
  haveReplied, failed: BOOLEAN;

PROCEDURE interrupt(i: LONGINT);
BEGIN
  IF inst # NIL THEN IRC.Stop(inst) END;
  IF logfile # NIL THEN Files.Register(logfile); Files.Close(logfile) END;
  HALT(0)
END interrupt;

PROCEDURE reply(user, text: ARRAY OF CHAR);
VAR item: Reply; at, count, length, limit, i: INTEGER;
BEGIN
  length := Strings.Length(text); at := 0; limit := 500 - Strings.Length(user);
  IF limit < 4 THEN RETURN END;
  REPEAT
    IF replyCount >= 2 * historyLength + 16 THEN RETURN END;
    count := length - at; IF count > limit THEN count := limit END;
    IF at + count < length THEN
      WHILE (count > 0) & (ORD(text[at + count]) >= 128) & (ORD(text[at + count]) < 192) DO DEC(count) END;
      IF count = 0 THEN RETURN END
    END;
    NEW(item); COPY(user, item.user); Strings.Extract(text, at, count, item.text); item.next := NIL;
    FOR i := 0 TO count - 1 DO IF (item.text[i] = IRC.CR) OR (item.text[i] = IRC.LF) THEN item.text[i] := " " END END;
    IF firstReply = NIL THEN firstReply := item ELSE finalReply.next := item END;
    finalReply := item; INC(replyCount); INC(at, count)
  UNTIL at >= length
END reply;

(* Reply pacing and history belong to the application, outside the IRC module. *)
PROCEDURE sendReply(inst: IRC.Client);
VAR now, elapsed: LONGINT; item: Reply;
BEGIN
  IF (firstReply = NIL) OR (inst.state # IRC.Ready) THEN RETURN END;
  now := Platform.Time();
  IF now < lastReply THEN elapsed := (MAX(LONGINT) - lastReply) + now
  ELSE elapsed := now - lastReply
  END;
  IF haveReplied & (elapsed < delay) THEN RETURN END;
  item := firstReply;
  IF ~IRC.Privmsg(inst, item.user, item.text) THEN RETURN END;
  firstReply := item.next;
  IF firstReply = NIL THEN finalReply := NIL END;
  DEC(replyCount);
  lastReply := now; haveReplied := TRUE
END sendReply;

PROCEDURE remember(text: ARRAY OF CHAR);
BEGIN
  IF history.Count >= historyLength THEN history.Delete(history, 0) END;
  history.AppendString(history, text)
END remember;

PROCEDURE listToUser(list: StringList.TStringList; user: ARRAY OF CHAR; count: LONGINT);
VAR i: LONGINT; text: strTypes.pstring;
BEGIN
  IF count > list.Count THEN count := list.Count END;
  FOR i := list.Count - count TO list.Count - 1 DO
    text := list.GetString(list, i);
    reply(user, text^)
  END
END listToUser;

PROCEDURE processPrivateMessage(VAR message, user: ARRAY OF CHAR);
VAR
  command: ARRAY 16 OF CHAR;
  rest, pattern, text: Buffer;
  number: ARRAY 16 OF CHAR;
  word, line: strTypes.pstring;
  count, i: LONGINT;
  result: SHORTINT;
  matches: StringList.TStringList;
BEGIN
  strUtils.RemoveLeftChars(message, " ");
  word := strUtils.ExtractWord(1, message, " ");
  COPY(word^, command); Strings.Capitalize(command);
  IF command = "HELP" THEN
    reply(user, "i'm a humble irc bot written in oberon. https://github.com/norayr/irc_bot/");
    COPY("Type 'last n' for recent messages, or 'search [n] pattern' to search them. I remember up to ", text);
    IntStr.IntToStr(historyLength, number); Strings.Append(number, text); Strings.Append(" messages.", text);
    reply(user, text);
    COPY("Currently I remember ", text); IntStr.IntToStr(history.Count, number);
    Strings.Append(number, text); Strings.Append(" lines.", text); reply(user, text)
  ELSIF command = "LAST" THEN
    IF strUtils.WordCount(message, " ") # 2 THEN
      reply(user, "Use 'last n' with a positive message count."); RETURN
    END;
    word := strUtils.ExtractWord(2, message, " "); IntStr.StrToInt(word^, count, result);
    IF (result # 0) OR (count <= 0) THEN
      reply(user, "Use 'last n' with a positive message count."); RETURN
    END;
    IF count > historyLength THEN count := historyLength END;
    IF history.Count = 0 THEN reply(user, "I do not remember any messages yet.")
    ELSE listToUser(history, user, count)
    END
  ELSIF command = "SEARCH" THEN
    Strings.Extract(message, Strings.Length(command), Strings.Length(message), rest);
    strUtils.RemoveLeftChars(rest, " ");
    IF rest = "" THEN reply(user, "Please provide a search pattern."); RETURN END;
    word := strUtils.ExtractWord(1, rest, " "); IntStr.StrToInt(word^, count, result);
    IF result = 0 THEN
      Strings.Extract(rest, Strings.Length(word^), Strings.Length(rest), pattern);
      strUtils.RemoveLeftChars(pattern, " ")
    ELSE count := 10; COPY(rest, pattern)
    END;
    IF pattern = "" THEN reply(user, "Please provide a search pattern."); RETURN END;
    IF count <= 0 THEN count := 10 END;
    matches := StringList.Create();
    FOR i := 0 TO history.Count - 1 DO
      line := history.GetString(history, i);
      IF strUtils.contains1(line^, pattern) THEN matches.AppendString(matches, line^) END
    END;
    IF matches.Count = 0 THEN reply(user, "No matches found.")
    ELSE
      IF count > matches.Count THEN count := matches.Count END;
      COPY("Found ", text); IntStr.IntToStr(matches.Count, number); Strings.Append(number, text);
      Strings.Append(" matches. Showing last ", text); IntStr.IntToStr(count, number);
      Strings.Append(number, text); Strings.Append(":", text); reply(user, text);
      listToUser(matches, user, count)
    END;
    matches.Free(matches)
  ELSE reply(user, "Type 'help' for help.")
  END
END processPrivateMessage;

PROCEDURE writeLog(text: ARRAY OF CHAR);
VAR line: Buffer; number: ARRAY 16 OF CHAR; t, d: LONGINT;

  PROCEDURE append(n: LONGINT; separator: ARRAY OF CHAR);
  BEGIN IntStr.IntToStr(n, number); Strings.Append(number, line); Strings.Append(separator, line) END append;

BEGIN
  IF logfile = NIL THEN RETURN END;
  Platform.GetClock(t, d); line[0] := 0X;
  append(2000 + d DIV 512, "-"); append(d DIV 32 MOD 16, "-"); append(d MOD 32, " (");
  append(t DIV 4096, ":"); append(t DIV 64 MOD 64, ":"); append(t MOD 64, ") ");
  Strings.Append(text, line); Files.WriteString(logRider, line);
  Files.Set(logRider, logfile, Files.Pos(logRider) - 1); Files.Write(logRider, 10); Files.Register(logfile)
END writeLog;

PROCEDURE publicMessage(VAR message, user: ARRAY OF CHAR);
VAR text, action: Buffer; found: BOOLEAN; pos, length: INTEGER;
BEGIN
  COPY(user, text); Strings.Append(": ", text);
  IF message[0] = 01X THEN
    Strings.FindNext("ACTION ", message, 1, found, pos);
    IF found & (pos = 1) THEN
      length := Strings.Length(message);
      IF message[length - 1] = 01X THEN DEC(length) END;
      Strings.Extract(message, 8, length - 8, action);
      COPY("***", text); Strings.Append(user, text); Strings.Append(" ", text);
      Strings.Append(action, text)
    ELSE Strings.Append(message, text)
    END
  ELSE Strings.Append(message, text)
  END;
  remember(text); writeLog(text)
END publicMessage;

PROCEDURE onMessage(inst: IRC.Client; VAR message: IRC.Message);
VAR user: Name; found: BOOLEAN; pos: INTEGER;
BEGIN
  IRC.Nick(message, user);
  IF (message.command = "PRIVMSG") & (message.count = 2) THEN
    IF IRC.SameName(inst, message.params[0]^, inst.nick) THEN
      processPrivateMessage(message.params[1]^, user)
    ELSIF IRC.SameName(inst, message.params[0]^, room) THEN
      publicMessage(message.params[1]^, user);
      Strings.FindNext(inst.nick, message.params[1]^, 0, found, pos);
      IF found THEN reply(user, "Let's talk in private. Type 'help' for help.") END
    END
  ELSIF (message.command = "KICK") & (message.count >= 2) THEN
    IF IRC.SameName(inst, message.params[1]^, inst.nick) THEN
      Out.String("Kicked from "); Out.String(message.params[0]^); Out.Ln
    END
  END
END onMessage;

PROCEDURE onState(inst: IRC.Client; state, error: INTEGER; detail: ARRAY OF CHAR);
VAR line: ARRAY 256 OF CHAR; accepted: BOOLEAN;
BEGIN
  Out.String("IRC: "); Out.String(detail); Out.Ln;
  IF (state = IRC.Stopped) & (error # 0) THEN failed := TRUE END;
  IF (state = IRC.Ready) & (error = 0) THEN
    COPY("JOIN ", line); Strings.Append(room, line); accepted := IRC.SendRaw(inst, line)
  END
END onState;

PROCEDURE readLine(VAR rider: Files.Rider; VAR text: ARRAY OF CHAR);
VAR i: LONGINT; byte: SHORTINT;
BEGIN
  i := 0;
  LOOP
    Files.Read(rider, byte);
    IF rider.eof OR (byte = 10) THEN EXIT END;
    IF (byte # 13) & (i < LEN(text) - 1) THEN text[i] := CHR(byte); INC(i) END
  END;
  text[i] := 0X
END readLine;

PROCEDURE loadHistory(VAR filename: ARRAY OF CHAR);
VAR file: Files.File; rider: Files.Rider; text, line: Buffer; found: BOOLEAN; pos: INTEGER;
BEGIN
  file := Files.Old(filename);
  IF file = NIL THEN RETURN END;
  Files.Set(rider, file, 0);
  REPEAT
    readLine(rider, text);
    Strings.FindNext(") ", text, 0, found, pos);
    IF found THEN
      Strings.Extract(text, pos + 2, Strings.Length(text) - pos - 2, line);
      IF ~strUtils.contains1(line, " joined ") & ~strUtils.contains1(line, " left ") THEN remember(line) END
    ELSIF text # "" THEN remember(text)
    END
  UNTIL rider.eof
END loadHistory;

PROCEDURE processOptions(VAR config: IRC.Config; VAR transportName: ARRAY OF CHAR);
VAR options, filled: opts.Options; length, port: ARRAY 16 OF CHAR; secretEnv: ARRAY 128 OF CHAR; result: SHORTINT;

  PROCEDURE add(short, long, description: ARRAY OF CHAR; required: BOOLEAN);
  VAR option: opts.Option;
  BEGIN
    option := opts.createOpt(); opts.setOptName(option, short); opts.setOptLName(option, long);
    opts.setOptHasVal(option, TRUE); opts.setOptDesc(option, description);
    opts.setOptRequired(option, required); options.add(options, option)
  END add;

BEGIN
  options := opts.createOptions();
  add("-h", "--host", "IRC host name", TRUE);
  add("-p", "--port", "server port", TRUE);
  add("-o", "--owner", "account owner", TRUE);
  add("-u", "--user", "account username", TRUE);
  add("-n", "--nick", "nick to use", TRUE);
  add("-r", "--room", "room to join", TRUE);
  add("-w", "--password", "server password", FALSE);
  add("-l", "--listlength", "how many lines to remember", FALSE);
  add("-x", "--transport", "tls (default) or plain", FALSE);
  add("-a", "--account", "SASL account name", FALSE);
  add("-s", "--secret-env", "SASL password environment variable (default IRC_SASL_PASSWORD)", FALSE);
  filled := opts.populateOptions(options);
  IF ~opts.reqsSatisfied(options, filled) THEN opts.showHelp(options); HALT(3) END;
  opts.valOfOpt("-o", filled, config.realName); opts.valOfOpt("-u", filled, config.user);
  opts.valOfOpt("-n", filled, config.nick); opts.valOfOpt("-h", filled, config.host);
  opts.valOfOpt("-p", filled, port); opts.valOfOpt("-r", filled, room);
  opts.valOfOpt("-w", filled, config.password); opts.valOfOpt("-l", filled, length);
  opts.valOfOpt("-x", filled, transportName); opts.valOfOpt("-a", filled, config.saslUser);
  opts.valOfOpt("-s", filled, secretEnv);
  IF transportName = "" THEN COPY("tls", transportName) END;
  IF (transportName # "tls") & (transportName # "plain") THEN Out.String("transport must be tls or plain"); Out.Ln; HALT(3) END;
  IF secretEnv = "" THEN secretEnv := "IRC_SASL_PASSWORD" END;
  IF config.saslUser # "" THEN
    Platform.GetEnv(secretEnv, config.saslPassword);
    IF config.saslPassword = "" THEN Out.String("SASL password environment variable is empty"); Out.Ln; HALT(3) END
  END;
  IntStr.StrToInt(port, config.port, result);
  IF (result # 0) OR (config.port < 1) OR (config.port > 65535) THEN HALT(3) END;
  IntStr.StrToInt(length, historyLength, result);
  IF (result # 0) OR (historyLength <= 0) OR (historyLength > MAX(INTEGER)) THEN
    historyLength := defListLength
  END
END processOptions;

PROCEDURE entrance;
VAR config: IRC.Config; transport: IRC.Transport; transportName: ARRAY 16 OF CHAR;
  started: BOOLEAN; byte: SHORTINT;
BEGIN
  IRC.DefaultConfig(config); processOptions(config, transportName);
  history := StringList.Create();
  loadHistory(room);
  logfile := Files.Old(room);
  IF logfile = NIL THEN logfile := Files.New(room) END;
  IF logfile # NIL THEN
    IF Files.Length(logfile) > 0 THEN
      Files.Set(logRider, logfile, Files.Length(logfile) - 1); Files.Read(logRider, byte);
      IF byte # 10 THEN Files.Write(logRider, 10); Files.Register(logfile) END
    ELSE Files.Set(logRider, logfile, 0)
    END
  END;
  IF transportName = "plain" THEN transport := IRCTCP.New() ELSE transport := IRCTLS.New() END;
  inst := IRC.New(config, transport, onMessage, onState); started := IRC.Start(inst);
  Out.String("Remembering up to "); Out.Int(historyLength, 0); Out.String(" messages in "); Out.String(room); Out.Ln;
  WHILE inst.state # IRC.Stopped DO IRC.Poll(inst); sendReply(inst); Platform.Delay(10) END;
  IF logfile # NIL THEN Files.Register(logfile); Files.Close(logfile) END;
  IF ~started OR failed THEN HALT(3) END
END entrance;

BEGIN
  firstReply := NIL; finalReply := NIL; replyCount := 0; lastReply := 0; haveReplied := FALSE; failed := FALSE;
  Platform.SetInterruptHandler(interrupt);
  entrance
END vocbot.
