MODULE TestHostedTools;

  IMPORT compiler, browser, Modules, Heap, Files, Texts, Oberon, Out, Strings;

  VAR original: Oberon.ParList; argc: INTEGER;

  PROCEDURE Parameters(text: ARRAY OF CHAR);
    VAR w: Texts.Writer;
  BEGIN
    NEW(Oberon.Par); NEW(Oberon.Par.text); Texts.Open(Oberon.Par.text, "");
    Texts.OpenWriter(w); Texts.WriteString(w, text);
    Texts.Append(Oberon.Par.text, w.buf); Oberon.Par.pos := 0
  END Parameters;

  PROCEDURE Source(name, text: ARRAY OF CHAR);
    VAR file: Files.File; rider: Files.Rider; n: INTEGER;
  BEGIN
    file := Files.New(name); Files.Set(rider, file, 0);
    n := 0; WHILE text[n] # 0X DO Files.Write(rider, text[n]); INC(n) END;
    Files.Register(file)
  END Source;

  PROCEDURE Compile(text: ARRAY OF CHAR; expected: INTEGER);
    VAR before, after: ARRAY 4096 OF CHAR;
  BEGIN
    ASSERT(Files.GetSearchPath(before));
    Parameters(text); compiler.Compile;
    ASSERT(compiler.res = expected); ASSERT(Modules.ArgCount = argc);
    ASSERT(Files.GetSearchPath(after)); ASSERT(before = after);
    Heap.GC(TRUE); ASSERT(original # NIL); ASSERT(original.text # NIL)
  END Compile;

  PROCEDURE LongCodeSource;
    VAR file: Files.File; rider: Files.Rider; i: INTEGER;

    PROCEDURE Write(text: ARRAY OF CHAR);
    BEGIN Files.WriteBytes(rider, text, Strings.Length(text)) END Write;

  BEGIN
    file := Files.New("HostedToolLongCode.Mod"); Files.Set(rider, file, 0);
    Write("MODULE HostedToolLongCode; IMPORT SYSTEM; PROCEDURE -Code '");
    FOR i := 0 TO 255 DO Files.Write(rider, " ") END;
    Write("'; END HostedToolLongCode."); Files.Register(file)
  END LongCodeSource;

BEGIN
  (* Importing the compiler and browser must not run their standalone startup. *)
  original := Oberon.Par; argc := Modules.ArgCount;
  Source("HostedToolProbe.Mod",
    "MODULE HostedToolProbe; IMPORT Out; PROCEDURE Run*; BEGIN Out.String('hosted probe'); Out.Ln END Run; END HostedToolProbe.");
  Compile("-slf HostedToolProbe.Mod", 0);
  ASSERT(Files.Old("HostedToolProbe.sym") # NIL);
  ASSERT(Files.Old("./libvoc-HostedToolProbe-O2.so") # NIL);
  ASSERT(Modules.ThisMod("HostedToolProbe") = NIL);
  Parameters("HostedToolProbe"); browser.ShowDef;
  ASSERT(Modules.ThisMod("HostedToolProbe") = NIL);
  Source("HostedToolBroken.Mod", "MODULE HostedToolBroken; BEGIN unknown END HostedToolBroken.");
  Compile("-slf HostedToolBroken.Mod", 1);
  Source("HostedToolBadC.Mod", "MODULE HostedToolBadC; IMPORT SYSTEM; PROCEDURE -AInclude '#error deliberate hosted C failure'; END HostedToolBadC.");
  Compile("-slf HostedToolBadC.Mod", 1);
  LongCodeSource; Compile("-sSlf HostedToolLongCode.Mod", 1);
  Compile("-Md HostedToolProbe.Mod", 1);
  Compile("-slf HostedToolMissing.Mod", 1);
  Compile("-slf HostedToolProbe.Mod", 0);
  Parameters("Modules"); browser.ShowDef;
  Oberon.Par := original;
  Out.String("hosted tool tests passed"); Out.Ln
END TestHostedTools.
