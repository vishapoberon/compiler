MODULE TestLoaderABI;
  IMPORT ModuleLoader, Modules, Strings, Out;
  VAR module: Modules.Module;
BEGIN
  Modules.GetArg(1, ModuleLoader.path);
  module := ModuleLoader.ThisMod("BadCoreABI");
  ASSERT(module = NIL); ASSERT(ModuleLoader.res # 0);
  ASSERT(Strings.Pos("module does not use the host's runtime core", ModuleLoader.resMsg, 0) >= 0);
  ASSERT(Modules.ThisMod("BadCoreABI") = NIL);
  Out.String("loader runtime-ownership tests passed"); Out.Ln
END TestLoaderABI.
