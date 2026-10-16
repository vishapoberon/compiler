MODULE TestLongOption;
IMPORT opts, Out;
VAR definitions, parsed: opts.Options;
    option, found: opts.Option;
    value: opts.string;
    i: LONGINT;
BEGIN
  definitions := opts.createOptions(); option := opts.createOpt();
  opts.setOptName(option, '-n'); opts.setOptHasVal(option, TRUE);
  definitions.add(definitions, option);
  parsed := opts.populateOptions(definitions);
  found := opts.findOpt('-n', parsed); ASSERT(found # NIL); ASSERT(found.val # NIL);
  ASSERT(LEN(found.val^) >= 301);
  FOR i := 0 TO 299 DO ASSERT(found.val[i] = 'x') END;
  ASSERT(found.val[300] = 0X);
  ASSERT(parsed.numPositional = 1);
  value := opts.GetPositionalArg(parsed, 0); ASSERT(value^ = 'tail');
  Out.String('long option tests passed'); Out.Ln
END TestLongOption.
