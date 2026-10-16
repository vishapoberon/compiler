MODULE InitInterruptProbe;

  IMPORT SYSTEM;
  VAR completed: BOOLEAN;
  PROCEDURE -AInclude '#include <signal.h>';
  PROCEDURE -Interrupt 'raise(SIGINT)';
  PROCEDURE Check*;
  BEGIN ASSERT(completed) END Check;

BEGIN Interrupt; completed := TRUE
END InitInterruptProbe.
