MODULE testopts;
IMPORT opts, Out;

TYPE string = opts.string;

VAR options  : opts.Options;
    foptions : opts.Options;
    opt      : opts.Option;
    i        : INTEGER;
    str      : string;
BEGIN
  options := opts.createOptions();
  foptions := NIL;

  (* Define -s/--symbol option *)
  opt := opts.createOpt();
  opts.setOptName(opt, "-s");
  opts.setOptHasVal(opt, FALSE);
  opts.setOptRequired(opt, FALSE);
  opts.setOptLName(opt, "--symbol");
  opts.setOptDesc(opt, "Update symbol file");
  options.add(options, opt);

  (* Define -m/--main option *)
  opt := opts.createOpt();
  opts.setOptName(opt, "-m");
  opts.setOptHasVal(opt, TRUE);
  opts.setOptRequired(opt, TRUE);
  opts.setOptLName(opt, "--main");
  opts.setOptDesc(opt, "Main module name");
  options.add(options, opt);

  (* Define -F option *)
  opt := opts.createOpt();
  opts.setOptName(opt, "-F");
  opts.setOptHasVal(opt, TRUE);
  opts.setOptRequired(opt, TRUE);
  opts.setOptDesc(opt, "Some fancy option");
  options.add(options, opt);

  Out.Ln;
  Out.String("Defined options:"); Out.Ln;
  opts.listOptions(options);
  Out.Ln; Out.String("----------------------"); Out.Ln;

  foptions := opts.populateOptions(options);

  Out.Ln;
  Out.String("Parsed options:"); Out.Ln;
  opts.listOptions(foptions);
  Out.Ln; Out.String("----------------------"); Out.Ln;

  IF opts.reqsSatisfied(options, foptions) THEN
    Out.String("All required options provided"); Out.Ln;
  ELSE
    Out.String("Missing required options!"); Out.Ln;
  END;

  (* Print positional arguments *)
  i := 0;
  WHILE i < opts.NumPositionalArgs(foptions) DO
    Out.String("Positional arg "); Out.Int(i, 0);
    Out.String(": ");
    str := opts.GetPositionalArg(foptions, i);
    Out.String(str^);
    Out.Ln;
    INC(i);
  END;

  (* Cleanup *)
  opts.CleanupOptions(options);
  opts.CleanupOptions(foptions);

  Out.Ln;
  Out.String("Test completed"); Out.Ln;
END testopts.
