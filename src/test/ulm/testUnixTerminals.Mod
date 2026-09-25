MODULE testUnixTerminals;

IMPORT Streams := ulmStreams, Terminals := ulmTerminals,
  UnixTerminals := ulmUnixTerminals, Write := ulmWrite;

VAR status: Terminals.Status; caps: Terminals.CapabilitySet;

BEGIN
  ASSERT(Terminals.console # NIL);
  ASSERT(Streams.stdout = Terminals.console);
  caps := Terminals.Capabilities(Terminals.console);
  ASSERT(Terminals.setEcho IN caps);
  ASSERT(Terminals.setTermMode IN caps);

  Terminals.GetStatus(Terminals.console, status);
  ASSERT((status.lines > 0) & (status.columns > 0));

  Terminals.Echo(Terminals.console, Terminals.off);
  Terminals.Echo(Terminals.console, Terminals.on);
  Terminals.SetTermMode(Terminals.console, Terminals.raw);
  Terminals.SetTermMode(Terminals.console, Terminals.cooked);

  Write.String("ulmUnixTerminals ok");
  Write.Ln;
  ASSERT(Streams.Close(Terminals.console))
END testUnixTerminals.
