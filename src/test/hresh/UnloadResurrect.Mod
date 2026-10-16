MODULE UnloadResurrect;
  IMPORT Modules, UnloadState;
  TYPE Object = POINTER TO ObjectDesc;
    ObjectDesc = RECORD value: INTEGER END;

  PROCEDURE Terminate;
    VAR object: Object;
  BEGIN NEW(object); object.value := 7; UnloadState.saved := object
  END Terminate;

BEGIN Modules.InstallTermHandler(Terminate); ASSERT(Modules.res = 0)
END UnloadResurrect.
