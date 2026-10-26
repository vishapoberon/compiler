MODULE Config;
(*  Read the oolng-xmpp configuration file, an INI-like text file:

        [name]
        jid=user@example.com
        password=secret
        message=Hello world
        host=example.com
        port=5222

    Only `jid', `password', `message', `host' and `port' are interpreted.
    The default location is $HOME/.config/oolng-xmpp.conf; override it with the
    XMPP_CONFIG environment variable.  Each setting can also be given (or
    overridden) via XMPP_JID, XMPP_PASSWORD, XMPP_MESSAGE, XMPP_HOST,
    XMPP_PORT. *)

IMPORT Files, TextRider, Strings, CStr, Runtime;

TYPE
  Config* = RECORD
    path*: ARRAY 512 OF CHAR;
    loaded*: BOOLEAN;          (* config file was found and opened *)
    name*: ARRAY 128 OF CHAR;
    jid*: ARRAY 256 OF CHAR;
    password*: ARRAY 256 OF CHAR;
    message*: ARRAY 2048 OF CHAR;
    host*: ARRAY 256 OF CHAR;
    port*: ARRAY 16 OF CHAR;
  END;

VAR
  env: ARRAY 2048 OF CHAR;

PROCEDURE DefaultPath* (VAR path: ARRAY OF CHAR);
(*  $HOME/.config/oolng-xmpp.conf  *)
VAR
  home: ARRAY 256 OF CHAR;
BEGIN
  CStr.CopyOut(Runtime.getenv("HOME"), home);
  IF home[0] = 0X THEN
    COPY ("/etc/oolng-xmpp.conf", path)
  ELSE
    Strings.Concat(home, "/.config/oolng-xmpp.conf", path)
  END
END DefaultPath;

PROCEDURE IsSpace (ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = " ") OR (ch = 09X) OR (ch = 0DX) OR (ch = 0AX)
END IsSpace;

PROCEDURE Trim (VAR s: ARRAY OF CHAR);
VAR
  i, j, len: LONGINT;
BEGIN
  len := Strings.Length(s);
  i := 0;
  WHILE (i < len) & IsSpace(s[i]) DO INC(i) END;
  IF i > 0 THEN
    j := 0;
    WHILE i + j <= len DO
      s[j] := s[i + j];
      INC(j)
    END
  END;
  len := Strings.Length(s);
  WHILE (len > 0) & IsSpace(s[len - 1]) DO DEC(len) END;
  IF len < LEN(s) THEN s[len] := 0X END
END Trim;

PROCEDURE Process (line: ARRAY OF CHAR; VAR cfg: Config);
VAR
  len, pos: INTEGER;
  key, value: ARRAY 1024 OF CHAR;
BEGIN
  len := Strings.Length(line);
  IF len = 0 THEN RETURN END;

  IF (line[0] = "[") & (line[len - 1] = "]") THEN
    Strings.Extract(line, 1, len - 2, cfg.name);
    RETURN
  END;

  pos := 0;
  WHILE (pos < len) & (line[pos] # "=") DO INC(pos) END;
  IF pos >= len THEN RETURN END;

  Strings.Extract(line, 0, pos, key);
  Strings.Extract(line, pos + 1, len - pos - 1, value);
  Trim(key); Trim(value);

  IF Strings.Equal(key, "jid") THEN Strings.Assign(value, cfg.jid)
  ELSIF Strings.Equal(key, "password") THEN Strings.Assign(value, cfg.password)
  ELSIF Strings.Equal(key, "message") THEN Strings.Assign(value, cfg.message)
  ELSIF Strings.Equal(key, "host") THEN Strings.Assign(value, cfg.host)
  ELSIF Strings.Equal(key, "port") THEN Strings.Assign(value, cfg.port)
  END
END Process;

PROCEDURE Read* (path: ARRAY OF CHAR; VAR cfg: Config): BOOLEAN;
VAR
  f: Files.File;
  tr: TextRider.Reader;
  res: Files.Result;
  line: ARRAY 1024 OF CHAR;
BEGIN
  cfg.loaded := FALSE;
  cfg.name[0] := 0X; cfg.jid[0] := 0X; cfg.password[0] := 0X;
  cfg.message[0] := 0X; cfg.host[0] := 0X; cfg.port[0] := 0X;

  f := Files.Old(path, {Files.read}, res);
  IF f = NIL THEN RETURN FALSE END;

  tr := TextRider.ConnectReader(f);
  LOOP
    tr.ReadLine(line);
    IF tr.res # TextRider.done THEN EXIT END;
    Process(line, cfg)
  END;
  f.Close();
  cfg.loaded := TRUE;
  RETURN TRUE
END Read;

PROCEDURE Over (name: ARRAY OF CHAR; VAR field: ARRAY OF CHAR);
(*  If environment variable NAME is set and non-empty, it replaces FIELD.  *)
BEGIN
  CStr.CopyOut(Runtime.getenv(name), env);
  IF env[0] # 0X THEN Strings.Assign(env, field) END
END Over;

PROCEDURE Load* (VAR cfg: Config);
(*  Read the config file and apply environment overrides.  *)
BEGIN
  CStr.CopyOut(Runtime.getenv("XMPP_CONFIG"), cfg.path);
  IF cfg.path[0] = 0X THEN DefaultPath(cfg.path) END;
  cfg.loaded := Read(cfg.path, cfg);

  Over("XMPP_JID", cfg.jid);
  Over("XMPP_PASSWORD", cfg.password);
  Over("XMPP_MESSAGE", cfg.message);
  Over("XMPP_HOST", cfg.host);
  Over("XMPP_PORT", cfg.port);

  IF cfg.message[0] = 0X THEN
    COPY ("Hi! Welcome to my blog.", cfg.message)
  END
END Load;

END Config.
