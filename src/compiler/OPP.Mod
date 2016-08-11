MODULE OPP;  (* NW, RC 6.3.89 / 10.2.94 *)  (* object model 4.12.93 *)

  IMPORT
    OPB, OPT, OPS, OPM;

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
  BEGIN (*sym = OPM.ident*)
    OPT.Find(obj); OPS.Get(sym);
    IF (sym = OPM.period) & (obj # NIL) & (obj^.mode = OPM.Mod) THEN
      OPS.Get(sym);
      IF sym = OPM.ident THEN
        OPT.FindImport(obj, obj); OPS.Get(sym)
      ELSE err(OPM.ident); obj := NIL
      END
    END ;
    IF obj = NIL THEN err(0);
      obj := OPT.NewObj(); obj^.mode := OPM.Var; obj^.typ := OPT.undftyp; obj^.adr := 0
    ELSE lev := obj^.mnolev;
      IF (obj^.mode IN {OPM.Var, OPM.VarPar}) & (lev # level) THEN
        obj^.leaf := FALSE;
        IF lev > 0 THEN OPB.StaticLink(level-lev) END
      END
    END ;
    id := obj
  END qualident;

  PROCEDURE ConstExpression(VAR x: OPT.Node);
  BEGIN Expression(x);
    IF x^.class # OPM.Nconst THEN
      err(50); x := OPB.NewIntConst(1)
    END
  END ConstExpression;

  PROCEDURE CheckMark(VAR vis: SHORTINT);
  BEGIN OPS.Get(sym);
    IF (sym = OPM.times) OR (sym = OPM.minus) THEN
      IF level > 0 THEN err(47) END ;
      IF sym = OPM.times THEN vis := OPM.external ELSE vis := OPM.externalR END ;
      OPS.Get(sym)
    ELSE vis := OPM.internal
    END
  END CheckMark;

  PROCEDURE CheckSysFlag(VAR sysflag: INTEGER; default: INTEGER);
    VAR x: OPT.Node; sf: LONGINT;
  BEGIN
    IF sym = OPM.lbrak THEN OPS.Get(sym);
	  IF ~OPT.SYSimported THEN err(135) END;
	  ConstExpression(x);
      IF x^.typ^.form IN OPM.intSet THEN sf := x^.conval^.intval;
        IF (sf < 0) OR (sf > OPM.MaxSysFlag) THEN err(220); sf := 0 END
      ELSE err(51); sf := 0
      END ;
      sysflag := SHORT(sf); CheckSym(OPM.rbrak)
    ELSE sysflag := default
    END
  END CheckSysFlag;

  PROCEDURE RecordType(VAR typ, banned: OPT.Struct);
    VAR fld, first, last, base: OPT.Object;
      ftyp: OPT.Struct; sysflag: INTEGER;
  BEGIN typ := OPT.NewStr(OPM.Comp, OPM.Record); typ^.BaseTyp := NIL;
    CheckSysFlag(sysflag, -1);
    IF sym = OPM.lparen THEN
      OPS.Get(sym); (*record extension*)
      IF sym = OPM.ident THEN
        qualident(base);
        IF (base^.mode = OPM.Typ) & (base^.typ^.comp = OPM.Record) THEN
          IF base^.typ = banned THEN err(58)
          ELSE base^.typ^.pvused := TRUE;
            typ^.BaseTyp := base^.typ; typ^.extlev := base^.typ^.extlev + 1; typ^.sysflag := base^.typ^.sysflag
          END
        ELSE err(52)
        END
      ELSE err(OPM.ident)
      END ;
      CheckSym(OPM.rparen)
    END ;
    IF sysflag >= 0 THEN typ^.sysflag := sysflag END ;
    OPT.OpenScope(0, NIL); first := NIL; last := NIL;
    LOOP
      IF sym = OPM.ident THEN
        LOOP
          IF sym = OPM.ident THEN
            IF typ^.BaseTyp # NIL THEN
              OPT.FindField(OPS.name, typ^.BaseTyp, fld);
              IF fld # NIL THEN err(1) END
            END ;
            OPT.Insert(OPS.name, fld); CheckMark(fld^.vis);
            fld^.mode := OPM.Fld; fld^.link := NIL; fld^.typ := OPT.undftyp;
            IF first = NIL THEN first := fld END ;
            IF last = NIL THEN typ^.link := fld ELSE last^.link := fld END ;
            last := fld
          ELSE err(OPM.ident)
          END ;
          IF sym = OPM.comma THEN OPS.Get(sym)
          ELSIF sym = OPM.ident THEN err(OPM.comma)
          ELSE EXIT
          END
        END ;
        CheckSym(OPM.colon); Type(ftyp, banned);
        ftyp^.pvused := TRUE;
        IF ftyp^.comp = OPM.DynArr THEN ftyp := OPT.undftyp; err(88) END ;
        WHILE first # NIL DO
          first^.typ := ftyp; first := first^.link
        END
      END ;
      IF sym = OPM.semicolon THEN OPS.Get(sym)
      ELSIF sym = OPM.ident THEN err(OPM.semicolon)
      ELSE EXIT
      END
    END ;
    OPT.CloseScope
  END RecordType;

  PROCEDURE ArrayType(VAR typ, banned: OPT.Struct);
    VAR x: OPT.Node; n: LONGINT; sysflag: INTEGER;
  BEGIN CheckSysFlag(sysflag, 0);
    IF sym = OPM.of THEN  (*dynamic array*)
      typ := OPT.NewStr(OPM.Comp, OPM.DynArr); typ^.mno := 0; typ^.sysflag := sysflag;
      OPS.Get(sym); Type(typ^.BaseTyp, banned);
      typ^.BaseTyp^.pvused := TRUE;
      IF typ^.BaseTyp^.comp = OPM.DynArr THEN typ^.n := typ^.BaseTyp^.n + 1
      ELSE typ^.n := 0
      END
    ELSE
      typ := OPT.NewStr(OPM.Comp, OPM.Array); typ^.sysflag := sysflag; ConstExpression(x);
      IF x^.typ^.form IN OPM.intSet THEN n := x^.conval^.intval;
        IF (n <= 0) OR (n > OPM.MaxIndex) THEN err(63); n := 1 END
      ELSE err(51); n := 1
      END ;
      typ^.n := n;
      IF sym = OPM.of THEN
        OPS.Get(sym); Type(typ^.BaseTyp, banned);
        typ^.BaseTyp^.pvused := TRUE
      ELSIF sym = OPM.comma THEN
        OPS.Get(sym); IF sym # OPM.of THEN ArrayType(typ^.BaseTyp, banned) END
      ELSE err(35)
      END ;
      IF typ^.BaseTyp^.comp = OPM.DynArr THEN typ^.BaseTyp := OPT.undftyp; err(88) END
    END
  END ArrayType;

  PROCEDURE PointerType(VAR typ: OPT.Struct);
    VAR id: OPT.Object;
  BEGIN typ := OPT.NewStr(OPM.Pointer, OPM.Basic); CheckSysFlag(typ^.sysflag, 0);
    CheckSym(OPM.to);
    IF sym = OPM.ident THEN OPT.Find(id);
      IF id = NIL THEN
        IF nofFwdPtr < LEN(FwdPtr) THEN FwdPtr[nofFwdPtr] := typ; INC(nofFwdPtr)
        ELSE err(224)
        END ;
        typ^.link := OPT.NewObj(); COPY(OPS.name, typ^.link^.name);
        typ^.BaseTyp := OPT.undftyp; OPS.Get(sym) (*forward ref*)
      ELSE qualident(id);
        IF id^.mode = OPM.Typ THEN
          IF id^.typ^.comp IN {OPM.Array, OPM.DynArr, OPM.Record} THEN
            typ^.BaseTyp := id^.typ
          ELSE typ^.BaseTyp := OPT.undftyp; err(57)
          END
        ELSE typ^.BaseTyp := OPT.undftyp; err(52)
        END
      END
    ELSE Type(typ^.BaseTyp, OPT.notyp);
      IF ~(typ^.BaseTyp^.comp IN {OPM.Array, OPM.DynArr, OPM.Record}) THEN
        typ^.BaseTyp := OPT.undftyp; err(57)
      END
    END
  END PointerType;

  PROCEDURE FormalParameters(VAR firstPar: OPT.Object; VAR resTyp: OPT.Struct);
    VAR mode: SHORTINT;
        par, first, last, res: OPT.Object; typ: OPT.Struct;
  BEGIN first := NIL; last := firstPar;
    IF (sym = OPM.ident) OR (sym = OPM.var) THEN
      LOOP
        IF sym = OPM.var THEN OPS.Get(sym); mode := OPM.VarPar ELSE mode := OPM.Var END ;
        LOOP
          IF sym = OPM.ident THEN
            OPT.Insert(OPS.name, par); OPS.Get(sym);
            par^.mode := mode; par^.link := NIL;
            IF first = NIL THEN first := par END ;
            IF firstPar = NIL THEN firstPar := par ELSE last^.link := par END ;
            last := par
          ELSE err(OPM.ident)
          END ;
          IF sym = OPM.comma THEN OPS.Get(sym)
          ELSIF sym = OPM.ident THEN err(OPM.comma)
          ELSIF sym = OPM.var THEN err(OPM.comma); OPS.Get(sym)
          ELSE EXIT
          END
        END ;
        CheckSym(OPM.colon); Type(typ, OPT.notyp);
        IF mode = OPM.Var THEN typ^.pvused := TRUE END ;
        (* typ^.pbused is set when parameter type name is parsed *)
        WHILE first # NIL DO first^.typ := typ; first := first^.link END ;
        IF sym = OPM.semicolon THEN OPS.Get(sym)
        ELSIF sym = OPM.ident THEN err(OPM.semicolon)
        ELSE EXIT
        END
      END
    END ;
    CheckSym(OPM.rparen);
    IF sym = OPM.colon THEN
      OPS.Get(sym); resTyp := OPT.undftyp;
      IF sym = OPM.ident THEN qualident(res);
        IF res^.mode = OPM.Typ THEN
          IF (res^.typ^.form < OPM.Comp) (*OR (res^.typ^.form >= Int8) & (res^.typ^.form <= Int64)*) THEN resTyp := res^.typ;
          ELSE err(54)
          END
        ELSE err(52)
        END
      ELSE err(OPM.ident)
      END
    ELSE resTyp := OPT.notyp
    END
  END FormalParameters;

  PROCEDURE TypeDecl(VAR typ, banned: OPT.Struct);
    VAR id: OPT.Object;
  BEGIN typ := OPT.undftyp;
    IF sym < OPM.lparen THEN err(12);
      REPEAT OPS.Get(sym) UNTIL sym >= OPM.lparen
    END ;
    IF sym = OPM.ident THEN qualident(id);
      IF id^.mode = OPM.Typ THEN
        IF id^.typ = banned THEN err(58) ELSE
          typ := id.typ
        END
      ELSE err(52)
      END
    ELSIF sym = OPM.array THEN
      OPS.Get(sym); ArrayType(typ, banned)
    ELSIF sym = OPM.record THEN
      OPS.Get(sym); RecordType(typ, banned);
      OPB.Inittd(TDinit, lastTDinit, typ); CheckSym(OPM.end)
    ELSIF sym = OPM.pointer THEN
      OPS.Get(sym); PointerType(typ)
    ELSIF sym = OPM.procedure THEN
      OPS.Get(sym); typ := OPT.NewStr(OPM.ProcTyp, OPM.Basic); CheckSysFlag(typ^.sysflag, 0);
      IF sym = OPM.lparen THEN
        OPS.Get(sym); OPT.OpenScope(level, NIL);
        FormalParameters(typ^.link, typ^.BaseTyp); OPT.CloseScope
      ELSE typ^.BaseTyp := OPT.notyp; typ^.link := NIL
      END
    ELSE err(12)
    END ;
    LOOP
      IF (sym >= OPM.semicolon) & (sym <= OPM.else) OR (sym = OPM.rparen) OR (sym = OPM.eof) THEN EXIT END;
      err(15); IF sym = OPM.ident THEN EXIT END;
      OPS.Get(sym)
    END
  END TypeDecl;

  PROCEDURE Type(VAR typ, banned: OPT.Struct);
  BEGIN TypeDecl(typ, banned);
    IF (typ^.form = OPM.Pointer) & (typ^.BaseTyp = OPT.undftyp) & (typ^.strobj = NIL) THEN err(0) END
  END Type;

  PROCEDURE selector(VAR x: OPT.Node);
    VAR obj, proc: OPT.Object; y: OPT.Node; typ: OPT.Struct; name: OPS.Name;
  BEGIN
    LOOP
      IF sym = OPM.lbrak THEN OPS.Get(sym);
        LOOP
          IF (x^.typ # NIL) & (x^.typ^.form = OPM.Pointer) THEN OPB.DeRef(x) END ;
          Expression(y); OPB.Index(x, y);
          IF sym = OPM.comma THEN OPS.Get(sym) ELSE EXIT END
        END ;
        CheckSym(OPM.rbrak)
      ELSIF sym = OPM.period THEN OPS.Get(sym);
        IF sym = OPM.ident THEN name := OPS.name; OPS.Get(sym);
          IF x^.typ # NIL THEN
            IF x^.typ^.form = OPM.Pointer THEN OPB.DeRef(x) END ;
            IF x^.typ^.comp = OPM.Record THEN
              OPT.FindField(name, x^.typ, obj); OPB.Field(x, obj);
              IF (obj # NIL) & (obj^.mode = OPM.TProc) THEN
                IF sym = OPM.arrow THEN  (* super call *) OPS.Get(sym);
                  y := x^.left;
                  IF y^.class = OPM.Nderef THEN y := y^.left END ;  (* y = record variable *)
                  IF y^.obj # NIL THEN
                    proc := OPT.topScope;  (* find innermost scope which owner is a OPM.TProc *)
                    WHILE (proc^.link # NIL) & (proc^.link^.mode # OPM.TProc) DO proc := proc^.left END ;
                    IF (proc^.link = NIL) OR (proc^.link^.link # y^.obj) THEN err(75) END ;
                    typ := y^.obj^.typ;
                    IF typ^.form = OPM.Pointer THEN typ := typ^.BaseTyp END ;
                    OPT.FindField(x^.obj^.name, typ^.BaseTyp, proc);
                    IF proc # NIL THEN x^.subcl := OPM.super ELSE err(74) END
                  ELSE err(75)
                  END
                END ;
                IF (obj^.typ # OPT.notyp) & (sym # OPM.lparen) THEN err(OPM.lparen) END
              END
            ELSE err(53)
            END
          ELSE err(52)
          END
        ELSE err(OPM.ident)
        END
      ELSIF sym = OPM.arrow THEN OPS.Get(sym); OPB.DeRef(x)
      ELSIF (sym = OPM.lparen) & (x^.class < OPM.Nconst) & (x^.typ^.form # OPM.ProcTyp) &
          ((x^.obj = NIL) OR (x^.obj^.mode # OPM.TProc)) THEN
        OPS.Get(sym);
        IF sym = OPM.ident THEN
          qualident(obj);
          IF obj^.mode = OPM.Typ THEN OPB.TypTest(x, obj, TRUE)
          ELSE err(52)
          END
        ELSE err(OPM.ident)
        END ;
        CheckSym(OPM.rparen)
      ELSE EXIT
      END
    END
  END selector;

  PROCEDURE ActualParameters(VAR aparlist: OPT.Node; fpar: OPT.Object);
    VAR apar, last: OPT.Node;
  BEGIN aparlist := NIL; last := NIL;
    IF sym # OPM.rparen THEN
      LOOP Expression(apar);
        IF fpar # NIL THEN
          OPB.Param(apar, fpar); OPB.Link(aparlist, last, apar);
          fpar := fpar^.link;
        ELSE err(64)
        END ;
        IF sym = OPM.comma THEN OPS.Get(sym)
        ELSIF (OPM.lparen <= sym) & (sym <= OPM.ident) THEN err(OPM.comma)
        ELSE EXIT
        END
      END
    END ;
    IF fpar # NIL THEN err(65) END
  END ActualParameters;

  PROCEDURE StandProcCall(VAR x: OPT.Node);
    VAR y: OPT.Node; m: SHORTINT; n: INTEGER;
  BEGIN m := SHORT(SHORT(x^.obj^.adr)); n := 0;
    IF sym = OPM.lparen THEN OPS.Get(sym);
      IF sym # OPM.rparen THEN
        LOOP
          IF n = 0 THEN Expression(x); OPB.StPar0(x, m); n := 1
          ELSIF n = 1 THEN Expression(y); OPB.StPar1(x, y, m); n := 2
          ELSE Expression(y); OPB.StParN(x, y, m, n); INC(n)
          END ;
          IF sym = OPM.comma THEN OPS.Get(sym)
          ELSIF (OPM.lparen <= sym) & (sym <= OPM.ident) THEN err(OPM.comma)
          ELSE EXIT
          END
        END ;
        CheckSym(OPM.rparen)
      ELSE OPS.Get(sym)
      END ;
      OPB.StFct(x, m, n)
    ELSE err(OPM.lparen)
    END ;
    IF (level > 0) & ((m = OPM.newfn) OR (m = OPM.sysnewfn)) THEN OPT.topScope^.link^.leaf := FALSE END
  END StandProcCall;

  PROCEDURE Element(VAR x: OPT.Node);
    VAR y: OPT.Node;
  BEGIN Expression(x);
    IF sym = OPM.upto THEN
      OPS.Get(sym); Expression(y); OPB.SetRange(x, y)
    ELSE OPB.SetElem(x)
    END
  END Element;

  PROCEDURE Sets(VAR x: OPT.Node);
    VAR y: OPT.Node;
  BEGIN
    IF sym # OPM.rbrace THEN
      Element(x);
      LOOP
        IF sym = OPM.comma THEN OPS.Get(sym)
        ELSIF (OPM.lparen <= sym) & (sym <= OPM.ident) THEN err(OPM.comma)
        ELSE EXIT
        END ;
        Element(y); OPB.Op(OPM.plus, x, y)
      END
    ELSE x := OPB.EmptySet()
    END ;
    CheckSym(OPM.rbrace)
  END Sets;

  PROCEDURE Factor(VAR x: OPT.Node);
    VAR fpar, id: OPT.Object; apar: OPT.Node;
  BEGIN
    IF sym < OPM.lparen THEN err(13);
      REPEAT OPS.Get(sym) UNTIL sym >= OPM.lparen
    END ;
    IF sym = OPM.ident THEN
      qualident(id); x := OPB.NewLeaf(id); selector(x);
      IF (x^.class = OPM.Nproc) & (x^.obj^.mode = OPM.SProc) THEN StandProcCall(x)  (* x may be NIL *)
      ELSIF sym = OPM.lparen THEN
        OPS.Get(sym); OPB.PrepCall(x, fpar);
        ActualParameters(apar, fpar);
        OPB.Call(x, apar, fpar);
        CheckSym(OPM.rparen);
        IF level > 0 THEN OPT.topScope^.link^.leaf := FALSE END
      END
    ELSIF sym = OPM.number THEN
      CASE OPS.numtyp OF
      | OPM.char:     x := OPB.NewIntConst(OPS.intval); x^.typ := OPT.chartyp
      | OPM.integer:  x := OPB.NewIntConst(OPS.intval)
      | OPM.real:     x := OPB.NewRealConst(OPS.realval, OPT.realtyp)
      | OPM.longreal: x := OPB.NewRealConst(OPS.lrlval, OPT.lrltyp)
      ELSE
         OPM.LogWStr("unhandled case in OPP.Factor, OPS.numtyp = "); OPM.LogWNum(OPS.numtyp, 0); OPM.LogWLn;
      END ;
      OPS.Get(sym)
    ELSIF sym = OPM.string THEN
      x := OPB.NewString(OPS.str, OPS.intval); OPS.Get(sym)
    ELSIF sym = OPM.nil THEN
      x := OPB.Nil(); OPS.Get(sym)
    ELSIF sym = OPM.lparen THEN
      OPS.Get(sym); Expression(x); CheckSym(OPM.rparen)
    ELSIF sym = OPM.lbrak THEN
      OPS.Get(sym); err(OPM.lparen); Expression(x); CheckSym(OPM.rparen)
    ELSIF sym = OPM.lbrace THEN OPS.Get(sym); Sets(x)
    ELSIF sym = OPM.not THEN
      OPS.Get(sym); Factor(x); OPB.MOp(OPM.not, x)
    ELSE err(13); OPS.Get(sym); x := NIL
    END ;
    IF x = NIL THEN x := OPB.NewIntConst(1); x^.typ := OPT.undftyp END
  END Factor;

  PROCEDURE Term(VAR x: OPT.Node);
    VAR y: OPT.Node; mulop: SHORTINT;
  BEGIN Factor(x);
    WHILE (OPM.times <= sym) & (sym <= OPM.and) DO
      mulop := sym; OPS.Get(sym);
      Factor(y); OPB.Op(mulop, x, y)
    END
  END Term;

  PROCEDURE SimpleExpression(VAR x: OPT.Node);
    VAR y: OPT.Node; addop: SHORTINT;
  BEGIN
    IF sym = OPM.minus THEN OPS.Get(sym); Term(x); OPB.MOp(OPM.minus, x)
    ELSIF sym = OPM.plus THEN OPS.Get(sym); Term(x); OPB.MOp(OPM.plus, x)
    ELSE Term(x)
    END ;
    WHILE (OPM.plus <= sym) & (sym <= OPM.or) DO
      addop := sym; OPS.Get(sym);
      Term(y); OPB.Op(addop, x, y)
    END
  END SimpleExpression;

  PROCEDURE Expression(VAR x: OPT.Node);
    VAR y: OPT.Node; obj: OPT.Object; relation: SHORTINT;
  BEGIN SimpleExpression(x);
    IF (OPM.eql <= sym) & (sym <= OPM.geq) THEN
      relation := sym; OPS.Get(sym);
      SimpleExpression(y); OPB.Op(relation, x, y)
    ELSIF sym = OPM.in THEN
      OPS.Get(sym); SimpleExpression(y); OPB.In(x, y)
    ELSIF sym = OPM.is THEN
      OPS.Get(sym);
      IF sym = OPM.ident THEN
        qualident(obj);
        IF obj^.mode = OPM.Typ THEN OPB.TypTest(x, obj, FALSE)
        ELSE err(52)
        END
      ELSE err(OPM.ident)
      END
    END
  END Expression;

  PROCEDURE Receiver(VAR mode: SHORTINT; VAR name: OPS.Name; VAR typ, rec: OPT.Struct);
    VAR obj: OPT.Object;
  BEGIN typ := OPT.undftyp; rec := NIL;
    IF sym = OPM.var THEN OPS.Get(sym); mode := OPM.VarPar ELSE mode := OPM.Var END ;
    name := OPS.name; CheckSym(OPM.ident); CheckSym(OPM.colon);
    IF sym = OPM.ident THEN OPT.Find(obj); OPS.Get(sym);
      IF obj = NIL THEN err(0)
      ELSIF obj^.mode # OPM.Typ THEN err(72)
      ELSE typ := obj^.typ; rec := typ;
        IF rec^.form = OPM.Pointer THEN rec := rec^.BaseTyp END ;
        IF ~((mode = OPM.Var) & (typ^.form = OPM.Pointer) & (rec^.comp = OPM.Record) OR
          (mode = OPM.VarPar) & (typ^.comp = OPM.Record)) THEN err(70); rec := NIL END ;
        IF (rec # NIL) & (rec^.mno # level) THEN err(72); rec := NIL END
      END
    ELSE err(OPM.ident)
    END ;
    CheckSym(OPM.rparen);
    IF rec = NIL THEN rec := OPT.NewStr(OPM.Comp, OPM.Record); rec^.BaseTyp := NIL END
  END Receiver;

  PROCEDURE Extends(x, b: OPT.Struct): BOOLEAN;
  BEGIN
    IF (b^.form = OPM.Pointer) & (x^.form = OPM.Pointer) THEN b := b^.BaseTyp; x := x^.BaseTyp END ;
    IF (b^.comp = OPM.Record) & (x^.comp = OPM.Record) THEN
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
      IF sym = OPM.string THEN
        WHILE OPS.str[n] # 0X DO ext[n+1] := OPS.str[n]; INC(n) END ;
        ext^[0] := CHR(n); OPS.Get(sym);
        (*
          Console.String("Code procedure, length "); Console.Int(n,1); Console.Ln;
          Console.String('  "'); Console.String(ext^); Console.String('"'); Console.Ln;
        *)
      ELSE
        LOOP
          IF sym = OPM.number THEN c := OPS.intval; INC(n);
            IF (c < 0) OR (c > 255) OR (n = OPT.MaxConstLen) THEN
              err(64); c := 1; n := 1
            END ;
            OPS.Get(sym); ext^[n] := CHR(c)
          END ;
          IF sym = OPM.comma THEN OPS.Get(sym)
          ELSIF sym = OPM.number THEN err(OPM.comma)
          ELSE ext^[0] := CHR(n); EXIT
          END
        END
      END ;
      INCL(proc^.conval^.setval, OPM.hasBody)
    END GetCode;

    PROCEDURE GetParams;
    BEGIN
      proc^.vis := vis; proc^.mode := mode; proc^.typ := OPT.notyp;
      proc^.conval := OPT.NewConst(); proc^.conval^.setval := {};
      IF sym = OPM.lparen THEN
        OPS.Get(sym); FormalParameters(proc^.link, proc^.typ)
      END ;
      IF fwd # NIL THEN
        OPB.CheckParameters(proc^.link, fwd^.link, TRUE);
        IF proc^.typ # fwd^.typ THEN err(117) END ;
        proc := fwd; OPT.topScope := proc^.scope;
        IF mode = OPM.IProc THEN proc^.mode := OPM.IProc END
      END
    END GetParams;

    PROCEDURE Body;
      VAR procdec, statseq: OPT.Node; c: LONGINT;
    BEGIN
      c := OPM.errpos;
      INCL(proc^.conval^.setval, OPM.hasBody);
      CheckSym(OPM.semicolon); Block(procdec, statseq);
      OPB.Enter(procdec, statseq, proc); x := procdec;
      x^.conval := OPT.NewConst(); x^.conval^.intval := c;
      IF sym = OPM.ident THEN
        IF OPS.name # proc^.name THEN err(4) END ;
        OPS.Get(sym)
      ELSE err(OPM.ident)
      END
    END Body;

    PROCEDURE TProcDecl;
      VAR baseProc: OPT.Object;
        objTyp, recTyp: OPT.Struct;
        objMode: SHORTINT;
        objName: OPS.Name;
    BEGIN
      OPS.Get(sym); mode := OPM.TProc;
      IF level > 0 THEN err(73) END ;
      Receiver(objMode, objName, objTyp, recTyp);
      IF sym = OPM.ident THEN
        name := OPS.name; CheckMark(vis);
        OPT.FindField(name, recTyp, fwd);
        OPT.FindField(name, recTyp^.BaseTyp, baseProc);
        IF (baseProc # NIL) & (baseProc^.mode # OPM.TProc) THEN baseProc := NIL END ;
        IF fwd = baseProc THEN fwd := NIL END ;
        IF (fwd # NIL) & (fwd^.mnolev # level) THEN fwd := NIL END ;
        IF (fwd # NIL) & (fwd^.mode = OPM.TProc) & ~(OPM.hasBody IN fwd^.conval^.setval) THEN
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
          IF (baseProc^.vis = OPM.external) & (proc^.vis = OPM.internal) &
            (recTyp^.strobj # NIL) & (recTyp^.strobj^.vis = OPM.external) THEN err(109)
          END ;
          INCL(proc^.conval^.setval, OPM.isRedef)
        END ;
        IF ~forward THEN Body END ;
        DEC(level); OPT.CloseScope
      ELSE err(OPM.ident)
      END
    END TProcDecl;

  BEGIN proc := NIL; forward := FALSE; x := NIL; mode := OPM.LProc;
    IF (sym # OPM.ident) & (sym # OPM.lparen) THEN
      IF sym = OPM.times THEN  (* mode set later in OPB.CheckAssign *)
      ELSIF sym = OPM.arrow THEN forward := TRUE
      ELSIF sym = OPM.plus THEN mode := OPM.IProc
      ELSIF sym = OPM.minus THEN mode := OPM.CProc
      ELSE err(OPM.ident)
      END ;
      IF (mode IN {OPM.IProc, OPM.CProc}) & ~OPT.SYSimported THEN err(135) END ;
      OPS.Get(sym)
    END ;
    IF sym = OPM.lparen THEN TProcDecl
    ELSIF sym = OPM.ident THEN OPT.Find(fwd);
      name := OPS.name; CheckMark(vis);
      IF (vis # OPM.internal) & (mode = OPM.LProc) THEN mode := OPM.XProc END ;
      IF (fwd # NIL) & ((fwd^.mnolev # level) OR (fwd^.mode = OPM.SProc)) THEN fwd := NIL END ;
      IF (fwd # NIL) & (fwd^.mode IN {OPM.LProc, OPM.XProc}) & ~(OPM.hasBody IN fwd^.conval^.setval) THEN
        (* there exists a corresponding forward declaration *)
        proc := OPT.NewObj(); proc^.leaf := TRUE;
        IF fwd^.vis # vis THEN err(118) END
      ELSE
        IF fwd # NIL THEN err(1); fwd := NIL END ;
        OPT.Insert(name, proc)
      END ;
      IF (mode # OPM.LProc) & (level > 0) THEN err(73) END ;
      INC(level); OPT.OpenScope(level, proc);
      proc^.link := NIL; GetParams;
      IF mode = OPM.CProc THEN GetCode
      ELSIF ~forward THEN Body
      END ;
      DEC(level); OPT.CloseScope
    ELSE err(OPM.ident)
    END
  END ProcedureDeclaration;

  PROCEDURE CaseLabelList(VAR lab: OPT.Node; LabelForm: INTEGER; VAR n: INTEGER; VAR tab: CaseTable);
    VAR x, y, lastlab: OPT.Node; i, f: INTEGER; xval, yval: LONGINT;
  BEGIN lab := NIL; lastlab := NIL;
    LOOP ConstExpression(x); f := x^.typ^.form;
      IF f IN OPM.intSet + {OPM.Char} THEN  xval := x^.conval^.intval
      ELSE err(61); xval := 1
      END ;
      IF f IN OPM.intSet THEN
        IF LabelForm < f THEN err(60) END
      ELSIF LabelForm # f THEN err(60)
      END ;
      IF sym = OPM.upto THEN
        OPS.Get(sym); ConstExpression(y); yval := y^.conval^.intval;
        IF (y^.typ^.form # f) & ~((f IN OPM.intSet) & (y^.typ^.form IN OPM.intSet)) THEN err(60) END ;
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
      IF sym = OPM.comma THEN OPS.Get(sym)
      ELSIF (sym = OPM.number) OR (sym = OPM.ident) THEN err(OPM.comma)
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
      IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
      ELSIF ~(x^.typ^.form IN {OPM.Char..OPM.LInt}) THEN err(125)
      END ;
      CheckSym(OPM.of); cases := NIL; lastcase := NIL; n := 0;
      LOOP
        IF sym < OPM.bar THEN
          CaseLabelList(lab, x^.typ^.form, n, tab);
          CheckSym(OPM.colon); StatSeq(y);
          OPB.Construct(OPM.Ncasedo, lab, y); OPB.Link(cases, lastcase, lab)
        END ;
        IF sym = OPM.bar THEN OPS.Get(sym) ELSE EXIT END
      END ;
      IF n > 0 THEN low := tab[0].low; high := tab[n-1].high;
        IF high - low > OPM.MaxCaseRange THEN err(209) END
      ELSE low := 1; high := 0
      END ;
      e := sym = OPM.else;
      IF e THEN OPS.Get(sym); StatSeq(y)
      ELSE
         y := NIL;
	 OPM.Mark(-307, OPM.curpos); (* notice about no OPM.else symbol; -- noch *)
      END ;
      OPB.Construct(OPM.Ncaselse, cases, y); OPB.Construct(OPM.Ncase, x, cases);
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
      IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126); x := OPB.NewBoolConst(FALSE)
      ELSIF x^.typ^.form # OPM.Bool THEN err(120); x := OPB.NewBoolConst(FALSE)
      END ;
      pos := OPM.errpos
    END CheckBool;

  BEGIN stat := NIL; last := NIL;
    LOOP x := NIL;
      IF sym < OPM.ident THEN err(14);
        REPEAT OPS.Get(sym) UNTIL sym >= OPM.ident
      END ;
      IF sym = OPM.ident THEN
        qualident(id); x := OPB.NewLeaf(id); selector(x);
        IF sym = OPM.becomes THEN
          OPS.Get(sym); Expression(y); OPB.Assign(x, y)
        ELSIF sym = OPM.eql THEN
          err(OPM.becomes); OPS.Get(sym); Expression(y); OPB.Assign(x, y)
        ELSIF (x^.class = OPM.Nproc) & (x^.obj^.mode = OPM.SProc) THEN
          StandProcCall(x);
          IF (x # NIL) & (x^.typ # OPT.notyp) THEN err(55) END
        ELSE OPB.PrepCall(x, fpar);
          IF sym = OPM.lparen THEN
            OPS.Get(sym); ActualParameters(apar, fpar); CheckSym(OPM.rparen)
          ELSE apar := NIL;
            IF fpar # NIL THEN err(65) END
          END ;
          OPB.Call(x, apar, fpar);
          IF x^.typ # OPT.notyp THEN err(55) END ;
          IF level > 0 THEN OPT.topScope^.link^.leaf := FALSE END
        END ;
        pos := OPM.errpos
      ELSIF sym = OPM.if THEN
        OPS.Get(sym); Expression(x); CheckBool(x); CheckSym(OPM.then); StatSeq(y);
        OPB.Construct(OPM.Nif, x, y); SetPos(x); lastif := x;
        WHILE sym = OPM.elsif DO
          OPS.Get(sym); Expression(y); CheckBool(y); CheckSym(OPM.then); StatSeq(z);
          OPB.Construct(OPM.Nif, y, z); SetPos(y); OPB.Link(x, lastif, y)
        END ;
        IF sym = OPM.else THEN OPS.Get(sym); StatSeq(y) ELSE y := NIL END ;
        OPB.Construct(OPM.Nifelse, x, y); CheckSym(OPM.end); OPB.OptIf(x); pos := OPM.errpos
      ELSIF sym = OPM.case THEN
        OPS.Get(sym); CasePart(x); CheckSym(OPM.end)
      ELSIF sym = OPM.while THEN
        OPS.Get(sym); Expression(x); CheckBool(x); CheckSym(OPM.do); StatSeq(y);
        OPB.Construct(OPM.Nwhile, x, y); CheckSym(OPM.end)
      ELSIF sym = OPM.repeat THEN
        OPS.Get(sym); StatSeq(x);
        IF sym = OPM.until THEN OPS.Get(sym); Expression(y); CheckBool(y)
        ELSE err(OPM.until)
        END ;
        OPB.Construct(OPM.Nrepeat, x, y)
      ELSIF sym = OPM.for THEN
        OPS.Get(sym);
        IF sym = OPM.ident THEN qualident(id);
          IF ~(id^.typ^.form IN OPM.intSet) THEN err(68) END ;
          CheckSym(OPM.becomes); Expression(y); pos := OPM.errpos;
          x := OPB.NewLeaf(id); OPB.Assign(x, y); SetPos(x);
          CheckSym(OPM.to); Expression(y); pos := OPM.errpos;
          IF y^.class # OPM.Nconst THEN
            name := "@@"; OPT.Insert(name, t); t^.name := "@for";  (* avoid err 1 *)
            t^.mode := OPM.Var; t^.typ := x^.left^.typ;
            obj := OPT.topScope^.scope;
            IF obj = NIL THEN OPT.topScope^.scope := t
            ELSE
              WHILE obj^.link # NIL DO obj := obj^.link END ;
              obj^.link := t
            END ;
            z := OPB.NewLeaf(t); OPB.Assign(z, y); SetPos(z); OPB.Link(stat, last, z);
            y := OPB.NewLeaf(t)
          ELSIF (y^.typ^.form < OPM.SInt) OR (y^.typ^.form > x^.left^.typ^.form) THEN err(113)
          END ;
          OPB.Link(stat, last, x);
          IF sym = OPM.by THEN OPS.Get(sym); ConstExpression(z) ELSE z := OPB.NewIntConst(1) END ;
          pos := OPM.errpos; x := OPB.NewLeaf(id);
          IF z^.conval^.intval > 0 THEN OPB.Op(OPM.leq, x, y)
          ELSIF z^.conval^.intval < 0 THEN OPB.Op(OPM.geq, x, y)
          ELSE err(63); OPB.Op(OPM.geq, x, y)
          END ;
          CheckSym(OPM.do); StatSeq(s);
          y := OPB.NewLeaf(id); OPB.StPar1(y, z, OPM.incfn); SetPos(y);
          IF s = NIL THEN s := y
          ELSE z := s;
            WHILE z^.link # NIL DO z := z^.link END ;
            z^.link := y
          END ;
          CheckSym(OPM.end); OPB.Construct(OPM.Nwhile, x, s)
        ELSE err(OPM.ident)
        END
      ELSIF sym = OPM.loop THEN
        OPS.Get(sym); INC(LoopLevel); StatSeq(x); DEC(LoopLevel);
        OPB.Construct(OPM.Nloop, x, NIL); CheckSym(OPM.end); pos := OPM.errpos
      ELSIF sym = OPM.with THEN
        OPS.Get(sym); idtyp := NIL; x := NIL;
        LOOP
          IF sym = OPM.ident THEN
            qualident(id); y := OPB.NewLeaf(id);
            IF (id # NIL) & (id^.typ^.form = OPM.Pointer) & ((id^.mode = OPM.VarPar) OR ~id^.leaf) THEN
              err(245)  (* jt: do not allow WITH on non-local pointers *)
            END ;
            CheckSym(OPM.colon);
            IF sym = OPM.ident THEN qualident(t);
              IF t^.mode = OPM.Typ THEN
                IF id # NIL THEN
                  idtyp := id^.typ; OPB.TypTest(y, t, FALSE); id^.typ := t^.typ
                ELSE err(130)
                END
              ELSE err(52)
              END
            ELSE err(OPM.ident)
            END
          ELSE err(OPM.ident)
          END ;
          pos := OPM.errpos; CheckSym(OPM.do); StatSeq(s); OPB.Construct(OPM.Nif, y, s); SetPos(y);
          IF idtyp # NIL THEN id^.typ := idtyp; idtyp := NIL END ;
          IF x = NIL THEN x := y; lastif := x ELSE OPB.Link(x, lastif, y) END ;
          IF sym = OPM.bar THEN OPS.Get(sym) ELSE EXIT END
        END;
        e := sym = OPM.else;
        IF e THEN OPS.Get(sym); StatSeq(s) ELSE s := NIL END ;
        OPB.Construct(OPM.Nwith, x, s); CheckSym(OPM.end);
        IF e THEN x^.subcl := 1 END
      ELSIF sym = OPM.exit THEN
        OPS.Get(sym);
        IF LoopLevel = 0 THEN err(46) END ;
        OPB.Construct(OPM.Nexit, x, NIL);
        pos := OPM.errpos
      ELSIF sym = OPM.return THEN OPS.Get(sym);
        IF sym < OPM.semicolon THEN Expression(x) END ;
        IF level > 0 THEN OPB.Return(x, OPT.topScope^.link)
        ELSE (* not standard Oberon *) OPB.Return(x, NIL)
        END ;
        pos := OPM.errpos
      END ;
      IF x # NIL THEN SetPos(x); OPB.Link(stat, last, x) END ;
      IF sym = OPM.semicolon THEN OPS.Get(sym)
      ELSIF (sym <= OPM.ident) OR (OPM.if <= sym) & (sym <= OPM.return) THEN err(OPM.semicolon)
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
      IF sym = OPM.const THEN
        OPS.Get(sym);
        WHILE sym = OPM.ident DO
          OPT.Insert(OPS.name, obj); CheckMark(obj^.vis);
          obj^.typ := OPT.sinttyp; obj^.mode := OPM.Var;  (* OPM.Var to avoid recursive definition *)
          IF sym = OPM.eql THEN
            OPS.Get(sym); ConstExpression(x)
          ELSIF sym = OPM.becomes THEN
            err(OPM.eql); OPS.Get(sym); ConstExpression(x)
          ELSE err(OPM.eql); x := OPB.NewIntConst(1)
          END ;
          obj^.mode := OPM.Con; obj^.typ := x^.typ; obj^.conval := x^.conval; (* ConstDesc ist not copied *)
          CheckSym(OPM.semicolon)
        END
      END ;
      IF sym = OPM.type THEN
        OPS.Get(sym);
        WHILE sym = OPM.ident DO
          OPT.Insert(OPS.name, obj); obj^.mode := OPM.Typ; obj^.typ := OPT.undftyp;
          CheckMark(obj^.vis);
          IF sym = OPM.eql THEN
            OPS.Get(sym); TypeDecl(obj^.typ, obj^.typ)
          ELSIF (sym = OPM.becomes) OR (sym = OPM.colon) THEN
            err(OPM.eql); OPS.Get(sym); TypeDecl(obj^.typ, obj^.typ)
          ELSE err(OPM.eql)
          END ;
          IF obj^.typ^.strobj = NIL THEN obj^.typ^.strobj := obj END ;
          IF obj^.typ^.comp IN {OPM.Record, OPM.Array, OPM.DynArr} THEN
            i := 0;
            WHILE i < nofFwdPtr DO typ := FwdPtr[i]; INC(i);
              IF typ^.link^.name = obj^.name THEN typ^.BaseTyp := obj^.typ; typ^.link^.name := "" END
            END
          END ;
          CheckSym(OPM.semicolon)
        END
      END ;
      IF sym = OPM.var THEN
        OPS.Get(sym);
        WHILE sym = OPM.ident DO
          LOOP
            IF sym = OPM.ident THEN
              OPT.Insert(OPS.name, obj); CheckMark(obj^.vis);
              obj^.mode := OPM.Var; obj^.link := NIL; obj^.leaf := obj^.vis = OPM.internal; obj^.typ := OPT.undftyp;
              IF first = NIL THEN first := obj END ;
              IF last = NIL THEN OPT.topScope^.scope := obj ELSE last^.link := obj END ;
              last := obj
            ELSE err(OPM.ident)
            END ;
            IF sym = OPM.comma THEN OPS.Get(sym)
            ELSIF sym = OPM.ident THEN err(OPM.comma)
            ELSE EXIT
            END
          END ;
          CheckSym(OPM.colon); Type(typ, OPT.notyp);
          typ^.pvused := TRUE;
          IF typ^.comp = OPM.DynArr THEN typ := OPT.undftyp; err(88) END ;
          WHILE first # NIL DO first^.typ := typ; first := first^.link END ;
          CheckSym(OPM.semicolon)
        END
      END ;
      IF (sym < OPM.const) OR (sym > OPM.var) THEN EXIT END ;
    END ;
    i := 0;
    WHILE i < nofFwdPtr DO
      IF FwdPtr[i]^.link^.name # "" THEN err(128) END ;
      FwdPtr[i] := NIL;  (* garbage collection *)
      INC(i)
    END ;
    OPT.topScope^.adr := OPM.errpos;
    procdec := NIL; lastdec := NIL;
    WHILE sym = OPM.procedure DO
      OPS.Get(sym); ProcedureDeclaration(x);
      IF x # NIL THEN
        IF lastdec = NIL THEN procdec := x ELSE lastdec^.link := x END ;
        lastdec := x
      END ;
      CheckSym(OPM.semicolon)
    END ;
    IF sym = OPM.begin THEN OPS.Get(sym); StatSeq(statseq)
    ELSE statseq := NIL
    END ;
    IF (level = 0) & (TDinit # NIL) THEN
      lastTDinit^.link := statseq; statseq := TDinit
    END ;
    CheckSym(OPM.end)
  END Block;

  PROCEDURE Module*(VAR prog: OPT.Node; opt: SET);
    VAR impName, aliasName: OPS.Name;
        procdec, statseq: OPT.Node;
        c: LONGINT; done: BOOLEAN;
  BEGIN
    OPS.Init; LoopLevel := 0; level := 0; OPS.Get(sym);
    IF sym = OPM.module THEN OPS.Get(sym) ELSE err(16) END ;
    IF sym = OPM.ident THEN
      OPM.LogWStr("compiling "); OPM.LogWStr(OPS.name); OPM.LogW(".");
      OPT.Init(OPS.name, opt); OPS.Get(sym); CheckSym(OPM.semicolon);
      IF sym = OPM.import THEN OPS.Get(sym);
        LOOP
          IF sym = OPM.ident THEN
            COPY(OPS.name, aliasName); COPY(aliasName, impName); OPS.Get(sym);
            IF sym = OPM.becomes THEN OPS.Get(sym);
              IF sym = OPM.ident THEN COPY(OPS.name, impName); OPS.Get(sym) ELSE err(OPM.ident) END
            END ;
            OPT.Import(aliasName, impName, done)
          ELSE err(OPM.ident)
          END ;
          IF sym = OPM.comma THEN OPS.Get(sym)
          ELSIF sym = OPM.ident THEN err(OPM.comma)
          ELSE EXIT
          END
        END ;
        CheckSym(OPM.semicolon)
      END ;
      IF OPM.noerr THEN TDinit := NIL; lastTDinit := NIL; c := OPM.errpos;
        Block(procdec, statseq); OPB.Enter(procdec, statseq, NIL); prog := procdec;
        prog^.conval := OPT.NewConst(); prog^.conval^.intval := c;
        IF sym = OPM.ident THEN
          IF OPS.name # OPT.SelfName THEN err(4) END ;
          OPS.Get(sym)
        ELSE err(OPM.ident)
        END ;
        IF sym # OPM.period THEN err(OPM.period) END
      END
    ELSE err(OPM.ident)
    END ;
    TDinit := NIL; lastTDinit := NIL
  END Module;

END OPP.
