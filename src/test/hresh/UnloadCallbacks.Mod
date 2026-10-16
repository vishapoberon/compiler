MODULE UnloadCallbacks;
  IMPORT SYSTEM, Platform, Modules, Heap;

  PROCEDURE Signal(signal: SYSTEM.INT32);
  BEGIN END Signal;

  PROCEDURE Free(name: ARRAY OF CHAR; all: BOOLEAN);
  BEGIN END Free;

  PROCEDURE Hook(owner: Modules.Module);
  BEGIN END Hook;

  PROCEDURE RegisterHook*;
  BEGIN ASSERT(Heap.RegisterUnloadHook(Hook))
  END RegisterHook;

  PROCEDURE RemoveHook*;
  BEGIN ASSERT(Heap.UnregisterUnloadHook(Hook))
  END RemoveHook;

  PROCEDURE RegisterSignal*;
  BEGIN Platform.SetQuitHandler(Signal)
  END RegisterSignal;

  PROCEDURE RemoveSignal*;
  BEGIN Platform.SetQuitHandler(NIL)
  END RemoveSignal;

  PROCEDURE RegisterFree*;
  BEGIN Modules.InstallFreeHandler(Free); ASSERT(Modules.res = 0)
  END RegisterFree;
END UnloadCallbacks.
