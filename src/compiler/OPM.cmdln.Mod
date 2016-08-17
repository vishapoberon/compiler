MODULE OPM;  (* RC 6.3.89 / 28.6.89, J.Templ 10.7.89 / 22.7.96  *)
(* constants needed for C code generation

  31.1.2007 jt synchronized with BlackBox version, in particular PromoteIntConstToLInt added
*)

  IMPORT SYSTEM, Texts, Files, Platform, Console, errors, Configuration, vt100, Strings;

  CONST
    OptionChar* = "-";

    (* compiler options; don't change the encoding *)
    inxchk*         = 0;  (* index check on *)
    ranchk*         = 2;  (* range check on *)
    typchk*         = 3;  (* type check on *)
    newsf*          = 4;  (* generation of new symbol file allowed *)
    ptrinit*        = 5;  (* pointer initialization *)
    ansi*           = 6;  (* ANSI or K&R style prototypes *)
    assert*         = 7;  (* assert evaluation *)
    extsf*          = 9;  (* extension of old symbol file allowed *)
    mainprog*       = 10; (* translate module body into C main function *)
    dontasm*        = 13; (* don't call external assembler/C compiler *)
    dontlink*       = 14; (* don't link *)
    mainlinkstat*   = 15; (* generate code for main module and then link object file statically *)
    notcoloroutput* = 16; (* turn off color output *)
    forcenewsym*    = 17; (* force new symbol file *)
    verbose*        = 18; (* verbose *)
    defopt*         = {inxchk, typchk, ptrinit, ansi, assert};  (* default options *)

    nilval*         = 0;

    MaxRExp*        = 38;
    MaxLExp*        = 308;

    MinHaltNr*      = 0;
    MaxHaltNr*      = 255;
    MaxSysFlag*     = 1;

    MaxCC*          = -1;  (* SYSTEM.CC, GETREG, PUTREG; not implementable in C backend *)
    MinRegNr*       = 0;
    MaxRegNr*       = -1;

    LANotAlloc*     = -1;  (* XProc link adr initialization *)
    ConstNotAlloc*  = -1;  (* for allocation of string and real constants *)
    TDAdrUndef*     = -1;  (* no type desc allocated *)

    MaxCases*       = 128;
    MaxCaseRange*   = 512;

    MaxStruct*      = 255;

    (* maximal number of pointer fields in a record: *)
    MaxPtr*         = MAX(LONGINT);

    (* maximal number of global pointers per module: *)
    MaxGPtr*        = MAX(LONGINT);

    (* maximal number of hidden fields in an exported record: *)
    MaxHdFld*       = 2048;

    HdPtrName*      = "@ptr";
    HdProcName*     = "@proc";
    HdTProcName*    = "@tproc";

    ExpHdPtrFld*    = TRUE;
    ExpHdProcFld*   = FALSE;
    ExpHdTProc*     = FALSE;

    NEWusingAdr*    = FALSE;

    Eot*            = 0X;

    HeaderFile*     = 0;
    BodyFile*       = 1;
    HeaderInclude*  = 2;

    SFext = ".sym"; (* symbol file extension *)
    BFext = ".c";   (* body file extension *)
    HFext = ".h";   (* header file extension *)
    SFtag = 0F7X;   (* symbol file tag *)




    (***** Symbols *****)


    (* Symbols values (also used as op values):
       |  0          1          2          3          4
    ---|--------------------------------------------------------
     0 |  null       *          /          DIV        MOD
     5 |  &          +          -          OR         =
    10 |  #          <          <=         >          >=
    15 |  IN         IS         ^          .          ,
    20 |  :          ..         )          ]          }
    25 |  OF         THEN       DO         TO         BY
    30 |  (          [          {          ~          :=
    35 |  number     NIL        string     OPM.ident      ;
    40 |  |          END        ELSE       ELSIF      UNTIL
    45 |  IF         CASE       WHILE      REPEAT     FOR
    50 |  LOOP       WITH       EXIT       RETURN     ARRAY
    55 |  RECORD     POINTER    BEGIN      CONST      TYPE
    60 |  VAR        PROCEDURE  IMPORT     MODULE     eof
    *)

    null*   = 0;  times*     = 1;  slash*   = 2;  div*    = 3;  mod*       = 4;
    and*    = 5;  plus*      = 6;  minus*   = 7;  or*     = 8;  eql*       = 9;
    neq*    = 10; lss*       = 11; leq*     = 12; gtr*    = 13; geq*       = 14;
    in*     = 15; is*        = 16; arrow*   = 17; period* = 18; comma*     = 19;
    colon*  = 20; upto*      = 21; rparen*  = 22; rbrak*  = 23; rbrace*    = 24;
    of*     = 25; then*      = 26; do*      = 27; to*     = 28; by*        = 29;
    lparen* = 30; lbrak*     = 31; lbrace*  = 32; not*    = 33; becomes*   = 34;
    number* = 35; nil*       = 36; string*  = 37; ident*  = 38; semicolon* = 39;
    bar*    = 40; end*       = 41; else*    = 42; elsif*  = 43; until*     = 44;
    if*     = 45; case*      = 46; while*   = 47; repeat* = 48; for*       = 49;
    loop*   = 50; with*      = 51; exit*    = 52; return* = 53; array*     = 54;
    record* = 55; pointer*   = 56; begin*   = 57; const*  = 58; type*      = 59;
    var*    = 60; procedure* = 61; import*  = 62; module* = 63; eof*       = 64;

    (* Symbol numtyp values *)
    char* = 1; integer* = 2; real* = 3; longreal* = 4;




    (***** Objects *****)


    (* Object.mode values *)
    Var*   = 1; VarPar* = 2; Con*   = 3;  Fld* = 4;  Typ* = 5;   LProc* = 6;  XProc* = 7;
    SProc* = 8; CProc*  = 9; IProc* = 10; Mod* = 11; Head* = 12; TProc* = 13;

    (* Object.vis - module visibility of objects *)
    internal* = 0; external* = 1; externalR* = 2;

    (* Object.history - History of imported objects *)
    inserted* = 0; same* = 1; pbmodified* = 2; pvmodified* = 3; removed* = 4; inconsistent* = 5;

    (* Object.adr Function numbers *)
    haltfn*   = 0;  newfn*  = 1;  absfn*    = 2;  capfn*  = 3;  ordfn* = 4;
    entierfn* = 5;  oddfn*  = 6;  minfn*    = 7;  maxfn*  = 8;  chrfn* = 9;
    shortfn*  = 10; longfn* = 11; sizefn*   = 12; incfn*  = 13; decfn* = 14;
    inclfn*   = 15; exclfn* = 16; lenfn*    = 17; copyfn* = 18; ashfn* = 19;
    adrfn*    = 20; ccfn*   = 21; lshfn*    = 22; rotfn*  = 23; getfn* = 24; (* SYSTEM *)
    putfn*    = 25; getrfn* = 26; putrfn*   = 27; bitfn*  = 28; valfn* = 29; (* SYSTEM *)
    sysnewfn* = 30; movefn* = 31;                                            (* SYSTEM *)
    assertfn* = 32;




    (***** Structures *****)


    (* Struct.form values *)
    Undef*   = 0;  Byte*    = 1;  Bool*    = 2;  Char*    = 3;
    SInt*    = 4;  Int*     = 5;  LInt*    = 6;
    Real*    = 7;  LReal*   = 8;  Set*     = 9;  String*  = 10;
    NilTyp*  = 11; NoTyp*   = 12; Pointer* = 13; ProcTyp* = 14;
    Comp*    = 15;

    intSet* = {SInt..LInt(*, Int8..Int64*)}; realSet* = {Real, LReal};

    (* Struct.comp - Composite structure forms *)
    Basic* = 1; Array* = 2; DynArr* = 3; Record* = 4;




    (***** Nodes *****)


    (* Node.class values *)
    Nvar*    = 0;  Nvarpar* = 1;  Nfield*   = 2;  Nderef*  = 3;  Nindex* = 4;  Nguard*  = 5;  Neguard* = 6;
    Nconst*  = 7;  Ntype*   = 8;  Nproc*    = 9;  Nupto*   = 10; Nmop*   = 11; Ndop*    = 12; Ncall*   = 13;
    Ninittd* = 14; Nif*     = 15; Ncaselse* = 16; Ncasedo* = 17; Nenter* = 18; Nassign* = 19;
    Nifelse* = 20; Ncase*   = 21; Nwhile*   = 22; Nrepeat* = 23; Nloop*  = 24; Nexit*   = 25;
    Nreturn* = 26; Nwith*   = 27; Ntrap*    = 28;


    (* Node.subcl values - general *)
    assign* = 0;  (* Pseudo function number for assignment *)
    super*  = 1;

    (* Node.subcl values - functions *)
    ash*   = 17; msk* = 18; len* = 19;
    conv*  = 20; abs* = 21; cap* = 22; odd* = 23;

    (* Node.subcl values - SYSTEM functions *)
    adr* = 24; cc* = 25; bit* = 26; lsh* = 27; rot* = 28; val* = 29;

    (* Note: some object.adr function numbers and some symbol types are
    also are used as Node.subcl function ids *)



    (* conval^.setval procedure flags *)
    hasBody* = 1; isRedef* = 2; slNeeded* = 3;




  TYPE
    FileName = ARRAY 32 OF CHAR;

  VAR
    SourceFileName : ARRAY 256 OF CHAR;

    Alignment*: INTEGER;

    ByteSize*, CharSize*, BoolSize*, SIntSize*, IntSize*,
    LIntSize*, SetSize*, RealSize*, LRealSize*, PointerSize*, ProcSize*, RecSize*,
    CharAlign*, BoolAlign*, SIntAlign*, IntAlign*,
    LIntAlign*, SetAlign*, RealAlign*, LRealAlign*, PointerAlign*, ProcAlign*, RecAlign*,
    MaxSet*: INTEGER;

    MinSInt*, MinInt*, MinLInt*, MaxSInt*, MaxInt*, MaxLInt*, MaxIndex*: LONGINT;

    MinReal*, MaxReal*, MinLReal*, MaxLReal*: LONGREAL;

    noerr*:           BOOLEAN;
    curpos*, errpos*: LONGINT;  (* character and error position in source file *)
    breakpc*:         LONGINT;  (* set by OPV.Init *)
    currFile*:        INTEGER;  (* current output file *)
    level*:           INTEGER;  (* procedure nesting level *)
    pc*, entno*:      INTEGER;  (* entry number *)
    modName*:         ARRAY 32 OF CHAR;
    objname*:         ARRAY 64 OF CHAR;
    opt*, glbopt*:    SET;

    ErrorLineStartPos, ErrorLineLimitPos, ErrorLineNumber: LONGINT;  (* Limit = start of next line *)

    lasterrpos:   LONGINT;
    inR:          Texts.Reader;
    Log:          Texts.Text;
    W:            Texts.Writer;
    oldSF, newSF: Files.Rider;
    R:            ARRAY 3 OF Files.Rider;

    oldSFile, newSFile, HFile, BFile, HIFile: Files.File;

    S: INTEGER;

    dontAsm-, dontLink-, mainProg-, mainLinkStat-, notColorOutput-, forceNewSym-, Verbose-: BOOLEAN;

    OBERON:  ARRAY 1024 OF CHAR;
    MODULES: ARRAY 1024 OF CHAR;


  (* ------------------------- Log Output ------------------------- *)

  PROCEDURE LogW*(ch: CHAR);            BEGIN Console.Char(ch)    END LogW;
  PROCEDURE LogWStr*(s: ARRAY OF CHAR); BEGIN Console.String(s)   END LogWStr;
  PROCEDURE LogWNum*(i, len: LONGINT);  BEGIN Console.Int(i, len) END LogWNum;
  PROCEDURE LogWLn*;                    BEGIN Console.Ln          END LogWLn;


  (* ------------------------- parameter handling -------------------------*)

  PROCEDURE ScanOptions(VAR s: ARRAY OF CHAR; VAR opt: SET);
    VAR i: INTEGER;
  BEGIN
  i := 1; (* skip - *)
    WHILE s[i] # 0X DO
      CASE s[i] OF

      | "a": opt := opt / {assert}
      | "c": opt := opt / {dontlink}
      | "e": opt := opt / {extsf}
      | "f": opt := opt / {notcoloroutput}
      | "k": opt := opt / {ansi}             (* undocumented *)
      | "m": opt := opt / {mainprog}
      | "p": opt := opt / {ptrinit}
      | "r": opt := opt / {ranchk}
      | "s": opt := opt / {newsf}
      | "t": opt := opt / {typchk}
      | "x": opt := opt / {inxchk}

      | "B": IF s[i+1] # 0X THEN INC(i); IntSize     := ORD(s[i]) - ORD('0') END;
             IF s[i+1] # 0X THEN INC(i); PointerSize := ORD(s[i]) - ORD('0') END;
             IF s[i+1] # 0X THEN INC(i); Alignment   := ORD(s[i]) - ORD('0') END;
             ASSERT((IntSize     = 2) OR (IntSize     = 4));
             ASSERT((PointerSize = 4) OR (PointerSize = 8));
             ASSERT((Alignment   = 4) OR (Alignment   = 8));
             Files.SetSearchPath("")
      | "F": opt := opt / {forcenewsym}
      | "M": opt := opt / {mainlinkstat}
      | "S": opt := opt / {dontasm}
      | "V": opt := opt / {verbose}
      ELSE
        LogWStr("  warning: option ");
        LogW(OptionChar);
        LogW(s[i]);
        LogWStr(" ignored");
        LogWLn
      END;
      INC(i)
    END;
  END ScanOptions;


  PROCEDURE ^GetProperties;


  (* Undocumented options used by the build system:

     The following parameter overrides the integer size, pointer size and alignment
     settings compiled into the binary. They are used when bootstrapping to generate
     the C source for a compiler with different sizes to the current compiler.

     -Bnnn  Where each n is a single digit specifying the integer size, pointer size
            and alignment in bytes.

            An alignment of n means that types smaller than n align to their
            own size, types larger than n align to n bytes.

            LONGINT size will be set to twice the integer size.
  *)

  PROCEDURE OpenPar*(): BOOLEAN;  (* prepare for a sequence of translations *)
    VAR s: ARRAY 256 OF CHAR;
  BEGIN
    IF Platform.ArgCount = 1 THEN
      LogWLn;
      LogWStr("Vishap Oberon-2 compiler v"); LogWStr(Configuration.versionLong); LogW("."); LogWLn;
      LogWStr("Based on Ofront by Software Templ OEG, continued by Norayr Chilingarian and others."); LogWLn;
      LogWLn;
      LogWStr('Usage:'); LogWLn; LogWLn;
      LogWStr('  '); LogWStr(Configuration.name); LogWStr(' options {files {options}}.'); LogWLn; LogWLn;
      LogWStr('Where options = ["-" {option} ].'); LogWLn;
      LogWLn;
      LogWStr("  m - generate code for main module"); LogWLn;
      LogWStr("  M - generate code for main module and link object statically"); LogWLn;
      LogWStr("  s - generate new symbol file"); LogWLn;
      LogWStr("  e - allow extending the module interface"); LogWLn;
      LogWStr("  r - check value ranges"); LogWLn;
      LogWStr("  x - turn off array indices check"); LogWLn;
      LogWStr("  a - don't check ASSERTs at runtime, use this option in tested production code"); LogWLn;
      LogWStr("  p - turn off automatic pointer initialization"); LogWLn;
      LogWStr("  t - don't check type guards (use in rare cases such as low-level modules where every cycle counts)"); LogWLn;
      LogWStr("  S - don't call external assembler/compiler, only generate C code"); LogWLn;
      LogWStr("  c - don't call linker"); LogWLn;
      LogWStr("  f - don't use color output"); LogWLn;
      LogWStr("  F - force writing new symbol file in current directory"); LogWLn;
      LogWStr("  V - verbose output"); LogWLn;
      LogWLn;
      LogWStr('Initial options specify defaults for all files.'); LogWLn;
      LogWStr('Options following a filename are specific to that file.'); LogWLn;
      LogWStr('Repeating an option toggles its value.'); LogWLn;
      RETURN FALSE
    ELSE
      S:=1; s:=""; Platform.GetArg(S, s);

      glbopt := defopt;

      WHILE s[0] = OptionChar DO
        ScanOptions(s, glbopt);
        INC(S); s:=""; Platform.GetArg(S, s)
      END;

      RETURN TRUE
    END;
  END OpenPar;


  PROCEDURE InitOptions*;  (* get the options for one translation *)
    VAR s: ARRAY 256 OF CHAR;
  BEGIN
    opt := glbopt;
    s:=""; Platform.GetArg(S, s);
    WHILE s[0] = OptionChar DO
      ScanOptions(s, opt);
      INC(S); s:=""; Platform.GetArg(S, s)
    END;

    dontAsm        := dontasm        IN opt;
    dontLink       := dontlink       IN opt;
    mainProg       := mainprog       IN opt;
    mainLinkStat   := mainlinkstat   IN opt;
    notColorOutput := notcoloroutput IN opt;
    forceNewSym    := forcenewsym    IN opt;
    Verbose        := verbose        IN opt;

    IF mainLinkStat THEN INCL(glbopt, mainprog) END; (* sic *)

    GetProperties;
  END InitOptions;


  PROCEDURE Init*(VAR done: BOOLEAN; VAR mname : ARRAY OF CHAR);  (* get the source for one translation *)
  VAR
    T: Texts.Text;
    beg, end, time: LONGINT;
    s: ARRAY 256 OF CHAR;
  BEGIN
    done := FALSE;
    curpos := 0;
    IF S >= Platform.ArgCount THEN RETURN END ;

    s:=""; Platform.GetArg(S, s);

    NEW(T); Texts.Open(T, s);
    LogWStr(s); LogWStr("  ");
    COPY(s, mname);
    COPY(s, SourceFileName); (* to keep it also in this module -- noch *)

    IF T.len = 0 THEN
      LogWStr(s); LogWStr(" not found."); LogWLn
    ELSE
      Texts.OpenReader(inR, T, 0);
      done := TRUE
    END;

    INC(S);
    level := 0; noerr := TRUE; errpos := curpos; lasterrpos := curpos -10;
    ErrorLineStartPos := 0; ErrorLineLimitPos := 0; ErrorLineNumber := 0;
  END Init;



  (* ------------------------- read source text -------------------------*)

  PROCEDURE Get*(VAR ch: CHAR);  (* read next character from source text, 0X if eof *)
  BEGIN
    Texts.Read(inR, ch);
    IF ch = 0DX THEN
       curpos := Texts.Pos(inR); (* supports CR LF mapping *)
    ELSE
      INC(curpos)
    END ;
    IF (ch < 09X) & ~inR.eot THEN ch := " " END
  END Get;


  PROCEDURE MakeFileName(VAR name, FName: ARRAY OF CHAR; ext: ARRAY OF CHAR);
    VAR i, j: INTEGER; ch: CHAR;
  BEGIN i := 0;
    LOOP ch := name[i];
      IF ch = 0X THEN EXIT END ;
      FName[i] := ch; INC(i)
    END ;
    j := 0;
    REPEAT ch := ext[j]; FName[i] := ch; INC(i); INC(j)
    UNTIL ch = 0X
  END MakeFileName;


  PROCEDURE LogErrMsg(n: INTEGER);
    VAR
      S: Texts.Scanner; T: Texts.Text;
      ch: CHAR; i: INTEGER;
      buf: ARRAY 1024 OF CHAR;
  BEGIN
    IF n >= 0 THEN
       IF ~notColorOutput THEN vt100.SetAttr(vt100.Red) END;
       LogWStr("  err ");
       IF ~notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;
    ELSE
       IF ~notColorOutput THEN vt100.SetAttr(vt100.Magenta) END;
       LogWStr("  warning "); n := -n;
       IF ~notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;
    END ;
    LogWNum(n, 1);
    LogWStr("  ");
    (*NEW(T); Texts.Open(T, "vocErrors.Text"); Texts.OpenScanner(S, T, 0);
    REPEAT S.line := 0;
      REPEAT Texts.Scan(S) UNTIL S.eot OR (S.line # 0)
    UNTIL S.eot OR (S.class = Texts.Int) & (S.i = n);
    IF ~S.eot THEN Texts.Read(S, ch); i := 0;
      WHILE ~S.eot & (ch # 0DX) DO buf[i] := ch; INC(i); Texts.Read(S, ch) END ;
      buf[i] := 0X; LogWStr(buf);
    END*)
    LogWStr(errors.errors[n]);
  END LogErrMsg;


  PROCEDURE FindLine(f: Files.File; VAR r: Files.Rider; pos: LONGINT);
  (* Updates ErrorLineStartPos, ErrorLineLimitPos, ErrorLineNumber to
     describe the line containing pos.
     Exits with the rider set to the start of the line conaining pos. *)
  VAR
    ch, cheol: CHAR;
  BEGIN
    IF pos < ErrorLineStartPos THEN  (* Desired position is before saved position, start again at the begnning of file *)
      ErrorLineStartPos := 0; ErrorLineLimitPos := 0; ErrorLineNumber := 0
    END;
    IF pos < ErrorLineLimitPos THEN (* Current saved line positions contain pos *)
      Files.Set(r, f, ErrorLineStartPos);
      RETURN
    END;

    Files.Set(r, f, ErrorLineLimitPos);
    Files.Read(r, ch);
    WHILE (ErrorLineLimitPos < pos) & ~r.eof DO
      ErrorLineStartPos := ErrorLineLimitPos;
      INC(ErrorLineNumber);
      WHILE (ch # 0X) & (ch # 0DX) & (ch # 0AX) DO
        Files.Read(r, ch); INC(ErrorLineLimitPos)
      END;
      cheol := ch; Files.Read(r, ch); INC(ErrorLineLimitPos);
      IF (cheol = 0DX) & (ch = 0AX) THEN
        INC(ErrorLineLimitPos); Files.Read(r, ch)
      END
    END;
    Files.Set(r, f, ErrorLineStartPos);
  END FindLine;


  PROCEDURE ShowLine(pos: LONGINT);
  VAR
    f:    Files.File;
    r:    Files.Rider;
    line: ARRAY 1023 OF CHAR;
    i:    INTEGER;
    ch:   CHAR;
  BEGIN
    f := Files.Old(SourceFileName);
    FindLine(f, r, pos);

    i := 0; Files.Read(r, ch);
    WHILE (ch # 0X) & (ch # 0DX) & (ch # 0AX) & (i < LEN(line)-1) DO
      line[i] := ch; INC(i); Files.Read(r, ch)
    END;
    line[i] := 0X;

    LogWLn; LogWLn;
    LogWNum(ErrorLineNumber, 4); LogWStr(": "); LogWStr(line); LogWLn;
    LogWStr("      ");

    IF pos >= ErrorLineLimitPos THEN pos := ErrorLineLimitPos-1 END;
    i := SHORT(pos - ErrorLineStartPos);
    WHILE i > 0 DO LogW(" "); DEC(i) END;

    IF ~notColorOutput THEN vt100.SetAttr(vt100.Green) END;
    LogW("^");
    IF ~notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;

    Files.Close(f);
  END ShowLine;


  PROCEDURE Mark*(n: INTEGER; pos: LONGINT);
  BEGIN
    IF pos = -1 THEN pos := 0 END;
    IF n >= 0 THEN
      noerr := FALSE;
      IF (pos < lasterrpos) OR (lasterrpos + 9 < pos) THEN lasterrpos := pos; ShowLine(pos); LogWLn; LogWStr("  ");
        IF n < 249 THEN LogWStr("  pos"); LogWNum(pos, 6); LogErrMsg(n)
        ELSIF n = 255 THEN LogWStr("pos"); LogWNum(pos, 6); LogWStr("  pc "); LogWNum(breakpc, 1)
        ELSIF n = 254 THEN LogWStr("pc not found")
        ELSE LogWStr(objname);
          IF    n = 253 THEN LogWStr(" is new, compile with option e")
          ELSIF n = 252 THEN LogWStr(" is redefined, compile with option s")
          ELSIF n = 251 THEN LogWStr(" is redefined (private part only), compile with option s")
          ELSIF n = 250 THEN LogWStr(" is no longer visible, compile with option s")
          ELSIF n = 249 THEN LogWStr(" is not consistently imported, recompile imports")
          END
        END
      END
    ELSE
      IF pos >= 0 THEN ShowLine(pos); LogWLn; LogWStr("  pos"); LogWNum(pos, 6) END ;
      LogErrMsg(n);
      IF pos < 0 THEN LogWLn END
    END
  END Mark;


  PROCEDURE err*(n: INTEGER);
  BEGIN Mark(n, errpos)
  END err;


  PROCEDURE FPrint*(VAR fp: LONGINT; val: LONGINT);
  BEGIN
    fp := SYSTEM.ROT(SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, fp) / SYSTEM.VAL(SET, val)), 1)
  END FPrint;


  PROCEDURE FPrintSet*(VAR fp: LONGINT; set: SET);
  BEGIN FPrint(fp, SYSTEM.VAL(LONGINT, set))
  END FPrintSet;


  PROCEDURE FPrintReal*(VAR fp: LONGINT; real: REAL);
    VAR i: INTEGER; l: LONGINT;
  BEGIN
    IF SIZE(REAL) = SIZE(INTEGER) THEN
      SYSTEM.GET(SYSTEM.ADR(real), i); l := i;
    ELSE
      SYSTEM.GET(SYSTEM.ADR(real), l);
    END;
    FPrint(fp, l)
  END FPrintReal;


  PROCEDURE FPrintLReal*(VAR fp: LONGINT; lr: LONGREAL);
  VAR l, h: LONGINT;
  BEGIN
    IF SIZE(LONGREAL) = SIZE(LONGINT) THEN
      (* 64 bit LONGINT *)
      FPrint(fp, SYSTEM.VAL(LONGINT, lr))
    ELSE
      (* 32 bit LONGINT *)
      SYSTEM.GET(SYSTEM.ADR(lr), l); SYSTEM.GET(SYSTEM.ADR(lr)+4, h);
      FPrint(fp, l); FPrint(fp, h)
    END
  END FPrintLReal;




  (* ------------------------- initialization ------------------------- *)

  PROCEDURE GetProperty(VAR S: Texts.Scanner; name: ARRAY OF CHAR; VAR size, align: INTEGER);
  BEGIN
    IF (S.class = Texts.Name) & (S.s = name) THEN Texts.Scan(S);
      IF S.class = Texts.Int THEN size := SHORT(S.i); Texts.Scan(S) ELSE Mark(-157, -1) END ;
      IF S.class = Texts.Int THEN align := SHORT(S.i); Texts.Scan(S) ELSE Mark(-157, -1) END
    ELSE Mark(-157, -1)
    END
  END GetProperty;


  PROCEDURE minusop(i: LONGINT): LONGINT;
  BEGIN
    RETURN -i;
  END minusop;


  PROCEDURE power0(i, j : LONGINT) : LONGINT; (* we would like to calculate exact Min Max values in GetProperties, not hardcode em, noch *)
  VAR k : LONGINT;
      p : LONGINT;
  BEGIN
     k := 1;
     p := i;
     REPEAT
        p := p * i;
        INC(k);
     UNTIL k=j;
     RETURN p;
  END power0;


  PROCEDURE VerboseListSizes;
  BEGIN
    LogWLn;
    LogWStr("Type        Size  Alignement"); LogWLn;
    LogWStr("CHAR         "); LogWNum(CharSize,    4); LogWNum(CharAlign,    5); LogWLn;
    LogWStr("BOOLEAN      "); LogWNum(BoolSize,    4); LogWNum(BoolAlign,    5); LogWLn;
    LogWStr("SHORTINT     "); LogWNum(SIntSize,    4); LogWNum(SIntAlign,    5); LogWLn;
    LogWStr("INTEGER      "); LogWNum(IntSize,     4); LogWNum(IntAlign,     5); LogWLn;
    LogWStr("LONGINT      "); LogWNum(LIntSize,    4); LogWNum(LIntAlign,    5); LogWLn;
    LogWStr("SET          "); LogWNum(SetSize,     4); LogWNum(SetAlign,     5); LogWLn;
    LogWStr("REAL         "); LogWNum(RealSize,    4); LogWNum(RealAlign,    5); LogWLn;
    LogWStr("LONGREAL     "); LogWNum(LRealSize,   4); LogWNum(LRealAlign,   5); LogWLn;
    LogWStr("PTR          "); LogWNum(PointerSize, 4); LogWNum(PointerAlign, 5); LogWLn;
    LogWStr("PROC         "); LogWNum(ProcSize,    4); LogWNum(ProcAlign,    5); LogWLn;
    LogWStr("RECORD       "); LogWNum(RecSize,     4); LogWNum(RecAlign,     5); LogWLn;
  (*LogWStr("ENDIAN       "); LogWNum(ByteOrder,   4); LogWNum(BitOrder,     5); LogWLn;*)
    LogWLn;
    LogWStr("Min shortint "); LogWNum(MinSInt,     4); LogWLn;
    LogWStr("Max shortint "); LogWNum(MaxSInt,     4); LogWLn;
    LogWStr("Min integer  "); LogWNum(MinInt,      4); LogWLn;
    LogWStr("Max integer  "); LogWNum(MaxInt,      4); LogWLn;
    LogWStr("Min longint  "); LogWNum(MinLInt,     4); LogWLn;
  END VerboseListSizes;


  PROCEDURE AlignSize*(size: LONGINT): INTEGER;
    VAR align: INTEGER;
  BEGIN
    IF size < Alignment THEN
      IF    size > 8 THEN align := 16
      ELSIF size > 4 THEN align := 8
      ELSIF size > 2 THEN align := 4
      ELSE                align := SHORT(size)
      END
    ELSE
      align := Alignment
    END;
    RETURN align
  END AlignSize;

  PROCEDURE GetProperties();
    VAR
      base:        LONGINT;
  BEGIN
    (* Fixed and Configuration.Mod based sizes have been initialised in
       the module startup code, and maybe overridden by the -Bnnn bootstrap
       parameter *)

    (* Derived sizes *)
    ProcSize := PointerSize;
    LIntSize := IntSize * 2;
    SetSize  := LIntSize;

    (* Calculate all type alignments *)
    CharAlign    := AlignSize(CharSize);
    BoolAlign    := AlignSize(BoolSize);
    SIntAlign    := AlignSize(SIntSize);
    RecAlign     := AlignSize(RecSize);
    RealAlign    := AlignSize(RealSize);
    LRealAlign   := AlignSize(LRealSize);
    PointerAlign := AlignSize(PointerSize);
    ProcAlign    := AlignSize(ProcSize);
    IntAlign     := AlignSize(IntSize);
    LIntAlign    := AlignSize(LIntSize);
    SetAlign     := AlignSize(SetSize);

    (* and I'd like to calculate it, not hardcode constants *)
    base := -2;
    MinSInt := ASH(base, SIntSize*8-2);
    MaxSInt := minusop(MinSInt + 1);

    MinInt := ASH(base, IntSize*8-2);
    MaxInt := minusop(MinInt + 1);

    MinLInt := ASH(base, LIntSize*8-2);
    MaxLInt := minusop(MinLInt +1);

    IF RealSize = 4 THEN MaxReal := 3.40282346D38
    ELSIF RealSize = 8 THEN MaxReal := 1.7976931348623157D307 * 9.999999
      (*should be 1.7976931348623157D308 *)
    END ;

    IF LRealSize = 4 THEN MaxLReal := 3.40282346D38
    ELSIF LRealSize = 8 THEN MaxLReal := 1.7976931348623157D307 * 9.999999
      (*should be 1.7976931348623157D308 *)
    END ;

    MinReal := -MaxReal;
    MinLReal := -MaxLReal;

    MaxSet := SetSize * 8 - 1;
    MaxIndex := MaxLInt; (* shouldn't it be like max(int)? so that for loop will be safe, noch *)

    IF Verbose THEN VerboseListSizes END;
  END GetProperties;




  (* ------------------------- Read Symbol File ------------------------- *)

  PROCEDURE SymRCh*(VAR ch: CHAR);
  BEGIN Files.Read(oldSF, ch)
  END SymRCh;

  PROCEDURE SymRInt*(): LONGINT;
    VAR k: LONGINT;
  BEGIN Files.ReadNum(oldSF, k); RETURN k
  END SymRInt;

  PROCEDURE SymRSet*(VAR s: SET);
  BEGIN Files.ReadNum(oldSF, SYSTEM.VAL(LONGINT, s))
  END SymRSet;

  PROCEDURE SymRReal*(VAR r: REAL);
  BEGIN Files.ReadReal(oldSF, r)
  END SymRReal;

  PROCEDURE SymRLReal*(VAR lr: LONGREAL);
  BEGIN Files.ReadLReal(oldSF, lr)
  END SymRLReal;

  PROCEDURE CloseOldSym*;
  END CloseOldSym;

  PROCEDURE OldSym*(VAR modName: ARRAY OF CHAR; VAR done: BOOLEAN);
    VAR ch: CHAR; fileName: FileName;
  BEGIN
    MakeFileName(modName, fileName, SFext);
    oldSFile := Files.Old(fileName); done := oldSFile # NIL;
    IF done THEN
      Files.Set(oldSF, oldSFile, 0); Files.Read(oldSF, ch);
      IF ch # SFtag THEN err(-306);  (*possibly a symbol file from another Oberon implementation, e.g. HP-Oberon*)
        CloseOldSym; done := FALSE
      END
    END
  END OldSym;

  PROCEDURE eofSF*(): BOOLEAN;
  BEGIN RETURN oldSF.eof
  END eofSF;




  (* ------------------------- Write Symbol File ------------------------- *)

  PROCEDURE SymWCh*(ch: CHAR);
  BEGIN Files.Write(newSF, ch)
  END SymWCh;

  PROCEDURE SymWInt*(i: LONGINT);
  BEGIN Files.WriteNum(newSF, i)
  END SymWInt;

  PROCEDURE SymWSet*(s: SET);
  BEGIN Files.WriteNum(newSF, SYSTEM.VAL(LONGINT, s))
  END SymWSet;

  PROCEDURE SymWReal*(r: REAL);
  BEGIN Files.WriteReal(newSF, r)
  END SymWReal;

  PROCEDURE SymWLReal*(lr: LONGREAL);
  BEGIN Files.WriteLReal(newSF, lr)
  END SymWLReal;

  PROCEDURE RegisterNewSym*;
  BEGIN
    IF (modName # "SYSTEM") OR (mainprog IN opt) THEN Files.Register(newSFile) END
  END RegisterNewSym;

  PROCEDURE DeleteNewSym*;
  END DeleteNewSym;

  PROCEDURE NewSym*(VAR modName: ARRAY OF CHAR);
    VAR fileName: FileName;
  BEGIN MakeFileName(modName, fileName, SFext);
    newSFile := Files.New(fileName);
    IF newSFile # NIL THEN Files.Set(newSF, newSFile, 0); Files.Write(newSF, SFtag)
    ELSE err(153)
    END
  END NewSym;




  (* ------------------------- Write Header & Body Files ------------------------- *)

  PROCEDURE Write*(ch: CHAR);
  BEGIN Files.Write(R[currFile], ch)
  END Write;

  PROCEDURE WriteString*(s: ARRAY [1] OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE s[i] # 0X DO INC(i) END ;
    Files.WriteBytes(R[currFile], s, i)
  END WriteString;

  PROCEDURE WriteStringVar*(VAR s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE s[i] # 0X DO INC(i) END ;
    Files.WriteBytes(R[currFile], s, i)
  END WriteStringVar;

  PROCEDURE WriteHex* (i: LONGINT);
    VAR s: ARRAY 3 OF CHAR;
      digit : INTEGER;
  BEGIN
    digit := SHORT(i) DIV 16;
    IF digit < 10 THEN s[0] := CHR (ORD ("0") + digit); ELSE s[0] := CHR (ORD ("a") - 10 + digit ); END;
    digit := SHORT(i) MOD 16;
    IF digit < 10 THEN s[1] := CHR (ORD ("0") + digit); ELSE s[1] := CHR (ORD ("a") - 10 + digit ); END;
    s[2] := 0X;
    WriteString(s)
  END WriteHex;

  PROCEDURE WriteInt* (i: LONGINT);
    VAR s: ARRAY 20 OF CHAR; i1, k: LONGINT;
  BEGIN
    IF (i = MinInt) OR (i = MinLInt) THEN
      (* abs(minint) is one more than maxint, causing problems representing the value as a minus sign
         followed by absoute value. Therefore represent as -maxint - 1. For INTEGER this avoids a
         compiler warning 'this decimal constant is unsigned only in ISO C90', for LONGINT it is the
         only way to represent MinLInt. *)
      Write("("); WriteInt(i+1); WriteString("-1)")
    ELSE i1 := ABS(i);
      s[0] := CHR(i1 MOD 10 + ORD("0")); i1 := i1 DIV 10; k := 1;
      WHILE i1 > 0 DO s[k] := CHR(i1 MOD 10 + ORD("0")); i1 := i1 DIV 10; INC(k) END ;
      IF i < 0 THEN s[k] := "-"; INC(k) END ;
      WHILE k > 0 DO  DEC(k); Write(s[k]) END
    END ;
  END WriteInt;

  PROCEDURE WriteReal* (r: LONGREAL; suffx: CHAR);
    VAR W: Texts.Writer; T: Texts.Text; R: Texts.Reader; s: ARRAY 32 OF CHAR; ch: CHAR; i: INTEGER;
  BEGIN
(*should be improved *)
    IF (r < MaxLInt) & (r > MinLInt) & (r = ENTIER(r)) THEN
      IF suffx = "f" THEN WriteString("(REAL)") ELSE WriteString("(LONGREAL)") END ;
      WriteInt(ENTIER(r))
    ELSE
      Texts.OpenWriter(W);
      IF suffx = "f" THEN Texts.WriteLongReal(W, r, 16) ELSE Texts.WriteLongReal(W, r, 23) END ;
      NEW(T); Texts.Open(T, ""); Texts.Append(T, W.buf);
      Texts.OpenReader(R, T, 0); i := 0; Texts.Read(R, ch);
      WHILE ch # 0X DO s[i] := ch; INC(i); Texts.Read(R, ch) END ;
  (* s[i] := suffx; s[i+1] := 0X;
  suffix does not work in K&R *)
      s[i] := 0X;
      i := 0; ch := s[0];
      WHILE (ch # "D") & (ch # 0X) DO INC(i); ch := s[i] END ;
      IF ch = "D" THEN s[i] := "e" END ;
      WriteString(s)
    END
  END WriteReal;

  PROCEDURE WriteLn* ();
  BEGIN Files.Write(R[currFile], 0AX)
  END WriteLn;

  PROCEDURE Append(VAR R: Files.Rider; F: Files.File);
    VAR R1: Files.Rider; buffer: ARRAY 4096 OF CHAR;
  BEGIN
    IF F # NIL THEN
      Files.Set(R1, F, 0); Files.ReadBytes(R1, buffer, LEN(buffer));
      WHILE LEN(buffer) - R1.res > 0 DO
        Files.WriteBytes(R, buffer, LEN(buffer) - R1.res);
        Files.ReadBytes(R1, buffer, LEN(buffer))
      END
    END
  END Append;

  PROCEDURE OpenFiles*(VAR moduleName: ARRAY OF CHAR);
    VAR FName: ARRAY 32 OF CHAR;
  BEGIN
    COPY(moduleName, modName);
    HFile := Files.New("");
    IF HFile # NIL THEN Files.Set(R[HeaderFile], HFile, 0) ELSE err(153) END ;
    MakeFileName(moduleName, FName, BFext);
    BFile := Files.New(FName);
    IF BFile # NIL THEN Files.Set(R[BodyFile], BFile, 0) ELSE err(153) END ;
    MakeFileName(moduleName, FName, HFext);
    HIFile := Files.New(FName);
    IF HIFile # NIL THEN Files.Set(R[HeaderInclude], HIFile, 0) ELSE err(153) END ;
  END OpenFiles;

  PROCEDURE CloseFiles*;
    VAR FName: ARRAY 32 OF CHAR; res: INTEGER;
  BEGIN
    IF noerr THEN LogWStr("  "); LogWNum(Files.Pos(R[BodyFile]), 0); LogWStr(" chars.") END;
    IF noerr THEN
      IF modName = "SYSTEM" THEN
        IF ~(mainprog IN opt) THEN Files.Register(BFile) END
      ELSIF ~(mainprog IN opt) THEN
        Append(R[HeaderInclude], HFile);
        Files.Register(HIFile); Files.Register(BFile)
      ELSE
        MakeFileName(modName, FName, HFext); Files.Delete(FName, res);
        MakeFileName(modName, FName, SFext); Files.Delete(FName, res);
        Files.Register(BFile)
      END
    END ;
    HFile := NIL; BFile := NIL; HIFile := NIL; newSFile := NIL; oldSFile := NIL;
    Files.Set(R[0], NIL, 0); Files.Set(R[1], NIL, 0); Files.Set(R[2], NIL, 0); Files.Set(newSF, NIL, 0); Files.Set(oldSF, NIL, 0)
  END CloseFiles;


BEGIN

  Texts.OpenWriter(W);

  MODULES := "";  Platform.GetEnv("MODULES", MODULES);

  OBERON  := "."; Platform.GetEnv("OBERON", OBERON);
  Strings.Append(";.;",                     OBERON);
  Strings.Append(MODULES,                   OBERON);
  Strings.Append(";",                       OBERON);
  Strings.Append(Configuration.installdir,  OBERON);
  Strings.Append("/sym;",                   OBERON);

  Files.SetSearchPath(OBERON);

  (* Fixed type sizes *)
  CharSize := 1; BoolSize  := 1; SIntSize := 1; RecSize := 1; ByteSize := 1;
  RealSize := 4; LRealSize := 8;

  (* type sizes with configuration based defaults *)
  PointerSize := Configuration.addressSize;
  Alignment   := Configuration.alignment;
  IntSize     := Configuration.intsize;

END OPM.
