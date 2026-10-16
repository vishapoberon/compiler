MODULE opts;

IMPORT Out, Strings, optsos := optsosv;

TYPE
   string* = optsos.string;
   stringArr = POINTER TO ARRAY OF string;

   Option* = POINTER TO OptionDesc;
   Options* = POINTER TO OptionsDesc;

   OptionDesc* = RECORD;
         name- : string;
  haslongname- : BOOLEAN;
     longname- : string;
       hasval- : BOOLEAN;
     required- : BOOLEAN;
          val- : string;
  description- : string;
          next : Option;
       setName : PROCEDURE(VAR opt: Option; name: ARRAY OF CHAR);
   setLongName : PROCEDURE(VAR opt: Option; name: ARRAY OF CHAR);
       setDesc : PROCEDURE(VAR opt: Option; desc: ARRAY OF CHAR);
     setHasVal : PROCEDURE(VAR opt: Option; hasval: BOOLEAN);
   setRequired : PROCEDURE(VAR opt: Option; req: BOOLEAN);
        branch : Options;
      END;

    OptionsDesc* = RECORD
     add* : PROCEDURE(VAR opts: Options; VAR opt: Option);
         first- : Option;
    last- : Option;
   count- : INTEGER;
   positionalArgs: stringArr;  (* New: positional arguments *)
   numPositional-: INTEGER;                    (* New: count of positional args *)
   END;

PROCEDURE addOpt*(VAR opts: Options; VAR opt: Option);
BEGIN
  IF opts.first = NIL THEN
    opts.first := opt;
  ELSE
    opts.last.next := opt;
  END;
  opts.last := opt;
  opt.next := NIL;
  INC(opts.count);
END addOpt;

PROCEDURE createOptions*(): Options;
VAR
  opts: Options;
BEGIN
  NEW(opts);
  opts.add   := addOpt;
  opts.first := NIL;
  opts.last  := NIL;
  opts.count := 0;
  opts.positionalArgs := NIL;  (* Initialize new fields *)
  opts.numPositional := 0;
  RETURN opts
END createOptions;

PROCEDURE CleanupOptions*(VAR opts: Options);
VAR
  opt, next: Option;
  i: INTEGER;
BEGIN
  IF opts # NIL THEN
    opt := opts.first;
    WHILE opt # NIL DO
      next := opt.next;
      opt := next;
    END;

    IF opts.positionalArgs # NIL THEN
      opts.positionalArgs := NIL;
    END;

    opts := NIL;
  END;
END CleanupOptions;

PROCEDURE setOptHasVal*(VAR opt: Option; hasval: BOOLEAN);
BEGIN
  opt.hasval := hasval
END setOptHasVal;

PROCEDURE setOptRequired*(VAR opt: Option; req: BOOLEAN);
BEGIN
  opt.required := req
END setOptRequired;

PROCEDURE setOptBranch*(VAR opt: Option; branch: Options);
BEGIN
  opt.branch := branch
END setOptBranch;

PROCEDURE setOptName*(VAR opt: Option; name: ARRAY OF CHAR);
VAR
  l: LONGINT;
BEGIN
  l := Strings.Length(name);
  NEW(opt.name, l+1);
  COPY(name, opt.name^)
END setOptName;

PROCEDURE setOptLName*(VAR opt:  Option; name: ARRAY OF CHAR);
VAR
  l: LONGINT;
BEGIN
  opt.haslongname := TRUE;
  l := Strings.Length(name);
  NEW(opt.longname, l+1);
  COPY(name, opt.longname^)
END setOptLName;

PROCEDURE setOptDesc*(VAR opt: Option; desc: ARRAY OF CHAR);
VAR
  l: LONGINT;
BEGIN
  l := Strings.Length(desc);
  NEW(opt.description, l+1);
  COPY(desc, opt.description^);
END setOptDesc;

PROCEDURE createOpt*(): Option;
VAR
  o: Option;
BEGIN
  NEW(o);
  o.name := NIL;
  o.haslongname := FALSE;
  o.longname := NIL;
  o.hasval := FALSE;
  o.required := FALSE;
  o.val := NIL;
  o.description := NIL;
  o.next := NIL;
  o.branch := NIL;
  o.setName := setOptName;
  o.setLongName := setOptLName;
  o.setDesc := setOptDesc;
  RETURN o
END createOpt;

PROCEDURE CleanupOpt*(VAR opt: Option);
BEGIN
  IF opt # NIL THEN
    opt := NIL;
  END;
END CleanupOpt;

PROCEDURE showHelp*(VAR opts : Options);
VAR
  opt: Option;
BEGIN
   Out.String("Options:"); Out.Ln; Out.Ln;
   opt := opts.first;

   IF opt = NIL THEN
     Out.String("No options available to show."); Out.Ln;
     RETURN;
   END;

   WHILE opt # NIL DO
      Out.String("  ");
      IF opt.name # NIL THEN
        Out.String(opt.name^);
      ELSE
        Out.String("<no name>");
      END;

      IF opt.haslongname THEN
         Out.String(", ");
         IF opt.longname # NIL THEN
           Out.String(opt.longname^);
         ELSE
           Out.String("<no long name>");
         END;
      END;

      IF opt.hasval THEN
         Out.String ("=VALUE")
      END;

      Out.Ln;
      Out.String("        ");
      IF opt.description # NIL THEN
        Out.String(opt.description^);
      ELSE
        Out.String("<no description>");
      END;
      Out.Ln; Out.Ln;

      opt := opt.next;
   END;

   Out.String("Positional arguments are accepted after options"); Out.Ln;
END showHelp;

PROCEDURE findOpt* (s : ARRAY OF CHAR; VAR opts : Options) : Option;
VAR
  opt: Option;
BEGIN
  IF (opts = NIL) OR (opts.first = NIL) THEN
    RETURN NIL;
  END;

  opt := opts.first;
  WHILE opt # NIL DO
    IF (opt.name # NIL) & (opt.name^ = s) THEN
      RETURN opt;
    END;

    IF opt.haslongname & (opt.longname # NIL) & (opt.longname^ = s) THEN
      RETURN opt;
    END;

    opt := opt.next;
  END;

  RETURN NIL;
END findOpt;

PROCEDURE reqsSatisfied*(opts, fopts: Options): BOOLEAN;
VAR
  opt, opt2: Option;
BEGIN
  IF (fopts # NIL) & (opts # NIL) THEN
    opt := opts.first;
    WHILE opt # NIL DO
      IF opt.required THEN
        opt2 := findOpt(opt.name^, fopts);
        IF (opt2 = NIL) OR (opt.hasval & (opt2.val = NIL)) THEN
          RETURN FALSE
        END;
      END;
      opt := opt.next
    END;
    RETURN TRUE
  END;
  RETURN FALSE
END reqsSatisfied;

PROCEDURE copyOpt(VAR opt: Option): Option;
VAR
  fopt: Option;
BEGIN
  fopt := createOpt();
  setOptName(fopt, opt.name^);
  setOptHasVal(fopt, opt.hasval);
  fopt.haslongname := opt.haslongname;
  IF opt.haslongname THEN setOptLName(fopt, opt.longname^) END;
  fopt.required := opt.required;
  IF opt.description # NIL THEN setOptDesc(fopt, opt.description^) END;
  RETURN fopt
END copyOpt;

PROCEDURE AddPositionalArg(VAR fopts: Options; s: string);
VAR
  newArr: stringArr;
  i: INTEGER;
BEGIN
  IF fopts.numPositional = 0 THEN
    NEW(fopts.positionalArgs, 1);
  ELSE
    NEW(newArr, fopts.numPositional + 1);
    FOR i := 0 TO fopts.numPositional - 1 DO
      newArr[i] := fopts.positionalArgs[i];
    END;
    fopts.positionalArgs := newArr;
  END;
  fopts.positionalArgs[fopts.numPositional] := s;
  INC(fopts.numPositional);
END AddPositionalArg;

PROCEDURE populateOptions*(VAR opts : Options): Options;
VAR
  s : string;
  opt, fopt: Option;
  fopts: Options;
  stopProcessing: BOOLEAN;
BEGIN
   fopts := createOptions();
   IF opts = NIL THEN
     Out.String("No options defined, exiting"); Out.Ln;
     HALT(1)
   END;

   stopProcessing := FALSE;
   s := optsos.Get();
   WHILE s # NIL DO
     (* Handle option terminator "--" *)
     IF ~stopProcessing & (s^ = "--") THEN
       stopProcessing := TRUE;
     ELSE
       (* Only look for options if not in stopProcessing mode *)
       IF ~stopProcessing THEN
         opt := findOpt(s^, opts);
       ELSE
         opt := NIL;
       END;

       IF opt # NIL THEN
         fopt := copyOpt(opt);
         fopts.add(fopts, fopt);

         IF opt.hasval THEN
           s := optsos.Get();
           (* Validate option value *)
           IF (s = NIL) OR (s^[0] = '-') & (~stopProcessing) THEN
             Out.String("Option '"); Out.String(opt.name^); 
             Out.String("' requires a value"); Out.Ln;
             HALT(5);
           END;
           opt.val := s;
           fopt.val := s;
         END;
       ELSE
         (* This is a positional argument *)
         AddPositionalArg(fopts, s);
       END;
     END;
     
     s := optsos.Get();  (* Get next argument *)
   END;

   RETURN fopts;
END populateOptions;

PROCEDURE GetPositionalArg*(VAR foptions: Options; idx: INTEGER): string;
BEGIN
  IF (foptions # NIL) & (foptions.positionalArgs # NIL) &
     (idx >= 0) & (idx < foptions.numPositional) THEN
    RETURN foptions.positionalArgs[idx];
  END;
  RETURN NIL;
END GetPositionalArg;

PROCEDURE NumPositionalArgs*(VAR foptions: Options): INTEGER;
BEGIN
  IF foptions # NIL THEN
    RETURN foptions.numPositional;
  END;
  RETURN 0;
END NumPositionalArgs;

PROCEDURE valOfOpt*(o: ARRAY OF CHAR; VAR foptions: Options; VAR val: ARRAY OF CHAR);
VAR
  fopt: Option;
BEGIN
  COPY("", val);
  fopt := findOpt(o, foptions);

  IF (fopt # NIL) & (fopt.val # NIL) THEN
    COPY(fopt.val^, val);
  END;
END valOfOpt;

PROCEDURE listOptions*(VAR opts : Options);
VAR
  opt: Option;
  i: INTEGER;
BEGIN
  IF opts = NIL THEN
    Out.String("Options: NIL"); Out.Ln;
    RETURN;
  END;

  Out.String("Options ("); Out.Int(opts.count,0); Out.String("):"); Out.Ln;
  opt := opts.first;
  WHILE opt # NIL DO
    Out.String("  ");
    IF opt.name # NIL THEN Out.String(opt.name^) END;

    IF opt.haslongname & (opt.longname # NIL) THEN
      Out.String(" / "); Out.String(opt.longname^);
    END;

    IF opt.hasval THEN
      Out.String(" [value]");
    END;

    IF opt.required THEN
      Out.String(" (required)");
    END;

    Out.Ln;
    opt := opt.next;
  END;

  IF opts.numPositional > 0 THEN
    Out.Ln;
    Out.String("Positional arguments (");
    Out.Int(opts.numPositional,0);
    Out.String("):"); Out.Ln;
    FOR i := 0 TO opts.numPositional - 1 DO
      Out.String("  ");
      Out.String(opts.positionalArgs[i]^);
      Out.Ln;
    END;
  END;
END listOptions;

END opts.
