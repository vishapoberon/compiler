MODULE OPM;  (* RC 6.3.89 / 28.6.89, J.Templ 10.7.89 / 22.7.96  *)
(* constants needed for C code generation 

  31.1.2007 jt synchronized with BlackBox version, in particular PromoteIntConstToLInt added
*)

  IMPORT SYSTEM, Texts := Texts0, Files := Files0, Args, Console, errors, version, vt100;

  CONST
    OptionChar* = "-";

    (* compiler options; don't change the encoding *)
    inxchk* = 0;  (* index check on *)
    vcpp* = 1;  (* VC++ support on; former ovflchk; neither used nor documented *)
    ranchk* = 2;  (* range check on *)
    typchk* = 3;  (* type check on *)
    newsf* = 4;  (* generation of new symbol file allowed *)
    ptrinit* = 5;  (* pointer initialization *)
    ansi* = 6;  (* ANSI or K&R style prototypes *)
    assert* = 7;  (* assert evaluation *)
    include0* = 8;  (* include M.h0 in header file and M.c0 in body file if such files exist *)
    extsf* = 9;  (* extension of old symbol file allowed *)
    mainprog* = 10;  (* translate module body into C main function *)
    lineno* = 11;  (* emit line numbers rather than text positions in error messages *)
    useparfile* = 12; (* use .par file *)
    dontasm* = 13; (* don't call external assembler/C compiler *)
    dontlink* = 14; (* don't link *)
    mainlinkstat* = 15; (* generate code for main module and then link object file statically *)
    notcoloroutput* = 16; (* turn off color output *)
    forcenewsym* = 17; (* force new symbol file *)
    defopt* = {inxchk, typchk, ptrinit, ansi, assert};  (* default options *)

    nilval* = 0;
(*
    MinRealPat = 0FF7FFFFFH;  (* most  negative, 32-bit pattern, -3.40282346E38 *)
    MinLRealPatL = 0FFFFFFFFH;  (* most  negative, lower 32-bit pattern *)
    MinLRealPatH = 0FFEFFFFFH;  (* most  negative, higher 32-bit pattern *)
    MaxRealPat = 7F7FFFFFH; (*3.40282346E38*)
    MaxLRealPatL = -1;
    MaxLRealPatH = 7FEFFFFFH;
*)

    MaxRExp* = 38;  MaxLExp* = 308;  MaxHDig* = 8;

    MinHaltNr* = 0;
    MaxHaltNr* = 255;
    MaxSysFlag* = 1;

    MaxCC* = -1;  (* SYSTEM.CC, GETREG, PUTREG; not implementable in C backend *)
    MinRegNr* = 0;
    MaxRegNr* = -1;

    LANotAlloc* = -1;  (* XProc link adr initialization *)
    ConstNotAlloc* = -1;  (* for allocation of string and real constants *)
    TDAdrUndef* = -1;  (* no type desc allocated *)

    MaxCases* = 128;
    MaxCaseRange* = 512;

    MaxStruct* = 255;

    (* maximal number of pointer fields in a record: *)
    MaxPtr* = MAX(LONGINT);

    (* maximal number of global pointers per module: *)
    MaxGPtr* = MAX(LONGINT);

    (* maximal number of hidden fields in an exported record: *)
    MaxHdFld* = 2048;
    
    HdPtrName* = "@ptr";
    HdProcName* = "@proc";
    HdTProcName* = "@tproc";

    ExpHdPtrFld* = TRUE;
    ExpHdProcFld* = FALSE;
    ExpHdTProc* = FALSE;

    NEWusingAdr* = FALSE;

    Eot* = 0X;

    SFext = ".sym";  (* symbol file extension *)
    BFext = ".c";  (* body file extension *)
    HFext = ".h";  (* header file extension *)
    SFtag = 0F7X;  (* symbol file tag *)

    HeaderFile* = 0;
    BodyFile* = 1;
    HeaderInclude* = 2;

  TYPE
    FileName = ARRAY 32 OF CHAR;

  VAR
    SourceFileName : ARRAY 256 OF CHAR;
    ByteSize*, CharSize*, BoolSize*, SIntSize*, IntSize*,
    LIntSize*, SetSize*, RealSize*, LRealSize*, PointerSize*, ProcSize*, RecSize*,
    CharAlign*, BoolAlign*, SIntAlign*, IntAlign*,
    LIntAlign*, SetAlign*, RealAlign*, LRealAlign*, PointerAlign*, ProcAlign*, RecAlign*,
    ByteOrder*, BitOrder*, MaxSet*: INTEGER;
    MinSInt*, MinInt*, MinLInt*, MaxSInt*, MaxInt*, MaxLInt*, MaxIndex*: LONGINT;
    MinReal*, MaxReal*, MinLReal*, MaxLReal*: LONGREAL;

    noerr*: BOOLEAN;
    curpos*, errpos*: LONGINT;  (* character and error position in source file *)
    breakpc*: LONGINT;  (* set by OPV.Init *)
    currFile*: INTEGER;  (* current output file *)
    level*: INTEGER;  (* procedure nesting level *)
    pc*, entno*: INTEGER;  (* entry number *)
    modName*: ARRAY 32 OF CHAR;
    objname*: ARRAY 64 OF CHAR;

    opt*, glbopt*: SET;

    lasterrpos: LONGINT;
    inR: Texts.Reader;
    Log: Texts.Text;
    W: Texts.Writer;
    oldSF, newSF: Files.Rider;
    R: ARRAY 3 OF Files.Rider;
    oldSFile, newSFile, HFile, BFile, HIFile: Files.File;

    S: INTEGER;
    stop, useLineNo, useParFile, dontAsm-, dontLink-, mainProg-, mainLinkStat-, notColorOutput-, forceNewSym-: BOOLEAN;


  (* ------------------------- Log Output ------------------------- *)

  PROCEDURE LogW*(ch: CHAR);
  BEGIN Console.Char(ch)
  END LogW;

  PROCEDURE LogWStr*(s: ARRAY OF CHAR);
  BEGIN Console.String(s)
  END LogWStr;
  
  PROCEDURE LogWNum*(i, len: LONGINT);
  BEGIN Console.Int(i, len)
  END LogWNum;

  PROCEDURE LogWLn*;
  BEGIN Console.Ln
  END LogWLn;


  (* ------------------------- parameter handling -------------------------*)

  PROCEDURE ScanOptions(VAR s: ARRAY OF CHAR; VAR opt: SET);
    VAR i: INTEGER;
  BEGIN
  i := 1; (* skip - *)
    WHILE s[i] # 0X DO
      CASE s[i] OF
      | "e": opt := opt / {extsf}
      | "s": opt := opt / {newsf}
      | "m": opt := opt / {mainprog}
      | "x": opt := opt / {inxchk}
      | "v": opt := opt / {vcpp};
      | "r": opt := opt / {ranchk}
      | "t": opt := opt / {typchk}
      | "a": opt := opt / {assert}
      | "k": opt := opt / {ansi}
      | "p": opt := opt / {ptrinit}
      | "i": opt := opt / {include0}
      | "l": opt := opt / {lineno}
      | "P": opt := opt / {useparfile}
      | "S": opt := opt / {dontasm}
      | "c": opt := opt / {dontlink}
      | "M": opt := opt / {mainlinkstat}
      | "f": opt := opt / {notcoloroutput}
      | "F": opt := opt / {forcenewsym}
      ELSE LogWStr("  warning: option "); LogW(OptionChar); LogW(s[i]); LogWStr(" ignored"); LogWLn
      END ;
      INC(i)
    END;
  END ScanOptions;

  PROCEDURE ^GetProperties;

  PROCEDURE OpenPar*;  (* prepare for a sequence of translations *)
    VAR s: ARRAY 256 OF CHAR;
  BEGIN
    IF Args.argc = 1 THEN stop := TRUE;
      Console.Ln;
      Console.String("voc - Vishap Oberon-2 compiler ");
      Console.String(version.version); Console.String (" ");
      Console.String(version.date); Console.String (" for "); Console.String(version.arch);
      Console.Ln;
      Console.String("based on Ofront by Software Templ OEG"); Console.Ln;
      Console.String("continued by Norayr Chilingarian and others"); Console.Ln;
      Console.Ln;
      Console.String('  command = "voc" options {file options}.'); Console.Ln;
      Console.String('  options = ["-" {option} ].'); Console.Ln;
      Console.String('  option  = "m" | "M" | "s" | "e" | "i" | "l" | "k" | "r" | "x" | "a" | "p" | "t" | "P" | "S" | "c" | "f" | "F" .'); Console.Ln;
      Console.Ln;
      Console.String(" m      - generate code for main module"); Console.Ln;
      Console.String(" M      - generate code for main module and link object statically"); Console.Ln;
      Console.String(" s      - generate new symbol file"); Console.Ln;
      Console.String(" e      - allow extending the module interface"); Console.Ln;
      Console.String(" i      - include header and body prefix files (c0)"); Console.Ln;
      Console.String(" l      - use line numbers"); Console.Ln;
      Console.String(" r      - check value ranges"); Console.Ln;
      Console.String(" x      - turn off array indices check"); Console.Ln;
      Console.String(" a      - don't check ASSERTs at runtime, use this option in tested production code"); Console.Ln;
      Console.String(" p      - turn off automatic pointer initialization"); Console.Ln;
      Console.String(" t      - don't check type guards (use in rare cases such as low-level modules where every cycle counts)"); Console.Ln;
      Console.String(" P      - use .par file"); Console.Ln;
      Console.String(" S      - don't call external assembler/compiler, only generate the asm/C code"); Console.Ln;
      Console.String(" c      - don't call linker"); Console.Ln;
      Console.String(" f      - don't use color output"); Console.Ln;
      Console.String(" F      - force writing new symbol file"); Console.Ln;
      Console.Ln;
    ELSE
      glbopt := defopt; S := 1; s := "";
      Args.Get(1, s); stop := FALSE;
      WHILE s[0] = OptionChar DO ScanOptions(s, glbopt); INC(S); s := ""; Args.Get(S, s) END;
      IF lineno IN opt THEN (* this brought here from InitOptions which turned out to be unnecessary *)
         useLineNo := TRUE; curpos := 256; errpos := curpos; 
	 lasterrpos := curpos - 10
      ELSE 
         useLineNo := FALSE;
      END;
      IF useparfile IN glbopt THEN useParFile := TRUE ELSE useParFile := FALSE END; (* this check must be made before calling getproperties,  noch *)
      IF dontasm IN glbopt THEN dontAsm := TRUE ELSE dontAsm := FALSE END;
      IF dontlink IN glbopt THEN dontLink := TRUE ELSE dontLink := FALSE END;
      IF mainprog IN glbopt THEN mainProg := TRUE ELSE mainProg := FALSE END;
      IF mainlinkstat IN glbopt THEN INCL(glbopt, mainprog); mainLinkStat := TRUE ELSE mainLinkStat := FALSE END;
      IF notcoloroutput IN glbopt THEN notColorOutput := TRUE ELSE notColorOutput := FALSE END;
      IF forcenewsym IN glbopt THEN forceNewSym := TRUE ELSE forceNewSym := FALSE END;
      GetProperties; (* GetProperties moved here in order to call it after ScanOptions because we have an option whether to use par file or not, noch *)

    END;
  END OpenPar;

  PROCEDURE InitOptions*;  (* get the options for one translation *)
    VAR s: ARRAY 256 OF CHAR;
  BEGIN
    opt := glbopt; s := ""; Args.Get(S, s);
    WHILE s[0] = OptionChar DO ScanOptions(s, opt); INC(S); s := ""; Args.Get(S, s) END ;
   IF lineno IN opt THEN useLineNo := TRUE; curpos := 256; errpos := curpos; lasterrpos := curpos - 10
    ELSE useLineNo := FALSE;
    END;

      IF useparfile IN opt THEN useParFile := TRUE ELSE useParFile := FALSE END; (* this check must be made before calling getproperties,  noch *)
      IF dontasm IN opt THEN dontAsm := TRUE ELSE dontAsm := FALSE END;
      IF dontlink IN opt THEN dontLink := TRUE ELSE dontLink := FALSE END;
      IF mainprog IN opt THEN mainProg := TRUE ELSE mainProg := FALSE END;
      IF mainlinkstat IN opt THEN INCL(glbopt, mainprog); mainLinkStat := TRUE ELSE mainLinkStat := FALSE END;

  END InitOptions;

  PROCEDURE Init*(VAR done: BOOLEAN; VAR mname : ARRAY OF CHAR);  (* get the source for one translation *)
    VAR T: Texts.Text; beg, end, time: LONGINT;
      s: ARRAY 256 OF CHAR;
  BEGIN
    done := FALSE; curpos := 0;
    IF stop OR (S >= Args.argc) THEN RETURN END ;
    s := ""; Args.Get(S, s);
    NEW(T); Texts.Open(T, s);
    LogWStr(s);
    COPY(s, mname);
    COPY(s, SourceFileName); (* to keep it also in this module -- noch *)
    IF T.len = 0 THEN LogWStr(" not found"); LogWLn
    ELSE
      Texts.OpenReader(inR, T, 0);
      LogWStr("  translating");
      done := TRUE
    END ;
    INC(S);
    level := 0; noerr := TRUE; errpos := curpos; lasterrpos := curpos -10;
  END Init;

  (* ------------------------- read source text -------------------------*)
  
  PROCEDURE Get*(VAR ch: CHAR);  (* read next character from source text, 0X if eof *)
  BEGIN
    Texts.Read(inR, ch);
    IF useLineNo THEN 
      IF ch = 0DX THEN curpos := (curpos DIV 256 + 1) * 256
      ELSIF curpos MOD 256 # 255 THEN INC(curpos)
        (* at 255 means:  >= 255 *)
      END
    ELSIF ch = 0DX THEN
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
    VAR S: Texts.Scanner; T: Texts.Text; ch: CHAR; i: INTEGER;
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

  PROCEDURE ShowLine(pos: LONGINT);
     VAR
     f : Files.File;
     r : Files.Rider;
     newpos, localpos, delta : LONGINT;
     line : ARRAY 1023 OF CHAR;
     i : INTEGER;
     ch : CHAR;
  BEGIN
     localpos := pos;
     f := Files.Old(SourceFileName);

     (*
     Console.Ln; Console.String("-- source file is "); Console.String(SourceFileName); Console.Ln;
     Console.String("-- pos is "); Console.Int(pos, 0); Console.Ln;
     *)
     (* make sure previous character is character *) 
     REPEAT
	DEC(localpos); IF localpos < 0 THEN localpos := 0 END;
        Files.Set(r, f, localpos);
        Files.Read(r, ch);
     UNTIL (localpos < 1) OR(ORD(ch) >= 32) OR (ORD(ch)=9);
     newpos := localpos;
     (*
     Console.String("-- newpos, last character before error "); Console.Int(newpos, 0); Console.Ln;
     *)
     (* finding last line end *)
     REPEAT
	DEC(localpos); IF localpos < 0 THEN newpos := 0 END;
        Files.Set(r, f, localpos);
        Files.Read(r, ch);
(*
        Console.String("-- prev num "); Console.Int(localpos, 0);Console.String("  "); Console.Char(ch); Console.Ln;
*)
     UNTIL (localpos < 1) OR ((ORD(ch) < 32) & (ORD(ch) # 9));
(*     
     Console.String("-- previous line at pos "); Console.Int(localpos, 0); Console.Ln;
*)
     delta := newpos - localpos - 1;
     IF delta < 1 THEN delta := 1 END;
  (*   
     Console.String("-- delta "); Console.Int(delta, 0); Console.Ln;
*)
     (* skip enter *)
     REPEAT
        INC(localpos);
	Files.Set(r, f, localpos);
	Files.Read(r, ch);
     UNTIL (ORD(ch) >= 32) OR (ORD(ch) = 9);
     i := 0;
     REPEAT
	Files.Set(r, f, localpos);
        Files.Read(r, ch);
	IF ORD(ch) = 9 THEN ch := " " END;
	line[i] := ch;
(*	
	Console.String("-- localpos "); Console.Int(localpos, 0); Console.Ln;
	Console.String(" -- ch "); Console.Char(ch); Console.Ln;
*)
	INC(localpos);
	INC(i);
     UNTIL r.eof OR (i >= 1022) OR ((ORD(ch) < 32) & (ORD(ch) # 9));
     line[i] := 0X;
     IF (line[i-1] = 0AX) OR (line[i-1] = 0DX) THEN line[i-1] := 0X END;
     (*Console.String(" -- length of line "); Console.Int(i, 0); Console.Ln;*)
     Console.Ln; Console.Ln; Console.String("  "); Console.String(line);
     Console.Ln;

     i := 0;
     Console.String("  ");
     REPEAT
        Console.Char(" ");
	INC(i);
     UNTIL i >= delta;
    IF ~notColorOutput THEN vt100.SetAttr(vt100.Green) END; 
     Console.Char("^"); (*Console.Ln;*)
    IF ~notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;
  Files.Close(f);

  END ShowLine;

  PROCEDURE ShowLineErr(linenum, posnum : LONGINT);
     VAR
        f : Files.File;
        r : Files.Rider;
        line : ARRAY 1023 OF CHAR;
        i,j : LONGINT;
        ch :      CHAR;
  BEGIN
     
     f := Files.Old(SourceFileName);
     Files.Set(r, f, 0);
     
     (* skip non character symbols in the beginning *)
     REPEAT
        Files.Read(r, ch);
     UNTIL ORD(ch) > 31;
     
     i := 0; j := 0;
     REPEAT
        IF (ORD(ch) > 31) OR (ORD(ch) = 9) THEN 
	   IF ORD(ch)=9 THEN ch := " " END;
	   line[i] := ch; INC(i); line[i+1] := 0X;
	ELSE 
	   IF ch = 0AX THEN INC(j); i := 0 END
	END;
        (* 
        Console.Ln; Console.String("-- line["); Console.Int(i-1, 0); Console.String("] = "); Console.Char(ch); Console.Ln;
*)
	Files.Read(r, ch);
(*
        Console.String("-- i "); Console.Int(i, 0); Console.Ln;

        Console.String("--j "); Console.Int(j, 0); Console.Ln;

	Console.Char(ch); Console.Ln;
*)
     UNTIL (j >= linenum) OR (i >= 1022);

     Console.Ln; Console.String("  "); Console.String(line); Console.Ln;

     i := 0;
     WHILE i < posnum-1 DO 
        Console.Char(" ");
	INC(i);
     END;

     Console.String("  "); (* compensate shift from Mark() ; -- noch *)
     IF ~notColorOutput THEN vt100.SetAttr(vt100.Green) END;
     Console.Char("^"); Console.Ln;
     IF ~notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;

     Files.Close(f);

  END ShowLineErr;

  PROCEDURE Mark*(n: INTEGER; pos: LONGINT);
  VAR
     linenumber, posnumber : LONGINT;
  BEGIN
    IF pos = -1 THEN pos := 0 END;
    
    linenumber := pos DIV 256;
    posnumber := pos MOD 256;
(*
        Console.Ln; Console.String("-- linenumber "); Console.Int(linenumber, 0); Console.Ln;
	Console.String("-- posnumber "); Console.Int(posnumber, 0); Console.Ln;
*)
    IF useLineNo THEN
      IF n >= 0 THEN
        noerr := FALSE;
(*
        Console.String("n = "); Console.Int(n, 0); Console.Ln;
*)
        IF (pos < lasterrpos) OR (lasterrpos + 9 < pos) THEN lasterrpos := pos; LogWLn; LogWStr("  ");
          IF n < 249 THEN ShowLineErr(linenumber, posnumber); LogWStr("  line "); LogWNum(linenumber, 1);
            LogWStr("  pos "); LogWNum(posnumber, 1); LogErrMsg(n)
          ELSIF n = 255 THEN ShowLineErr(linenumber, posnumber); LogWStr("  line "); LogWNum(linenumber, 1);
            LogWStr("  pos "); LogWNum(posnumber, 1); LogWStr("  pc "); LogWNum(breakpc, 1)
          ELSIF n = 254 THEN LogWStr("pc not found")
          ELSE LogWStr(objname);
            IF n = 253 THEN LogWStr(" is new, compile with option e")
            ELSIF n = 252 THEN LogWStr(" is redefined, compile with option s")
            ELSIF n = 251 THEN LogWStr(" is redefined (private part only), compile with option s")
            ELSIF n = 250 THEN LogWStr(" is no longer visible, compile with option s")
            ELSIF n = 249 THEN LogWStr(" is not consistently imported, recompile imports")
            END
          END
        END
      ELSE
        ShowLineErr(linenumber, posnumber);
        IF pos >= 0 THEN LogWLn;
          LogWStr("  line "); LogWNum(pos DIV 256, 1); LogWStr("  pos "); LogWNum(pos MOD 256, 1)
        END ;
        LogErrMsg(n);
        IF pos < 0 THEN LogWLn END
      END
    ELSE
      IF n >= 0 THEN
        noerr := FALSE;
        IF (pos < lasterrpos) OR (lasterrpos + 9 < pos) THEN lasterrpos := pos; ShowLine(pos); LogWLn; LogWStr("  ");
          IF n < 249 THEN LogWStr("  pos"); LogWNum(pos, 6); LogErrMsg(n)
          ELSIF n = 255 THEN LogWStr("pos"); LogWNum(pos, 6); LogWStr("  pc "); LogWNum(breakpc, 1)
          ELSIF n = 254 THEN LogWStr("pc not found")
          ELSE LogWStr(objname);
            IF n = 253 THEN LogWStr(" is new, compile with option e")
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
    END
  END Mark;

  PROCEDURE err*(n: INTEGER);
  BEGIN 
    IF useLineNo & (errpos MOD 256 = 255) THEN (* line underflow from OPS.Get *)
      Mark(n, errpos + 1)
    ELSE
      Mark(n, errpos)
    END
  END err;

  PROCEDURE FPrint*(VAR fp: LONGINT; val: LONGINT);
  BEGIN
    fp := SYSTEM.ROT(SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, fp) / SYSTEM.VAL(SET, val)), 1)
  END FPrint;

  PROCEDURE FPrintSet*(VAR fp: LONGINT; set: SET);
  BEGIN FPrint(fp, SYSTEM.VAL(LONGINT, set))
  END FPrintSet;

  PROCEDURE FPrintReal*(VAR fp: LONGINT; real: REAL);
  BEGIN FPrint(fp, SYSTEM.VAL(LONGINT, real))
  END FPrintReal;

  PROCEDURE FPrintLReal*(VAR fp: LONGINT; lr: LONGREAL);
    VAR l, h: LONGINT;
  BEGIN
    SYSTEM.GET(SYSTEM.ADR(lr), l); SYSTEM.GET(SYSTEM.ADR(lr)+4, h);
    FPrint(fp, l); FPrint(fp, h)
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



  PROCEDURE minus(i: LONGINT): LONGINT;
  BEGIN
     RETURN -i;
  END minus;

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


  PROCEDURE GetProperties();
    VAR T: Texts.Text; S: Texts.Scanner;
    base : LONGINT;
  BEGIN
 
    (* default characteristics *)
  IF ~useParFile THEN
    IF version.defaultTarget = version.gnux8664 THEN
        Console.String (" GNU "); Console.String(version.arch); Console.String(" target"); Console.Ln;
        ByteSize := 1; CharSize := 1; BoolSize := 1; SIntSize := 1; IntSize := 4; LIntSize := 8;
       SetSize := 8; RealSize := 4; LRealSize := 8; ProcSize := 8; PointerSize := 8; RecSize := 1;
       CharAlign := 1; BoolAlign := 1; SIntAlign := 1; IntAlign := 4; LIntAlign := 8;
       SetAlign := 8; RealAlign := 4; LRealAlign := 8; ProcAlign := 8; PointerAlign := 8; RecAlign := 1;
    (*  not necessary, we will calculate values later  
       MinSInt := -80H; MaxSInt := 7FH;
       MinInt := 80000000H(*-2147483648*); 
       MaxInt := 7FFFFFFFH (*2147483647*); 
       (*MinLInt := -8000000000000000H*) (*-9223372036854775808*) ; (* -2^63 *) 
       (*MaxLInt := 7FFFFFFFFFFFFFFFH *)(*9223372036854775807*) ;(* 2^63-1 *)
       (*MaxSet := 31;*) 
       MaxSet := SetSize * 8 - 1; (*noch*)
     *)
    ELSIF (version.defaultTarget >= version.gnuarmv6j) & (version.defaultTarget <= version.gnuarmv7ahardfp) THEN
      Console.String (" GNU ");
      Console.String (version.arch); Console.String (" target"); Console.Ln;
       ByteSize := 1; CharSize := 1; BoolSize := 1; SIntSize := 1; IntSize := 2; LIntSize := 4;
       SetSize := 4; RealSize := 4; LRealSize := 8; ProcSize := 4; PointerSize := 4; RecSize := 1;
       CharAlign := 1; BoolAlign := 1; SIntAlign := 1; IntAlign := 2; LIntAlign := 4;
       SetAlign := 4; RealAlign := 4; LRealAlign := 8; ProcAlign := 4; PointerAlign := 4; RecAlign := 1;

     (* not necessary, we will calculate values later
       MinSInt := -80H; MinInt := -8000H; MinLInt :=  80000000H;  (*-2147483648*)
       MaxSInt := 7FH; MaxInt := 7FFFH; MaxLInt := 7FFFFFFFH;  (*2147483647*)
       MaxSet := SetSize * 8 -1; (* noch *)
      *)
    ELSIF (version.defaultTarget = version.gnupowerpc) THEN
      Console.String (" GNU ");
      Console.String (version.arch); Console.String (" target"); Console.Ln;
       ByteSize := 1; CharSize := 1; BoolSize := 1; SIntSize := 1; IntSize := 2; LIntSize := 4;
       SetSize := 4; RealSize := 4; LRealSize := 8; ProcSize := 4; PointerSize := 4; RecSize := 1;
       CharAlign := 1; BoolAlign := 1; SIntAlign := 1; IntAlign := 2; LIntAlign := 4;
       SetAlign := 4; RealAlign := 4; LRealAlign := 8; ProcAlign := 4; PointerAlign := 4; RecAlign := 1;


    ELSIF version.defaultTarget = version.gnux86 THEN
        Console.String("GNU "); Console.String(version.arch); Console.String(" target"); Console.Ln;
       ByteSize := 1; CharSize := 1; BoolSize := 1; SIntSize := 1; IntSize := 2; LIntSize := 4;
       SetSize := 4; RealSize := 4; LRealSize := 8; ProcSize := 4; PointerSize := 4; RecSize := 1;
       CharAlign := 1; BoolAlign := 1; SIntAlign := 1; IntAlign := 2; LIntAlign := 4;
       SetAlign := 4; RealAlign := 4; LRealAlign := 4; ProcAlign := 4; PointerAlign := 4; RecAlign := 1;

    ELSE (* this should suite any gnu x86 system *)
       Console.String (" generic target, like GNU x86 system"); Console.Ln;
       ByteSize := 1; CharSize := 1; BoolSize := 1; SIntSize := 1; IntSize := 2; LIntSize := 4;
       SetSize := 4; RealSize := 4; LRealSize := 8; ProcSize := 4; PointerSize := 4; RecSize := 1;
       CharAlign := 1; BoolAlign := 1; SIntAlign := 1; IntAlign := 2; LIntAlign := 4;
       SetAlign := 4; RealAlign := 4; LRealAlign := 4; ProcAlign := 4; PointerAlign := 4; RecAlign := 1;
(* LRealAlign should be checked and confirmed *)
    (* not necessary, will be calculated later 
       MinSInt := -80H; MinInt := -8000H; MinLInt :=  80000000H;  (*-2147483648*)
       MaxSInt := 7FH; MaxInt := 7FFFH; MaxLInt := 7FFFFFFFH;  (*2147483647*)
       MaxSet := SetSize * 8 - 1;
   *)

    END; (* if defaultTarget *)
  END; (* if ~useParFile *)
    (* read voc.par *)
    
    IF useParFile THEN (* noch *)
       Console.String ("loading type sizes from voc.par"); Console.Ln; 
       NEW(T); Texts.Open(T, "voc.par");
       IF T.len # 0 THEN
         Texts.OpenScanner(S, T, 0); Texts.Scan(S);
         GetProperty(S, "CHAR", CharSize, CharAlign);
         GetProperty(S, "BOOLEAN", BoolSize, BoolAlign);
         GetProperty(S, "SHORTINT", SIntSize, SIntAlign);
         GetProperty(S, "INTEGER", IntSize, IntAlign);
         GetProperty(S, "LONGINT", LIntSize, LIntAlign);
         GetProperty(S, "SET", SetSize, SetAlign);
         GetProperty(S, "REAL", RealSize, RealAlign);
         GetProperty(S, "LONGREAL", LRealSize, LRealAlign);
         GetProperty(S, "PTR", PointerSize, PointerAlign);
         GetProperty(S, "PROC", ProcSize, ProcAlign);
         GetProperty(S, "RECORD", RecSize, RecAlign);
         (* Size = 0: natural size aligned to next power of 2 up to RecAlign; e.g. i960
           Size = 1; size and alignment follows from field types but at least RecAlign; e.g, SPARC, MIPS, PowerPC
         *)
         GetProperty(S, "ENDIAN", ByteOrder, BitOrder);  (*currently not used*)
	 (* add here Max and Min sizes, noch *)
	 ByteSize := CharSize;
       ELSE Mark(-156, -1)
       END ;
    ELSE Console.String ("not using voc.par file"); Console.Ln;
    END; (* if useParFile , noch *)

(* commenting this by replacing with faster way; -- noch *
    MinSInt := power0(-2, (SIntSize*8-1)); (* -2^(SIntSize*8-1)*)
    (*MaxSInt := -(MinSint + 1);; may be optimized?*)
    MaxSInt := minus(MinSInt + 1);
    MinInt := power0(-2, (IntSize*8-1));
    MaxInt := minus(MinInt + 1);
     
    MinLInt := power0(-2, (LIntSize*8-1));
    MaxLInt := minus(MinLInt +1);
*)
    (* and I'd like to calculate it, not hardcode constants *)
    base := -2; 
    (* we can do
    MinLInt := ASH(-2, LIntSize*8-2);
    but some compilers may treat -2 as SHORTINT, not LONGINT; -- noch *)
    MinSInt := ASH(base, SIntSize*8-2);
    MaxSInt := minus(MinSInt + 1);

    MinInt := ASH(base, IntSize*8-2);
    MaxInt := minus(MinInt + 1);
    
    MinLInt := ASH(base, LIntSize*8-2);
    MaxLInt := minus(MinLInt +1);

(*
    Console.Int(MinSInt, 0); Console.Ln;
    Console.Int(MaxSInt, 0); Console.Ln;
    Console.Int(MinInt, 0); Console.Ln;
    Console.Int(MaxInt, 0); Console.Ln;
    Console.Int(MinLInt, 0); Console.Ln;
    Console.Int(MaxLInt, 0); Console.Ln;
*)


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
    (* commented this out,  *)
    (*IF IntSize = 4 THEN MinInt := MinLInt; MaxInt := MaxLInt END ;*)
    (*IF IntSize = 4 THEN MinLInt := MinInt; MaxLInt := MaxInt END ;*)
    MaxSet := SetSize * 8 - 1;
    MaxIndex := MaxLInt; (* shouldn't it be like max(int)? so that for loop will be safe, noch *)

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
  BEGIN MakeFileName(modName, fileName, SFext);
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
    IF i = MinLInt THEN Write("("); WriteInt(i+1); WriteString("-1)")  (* requires special bootstrap for 64 bit *)
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
    IF include0 IN opt THEN
      MakeFileName(moduleName, FName, ".h0"); Append(R[HeaderInclude], Files.Old(FName));
      MakeFileName(moduleName, FName, ".c0"); Append(R[BodyFile], Files.Old(FName))
    END
  END OpenFiles;

  PROCEDURE CloseFiles*;
    VAR FName: ARRAY 32 OF CHAR; res: INTEGER;
  BEGIN
    IF noerr THEN LogWStr("    "); LogWNum(Files.Pos(R[BodyFile]), 0) END ;
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
  
  PROCEDURE PromoteIntConstToLInt*();
  BEGIN
    (* ANSI C does not need explicit promotion.
      K&R C implicitly promotes integer constants to type int in parameter lists.
      if the formal parameter, however, is of type long, appending "L" is required in ordere to promote
      the parameter explicitly to type long (if LONGINT corresponds to long, which we do not really know).
      It works for all known K&R versions of voc and K&R is dying out anyway.
      A cleaner solution would be to cast with type (LONGINT), but this requires a bit more changes.
    *)
    IF ~(ansi IN opt) THEN Write("L") END
  END PromoteIntConstToLInt;

BEGIN Texts.OpenWriter(W)
END OPM.
