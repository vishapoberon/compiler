MODULE dcsMain;
IMPORT dcs, Args, PortArgs, Out;
VAR command: ARRAY 32 OF CHAR;
BEGIN
  Args.Get(1, command);
  IF command = "Idents" THEN PortArgs.FromCLI(2); dcs.Idents
  ELSIF command = "NewIdent" THEN PortArgs.FromCLI(2); dcs.NewIdent
  ELSIF (command = "Help") OR (command = "--help") THEN dcs.Help
  ELSE PortArgs.FromCLI(1); dcs.Get
  END;
  Out.Flush  (* hresh flushes after commands; standalone programs must do so too *)
END dcsMain.
