MODULE TestModuleUnload;
  IMPORT SYSTEM, Modules, ModuleLoader, SharedModules, Heap, Oberon, Out, UnloadState;
  VAR m: Modules.Module; command, alias: SharedModules.CommandRef;
    retention, duplicate: Modules.Retention; before, foreignFinalized: INTEGER;
    native: SYSTEM.ADDRESS; raw: Modules.Command;

  PROCEDURE -AInclude '#include "TestModuleUnloadSupport.h"';
  PROCEDURE -Hold(command: Modules.Command): SYSTEM.ADDRESS 'VOCUnload_hold((ADDRESS)command)';
  PROCEDURE -ReleaseNative(handle: SYSTEM.ADDRESS) 'VOCUnload_release(handle)';
  PROCEDURE -Scrub(): SYSTEM.ADDRESS 'VOCUnload_scrub()';

  PROCEDURE Invoke(name: ARRAY OF CHAR);
    VAR c: Modules.Command;
  BEGIN c := SharedModules.ThisCommand(m, name); ASSERT(c # NIL); c
  END Invoke;

  PROCEDURE Free(name: ARRAY OF CHAR; expected: INTEGER);
  BEGIN
    IF expected = 0 THEN ASSERT(Scrub() = 0) END;
    Modules.Free(name, FALSE);
    IF Modules.res # expected THEN Out.String(name); Out.String(": "); Out.String(Modules.resMsg); Out.Ln END;
    ASSERT(Modules.res = expected)
  END Free;

  PROCEDURE StackRoot;
    VAR object: SYSTEM.PTR;
  BEGIN
    Invoke("Escape"); object := UnloadState.saved; UnloadState.saved := NIL;
    Free("UnloadProbe", 1); ASSERT(object # NIL);
    ASSERT(Modules.resMsg = "live objects use this module's type descriptors");
    object := NIL
  END StackRoot;

  PROCEDURE ForeignFinalize(object: SYSTEM.PTR);
  BEGIN ASSERT(object # NIL); INC(foreignFinalized)
  END ForeignFinalize;

BEGIN
  Modules.GetArg(1, SharedModules.path); COPY(SharedModules.path, ModuleLoader.path);
  Free("Heap", 1); Free("NoSuchUnloadModule", 1);
  m := SharedModules.ThisMod("UnloadProbe"); ASSERT(m # NIL);
  ASSERT(UnloadState.initialized = 1); Invoke("Check");
  ASSERT(SharedModules.ThisMod("UnloadStopClient") # NIL);
  Oberon.Stopped; ASSERT(UnloadState.stopFree = 1);
  Free("UnloadStopClient", 0);
  Invoke("SelfFree"); ASSERT(UnloadState.selfFree = 1);
  command := SharedModules.AcquireCommand(m, "Check"); ASSERT(command # NIL);
  alias := command; Free("UnloadProbe", 1);
  SharedModules.Invoke(command);
  SharedModules.ReleaseCommand(command); ASSERT(command = NIL);
  SharedModules.Invoke(alias); ASSERT(SharedModules.res # 0);
  SharedModules.ReleaseCommand(alias); ASSERT(Heap.Retained(m) = 0);
  retention := Modules.Retain(m); ASSERT(retention # NIL); duplicate := retention;
  Free("UnloadProbe", 1);
  Modules.Release(retention); ASSERT(Modules.res = 0);
  Modules.Release(duplicate); ASSERT(Modules.res # 0); ASSERT(Heap.Retained(m) = 0);
  ASSERT(SharedModules.ThisMod("UnloadClient") # NIL);
  Free("UnloadProbe", 1); Free("UnloadClient", 0);
  Invoke("Escape"); Free("UnloadProbe", 1);
  ASSERT(Modules.ThisMod("UnloadProbe") = m); Invoke("Check");
  UnloadState.saved := NIL;
  StackRoot;
  Invoke("Escape"); Heap.RegisterFinalizer(UnloadState.saved, ForeignFinalize);
  UnloadState.saved := NIL;
  Free("UnloadProbe", 1);
  ASSERT(Modules.resMsg = "live objects use this module's type descriptors");
  Heap.GC(FALSE); ASSERT(foreignFinalized = 1); Heap.GC(FALSE);
  before := UnloadState.stopped;
  Free("UnloadProbe", 0);
  ASSERT(Modules.ThisMod("UnloadProbe") = NIL);
  ASSERT(UnloadState.terminated = 1); ASSERT(UnloadState.stopped = before + 1);
  before := UnloadState.stopped; Oberon.Stopped; ASSERT(UnloadState.stopped = before);
  m := SharedModules.ThisMod("UnloadProbe"); ASSERT(m # NIL);
  ASSERT(UnloadState.initialized = 2); Invoke("Check");
  Free("UnloadProbe", 0); ASSERT(UnloadState.terminated = 2);
  ASSERT(SharedModules.ThisMod("UnloadClient") # NIL);
  Modules.Free("UnloadClient", TRUE); ASSERT(Modules.res = 0);
  ASSERT(Modules.ThisMod("UnloadClient") = NIL);
  (* Recursive freeing is best-effort; a conservative root may defer an import. *)
  IF Modules.ThisMod("UnloadProbe") # NIL THEN Free("UnloadProbe", 0) END;
  ASSERT(Modules.ThisMod("UnloadProbe") = NIL);
  ASSERT(UnloadState.terminated = 3);
  m := SharedModules.ThisMod("UnloadCallbacks"); ASSERT(m # NIL);
  Invoke("RegisterSignal"); Free("UnloadCallbacks", 1);
  ASSERT(Modules.resMsg = "retained references to this module exist");
  Invoke("RemoveSignal"); Invoke("RegisterHook"); Free("UnloadCallbacks", 1);
  Invoke("RemoveHook"); Invoke("RegisterFree");
  ModuleLoader.Free("UnloadCallbacks", FALSE); ASSERT(Modules.res = 1);
  ASSERT(Modules.resMsg = "retained references to this module exist");
  Modules.InstallFreeHandler(ModuleLoader.Free); ASSERT(Modules.res = 0);
  Free("UnloadCallbacks", 0);
  ASSERT(SharedModules.ThisMod("UnloadDamageClient") # NIL);
  m := Modules.ThisMod("UnloadResurrect"); ASSERT(m # NIL);
  Modules.Free("UnloadDamageClient", TRUE); ASSERT(Modules.res = 1);
  ASSERT(Modules.ThisMod("UnloadDamageClient") = NIL);
  ASSERT(Heap.ModuleState(m) = 4); ASSERT(UnloadState.saved # NIL);
  ASSERT(SharedModules.ThisMod("UnloadResurrect") = NIL);
  UnloadState.saved := NIL; Heap.GC(TRUE);
  ASSERT(SharedModules.ThisMod("UnloadSpawn") # NIL);
  Free("UnloadSpawn", 0);
  ASSERT(Modules.ThisMod("UnloadPinned") # NIL);
  Free("UnloadPinned", 0); (* Ownership must survive loading from a cleanup callback. *)
  m := SharedModules.ThisMod("UnloadPinned"); ASSERT(m # NIL);
  Heap.Lock; Free("UnloadPinned", 1); Heap.Unlock;
  raw := SharedModules.ThisCommand(m, "Ping"); ASSERT(raw # NIL);
  native := Hold(raw); ASSERT(native # 0); raw := NIL;
  Free("UnloadPinned", 1); ASSERT(Heap.ModuleState(m) = 4);
  ASSERT(SharedModules.ThisMod("UnloadPinned") = NIL);
  ReleaseNative(native); native := 0; Heap.GC(TRUE);
  Out.String("checked module unloading tests passed"); Out.Ln
END TestModuleUnload.
