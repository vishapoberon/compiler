MODULE UnloadProbe;
  IMPORT SYSTEM, Modules, Heap, Oberon, UnloadState;
  TYPE Object = POINTER TO ObjectDesc;
    ObjectDesc = RECORD (UnloadState.BaseDesc) value: INTEGER END;
  VAR owned: Object;

  PROCEDURE (object: Object) Value(): INTEGER;
  BEGIN RETURN object.value
  END Value;

  PROCEDURE Finalize(object: SYSTEM.PTR);
  BEGIN
    INC(UnloadState.finalized); owned := NIL
  END Finalize;

  PROCEDURE Stop;
  BEGIN INC(UnloadState.stopped)
  END Stop;

  PROCEDURE Terminate;
  BEGIN
    ASSERT(UnloadState.finalized = UnloadState.initialized);
    INC(UnloadState.terminated)
  END Terminate;

  PROCEDURE Escape*;
    VAR object: Object;
  BEGIN NEW(object); object.value := 123; UnloadState.saved := object
  END Escape;

  PROCEDURE SelfFree*;
  BEGIN
    Modules.Free("UnloadProbe", FALSE);
    ASSERT(Modules.resMsg = "module code is active");
    UnloadState.selfFree := Modules.res
  END SelfFree;

  PROCEDURE Check*;
  BEGIN ASSERT(owned # NIL); ASSERT(owned.Value() = 42)
  END Check;

BEGIN
  INC(UnloadState.initialized);
  NEW(owned); owned.value := 42; Heap.RegisterFinalizer(owned, Finalize);
  Modules.InstallTermHandler(Terminate); ASSERT(Modules.res = 0);
  Oberon.OnStop(Stop)
END UnloadProbe.
