MODULE IRCProbe;
(* SPDX-License-Identifier: LGPL-3.0-only *)
IMPORT IRC, IRCTCP, IRCTLS, Args, Platform, Out, IntStr, Strings := oocStrings;
VAR c: IRC.Client; config: IRC.Config; transport: IRC.Transport;
  mode, host, port: ARRAY 256 OF CHAR; result: SHORTINT; ok: BOOLEAN; i: INTEGER;

PROCEDURE State(c: IRC.Client; state, error: INTEGER; detail: ARRAY OF CHAR);
VAR line: ARRAY 128 OF CHAR; accepted: BOOLEAN;
BEGIN
  Out.String("state "); Out.Int(state, 0); Out.String(" error "); Out.Int(error, 0); Out.String(" "); Out.String(detail); Out.Ln;
  IF (state = IRC.Ready) & (error = 0) THEN accepted := IRC.SendRaw(c, "JOIN #one"); accepted := IRC.SendRaw(c, "JOIN #two") END
END State;
PROCEDURE Message(c: IRC.Client; VAR m: IRC.Message);
VAR accepted: BOOLEAN; text: ARRAY 400 OF CHAR;
BEGIN
  IF (m.command = "PRIVMSG") & (m.count = 2) THEN
    IF m.params[1]^ = "stop" THEN IRC.Stop(c)
    ELSE
      COPY("echo ", text); Strings.Append(m.params[1]^, text); accepted := IRC.Privmsg(c, "#events", text)
    END
  END
END Message;
PROCEDURE Interrupt(code: LONGINT);
BEGIN IF c # NIL THEN IRC.Stop(c) END; HALT(0) END Interrupt;

BEGIN
  Args.Get(1, host); Args.Get(2, port); Args.Get(3, mode);
  IRC.DefaultConfig(config); COPY(host, config.host); IntStr.StrToInt(port, config.port, result);
  config.nick := "probe"; config.user := "user"; config.realName := "owner";
  config.connectTimeout := 5000; config.replyTimeout := 1000; config.idleTimeout := 600;
  config.retryDelay := 100; config.maxRetryDelay := 400;
  IF mode = "tls" THEN transport := IRCTLS.New()
  ELSE transport := IRCTCP.New()
  END;
  IF (mode = "tls") OR (mode = "sasl") OR (mode = "policy") THEN config.saslUser := "account"; config.saslPassword := "secret" END;
  IF (mode = "sasl") OR (mode = "chunk") THEN config.allowInsecureSASL := TRUE END;
  IF mode = "chunk" THEN
    FOR i := 0 TO 254 DO config.saslUser[i] := "a" END; config.saslUser[255] := 0X;
    FOR i := 0 TO 42 DO config.saslPassword[i] := "x" END; config.saslPassword[43] := 0X
  END;
  c := IRC.New(config, transport, Message, State); Platform.SetInterruptHandler(Interrupt);
  ok := IRC.Start(c); IRC.Loop(c)
END IRCProbe.
