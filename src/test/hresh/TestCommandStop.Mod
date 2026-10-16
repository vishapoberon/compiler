MODULE TestCommandStop;

  IMPORT SYSTEM, Platform, Oberon, Heap, Out, SharedModules, Native := TestCommandNative;

  VAR stops, callbacks: INTEGER; status: SYSTEM.INT32;
    listener: SYSTEM.INT32;
    signals: INTEGER;

  PROCEDURE Stopped;
  BEGIN
    INC(stops);
    IF listener >= 0 THEN Native.Close(listener); listener := -1 END
  END Stopped;

  PROCEDURE Callback;
  BEGIN INC(callbacks) END Callback;

  PROCEDURE Signal(signal: SYSTEM.INT32);
  BEGIN ASSERT(signal = 2); INC(signals) END Signal;

  PROCEDURE Stop;
  BEGIN
    Oberon.OnStop(Stopped); Oberon.OnStop(Stopped);
    Native.Interrupt;
    HALT(99) (* The next Oberon statement is never executed. *)
  END Stop;

  PROCEDURE NativeCall;
  BEGIN Native.NativeCallback(Callback); HALT(99)
  END NativeCall;

  PROCEDURE While;
  BEGIN WHILE Native.InterruptingCondition() DO END
  END While;

  PROCEDURE Repeat;
  BEGIN REPEAT UNTIL ~Native.InterruptingCondition()
  END Repeat;

  PROCEDURE Critical;
  BEGIN
    Heap.Lock; Native.Interrupt; INC(callbacks); Heap.Unlock;
    HALT(99)
  END Critical;

  PROCEDURE Nested;
  BEGIN ASSERT(Platform.RunCommand(Callback) < 0)
  END Nested;

  PROCEDURE Masked;
  BEGIN Native.Interrupt END Masked;

  PROCEDURE Initialize;
    VAR module: SharedModules.Module;
  BEGIN module := SharedModules.ThisMod("InitInterruptProbe"); HALT(99)
  END Initialize;

  PROCEDURE CheckInitializer;
    VAR module: SharedModules.Module; command: SharedModules.Command;
  BEGIN
    module := SharedModules.ThisMod("InitInterruptProbe"); ASSERT(module # NIL);
    command := SharedModules.ThisCommand(module, "Check"); ASSERT(command # NIL); command
  END CheckInitializer;

  PROCEDURE Spin;
  BEGIN ASSERT(Native.StartInterrupt()); LOOP END
  END Spin;

  PROCEDURE Socket;
    VAR connection: SYSTEM.INT32;
  BEGIN
    Oberon.OnStop(Stopped);
    Platform.CommandCritical(TRUE); listener := Native.Listen(); ASSERT(listener >= 0);
    Platform.CommandCritical(FALSE);
    ASSERT(Native.StartInterrupt()); connection := Native.Accept(listener);
    HALT(99)
  END Socket;

  PROCEDURE Run(command: Platform.Command);
  BEGIN
    status := Platform.RunCommand(command);
    ASSERT(status = 2); (* SIGINT on supported Unix hosts *)
    Oberon.Stopped; Heap.GC(TRUE)
  END Run;

BEGIN
  listener := -1;
  Native.SignalHandler(TRUE);
  Run(Stop); ASSERT(stops = 1);
  Run(Stop); ASSERT(stops = 2); (* Persistent, deduplicated stop callbacks. *)
  Run(NativeCall); ASSERT(Native.NativeReturned()); ASSERT(callbacks = 1);
  Run(While); Run(Repeat);
  Run(Critical); ASSERT(callbacks = 2);
  Run(Initialize); CheckInitializer;
  Run(Spin); ASSERT(Native.WaitInterrupt());
  Run(Socket); ASSERT(Native.WaitInterrupt()); ASSERT(listener = -1); ASSERT(Native.ListenerClosed());
  ASSERT(Platform.RunCommand(Nested) = 0);
  ASSERT(Platform.RunCommand(NIL) < 0);
  ASSERT(Platform.RunCommand(Callback) = 0); ASSERT(callbacks = 3);
  Native.Interrupt; ASSERT(Native.PreviousSignals() = 1); (* Previous SIGINT disposition restored. *)
  Native.BlockInterrupt(TRUE); ASSERT(Platform.RunCommand(Masked) = 0);
  ASSERT(Native.PreviousSignals() = 1); Native.BlockInterrupt(FALSE);
  ASSERT(Native.PreviousSignals() = 2); (* The caller's mask and pending signal are preserved. *)
  Native.SignalHandler(FALSE);
  Platform.SetInterruptHandler(Signal); Native.Interrupt; Native.Interrupt;
  ASSERT(signals = 2); (* Runtime signal handlers remain installed after delivery. *)
  Out.String("command stop tests passed"); Out.Ln
END TestCommandStop.
