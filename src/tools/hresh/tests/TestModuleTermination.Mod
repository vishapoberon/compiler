MODULE TestModuleTermination;

  IMPORT Modules, SharedModules, Heap, Out;
  VAR module: Modules.Module; check: Modules.Command;

BEGIN
  Modules.GetArg(1, SharedModules.path);
  ASSERT(Modules.ThisMod("TerminationProbe") = NIL);
  module := SharedModules.ThisMod("TerminationProbe"); ASSERT(module # NIL);
  check := SharedModules.ThisCommand(module, "Check"); ASSERT(check # NIL);
  (* FINALMOD runs termination handlers without unloading the module. *)
  Heap.FINALMOD(module); check;
  Heap.FINALMOD(module); check;
  Heap.GC(TRUE); check;
  ASSERT(Modules.ThisMod("TerminationProbe") = module);
  Heap.FINALL; check; (* No callback runs twice at process shutdown. *)
  Out.String("module termination tests passed"); Out.Ln
END TestModuleTermination.
