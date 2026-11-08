MODULE IRC;
(* SPDX-License-Identifier: LGPL-3.0-only *)

IMPORT Platform, Strings := oocStrings;

CONST
  MaxLine* = 8703; MaxParams* = 15; QueueLimit* = 64;
  Stopped* = 0; Waiting* = 1; Connecting* = 2; Registering* = 3; Ready* = 4;
  BadConfig* = 1; NetworkError* = 2; TimedOut* = 3; BadMessage* = 4;
  AuthError* = 5; NickError* = 6; JoinError* = 7;
  Pending* = 0; Connected* = 1; Failed* = -1; WouldBlock* = -2;
  CR* = 0DX; LF* = 0AX;

TYPE
  Text* = POINTER TO ARRAY OF CHAR;
  Message* = RECORD
    raw*, tags*, prefix*: Text;
    command*: ARRAY 16 OF CHAR;
    count*: INTEGER;
    params*: ARRAY MaxParams OF Text;
    trailing*: BOOLEAN
  END;
  Transport* = POINTER TO TransportDesc;
  TransportDesc* = RECORD
    secure*: BOOLEAN;
    Open*: PROCEDURE(t: Transport; host: ARRAY OF CHAR; port, timeout: LONGINT): BOOLEAN;
    Poll*: PROCEDURE(t: Transport): INTEGER;
    Read*, Write*: PROCEDURE(t: Transport; VAR bytes: ARRAY OF CHAR; offset, count: LONGINT): LONGINT;
    Close*: PROCEDURE(t: Transport)
  END;
  Config* = RECORD
    host*: ARRAY 256 OF CHAR;
    port*: LONGINT;
    nick*, user*, realName*: ARRAY 128 OF CHAR;
    password*, saslUser*, saslPassword*: ARRAY 256 OF CHAR;
    allowInsecureSASL*: BOOLEAN;
    connectTimeout*, replyTimeout*, idleTimeout*, retryDelay*, maxRetryDelay*: LONGINT
  END;
  Client* = POINTER TO ClientDesc;
  OnMessage* = PROCEDURE(client: Client; VAR message: Message);
  OnState* = PROCEDURE(client: Client; state, error: INTEGER; detail: ARRAY OF CHAR);
  Frame = POINTER TO FrameDesc;
  FrameDesc = RECORD data: ARRAY 513 OF CHAR; length, offset: LONGINT; next: Frame END;
  ClientDesc* = RECORD
    state-: INTEGER;
    nick-: ARRAY 128 OF CHAR;
    channelTypes-: ARRAY 32 OF CHAR;
    nickLength-: INTEGER;
    onMessage*: OnMessage;
    onState*: OnState;
    config: Config;
    transport: Transport;
    line: ARRAY MaxLine + 1 OF CHAR;
    used: INTEGER;
    first, last, controlFirst, controlLast, writing: Frame;
    queued: INTEGER;
    started, lastReceived, pingSent, writeStarted, retryStarted, retryWait: LONGINT;
    busy, firstAttempt, pingPending, capEnded, saslRequested, saslSent, saslDone: BOOLEAN;
    offered: ARRAY 4096 OF CHAR;
    caseMapping: INTEGER
  END;

PROCEDURE CopyText(source: ARRAY OF CHAR; start, count: INTEGER): Text;
VAR text: Text; i: INTEGER;
BEGIN
  NEW(text, count + 1);
  FOR i := 0 TO count - 1 DO text[i] := source[start + i] END;
  text[count] := 0X; RETURN text
END CopyText;

PROCEDURE Upper(c: CHAR): CHAR;
BEGIN
  IF (c >= "a") & (c <= "z") THEN RETURN CAP(c) END;
  RETURN c
END Upper;

PROCEDURE Parse*(line: ARRAY OF CHAR; VAR message: Message): BOOLEAN;
VAR i, start, length, j, body: INTEGER; c: CHAR; numeric: BOOLEAN;
BEGIN
  length := 0;
  WHILE (length < LEN(line)) & (line[length] # 0X) DO INC(length) END;
  IF (length = 0) OR (length > MaxLine) OR (length = LEN(line)) THEN RETURN FALSE END;
  FOR i := 0 TO length - 1 DO IF (line[i] = CR) OR (line[i] = LF) THEN RETURN FALSE END END;
  message.raw := CopyText(line, 0, length); message.tags := CopyText("", 0, 0);
  message.prefix := CopyText("", 0, 0); message.count := 0; message.trailing := FALSE;
  FOR i := 0 TO MaxParams - 1 DO message.params[i] := NIL END;
  i := 0;
  IF line[i] = "@" THEN
    INC(i); start := i;
    WHILE (line[i] # 0X) & (line[i] # " ") DO INC(i) END;
    IF (i = start) OR (i - start > 8190) OR (line[i] = 0X) THEN RETURN FALSE END;
    message.tags := CopyText(line, start, i - start);
    WHILE line[i] = " " DO INC(i) END
  END;
  body := i;
  IF length - body > 510 THEN RETURN FALSE END;
  IF line[i] = ":" THEN
    INC(i); start := i;
    WHILE (line[i] # 0X) & (line[i] # " ") DO INC(i) END;
    IF (i = start) OR (line[i] = 0X) THEN RETURN FALSE END;
    message.prefix := CopyText(line, start, i - start);
    WHILE line[i] = " " DO INC(i) END
  END;
  start := i;
  WHILE (line[i] # 0X) & (line[i] # " ") DO INC(i) END;
  IF (i = start) OR (i - start >= LEN(message.command)) THEN RETURN FALSE END;
  numeric := (i - start = 3) & (line[start] >= "0") & (line[start] <= "9");
  FOR j := start TO i - 1 DO
    c := Upper(line[j]);
    IF numeric THEN IF (c < "0") OR (c > "9") THEN RETURN FALSE END
    ELSIF (c < "A") OR (c > "Z") THEN RETURN FALSE
    END;
    message.command[j - start] := c
  END;
  message.command[i - start] := 0X;
  LOOP
    WHILE line[i] = " " DO INC(i) END;
    IF line[i] = 0X THEN EXIT END;
    IF message.count = MaxParams THEN RETURN FALSE END;
    IF line[i] = ":" THEN
      INC(i); message.params[message.count] := CopyText(line, i, length - i);
      INC(message.count); message.trailing := TRUE; RETURN TRUE
    END;
    start := i;
    WHILE (line[i] # 0X) & (line[i] # " ") DO INC(i) END;
    message.params[message.count] := CopyText(line, start, i - start); INC(message.count)
  END;
  RETURN TRUE
END Parse;

PROCEDURE Tag*(VAR message: Message; key: ARRAY OF CHAR; VAR value: ARRAY OF CHAR): BOOLEAN;
VAR i, start, equal, finish, j, k: INTEGER; name: Text; c: CHAR;
BEGIN
  IF LEN(value) = 0 THEN RETURN FALSE END;
  value[0] := 0X; i := 0;
  WHILE message.tags[i] # 0X DO
    start := i; equal := -1;
    WHILE (message.tags[i] # 0X) & (message.tags[i] # ";") DO
      IF (message.tags[i] = "=") & (equal < 0) THEN equal := i END;
      INC(i)
    END;
    finish := i; IF equal < 0 THEN equal := finish END;
    name := CopyText(message.tags^, start, equal - start);
    IF name^ = key THEN
      j := equal + 1; k := 0;
      WHILE j < finish DO
        c := message.tags[j]; INC(j);
        IF c = 5CX THEN
          IF j = finish THEN value[k] := 0X; RETURN TRUE END;
          c := message.tags[j]; INC(j);
          CASE c OF ":": c := ";" | "s": c := " " | "r": c := CR | "n": c := LF ELSE END
        END;
        IF k >= LEN(value) - 1 THEN RETURN FALSE END;
        value[k] := c; INC(k)
      END;
      value[k] := 0X; RETURN TRUE
    END;
    IF message.tags[i] = ";" THEN INC(i) END
  END;
  RETURN FALSE
END Tag;

PROCEDURE Nick*(VAR message: Message; VAR nick: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (message.prefix[i] # 0X) & (message.prefix[i] # "!") & (message.prefix[i] # "@") DO INC(i) END;
  Strings.Extract(message.prefix^, 0, i, nick)
END Nick;

PROCEDURE Fold(c: CHAR; mapping: INTEGER): CHAR;
BEGIN
  c := Upper(c);
  IF mapping # 0 THEN
    CASE c OF "{": c := "[" | "}": c := "]" | "|": c := 5CX ELSE END;
    IF (mapping = 2) & (c = "~") THEN c := "^" END
  END;
  RETURN c
END Fold;

PROCEDURE SameName*(client: Client; left, right: ARRAY OF CHAR): BOOLEAN;
VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (left[i] # 0X) & (right[i] # 0X) & (Fold(left[i], client.caseMapping) = Fold(right[i], client.caseMapping)) DO INC(i) END;
  RETURN left[i] = right[i]
END SameName;

PROCEDURE IsChannel*(client: Client; name: ARRAY OF CHAR): BOOLEAN;
VAR i: INTEGER;
BEGIN
  IF name[0] = 0X THEN RETURN FALSE END;
  i := 0;
  WHILE client.channelTypes[i] # 0X DO IF client.channelTypes[i] = name[0] THEN RETURN TRUE END; INC(i) END;
  RETURN FALSE
END IsChannel;

PROCEDURE Elapsed(since: LONGINT): LONGINT;
VAR now: LONGINT;
BEGIN
  now := Platform.Time();
  IF now < since THEN RETURN (MAX(LONGINT) - since) + now END;
  RETURN now - since
END Elapsed;

PROCEDURE DefaultConfig*(VAR config: Config);
BEGIN
  config.host := ""; config.port := 6697; config.nick := ""; config.user := ""; config.realName := "";
  config.password := ""; config.saslUser := ""; config.saslPassword := ""; config.allowInsecureSASL := FALSE;
  config.connectTimeout := 30000; config.replyTimeout := 60000; config.idleTimeout := 240000;
  config.retryDelay := 23000; config.maxRetryDelay := 300000
END DefaultConfig;

PROCEDURE New*(VAR config: Config; transport: Transport; onMessage: OnMessage; onState: OnState): Client;
VAR client: Client;
BEGIN
  NEW(client); client.config := config; client.transport := transport; client.onMessage := onMessage;
  client.onState := onState; client.state := Stopped; client.nick := config.nick;
  client.caseMapping := 2; client.channelTypes := "#&"; client.nickLength := 127; client.busy := FALSE;
  RETURN client
END New;

PROCEDURE Notify(client: Client; error: INTEGER; detail: ARRAY OF CHAR);
BEGIN
  IF client.onState # NIL THEN client.onState(client, client.state, error, detail) END
END Notify;

PROCEDURE Clear(client: Client);
BEGIN
  IF (client.transport # NIL) & (client.transport.Close # NIL) THEN client.transport.Close(client.transport) END;
  client.first := NIL; client.last := NIL; client.controlFirst := NIL; client.controlLast := NIL;
  client.writing := NIL; client.queued := 0; client.used := 0; client.pingPending := FALSE
END Clear;

PROCEDURE Stop*(client: Client);
BEGIN
  Clear(client); client.state := Stopped; Notify(client, 0, "stopped")
END Stop;

PROCEDURE Fail(client: Client; error: INTEGER; detail: ARRAY OF CHAR; fatal: BOOLEAN);
BEGIN
  Clear(client);
  IF fatal THEN client.state := Stopped
  ELSE
    client.state := Waiting; client.firstAttempt := FALSE; client.retryStarted := Platform.Time();
    client.retryWait := client.retryWait * 2;
    IF client.retryWait > client.config.maxRetryDelay THEN client.retryWait := client.config.maxRetryDelay END
  END;
  Notify(client, error, detail)
END Fail;

PROCEDURE Safe(text: ARRAY OF CHAR; word: BOOLEAN): BOOLEAN;
VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE text[i] # 0X DO
    IF (text[i] = CR) OR (text[i] = LF) OR (word & (text[i] <= " ")) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END Safe;

PROCEDURE Start*(client: Client): BOOLEAN;
BEGIN
  Clear(client);
  IF (client.transport = NIL) OR (client.transport.Open = NIL) OR (client.transport.Poll = NIL) OR
     (client.transport.Read = NIL) OR (client.transport.Write = NIL) OR (client.transport.Close = NIL) OR
     (client.config.host = "") OR (client.config.nick = "") OR
     (client.config.user = "") OR ~Safe(client.config.host, TRUE) OR ~Safe(client.config.nick, TRUE) OR
     ~Safe(client.config.user, TRUE) OR ~Safe(client.config.realName, FALSE) OR ~Safe(client.config.password, FALSE) OR
     (client.config.port < 1) OR (client.config.port > 65535) OR (client.config.connectTimeout <= 0) OR
     (client.config.replyTimeout <= 0) OR (client.config.idleTimeout <= 0) OR (client.config.retryDelay < 0) OR
     (client.config.maxRetryDelay < client.config.retryDelay) OR (client.config.maxRetryDelay > 3600000) THEN
    client.state := Stopped; Notify(client, BadConfig, "invalid configuration"); RETURN FALSE
  END;
  client.state := Waiting; client.firstAttempt := TRUE; client.retryWait := client.config.retryDelay DIV 2;
  Notify(client, 0, "starting"); RETURN TRUE
END Start;

PROCEDURE Enqueue(client: Client; line: ARRAY OF CHAR; control: BOOLEAN): BOOLEAN;
VAR frame: Frame; length: INTEGER;
BEGIN
  length := Strings.Length(line);
  IF (client.state < Registering) OR (length = 0) OR (length > 510) OR ~Safe(line, FALSE) OR
     (client.queued >= QueueLimit) OR (~control & (client.queued >= QueueLimit - 8)) THEN RETURN FALSE END;
  NEW(frame); COPY(line, frame.data); frame.data[length] := CR; frame.data[length + 1] := LF;
  frame.data[length + 2] := 0X; frame.length := length + 2; frame.offset := 0; frame.next := NIL;
  IF control THEN
    IF client.controlFirst = NIL THEN client.controlFirst := frame ELSE client.controlLast.next := frame END;
    client.controlLast := frame
  ELSE
    IF client.first = NIL THEN client.first := frame ELSE client.last.next := frame END;
    client.last := frame
  END;
  INC(client.queued); RETURN TRUE
END Enqueue;

PROCEDURE Control(client: Client; line: ARRAY OF CHAR);
BEGIN
  IF ~Enqueue(client, line, TRUE) THEN Fail(client, NetworkError, "control queue exhausted", FALSE) END
END Control;

PROCEDURE SendRaw*(client: Client; line: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF client.state # Ready THEN RETURN FALSE END;
  RETURN Enqueue(client, line, FALSE)
END SendRaw;

PROCEDURE Privmsg*(client: Client; destination, text: ARRAY OF CHAR): BOOLEAN;
VAR line: ARRAY 511 OF CHAR;
BEGIN
  IF (destination = "") OR ~Safe(destination, TRUE) OR (destination[0] = ":") OR
     ~Safe(text, FALSE) OR (Strings.Length(destination) + Strings.Length(text) + 10 > 510) THEN RETURN FALSE END;
  COPY("PRIVMSG ", line); Strings.Append(destination, line); Strings.Append(" :", line); Strings.Append(text, line);
  RETURN SendRaw(client, line)
END Privmsg;

PROCEDURE Flush(client: Client);
VAR n, operations: LONGINT; frame: Frame;
BEGIN
  operations := 0;
  WHILE (client.state >= Registering) & (operations < 8) DO
    IF client.writing = NIL THEN
      IF client.controlFirst # NIL THEN
        client.writing := client.controlFirst; client.controlFirst := client.controlFirst.next;
        IF client.controlFirst = NIL THEN client.controlLast := NIL END
      ELSIF client.first # NIL THEN
        client.writing := client.first; client.first := client.first.next;
        IF client.first = NIL THEN client.last := NIL END
      ELSE RETURN
      END;
      client.writeStarted := Platform.Time()
    END;
    frame := client.writing;
    n := client.transport.Write(client.transport, frame.data, frame.offset, frame.length - frame.offset);
    INC(operations);
    IF n > 0 THEN
      IF n > frame.length - frame.offset THEN Fail(client, NetworkError, "invalid transport write count", TRUE); RETURN END;
      INC(frame.offset, n);
      IF frame.offset = frame.length THEN client.writing := NIL; DEC(client.queued) END
    ELSIF n # WouldBlock THEN Fail(client, NetworkError, "write failed", FALSE); RETURN
    ELSE
      IF Elapsed(client.writeStarted) >= client.config.replyTimeout THEN Fail(client, TimedOut, "write timed out", FALSE) END;
      RETURN
    END
  END
END Flush;

PROCEDURE HasWord(list, word: ARRAY OF CHAR): BOOLEAN;
VAR i, start: INTEGER; token: Text;
BEGIN
  i := 0;
  WHILE list[i] # 0X DO
    WHILE list[i] = " " DO INC(i) END;
    start := i; WHILE (list[i] # 0X) & (list[i] # " ") & (list[i] # "=") DO INC(i) END;
    token := CopyText(list, start, i - start); IF token^ = word THEN RETURN TRUE END;
    WHILE (list[i] # 0X) & (list[i] # " ") DO INC(i) END
  END;
  RETURN FALSE
END HasWord;

PROCEDURE EndCAP(client: Client);
BEGIN
  IF ~client.capEnded THEN client.capEnded := TRUE; Control(client, "CAP END") END
END EndCAP;

PROCEDURE SASL(client: Client);
CONST alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
VAR raw: ARRAY 514 OF CHAR; encoded: ARRAY 689 OF CHAR; letters: ARRAY 65 OF CHAR;
  i, n, at, value, take, out: INTEGER; line: ARRAY 511 OF CHAR; part: ARRAY 401 OF CHAR;
BEGIN
  letters := alphabet; n := 0; raw[n] := 0X; INC(n);
  i := 0; WHILE client.config.saslUser[i] # 0X DO raw[n] := client.config.saslUser[i]; INC(i); INC(n) END;
  raw[n] := 0X; INC(n);
  i := 0; WHILE client.config.saslPassword[i] # 0X DO raw[n] := client.config.saslPassword[i]; INC(i); INC(n) END;
  at := 0; out := 0;
  WHILE at < n DO
    take := n - at; IF take > 3 THEN take := 3 END;
    value := ORD(raw[at]); encoded[out] := letters[value DIV 4]; INC(out);
    value := value MOD 4 * 16;
    IF take > 1 THEN value := value + ORD(raw[at + 1]) DIV 16 END;
    encoded[out] := letters[value]; INC(out);
    IF take > 1 THEN
      value := ORD(raw[at + 1]) MOD 16 * 4;
      IF take > 2 THEN value := value + ORD(raw[at + 2]) DIV 64 END;
      encoded[out] := letters[value]
    ELSE encoded[out] := "="
    END;
    INC(out);
    IF take > 2 THEN encoded[out] := letters[ORD(raw[at + 2]) MOD 64] ELSE encoded[out] := "=" END;
    INC(out); INC(at, take)
  END;
  encoded[out] := 0X; at := 0;
  WHILE at < out DO
    take := out - at; IF take > 400 THEN take := 400 END;
    Strings.Extract(encoded, at, take, part); COPY("AUTHENTICATE ", line); Strings.Append(part, line);
    Control(client, line); INC(at, take)
  END;
  IF out MOD 400 = 0 THEN Control(client, "AUTHENTICATE +") END;
  FOR i := 0 TO LEN(raw) - 1 DO raw[i] := 0X END;
  FOR i := 0 TO LEN(encoded) - 1 DO encoded[i] := 0X END
END SASL;

PROCEDURE Register(client: Client);
VAR line: ARRAY 511 OF CHAR;
BEGIN
  client.capEnded := FALSE; client.saslRequested := FALSE; client.saslSent := FALSE;
  client.saslDone := FALSE; client.offered := "";
  IF (client.config.saslUser # "") & ~client.transport.secure & ~client.config.allowInsecureSASL THEN
    Fail(client, AuthError, "SASL PLAIN requires verified TLS", TRUE); RETURN
  END;
  IF client.config.password # "" THEN
    COPY("PASS :", line); Strings.Append(client.config.password, line); Control(client, line)
  END;
  Control(client, "CAP LS 302");
  COPY("NICK ", line); Strings.Append(client.nick, line); Control(client, line);
  COPY("USER ", line); Strings.Append(client.config.user, line); Strings.Append(" 0 * :", line);
  Strings.Append(client.config.realName, line); Control(client, line)
END Register;

PROCEDURE ISupport(client: Client; VAR message: Message);
VAR i, j, value: INTEGER; token, key: Text;
BEGIN
  FOR i := 1 TO message.count - 1 DO
    token := message.params[i];
    IF token^ = "CASEMAPPING=ascii" THEN client.caseMapping := 0
    ELSIF token^ = "CASEMAPPING=strict-rfc1459" THEN client.caseMapping := 1
    ELSIF token^ = "CASEMAPPING=rfc1459" THEN client.caseMapping := 2
    ELSIF (Strings.Length(token^) > 10) & (token[0] = "C") THEN
      IF Strings.Length(token^) < LEN(client.channelTypes) + 10 THEN
        key := CopyText(token^, 0, 10);
        IF key^ = "CHANTYPES=" THEN
          Strings.Extract(token^, 10, Strings.Length(token^) - 10, client.channelTypes)
        END
      END
    ELSIF Strings.Length(token^) > 8 THEN
      key := CopyText(token^, 0, 8);
      IF key^ = "NICKLEN=" THEN
        value := 0; j := 8;
        WHILE (token[j] >= "0") & (token[j] <= "9") & (value < 128) DO value := value * 10 + ORD(token[j]) - ORD("0"); INC(j) END;
        IF (token[j] = 0X) & (value > 0) & (value < 128) THEN client.nickLength := value END
      END
    END
  END
END ISupport;

PROCEDURE Handle(client: Client; VAR message: Message);
VAR line: ARRAY 511 OF CHAR; name: ARRAY 128 OF CHAR; request: ARRAY 128 OF CHAR;
BEGIN
  IF message.command = "PING" THEN
    IF message.count = 0 THEN Fail(client, BadMessage, "PING without a token", FALSE); RETURN END;
    COPY("PONG :", line); Strings.Append(message.params[message.count - 1]^, line); Control(client, line)
  ELSIF message.command = "PONG" THEN
    IF (message.count > 0) & (message.params[message.count - 1]^ = "voc-keepalive") THEN client.pingPending := FALSE END
  ELSIF message.command = "ERROR" THEN Fail(client, NetworkError, "server ERROR", FALSE)
  ELSIF message.command = "CAP" THEN
    IF message.count < 3 THEN Fail(client, BadMessage, "malformed CAP reply", TRUE); RETURN END;
    IF message.params[1]^ = "LS" THEN
      IF Strings.Length(client.offered) + Strings.Length(message.params[message.count - 1]^) + 1 >= LEN(client.offered) THEN
        Fail(client, BadMessage, "capability list too long", TRUE); RETURN
      END;
      Strings.Append(" ", client.offered); Strings.Append(message.params[message.count - 1]^, client.offered);
      IF (message.count > 3) & (message.params[2]^ = "*") THEN RETURN END;
      request := "";
      IF HasWord(client.offered, "message-tags") THEN Strings.Append("message-tags ", request) END;
      IF HasWord(client.offered, "server-time") THEN Strings.Append("server-time ", request) END;
      IF client.config.saslUser # "" THEN
        IF ~HasWord(client.offered, "sasl") THEN Fail(client, AuthError, "server does not offer SASL", TRUE); RETURN END;
        Strings.Append("sasl", request); client.saslRequested := TRUE
      END;
      IF request = "" THEN EndCAP(client)
      ELSE COPY("CAP REQ :", line); Strings.Append(request, line); Control(client, line)
      END
    ELSIF message.params[1]^ = "ACK" THEN
      IF client.saslRequested THEN
        IF ~HasWord(message.params[message.count - 1]^, "sasl") THEN Fail(client, AuthError, "SASL capability not acknowledged", TRUE)
        ELSE Control(client, "AUTHENTICATE PLAIN")
        END
      ELSE EndCAP(client)
      END
    ELSIF message.params[1]^ = "NAK" THEN
      IF client.saslRequested THEN Fail(client, AuthError, "SASL capability rejected", TRUE) ELSE EndCAP(client) END
    END
  ELSIF message.command = "AUTHENTICATE" THEN
    IF ~client.saslRequested OR client.saslSent OR (message.count # 1) OR (message.params[0]^ # "+") THEN
      Fail(client, AuthError, "unexpected SASL challenge", TRUE)
    ELSE client.saslSent := TRUE; SASL(client)
    END
  ELSIF message.command = "903" THEN
    IF client.saslSent THEN client.saslDone := TRUE; EndCAP(client) END
  ELSIF (message.command = "904") OR (message.command = "905") OR (message.command = "906") OR
        (message.command = "907") OR (message.command = "902") OR (message.command = "464") THEN
    Fail(client, AuthError, "authentication rejected", TRUE)
  ELSIF message.command = "421" THEN
    IF (message.count > 1) & (message.params[1]^ = "CAP") THEN
      IF client.config.saslUser # "" THEN Fail(client, AuthError, "server does not support CAP/SASL", TRUE)
      ELSE client.capEnded := TRUE
      END
    END
  ELSIF (message.command = "432") OR (message.command = "433") OR (message.command = "436") THEN
    Fail(client, NickError, "nickname rejected", message.command = "432")
  ELSIF message.command = "001" THEN
    IF (message.count = 0) OR ~client.capEnded OR ((client.config.saslUser # "") & ~client.saslDone) THEN
      Fail(client, AuthError, "welcome before registration/authentication completed", TRUE); RETURN
    END;
    IF Strings.Length(message.params[0]^) >= LEN(client.nick) THEN
      Fail(client, BadMessage, "server nickname exceeds supported length", TRUE); RETURN
    END;
    COPY(message.params[0]^, client.nick); client.state := Ready;
    client.retryWait := client.config.retryDelay DIV 2; Notify(client, 0, "registered")
  ELSIF message.command = "005" THEN ISupport(client, message)
  ELSIF (message.command = "471") OR (message.command = "473") OR (message.command = "474") OR
        (message.command = "475") OR (message.command = "476") OR (message.command = "477") THEN
    Notify(client, JoinError, "channel join rejected")
  ELSIF (message.command = "NICK") & (message.count = 1) THEN
    Nick(message, name);
    IF SameName(client, name, client.nick) THEN
      IF Strings.Length(message.params[0]^) >= LEN(client.nick) THEN
        Fail(client, BadMessage, "server nickname exceeds supported length", TRUE)
      ELSE COPY(message.params[0]^, client.nick)
      END
    END
  END
END Handle;

PROCEDURE Feed(client: Client; VAR data: ARRAY OF CHAR; count: LONGINT);
VAR i: LONGINT; message: Message;
BEGIN
  FOR i := 0 TO count - 1 DO
    IF client.state < Registering THEN RETURN END;
    IF data[i] = 0X THEN Fail(client, BadMessage, "NUL in IRC stream", FALSE); RETURN END;
    IF data[i] = LF THEN
      IF (client.used > 0) & (client.line[client.used - 1] = CR) THEN DEC(client.used) END;
      client.line[client.used] := 0X;
      IF client.used > 0 THEN
        IF ~Parse(client.line, message) THEN Fail(client, BadMessage, "invalid IRC line", FALSE); RETURN END;
        client.used := 0; Handle(client, message);
        IF client.onMessage # NIL THEN client.onMessage(client, message) END
      END
    ELSIF client.used < MaxLine THEN client.line[client.used] := data[i]; INC(client.used)
    ELSE Fail(client, BadMessage, "IRC line exceeds limit", FALSE); RETURN
    END
  END
END Feed;

PROCEDURE Poll*(client: Client);
VAR n: LONGINT; status: INTEGER; data: ARRAY 4096 OF CHAR;
BEGIN
  IF client.busy OR (client.state = Stopped) THEN RETURN END;
  client.busy := TRUE;
  IF client.state = Waiting THEN
    IF client.firstAttempt OR (Elapsed(client.retryStarted) >= client.retryWait) THEN
      client.firstAttempt := FALSE; client.started := Platform.Time(); client.state := Connecting;
      client.caseMapping := 2; client.channelTypes := "#&"; client.nickLength := 127;
      IF ~client.transport.Open(client.transport, client.config.host, client.config.port, client.config.connectTimeout) THEN
        Fail(client, NetworkError, "connection failed", FALSE)
      ELSE Notify(client, 0, "connecting")
      END
    END
  ELSIF client.state = Connecting THEN
    status := client.transport.Poll(client.transport);
    IF status = Connected THEN
      client.state := Registering; client.started := Platform.Time(); client.lastReceived := client.started;
      Register(client); IF client.state = Registering THEN Notify(client, 0, "registering") END
    ELSIF status = Failed THEN Fail(client, NetworkError, "connection or TLS verification failed", FALSE)
    ELSIF Elapsed(client.started) >= client.config.connectTimeout THEN Fail(client, TimedOut, "connection timed out", FALSE)
    END
  END;
  IF client.state >= Registering THEN
    n := client.transport.Read(client.transport, data, 0, LEN(data));
    IF n > LEN(data) THEN Fail(client, NetworkError, "invalid transport read count", TRUE)
    ELSIF n > 0 THEN client.lastReceived := Platform.Time(); Feed(client, data, n)
    ELSIF n # WouldBlock THEN Fail(client, NetworkError, "connection ended", FALSE)
    END
  END;
  IF client.state >= Registering THEN
    IF (client.state = Registering) & (Elapsed(client.started) >= client.config.replyTimeout) THEN
      Fail(client, TimedOut, "registration timed out", FALSE)
    ELSIF client.pingPending & (Elapsed(client.pingSent) >= client.config.replyTimeout) THEN
      Fail(client, TimedOut, "PONG timed out", FALSE)
    ELSIF (client.state = Ready) & ~client.pingPending & (Elapsed(client.lastReceived) >= client.config.idleTimeout) THEN
      client.pingPending := TRUE; client.pingSent := Platform.Time(); Control(client, "PING :voc-keepalive")
    END;
    Flush(client)
  END;
  client.busy := FALSE
END Poll;

PROCEDURE Loop*(client: Client);
BEGIN
  WHILE client.state # Stopped DO Poll(client); Platform.Delay(10) END
END Loop;

END IRC.
