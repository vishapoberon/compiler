MODULE testUnixTerminalExit;

IMPORT Terminals := ulmTerminals, UnixTerminals := ulmUnixTerminals;

BEGIN
  ASSERT(Terminals.console # NIL);
  Terminals.Echo(Terminals.console, Terminals.off);
  Terminals.SetTermMode(Terminals.console, Terminals.raw)
END testUnixTerminalExit.
