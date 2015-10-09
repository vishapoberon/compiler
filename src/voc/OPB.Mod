MODULE OPB;  (* RC 6.3.89 / 21.2.94 *)  (* object model 17.1.93 *)
(* build parse tree *)

  IMPORT OPT, OPS, OPM, SYSTEM;

  CONST
    (* symbol values or ops *)
    times = 1; slash = 2; div = 3; mod = 4;
    and = 5; plus = 6; minus = 7; or = 8; eql = 9;
    neq = 10; lss = 11; leq = 12; gtr = 13; geq = 14;
    in = 15; is = 16; ash = 17; msk = 18; len = 19;
    conv = 20; abs = 21; cap = 22; odd = 23; not = 33;
    (*SYSTEM*)
    adr = 24; cc = 25; bit = 26; lsh = 27; rot = 28; val = 29;
    
    (* object modes *)
    Var = 1; VarPar = 2; Con = 3; Fld = 4; Typ = 5; LProc = 6; XProc = 7;
    SProc = 8; CProc = 9; IProc = 10; Mod = 11; Head = 12; TProc = 13;

    (* Structure forms *)
    Undef = 0; Byte = 1; Bool = 2; Char = 3; 
    SInt = 4; Int = 5; LInt = 6;
    Real = 7; LReal = 8; Set = 9; String = 10; NilTyp = 11; NoTyp = 12;
    Pointer = 13; ProcTyp = 14;
    Comp = 15;
(*    Int8 = 7; Int16 = 8; Int32 = 9; Int64 = 10;
    Real = 11; LReal = 12; Set = 13; String = 14; NilTyp = 15; NoTyp = 16;
    Pointer = 17; ProcTyp = 18;
    Comp = 19;
 *)
    (*Real = 7; LReal = 8; Set = 9; String = 10; NilTyp = 11; NoTyp = 12;
    Pointer = 13; ProcTyp = 14; 
    Int8 = 15; Int16 = 16; Int32 = 17; Int64 = 18;   
    Comp = (*15*)19;*)

    intSet = {SInt..LInt(*, Int8..Int64*)}; realSet = {Real, LReal};

    (* composite structure forms *)
    Basic = 1; Array = 2; DynArr = 3; Record = 4;

    (* nodes classes *)
    Nvar = 0; Nvarpar = 1; Nfield = 2; Nderef = 3; Nindex = 4; Nguard = 5; Neguard = 6;
    Nconst = 7; Ntype = 8; Nproc = 9; Nupto = 10; Nmop = 11; Ndop = 12; Ncall = 13;
    Ninittd = 14; Nif = 15; Ncaselse = 16; Ncasedo = 17; Nenter = 18; Nassign = 19;
    Nifelse = 20; Ncase = 21; Nwhile = 22; Nrepeat = 23; Nloop = 24; Nexit = 25;
    Nreturn = 26; Nwith = 27; Ntrap = 28;

    (*function number*)
    assign = 0;
    haltfn = 0; newfn = 1; absfn = 2; capfn = 3; ordfn = 4;
    entierfn = 5; oddfn = 6; minfn = 7; maxfn = 8; chrfn = 9;
    shortfn = 10; longfn = 11; sizefn = 12; incfn = 13; decfn = 14;
    inclfn = 15; exclfn = 16; lenfn = 17; copyfn = 18; ashfn = 19; assertfn = 32;
    
    (*SYSTEM function number*)
    adrfn = 20; ccfn = 21; lshfn = 22; rotfn = 23;
    getfn = 24; putfn = 25; getrfn = 26; putrfn = 27;
    bitfn = 28; valfn = 29; sysnewfn = 30; movefn = 31;

    (* module visibility of objects *)
    internal = 0; external = 1; externalR = 2;

    (* procedure flags (conval^.setval) *)
    hasBody = 1; isRedef = 2; slNeeded = 3;

    AssertTrap = 0;  (* default trap number *)

  VAR
    typSize*: PROCEDURE(typ: OPT.Struct);
    exp: INTEGER;  (*side effect of log*)
    maxExp: LONGINT;  (* max n in ASH(1, n) on this machine *)
    
  PROCEDURE err(n: INTEGER);
  BEGIN OPM.err(n)
  END err;
  
  PROCEDURE NewLeaf*(obj: OPT.Object): OPT.Node;
    VAR node: OPT.Node;
  BEGIN
    CASE obj^.mode OF
      Var:
        node := OPT.NewNode(Nvar); node^.readonly := (obj^.vis = externalR) & (obj^.mnolev < 0)
    | VarPar:
        node := OPT.NewNode(Nvarpar)
    | Con:
        node := OPT.NewNode(Nconst); node^.conval := OPT.NewConst();
        node^.conval^ := obj^.conval^  (* string is not copied, only its ref *)
    | Typ:
        node := OPT.NewNode(Ntype)
    | LProc..IProc:
        node := OPT.NewNode(Nproc)
    ELSE err(127); node := OPT.NewNode(Nvar)
    END ;
    node^.obj := obj; node^.typ := obj^.typ;
    RETURN node
  END NewLeaf;
  
  PROCEDURE Construct*(class: SHORTINT; VAR x: OPT.Node;  y: OPT.Node);
    VAR node: OPT.Node;
  BEGIN
    node := OPT.NewNode(class); node^.typ := OPT.notyp;
    node^.left := x; node^.right := y; x := node
  END Construct;
  
  PROCEDURE Link*(VAR x, last: OPT.Node; y: OPT.Node);
  BEGIN
    IF x = NIL THEN x := y ELSE last^.link := y END ;
    WHILE y^.link # NIL DO y := y^.link END ;
    last := y
  END Link;
  
  PROCEDURE BoolToInt(b: BOOLEAN): LONGINT;
  BEGIN
    IF b THEN RETURN 1 ELSE RETURN 0 END
  END BoolToInt;
  
  PROCEDURE IntToBool(i: LONGINT): BOOLEAN;
  BEGIN
    IF i = 0 THEN RETURN FALSE ELSE RETURN TRUE END
  END IntToBool;
  
  PROCEDURE NewBoolConst*(boolval: BOOLEAN): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(Nconst); x^.typ := OPT.booltyp;
    x^.conval := OPT.NewConst(); x^.conval^.intval := BoolToInt(boolval); RETURN x
  END NewBoolConst;

  PROCEDURE OptIf*(VAR x: OPT.Node);  (* x^.link = NIL *)
    VAR if, pred: OPT.Node;
  BEGIN
    if := x^.left;
    WHILE if^.left^.class = Nconst DO
      IF IntToBool(if^.left^.conval^.intval) THEN x := if^.right; RETURN
      ELSIF if^.link = NIL THEN x := x^.right; RETURN
      ELSE if := if^.link; x^.left := if
      END
    END ;
    pred := if; if := if^.link;
    WHILE if # NIL DO
      IF if^.left^.class = Nconst THEN
        IF IntToBool(if^.left^.conval^.intval) THEN
          pred^.link := NIL; x^.right := if^.right; RETURN
        ELSE if := if^.link; pred^.link := if
        END
      ELSE pred := if; if := if^.link
      END
    END
  END OptIf;

  PROCEDURE Nil*(): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(Nconst); x^.typ := OPT.niltyp;
    x^.conval := OPT.NewConst(); x^.conval^.intval := OPM.nilval; RETURN x
  END Nil;

  PROCEDURE EmptySet*(): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(Nconst); x^.typ := OPT.settyp;
    x^.conval := OPT.NewConst(); x^.conval^.setval := {}; RETURN x
  END EmptySet;

  PROCEDURE SetIntType(node: OPT.Node);
    VAR v: LONGINT(*SYSTEM.INT64*);
  BEGIN v := node^.conval^.intval;
    IF (OPM.MinSInt <= SYSTEM.VAL(LONGINT, v)) & (SYSTEM.VAL(LONGINT, v) <= OPM.MaxSInt) THEN node^.typ := OPT.sinttyp
    ELSIF (OPM.MinInt <= SYSTEM.VAL(LONGINT, v)) & (SYSTEM.VAL(LONGINT, v) <= OPM.MaxInt) THEN node^.typ := OPT.inttyp
    ELSIF (OPM.MinLInt <= v) & (v <= OPM.MaxLInt) (*bootstrap or cross*) THEN
      node^.typ := OPT.linttyp
    (*ELSIF (OPM.MinInt64) <= v) & (v <= OPM.MaxInt64) THEN
          node^.typ := OPT.int64typ*)
    ELSE err(203); node^.typ := OPT.sinttyp; node^.conval^.intval := 1
    END
  END SetIntType;

  PROCEDURE NewIntConst*(intval: LONGINT): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(Nconst); x^.conval := OPT.NewConst();
    x^.conval^.intval := intval; SetIntType(x); RETURN x
  END NewIntConst;
  
  PROCEDURE NewRealConst*(realval: LONGREAL; typ: OPT.Struct): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(Nconst); x^.conval := OPT.NewConst();
    x^.conval^.realval := realval; x^.typ := typ; x^.conval^.intval := OPM.ConstNotAlloc;
    RETURN x
  END NewRealConst;

  PROCEDURE NewString*(VAR str: OPS.String; len: LONGINT): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(Nconst); x^.conval := OPT.NewConst(); x^.typ := OPT.stringtyp;
    x^.conval^.intval := OPM.ConstNotAlloc; x^.conval^.intval2 := len;
    x^.conval^.ext := OPT.NewExt(); x^.conval^.ext^ := str;
    RETURN x
  END NewString;
  
  PROCEDURE CharToString(n: OPT.Node);
    VAR ch: CHAR;
  BEGIN
    n^.typ := OPT.stringtyp; ch := CHR(n^.conval^.intval); n^.conval^.ext := OPT.NewExt();
    IF ch = 0X THEN n^.conval^.intval2 := 1 ELSE n^.conval^.intval2 := 2; n^.conval^.ext[1] := 0X END ;
    n^.conval^.ext[0] := ch; n^.conval^.intval := OPM.ConstNotAlloc; n^.obj := NIL
  END CharToString;

  PROCEDURE BindNodes(class: SHORTINT; typ: OPT.Struct; VAR x: OPT.Node; y: OPT.Node);
    VAR node: OPT.Node;
  BEGIN
    node := OPT.NewNode(class); node^.typ := typ;
    node^.left := x; node^.right := y; x := node
  END BindNodes;

  PROCEDURE NotVar(x: OPT.Node): BOOLEAN;
  BEGIN RETURN (x^.class >= Nconst) & ((x^.class # Nmop) OR (x^.subcl # val) OR (x^.left^.class >= Nconst))
  END NotVar;

  PROCEDURE DeRef*(VAR x: OPT.Node);
    VAR strobj, bstrobj: OPT.Object; typ, btyp: OPT.Struct;
  BEGIN
    typ := x^.typ;
    IF x^.class >= Nconst THEN err(78)
    ELSIF typ^.form = Pointer THEN
      IF typ = OPT.sysptrtyp THEN err(57) END ;
      btyp := typ^.BaseTyp; strobj := typ^.strobj; bstrobj := btyp^.strobj;
      IF (strobj # NIL) & (strobj^.name # "") & (bstrobj # NIL) & (bstrobj^.name # "") THEN
        btyp^.pbused := TRUE
      END ;
      BindNodes(Nderef, btyp, x, NIL)
    ELSE err(84)
    END
  END DeRef;

  PROCEDURE Index*(VAR x: OPT.Node; y: OPT.Node);
    VAR f: INTEGER; typ: OPT.Struct;
  BEGIN
    f := y^.typ^.form;
    IF x^.class >= Nconst THEN err(79)
    ELSIF ~(f IN intSet) OR (y^.class IN {Nproc, Ntype}) THEN err(80); y^.typ := OPT.inttyp END ;
    IF x^.typ^.comp = Array THEN typ := x^.typ^.BaseTyp;
      IF (y^.class = Nconst) & ((y^.conval^.intval < 0) OR (y^.conval^.intval >= x^.typ^.n)) THEN err(81) END
    ELSIF x^.typ^.comp = DynArr THEN typ := x^.typ^.BaseTyp;
      IF (y^.class = Nconst) & (y^.conval^.intval < 0) THEN err(81) END
    ELSE err(82); typ := OPT.undftyp
    END ;
    BindNodes(Nindex, typ, x, y); x^.readonly := x^.left^.readonly
  END Index;
  
  PROCEDURE Field*(VAR x: OPT.Node; y: OPT.Object);
  BEGIN (*x^.typ^.comp = Record*)
    IF x^.class >= Nconst THEN err(77) END ;
    IF (y # NIL) & (y^.mode IN {Fld, TProc}) THEN
      BindNodes(Nfield, y^.typ, x, NIL); x^.obj := y;
      x^.readonly := x^.left^.readonly OR ((y^.vis = externalR) & (y^.mnolev < 0))
    ELSE err(83); x^.typ := OPT.undftyp
    END
  END Field;
  
  PROCEDURE TypTest*(VAR x: OPT.Node; obj: OPT.Object; guard: BOOLEAN);

    PROCEDURE GTT(t0, t1: OPT.Struct);
      VAR node: OPT.Node; t: OPT.Struct;
    BEGIN t := t0;
      WHILE (t # NIL) & (t # t1) & (t # OPT.undftyp) DO t := t^.BaseTyp END ;
      IF t # t1 THEN
        WHILE (t1 # NIL) & (t1 # t0) & (t1 # OPT.undftyp) DO t1 := t1^.BaseTyp END ;
        IF (t1 = t0) OR (t0.form = Undef (*SYSTEM.PTR*)) THEN
          IF guard THEN BindNodes(Nguard, NIL, x, NIL); x^.readonly := x^.left^.readonly
          ELSE node := OPT.NewNode(Nmop); node^.subcl := is; node^.left := x;
            node^.obj := obj; x := node
          END
        ELSE err(85)
        END
      ELSIF t0 # t1 THEN err(85)  (* prevent down guard *)
      ELSIF ~guard THEN
        IF x^.class = Nguard THEN  (* cannot skip guard *)
          node := OPT.NewNode(Nmop); node^.subcl := is; node^.left := x;
          node^.obj := obj; x := node
        ELSE x := NewBoolConst(TRUE)
        END
      END
    END GTT;

  BEGIN
    IF NotVar(x) THEN err(112)
    ELSIF x^.typ^.form = Pointer THEN
      IF (x^.typ^.BaseTyp^.comp # Record) & (x^.typ # OPT.sysptrtyp) THEN err(85)
      ELSIF obj^.typ^.form = Pointer THEN GTT(x^.typ^.BaseTyp, obj^.typ^.BaseTyp)
      ELSE err(86)
      END
    ELSIF (x^.typ^.comp = Record) & (x^.class = Nvarpar) & (obj^.typ^.comp = Record) THEN
      GTT(x^.typ, obj^.typ)
    ELSE err(87)
    END ;
    IF guard THEN x^.typ := obj^.typ ELSE x^.typ := OPT.booltyp END
  END TypTest;
  
  PROCEDURE In*(VAR x: OPT.Node; y: OPT.Node);
    VAR f: INTEGER; k: LONGINT;
  BEGIN f := x^.typ^.form;
    IF (x^.class = Ntype) OR (x^.class = Nproc) OR (y^.class = Ntype) OR (y^.class = Nproc) THEN err(126)
    ELSIF (f IN intSet) & (y^.typ^.form = Set) THEN
      IF x^.class = Nconst THEN
        k := x^.conval^.intval;
        IF (k < 0) OR (k > OPM.MaxSet) THEN err(202)
        ELSIF y^.class = Nconst THEN x^.conval^.intval := BoolToInt(k IN y^.conval^.setval); x^.obj := NIL
        ELSE BindNodes(Ndop, OPT.booltyp, x, y); x^.subcl := in
        END
      ELSE BindNodes(Ndop, OPT.booltyp, x, y); x^.subcl := in
      END
    ELSE err(92)
    END ;
    x^.typ := OPT.booltyp
  END In;

  PROCEDURE log(x: LONGINT): LONGINT;
  BEGIN exp := 0;
    IF x > 0 THEN
      WHILE ~ODD(x) DO x := x DIV 2; INC(exp) END
    END ;
    RETURN x
  END log;

  PROCEDURE CheckRealType(f, nr: INTEGER; x: OPT.Const);
    VAR min, max, r: LONGREAL;
  BEGIN
    IF f = Real THEN min := OPM.MinReal; max := OPM.MaxReal
    ELSE min := OPM.MinLReal; max := OPM.MaxLReal
    END ;
    r := ABS(x^.realval);
    IF (r > max) OR (r < min) THEN
        err(nr); x^.realval := 1.0
    ELSIF f = Real THEN x^.realval := SHORT(x^.realval)  (* single precision only *)
    END ;
    x^.intval := OPM.ConstNotAlloc
  END CheckRealType;
  
  PROCEDURE MOp*(op: SHORTINT; VAR x: OPT.Node);
    VAR f: INTEGER; typ: OPT.Struct; z: OPT.Node;
    
    PROCEDURE NewOp(op: SHORTINT; typ: OPT.Struct; z: OPT.Node): OPT.Node;
      VAR node: OPT.Node;
    BEGIN
      node := OPT.NewNode(Nmop); node^.subcl := op; node^.typ := typ;
      node^.left := z; RETURN node
    END NewOp;

  BEGIN z := x;
    IF (z^.class = Ntype) OR (z^.class = Nproc) THEN err(126)
    ELSE typ := z^.typ; f := typ^.form;
      CASE op OF
        not:
          IF f = Bool THEN
            IF z^.class = Nconst THEN
              z^.conval^.intval := BoolToInt(~IntToBool(z^.conval^.intval)); z^.obj := NIL
            ELSE z := NewOp(op, typ, z)
            END
          ELSE err(98)
          END
      | plus:
          IF ~(f IN intSet + realSet) THEN err(96) END
      | minus:
          IF f IN intSet + realSet +{Set}THEN
            IF z^.class = Nconst THEN
              IF f IN intSet THEN
                IF z^.conval^.intval = MIN(LONGINT) THEN err(203)
                ELSE z^.conval^.intval := -z^.conval^.intval; SetIntType(z)
                END
              ELSIF f IN realSet THEN z^.conval^.realval := -z^.conval^.realval
              ELSE z^.conval^.setval := -z^.conval^.setval
              END ;
              z^.obj := NIL
            ELSE z := NewOp(op, typ, z)
            END
          ELSE err(97)
          END
      | abs:
          IF f IN intSet + realSet THEN
            IF z^.class = Nconst THEN
              IF f IN intSet THEN
                IF z^.conval^.intval = MIN(LONGINT) THEN err(203)
                ELSE z^.conval^.intval := ABS(z^.conval^.intval); SetIntType(z)
                END
              ELSE z^.conval^.realval := ABS(z^.conval^.realval)
              END ;
              z^.obj := NIL
            ELSE z := NewOp(op, typ, z)
            END
          ELSE err(111)
          END
      | cap:
          IF f = Char THEN
            IF z^.class = Nconst THEN
              z^.conval^.intval := ORD(CAP(CHR(z^.conval^.intval))); z^.obj := NIL
            ELSE z := NewOp(op, typ, z)
            END
          ELSE err(111); z^.typ := OPT.chartyp
          END
      | odd:
          IF f IN intSet THEN
            IF z^.class = Nconst THEN
              z^.conval^.intval := BoolToInt(ODD(z^.conval^.intval)); z^.obj := NIL
            ELSE z := NewOp(op, typ, z)
            END
          ELSE err(111)
          END ;
          z^.typ := OPT.booltyp
      | adr: (*SYSTEM.ADR*)
		  IF (z^.class = Nconst) & (f = Char) & (z^.conval^.intval >= 20H) THEN
		    CharToString(z); f := String
		  END ;
          IF (z^.class < Nconst) OR (f = String) THEN z := NewOp(op, typ, z)
          ELSE err(127)
          END ;
          z^.typ := OPT.linttyp
      | cc: (*SYSTEM.CC*)
          IF (f IN intSet) & (z^.class = Nconst) THEN
            IF (0 <= z^.conval^.intval) & (z^.conval^.intval <= OPM.MaxCC) THEN z := NewOp(op, typ, z) ELSE err(219) END
          ELSE err(69)
          END ;
          z^.typ := OPT.booltyp
      ELSE
         OPM.LogWStr("unhandled case in OPB.MOp, op = "); OPM.LogWNum(op, 0); OPM.LogWLn;
      END
    END ;
    x := z
  END MOp;
  
  PROCEDURE CheckPtr(x, y: OPT.Node);
    VAR g: INTEGER; p, q, t: OPT.Struct;
  BEGIN g := y^.typ^.form;
    IF g = Pointer THEN
      p := x^.typ^.BaseTyp; q := y^.typ^.BaseTyp;
      IF (p^.comp = Record) & (q^.comp = Record) THEN
        IF p^.extlev < q^.extlev THEN t := p; p := q; q := t END ;
        WHILE (p # q) & (p # NIL) & (p # OPT.undftyp) DO p := p^.BaseTyp END ;
        IF p = NIL THEN err(100) END
      ELSE err(100)
      END
    ELSIF g # NilTyp THEN err(100)
    END
  END CheckPtr;

  PROCEDURE CheckParameters*(fp, ap: OPT.Object; checkNames: BOOLEAN);
    VAR ft, at: OPT.Struct;
  BEGIN
    WHILE fp # NIL DO
      IF ap # NIL THEN
        ft := fp^.typ; at := ap^.typ;
        WHILE (ft^.comp = DynArr) & (at^.comp = DynArr) DO
          ft := ft^.BaseTyp; at := at^.BaseTyp
        END ;
        IF ft # at THEN
          IF (ft^.form = ProcTyp) & (at^.form = ProcTyp) THEN
            IF ft^.BaseTyp = at^.BaseTyp THEN CheckParameters(ft^.link, at^.link, FALSE)
            ELSE err(117)
            END
          ELSE err(115)
          END
        END ;
        IF (fp^.mode # ap^.mode) OR checkNames & (fp^.name # ap^.name) THEN err(115) END ;
        ap := ap^.link
      ELSE err(116)
      END ;
      fp := fp^.link
    END ;
    IF ap # NIL THEN err(116) END
  END CheckParameters;

  PROCEDURE CheckProc(x: OPT.Struct; y: OPT.Object);  (* proc var x := proc y, check compatibility *)
  BEGIN
    IF y^.mode IN {XProc, IProc, LProc} THEN
      IF y^.mode = LProc THEN
        IF y^.mnolev = 0 THEN y^.mode := XProc
        ELSE err(73)
        END
      END ;
      IF x^.BaseTyp = y^.typ THEN CheckParameters(x^.link, y^.link, FALSE)
      ELSE err(117)
      END
    ELSE err(113)
    END
  END CheckProc;

  PROCEDURE ConstOp(op: INTEGER; x, y: OPT.Node);
    VAR f, g: INTEGER; xval, yval: OPT.Const; xv, yv: LONGINT;
        temp: BOOLEAN; (* temp avoids err 215 *)

    PROCEDURE ConstCmp(): INTEGER;
      VAR res: INTEGER;
    BEGIN
      CASE f OF
        Undef:
          res := eql
      | Byte, Char..LInt(*,Int8..Int64*):
          IF xval^.intval < yval^.intval THEN res := lss
          ELSIF xval^.intval > yval^.intval THEN res := gtr
          ELSE res := eql
          END
      | Real, LReal:
          IF xval^.realval < yval^.realval THEN res := lss
          ELSIF xval^.realval > yval^.realval THEN res := gtr
          ELSE res := eql
          END
      | Bool:
          IF xval^.intval # yval^.intval THEN res := neq
          ELSE res := eql
          END
      | Set:
          IF xval^.setval # yval^.setval THEN res := neq
          ELSE res := eql
          END
      | String:
          IF xval^.ext^ < yval^.ext^ THEN res := lss
          ELSIF xval^.ext^ > yval^.ext^ THEN res := gtr
          ELSE res := eql
          END
      | NilTyp, Pointer, ProcTyp:
          IF xval^.intval # yval^.intval THEN res := neq
          ELSE res := eql
          END
      ELSE
         OPM.LogWStr("unhandled case in OPB.ConstCmp, f = "); OPM.LogWNum(f, 0); OPM.LogWLn;
      END ;
      x^.typ := OPT.booltyp; RETURN res
    END ConstCmp;

  BEGIN
    f := x^.typ^.form; g := y^.typ^.form; xval := x^.conval; yval := y^.conval;
    IF f # g THEN
      CASE f OF
        Char:
          IF g = String THEN CharToString(x)
          ELSE err(100); y^.typ := x^.typ; yval^ := xval^
          END ;
      | SInt(*, Int8*):
          IF g IN intSet THEN x^.typ := y^.typ
          ELSIF g = Real THEN x^.typ := OPT.realtyp; xval^.realval := xval^.intval
          ELSIF g = LReal THEN x^.typ := OPT.lrltyp; xval^.realval := xval^.intval
          ELSE  err(100); y^.typ := x^.typ; yval^ := xval^
          END
      | Int(*, Int16, Int32, Int64*):
          IF g = SInt THEN y^.typ := OPT.inttyp
          ELSIF g IN intSet THEN x^.typ := y^.typ
          ELSIF g = Real THEN x^.typ := OPT.realtyp; xval^.realval := xval^.intval
          ELSIF g = LReal THEN x^.typ := OPT.lrltyp; xval^.realval := xval^.intval
          ELSE  err(100); y^.typ := x^.typ; yval^ := xval^
          END
      | LInt:
          IF g IN intSet THEN y^.typ := OPT.linttyp
          ELSIF g = Real THEN x^.typ := OPT.realtyp; xval^.realval := xval^.intval
          ELSIF g = LReal THEN x^.typ := OPT.lrltyp; xval^.realval := xval^.intval
          ELSE  err(100); y^.typ := x^.typ; yval^ := xval^
          END
      | Real:
          IF g IN intSet THEN y^.typ := x^.typ; yval^.realval := yval^.intval
          ELSIF g = LReal THEN x^.typ := OPT.lrltyp
          ELSE  err(100); y^.typ := x^.typ; yval^ := xval^
          END
      | LReal:
          IF g IN intSet THEN y^.typ := x^.typ; yval^.realval := yval^.intval
          ELSIF g = Real THEN y^.typ := OPT.lrltyp
          ELSE  err(100); y^.typ := x^.typ; yval^ := xval^
          END
      | String:
          IF g = Char THEN CharToString(y); g := String
          ELSE err(100); y^.typ := x^.typ; yval^ := xval^
          END ;
      | NilTyp:
          IF ~(g IN {Pointer, ProcTyp}) THEN err(100) END
      | Pointer:
          CheckPtr(x, y)
      | ProcTyp:
          IF g # NilTyp THEN err(100) END
      ELSE err(100); y^.typ := x^.typ; yval^ := xval^
      END ;
      f := x^.typ^.form
    END ;  (* {x^.typ = y^.typ} *)
    CASE op OF
      times:
        IF f IN intSet THEN xv := xval^.intval; yv := yval^.intval;
          IF (xv = 0) OR (yv = 0) OR  (* division with negative numbers is not defined *)
            (xv > 0) & (yv > 0) & (yv <= MAX(LONGINT) DIV xv) OR
            (xv > 0) & (yv < 0) & (yv >= MIN(LONGINT) DIV xv) OR
            (xv < 0) & (yv > 0) & (xv >= MIN(LONGINT) DIV yv) OR
            (xv < 0) & (yv < 0) & (xv # MIN(LONGINT)) & (yv # MIN(LONGINT)) & (-xv <= MAX(LONGINT) DIV (-yv)) THEN
            xval^.intval := xv * yv; SetIntType(x)
          ELSE err(204)
          END
        ELSIF f IN realSet THEN
          temp := ABS(yval^.realval) <= 1.0;
          IF temp OR (ABS(xval^.realval) <= MAX(LONGREAL) / ABS(yval^.realval)) THEN
            xval^.realval := xval^.realval * yval^.realval; CheckRealType(f, 204, xval)
          ELSE err(204)
          END
        ELSIF f = Set THEN
          xval^.setval := xval^.setval * yval^.setval
        ELSIF f # Undef THEN err(101)
        END
    | slash:
        IF f IN intSet THEN
          IF yval^.intval # 0 THEN
            xval^.realval := xval^.intval / yval^.intval; CheckRealType(Real, 205, xval)
          ELSE err(205); xval^.realval := 1.0
          END ;
          x^.typ := OPT.realtyp
        ELSIF f IN realSet THEN
          temp := ABS(yval^.realval) >= 1.0;
          IF temp OR (ABS(xval^.realval) <= MAX(LONGREAL) * ABS(yval^.realval)) THEN
            xval^.realval := xval^.realval / yval^.realval; CheckRealType(f, 205, xval)
          ELSE err(205)
          END
        ELSIF f = Set THEN
          xval^.setval := xval^.setval / yval^.setval
        ELSIF f # Undef THEN err(102)
        END
    | div:
        IF f IN intSet THEN
          IF yval^.intval # 0 THEN
            xval^.intval := xval^.intval DIV yval^.intval; SetIntType(x)
          ELSE err(205)
          END
        ELSIF f # Undef THEN err(103)
        END
    | mod:
        IF f IN intSet THEN
          IF yval^.intval # 0 THEN
            xval^.intval := xval^.intval MOD yval^.intval; SetIntType(x)
          ELSE err(205)
          END
        ELSIF f # Undef THEN err(104)
        END
    | and:
        IF f = Bool THEN
          xval^.intval := BoolToInt(IntToBool(xval^.intval) & IntToBool(yval^.intval))
        ELSE err(94)
        END
    | plus:
        IF f IN intSet THEN
          temp := (yval^.intval >= 0) & (xval^.intval <= MAX(LONGINT) - yval^.intval);
          IF temp OR (yval^.intval < 0) & (xval^.intval >= MIN(LONGINT) - yval^.intval) THEN 
              INC(xval^.intval, yval^.intval); SetIntType(x)
          ELSE err(206)
          END
        ELSIF f IN realSet THEN
          temp := (yval^.realval >= 0.0) & (xval^.realval <= MAX(LONGREAL) - yval^.realval);
          IF temp OR (yval^.realval < 0.0) & (xval^.realval >= -MAX(LONGREAL) - yval^.realval) THEN
              xval^.realval := xval^.realval + yval^.realval; CheckRealType(f, 206, xval)
          ELSE err(206)
          END
        ELSIF f = Set THEN
          xval^.setval := xval^.setval + yval^.setval
        ELSIF f # Undef THEN err(105)
        END
    | minus:
        IF f IN intSet THEN
          IF (yval^.intval >= 0) & (xval^.intval >= MIN(LONGINT) + yval^.intval) OR
            (yval^.intval < 0) & (xval^.intval <= MAX(LONGINT) + yval^.intval) THEN 
              DEC(xval^.intval, yval^.intval); SetIntType(x)
          ELSE err(207)
          END
        ELSIF f IN realSet THEN
          temp := (yval^.realval >= 0.0) & (xval^.realval >= -MAX(LONGREAL) + yval^.realval);
          IF temp OR (yval^.realval < 0.0) & (xval^.realval <= MAX(LONGREAL) + yval^.realval) THEN
              xval^.realval := xval^.realval - yval^.realval; CheckRealType(f, 207, xval)
          ELSE err(207)
          END
        ELSIF f = Set THEN
          xval^.setval := xval^.setval - yval^.setval
        ELSIF f # Undef THEN err(106)
        END
    | or:
        IF f = Bool THEN
          xval^.intval := BoolToInt(IntToBool(xval^.intval) OR IntToBool(yval^.intval))
        ELSE err(95)
        END
    | eql:
        xval^.intval := BoolToInt(ConstCmp() = eql)
    | neq:
        xval^.intval := BoolToInt(ConstCmp() # eql)
    | lss:
        IF f IN {Bool, Set, NilTyp, Pointer} THEN err(108)
        ELSE xval^.intval := BoolToInt(ConstCmp() = lss)
        END
    | leq:
        IF f IN {Bool, Set, NilTyp, Pointer} THEN err(108)
        ELSE xval^.intval := BoolToInt(ConstCmp() # gtr)
        END
    | gtr:
        IF f IN {Bool, Set, NilTyp, Pointer} THEN err(108)
        ELSE xval^.intval := BoolToInt(ConstCmp() = gtr)
        END
    | geq:
        IF f IN {Bool, Set, NilTyp, Pointer} THEN err(108)
        ELSE xval^.intval := BoolToInt(ConstCmp() # lss)
        END
    ELSE
       OPM.LogWStr("unhandled case in OPB.ConstOp, op = "); OPM.LogWNum(op, 0); OPM.LogWLn;
    END
  END ConstOp;

  PROCEDURE Convert(VAR x: OPT.Node; typ: OPT.Struct);
    VAR node: OPT.Node; f, g: INTEGER; k: LONGINT; r: LONGREAL;
  BEGIN f := x^.typ^.form; g := typ^.form;
    IF x^.class = Nconst THEN
      IF f IN intSet THEN
        IF g IN intSet THEN
          IF f > g THEN SetIntType(x);
            IF x^.typ^.form > g THEN err(203); x^.conval^.intval := 1 END
          END
        ELSIF g IN realSet THEN x^.conval^.realval := x^.conval^.intval; x^.conval^.intval := OPM.ConstNotAlloc
        ELSE (*g = Char*) k := x^.conval^.intval;
          IF (0 > k) OR (k > 0FFH) THEN err(220) END
        END
      ELSIF f IN realSet THEN
        IF g IN realSet THEN CheckRealType(g, 203, x^.conval)
        ELSE (*g = LInt*)
          r := x^.conval^.realval;
          IF (r < MIN(LONGINT)) OR (r > MAX(LONGINT)) THEN err(203); r := 1 END ;
          x^.conval^.intval := ENTIER(r); SetIntType(x)
        END
      ELSE (* (f IN {Char, Byte}) & (g IN {Byte} + intSet) OR (f = Undef) *)
      END ;
      x^.obj := NIL
    ELSIF (x^.class = Nmop) & (x^.subcl = conv) & ((x^.left^.typ^.form < f) OR (f > g)) THEN
      (* don't create new node *)
      IF x^.left^.typ = typ THEN (* and suppress existing node *) x := x^.left END
    ELSE node := OPT.NewNode(Nmop); node^.subcl := conv; node^.left := x; x := node
    END ;
    x^.typ := typ
  END Convert;

  PROCEDURE Op*(op: SHORTINT; VAR x: OPT.Node; y: OPT.Node);
    VAR f, g: INTEGER; t, z: OPT.Node; typ: OPT.Struct; do: BOOLEAN; val: LONGINT;

    PROCEDURE NewOp(op: SHORTINT; typ: OPT.Struct; VAR x: OPT.Node; y: OPT.Node);
      VAR node: OPT.Node;
    BEGIN
      node := OPT.NewNode(Ndop); node^.subcl := op; node^.typ := typ;
      node^.left := x; node^.right := y; x := node
    END NewOp;

    PROCEDURE strings(VAR x, y: OPT.Node): BOOLEAN;
      VAR ok, xCharArr, yCharArr: BOOLEAN;
    BEGIN
      xCharArr := ((x^.typ^.comp IN {Array, DynArr}) & (x^.typ^.BaseTyp^.form=Char)) OR (f=String);
      yCharArr := (((y^.typ^.comp IN {Array, DynArr}) & (y^.typ^.BaseTyp^.form=Char)) OR (g=String));
      IF xCharArr & (g = Char) & (y^.class = Nconst) THEN CharToString(y); g := String; yCharArr := TRUE END ;
      IF yCharArr & (f = Char) & (x^.class = Nconst) THEN CharToString(x); f := String; xCharArr := TRUE END ;
      ok := xCharArr & yCharArr;
      IF ok THEN  (* replace ""-string compare with 0X-char compare, if possible *)
        IF (f=String) & (x^.conval^.intval2 = 1) THEN  (* y is array of char *)
          x^.typ := OPT.chartyp; x^.conval^.intval := 0;
          Index(y, NewIntConst(0))
        ELSIF (g=String) & (y^.conval^.intval2 = 1) THEN  (* x is array of char *)
          y^.typ := OPT.chartyp; y^.conval^.intval := 0;
          Index(x, NewIntConst(0))
        END
      END ;
      RETURN ok
    END strings;


  BEGIN z := x;
    IF (z^.class = Ntype) OR (z^.class = Nproc) OR (y^.class = Ntype) OR (y^.class = Nproc) THEN err(126)
    ELSIF (z^.class = Nconst) & (y^.class = Nconst) THEN ConstOp(op, z, y); z^.obj := NIL
    ELSE
      IF z^.typ # y^.typ THEN
        g := y^.typ^.form;
        CASE z^.typ^.form OF
           Char:
            IF z^.class = Nconst THEN CharToString(z) ELSE err(100) END
        | SInt(*, Int8*):
            IF g IN intSet + realSet THEN Convert(z, y^.typ)
            ELSE  err(100)
            END
        | Int:
            IF g = SInt THEN Convert(y, z^.typ)
            ELSIF g IN intSet + realSet THEN Convert(z, y^.typ)
            ELSE  err(100)
            END
        | LInt(*, Int16, Int32, Int64*):
            IF g IN intSet THEN Convert(y, z^.typ)
            ELSIF g IN realSet THEN Convert(z, y^.typ)
            ELSE  err(100)
            END
        | Real:
            IF g IN intSet THEN Convert(y, z^.typ)
            ELSIF g IN realSet THEN Convert(z, y^.typ)
            ELSE  err(100)
            END
        | LReal:
            IF g IN intSet + realSet THEN Convert(y, z^.typ)
            ELSIF g IN realSet THEN Convert(y, z^.typ)
            ELSE  err(100)
            END
        | NilTyp:
            IF ~(g IN {Pointer, ProcTyp}) THEN err(100) END
        | Pointer:
            CheckPtr(z, y)
        | ProcTyp:
            IF g # NilTyp THEN err(100) END
        | String:
        | Comp:
            IF z^.typ^.comp = Record THEN err(100) END
        ELSE err(100)
        END
      END ;  (* {z^.typ = y^.typ} *)
      typ := z^.typ; f := typ^.form; g := y^.typ^.form;
      CASE op OF
        times:
          do := TRUE;
          IF f IN intSet THEN
            IF z^.class = Nconst THEN val := z^.conval^.intval;
              IF val = 1 THEN do := FALSE; z := y
              ELSIF val = 0 THEN do := FALSE
              ELSIF log(val) = 1 THEN
                t := y; y := z; z := t;
                op := ash; y^.typ := OPT.sinttyp; y^.conval^.intval := exp; y^.obj := NIL
              END
            ELSIF y^.class = Nconst THEN val := y^.conval^.intval;
              IF val = 1 THEN do := FALSE
              ELSIF val = 0 THEN do := FALSE; z := y
              ELSIF log(val) = 1 THEN
                op := ash; y^.typ := OPT.sinttyp; y^.conval^.intval := exp; y^.obj := NIL
              END
            END
          ELSIF ~(f IN {Undef, Real..Set}) THEN err(105); typ := OPT.undftyp
          END ;
          IF do THEN NewOp(op, typ, z, y) END
      | slash:
          IF f IN intSet THEN
            IF (y^.class = Nconst) & (y^.conval^.intval = 0) THEN err(205) END ;
            Convert(z, OPT.realtyp); Convert(y, OPT.realtyp);
            typ := OPT.realtyp
          ELSIF f IN realSet THEN
            IF (y^.class = Nconst) & (y^.conval^.realval = 0.0) THEN err(205) END
          ELSIF (f # Set) & (f # Undef) THEN err(102); typ := OPT.undftyp
          END ;
          NewOp(op, typ, z, y)
      | div:
          do := TRUE;
          IF f IN intSet THEN
            IF y^.class = Nconst THEN val := y^.conval^.intval;
              IF val = 0 THEN err(205)
              ELSIF val = 1 THEN do := FALSE
              ELSIF log(val) = 1 THEN
                op := ash; y^.typ := OPT.sinttyp; y^.conval^.intval := -exp; y^.obj := NIL
              END
            END
          ELSIF f # Undef THEN err(103); typ := OPT.undftyp
          END ;
          IF do THEN NewOp(op, typ, z, y) END
      | mod:
          IF f IN intSet THEN
            IF y^.class = Nconst THEN
              IF y^.conval^.intval = 0 THEN err(205)
              ELSIF log(y^.conval^.intval) = 1 THEN
                op := msk; y^.conval^.intval := ASH(-1, exp); y^.obj := NIL
              END
            END
          ELSIF f # Undef THEN err(104); typ := OPT.undftyp
          END ;
          NewOp(op, typ, z, y)
      | and:
          IF f = Bool THEN
            IF z^.class = Nconst THEN
              IF IntToBool(z^.conval^.intval) THEN z := y END
            ELSIF (y^.class = Nconst) & IntToBool(y^.conval^.intval) THEN (* optimize z & TRUE -> z *)
        (*  ELSIF (y^.class = Nconst) & ~IntToBool(y^.conval^.intval) THEN
              don't optimize z & FALSE -> FALSE: side effects possible  *)
            ELSE NewOp(op, typ, z, y)
            END
          ELSIF f # Undef THEN err(94); z^.typ := OPT.undftyp
          END
      | plus:
          IF ~(f IN {Undef, SInt..Set(*, Int8..Int64*)}) THEN err(105); typ := OPT.undftyp END ;
          do := TRUE;
          IF f IN intSet THEN
            IF (z^.class = Nconst) & (z^.conval^.intval = 0) THEN do := FALSE; z := y END ;
            IF (y^.class = Nconst) & (y^.conval^.intval = 0) THEN do := FALSE END
          END ;
          IF do THEN NewOp(op, typ, z, y) END
      | minus:
          IF ~(f IN {Undef, SInt..Set(*, Int8..Int64*)}) THEN err(106); typ := OPT.undftyp END ;
          IF ~(f IN intSet) OR (y^.class # Nconst) OR (y^.conval^.intval # 0) THEN NewOp(op, typ, z, y) END
      | or:
          IF f = Bool THEN
            IF z^.class = Nconst THEN
              IF ~IntToBool(z^.conval^.intval) THEN z := y END
            ELSIF (y^.class = Nconst) & ~IntToBool(y^.conval^.intval) THEN (* optimize z OR FALSE -> z *)
        (*  ELSIF (y^.class = Nconst) & IntToBool(y^.conval^.intval) THEN
              don't optimize z OR TRUE -> TRUE: side effects possible  *)
            ELSE NewOp(op, typ, z, y)
            END
          ELSIF f # Undef THEN err(95); z^.typ := OPT.undftyp
          END
      | eql, neq:
          IF (f IN {Undef..Set, NilTyp, Pointer, ProcTyp(*, Int8..Int64*)}) OR strings(z, y) THEN typ := OPT.booltyp
          ELSE err(107); typ := OPT.undftyp
          END ;
          NewOp(op, typ, z, y)
      | lss, leq, gtr, geq:
          IF (f IN {Undef, Char..LReal(*, Int8..Int64*)}) OR strings(z, y) THEN typ := OPT.booltyp
          ELSE
	     OPM.LogWLn; OPM.LogWStr("ELSE in Op()"); OPM.LogWLn;
	     err(108); typ := OPT.undftyp
          END ;
          NewOp(op, typ, z, y)
      ELSE
         OPM.LogWStr("unhandled case in OPB.Op, op = "); OPM.LogWNum(op, 0); OPM.LogWLn;
      END
    END ;
    x := z
  END Op;

  PROCEDURE SetRange*(VAR x: OPT.Node; y: OPT.Node);
    VAR k, l: LONGINT;
  BEGIN
    IF (x^.class = Ntype) OR (x^.class = Nproc) OR (y^.class = Ntype) OR (y^.class = Nproc) THEN err(126)  
    ELSIF (x^.typ^.form IN intSet) & (y^.typ^.form IN intSet) THEN
      IF x^.class = Nconst THEN
        k := x^.conval^.intval;
        IF (0 > k) OR (k > OPM.MaxSet) THEN err(202) END
      END ;
      IF y^.class = Nconst THEN
        l := y^.conval^.intval;
        IF (0 > l) OR (l > OPM.MaxSet) THEN err(202) END
      END ;
      IF (x^.class = Nconst) & (y^.class = Nconst) THEN
        IF k <= l THEN
          x^.conval^.setval := {k..l}
        ELSE err(201); x^.conval^.setval := {l..k}
        END ;
        x^.obj := NIL
      ELSE BindNodes(Nupto, OPT.settyp, x, y)
      END
    ELSE err(93)
    END ;
    x^.typ := OPT.settyp
  END SetRange;

  PROCEDURE SetElem*(VAR x: OPT.Node);
    VAR k: LONGINT;
  BEGIN
    IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
    ELSIF ~(x^.typ^.form IN intSet) THEN err(93)
    ELSIF x^.class = Nconst THEN
      k := x^.conval^.intval;
      IF (0 <= k) & (k <= OPM.MaxSet) THEN x^.conval^.setval := {k}
      ELSE err(202)
      END ;
      x^.obj := NIL
    ELSE Convert(x, OPT.settyp)
    END ;
    x^.typ := OPT.settyp
  END SetElem;
  
  PROCEDURE CheckAssign(x: OPT.Struct; ynode: OPT.Node);  (* x := y *)
    VAR f, g: INTEGER; y, p, q: OPT.Struct;
  BEGIN
    IF OPM.Verbose THEN
       OPM.LogWLn; OPM.LogWStr("PROCEDURE CheckAssign"); OPM.LogWLn;
    END;
    y := ynode^.typ; f := x^.form; g := y^.form;
    IF OPM.Verbose THEN
       OPM.LogWStr("y.form = "); OPM.LogWNum(y.form, 0); OPM.LogWLn;
       OPM.LogWStr("f = "); OPM.LogWNum(f, 0); OPM.LogWLn;
       OPM.LogWStr("g = "); OPM.LogWNum(g, 0); OPM.LogWLn;
       OPM.LogWStr("ynode.typ.syze = "); OPM.LogWNum(ynode.typ.size, 0); OPM.LogWLn;
    END;
    IF (ynode^.class = Ntype) OR (ynode^.class = Nproc) & (f # ProcTyp) THEN err(126) END ;
    CASE f OF
      Undef, String:
   (* | Int8:
        IF (ynode.typ.size > OPM.Int8Size) THEN 
	   IF OPM.Verbose THEN OPM.LogWStr("f of int8"); OPM.LogWLn END;
	   err(113) 
	END
    | Int16:
        IF (ynode.typ.size > OPM.Int16Size) THEN 
	   IF OPM.Verbose THEN OPM.LogWStr("f of int16"); OPM.LogWLn END;
	   err(113) 
	END
    | Int32:
        IF (ynode.typ.size > OPM.Int32Size) THEN 
	   IF OPM.Verbose THEN OPM.LogWStr("f of int32"); OPM.LogWLn END;
	   err(113) 
	END
    | Int64:
        IF ynode.typ.size > OPM.Int64Size THEN 
	   IF OPM.Verbose THEN OPM.LogWStr("f of int64"); OPM.LogWLn END;
	   err(113) 
	END*)
    | Byte:
        IF ~(g IN {Byte, Char, SInt}) THEN err(113) END
    | Bool, Char, SInt, Set:
        IF g # f THEN err(113) END
    | Int:
        IF ~(g IN {SInt, Int}) THEN err(113) END
    | LInt:
        IF OPM.LIntSize = 4 THEN
	   IF ~(g IN {SInt, Int, LInt(*, Int8, Int16, Int32*)}) THEN err(113) END
	ELSE (* assume OPM.LIntSize = 8 *)
           IF ~(g IN {SInt, Int, LInt(*, Int8, Int16, Int32, Int64*)}) THEN err(113) END
	END;
    | Real:
        IF ~(g IN {SInt..Real}) THEN err(113) END
    | LReal:
        IF ~(g IN {SInt..LReal}) THEN err(113) END
    | Pointer:
        IF (x = y) OR (g = NilTyp) OR (x = OPT.sysptrtyp) & (g = Pointer) THEN (* ok *)
        ELSIF g = Pointer THEN
          p := x^.BaseTyp; q := y^.BaseTyp;
          IF (p^.comp = Record) & (q^.comp = Record) THEN
            WHILE (q # p) & (q # NIL) & (q # OPT.undftyp) DO q := q^.BaseTyp END ;
            IF q = NIL THEN err(113) END
          ELSE err(113)
          END
        ELSE err(113)
        END
    | ProcTyp:
        IF ynode^.class = Nproc THEN CheckProc(x, ynode^.obj)
        ELSIF (x = y) OR (g = NilTyp) THEN (* ok *)
        ELSE err(113)
        END
    | NoTyp, NilTyp:
        err(113)
    | Comp:
        x^.pvused := TRUE;  (* idfp of y guarantees assignment compatibility with x *)
        IF x^.comp = Array THEN
          IF (ynode^.class = Nconst) & (g = Char) THEN CharToString(ynode); y := ynode^.typ; g := String END ;
          IF x = y THEN (* ok *)
          ELSIF (g = String) & (x^.BaseTyp = OPT.chartyp) THEN (*check length of string*)
            IF ynode^.conval^.intval2 > x^.n THEN err(114) END ;
          ELSE err(113)
          END
        ELSIF x^.comp = Record THEN
          IF x = y THEN (* ok *)
          ELSIF y^.comp = Record THEN
            q := y^.BaseTyp;
            WHILE (q # NIL) & (q # x) & (q # OPT.undftyp) DO q := q^.BaseTyp END ;
            IF q = NIL THEN err(113) END
          ELSE err(113)
          END
        ELSE (*DynArr*) err(113)
        END
    ELSE (* In case of not estimated f it would crash -- noch *)
       OPM.LogWStr("unhandled case in OPB.CheckAssign, f = "); OPM.LogWNum(f, 0); OPM.LogWLn;
    END ;
    IF (ynode^.class = Nconst) & (g < f) & (g IN {SInt..Real}) & (f IN {Int..LReal}) THEN
      Convert(ynode, x)
    END
  END CheckAssign;
  
  PROCEDURE CheckLeaf(x: OPT.Node; dynArrToo: BOOLEAN);
  BEGIN
(*
avoid unnecessary intermediate variables in voc 

    IF (x^.class = Nmop) & (x^.subcl = val) THEN x := x^.left END ;
    IF x^.class = Nguard THEN x := x^.left END ;  (* skip last (and unique) guard *)
    IF (x^.class = Nvar) & (dynArrToo OR (x^.typ^.comp # DynArr)) THEN x^.obj^.leaf := FALSE END
*)
  END CheckLeaf;
  
  PROCEDURE StPar0*(VAR par0: OPT.Node; fctno: INTEGER);  (* par0: first param of standard proc *)
    VAR f: INTEGER; typ: OPT.Struct; x: OPT.Node;
  BEGIN x := par0; f := x^.typ^.form;
    CASE fctno OF
      haltfn: (*HALT*)
        IF (f IN intSet) & (x^.class = Nconst) THEN
          IF (OPM.MinHaltNr <= x^.conval^.intval) & (x^.conval^.intval <= OPM.MaxHaltNr) THEN
            BindNodes(Ntrap, OPT.notyp, x, x)
          ELSE err(218)
          END
        ELSE err(69)
        END ;
        x^.typ := OPT.notyp
    | newfn: (*NEW*)
        typ := OPT.notyp;
        IF NotVar(x) THEN err(112)
        ELSIF f = Pointer THEN
          IF OPM.NEWusingAdr THEN CheckLeaf(x, TRUE) END ;
          IF x^.readonly THEN err(76) END ;
          f := x^.typ^.BaseTyp^.comp;
          IF f IN {Record, DynArr, Array} THEN
            IF f = DynArr THEN typ := x^.typ^.BaseTyp END ;
            BindNodes(Nassign, OPT.notyp, x, NIL); x^.subcl := newfn
          ELSE err(111)
          END
        ELSE err(111)
        END ;
        x^.typ := typ
    | absfn: (*ABS*)
        MOp(abs, x)
    | capfn: (*CAP*)
        MOp(cap, x)
    | ordfn: (*ORD*) 
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f = Char THEN Convert(x, OPT.inttyp)
        ELSE err(111)
        END ;
        x^.typ := OPT.inttyp
    | entierfn: (*ENTIER*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f IN realSet THEN Convert(x, OPT.linttyp)
        ELSE err(111)
        END ;
        x^.typ := OPT.linttyp
    | oddfn: (*ODD*)
        MOp(odd, x)
    | minfn: (*MIN*)
        IF x^.class = Ntype THEN
          CASE f OF
            Bool:  x := NewBoolConst(FALSE)
          | Char:  x := NewIntConst(0); x^.typ := OPT.chartyp
          | SInt:  x := NewIntConst(OPM.MinSInt)
          | Int:   x := NewIntConst(OPM.MinInt)
          | LInt:  x := NewIntConst(OPM.MinLInt)
	 (* | Int8:  x := NewIntConst(OPM.MinInt8)
	  | Int16: x := NewIntConst(OPM.MinInt16)
	  | Int32: x := NewIntConst(OPM.MinInt32)
	  | Int64: err(111)(*x := NewIntConst(OPM.MinInt64)*) (* int64 constants not implemented yet *)*)
          | Set:   x := NewIntConst(0); x^.typ := OPT.inttyp
          | Real:  x := NewRealConst(OPM.MinReal, OPT.realtyp)
          | LReal: x := NewRealConst(OPM.MinLReal, OPT.lrltyp)
          ELSE err(111)
          END
        ELSE err(110)
        END
    | maxfn: (*MAX*)
        IF x^.class = Ntype THEN
          CASE f OF
            Bool:  x := NewBoolConst(TRUE)
          | Char:  x := NewIntConst(0FFH); x^.typ := OPT.chartyp
          | SInt:  x := NewIntConst(OPM.MaxSInt)
          | Int:   x := NewIntConst(OPM.MaxInt)
          | LInt:  x := NewIntConst(OPM.MaxLInt)
	 (* | Int8:  x := NewIntConst(OPM.MaxInt8)
	  | Int16: x := NewIntConst(OPM.MaxInt16)
	  | Int32: x := NewIntConst(OPM.MaxInt32)
	  | Int64: err(111); (*x := NewIntConst(OPM.MaxInt64)*) (* int64 contstants not implemented yet *)*)
          | Set:   x := NewIntConst(OPM.MaxSet); x^.typ := OPT.inttyp
          | Real:  x := NewRealConst(OPM.MaxReal, OPT.realtyp)
          | LReal: x := NewRealConst(OPM.MaxLReal, OPT.lrltyp)
          ELSE err(111)
          END
        ELSE err(110)
        END
    | chrfn: (*CHR*) 
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f IN {Undef, SInt..LInt(*, Int8..Int64*)} THEN Convert(x, OPT.chartyp)
        ELSE err(111); x^.typ := OPT.chartyp
        END
    | shortfn: (*SHORT*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f = Int THEN Convert(x, OPT.sinttyp)
        ELSIF f = LInt THEN Convert(x, OPT.inttyp)
        (*ELSIF f = Int64 THEN Convert(x, OPT.int32typ)
        ELSIF f = Int32 THEN Convert(x, OPT.int16typ)
        ELSIF f = Int16 THEN Convert(x, OPT.int8typ)*)
        ELSIF f = LReal THEN Convert(x, OPT.realtyp)
        ELSE err(111)
        END
    | longfn: (*LONG*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f = SInt THEN Convert(x, OPT.inttyp)
        ELSIF f = Int THEN Convert(x, OPT.linttyp)
        (*ELSIF f = Int8 THEN Convert(x, OPT.int16typ)
        ELSIF f = Int16 THEN Convert(x, OPT.int32typ)
        ELSIF f = Int32 THEN Convert(x, OPT.int64typ)*)
        ELSIF f = Real THEN Convert(x, OPT.lrltyp)
        ELSIF f = Char THEN Convert(x, OPT.linttyp)
        ELSE err(111)
        END
    | incfn, decfn: (*INC, DEC*) 
        IF NotVar(x) THEN err(112)
        ELSIF ~(f IN intSet) THEN err(111)
        ELSIF x^.readonly THEN err(76)
        END
    | inclfn, exclfn: (*INCL, EXCL*)
        IF NotVar(x) THEN err(112)
        ELSIF x^.typ # OPT.settyp THEN err(111); x^.typ := OPT.settyp
        ELSIF x^.readonly THEN err(76)
        END
    | lenfn: (*LEN*)
        IF ~(x^.typ^.comp IN {DynArr, Array}) THEN err(131) END
    | copyfn: (*COPY*)
        IF (x^.class = Nconst) & (f = Char) THEN CharToString(x); f := String END ;
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF (~(x^.typ^.comp IN {DynArr, Array}) OR (x^.typ^.BaseTyp^.form # Char))
           & (f # String) THEN err(111)
        END
    | ashfn: (*ASH*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f IN intSet THEN
          IF f # LInt THEN Convert(x, OPT.linttyp) END
        ELSE err(111); x^.typ := OPT.linttyp
        END
    | adrfn: (*SYSTEM.ADR*)
        CheckLeaf(x, FALSE); MOp(adr, x)
    | sizefn: (*SIZE*)
        IF x^.class # Ntype THEN err(110); x := NewIntConst(1)
        ELSIF (f IN {Byte..Set(*, Int8..Int64*), Pointer, ProcTyp}) OR (x^.typ^.comp IN {Array, Record}) THEN
          typSize(x^.typ); x^.typ^.pvused := TRUE; x := NewIntConst(x^.typ^.size)
        ELSE err(111); x := NewIntConst(1)
        END
    | ccfn: (*SYSTEM.CC*)
        MOp(cc, x)
    | lshfn, rotfn: (*SYSTEM.LSH, SYSTEM.ROT*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF ~(f IN intSet + {Byte, Char, Set(*, Int8, Int16, Int32, Int64*)}) THEN err(111)
        END
    | getfn, putfn, bitfn, movefn: (*SYSTEM.GET, SYSTEM.PUT, SYSTEM.BIT, SYSTEM.MOVE*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF (x^.class = Nconst) & (f IN {SInt, Int}) THEN Convert(x, OPT.linttyp)
        ELSIF ~(f IN {LInt, Pointer}) THEN err(111); x^.typ := OPT.linttyp
        END
    | getrfn, putrfn: (*SYSTEM.GETREG, SYSTEM.PUTREG*)
        IF (f IN intSet) & (x^.class = Nconst) THEN
          IF (x^.conval^.intval < OPM.MinRegNr) OR (x^.conval^.intval > OPM.MaxRegNr) THEN err(220) END
        ELSE err(69)
        END
    | valfn: (*SYSTEM.VAL*)
        IF x^.class # Ntype THEN err(110)
        ELSIF (f IN {Undef, String, NoTyp}) OR (x^.typ^.comp = DynArr) THEN err(111)
        END
    | sysnewfn: (*SYSTEM.NEW*)
        IF NotVar(x) THEN err(112)
        ELSIF f = Pointer THEN
          IF OPM.NEWusingAdr THEN CheckLeaf(x, TRUE) END
        ELSE err(111)
        END
    | assertfn: (*ASSERT*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126); x := NewBoolConst(FALSE)
        ELSIF f # Bool THEN err(120); x := NewBoolConst(FALSE)
        ELSE MOp(not, x)
        END
    ELSE
       OPM.LogWStr("unhandled case in OPB.StPar0, fctno = "); OPM.LogWNum(fctno, 0); OPM.LogWLn;
    END ;
    par0 := x
  END StPar0;

  PROCEDURE StPar1*(VAR par0: OPT.Node; x: OPT.Node; fctno: SHORTINT);  (* x: second parameter of standard proc *)
    VAR f, L: INTEGER; typ: OPT.Struct; p, t: OPT.Node;
    
    PROCEDURE NewOp(class, subcl: SHORTINT; left, right: OPT.Node): OPT.Node;
      VAR node: OPT.Node;
    BEGIN
      node := OPT.NewNode(class); node^.subcl := subcl;
      node^.left := left; node^.right := right; RETURN node
    END NewOp;
    
  BEGIN p := par0; f := x^.typ^.form;
    CASE fctno OF
      incfn, decfn: (*INC DEC*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126); p^.typ := OPT.notyp
        ELSE
          IF x^.typ # p^.typ THEN
            IF (x^.class = Nconst) & (f IN intSet) THEN Convert(x, p^.typ)
            ELSE err(111)
            END
          END ;
          p := NewOp(Nassign, fctno, p, x);
          p^.typ := OPT.notyp
        END
    | inclfn, exclfn: (*INCL, EXCL*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f IN intSet THEN
          IF (x^.class = Nconst) & ((0 > x^.conval^.intval) OR (x^.conval^.intval > OPM.MaxSet)) THEN err(202)
          END ;
          p := NewOp(Nassign, fctno, p, x)
        ELSE err(111)
        END ;
        p^.typ := OPT.notyp
    | lenfn: (*LEN*)
        IF ~(f IN intSet) OR (x^.class # Nconst) THEN err(69)
        ELSIF f = SInt THEN
          L := SHORT(x^.conval^.intval); typ := p^.typ;
          WHILE (L > 0) & (typ^.comp IN {DynArr, Array}) DO typ := typ^.BaseTyp; DEC(L) END ;
          IF (L # 0) OR ~(typ^.comp IN {DynArr, Array}) THEN err(132)
          ELSE x^.obj := NIL;
            IF typ^.comp = DynArr THEN
              WHILE p^.class = Nindex DO p := p^.left; INC(x^.conval^.intval) END ;  (* possible side effect ignored *)
              p := NewOp(Ndop, len, p, x); p^.typ := OPT.linttyp
            ELSE p := x; p^.conval^.intval := typ^.n; SetIntType(p)
            END
          END
        ELSE err(132)
        END
    | copyfn: (*COPY*)
        IF NotVar(x) THEN err(112)
        ELSIF (x^.typ^.comp IN {Array, DynArr}) & (x^.typ^.BaseTyp^.form = Char) THEN
          IF x^.readonly THEN err(76) END ;
          t := x; x := p; p := t; p := NewOp(Nassign, copyfn, p, x)
        ELSE err(111)
        END ;
        p^.typ := OPT.notyp
    | ashfn: (*ASH*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f IN intSet THEN
          IF (p^.class = Nconst) & (x^.class = Nconst) THEN
            IF (-maxExp > x^.conval^.intval) OR (x^.conval^.intval > maxExp) THEN err(208); p^.conval^.intval := 1
            ELSIF x^.conval^.intval >= 0 THEN
              IF ABS(p^.conval^.intval) <= MAX(LONGINT) DIV ASH(1, x^.conval^.intval) THEN
                p^.conval^.intval := p^.conval^.intval * ASH(1, x^.conval^.intval)
              ELSE err(208); p^.conval^.intval := 1
              END
            ELSE p^.conval^.intval := ASH(p^.conval^.intval, x^.conval^.intval)
            END ;
            p^.obj := NIL
          ELSE p := NewOp(Ndop, ash, p, x); p^.typ := OPT.linttyp
          END
        ELSE err(111)
        END
    | newfn: (*NEW(p, x...)*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF p^.typ^.comp = DynArr THEN
          IF f IN intSet THEN
            IF (x^.class = Nconst) & ((x^.conval^.intval <= 0) OR (x^.conval^.intval > OPM.MaxIndex)) THEN err(63) END
          ELSE err(111)
          END ;
          p^.right := x; p^.typ := p^.typ^.BaseTyp
        ELSE err(64)
        END
    | lshfn, rotfn: (*SYSTEM.LSH, SYSTEM.ROT*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF ~(f IN intSet) THEN err(111)
        ELSE
          IF fctno = lshfn THEN p := NewOp(Ndop, lsh, p, x) ELSE p := NewOp(Ndop, rot, p, x) END ;
          p^.typ := p^.left^.typ
        END
    | getfn, putfn, getrfn, putrfn: (*SYSTEM.GET, SYSTEM.PUT, SYSTEM.GETREG, SYSTEM.PUTREG*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f IN {Undef..Set, Pointer, ProcTyp} THEN
          IF (fctno = getfn) OR (fctno = getrfn) THEN
            IF NotVar(x) THEN err(112) END ;
            t := x; x := p; p := t
          END ;
          p := NewOp(Nassign, fctno, p, x)
        ELSE err(111)
        END ;
        p^.typ := OPT.notyp
    | bitfn: (*SYSTEM.BIT*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f IN intSet THEN
          p := NewOp(Ndop, bit, p, x)
        ELSE err(111)
        END ;
        p^.typ := OPT.booltyp
    | valfn: (*SYSTEM.VAL*)  (* type is changed without considering the byte ordering on the target machine *)
        IF (x^.class = Ntype) OR (x^.class = Nproc) OR
          (f IN {Undef, String, NoTyp}) OR (x^.typ^.comp = DynArr) THEN err(126)
        END ;
        t := OPT.NewNode(Nmop); t^.subcl := val; t^.left := x; x := t;
(*
        IF (x^.class >= Nconst) OR ((f IN realSet) # (p^.typ^.form IN realSet)) THEN
          t := OPT.NewNode(Nmop); t^.subcl := val; t^.left := x; x := t
        ELSE x^.readonly := FALSE
        END ;
*)
        x^.typ := p^.typ; p := x
    | sysnewfn: (*SYSTEM.NEW*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF f IN intSet THEN
          p := NewOp(Nassign, sysnewfn, p, x)
        ELSE err(111)
        END ;
        p^.typ := OPT.notyp
    | movefn: (*SYSTEM.MOVE*)
        IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
        ELSIF (x^.class = Nconst) & (f IN {SInt, Int}) THEN Convert(x, OPT.linttyp)
        ELSIF ~(f IN {LInt, Pointer}) THEN err(111); x^.typ := OPT.linttyp
        END ;
        p^.link := x
    | assertfn: (*ASSERT*)
        IF (f IN intSet) & (x^.class = Nconst) THEN
          IF (OPM.MinHaltNr <= x^.conval^.intval) & (x^.conval^.intval <= OPM.MaxHaltNr) THEN
            BindNodes(Ntrap, OPT.notyp, x, x);
            x^.conval := OPT.NewConst(); x^.conval^.intval := OPM.errpos;
            Construct(Nif, p, x); p^.conval := OPT.NewConst(); p^.conval^.intval := OPM.errpos;
            Construct(Nifelse, p, NIL); OptIf(p);
            IF p = NIL THEN  (* ASSERT(TRUE) *)
            ELSIF p^.class = Ntrap THEN err(99)
            ELSE p^.subcl := assertfn
            END
          ELSE err(218)
          END
        ELSE err(69)
        END
    ELSE err(64)
    END ;
    par0 := p
  END StPar1;

  PROCEDURE StParN*(VAR par0: OPT.Node; x: OPT.Node; fctno, n: INTEGER);  (* x: n+1-th param of standard proc *)
    VAR node: OPT.Node; f: INTEGER; p: OPT.Node;
  BEGIN p := par0; f := x^.typ^.form;
    IF fctno = newfn THEN (*NEW(p, ..., x...*)
      IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
      ELSIF p^.typ^.comp # DynArr THEN err(64)
      ELSIF f IN intSet THEN
        IF (x^.class = Nconst) & ((x^.conval^.intval <= 0) OR (x^.conval^.intval > OPM.MaxIndex)) THEN err(63) END ;
        node := p^.right; WHILE node^.link # NIL DO node := node^.link END;
        node^.link := x; p^.typ := p^.typ^.BaseTyp
      ELSE err(111)
      END
    ELSIF (fctno = movefn) & (n = 2) THEN (*SYSTEM.MOVE*)
      IF (x^.class = Ntype) OR (x^.class = Nproc) THEN err(126)
      ELSIF f IN intSet THEN
        node := OPT.NewNode(Nassign); node^.subcl := movefn; node^.right := p;
        node^.left := p^.link; p^.link := x; p := node
      ELSE err(111)
      END ;
      p^.typ := OPT.notyp
    ELSE err(64)
    END ;
    par0 := p
  END StParN;

  PROCEDURE StFct*(VAR par0: OPT.Node; fctno: SHORTINT; parno: INTEGER);
    VAR dim: INTEGER; x, p: OPT.Node;
  BEGIN p := par0;
    IF fctno <= ashfn THEN
      IF (fctno = newfn) & (p^.typ # OPT.notyp) THEN
        IF p^.typ^.comp = DynArr THEN err(65) END ;
        p^.typ := OPT.notyp
      ELSIF fctno <= sizefn THEN (* 1 param *)
        IF parno < 1 THEN err(65) END
      ELSE (* more than 1 param *)
        IF ((fctno = incfn) OR (fctno = decfn)) & (parno = 1) THEN (*INC, DEC*)
          BindNodes(Nassign, OPT.notyp, p, NewIntConst(1)); p^.subcl := fctno; p^.right^.typ := p^.left^.typ
        ELSIF (fctno = lenfn) & (parno = 1) THEN (*LEN*)
          IF p^.typ^.comp = DynArr THEN dim := 0;
            WHILE p^.class = Nindex DO p := p^.left; INC(dim) END ;  (* possible side effect ignored *)
            BindNodes(Ndop, OPT.linttyp, p, NewIntConst(dim)); p^.subcl := len
          ELSE
            p := NewIntConst(p^.typ^.n)
          END
        ELSIF parno < 2 THEN err(65)
        END
      END
    ELSIF fctno = assertfn THEN
      IF parno = 1 THEN x := NIL;
        BindNodes(Ntrap, OPT.notyp, x, NewIntConst(AssertTrap));
        x^.conval := OPT.NewConst(); x^.conval^.intval := OPM.errpos;
        Construct(Nif, p, x); p^.conval := OPT.NewConst(); p^.conval^.intval := OPM.errpos;
        Construct(Nifelse, p, NIL); OptIf(p);
        IF p = NIL THEN  (* ASSERT(TRUE) *)
        ELSIF p^.class = Ntrap THEN err(99)
        ELSE p^.subcl := assertfn
        END
      ELSIF parno < 1 THEN err(65)
      END
    ELSE (*SYSTEM*)
      IF (parno < 1) OR
        (fctno > ccfn) & (parno < 2) OR
        (fctno = movefn) & (parno < 3) THEN err(65)
      END
    END ;
    par0 := p
  END StFct;
  
  PROCEDURE DynArrParCheck(ftyp, atyp: OPT.Struct; fvarpar: BOOLEAN);
    VAR f: INTEGER;
  BEGIN (* ftyp^.comp = DynArr *)
    f := atyp^.comp; ftyp := ftyp^.BaseTyp; atyp := atyp^.BaseTyp;
    IF fvarpar & (ftyp = OPT.bytetyp) THEN (* ok, but ... *)
      IF ~(f IN {Array, DynArr}) OR ~(atyp^.form IN {Byte..SInt(*, Int8..Int64*)}) THEN err(-301) END (* ... warning 301 *)
    ELSIF f IN {Array, DynArr} THEN
      IF ftyp^.comp = DynArr THEN DynArrParCheck(ftyp, atyp, fvarpar)
      ELSIF ftyp # atyp THEN
        IF ~fvarpar & (ftyp.form = Pointer) & (atyp.form = Pointer) THEN
          ftyp := ftyp^.BaseTyp; atyp := atyp^.BaseTyp;
          IF (ftyp^.comp = Record) & (atyp^.comp = Record) THEN
            WHILE (ftyp # atyp) & (atyp # NIL) & (atyp # OPT.undftyp) DO atyp := atyp^.BaseTyp END ;
            IF atyp = NIL THEN err(113) END
          ELSE err(66)
          END
        ELSE err(66)
        END
      END ;
    ELSE err(67)
    END
  END DynArrParCheck;

  PROCEDURE CheckReceiver(VAR x: OPT.Node; fp: OPT.Object);
  BEGIN
    IF fp^.typ^.form = Pointer THEN
      IF x^.class = Nderef THEN x := x^.left (*undo DeRef*) ELSE (*x^.typ^.comp = Record*) err(71) END
    END
  END CheckReceiver;
  
  PROCEDURE PrepCall*(VAR x: OPT.Node; VAR fpar: OPT.Object);
  BEGIN
    IF (x^.obj # NIL) & (x^.obj^.mode IN {LProc, XProc, TProc, CProc}) THEN
      fpar := x^.obj^.link;
      IF x^.obj^.mode = TProc THEN CheckReceiver(x^.left, fpar); fpar := fpar^.link END
    ELSIF (x^.class # Ntype) & (x^.typ # NIL) & (x^.typ^.form = ProcTyp) THEN
      fpar := x^.typ^.link
    ELSE err(121); fpar := NIL; x^.typ := OPT.undftyp
    END
  END PrepCall;

  PROCEDURE Param*(ap: OPT.Node; fp: OPT.Object);
    VAR q: OPT.Struct;
  BEGIN
    IF fp.typ.form # Undef THEN
      IF fp^.mode = VarPar THEN
        IF NotVar(ap) THEN err(122)
        ELSE CheckLeaf(ap, FALSE)
        END ;
        IF ap^.readonly THEN err(76) END ;
        IF fp^.typ^.comp = DynArr THEN DynArrParCheck(fp^.typ, ap^.typ, TRUE)
        ELSIF (fp^.typ^.comp = Record) & (ap^.typ^.comp = Record) THEN
          q := ap^.typ;
          WHILE (q # fp^.typ) & (q # NIL) & (q # OPT.undftyp) DO q := q^.BaseTyp END ;
          IF q = NIL THEN err(111) END
        ELSIF (fp^.typ = OPT.sysptrtyp) & (ap^.typ^.form = Pointer) THEN (* ok *)
        ELSIF (ap^.typ # fp^.typ) & ~((fp^.typ^.form = Byte) & (ap^.typ^.form IN {Char, SInt})) THEN err(123)
        ELSIF (fp^.typ^.form = Pointer) & (ap^.class = Nguard) THEN err(123)
        END
      ELSIF fp^.typ^.comp = DynArr THEN
        IF (ap^.class = Nconst) & (ap^.typ^.form = Char) THEN CharToString(ap) END ;
        IF (ap^.typ^.form = String) & (fp^.typ^.BaseTyp^.form = Char) THEN (* ok *)
        ELSIF ap^.class >= Nconst THEN err(59)
        ELSE DynArrParCheck(fp^.typ, ap^.typ, FALSE)
        END
      ELSE CheckAssign(fp^.typ, ap)
      END
    END
  END Param;
  
  PROCEDURE StaticLink*(dlev: SHORTINT);
    VAR scope: OPT.Object;
  BEGIN
    scope := OPT.topScope;
    WHILE dlev > 0 DO DEC(dlev);
      INCL(scope^.link^.conval^.setval, slNeeded);
      scope := scope^.left
    END
  END StaticLink;

  PROCEDURE Call*(VAR x: OPT.Node; apar: OPT.Node; fp: OPT.Object);
    VAR typ: OPT.Struct; p: OPT.Node; lev: SHORTINT;
  BEGIN
    IF x^.class = Nproc THEN typ := x^.typ;
      lev := x^.obj^.mnolev;
      IF lev > 0 THEN StaticLink(OPT.topScope^.mnolev-lev) END ;
      IF x^.obj^.mode = IProc THEN err(121) END
    ELSIF (x^.class = Nfield) & (x^.obj^.mode = TProc) THEN typ := x^.typ;
      x^.class := Nproc; p := x^.left; x^.left := NIL; p^.link := apar; apar := p; fp := x^.obj^.link
    ELSE typ := x^.typ^.BaseTyp
    END ;
    BindNodes(Ncall, typ, x, apar); x^.obj := fp
  END Call;

  PROCEDURE Enter*(VAR procdec: OPT.Node; stat: OPT.Node; proc: OPT.Object);
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(Nenter); x^.typ := OPT.notyp; x^.obj := proc;
    x^.left := procdec; x^.right := stat; procdec := x
  END Enter;
  
  PROCEDURE Return*(VAR x: OPT.Node; proc: OPT.Object);
    VAR node: OPT.Node;
  BEGIN
    IF proc = NIL THEN (* return from module *)
      IF x # NIL THEN err(124) END
    ELSE
      IF x # NIL THEN CheckAssign(proc^.typ, x)
      ELSIF proc^.typ # OPT.notyp THEN err(124)
      END
    END ;
    node := OPT.NewNode(Nreturn); node^.typ := OPT.notyp; node^.obj := proc; node^.left := x; x := node
  END Return;

  PROCEDURE Assign*(VAR x: OPT.Node; y: OPT.Node);
    VAR z: OPT.Node;
  BEGIN
    IF x^.class >= Nconst THEN err(56) END ;
    CheckAssign(x^.typ, y);
    IF x^.readonly THEN err(76) END ;
    IF x^.typ^.comp = Record THEN
      IF x^.class = Nguard THEN z := x^.left ELSE z := x END ;
      IF (z^.class = Nderef) & (z^.left^.class = Nguard) THEN
        z^.left := z^.left^.left  (* skip guard before dereferencing *)
      END ;
      IF (x^.typ^.strobj # NIL) & ((z^.class = Nderef) OR (z^.class = Nvarpar)) THEN
        BindNodes(Neguard, x^.typ, z, NIL); x := z
      END
    ELSIF (x^.typ^.comp = Array) & (x^.typ^.BaseTyp = OPT.chartyp) &
        (y^.typ^.form = String) & (y^.conval^.intval2 = 1) THEN  (* replace array := "" with array[0] := 0X *)
      y^.typ := OPT.chartyp; y^.conval^.intval := 0;
      Index(x, NewIntConst(0))
    END ;
    BindNodes(Nassign, OPT.notyp, x, y); x^.subcl := assign
  END Assign;
  
  PROCEDURE Inittd*(VAR inittd, last: OPT.Node; typ: OPT.Struct);
    VAR node: OPT.Node;
  BEGIN
    node := OPT.NewNode(Ninittd); node^.typ := typ;
    node^.conval := OPT.NewConst(); node^.conval^.intval := typ^.txtpos;
    IF inittd = NIL THEN inittd := node ELSE last^.link := node END ;
    last := node
  END Inittd;
  
BEGIN
  maxExp := log(MAX(LONGINT) DIV 2 + 1); maxExp := exp
END OPB.
