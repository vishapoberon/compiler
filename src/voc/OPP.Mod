MODULE OPP;  (* NW, RC 6.3.89 / 10.2.94 *)  (* object model 4.12.93 *)

  IMPORT
    OPB, OPT, OPS, OPM;
    
  CONST
    (* numtyp values *)
    char = 1; integer = 2; real = 3; longreal = 4;

    (* symbol values *)
    null = 0; times = 1; slash = 2; div = 3; mod = 4;
    and = 5; plus = 6; minus = 7; or = 8; eql = 9;
    neq = 10; lss = 11; leq = 12; gtr = 13; geq = 14;
    in = 15; is = 16; arrow = 17; period = 18; comma = 19;
    colon = 20; upto = 21; rparen = 22; rbrak = 23; rbrace = 24;
    of = 25; then = 26; do = 27; to = 28; by = 29;
    lparen = 30; lbrak = 31; lbrace = 32; not = 33; becomes = 34;
    number = 35; nil = 36; string = 37; ident = 38; semicolon = 39;
    bar = 40; end = 41; else = 42; elsif = 43; until = 44;
    if = 45; case = 46; while = 47; repeat = 48; for = 49;
    loop = 50; with = 51; exit = 52; return = 53; array = 54;
    record = 55; pointer = 56; begin = 57; const = 58; type = 59;
    var = 60; procedure = 61; import = 62; module = 63; eof = 64;

    (* object modes *)
    Var = 1; VarPar = 2; Con = 3; Fld = 4; Typ = 5; LProc = 6; XProc = 7;
    SProc = 8; CProc = 9; IProc = 10; Mod = 11; Head = 12; TProc = 13;

    (* Structure forms *)
    Undef = 0; Byte = 1; Bool = 2; Char = 3; SInt = 4; Int = 5; LInt = 6;
    Real = 7; LReal = 8; Set = 9; String = 10; NilTyp = 11; NoTyp = 12;
    Pointer = 13; ProcTyp = 14; Comp = 15;
    intSet = {SInt..LInt};
    
    (* composite structure forms *)
    Basic = 1; Array = 2; DynArr = 3; Record = 4;

    (*function number*)
    haltfn = 0; newfn = 1; incfn = 13; sysnewfn = 30;

    (* nodes classes *)
    Nvar = 0; Nvarpar = 1; Nfield = 2; Nderef = 3; Nindex = 4; Nguard = 5; Neguard = 6;
    Nconst = 7; Ntype = 8; Nproc = 9; Nupto = 10; Nmop = 11; Ndop = 12; Ncall = 13;
    Ninittd = 14; Nif = 15; Ncaselse = 16; Ncasedo = 17; Nenter = 18; Nassign = 19;
    Nifelse = 20; Ncase = 21; Nwhile = 22; Nrepeat = 23; Nloop = 24; Nexit = 25;
    Nreturn = 26; Nwith = 27; Ntrap = 28;

    (* node subclasses *)
    super = 1;
    
    (* module visibility of objects *)
    internal = 0; external = 1; externalR = 2;

    (* procedure flags (conval^.setval) *)
    hasBody = 1; isRedef = 2; slNeeded = 3;

  TYPE
    CaseTable = ARRAY OPM.MaxCases OF
      RECORD
        low, high: LONGINT
      END ;
    
  VAR
    sym, level: SHORTINT;
    LoopLevel: INTEGER;
    TDinit, lastTDinit: OPT.Node;
    nofFwdPtr: INTEGER;
    FwdPtr: ARRAY 64 OF OPT.Struct;

  PROCEDURE^ Type(VAR typ, banned: OPT.Struct);
  PROCEDURE^ Expression(VAR x: OPT.Node);
  PROCEDURE^ Block(VAR procdec, statseq: OPT.Node);

  PROCEDURE err(n: INTEGER);
  BEGIN OPM.err(n)
  END err;

  PROCEDURE CheckSym(s: INTEGER);
  BEGIN
    IF sym = s THEN OPS.Get(sym) ELSE OPM.err(s) END
  END CheckSym;

  PROCEDURE qualident(VAR id: OPT.Object);
    VAR obj: OPT.Object; lev: SHORTINT;
  BEGIN (*sym = ident*)
    OPT.Find(obj); OPS.Get(sym);
    IF (sym = period) & (obj # NIL) & (obj^.mode = Mod) THEN
      OPS.Get(sym);
      IF sym = ident THEN
        OPT.FindImport(obj, obj); OPS.Get(sym)
      ELSE err(ident); obj := NIL
      END
    END ;
    IF obj = NIL THEN err(0);
      obj := OPT.NewObj(); obj^.mode := Var; obj^.typ := OPT.undftyp; obj^.adr := 0
    ELSE lev := obj^.mnolev;
      IF (obj^.mode IN {Var, VarPar}) & (lev # level) THEN
        obj^.leaf := FALSE;
        IF lev > 0 THEN OPB.StaticLink(level-lev) END
      END
    END ;
    id := obj
  END qualident;

  PROCEDURE ConstExpression(VAR x: OPT.Node);
  BEGIN Expression(x);
    IF x^.class # Nconst THEN
      err(50); x := OPB.NewIntConst(1) 
    END
  END ConstExpression;

  PROCEDURE CheckMark(VAR vis: SHORTINT);
  BEGIN OPS.Get(sym);
    IF (sym = times) OR (sym = minus) THEN
      IF level > 0 THEN err(47) END ;
      IF sym = times THEN vis := external ELSE vis := externalR END ;
      OPS.Get(sym)
    ELSE vis := internal
    END
  END CheckMark;
  
  PROCEDURE CheckSysFlag(VAR sysflag: INTEGER; default: INTEGER);
    VAR x: OPT.Node; sf: LONGINT;
  BEGIN
    IF sym = lbrak THEN OPS.Get(sym); ConstExpression(x);
      IF x^.typ^.form IN intSet THEN sf := x^.conval^.intval;
        IF (sf < 0) OR (sf > OPM.MaxSysFlag) THEN err(220); sf := 0 END
      ELSE err(51); sf := 0
      END ;
      sysflag := SHORT(sf); CheckSym(rbrak)
    ELSE sysflag := default
    END
  END CheckSysFlag;

  PROCEDURE RecordType(VAR typ, banned: OPT.Struct);
    VAR fld, first, last, base: OPT.Object;
      ftyp: OPT.Struct; sysflag: INTEGER;
  BEGIN typ := OPT.NewStr(Comp, Record); typ^.BaseTyp := NIL;
    CheckSysFlag(sysflag, -1);
    IF sym = lparen THEN
      OPS.Get(sym); (*record extension*)
      IF sym = ident THEN
        qualident(base);
        IF (base^.mode = Typ) & (base^.typ^.comp = Record) THEN
          IF base^.typ = banned THEN err(58)
          ELSE base^.typ^.pvused := TRUE;
            typ^.BaseTyp := base^.typ; typ^.extlev := base^.typ^.extlev + 1; typ^.sysflag := base^.typ^.sysflag
          END
        ELSE err(52)
        END
      ELSE err(ident)
      END ;
      CheckSym(rparen)
    END ;
    IF sysflag >= 0 THEN typ^.sysflag := sysflag END ;
    OPT.OpenScope(0, NIL); first := NIL; last := NIL;
    LOOP
      IF sym = ident THEN
        LOOP
          IF sym = ident THEN
            IF typ^.BaseTyp # NIL THEN
              OPT.FindField(OPS.name, typ^.BaseTyp, fld);
              IF fld # NIL THEN err(1) END
            END ;
            OPT.Insert(OPS.name, fld); CheckMark(fld^.vis);
            fld^.mode := Fld; fld^.link := NIL; fld^.typ := OPT.undftyp;
            IF first = NIL THEN first := fld END ;
            IF last = NIL THEN typ^.link := fld ELSE last^.link := fld END ;
            last := fld
          ELSE err(ident)
          END ;
          IF sym = comma THEN OPS.Get(sym)
          ELSIF sym = ident THEN err(comma)
          ELSE EXIT
          END
        END ;
        CheckSym(colon); Type(ftyp, banned);
        ftyp^.pvused := TRUE;
        IF ftyp^.comp = DynArr THEN ftyp := OPT.undftyp; err(88) END ;
        WHILE first # NIL DO
          first^.typ := ftyp; first := first^.link
        END
      END ;
      IF sym = semicolon THEN OPS.Get(sym)
      ELSIF sym = ident THEN err(semicolon)
      ELSE EXIT
      END
    END ;
    OPT.CloseScope
  END RecordType;

  PROCEDURE ArrayType(VAR typ, banned: OPT.Struct);
    VAR x: OPT.Node; n: LONGINT; sysflag: INTEGER;
  BEGIN CheckSysFlag(sysflag, 0);
    IF sym = of THEN  (*dynamic array*)
      typ := OPT.NewStr(Comp, DynArr); typ^.mno := 0; typ^.sysflag := sysflag;
      OPS.Get(sym); Type(typ^.BaseTyp, banned);
      typ^.BaseTyp^.pvused := TRUE;
      IF typ^.BaseTyp^.comp = DynArr THEN typ^.n := typ^.BaseTyp^.n + 1
      ELSE typ^.n := 0
      END
    ELSE
      typ := OPT.NewStr(Comp, Array); typ^.sysflag := sysflag; ConstExpression(x);
      IF x^.typ^.form IN intSet THEN n := x^.conval^.intval;
        IF (n <= 0) OR (n > OPM.MaxIndex) THEN err(63); n := 1 END
      ELSE err(51); n := 1
      END ;
      typ^.n := n;
      IF sym = of THEN
        OPS.Get(sym); Type(typ^.BaseTyp, banned);
        typ^.BaseTyp^.pvused := TRUE
      ELSIF sym = comma THEN
        OPS.Get(sym); IF sym # of THEN ArrayType(typ^.BaseTyp, banned) END
      ELSE err(35)
      END ;
      IF typ^.BaseTyp^.comp = DynArr THEN typ^.BaseTyp := OPT.undftyp; err(88) END
    END
  END ArrayType;

  PROCEDURE PointerType(VAR typ: OPT.Struct);
    VAR id: OPT.Object;
  BEGIN typ := OPT.NewStr(Pointer, Basic); CheckSysFlag(typ^.sysflag, 0);
    CheckSym(to);
    IF sym = ident THEN OPT.Find(id);
      IF id = NIL THEN
        IF nofFwdPtr < LEN(FwdPtr) THEN FwdPtr[nofFwdPtr] := typ; INC(nofFwdPtr)
        ELSE err(224)
        END ;
        typ^.link := OPT.NewObj(); COPY(OPS.name, typ^.link^.name);
        typ^.BaseTyp := OPT.undftyp; OPS.Get(sym) (*forward ref*)
      ELSE qualident(id);
        IF id^.mode = Typ THEN
          IF id^.typ^.comp IN {Array, DynArr, Record} THEN
            typ^.BaseTyp := id^.typ
          ELSE typ^.BaseTyp := OPT.undftyp; err(57)
          END
        ELSE typ^.BaseTyp := OPT.undftyp; err(52)
        END
      END
    ELSE Type(typ^.BaseTyp, OPT.notyp);
      IF ~(typ^.BaseTyp^.comp IN {Array, DynArr, Record}) THEN
        typ^.BaseTyp := OPT.undftyp; err(57)
      END
    END
  END PointerType;
  
  PROCEDURE FormalParameters(VAR firstPar: OPT.Object; VAR resTyp: OPT.Struct);
    VAR mode: SHORTINT;
        par, first, last, res: OPT.Object; typ: OPT.Struct;
  BEGIN first := NIL; last := firstPar;
    IF (sym = ident) OR (sym = var) THEN
      LOOP
        IF sym = var THEN OPS.Get(sym); mode := VarPar ELSE mode := Var END ;
        LOOP
          IF sym = ident THEN
            OPT.Insert(OPS.name, par); OPS.Get(sym);
            par^.mode := mode; par^.link := NIL;
            IF first = NIL THEN first := par END ;
            IF firstPar = NIL THEN firstPar := par ELSE last^.link := par END ;
            last := par
          ELSE err(ident)
          END ;
          IF sym = comma THEN OPS.Get(sym)
          ELSIF sym = ident THEN err(comma)
          ELSIF sym = var THEN err(comma); OPS.Get(sym)
          ELSE EXIT
          END
        END ;
        CheckSym(colon); Type(typ, OPT.notyp);
        IF mode = Var THEN typ^.pvused := TRUE END ;
        (* typ^.pbused is set when parameter type name is parsed *)
        WHILE first # NIL DO first^.typ := typ; first := first^.link END ;
        IF sym = semicolon THEN OPS.Get(sym)
        ELSIF sym = ident THEN err(semicolon)
        ELSE EXIT
        END
      END
    END ;
    CheckSym(rparen);
    IF sym = colon THEN
      OPS.Get(sym); resTyp := OPT.undftyp;
      IF sym = ident THEN qualident(res);
        IF res^.mode = Typ THEN
          IF res^.typ^.form < Comp THEN resTyp := res^.typ
          ELSE err(54)
          END
        ELSE err(52)
        END
      ELSE err(ident)
      END
    ELSE resTyp := OPT.notyp
    END
  END FormalParameters;

  PROCEDURE TypeDecl(VAR typ, banned: OPT.Struct);
    VAR id: OPT.Object;
  BEGIN typ := OPT.undftyp;
    IF sym < lparen THEN err(12);
      REPEAT OPS.Get(sym) UNTIL sym >= lparen
    END ;
    IF sym = ident THEN qualident(id);
      IF id^.mode = Typ THEN
        IF id^.typ # banned THEN typ := id^.typ ELSE err(58) END
      ELSE err(52)
      END
    ELSIF sym = array THEN
      OPS.Get(sym); ArrayType(typ, banned)
    ELSIF sym = record THEN
      OPS.Get(sym); RecordType(typ, banned);
      OPB.Inittd(TDinit, lastTDinit, typ); CheckSym(end)
    ELSIF sym = pointer THEN
      OPS.Get(sym); PointerType(typ)
    ELSIF sym = procedure THEN
      OPS.Get(sym); typ := OPT.NewStr(ProcTyp, Basic); CheckSysFlag(typ^.sysflag, 0);
      IF sym = lparen THEN
        OPS.Get(sym); OPT.OpenScope(level, NIL);
        FormalParameters(typ^.link, typ^.BaseTyp); OPT.CloseScope
      ELSE typ^.BaseTyp := OPT.notyp; typ^.link := NIL
      END
    ELSE err(12)
    END ;
    LOOP
      IF (sym >= semicolon) & (sym <= else) OR (sym = rparen) OR (sym = eof) THEN EXIT END;
      err(15); IF sym = ident THEN EXIT END;
      OPS.Get(sym)
    END
  END TypeDecl;
  
  PROCEDURE Type(VAR typ, banned: OPT.Struct);
  BEGIN TypeDecl(typ, banned);
    IF (typ^.form = Pointer) & (typ^.BaseTyp = OPT.undftyp) & (typ^.strobj = NIL) THEN err(0) END
  END Type;

  PROCEDURE selector(VAR x: OPT.Node);
    VAR obj, proc: OPT.Object; y: OPT.Node; typ: OPT.Struct; name: OPS.Name;
  BEGIN
    LOOP
      IF sym = lbrak THEN OPS.Get(sym);
        LOOP
          IF (x^.typ # NIL) & (x^.typ^.form = Pointer) THEN OPB.DeRef(x) END ;
          Expression(y); OPB.Index(x, y);
          IF sym = comma THEN OPS.Get(sym) ELSE EXIT END
        END ;
        CheckSym(rbrak)
      ELSIF sym = period THEN OPS.Get(sym);
        IF sym = ident THEN name := OPS.name; OPS.Get(sym);
          IF x^.typ # NIL THEN
            IF x^.typ^.form = Pointer THEN OPB.DeRef(x) END ;
            IF x^.typ^.comp = Record THEN
              OPT.FindField(name, x^.typ, obj); OPB.Field(x, obj);
              IF (obj # NIL) & (obj^.mode = TProc) THEN
                IF sym = arrow THEN  (* super call *) OPS.Get(sym);
                  y := x^.left;
                  IF y^.class = Nderef THEN y := y^.left END ;  (* y = record variable *)
                  IF y^.obj # NIL THEN
                    proc := OPT.topScope;  (* find innermost scope which owner is a TProc *)
                    WHILE (proc^.link # NIL) & (proc^.link^.mode # TProc) DO proc := proc^.left END ;
                    IF (proc^.link = NIL) OR (proc^.link^.link # y^.obj) THEN err(75) END ;
                    typ := y^.obj^.typ;
                    IF typ^.form = Pointer THEN typ := typ^.BaseTyp END ;
                    OPT.FindField(x^.obj^.name, typ^.BaseTyp, proc);
                    IF proc # NIL THEN x^.subcl := super ELSE err(74) END
                  ELSE err(75)
                  END
                END ;
                IF (obj^.typ # OPT.notyp) & (sym # lparen) THEN err(lparen) END
              END
            ELSE err(53)
            END
          ELSE err(52)
          END
        ELSE err(ident)
        END
      ELSIF sym = arrow THEN OPS.Get(sym); OPB.DeRef(x)
      ELSIF (sym = lparen) & (x^.class < Nconst) & (x^.typ^.form # ProcTyp) &
          ((x^.obj = NIL) OR (x^.obj^.mode # TProc)) THEN
        OPS.Get(sym);
        IF sym = ident THEN
          qualident(obj);
          IF obj^.mode = Typ THEN OPB.TypTest(x, obj, TRUE)
          ELSE err(52)
          END
        ELSE err(ident)
        END ;
        CheckSym(rparen)
      ELSE EXIT
      END
    END
  END selector;

  PROCEDURE ActualParameters(VAR aparlist: OPT.Node; fpar: OPT.Object);
    VAR apar, last: OPT.Node;
  BEGIN aparlist := NIL; last := NIL;
    IF sym # rparen THEN
      LOOP Expression(apar);
        IF fpar # NIL THEN
          OPB.Param(apar, fpar); OPB.Link(aparlist, last, apar);
          fpar := fpar^.link;
        ELSE err(64)
        END ;
        IF sym = comma THEN OPS.Get(sym)
        ELSIF (lparen <= sym) & (sym <= ident) THEN err(comma)
        ELSE EXIT
        END
      END
    END ;
    IF fpar # NIL THEN err(65) END
  END ActualParameters;

  PROCEDURE StandProcCall(VAR x: OPT.Node);
    VAR y: OPT.Node; m: SHORTINT; n: INTEGER;
  BEGIN m := SHORT(SHORT(x^.obj^.adr)); n := 0;
    IF sym = lparen THEN OPS.Get(sym);
      IF sym # rparen THEN
        LOOP
          IF n = 0 THEN Expression(x); OPB.StPar0(x, m); n := 1
          ELSIF n = 1 THEN Expression(y); OPB.StPar1(x, y, m); n := 2
          ELSE Expression(y); OPB.StParN(x, y, m, n); INC(n)
          END ;
          IF sym = comma THEN OPS.Get(sym)
          ELSIF (lparen <= sym) & (sym <= ident) THEN err(comma)
          ELSE EXIT
          END
        END ;
        CheckSym(rparen)
      ELSE OPS.Get(sym)
      END ;
      OPB.StFct(x, m, n)
    ELSE err(lparen)
    END ;
    IF (level > 0) & ((m = newfn) OR (m = sysnewfn)) THEN OPT.topScope^.link^.leaf := FALSE END
  END StandProcCall;
  
  PROCEDURE Element(VAR x: OPT.Node);
    VAR y: OPT.Node;
  BEGIN Expression(x);
    IF sym = upto THEN
      OPS.Get(sym); Expression(y); OPB.SetRange(x, y)
    ELSE OPB.SetElem(x)
    END
  END Element;

  PROCEDURE Sets(VAR x: OPT.Node);
    VAR y: OPT.Node;
  BEGIN
    IF sym # rbrace THEN
      Element(x);
      LOOP
        IF sym = comma THEN OPS.Get(sym)
        ELSIF (lparen <= sym) & (sym <= ident) THEN err(comma)
        ELSE EXIT
        END ;
        Element(y); OPB.Op(plus, x, y)
      END
    ELSE x := OPB.EmptySet()
    END ;
    CheckSym(rbrace)
  END Sets;
  
  PROCEDURE Factor(VAR x: OPT.Node);
    VAR fpar, id: OPT.Object; apar: OPT.Node;
  BEGIN
    IF sym < lparen THEN err(13);
      REPEAT OPS.Get(sym) UNTIL sym >= lparen
    END ;
    IF sym = ident THEN
      qualident(id); x := OPB.NewLeaf(id); selector(x);
      IF (x^.class = Nproc) & (x^.obj^.mode = SProc) THEN StandProcCall(x)  (* x may be NIL *)
      ELSIF sym = lparen THEN
        OPS.Get(sym); OPB.PrepCall(x, fpar);
        ActualParameters(apar, fpar);
        OPB.Call(x, apar, fpar);
        CheckSym(rparen);
        IF level > 0 THEN OPT.topScope^.link^.leaf := FALSE END
      END
    ELSIF sym = number THEN
      CASE OPS.numtyp OF
         char: x := OPB.NewIntConst(OPS.intval); x^.typ := OPT.chartyp
      | integer: x := OPB.NewIntConst(OPS.intval)
      | real: x := OPB.NewRealConst(OPS.realval, OPT.realtyp)
      | longreal: x := OPB.NewRealConst(OPS.lrlval, OPT.lrltyp)
      END ;
      OPS.Get(sym)
    ELSIF sym = string THEN
      x := OPB.NewString(OPS.str, OPS.intval); OPS.Get(sym)
    ELSIF sym = nil THEN
      x := OPB.Nil(); OPS.Get(sym)
    ELSIF sym = lparen THEN
      OPS.Get(sym); Expression(x); CheckSym(rparen)
    ELSIF sym = lbrak THEN
      OPS.Get(sym); err(lparen); Expression(x); CheckSym(rparen)
    ELSIF sym = lbrace THEN OPS.Get(sym); Sets(x)
    ELSIF sym = not THEN
      OPS.Get(sym); Factor(x); OPB.MOp(not, x)
    ELSE err(13); OPS.Get(sym); x := NIL
    END ;
    IF x = NIL THEN x := OPB.NewIntConst(1); x^.typ := OPT.undftyp END
  END Factor;

  PROCEDURE Term(VAR x: OPT.Node);
    VAR y: OPT.Node; mulop: SHORTINT;
  BEGIN Factor(x);
    WHILE (times <= sym) & (sym <= and) DO
      mulop := sym; OPS.Get(sym);
      Factor(y); OPB.Op(mulop, x, y)
    END
  END Term;

  PROCEDURE SimpleExpression(VAR x: OPT.Node);
    VAR y: OPT.Node; addop: SHORTINT;
  BEGIN
    IF sym = minus THEN OPS.Get(sym); Term(x); OPB.MOp(minus, x)
    ELSIF sym = plus THEN OPS.Get(sym); Term(x); OPB.MOp(plus, x)
    ELSE Term(x)
    END ;
    WHILE (plus <= sym) & (sym <= or) DO
      addop := sym; OPS.Get(sym);
      Term(y); OPB.Op(addop, x, y)
    END
  END SimpleExpression;

  PROCEDURE Expression(VAR x: OPT.Node);
    VAR y: OPT.Node; obj: OPT.Object; relation: SHORTINT;
  BEGIN SimpleExpression(x);
    IF (eql <= sym) & (sym <= geq) THEN
      relation := sym; OPS.Get(sym);
      SimpleExpression(y); OPB.Op(relation, x, y)
    ELSIF sym = in THEN
      OPS.Get(sym); SimpleExpression(y); OPB.In(x, y)
    ELSIF sym = is THEN
      OPS.Get(sym);
      IF sym = ident THEN
        qualident(obj);
        IF obj^.mode = Typ THEN OPB.TypTest(x, obj, FALSE)
        ELSE err(52)
        END
      ELSE err(ident)
      END
    END
  END Expression;

  PROCEDURE Receiver(VAR mode: SHORTINT; VAR name: OPS.Name; VAR typ, rec: OPT.Struct);
    VAR obj: OPT.Object;
  BEGIN typ := OPT.undftyp; rec := NIL;
    IF sym = var THEN OPS.Get(sym); mode := VarPar ELSE mode := Var END ;
    name := OPS.name; CheckSym(ident); CheckSym(colon);
    IF sym = ident THEN OPT.Find(obj); OPS.Get(sym);
      IF obj = NIL THEN err(0)
      ELSIF obj^.mode # Typ THEN err(72)
      ELSE typ := obj^.typ; rec := typ;
        IF rec^.form = Pointer THEN rec := rec^.BaseTyp END ;
        IF ~((mode = Var) & (typ^.form = Pointer) & (rec^.comp = Record) OR
          (mode = VarPar) & (typ^.comp = Record)) THEN err(70); rec := NIL END ;
        IF (rec # NIL) & (rec^.mno # level) THEN err(72); rec := NIL END
      END
    ELSE err(ident)
    END ;
    CheckSym(rparen);
    IF rec = NIL THEN rec := OPT.NewStr(Comp, Record); rec^.BaseTyp := NIL END
  END Receiver;
  
  PROCEDURE Extends(x, b: OPT.Struct): BOOLEAN;
  BEGIN
    IF (b^.form = Pointer) & (x^.form = Pointer) THEN b := b^.BaseTyp; x := x^.BaseTyp END ;
    IF (b^.comp = Record) & (x^.comp = Record) THEN
      REPEAT x := x^.BaseTyp UNTIL (x = NIL) OR (x = b)
    END ;
    RETURN x = b
  END Extends;

  PROCEDURE ProcedureDeclaration(VAR x: OPT.Node);
    VAR proc, fwd: OPT.Object;
      name: OPS.Name;
      mode, vis: SHORTINT;
      forward: BOOLEAN;

    PROCEDURE GetCode;
      VAR ext: OPT.ConstExt; n: INTEGER; c: LONGINT;
    BEGIN
      ext := OPT.NewExt(); proc^.conval^.ext := ext; n := 0;
      IF sym = string THEN
        WHILE OPS.str[n] # 0X DO ext[n+1] := OPS.str[n]; INC(n) END ;
        ext^[0] := CHR(n); OPS.Get(sym)
      ELSE
        LOOP
          IF sym = number THEN c := OPS.intval; INC(n);
            IF (c < 0) OR (c > 255) OR (n = OPT.MaxConstLen) THEN
              err(64); c := 1; n := 1
            END ;
            OPS.Get(sym); ext^[n] := CHR(c)
          END ;
          IF sym = comma THEN OPS.Get(sym)
          ELSIF sym = number THEN err(comma)
          ELSE ext^[0] := CHR(n); EXIT
          END
        END
      END ;
      INCL(proc^.conval^.setval, hasBody)
    END GetCode;

    PROCEDURE GetParams;
    BEGIN
      proc^.vis := vis; proc^.mode := mode; proc^.typ := OPT.notyp;
      proc^.conval := OPT.NewConst(); proc^.conval^.setval := {};
      IF sym = lparen THEN
        OPS.Get(sym); FormalParameters(proc^.link, proc^.typ)
      END ;
      IF fwd # NIL THEN
        OPB.CheckParameters(proc^.link, fwd^.link, TRUE);
        IF proc^.typ # fwd^.typ THEN err(117) END ;
        proc := fwd; OPT.topScope := proc^.scope;
        IF mode = IProc THEN proc^.mode := IProc END
      END
    END GetParams;

    PROCEDURE Body;
      VAR procdec, statseq: OPT.Node; c: LONGINT;
    BEGIN
      c := OPM.errpos;
      INCL(proc^.conval^.setval, hasBody);
      CheckSym(semicolon); Block(procdec, statseq);
      OPB.Enter(procdec, statseq, proc); x := procdec;
      x^.conval := OPT.NewConst(); x^.conval^.intval := c;
      IF sym = ident THEN
        IF OPS.name # proc^.name THEN err(4) END ;
        OPS.Get(sym)
      ELSE err(ident)
      END
    END Body;

    PROCEDURE TProcDecl;
      VAR baseProc: OPT.Object;
        objTyp, recTyp: OPT.Struct;
        objMode: SHORTINT;
        objName: OPS.Name;
    BEGIN
      OPS.Get(sym); mode := TProc;
      IF level > 0 THEN err(73) END ;
      Receiver(objMode, objName, objTyp, recTyp);
      IF sym = ident THEN
        name := OPS.name; CheckMark(vis);
        OPT.FindField(name, recTyp, fwd);
        OPT.FindField(name, recTyp^.BaseTyp, baseProc);
        IF (baseProc # NIL) & (baseProc^.mode # TProc) THEN baseProc := NIL END ;
        IF fwd = baseProc THEN fwd := NIL END ;
        IF (fwd # NIL) & (fwd^.mnolev # level) THEN fwd := NIL END ;
        IF (fwd # NIL) & (fwd^.mode = TProc) & ~(hasBody IN fwd^.conval^.setval) THEN
          (* there exists a corresponding forward declaration *)
          proc := OPT.NewObj(); proc^.leaf := TRUE;
          IF fwd^.vis # vis THEN err(118) END
        ELSE
          IF fwd # NIL THEN err(1); fwd := NIL END ;
          OPT.OpenScope(0, NIL); OPT.topScope^.right := recTyp^.link; OPT.Insert(name, proc);
          recTyp^.link := OPT.topScope^.right; OPT.CloseScope; 
        END ;
        INC(level); OPT.OpenScope(level, proc);
        OPT.Insert(objName, proc^.link); proc^.link^.mode := objMode; proc^.link^.typ := objTyp;
        GetParams;
        IF baseProc # NIL THEN
          IF (objMode # baseProc^.link^.mode) OR ~Extends(objTyp, baseProc^.link^.typ) THEN err(115) END ;
          OPB.CheckParameters(proc^.link^.link, baseProc^.link^.link, FALSE);
          IF proc^.typ # baseProc^.typ THEN err(117) END ;
          IF (baseProc^.vis = external) & (proc^.vis = internal) &
            (recTyp^.strobj # NIL) & (recTyp^.strobj^.vis = external) THEN err(109)
          END ;
          INCL(proc^.conval^.setval, isRedef)
        END ;
        IF ~forward THEN Body END ;
        DEC(level); OPT.CloseScope
      ELSE err(ident)
      END
    END TProcDecl;
  
  BEGIN proc := NIL; forward := FALSE; x := NIL; mode := LProc;
    IF (sym # ident) & (sym # lparen) THEN
      IF sym = times THEN  (* mode set later in OPB.CheckAssign *)
      ELSIF sym = arrow THEN forward := TRUE
      ELSIF sym = plus THEN mode := IProc
      ELSIF sym = minus THEN mode := CProc
      ELSE err(ident)
      END ;
      IF (mode IN {IProc, CProc}) & ~OPT.SYSimported THEN err(135) END ;
      OPS.Get(sym)
    END ;
    IF sym = lparen THEN TProcDecl
    ELSIF sym = ident THEN OPT.Find(fwd);
      name := OPS.name; CheckMark(vis);
      IF (vis # internal) & (mode = LProc) THEN mode := XProc END ;
      IF (fwd # NIL) & ((fwd^.mnolev # level) OR (fwd^.mode = SProc)) THEN fwd := NIL END ;
      IF (fwd # NIL) & (fwd^.mode IN {LProc, XProc}) & ~(hasBody IN fwd^.conval^.setval) THEN
        (* there exists a corresponding forward declaration *)
        proc := OPT.NewObj(); proc^.leaf := TRUE;
        IF fwd^.vis # vis THEN err(118) END
      ELSE
        IF fwd # NIL THEN err(1); fwd := NIL END ;
        OPT.Insert(name, proc)
      END ;
      IF (mode # LProc) & (level > 0) THEN err(73) END ;
      INC(level); OPT.OpenScope(level, proc);
      proc^.link := NIL; GetParams;
      IF mode = CProc THEN GetCode
      ELSIF ~forward THEN Body
      END ;
      DEC(level); OPT.CloseScope
    ELSE err(ident)
    END
  END ProcedureDeclaration;

  PROCEDURE CaseLabelList(VAR lab: OPT.Node; LabelForm: INTEGER; VAR n: INTEGER; VAR tab: CaseTable);
    VAR x, y, lastlab: OPT.Node; i, f: INTEGER; xval, yval: LONGINT;
  BEGIN lab := NIL; lastlab := NIL;
    LOOP ConstExpression(x); f := x^.typ^.form;
      IF f IN intSet + {Char} THEN  xval := x^.conval^.intval
      ELSE err(61); xval := 1
      END ;
      IF f IN intSet THEN
        IF LabelForm < f THEN err(60) END
      ELSIF LabelForm # f THEN err(60)
      END ;
      IF sym = upto THEN
        OPS.Get(sym); ConstExpression(y); yval := y^.conval^.intval;
        IF (y^.typ^.form # f) & ~((f IN intSet) & (y^.typ^.form IN intSet)) THEN err(60) END ;
        IF yval < xval THEN err(63); yval := xval END
      ELSE yval := xval
      END ;
      x^.conval^.intval2 := yval;
      (*enter label range into ordered table*)  i := n;
      IF i < OPM.MaxCases THEN
        LOOP
          IF i = 0 THEN EXIT END ;
          IF tab[i-1].low <= yval THEN
            IF tab[i-1].high >= xval THEN err(62) END ;
            EXIT
          END ;
          tab[i] := tab[i-1]; DEC(i)
        END ;
        tab[i].low := xval; tab[i].high := yval; INC(n)
      ELSE err(213)
      END ;
      OPB.Link(lab, lastlab, x);
      IF sym = comma THEN OPS.Get(sym)
      ELSIF (sym = number) OR (sym = ident) THEN err(comma)
      ELSE EXIT
      END
    END
  END CaseLabelList;

  PROCEDURE StatSeq(VAR stat: OPT.Node);
    VAR fpar, id, t, obj: OPT.Object; idtyp: OPT.Struct; e: BOOLEAN;
        s, x, y, z, apar, last, lastif: OPT.Node; pos: LONGINT; name: OPS.Name;

    PROCEDURE CasePart(VAR x: OPT.Node);
      VAR n: INTEGER; low, high: LONGINT; e: BOOLEAN;
          tab: CaseTable; cases, lab, y, lastcase: OPT.Node; 
    BEGIN
      Expression(x); pos := OPM.errpos;
      IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
      ELSIF ~(x^.typ^.form IN {Char..LInt}) THEN err(125)
      END ;
      CheckSym(of); cases := NIL; lastcase := NIL; n := 0;
      LOOP
        IF sym < bar THEN
          CaseLabelList(lab, x^.typ^.form, n, tab);
          CheckSym(colon); StatSeq(y);
          OPB.Construct(Ncasedo, lab, y); OPB.Link(cases, lastcase, lab)
        END ;
        IF sym = bar THEN OPS.Get(sym) ELSE EXIT END
      END ;
      IF n > 0 THEN low := tab[0].low; high := tab[n-1].high;
        IF high - low > OPM.MaxCaseRange THEN err(209) END
      ELSE low := 1; high := 0
      END ;
      e := sym = else;
      IF e THEN OPS.Get(sym); StatSeq(y) ELSE y := NIL END ;
      OPB.Construct(Ncaselse, cases, y); OPB.Construct(Ncase, x, cases);
      cases^.conval := OPT.NewConst();
      cases^.conval^.intval := low; cases^.conval^.intval2 := high;
      IF e THEN cases^.conval^.setval := {1} ELSE cases^.conval^.setval := {} END
    END CasePart;
    
    PROCEDURE SetPos(x: OPT.Node);
    BEGIN
      x^.conval := OPT.NewConst(); x^.conval^.intval := pos
    END SetPos;

    PROCEDURE CheckBool(VAR x: OPT.Node);
    BEGIN
      IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126); x := OPB.NewBoolConst(FALSE)
      ELSIF x^.typ^.form # Bool THEN err(120); x := OPB.NewBoolConst(FALSE)
      END ;
      pos := OPM.errpos
    END CheckBool;

  BEGIN stat := NIL; last := NIL;
    LOOP x := NIL;
      IF sym < ident THEN err(14);
        REPEAT OPS.Get(sym) UNTIL sym >= ident
      END ;
      IF sym = ident THEN
        qualident(id); x := OPB.NewLeaf(id); selector(x);
        IF sym = becomes THEN
          OPS.Get(sym); Expression(y); OPB.Assign(x, y)
        ELSIF sym = eql THEN
          err(becomes); OPS.Get(sym); Expression(y); OPB.Assign(x, y)
        ELSIF (x^.class = Nproc) & (x^.obj^.mode = SProc) THEN
          StandProcCall(x);
          IF (x # NIL) & (x^.typ # OPT.notyp) THEN err(55) END
        ELSE OPB.PrepCall(x, fpar);
          IF sym = lparen THEN
            OPS.Get(sym); ActualParameters(apar, fpar); CheckSym(rparen)
          ELSE apar := NIL;
            IF fpar # NIL THEN err(65) END
          END ;
          OPB.Call(x, apar, fpar);
          IF x^.typ # OPT.notyp THEN err(55) END ;
          IF level > 0 THEN OPT.topScope^.link^.leaf := FALSE END
        END ;
        pos := OPM.errpos
      ELSIF sym = if THEN
        OPS.Get(sym); Expression(x); CheckBool(x); CheckSym(then); StatSeq(y);
        OPB.Construct(Nif, x, y); SetPos(x); lastif := x;
        WHILE sym = elsif DO
          OPS.Get(sym); Expression(y); CheckBool(y); CheckSym(then); StatSeq(z);
          OPB.Construct(Nif, y, z); SetPos(y); OPB.Link(x, lastif, y)
        END ;
        IF sym = else THEN OPS.Get(sym); StatSeq(y) ELSE y := NIL END ;
        OPB.Construct(Nifelse, x, y); CheckSym(end); OPB.OptIf(x); pos := OPM.errpos
      ELSIF sym = case THEN
        OPS.Get(sym); CasePart(x); CheckSym(end)
      ELSIF sym = while THEN
        OPS.Get(sym); Expression(x); CheckBool(x); CheckSym(do); StatSeq(y);
        OPB.Construct(Nwhile, x, y); CheckSym(end)
      ELSIF sym = repeat THEN
        OPS.Get(sym); StatSeq(x);
        IF sym = until THEN OPS.Get(sym); Expression(y); CheckBool(y)
        ELSE err(until)
        END ;
        OPB.Construct(Nrepeat, x, y)
      ELSIF sym = for THEN
        OPS.Get(sym);
        IF sym = ident THEN qualident(id);
          IF ~(id^.typ^.form IN intSet) THEN err(68) END ;
          CheckSym(becomes); Expression(y); pos := OPM.errpos;
          x := OPB.NewLeaf(id); OPB.Assign(x, y); SetPos(x);
          CheckSym(to); Expression(y); pos := OPM.errpos;
          IF y^.class # Nconst THEN
            name := "@@"; OPT.Insert(name, t); t^.name := "@for";  (* avoid err 1 *)
            t^.mode := Var; t^.typ := x^.left^.typ;
            obj := OPT.topScope^.scope;
            IF obj = NIL THEN OPT.topScope^.scope := t
            ELSE
              WHILE obj^.link # NIL DO obj := obj^.link END ;
              obj^.link := t
            END ;
            z := OPB.NewLeaf(t); OPB.Assign(z, y); SetPos(z); OPB.Link(stat, last, z);
            y := OPB.NewLeaf(t)
          ELSIF (y^.typ^.form < SInt) OR (y^.typ^.form > x^.left^.typ^.form) THEN err(113)
          END ;
          OPB.Link(stat, last, x);
          IF sym = by THEN OPS.Get(sym); ConstExpression(z) ELSE z := OPB.NewIntConst(1) END ;
          pos := OPM.errpos; x := OPB.NewLeaf(id);
          IF z^.conval^.intval > 0 THEN OPB.Op(leq, x, y)
          ELSIF z^.conval^.intval < 0 THEN OPB.Op(geq, x, y)
          ELSE err(63); OPB.Op(geq, x, y)
          END ;
          CheckSym(do); StatSeq(s);
          y := OPB.NewLeaf(id); OPB.StPar1(y, z, incfn); SetPos(y);
          IF s = NIL THEN s := y
          ELSE z := s;
            WHILE z^.link # NIL DO z := z^.link END ;
            z^.link := y
          END ;
          CheckSym(end); OPB.Construct(Nwhile, x, s)
        ELSE err(ident)
        END
      ELSIF sym = loop THEN
        OPS.Get(sym); INC(LoopLevel); StatSeq(x); DEC(LoopLevel);
        OPB.Construct(Nloop, x, NIL); CheckSym(end); pos := OPM.errpos
      ELSIF sym = with THEN
        OPS.Get(sym); idtyp := NIL; x := NIL;
        LOOP
          IF sym = ident THEN
            qualident(id); y := OPB.NewLeaf(id);
            IF (id # NIL) & (id^.typ^.form = Pointer) & ((id^.mode = VarPar) OR ~id^.leaf) THEN
              err(245)  (* jt: do not allow WITH on non-local pointers *)
            END ;
            CheckSym(colon);
            IF sym = ident THEN qualident(t);
              IF t^.mode = Typ THEN
                IF id # NIL THEN
                  idtyp := id^.typ; OPB.TypTest(y, t, FALSE); id^.typ := t^.typ
                ELSE err(130)
                END
              ELSE err(52)
              END
            ELSE err(ident)
            END
          ELSE err(ident)
          END ;
          pos := OPM.errpos; CheckSym(do); StatSeq(s); OPB.Construct(Nif, y, s); SetPos(y);
          IF idtyp # NIL THEN id^.typ := idtyp; idtyp := NIL END ;
          IF x = NIL THEN x := y; lastif := x ELSE OPB.Link(x, lastif, y) END ;
          IF sym = bar THEN OPS.Get(sym) ELSE EXIT END
        END;
        e := sym = else;
        IF e THEN OPS.Get(sym); StatSeq(s) ELSE s := NIL END ;
        OPB.Construct(Nwith, x, s); CheckSym(end);
        IF e THEN x^.subcl := 1 END
      ELSIF sym = exit THEN
        OPS.Get(sym);
        IF LoopLevel = 0 THEN err(46) END ;
        OPB.Construct(Nexit, x, NIL);
        pos := OPM.errpos
      ELSIF sym = return THEN OPS.Get(sym);
        IF sym < semicolon THEN Expression(x) END ;
        IF level > 0 THEN OPB.Return(x, OPT.topScope^.link)
        ELSE (* not standard Oberon *) OPB.Return(x, NIL)
        END ;
        pos := OPM.errpos
      END ;
      IF x # NIL THEN SetPos(x); OPB.Link(stat, last, x) END ;
      IF sym = semicolon THEN OPS.Get(sym)
      ELSIF (sym <= ident) OR (if <= sym) & (sym <= return) THEN err(semicolon)
      ELSE EXIT
      END
    END
  END StatSeq;

  PROCEDURE Block(VAR procdec, statseq: OPT.Node);
    VAR typ: OPT.Struct;
      obj, first, last: OPT.Object;
      x, lastdec: OPT.Node;
      i: INTEGER;

  BEGIN first := NIL; last := NIL; nofFwdPtr := 0;
    LOOP
      IF sym = const THEN
        OPS.Get(sym);
        WHILE sym = ident DO
          OPT.Insert(OPS.name, obj); CheckMark(obj^.vis);
          obj^.typ := OPT.sinttyp; obj^.mode := Var;  (* Var to avoid recursive definition *)
          IF sym = eql THEN
            OPS.Get(sym); ConstExpression(x)
          ELSIF sym = becomes THEN
            err(eql); OPS.Get(sym); ConstExpression(x)
          ELSE err(eql); x := OPB.NewIntConst(1)
          END ;
          obj^.mode := Con; obj^.typ := x^.typ; obj^.conval := x^.conval; (* ConstDesc ist not copied *)
          CheckSym(semicolon)
        END
      END ;
      IF sym = type THEN
        OPS.Get(sym);
        WHILE sym = ident DO
          OPT.Insert(OPS.name, obj); obj^.mode := Typ; obj^.typ := OPT.undftyp;
          CheckMark(obj^.vis);
          IF sym = eql THEN
            OPS.Get(sym); TypeDecl(obj^.typ, obj^.typ)
          ELSIF (sym = becomes) OR (sym = colon) THEN
            err(eql); OPS.Get(sym); TypeDecl(obj^.typ, obj^.typ)
          ELSE err(eql)
          END ;
          IF obj^.typ^.strobj = NIL THEN obj^.typ^.strobj := obj END ;
          IF obj^.typ^.comp IN {Record, Array, DynArr} THEN
            i := 0;
            WHILE i < nofFwdPtr DO typ := FwdPtr[i]; INC(i);
              IF typ^.link^.name = obj^.name THEN typ^.BaseTyp := obj^.typ; typ^.link^.name := "" END
            END
          END ;
          CheckSym(semicolon)
        END
      END ;
      IF sym = var THEN
        OPS.Get(sym);
        WHILE sym = ident DO
          LOOP
            IF sym = ident THEN
              OPT.Insert(OPS.name, obj); CheckMark(obj^.vis);
              obj^.mode := Var; obj^.link := NIL; obj^.leaf := obj^.vis = internal; obj^.typ := OPT.undftyp;
              IF first = NIL THEN first := obj END ;
              IF last = NIL THEN OPT.topScope^.scope := obj ELSE last^.link := obj END ;
              last := obj
            ELSE err(ident)
            END ;
            IF sym = comma THEN OPS.Get(sym)
            ELSIF sym = ident THEN err(comma)
            ELSE EXIT
            END
          END ;
          CheckSym(colon); Type(typ, OPT.notyp);
          typ^.pvused := TRUE;
          IF typ^.comp = DynArr THEN typ := OPT.undftyp; err(88) END ;
          WHILE first # NIL DO first^.typ := typ; first := first^.link END ;
          CheckSym(semicolon)
        END
      END ;
      IF (sym < const) OR (sym > var) THEN EXIT END ;
    END ;
    i := 0;
    WHILE i < nofFwdPtr DO
      IF FwdPtr[i]^.link^.name # "" THEN err(128) END ;
      FwdPtr[i] := NIL;  (* garbage collection *)
      INC(i)
    END ;
    OPT.topScope^.adr := OPM.errpos;
    procdec := NIL; lastdec := NIL;
    WHILE sym = procedure DO
      OPS.Get(sym); ProcedureDeclaration(x);
      IF x # NIL THEN
        IF lastdec = NIL THEN procdec := x ELSE lastdec^.link := x END ;
        lastdec := x
      END ;
      CheckSym(semicolon)
    END ;
    IF sym = begin THEN OPS.Get(sym); StatSeq(statseq)
    ELSE statseq := NIL
    END ;
    IF (level = 0) & (TDinit # NIL) THEN
      lastTDinit^.link := statseq; statseq := TDinit
    END ;
    CheckSym(end)
  END Block;

  PROCEDURE Module*(VAR prog: OPT.Node; opt: SET);
    VAR impName, aliasName: OPS.Name;
        procdec, statseq: OPT.Node;
        c: LONGINT; done: BOOLEAN;
  BEGIN
    OPS.Init; LoopLevel := 0; level := 0; OPS.Get(sym);
    IF sym = module THEN OPS.Get(sym) ELSE err(16) END ;
    IF sym = ident THEN
      OPM.LogW(" "); OPM.LogWStr(OPS.name);
      OPT.Init(OPS.name, opt); OPS.Get(sym); CheckSym(semicolon);
      IF sym = import THEN OPS.Get(sym);
        LOOP
          IF sym = ident THEN
            COPY(OPS.name, aliasName); COPY(aliasName, impName); OPS.Get(sym);
            IF sym = becomes THEN OPS.Get(sym);
              IF sym = ident THEN COPY(OPS.name, impName); OPS.Get(sym) ELSE err(ident) END
            END ;
            OPT.Import(aliasName, impName, done)
          ELSE err(ident)
          END ;
          IF sym = comma THEN OPS.Get(sym)
          ELSIF sym = ident THEN err(comma)
          ELSE EXIT
          END
        END ;
        CheckSym(semicolon)
      END ;
      IF OPM.noerr THEN TDinit := NIL; lastTDinit := NIL; c := OPM.errpos;
        Block(procdec, statseq); OPB.Enter(procdec, statseq, NIL); prog := procdec;
        prog^.conval := OPT.NewConst(); prog^.conval^.intval := c;
        IF sym = ident THEN
          IF OPS.name # OPT.SelfName THEN err(4) END ;
          OPS.Get(sym)
        ELSE err(ident)
        END ;
        IF sym # period THEN err(period) END
      END
    ELSE err(ident)
    END ;
    TDinit := NIL; lastTDinit := NIL
  END Module;

END OPP.
