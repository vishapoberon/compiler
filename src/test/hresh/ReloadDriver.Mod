MODULE ReloadDriver;
  IMPORT Files, Modules, SharedModules, Out;
  VAR version*: INTEGER; sawOld, sawNew: BOOLEAN;

  PROCEDURE Source(text: ARRAY OF CHAR);
    VAR file: Files.File; rider: Files.Rider; i: INTEGER;
  BEGIN
    ASSERT(Modules.ThisMod("HostedReload") = NIL);
    file := Files.New("HostedReload.Mod"); ASSERT(file # NIL);
    Files.Set(rider, file, 0); i := 0;
    WHILE text[i] # 0X DO Files.Write(rider, text[i]); INC(i) END;
    Files.Register(file)
  END Source;

  PROCEDURE VersionOne*;
  BEGIN Source("MODULE HostedReload; IMPORT ReloadDriver; PROCEDURE Run*; BEGIN ReloadDriver.version := 1 END Run; END HostedReload.")
  END VersionOne;

  PROCEDURE VersionTwo*;
  BEGIN
    ASSERT(version = 1);
    Source("MODULE HostedReload; IMPORT ReloadDriver; PROCEDURE Changed*; BEGIN ReloadDriver.version := 2 END Changed; END HostedReload.")
  END VersionTwo;

  PROCEDURE Command(name: ARRAY OF CHAR);
  BEGIN
    IF name = "Run" THEN sawOld := TRUE END;
    IF name = "Changed" THEN sawNew := TRUE END
  END Command;

  PROCEDURE CheckSymbols*;
  BEGIN
    ASSERT(Modules.ThisMod("HostedReload") = NIL);
    sawOld := FALSE; sawNew := FALSE;
    ASSERT(SharedModules.EnumerateCommands("HostedReload", Command));
    ASSERT(sawNew & ~sawOld);
    ASSERT(Modules.ThisMod("HostedReload") = NIL)
  END CheckSymbols;

  PROCEDURE Check*;
  BEGIN
    ASSERT(version = 2); ASSERT(Modules.ThisMod("HostedReload") = NIL);
    Out.String("same-shell free/recompile/discovery/reload tests passed"); Out.Ln
  END Check;
END ReloadDriver.
