MODULE UnloadStopClient;
  IMPORT Modules, Oberon, UnloadState;
  PROCEDURE Cleanup;
  BEGIN
    Modules.Free("UnloadProbe", FALSE); UnloadState.stopFree := Modules.res
  END Cleanup;
BEGIN Oberon.OnStop(Cleanup)
END UnloadStopClient.
