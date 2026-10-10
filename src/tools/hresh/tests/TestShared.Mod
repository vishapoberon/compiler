MODULE TestShared;
  (* Discovery must not initialize either library. Loading must share one
     registry, one heap and persistent module state across commands and GC. *)
  IMPORT SharedModules, Modules, Heap, Out;
  VAR m: Modules.Module; cmd: Modules.Command;
    commands: INTEGER; sawRun, sawEcho: BOOLEAN;
  PROCEDURE Visit(name: ARRAY OF CHAR);
  BEGIN
    INC(commands);
    IF name = "Run" THEN sawRun := TRUE
    ELSIF name = "Echo" THEN sawEcho := TRUE
    ELSE ASSERT(name = "Run")
    END
  END Visit;
  PROCEDURE Count(name: ARRAY OF CHAR): INTEGER;
    VAR current: Modules.Module; count: INTEGER;
  BEGIN
    current := SharedModules.First(); count := 0;
    WHILE current # NIL DO
      IF current.name = name THEN INC(count) END;
      current := current.next
    END;
    RETURN count
  END Count;
BEGIN
  Modules.GetArg(1, SharedModules.path);
  ASSERT(Modules.ThisMod("SharedConsumer") = NIL);
  ASSERT(Modules.ThisMod("SharedProvider") = NIL);
  ASSERT(SharedModules.EnumerateCommands("SharedConsumer", Visit));
  ASSERT((commands = 2) & sawRun & sawEcho);
  ASSERT(Modules.ThisMod("SharedConsumer") = NIL);
  ASSERT(Modules.ThisMod("SharedProvider") = NIL);
  (* An import used only for a type still initializes and references its module. *)
  ASSERT(SharedModules.ThisMod("TypeOnly") # NIL);
  ASSERT(Modules.ThisMod("SharedProvider") # NIL);
  m := SharedModules.ThisMod("SharedConsumer"); ASSERT(m # NIL);
  ASSERT(SharedModules.ThisMod("SharedConsumer") = m);
  ASSERT(Modules.ThisMod("SharedProvider") # NIL);
  cmd := SharedModules.ThisCommand(m, "Run"); ASSERT(cmd # NIL);
  cmd; Heap.GC(TRUE); cmd;
  ASSERT(SharedModules.ThisCommand(m, "Function") = NIL);
  ASSERT(SharedModules.ThisCommand(m, "WithArg") = NIL);
  ASSERT(SharedModules.ThisCommand(m, "Touch") = NIL);
  ASSERT(SharedModules.ThisMod("Absent") = NIL);
  (* A directly loaded module stays pinned even when someone asks to free it. *)
  Modules.Free("SharedConsumer", FALSE);
  ASSERT(Modules.ThisMod("SharedConsumer") = m);
  ASSERT(Count("SharedConsumer") = 1); ASSERT(Count("SharedProvider") = 1);
  ASSERT(Count("Heap") = 1); ASSERT(Count("Platform") = 1);
  ASSERT(Count("Modules") = 1); ASSERT(Count("Out") = 1);
  Out.String("shared module tests passed"); Out.Ln
END TestShared.
