MODULE TestLoaded;
  (* This application runs only after its generated host has opened its .so.
     Further modules can be added and loaded without relinking that host. *)
  IMPORT SYSTEM, ModuleLoader, Modules, Heap, Out;

  TYPE State = POINTER TO RECORD value: LONGINT END;
  VAR m: Modules.Module; run: Modules.Command; argument: ARRAY 64 OF CHAR;
    state: State;

  PROCEDURE Count(name: ARRAY OF CHAR): INTEGER;
    VAR current: Modules.Module; count: INTEGER;
  BEGIN
    current := ModuleLoader.First(); count := 0;
    WHILE current # NIL DO
      IF current.name = name THEN INC(count) END;
      current := current.next
    END;
    RETURN count
  END Count;

  PROCEDURE Finalize(obj: SYSTEM.PTR);
    VAR saved: State;
  BEGIN
    saved := SYSTEM.VAL(State, obj); ASSERT(saved.value = 42);
    Out.String("loaded application finalizer passed"); Out.Ln
  END Finalize;

BEGIN
  ASSERT(Modules.ArgCount = 2);
  Modules.GetArg(1, argument); ASSERT(argument = "runtime argument");
  ASSERT(Count("TestLoaded") = 1);
  ASSERT(Count("ModuleLoader") = 1);
  ASSERT(Count("Platform") = 1); ASSERT(Count("Heap") = 1);
  ASSERT(Count("Modules") = 1); ASSERT(Count("Out") = 1);
  ASSERT(Modules.ThisMod("SharedConsumer") = NIL);
  ASSERT(Modules.ThisMod("SharedProvider") = NIL);

  m := ModuleLoader.ThisMod("SharedConsumer"); ASSERT(m # NIL);
  ASSERT(ModuleLoader.ThisMod("SharedConsumer") = m);
  ASSERT(Count("SharedConsumer") = 1); ASSERT(Count("SharedProvider") = 1);
  run := Modules.ThisCommand(m, "Run"); ASSERT(run # NIL);
  run; Heap.GC(TRUE); run;
  Modules.Free("SharedConsumer", FALSE);
  ASSERT(Modules.ThisMod("SharedConsumer") = m);
  ASSERT(ModuleLoader.ThisMod("Absent") = NIL);

  NEW(state); state.value := 42;
  Heap.RegisterFinalizer(state, Finalize);
  Heap.GC(TRUE); ASSERT(state.value = 42);
  Out.String("loaded application tests passed"); Out.Ln
END TestLoaded.
