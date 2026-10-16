MODULE UnloadSpawn;
  IMPORT Modules, ModuleLoader;
  PROCEDURE Terminate;
  BEGIN ASSERT(ModuleLoader.ThisMod("UnloadPinned") # NIL)
  END Terminate;
BEGIN Modules.InstallTermHandler(Terminate); ASSERT(Modules.res = 0)
END UnloadSpawn.
