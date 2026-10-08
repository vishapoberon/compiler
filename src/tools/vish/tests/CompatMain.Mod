MODULE CompatMain;
  (* The original -m/-M modes keep the monolithic runtime and do not activate
     either the modular core or the shared-module loader. *)
  IMPORT Modules, Out;
BEGIN
  ASSERT(Modules.ThisMod("ModuleLoader") = NIL);
  Out.String("compatibility program passed"); Out.Ln
END CompatMain.
