MODULE vish;

  (* Vishap shell. Commands execute in this process,
     not in child processes, just as in loksh and the Oberon UI. *)

  IMPORT Modules, SharedModules, Oberon, Texts, Out, Heap, Platform, LineEditor;

  VAR
    prefix, modulePrefix: ARRAY 128 OF CHAR;
    failed, quit: BOOLEAN;

  PROCEDURE StartsWith(name, prefix: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < LEN(prefix)) & (prefix[i] # 0X) DO
      IF (i >= LEN(name)) OR (name[i] # prefix[i]) THEN RETURN FALSE END;
      INC(i)
    END;
    RETURN TRUE
  END StartsWith;

  PROCEDURE Append(source: ARRAY OF CHAR; VAR target: ARRAY OF CHAR): BOOLEAN;
    VAR i, j: INTEGER;
  BEGIN
    i := 0; WHILE (i < LEN(target)) & (target[i] # 0X) DO INC(i) END;
    j := 0;
    WHILE (j < LEN(source)) & (source[j] # 0X) DO
      IF i >= LEN(target) - 1 THEN RETURN FALSE END;
      target[i] := source[j]; INC(i); INC(j)
    END;
    target[i] := 0X;
    RETURN TRUE
  END Append;

  PROCEDURE CompleteModule(name: ARRAY OF CHAR);
    VAR candidate: ARRAY 128 OF CHAR; ok: BOOLEAN;
  BEGIN
    IF StartsWith(name, prefix) THEN
      COPY(name, candidate); ok := Append(".", candidate);
      IF ok THEN LineEditor.AddCompletion(candidate) END
    END
  END CompleteModule;

  PROCEDURE CompleteCommand(name: ARRAY OF CHAR);
    VAR candidate: ARRAY 128 OF CHAR; ok: BOOLEAN;
  BEGIN
    COPY(modulePrefix, candidate);
    ok := Append(".", candidate) & Append(name, candidate);
    IF ok & StartsWith(candidate, prefix) THEN LineEditor.AddCompletion(candidate) END
  END CompleteCommand;

  PROCEDURE Complete(text: ARRAY OF CHAR);
    VAR i, j: INTEGER; valid: BOOLEAN;
  BEGIN
    i := 0; WHILE (i < LEN(text)) & (text[i] # 0X) DO INC(i) END;
    IF i >= LEN(prefix) THEN RETURN END;
    COPY(text, prefix);
    i := 0; WHILE (prefix[i] # 0X) & (prefix[i] # ".") DO INC(i) END;
    IF prefix[i] = "." THEN
      j := 0; WHILE j < i DO modulePrefix[j] := prefix[j]; INC(j) END;
      modulePrefix[j] := 0X;
      valid := SharedModules.EnumerateCommands(modulePrefix, CompleteCommand)
    ELSE
      IF StartsWith("help", prefix) THEN LineEditor.AddCompletion("help") END;
      IF StartsWith("quit", prefix) THEN LineEditor.AddCompletion("quit") END;
      IF StartsWith("exit", prefix) THEN LineEditor.AddCompletion("exit") END;
      SharedModules.EnumerateModules(CompleteModule)
    END
  END Complete;

  PROCEDURE Help;
  BEGIN
    Out.String("vish - Vishap Oberon shell"); Out.Ln;
    Out.String("  vish [-Ppath] [Module.Command [arguments]]"); Out.Ln;
    Out.String("  vish < script       run a batch of commands"); Out.Ln;
    Out.String("  Module              list its commands without initializing it"); Out.Ln;
    Out.String("  Tab: commands, then files/directories; arrows: history"); Out.Ln;
    Out.String("  quit/exit/Ctrl-D: leave"); Out.Ln;
    Out.String("  VOC_MODULE_PATH: colon-separated module directories"); Out.Ln;
    Out.String("  Modules stay loaded; HALT or a fault terminates this prototype."); Out.Ln
  END Help;

  PROCEDURE ShowCommand(name: ARRAY OF CHAR);
  BEGIN
    Out.String("  "); Out.String(modulePrefix); Out.Char("."); Out.String(name); Out.Ln
  END ShowCommand;

  PROCEDURE Error;
  BEGIN
    Out.String("vish: "); Out.String(SharedModules.resMsg); Out.Ln;
    failed := TRUE
  END Error;

  PROCEDURE Execute(line: ARRAY OF CHAR);
    VAR i, j, dot, start: INTEGER; name: ARRAY 128 OF CHAR;
      command: ARRAY 64 OF CHAR; m: SharedModules.Module;
      proc: SharedModules.Command; par, previous: Oberon.ParList;
      W: Texts.Writer;
  BEGIN
    i := 0; WHILE (line[i] = " ") OR (line[i] = 09X) DO INC(i) END;
    IF (line[i] = 0X) OR (line[i] = "#") THEN RETURN END;
    j := 0; dot := -1;
    WHILE (line[i] # 0X) & (line[i] > " ") DO
      IF j >= LEN(name) - 1 THEN
        SharedModules.resMsg := "command name too long"; Error; RETURN
      END;
      IF line[i] = "." THEN dot := j END;
      name[j] := line[i]; INC(i); INC(j)
    END;
    name[j] := 0X;
    IF (name = "quit") OR (name = "exit") THEN quit := TRUE; RETURN END;
    IF (name = "help") OR (name = "--help") OR (name = "-h") THEN Help; RETURN END;
    IF dot < 0 THEN
      COPY(name, modulePrefix);
      IF ~SharedModules.EnumerateCommands(name, ShowCommand) THEN Error END;
      Out.Flush; RETURN
    END;
    name[dot] := 0X;
    j := 0; start := dot + 1;
    WHILE name[start] # 0X DO
      IF j >= LEN(command) - 1 THEN
        SharedModules.resMsg := "command name too long"; Error; RETURN
      END;
      command[j] := name[start]; INC(j); INC(start)
    END;
    command[j] := 0X;
    WHILE (line[i] = " ") OR (line[i] = 09X) DO INC(i) END;
    NEW(par); NEW(par.text); Texts.Open(par.text, ""); par.pos := 0;
    Texts.OpenWriter(W);
    WHILE line[i] # 0X DO Texts.Write(W, line[i]); INC(i) END;
    Texts.Append(par.text, W.buf);
    (* Set parameters before __init too, for modules that inspect them there. *)
    previous := Oberon.Par; Oberon.Par := par;
    m := SharedModules.ThisMod(name);
    IF m # NIL THEN
      proc := SharedModules.ThisCommand(m, command);
      IF proc # NIL THEN proc ELSE Error END
    ELSE Error
    END;
    Oberon.Par := previous;
    Out.Flush;
    Heap.GC(TRUE)
  END Execute;

  PROCEDURE Run;
    VAR i, status: INTEGER; line: ARRAY 4096 OF CHAR;
      arg: ARRAY 4096 OF CHAR; ok: BOOLEAN;
  BEGIN
    i := 1;
    IF i < Modules.ArgCount THEN
      Modules.GetArg(i, arg);
      IF (arg[0] = "-") & (arg[1] = "P") THEN
        IF arg[2] = 0X THEN
          INC(i);
          IF i >= Modules.ArgCount THEN
            Out.String("vish: -P needs a module path"); Out.Ln; Platform.Exit(1)
          END;
          Modules.GetArg(i, SharedModules.path)
        ELSE
          status := 0;
          WHILE arg[status + 2] # 0X DO
            SharedModules.path[status] := arg[status + 2]; INC(status)
          END;
          SharedModules.path[status] := 0X
        END;
        INC(i)
      END
    END;
    IF i < Modules.ArgCount THEN
      line := "";
      WHILE i < Modules.ArgCount DO
        Modules.GetArg(i, arg);
        ok := Append(arg, line);
        IF i < Modules.ArgCount - 1 THEN ok := ok & Append(" ", line) END;
        IF ~ok THEN Out.String("vish: command line too long"); Out.Ln; Platform.Exit(1) END;
        INC(i)
      END;
      Execute(line)
    ELSE
      LineEditor.Init(Complete);
      WHILE ~quit DO
        status := LineEditor.ReadLine(line);
        IF status = 0 THEN quit := TRUE
        ELSIF status = -1 THEN
          Out.String("vish: input line too long"); Out.Ln; failed := TRUE
        ELSIF status < 0 THEN
          Out.String("vish: terminal or input error"); Out.Ln; failed := TRUE; quit := TRUE
        ELSE Execute(line)
        END
      END
    END;
    IF failed THEN Heap.FINALL; Platform.Exit(1) END
  END Run;

BEGIN Run
END vish.
