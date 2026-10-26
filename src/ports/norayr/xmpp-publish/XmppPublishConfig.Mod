MODULE XmppPublishConfig;

(* Bounded UTF-8 configuration with environment overrides. Diagnostics identify
   settings without copying their values into messages. *)

IMPORT SYSTEM, Platform, Files := oocFiles, Channel, Msg, S := LongStrings, Strings := oocStrings;

CONST maxFileBytes* = 65536; maxLineBytes* = 16384;
TYPE
  Config* = RECORD
    path*: ARRAY 4096 OF CHAR;
    loaded*, allowPlain*, directTLS*: BOOLEAN;
    jid*, password*: ARRAY 12289 OF CHAR;
    message*: ARRAY maxLineBytes+1 OF CHAR;
    host*: ARRAY 1024 OF CHAR;
    port*: ARRAY 8 OF CHAR;
    timeoutMS*: LONGINT;
  END;

PROCEDURE Init*(VAR cfg: Config);
BEGIN
  cfg.path[0] := 0X; cfg.loaded := FALSE; cfg.allowPlain := FALSE; cfg.directTLS := FALSE;
  cfg.jid[0] := 0X; cfg.password[0] := 0X; cfg.host[0] := 0X;
  cfg.message := "Hi! Welcome to my blog."; cfg.port := "5222"; cfg.timeoutMS := 10000
END Init;

PROCEDURE Wipe*(VAR cfg: Config);
  VAR i: LONGINT;
BEGIN FOR i := 0 TO LEN(cfg.password)-1 DO cfg.password[i] := 0X END END Wipe;

PROCEDURE Copy(text: ARRAY OF CHAR; VAR field: ARRAY OF CHAR): BOOLEAN;
BEGIN IF S.Length8(text) >= LEN(field) THEN RETURN FALSE END; COPY(text, field); RETURN TRUE END Copy;

PROCEDURE Number*(text: ARRAY OF CHAR; maximum: LONGINT): LONGINT;
  VAR i, n, digit: LONGINT;
BEGIN
  IF text[0] = 0X THEN RETURN -1 END;
  n := 0;
  FOR i := 0 TO S.Length8(text)-1 DO
    digit := ORD(text[i])-ORD("0");
    IF (digit < 0) OR (digit > 9) OR (n > (maximum-digit) DIV 10) THEN RETURN -1 END;
    n := n*10+digit
  END;
  IF n = 0 THEN RETURN -1 END; RETURN n
END Number;

PROCEDURE Setting*(VAR cfg: Config; key, value: ARRAY OF CHAR): BOOLEAN;
  VAR n: LONGINT;
BEGIN
  IF key = "jid" THEN RETURN Copy(value, cfg.jid)
  ELSIF key = "password" THEN RETURN Copy(value, cfg.password)
  ELSIF key = "message" THEN RETURN Copy(value, cfg.message)
  ELSIF key = "host" THEN RETURN Copy(value, cfg.host)
  ELSIF key = "port" THEN
    IF Number(value, 65535) < 0 THEN RETURN FALSE END; RETURN Copy(value, cfg.port)
  ELSIF key = "allow_plain" THEN
    IF (value # "yes") & (value # "no") THEN RETURN FALSE END; cfg.allowPlain := value = "yes"
  ELSIF key = "tls" THEN
    IF (value # "starttls") & (value # "direct") THEN RETURN FALSE END; cfg.directTLS := value = "direct"
  ELSIF key = "timeout_ms" THEN
    n := Number(value, 60000); IF n < 0 THEN RETURN FALSE END; cfg.timeoutMS := n
  ELSE RETURN FALSE
  END;
  RETURN TRUE
END Setting;

PROCEDURE Space(byte: CHAR): BOOLEAN;
BEGIN RETURN (byte = " ") OR (byte = 09X) OR (byte = 0DX) END Space;

PROCEDURE Line(VAR cfg: Config; line: ARRAY OF CHAR): BOOLEAN;
  VAR start, end, equals, keyEnd, valueStart, i: LONGINT; key: ARRAY 64 OF CHAR;
    value: ARRAY maxLineBytes+1 OF CHAR;
BEGIN
  start := 0; end := S.Length8(line);
  WHILE (start < end) & Space(line[start]) DO INC(start) END;
  WHILE (end > start) & Space(line[end-1]) DO DEC(end) END;
  IF (start = end) OR (line[start] = "#") OR (line[start] = ";") THEN RETURN TRUE END;
  IF (line[start] = "[") & (line[end-1] = "]") THEN RETURN TRUE END;
  equals := start; WHILE (equals < end) & (line[equals] # "=") DO INC(equals) END;
  IF equals = end THEN RETURN FALSE END;
  keyEnd := equals; WHILE (keyEnd > start) & Space(line[keyEnd-1]) DO DEC(keyEnd) END;
  IF keyEnd-start >= LEN(key) THEN RETURN FALSE END;
  FOR i := start TO keyEnd-1 DO key[i-start] := line[i] END; key[keyEnd-start] := 0X;
  valueStart := equals+1; WHILE (valueStart < end) & Space(line[valueStart]) DO INC(valueStart) END;
  FOR i := valueStart TO end-1 DO value[i-valueStart] := line[i] END; value[end-valueStart] := 0X;
  RETURN Setting(cfg, key, value)
END Line;

PROCEDURE Read*(path: ARRAY OF CHAR; VAR cfg: Config; VAR absent: BOOLEAN): BOOLEAN;
  VAR file: Files.File; reader: Channel.Reader; error: Msg.Msg; byte: CHAR; octet: SYSTEM.BYTE;
    line: ARRAY maxLineBytes+1 OF CHAR; length, total: LONGINT; ok: BOOLEAN;
BEGIN
  absent := FALSE; cfg.loaded := FALSE; file := Files.Old(path, {Files.read}, error);
  IF file = NIL THEN absent := (error # NIL) & (error.code = Files.noSuchFile); RETURN FALSE END;
  reader := file.NewReader(); length := 0; total := 0; ok := TRUE;
  LOOP
    reader.ReadByte(octet); byte := SYSTEM.VAL(CHAR, octet);
    IF reader.res # NIL THEN
      ok := reader.res.code = Channel.readAfterEnd;
      IF ok & (length > 0) THEN line[length] := 0X; ok := Line(cfg, line) END;
      EXIT
    END;
    INC(total); IF (total > maxFileBytes) OR (byte = 0X) THEN ok := FALSE; EXIT END;
    IF byte = 0AX THEN
      line[length] := 0X; ok := Line(cfg, line); length := 0; IF ~ok THEN EXIT END
    ELSE
      IF length = maxLineBytes THEN ok := FALSE; EXIT END;
      line[length] := byte; INC(length)
    END
  END;
  file.Close; IF file.res # NIL THEN ok := FALSE END;
  FOR length := 0 TO LEN(line)-1 DO line[length] := 0X END;
  cfg.loaded := ok; IF ~ok THEN Wipe(cfg) END; RETURN ok
END Read;

PROCEDURE Over(VAR cfg: Config; name, key: ARRAY OF CHAR): BOOLEAN;
  VAR value: ARRAY maxLineBytes+2 OF CHAR; ok: BOOLEAN; i: LONGINT;
BEGIN
  Platform.GetEnv(name, value);
  ok := (value[0] = 0X) OR ((S.Length8(value) <= maxLineBytes) & Setting(cfg, key, value));
  FOR i := 0 TO LEN(value)-1 DO value[i] := 0X END;
  RETURN ok
END Over;

PROCEDURE Load*(VAR cfg: Config): BOOLEAN;
  VAR path, home: ARRAY 4097 OF CHAR; explicit, absent, ok: BOOLEAN;
BEGIN
  Init(cfg); Platform.GetEnv("XMPP_CONFIG", path); explicit := path[0] # 0X;
  IF ~explicit THEN
    Platform.GetEnv("HOME", home);
    IF S.Length8(home)+S.Length8("/.config/oolng-xmpp.conf") >= LEN(path) THEN RETURN FALSE END;
    IF home[0] = 0X THEN path := "/etc/oolng-xmpp.conf"
    ELSE COPY(home, path); Strings.Append("/.config/oolng-xmpp.conf", path)
    END
  END;
  IF ~Copy(path, cfg.path) THEN RETURN FALSE END;
  ok := Read(cfg.path, cfg, absent);
  IF ~ok & (explicit OR ~absent) THEN Wipe(cfg); RETURN FALSE END;
  ok := Over(cfg, "XMPP_JID", "jid") & Over(cfg, "XMPP_PASSWORD", "password") &
    Over(cfg, "XMPP_MESSAGE", "message") & Over(cfg, "XMPP_HOST", "host") & Over(cfg, "XMPP_PORT", "port") &
    Over(cfg, "XMPP_ALLOW_PLAIN", "allow_plain") & Over(cfg, "XMPP_TLS", "tls") & Over(cfg, "XMPP_TIMEOUT_MS", "timeout_ms");
  IF ~ok THEN Wipe(cfg) END;
  RETURN ok
END Load;

END XmppPublishConfig.
