MODULE TestCommandStop;

  IMPORT SYSTEM, Platform, Oberon, Heap, Out, SharedModules;

  VAR stops, callbacks: INTEGER; status: SYSTEM.INT32;
    listener: SYSTEM.INT32;
    signals: INTEGER;

  PROCEDURE -AInclude '#include "TestCommandSupport.h"';
  PROCEDURE -Interrupt 'VOC_TestInterrupt()';
  PROCEDURE -NativeCallback(callback: Platform.Command) 'VOC_TestNativeCallback(callback)';
  PROCEDURE -NativeReturned(): BOOLEAN 'VOC_TestNativeReturned()';
  PROCEDURE -SignalHandler(install: BOOLEAN) 'VOC_TestSignalHandler(install)';
  PROCEDURE -PreviousSignals(): INTEGER 'VOC_TestPreviousSignals()';
  PROCEDURE -InterruptingCondition(): BOOLEAN 'VOC_TestInterruptingCondition()';
  PROCEDURE -StartInterrupt(): BOOLEAN 'VOC_TestStartInterrupt()';
  PROCEDURE -WaitInterrupt(): BOOLEAN 'VOC_TestWaitInterrupt()';
  PROCEDURE -Listen(): SYSTEM.INT32 'VOC_TestListen()';
  PROCEDURE -Accept(fd: SYSTEM.INT32): SYSTEM.INT32 'VOC_TestAccept(fd)';
  PROCEDURE -Close(fd: SYSTEM.INT32) 'VOC_TestClose(fd)';
  PROCEDURE -ListenerClosed(): BOOLEAN 'VOC_TestListenerClosed()';
  PROCEDURE -BlockInterrupt(block: BOOLEAN) 'VOC_TestBlockInterrupt(block)';

  PROCEDURE Stopped;
  BEGIN
    INC(stops);
    IF listener >= 0 THEN Close(listener); listener := -1 END
  END Stopped;

  PROCEDURE Callback;
  BEGIN INC(callbacks) END Callback;

  PROCEDURE Signal(signal: SYSTEM.INT32);
  BEGIN ASSERT(signal = 2); INC(signals) END Signal;

  PROCEDURE Stop;
  BEGIN
    Oberon.OnStop(Stopped); Oberon.OnStop(Stopped);
    Interrupt;
    HALT(99) (* The next Oberon statement is never executed. *)
  END Stop;

  PROCEDURE Native;
  BEGIN NativeCallback(Callback); HALT(99)
  END Native;

  PROCEDURE While;
  BEGIN WHILE InterruptingCondition() DO END
  END While;

  PROCEDURE Repeat;
  BEGIN REPEAT UNTIL ~InterruptingCondition()
  END Repeat;

  PROCEDURE Critical;
  BEGIN
    Heap.Lock; Interrupt; INC(callbacks); Heap.Unlock;
    HALT(99)
  END Critical;

  PROCEDURE Nested;
  BEGIN ASSERT(Platform.RunCommand(Callback) < 0)
  END Nested;

  PROCEDURE Masked;
  BEGIN Interrupt END Masked;

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
  BEGIN ASSERT(StartInterrupt()); LOOP END
  END Spin;

  PROCEDURE Socket;
    VAR connection: SYSTEM.INT32;
  BEGIN
    Oberon.OnStop(Stopped);
    Platform.CommandCritical(TRUE); listener := Listen(); ASSERT(listener >= 0);
    Platform.CommandCritical(FALSE);
    ASSERT(StartInterrupt()); connection := Accept(listener);
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
  SignalHandler(TRUE);
  Run(Stop); ASSERT(stops = 1);
  Run(Stop); ASSERT(stops = 2); (* Persistent, deduplicated stop callbacks. *)
  Run(Native); ASSERT(NativeReturned()); ASSERT(callbacks = 1);
  Run(While); Run(Repeat);
  Run(Critical); ASSERT(callbacks = 2);
  Run(Initialize); CheckInitializer;
  Run(Spin); ASSERT(WaitInterrupt());
  Run(Socket); ASSERT(WaitInterrupt()); ASSERT(listener = -1); ASSERT(ListenerClosed());
  ASSERT(Platform.RunCommand(Nested) = 0);
  ASSERT(Platform.RunCommand(NIL) < 0);
  ASSERT(Platform.RunCommand(Callback) = 0); ASSERT(callbacks = 3);
  Interrupt; ASSERT(PreviousSignals() = 1); (* Previous SIGINT disposition restored. *)
  BlockInterrupt(TRUE); ASSERT(Platform.RunCommand(Masked) = 0);
  ASSERT(PreviousSignals() = 1); BlockInterrupt(FALSE);
  ASSERT(PreviousSignals() = 2); (* The caller's mask and pending signal are preserved. *)
  SignalHandler(FALSE);
  Platform.SetInterruptHandler(Signal); Interrupt; Interrupt;
  ASSERT(signals = 2); (* Runtime signal handlers remain installed after delivery. *)
  Out.String("command stop tests passed"); Out.Ln
END TestCommandStop.
