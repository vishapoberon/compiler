MODULE TerminationProbe;

  IMPORT SYSTEM, Modules, Heap;

  TYPE Object = POINTER TO ObjectDesc;
    ObjectDesc = RECORD value: INTEGER END;
  VAR object: Object; finalized, terminated: INTEGER;

  PROCEDURE Finalize(obj: SYSTEM.PTR);
    VAR value: Object;
  BEGIN
    value := SYSTEM.VAL(Object, obj); ASSERT(value.value = 42);
    ASSERT(terminated = 0); INC(finalized)
  END Finalize;

  PROCEDURE Terminate;
  BEGIN ASSERT(finalized = 1); INC(terminated)
  END Terminate;

  PROCEDURE Obsolete;
  BEGIN HALT(99) END Obsolete;

  PROCEDURE Check*;
  BEGIN ASSERT(finalized = 1); ASSERT(terminated = 1)
  END Check;

BEGIN
  NEW(object); object.value := 42; Heap.RegisterFinalizer(object, Finalize);
  (* Private callbacks must be registered before the module body executes. *)
  Modules.InstallTermHandler(Obsolete); ASSERT(Modules.res = 0);
  Modules.InstallTermHandler(Terminate); ASSERT(Modules.res = 0);
  Modules.InstallTermHandler(NIL); ASSERT(Modules.res # 0)
END TerminationProbe.
