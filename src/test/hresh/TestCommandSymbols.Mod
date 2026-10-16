MODULE TestCommandSymbols;
  IMPORT SYSTEM, CommandSymbols, Files, Out;
  VAR file: Files.File; rider: Files.Rider; calls: INTEGER;

  PROCEDURE Visit(name: ARRAY OF CHAR);
  BEGIN ASSERT(name = "Run"); INC(calls)
  END Visit;

  PROCEDURE Header(name: ARRAY OF CHAR);
  BEGIN
    file := Files.New(name); Files.Set(rider, file, 0);
    Files.Write(rider, 0F7X); Files.Write(rider, 084X);
    Files.WriteNum(rider, 16); Files.WriteString(rider, "SymbolsFixture");
    Files.WriteString(rider, "")
  END Header;

  PROCEDURE Command;
  BEGIN
    Files.WriteNum(rider, 31); Files.WriteNum(rider, -10);
    Files.WriteNum(rider, 18); Files.WriteString(rider, "Run")
  END Command;

  PROCEDURE Check(name: ARRAY OF CHAR; valid: BOOLEAN);
  BEGIN
    Files.Register(file); calls := 0;
    ASSERT(CommandSymbols.Enumerate(name, "SymbolsFixture", Visit) = valid);
    IF valid THEN ASSERT(calls = 1) ELSE ASSERT(calls = 0) END
  END Check;

BEGIN
  Header("symbols-valid.sym"); Command; Check("symbols-valid.sym", TRUE);
  Header("symbols-partial.sym"); Command; Files.WriteNum(rider, 0);
  Check("symbols-partial.sym", FALSE);
  Header("symbols-minimum.sym"); Files.WriteNum(rider, 19);
  Files.WriteNum(rider, MIN(SYSTEM.INT64)); Check("symbols-minimum.sym", FALSE);
  Header("symbols-wide-tag.sym"); Files.WriteNum(rider, 19);
  Files.WriteNum(rider, 34); Files.WriteNum(rider, 0); Files.WriteString(rider, "T");
  Files.WriteNum(rider, 100000024H); Files.WriteNum(rider, -1);
  Check("symbols-wide-tag.sym", FALSE);
  Header("symbols-truncated.sym"); Files.Write(rider, 080X);
  Check("symbols-truncated.sym", FALSE);
  Out.String("command symbol validation tests passed"); Out.Ln
END TestCommandSymbols.
