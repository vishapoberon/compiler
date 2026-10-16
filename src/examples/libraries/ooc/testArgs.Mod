MODULE testArgs;
(**Demonstrates reading command-line arguments via TextRider.

   Each argument is presented as a separate line in the ProgramArgs channel.
   The first line is always argv[0] (the program name); the actual arguments
   start from the second line.  ConnectReader attaches a TextRider.Reader to
   that channel so arguments can be read as strings, integers, or reals.

   Usage:
     bin/testArgs hello 42 3.14
*)

IMPORT
  Out, ProgramArgs, TextRider;

PROCEDURE Run;
  VAR
    r: TextRider.Reader;
    arg: ARRAY 1024 OF CHAR;
    n, i: LONGINT;
  BEGIN
    n := ProgramArgs.args.ArgNumber();
    Out.String("argument count: "); Out.Int(n, 0); Out.Ln;

    r := TextRider.ConnectReader(ProgramArgs.args);

    (* first line is the program name (argv[0]) — skip it *)
    r.ReadLine(arg);

    i := 0;
    WHILE r.res = TextRider.done DO
      r.ReadLine(arg);
      IF r.res = TextRider.done THEN
        Out.String("arg "); Out.Int(i, 0);
        Out.String(": "); Out.String(arg); Out.Ln;
        INC(i)
      END
    END
  END Run;

BEGIN
  Run
END testArgs.
