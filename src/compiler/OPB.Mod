MODULE OPB;  (* RC 6.3.89 / 21.2.94 *)  (* object model 17.1.93 *)
(* build parse tree *)

  IMPORT OPT, OPS, OPM, SYSTEM;


  CONST
    AssertTrap = 0;  (* default trap number *)


  VAR
    typSize*: PROCEDURE(typ: OPT.Struct);
    exp:      INTEGER;  (*side effect of log*)
    maxExp:   LONGINT;  (* max n in ASH(1, n) on this machine *)


  PROCEDURE err(n: INTEGER);
  BEGIN OPM.err(n)
  END err;


  PROCEDURE NewLeaf*(obj: OPT.Object): OPT.Node;
    VAR node: OPT.Node;
  BEGIN
    CASE obj^.mode OF
    | OPM.Var:    node := OPT.NewNode(OPM.Nvar);
                  node^.readonly := (obj^.vis = OPM.externalR) & (obj^.mnolev < 0)
    | OPM.VarPar: node := OPT.NewNode(OPM.Nvarpar)
    | OPM.Con:    node := OPT.NewNode(OPM.Nconst);
                  node^.conval := OPT.NewConst();
                  node^.conval^ := obj^.conval^  (* string is not copied, only its ref *)
    | OPM.Typ:    node := OPT.NewNode(OPM.Ntype)
    | OPM.LProc
    ..OPM.IProc:  node := OPT.NewNode(OPM.Nproc)
    ELSE          node := OPT.NewNode(OPM.Nvar); err(127)
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
    x := OPT.NewNode(OPM.Nconst); x^.typ := OPT.booltyp;
    x^.conval := OPT.NewConst(); x^.conval^.intval := BoolToInt(boolval); RETURN x
  END NewBoolConst;

  PROCEDURE OptIf*(VAR x: OPT.Node);  (* x^.link = NIL *)
    VAR if, pred: OPT.Node;
  BEGIN
    if := x^.left;
    WHILE if^.left^.class = OPM.Nconst DO
      IF IntToBool(if^.left^.conval^.intval) THEN x := if^.right; RETURN
      ELSIF if^.link = NIL THEN x := x^.right; RETURN
      ELSE if := if^.link; x^.left := if
      END
    END ;
    pred := if; if := if^.link;
    WHILE if # NIL DO
      IF if^.left^.class = OPM.Nconst THEN
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
    x := OPT.NewNode(OPM.Nconst); x^.typ := OPT.niltyp;
    x^.conval := OPT.NewConst(); x^.conval^.intval := OPM.nilval; RETURN x
  END Nil;

  PROCEDURE EmptySet*(): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(OPM.Nconst); x^.typ := OPT.settyp;
    x^.conval := OPT.NewConst(); x^.conval^.setval := {}; RETURN x
  END EmptySet;


  (* Integer size support *)

  PROCEDURE SignedByteSize(n: LONGINT): INTEGER;
  (* Returns number of bytes required to represent signed value n *)
    VAR b: INTEGER;
  BEGIN
    IF n < 0 THEN n := -(n+1) END; (* Positive value in the range 0 - 7F.. *)
    b := 1; WHILE (b < 8) & (ASH(n, -(8*b-1)) # 0) DO INC(b) END;
    RETURN b
  END SignedByteSize;

  PROCEDURE ShorterSize(i: LONGINT): LONGINT;
  BEGIN IF i >= OPM.LIntSize THEN RETURN OPM.IntSize ELSE RETURN OPM.SIntSize END
  END ShorterSize;

  PROCEDURE LongerSize(i: LONGINT): LONGINT;
  BEGIN IF i <= OPM.SIntSize THEN RETURN OPM.IntSize ELSE RETURN OPM.LIntSize END
  END LongerSize;

  PROCEDURE IntType(size: LONGINT): OPT.Struct;
  (* Selects smallest standard integer type for given size in bytes *)
    VAR result: OPT.Struct;
  BEGIN
    IF    size <= OPT.sinttyp.size THEN result := OPT.sinttyp
    ELSIF size <= OPT.inttyp.size  THEN result := OPT.inttyp
    ELSE
      result := OPT.linttyp
    END;
    IF size > OPT.linttyp.size THEN err(203) END; (* Number too large *)
    RETURN result
  END IntType;

  PROCEDURE SetIntType(node: OPT.Node);
  BEGIN node.typ := IntType(SignedByteSize(node.conval.intval))
  END SetIntType;

  PROCEDURE NewIntConst*(intval: LONGINT): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(OPM.Nconst);  x^.conval := OPT.NewConst();
    x^.conval^.intval := intval; SetIntType(x); RETURN x
  END NewIntConst;

  PROCEDURE NewRealConst*(realval: LONGREAL; typ: OPT.Struct): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(OPM.Nconst); x^.conval := OPT.NewConst();
    x^.conval^.realval := realval; x^.typ := typ; x^.conval^.intval := OPM.ConstNotAlloc;
    RETURN x
  END NewRealConst;

  PROCEDURE NewString*(VAR str: OPS.String; len: LONGINT): OPT.Node;
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(OPM.Nconst); x^.conval := OPT.NewConst(); x^.typ := OPT.stringtyp;
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
  BEGIN RETURN (x^.class >= OPM.Nconst) & ((x^.class # OPM.Nmop) OR (x^.subcl # OPM.val) OR (x^.left^.class >= OPM.Nconst))
  END NotVar;

  PROCEDURE DeRef*(VAR x: OPT.Node);
    VAR strobj, bstrobj: OPT.Object; typ, btyp: OPT.Struct;
  BEGIN
    typ := x^.typ;
    IF x^.class >= OPM.Nconst THEN err(78)
    ELSIF typ^.form = OPM.Pointer THEN
      IF typ = OPT.sysptrtyp THEN err(57) END ;
      btyp := typ^.BaseTyp; strobj := typ^.strobj; bstrobj := btyp^.strobj;
      IF (strobj # NIL) & (strobj^.name # "") & (bstrobj # NIL) & (bstrobj^.name # "") THEN
        btyp^.pbused := TRUE
      END ;
      BindNodes(OPM.Nderef, btyp, x, NIL)
    ELSE err(84)
    END
  END DeRef;

  PROCEDURE Index*(VAR x: OPT.Node; y: OPT.Node);
    VAR f: INTEGER; typ: OPT.Struct;
  BEGIN
    f := y^.typ^.form;
    IF x^.class >= OPM.Nconst THEN err(79)
    ELSIF ~(f IN OPM.intSet) OR (y^.class IN {OPM.Nproc, OPM.Ntype}) THEN err(80); y^.typ := OPT.inttyp END ;
    IF x^.typ^.comp = OPM.Array THEN typ := x^.typ^.BaseTyp;
      IF (y^.class = OPM.Nconst) & ((y^.conval^.intval < 0) OR (y^.conval^.intval >= x^.typ^.n)) THEN err(81) END
    ELSIF x^.typ^.comp = OPM.DynArr THEN typ := x^.typ^.BaseTyp;
      IF (y^.class = OPM.Nconst) & (y^.conval^.intval < 0) THEN err(81) END
    ELSE err(82); typ := OPT.undftyp
    END ;
    BindNodes(OPM.Nindex, typ, x, y); x^.readonly := x^.left^.readonly
  END Index;

  PROCEDURE Field*(VAR x: OPT.Node; y: OPT.Object);
  BEGIN (*x^.typ^.comp = OPM.Record*)
    IF x^.class >= OPM.Nconst THEN err(77) END ;
    IF (y # NIL) & (y^.mode IN {OPM.Fld, OPM.TProc}) THEN
      BindNodes(OPM.Nfield, y^.typ, x, NIL); x^.obj := y;
      x^.readonly := x^.left^.readonly OR ((y^.vis = OPM.externalR) & (y^.mnolev < 0))
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
        IF (t1 = t0) OR (t0.form = OPM.Undef (*SYSTEM.PTR*)) THEN
          IF guard THEN BindNodes(OPM.Nguard, NIL, x, NIL); x^.readonly := x^.left^.readonly
          ELSE node := OPT.NewNode(OPM.Nmop); node^.subcl := OPM.is; node^.left := x;
            node^.obj := obj; x := node
          END
        ELSE err(85)
        END
      ELSIF t0 # t1 THEN err(85)  (* prevent down guard *)
      ELSIF ~guard THEN
        IF x^.class = OPM.Nguard THEN  (* cannot skip guard *)
          node := OPT.NewNode(OPM.Nmop); node^.subcl := OPM.is; node^.left := x;
          node^.obj := obj; x := node
        ELSE x := NewBoolConst(TRUE)
        END
      END
    END GTT;

  BEGIN
    IF NotVar(x) THEN err(112)
    ELSIF x^.typ^.form = OPM.Pointer THEN
      IF (x^.typ^.BaseTyp^.comp # OPM.Record) & (x^.typ # OPT.sysptrtyp) THEN err(85)
      ELSIF obj^.typ^.form = OPM.Pointer THEN GTT(x^.typ^.BaseTyp, obj^.typ^.BaseTyp)
      ELSE err(86)
      END
    ELSIF (x^.typ^.comp = OPM.Record) & (x^.class = OPM.Nvarpar) & (obj^.typ^.comp = OPM.Record) THEN
      GTT(x^.typ, obj^.typ)
    ELSE err(87)
    END ;
    IF guard THEN x^.typ := obj^.typ ELSE x^.typ := OPT.booltyp END
  END TypTest;

  PROCEDURE In*(VAR x: OPT.Node; y: OPT.Node);
    VAR f: INTEGER; k: LONGINT;
  BEGIN f := x^.typ^.form;
    IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) OR (y^.class = OPM.Ntype) OR (y^.class = OPM.Nproc) THEN err(126)
    ELSIF (f IN OPM.intSet) & (y^.typ^.form = OPM.Set) THEN
      IF x^.class = OPM.Nconst THEN
        k := x^.conval^.intval;
        IF (k < 0) OR (k > OPM.MaxSet) THEN err(202)
        ELSIF y^.class = OPM.Nconst THEN x^.conval^.intval := BoolToInt(k IN y^.conval^.setval); x^.obj := NIL
        ELSE BindNodes(OPM.Ndop, OPT.booltyp, x, y); x^.subcl := OPM.in
        END
      ELSE BindNodes(OPM.Ndop, OPT.booltyp, x, y); x^.subcl := OPM.in
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
    IF f = OPM.Real THEN min := OPM.MinReal; max := OPM.MaxReal
    ELSE min := OPM.MinLReal; max := OPM.MaxLReal
    END ;
    r := ABS(x^.realval);
    IF (r > max) OR (r < min) THEN
        err(nr); x^.realval := 1.0
    ELSIF f = OPM.Real THEN x^.realval := SHORT(x^.realval)  (* single precision only *)
    END ;
    x^.intval := OPM.ConstNotAlloc
  END CheckRealType;

  PROCEDURE MOp*(op: SHORTINT; VAR x: OPT.Node);
    VAR f: INTEGER; typ: OPT.Struct; z: OPT.Node;

    PROCEDURE NewOp(op: SHORTINT; typ: OPT.Struct; z: OPT.Node): OPT.Node;
      VAR node: OPT.Node;
    BEGIN
      node := OPT.NewNode(OPM.Nmop); node^.subcl := op; node^.typ := typ;
      node^.left := z; RETURN node
    END NewOp;

  BEGIN z := x;
    IF (z^.class = OPM.Ntype) OR (z^.class = OPM.Nproc) THEN err(126)
    ELSE typ := z^.typ; f := typ^.form;
      CASE op OF
      |OPM.not:   IF f = OPM.Bool THEN
                    IF z^.class = OPM.Nconst THEN
                      z^.conval^.intval := BoolToInt(~IntToBool(z^.conval^.intval)); z^.obj := NIL
                    ELSE z := NewOp(op, typ, z)
                    END
                  ELSE err(98)
                  END
      |OPM.plus:  IF ~(f IN OPM.intSet + OPM.realSet) THEN err(96) END
      |OPM.minus: IF f IN OPM.intSet + OPM.realSet +{OPM.Set}THEN
                    IF z^.class = OPM.Nconst THEN
                      IF f IN OPM.intSet THEN
                        IF z^.conval^.intval = MIN(LONGINT) THEN err(203)
                        ELSE z^.conval^.intval := -z^.conval^.intval; SetIntType(z)
                        END
                      ELSIF f IN OPM.realSet THEN z^.conval^.realval := -z^.conval^.realval
                      ELSE z^.conval^.setval := -z^.conval^.setval
                      END ;
                      z^.obj := NIL
                    ELSE z := NewOp(op, typ, z)
                    END
                  ELSE err(97)
                  END
      |OPM.abs:   IF f IN OPM.intSet + OPM.realSet THEN
                    IF z^.class = OPM.Nconst THEN
                      IF f IN OPM.intSet THEN
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
      |OPM.cap:   IF f = OPM.Char THEN
                    IF z^.class = OPM.Nconst THEN
                      z^.conval^.intval := ORD(CAP(CHR(z^.conval^.intval))); z^.obj := NIL
                    ELSE z := NewOp(op, typ, z)
                    END
                  ELSE err(111); z^.typ := OPT.chartyp
                  END
      |OPM.odd:   IF f IN OPM.intSet THEN
                    IF z^.class = OPM.Nconst THEN
                      z^.conval^.intval := BoolToInt(ODD(z^.conval^.intval)); z^.obj := NIL
                    ELSE z := NewOp(op, typ, z)
                    END
                  ELSE err(111)
                  END ;
                  z^.typ := OPT.booltyp
      |OPM.adr:   IF (z^.class = OPM.Nconst) & (f = OPM.Char) & (z^.conval^.intval >= 20H) THEN    (*SYSTEM.ADR*)
                    CharToString(z); f := OPM.String
                  END;
                  IF (z^.class < OPM.Nconst) OR (f = OPM.String) THEN z := NewOp(op, typ, z)
                  ELSE err(127)
                  END ;
                  z^.typ := OPT.linttyp
      |OPM.cc:    IF (f IN OPM.intSet) & (z^.class = OPM.Nconst) THEN                              (*SYSTEM.CC*)
                    IF (0 <= z^.conval^.intval) & (z^.conval^.intval <= OPM.MaxCC) THEN z := NewOp(op, typ, z) ELSE err(219) END
                  ELSE err(69)
                  END ;
                  z^.typ := OPT.booltyp
      ELSE OPM.LogWStr("unhandled case in OPB.MOp, op = "); OPM.LogWNum(op, 0); OPM.LogWLn;
      END
    END ;
    x := z
  END MOp;

  PROCEDURE CheckPtr(x, y: OPT.Node);
    VAR g: INTEGER; p, q, t: OPT.Struct;
  BEGIN g := y^.typ^.form;
    IF g = OPM.Pointer THEN
      p := x^.typ^.BaseTyp; q := y^.typ^.BaseTyp;
      IF (p^.comp = OPM.Record) & (q^.comp = OPM.Record) THEN
        IF p^.extlev < q^.extlev THEN t := p; p := q; q := t END ;
        WHILE (p # q) & (p # NIL) & (p # OPT.undftyp) DO p := p^.BaseTyp END ;
        IF p = NIL THEN err(100) END
      ELSE err(100)
      END
    ELSIF g # OPM.NilTyp THEN err(100)
    END
  END CheckPtr;

  PROCEDURE CheckParameters*(fp, ap: OPT.Object; checkNames: BOOLEAN);
    VAR ft, at: OPT.Struct;
  BEGIN
    WHILE fp # NIL DO
      IF ap # NIL THEN
        ft := fp^.typ; at := ap^.typ;
        WHILE (ft^.comp = OPM.DynArr) & (at^.comp = OPM.DynArr) DO
          ft := ft^.BaseTyp; at := at^.BaseTyp
        END ;
        IF ft # at THEN
          IF (ft^.form = OPM.ProcTyp) & (at^.form = OPM.ProcTyp) THEN
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
    IF y^.mode IN {OPM.XProc, OPM.IProc, OPM.LProc} THEN
      IF y^.mode = OPM.LProc THEN
        IF y^.mnolev = 0 THEN y^.mode := OPM.XProc
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
      |OPM.Undef:   res := OPM.eql
      |OPM.Byte,
       OPM.Char
       ..OPM.LInt:  IF xval^.intval < yval^.intval THEN res := OPM.lss
                    ELSIF xval^.intval > yval^.intval THEN res := OPM.gtr
                    ELSE res := OPM.eql
                    END
      |OPM.Real,
       OPM.LReal:   IF xval^.realval < yval^.realval THEN res := OPM.lss
                    ELSIF xval^.realval > yval^.realval THEN res := OPM.gtr
                    ELSE res := OPM.eql
                    END
      |OPM.Bool:    IF xval^.intval # yval^.intval THEN res := OPM.neq
                    ELSE res := OPM.eql
                    END
      |OPM.Set:     IF xval^.setval # yval^.setval THEN res := OPM.neq
                    ELSE res := OPM.eql
                    END
      |OPM.String:  IF xval^.ext^ < yval^.ext^ THEN res := OPM.lss
                    ELSIF xval^.ext^ > yval^.ext^ THEN res := OPM.gtr
                    ELSE res := OPM.eql
                    END
      |OPM.NilTyp,
       OPM.Pointer,
       OPM.ProcTyp: IF xval^.intval # yval^.intval THEN res := OPM.neq
                    ELSE res := OPM.eql
                    END
      ELSE OPM.LogWStr("unhandled case in OPB.ConstCmp, f = "); OPM.LogWNum(f, 0); OPM.LogWLn;
      END ;
      x^.typ := OPT.booltyp; RETURN res
    END ConstCmp;

  BEGIN
    (* f, x, xval are for left side; g, y, yval for right side. *)
    f := x^.typ^.form; g := y^.typ^.form; xval := x^.conval; yval := y^.conval;
    IF f # g THEN
      CASE f OF
      |OPM.Char:    IF g = OPM.String THEN CharToString(x)
                    ELSE err(100); y^.typ := x^.typ; yval^ := xval^
                    END ;
      |OPM.SInt,
       OPM.Int,
       OPM.LInt:    IF g IN OPM.intSet THEN
                      IF x.typ.size <= y.typ.size THEN x.typ := y.typ ELSE x.typ := IntType(x.typ.size) END
                    ELSIF g = OPM.Real THEN x^.typ := OPT.realtyp; xval^.realval := xval^.intval
                    ELSIF g = OPM.LReal THEN x^.typ := OPT.lrltyp; xval^.realval := xval^.intval
                    ELSE  err(100); y^.typ := x^.typ; yval^ := xval^
                    END
      |OPM.Real:    IF g IN OPM.intSet THEN y^.typ := x^.typ; yval^.realval := yval^.intval
                    ELSIF g = OPM.LReal THEN x^.typ := OPT.lrltyp
                    ELSE  err(100); y^.typ := x^.typ; yval^ := xval^
                    END
      |OPM.LReal:   IF g IN OPM.intSet THEN y^.typ := x^.typ; yval^.realval := yval^.intval
                    ELSIF g = OPM.Real THEN y^.typ := OPT.lrltyp
                    ELSE  err(100); y^.typ := x^.typ; yval^ := xval^
                    END
      |OPM.String:  IF g = OPM.Char THEN CharToString(y); g := OPM.String
                    ELSE err(100); y^.typ := x^.typ; yval^ := xval^
                    END ;
      |OPM.NilTyp:  IF ~(g IN {OPM.Pointer, OPM.ProcTyp}) THEN err(100) END
      |OPM.Pointer: CheckPtr(x, y)
      |OPM.ProcTyp: IF g # OPM.NilTyp THEN err(100) END
      ELSE err(100); y^.typ := x^.typ; yval^ := xval^
      END ;
      f := x^.typ^.form
    END ;  (* {x^.typ = y^.typ} *)
    CASE op OF
    |OPM.times: IF f IN OPM.intSet THEN xv := xval^.intval; yv := yval^.intval;
                  IF (xv = 0) OR (yv = 0) OR  (* division with negative numbers is not defined *)
                    (xv > 0) & (yv > 0) & (yv <= MAX(LONGINT) DIV xv) OR
                    (xv > 0) & (yv < 0) & (yv >= MIN(LONGINT) DIV xv) OR
                    (xv < 0) & (yv > 0) & (xv >= MIN(LONGINT) DIV yv) OR
                    (xv < 0) & (yv < 0) & (xv  # MIN(LONGINT)) & (yv # MIN(LONGINT)) & (-xv <= MAX(LONGINT) DIV (-yv)) THEN
                    xval^.intval := xv * yv; SetIntType(x)
                  ELSE err(204)
                  END
                ELSIF f IN OPM.realSet THEN
                  temp := ABS(yval^.realval) <= 1.0;
                  IF temp OR (ABS(xval^.realval) <= MAX(LONGREAL) / ABS(yval^.realval)) THEN
                    xval^.realval := xval^.realval * yval^.realval; CheckRealType(f, 204, xval)
                  ELSE err(204)
                  END
                ELSIF f = OPM.Set THEN
                  xval^.setval := xval^.setval * yval^.setval
                ELSIF f # OPM.Undef THEN err(101)
                END
    |OPM.slash: IF f IN OPM.intSet THEN
                  IF yval^.intval # 0 THEN
                    xval^.realval := xval^.intval / yval^.intval; CheckRealType(OPM.Real, 205, xval)
                  ELSE err(205); xval^.realval := 1.0
                  END ;
                  x^.typ := OPT.realtyp
                ELSIF f IN OPM.realSet THEN
                  temp := ABS(yval^.realval) >= 1.0;
                  IF temp OR (ABS(xval^.realval) <= MAX(LONGREAL) * ABS(yval^.realval)) THEN
                    xval^.realval := xval^.realval / yval^.realval; CheckRealType(f, 205, xval)
                  ELSE err(205)
                  END
                ELSIF f = OPM.Set THEN
                  xval^.setval := xval^.setval / yval^.setval
                ELSIF f # OPM.Undef THEN err(102)
                END
    |OPM.div:   IF f IN OPM.intSet THEN
                  IF yval^.intval # 0 THEN
                    xval^.intval := xval^.intval DIV yval^.intval; SetIntType(x)
                  ELSE err(205)
                  END
                ELSIF f # OPM.Undef THEN err(103)
                END
    |OPM.mod:   IF f IN OPM.intSet THEN
                  IF yval^.intval # 0 THEN
                    xval^.intval := xval^.intval MOD yval^.intval; SetIntType(x)
                  ELSE err(205)
                  END
                ELSIF f # OPM.Undef THEN err(104)
                END
    |OPM.and:   IF f = OPM.Bool THEN
                  xval^.intval := BoolToInt(IntToBool(xval^.intval) & IntToBool(yval^.intval))
                ELSE err(94)
                END
    |OPM.plus:  IF f IN OPM.intSet THEN
                  temp := (yval^.intval >= 0) & (xval^.intval <= MAX(LONGINT) - yval^.intval);
                  IF temp OR (yval^.intval < 0) & (xval^.intval >= MIN(LONGINT) - yval^.intval) THEN
                      INC(xval^.intval, yval^.intval); SetIntType(x)
                  ELSE err(206)
                  END
                ELSIF f IN OPM.realSet THEN
                  temp := (yval^.realval >= 0.0) & (xval^.realval <= MAX(LONGREAL) - yval^.realval);
                  IF temp OR (yval^.realval < 0.0) & (xval^.realval >= -MAX(LONGREAL) - yval^.realval) THEN
                      xval^.realval := xval^.realval + yval^.realval; CheckRealType(f, 206, xval)
                  ELSE err(206)
                  END
                ELSIF f = OPM.Set THEN
                  xval^.setval := xval^.setval + yval^.setval
                ELSIF f # OPM.Undef THEN err(105)
                END
    |OPM.minus: IF f IN OPM.intSet THEN
                  IF (yval^.intval >= 0) & (xval^.intval >= MIN(LONGINT) + yval^.intval) OR
                    (yval^.intval < 0) & (xval^.intval  <= MAX(LONGINT) + yval^.intval) THEN
                      DEC(xval^.intval, yval^.intval); SetIntType(x)
                  ELSE err(207)
                  END
                ELSIF f IN OPM.realSet THEN
                  temp := (yval^.realval >= 0.0) & (xval^.realval >= -MAX(LONGREAL) + yval^.realval);
                  IF temp OR (yval^.realval < 0.0) & (xval^.realval <= MAX(LONGREAL) + yval^.realval) THEN
                      xval^.realval := xval^.realval - yval^.realval; CheckRealType(f, 207, xval)
                  ELSE err(207)
                  END
                ELSIF f = OPM.Set THEN
                  xval^.setval := xval^.setval - yval^.setval
                ELSIF f # OPM.Undef THEN err(106)
                END
    |OPM.or:    IF f = OPM.Bool THEN
                  xval^.intval := BoolToInt(IntToBool(xval^.intval) OR IntToBool(yval^.intval))
                ELSE err(95)
                END
    |OPM.eql:   xval^.intval := BoolToInt(ConstCmp() = OPM.eql)
    |OPM.neq:   xval^.intval := BoolToInt(ConstCmp() # OPM.eql)
    |OPM.lss:   IF f IN {OPM.Bool, OPM.Set, OPM.NilTyp, OPM.Pointer} THEN err(108)
                ELSE xval^.intval := BoolToInt(ConstCmp() = OPM.lss)
                END
    |OPM.leq:   IF f IN {OPM.Bool, OPM.Set, OPM.NilTyp, OPM.Pointer} THEN err(108)
                ELSE xval^.intval := BoolToInt(ConstCmp() # OPM.gtr)
                END
    |OPM.gtr:   IF f IN {OPM.Bool, OPM.Set, OPM.NilTyp, OPM.Pointer} THEN err(108)
                ELSE xval^.intval := BoolToInt(ConstCmp() = OPM.gtr)
                END
    |OPM.geq:   IF f IN {OPM.Bool, OPM.Set, OPM.NilTyp, OPM.Pointer} THEN err(108)
                ELSE xval^.intval := BoolToInt(ConstCmp() # OPM.lss)
                END
    ELSE
       OPM.LogWStr("unhandled case in OPB.ConstOp, op = "); OPM.LogWNum(op, 0); OPM.LogWLn;
    END
  END ConstOp;

  PROCEDURE Convert(VAR x: OPT.Node; typ: OPT.Struct);
    VAR node: OPT.Node; f, g: INTEGER; k: LONGINT; r: LONGREAL;
  BEGIN f := x^.typ^.form; g := typ^.form;
    IF x^.class = OPM.Nconst THEN
      IF f IN OPM.intSet THEN
        IF g IN OPM.intSet THEN
          IF f > g THEN SetIntType(x);
            IF x^.typ^.form > g THEN err(203); x^.conval^.intval := 1 END
          END
        ELSIF g IN OPM.realSet THEN x^.conval^.realval := x^.conval^.intval; x^.conval^.intval := OPM.ConstNotAlloc
        ELSE (*g = OPM.Char*) k := x^.conval^.intval;
          IF (0 > k) OR (k > 0FFH) THEN err(220) END
        END
      ELSIF f IN OPM.realSet THEN
        IF g IN OPM.realSet THEN CheckRealType(g, 203, x^.conval)
        ELSE (*g = OPM.LInt*)
          r := x^.conval^.realval;
          IF (r < MIN(LONGINT)) OR (r > MAX(LONGINT)) THEN err(203); r := 1 END ;
          x^.conval^.intval := ENTIER(r); SetIntType(x)
        END
      ELSE (* (f IN {OPM.Char, OPM.Byte}) & (g IN {OPM.Byte} + OPM.intSet) OR (f = OPM.Undef) *)
      END ;
      x^.obj := NIL
    ELSIF (x^.class = OPM.Nmop) & (x^.subcl = OPM.conv) & ((x^.left^.typ^.form < f) OR (f > g)) THEN
      (* don't create new node *)
      IF x^.left^.typ = typ THEN (* and suppress existing node *) x := x^.left END
    ELSE node := OPT.NewNode(OPM.Nmop); node^.subcl := OPM.conv; node^.left := x; x := node
    END ;
    x^.typ := typ
  END Convert;

  PROCEDURE Op*(op: SHORTINT; VAR x: OPT.Node; y: OPT.Node);
    VAR f, g: INTEGER; t, z: OPT.Node; typ: OPT.Struct; do: BOOLEAN; val: LONGINT;

    PROCEDURE NewOp(op: SHORTINT; typ: OPT.Struct; VAR x: OPT.Node; y: OPT.Node);
      VAR node: OPT.Node;
    BEGIN
      node := OPT.NewNode(OPM.Ndop); node^.subcl := op; node^.typ := typ;
      node^.left := x; node^.right := y; x := node
    END NewOp;

    PROCEDURE strings(VAR x, y: OPT.Node): BOOLEAN;
      VAR ok, xCharArr, yCharArr: BOOLEAN;
    BEGIN
      xCharArr := ((x^.typ^.comp IN {OPM.Array, OPM.DynArr}) & (x^.typ^.BaseTyp^.form=OPM.Char)) OR (f=OPM.String);
      yCharArr := (((y^.typ^.comp IN {OPM.Array, OPM.DynArr}) & (y^.typ^.BaseTyp^.form=OPM.Char)) OR (g=OPM.String));
      IF xCharArr & (g = OPM.Char) & (y^.class = OPM.Nconst) THEN CharToString(y); g := OPM.String; yCharArr := TRUE END ;
      IF yCharArr & (f = OPM.Char) & (x^.class = OPM.Nconst) THEN CharToString(x); f := OPM.String; xCharArr := TRUE END ;
      ok := xCharArr & yCharArr;
      IF ok THEN  (* replace ""-string compare with 0X-char compare, if possible *)
        IF (f=OPM.String) & (x^.conval^.intval2 = 1) THEN  (* y is array of char *)
          x^.typ := OPT.chartyp; x^.conval^.intval := 0;
          Index(y, NewIntConst(0))
        ELSIF (g=OPM.String) & (y^.conval^.intval2 = 1) THEN  (* x is array of char *)
          y^.typ := OPT.chartyp; y^.conval^.intval := 0;
          Index(x, NewIntConst(0))
        END
      END ;
      RETURN ok
    END strings;


  BEGIN z := x;
    IF (z^.class = OPM.Ntype) OR (z^.class = OPM.Nproc) OR (y^.class = OPM.Ntype) OR (y^.class = OPM.Nproc) THEN err(126)
    ELSIF (z^.class = OPM.Nconst) & (y^.class = OPM.Nconst) THEN ConstOp(op, z, y); z^.obj := NIL
    ELSE
      IF z^.typ # y^.typ THEN
        g := y^.typ^.form;
        CASE z^.typ^.form OF
        |OPM.Char:    IF z^.class = OPM.Nconst THEN CharToString(z) ELSE err(100) END
        |OPM.SInt,
         OPM.Int,
         OPM.LInt:    IF (g IN OPM.intSet) & (y.typ.size < z.typ.size) THEN Convert(y, z.typ)
                      ELSIF g IN OPM.intSet + OPM.realSet              THEN Convert(z, y.typ)
                      ELSE err(100)
                      END
        |OPM.Real:    IF g IN OPM.intSet THEN Convert(y, z^.typ)
                      ELSIF g IN OPM.realSet THEN Convert(z, y^.typ)
                      ELSE  err(100)
                      END
        |OPM.LReal:   IF g IN OPM.intSet + OPM.realSet THEN Convert(y, z^.typ)
                      ELSIF g IN OPM.realSet THEN Convert(y, z^.typ)          (* DCWB: Surely this line does nothing. *)
                      ELSE  err(100)
                      END
        |OPM.NilTyp:  IF ~(g IN {OPM.Pointer, OPM.ProcTyp}) THEN err(100) END
        |OPM.Pointer: CheckPtr(z, y)
        |OPM.ProcTyp: IF g # OPM.NilTyp THEN err(100) END
        |OPM.String:
        |OPM.Comp:    IF z^.typ^.comp = OPM.Record THEN err(100) END
        ELSE err(100)
        END
      END ;  (* {z^.typ = y^.typ} *)
      typ := z^.typ; f := typ^.form; g := y^.typ^.form;
      CASE op OF
      |OPM.times: do := TRUE;
                  IF f IN OPM.intSet THEN
                    IF z^.class = OPM.Nconst THEN val := z^.conval^.intval;
                      IF val = 1 THEN do := FALSE; z := y
                      ELSIF val = 0 THEN do := FALSE
                      ELSIF log(val) = 1 THEN
                        t := y; y := z; z := t;
                        op := OPM.ash; y^.typ := OPT.sinttyp; y^.conval^.intval := exp; y^.obj := NIL
                      END
                    ELSIF y^.class = OPM.Nconst THEN val := y^.conval^.intval;
                      IF val = 1 THEN do := FALSE
                      ELSIF val = 0 THEN do := FALSE; z := y
                      ELSIF log(val) = 1 THEN
                        op := OPM.ash; y^.typ := OPT.sinttyp; y^.conval^.intval := exp; y^.obj := NIL
                      END
                    END
                  ELSIF ~(f IN {OPM.Undef, OPM.Real..OPM.Set}) THEN err(105); typ := OPT.undftyp
                  END ;
                  IF do THEN NewOp(op, typ, z, y) END
      |OPM.slash: IF f IN OPM.intSet THEN
                    IF (y^.class = OPM.Nconst) & (y^.conval^.intval = 0) THEN err(205) END ;
                    Convert(z, OPT.realtyp); Convert(y, OPT.realtyp);
                    typ := OPT.realtyp
                  ELSIF f IN OPM.realSet THEN
                    IF (y^.class = OPM.Nconst) & (y^.conval^.realval = 0.0) THEN err(205) END
                  ELSIF (f # OPM.Set) & (f # OPM.Undef) THEN err(102); typ := OPT.undftyp
                  END ;
                  NewOp(op, typ, z, y)
      |OPM.div:   do := TRUE;
                  IF f IN OPM.intSet THEN
                    IF y^.class = OPM.Nconst THEN val := y^.conval^.intval;
                      IF val = 0 THEN err(205)
                      ELSIF val = 1 THEN do := FALSE
                      ELSIF log(val) = 1 THEN
                        op := OPM.ash; y^.typ := OPT.sinttyp; y^.conval^.intval := -exp; y^.obj := NIL
                      END
                    END
                  ELSIF f # OPM.Undef THEN err(103); typ := OPT.undftyp
                  END ;
                  IF do THEN NewOp(op, typ, z, y) END
      |OPM.mod:   IF f IN OPM.intSet THEN
                    IF y^.class = OPM.Nconst THEN
                      IF y^.conval^.intval = 0 THEN err(205)
                      ELSIF log(y^.conval^.intval) = 1 THEN
                        op := OPM.msk; y^.conval^.intval := ASH(-1, exp); y^.obj := NIL
                      END
                    END
                  ELSIF f # OPM.Undef THEN err(104); typ := OPT.undftyp
                  END ;
                  NewOp(op, typ, z, y)
      |OPM.and:   IF f = OPM.Bool THEN
                    IF z^.class = OPM.Nconst THEN
                      IF IntToBool(z^.conval^.intval) THEN z := y END
                    ELSIF (y^.class = OPM.Nconst) & IntToBool(y^.conval^.intval) THEN (* optimize z & TRUE -> z *)
                  (*ELSIF (y^.class = OPM.Nconst) & ~IntToBool(y^.conval^.intval) THEN
                      don't optimize z & FALSE -> FALSE: side effects possible  *)
                    ELSE NewOp(op, typ, z, y)
                    END
                  ELSIF f # OPM.Undef THEN err(94); z^.typ := OPT.undftyp
                  END
      |OPM.plus:  IF ~(f IN {OPM.Undef, OPM.SInt..OPM.Set}) THEN err(105); typ := OPT.undftyp END ;
                  do := TRUE;
                  IF f IN OPM.intSet THEN
                    IF (z^.class = OPM.Nconst) & (z^.conval^.intval = 0) THEN do := FALSE; z := y END ;
                    IF (y^.class = OPM.Nconst) & (y^.conval^.intval = 0) THEN do := FALSE END
                  END ;
                  IF do THEN NewOp(op, typ, z, y) END
      |OPM.minus: IF ~(f IN {OPM.Undef, OPM.SInt..OPM.Set}) THEN err(106); typ := OPT.undftyp END ;
                  IF ~(f IN OPM.intSet) OR (y^.class # OPM.Nconst) OR (y^.conval^.intval # 0) THEN NewOp(op, typ, z, y) END
      |OPM.or:    IF f = OPM.Bool THEN
                    IF z^.class = OPM.Nconst THEN
                      IF ~IntToBool(z^.conval^.intval) THEN z := y END
                    ELSIF (y^.class = OPM.Nconst) & ~IntToBool(y^.conval^.intval) THEN (* optimize z OR FALSE -> z *)
                  (*ELSIF (y^.class = OPM.Nconst) & IntToBool(y^.conval^.intval) THEN
                      don't optimize z OR TRUE -> TRUE: side effects possible  *)
                    ELSE NewOp(op, typ, z, y)
                    END
                  ELSIF f # OPM.Undef THEN err(95); z^.typ := OPT.undftyp
                  END
      |OPM.eql,
       OPM.neq:   IF (f IN {OPM.Undef..OPM.Set, OPM.NilTyp, OPM.Pointer, OPM.ProcTyp}) OR strings(z, y) THEN typ := OPT.booltyp
                  ELSE err(107); typ := OPT.undftyp
                  END ;
                  NewOp(op, typ, z, y)
      |OPM.lss,
       OPM.leq,
       OPM.gtr,
       OPM.geq:   IF (f IN {OPM.Undef, OPM.Char..OPM.LReal}) OR strings(z, y) THEN typ := OPT.booltyp
                  ELSE
                    OPM.LogWLn; OPM.LogWStr("ELSE in Op()"); OPM.LogWLn;
                    err(108); typ := OPT.undftyp
                  END ;
                  NewOp(op, typ, z, y)
      ELSE OPM.LogWStr("unhandled case in OPB.Op, op = "); OPM.LogWNum(op, 0); OPM.LogWLn;
      END
    END ;
    x := z
  END Op;

  PROCEDURE SetRange*(VAR x: OPT.Node; y: OPT.Node);
    VAR k, l: LONGINT;
  BEGIN
    IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) OR (y^.class = OPM.Ntype) OR (y^.class = OPM.Nproc) THEN err(126)
    ELSIF (x^.typ^.form IN OPM.intSet) & (y^.typ^.form IN OPM.intSet) THEN
      IF x^.class = OPM.Nconst THEN
        k := x^.conval^.intval;
        IF (0 > k) OR (k > OPM.MaxSet) THEN err(202) END
      END ;
      IF y^.class = OPM.Nconst THEN
        l := y^.conval^.intval;
        IF (0 > l) OR (l > OPM.MaxSet) THEN err(202) END
      END ;
      IF (x^.class = OPM.Nconst) & (y^.class = OPM.Nconst) THEN
        IF k <= l THEN
          x^.conval^.setval := {k..l}
        ELSE err(201); x^.conval^.setval := {l..k}
        END ;
        x^.obj := NIL
      ELSE BindNodes(OPM.Nupto, OPT.settyp, x, y)
      END
    ELSE err(93)
    END ;
    x^.typ := OPT.settyp
  END SetRange;

  PROCEDURE SetElem*(VAR x: OPT.Node);
    VAR k: LONGINT;
  BEGIN
    IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
    ELSIF ~(x^.typ^.form IN OPM.intSet) THEN err(93)
    ELSIF x^.class = OPM.Nconst THEN
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
    VAR         (* x is designator (target) type *)
      y: OPT.Struct; (* expression (source) type *)
      f: INTEGER;    (* designator (target) form *)
      g: INTEGER;    (* expression (source) form *)
      p, q: OPT.Struct;
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
    IF (ynode^.class = OPM.Ntype) OR (ynode^.class = OPM.Nproc) & (f # OPM.ProcTyp) THEN err(126) END ;
    CASE f OF
      OPM.Undef,
      OPM.String:
    | OPM.Byte:     IF ~((g IN ({OPM.Byte, OPM.Char} + OPM.intSet)) & (y.size = 1)) THEN err(113) END
    | OPM.Bool,
      OPM.Char,
      OPM.Set:      IF g # f THEN err(113) END
    | OPM.SInt,
      OPM.Int,
      OPM.LInt:     IF ~(g IN OPM.intSet) OR (x.size < y.size) THEN err(113) END
    | OPM.Real:     IF ~(g IN {OPM.SInt..OPM.Real})  THEN err(113) END
    | OPM.LReal:    IF ~(g IN {OPM.SInt..OPM.LReal}) THEN err(113) END
    | OPM.Pointer:  IF (x = y) OR (g = OPM.NilTyp) OR (x = OPT.sysptrtyp) & (g = OPM.Pointer) THEN (* ok *)
                    ELSIF g = OPM.Pointer THEN
                      p := x^.BaseTyp; q := y^.BaseTyp;
                      IF (p^.comp = OPM.Record) & (q^.comp = OPM.Record) THEN
                        WHILE (q # p) & (q # NIL) & (q # OPT.undftyp) DO q := q^.BaseTyp END ;
                        IF q = NIL THEN err(113) END
                      ELSE err(113)
                      END
                    ELSE err(113)
                    END
    | OPM.ProcTyp:  IF ynode^.class = OPM.Nproc THEN CheckProc(x, ynode^.obj)
                    ELSIF (x = y) OR (g = OPM.NilTyp) THEN (* ok *)
                    ELSE err(113)
                    END
    | OPM.NoTyp,
      OPM.NilTyp:   err(113)
    | OPM.Comp:     x^.pvused := TRUE;  (* idfp of y guarantees assignment compatibility with x *)
                    IF x^.comp = OPM.Array THEN
                      IF (ynode^.class = OPM.Nconst) & (g = OPM.Char) THEN CharToString(ynode); y := ynode^.typ; g := OPM.String END ;
                      IF x = y THEN (* ok *)
                      ELSIF x^.BaseTyp = OPT.chartyp THEN (* Assign to (static) ARRAY OF CHAR *)
                        IF g = OPM.String THEN (*check length of string*)
                          IF ynode^.conval^.intval2 > x^.n THEN err(114) END
                        ELSIF (y.comp IN {OPM.DynArr, OPM.Array}) & (y.BaseTyp = OPT.chartyp) THEN
                          (* Assignment from ARRAY OF CHAR is good.*)
                        ELSE err(113)
                        END
                      ELSE err(113)
                      END
                    ELSIF (x.comp = OPM.DynArr) & (x^.BaseTyp = OPT.chartyp) THEN (* Assign to dynamic ARRAY OF CHAR*)
                      IF (y.comp IN {OPM.DynArr, OPM.Array}) & (y.BaseTyp = OPT.chartyp) THEN
                        (* Assignment from ARRAY OF CHAR is good.*)
                      ELSE err(113)
                      END
                    ELSIF x^.comp = OPM.Record THEN
                      IF x = y THEN (* ok *)
                      ELSIF y^.comp = OPM.Record THEN
                        q := y^.BaseTyp;
                        WHILE (q # NIL) & (q # x) & (q # OPT.undftyp) DO q := q^.BaseTyp END ;
                        IF q = NIL THEN err(113) END
                      ELSE err(113)
                      END
                    ELSE err(113)
                    END
    ELSE            OPM.LogWStr("unhandled case in OPB.CheckAssign, f = "); OPM.LogWNum(f, 0); OPM.LogWLn;
    END ;
    IF (ynode^.class = OPM.Nconst) & (g < f) & (g IN {OPM.SInt..OPM.Real}) & (f IN {OPM.Int..OPM.LReal}) THEN
      Convert(ynode, x)
    END
  END CheckAssign;

  PROCEDURE CheckLeaf(x: OPT.Node; dynArrToo: BOOLEAN);
  BEGIN
(* avoid unnecessary intermediate variables in voc
    IF (x^.class = OPM.Nmop) & (x^.subcl = val) THEN x := x^.left END ;
    IF x^.class = OPM.Nguard THEN x := x^.left END ;  (* skip last (and unique) guard *)
    IF (x^.class = OPM.Nvar) & (dynArrToo OR (x^.typ^.comp # OPM.DynArr)) THEN x^.obj^.leaf := FALSE END
*)
  END CheckLeaf;

  PROCEDURE StPar0*(VAR par0: OPT.Node; fctno: INTEGER);  (* par0: first param of standard proc *)
    VAR f: INTEGER; typ: OPT.Struct; x: OPT.Node;
  BEGIN x := par0; f := x^.typ^.form;
    CASE fctno OF
    |OPM.haltfn:   (*HALT*)
                   IF (f IN OPM.intSet) & (x^.class = OPM.Nconst) THEN
                     IF (OPM.MinHaltNr <= x^.conval^.intval) & (x^.conval^.intval <= OPM.MaxHaltNr) THEN
                       BindNodes(OPM.Ntrap, OPT.notyp, x, x)
                     ELSE err(218)
                     END
                   ELSE err(69)
                   END ;
                   x^.typ := OPT.notyp
    |OPM.newfn:    (*NEW*)
                   typ := OPT.notyp;
                   IF NotVar(x) THEN err(112)
                   ELSIF f = OPM.Pointer THEN
                     IF OPM.NEWusingAdr THEN CheckLeaf(x, TRUE) END ;
                     IF x^.readonly THEN err(76) END ;
                     f := x^.typ^.BaseTyp^.comp;
                     IF f IN {OPM.Record, OPM.DynArr, OPM.Array} THEN
                       IF f = OPM.DynArr THEN typ := x^.typ^.BaseTyp END ;
                       BindNodes(OPM.Nassign, OPT.notyp, x, NIL); x^.subcl := OPM.newfn
                     ELSE err(111)
                     END
                   ELSE err(111)
                   END ;
                   x^.typ := typ
    |OPM.absfn:    (*ABS*)
                   MOp(OPM.abs, x)
    |OPM.capfn:    (*CAP*)
                   MOp(OPM.cap, x)
    |OPM.ordfn:    (*ORD*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f = OPM.Char THEN Convert(x, OPT.inttyp)
                   ELSE err(111)
                   END ;
                   x^.typ := OPT.inttyp
    |OPM.entierfn: (*ENTIER*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f IN OPM.realSet THEN Convert(x, OPT.linttyp)
                   ELSE err(111)
                   END ;
                   x^.typ := OPT.linttyp
    |OPM.oddfn:    (*ODD*)
                   MOp(OPM.odd, x)
    |OPM.minfn:    (*MIN*)
                   IF x^.class = OPM.Ntype THEN
                     CASE f OF
                       OPM.Bool:  x := NewBoolConst(FALSE)
                     | OPM.Char:  x := NewIntConst(0); x^.typ := OPT.chartyp
                     | OPM.SInt,
                       OPM.Int,
                       OPM.LInt:  x := NewIntConst(OPM.SignedMinimum(x.typ.size))
                     | OPM.Set:   x := NewIntConst(0); x^.typ := OPT.inttyp
                     | OPM.Real:  x := NewRealConst(OPM.MinReal, OPT.realtyp)
                     | OPM.LReal: x := NewRealConst(OPM.MinLReal, OPT.lrltyp)
                     ELSE err(111)
                     END
                   ELSE err(110)
                   END
    |OPM.maxfn:    (*MAX*)
                   IF x^.class = OPM.Ntype THEN
                     CASE f OF
                       OPM.Bool:  x := NewBoolConst(TRUE)
                     | OPM.Char:  x := NewIntConst(0FFH); x^.typ := OPT.chartyp
                     | OPM.SInt,
                       OPM.Int,
                       OPM.LInt:  x := NewIntConst(OPM.SignedMaximum(x.typ.size))
                     | OPM.Set:   x := NewIntConst(OPM.MaxSet); x^.typ := OPT.inttyp
                     | OPM.Real:  x := NewRealConst(OPM.MaxReal, OPT.realtyp)
                     | OPM.LReal: x := NewRealConst(OPM.MaxLReal, OPT.lrltyp)
                     ELSE err(111)
                     END
                   ELSE err(110)
                   END
    |OPM.chrfn:    (*CHR*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f IN {OPM.Undef} + OPM.intSet THEN Convert(x, OPT.chartyp)
                   ELSE err(111); x^.typ := OPT.chartyp
                   END
    |OPM.shortfn:  (*SHORT*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF (f IN OPM.intSet) & (x.typ.size > OPM.SIntSize) THEN Convert(x, IntType(ShorterSize(x.typ.size)))
                   ELSIF f = OPM.LReal THEN Convert(x, OPT.realtyp)
                   ELSE err(111)
                   END
    |OPM.longfn:   (*LONG*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF (f IN OPM.intSet) & (x.typ.size < OPM.LIntSize) THEN Convert(x, IntType(LongerSize(x.typ.size)))
                   ELSIF f = OPM.Real THEN Convert(x, OPT.lrltyp)
                   ELSIF f = OPM.Char THEN Convert(x, OPT.linttyp)
                   ELSE err(111)
                   END
    |OPM.incfn,
     OPM.decfn:    (*INC, DEC*)
                   IF NotVar(x) THEN err(112)
                   ELSIF ~(f IN OPM.intSet) THEN err(111)
                   ELSIF x^.readonly THEN err(76)
                   END
    |OPM.inclfn,
     OPM.exclfn:   (*INCL, EXCL*)
                   IF NotVar(x) THEN err(112)
                   ELSIF x^.typ # OPT.settyp THEN err(111); x^.typ := OPT.settyp
                   ELSIF x^.readonly THEN err(76)
                   END
    |OPM.lenfn:    (*LEN*)
                   IF ~(x^.typ^.comp IN {OPM.DynArr, OPM.Array}) THEN err(131) END
    |OPM.copyfn:   (*COPY*)
                   IF (x^.class = OPM.Nconst) & (f = OPM.Char) THEN CharToString(x); f := OPM.String END ;
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF (~(x^.typ^.comp IN {OPM.DynArr, OPM.Array}) OR (x^.typ^.BaseTyp^.form # OPM.Char))
                      & (f # OPM.String) THEN err(111)
                   END
    |OPM.ashfn:    (*ASH*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f IN OPM.intSet THEN
                     IF x.typ.size # OPM.LIntSize THEN Convert(x, OPT.linttyp) END
                   ELSE err(111); x^.typ := OPT.linttyp
                   END
    |OPM.adrfn:    (*SYSTEM.ADR*)
                   CheckLeaf(x, FALSE); MOp(OPM.adr, x)
    |OPM.sizefn:   (*SIZE*)
                   IF x^.class # OPM.Ntype THEN err(110); x := NewIntConst(1)
                   ELSIF (f IN {OPM.Byte..OPM.Set, OPM.Pointer, OPM.ProcTyp})
                      OR (x^.typ^.comp IN {OPM.Array, OPM.Record}) THEN
                     typSize(x^.typ); x^.typ^.pvused := TRUE; x := NewIntConst(x^.typ^.size)
                   ELSE err(111); x := NewIntConst(1)
                   END
    |OPM.ccfn:     (*SYSTEM.CC*)
                   MOp(OPM.cc, x)
    |OPM.lshfn,
     OPM.rotfn:    (*SYSTEM.LSH, SYSTEM.ROT*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF ~(f IN OPM.intSet + {OPM.Byte, OPM.Char, OPM.Set}) THEN err(111)
                   END
    |OPM.getfn,
     OPM.putfn,
     OPM.bitfn,
     OPM.movefn:   (*SYSTEM.GET, SYSTEM.PUT, SYSTEM.BIT, SYSTEM.MOVE*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF (x^.class = OPM.Nconst) & (f IN OPM.intSet) & (x.typ.size < OPT.linttyp.size) THEN Convert(x, OPT.linttyp)
                   ELSIF ~((x.typ.form IN {OPM.Pointer} + OPM.intSet) & (x.typ.size = OPM.PointerSize)) THEN err(111); x^.typ := OPT.linttyp
                   END
    |OPM.getrfn,
     OPM.putrfn:   (*SYSTEM.GETREG, SYSTEM.PUTREG*)
                   IF (f IN OPM.intSet) & (x^.class = OPM.Nconst) THEN
                     IF (x^.conval^.intval < OPM.MinRegNr) OR (x^.conval^.intval > OPM.MaxRegNr) THEN err(220) END
                   ELSE err(69)
                   END
    |OPM.valfn:    (*SYSTEM.VAL*)
                   IF x^.class # OPM.Ntype THEN err(110)
                   ELSIF (f IN {OPM.Undef, OPM.String, OPM.NoTyp}) OR (x^.typ^.comp = OPM.DynArr) THEN err(111)
                   END
    |OPM.sysnewfn: (*SYSTEM.NEW*)
                   IF NotVar(x) THEN err(112)
                   ELSIF f = OPM.Pointer THEN
                     IF OPM.NEWusingAdr THEN CheckLeaf(x, TRUE) END
                   ELSE err(111)
                   END
    |OPM.assertfn: (*ASSERT*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126); x := NewBoolConst(FALSE)
                   ELSIF f # OPM.Bool THEN err(120); x := NewBoolConst(FALSE)
                   ELSE MOp(OPM.not, x)
                   END
    ELSE OPM.LogWStr("unhandled case in OPB.StPar0, fctno = "); OPM.LogWNum(fctno, 0); OPM.LogWLn;
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
    |OPM.incfn,
     OPM.decfn:    (*INC DEC*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126); p^.typ := OPT.notyp
                   ELSE
                     IF x^.typ # p^.typ THEN
                       IF (x^.class = OPM.Nconst) & (f IN OPM.intSet) THEN Convert(x, p^.typ)
                       ELSE err(111)
                       END
                     END ;
                     p := NewOp(OPM.Nassign, fctno, p, x);
                     p^.typ := OPT.notyp
                   END
    |OPM.inclfn,
     OPM.exclfn:   (*INCL, EXCL*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f IN OPM.intSet THEN
                     IF (x^.class = OPM.Nconst) & ((0 > x^.conval^.intval) OR (x^.conval^.intval > OPM.MaxSet)) THEN err(202)
                     END ;
                     p := NewOp(OPM.Nassign, fctno, p, x)
                   ELSE err(111)
                   END ;
                   p^.typ := OPT.notyp
    |OPM.lenfn:    (*LEN*)
                   IF ~(f IN OPM.intSet) OR (x^.class # OPM.Nconst) THEN err(69)
                   ELSIF x.typ.size = 1 THEN (* Hard limit of 127 dimensions *)
                     L := SHORT(x^.conval^.intval); typ := p^.typ;
                     WHILE (L > 0) & (typ^.comp IN {OPM.DynArr, OPM.Array}) DO typ := typ^.BaseTyp; DEC(L) END ;
                     IF (L # 0) OR ~(typ^.comp IN {OPM.DynArr, OPM.Array}) THEN err(132)
                     ELSE x^.obj := NIL;
                       IF typ^.comp = OPM.DynArr THEN
                         WHILE p^.class = OPM.Nindex DO p := p^.left; INC(x^.conval^.intval) END ;  (* possible side effect ignored *)
                         p := NewOp(OPM.Ndop, OPM.len, p, x); p^.typ := OPT.linttyp
                       ELSE p := x; p^.conval^.intval := typ^.n; SetIntType(p)
                       END
                     END
                   ELSE err(132)
                   END
    |OPM.copyfn:   (*COPY*)
                   IF NotVar(x) THEN err(112)
                   ELSIF (x^.typ^.comp IN {OPM.Array, OPM.DynArr}) & (x^.typ^.BaseTyp^.form = OPM.Char) THEN
                     IF x^.readonly THEN err(76) END ;
                     t := x; x := p; p := t; p := NewOp(OPM.Nassign, OPM.copyfn, p, x)
                   ELSE err(111)
                   END ;
                   p^.typ := OPT.notyp
    |OPM.ashfn:    (*ASH*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f IN OPM.intSet THEN
                     IF (p^.class = OPM.Nconst) & (x^.class = OPM.Nconst) THEN
                       IF (-maxExp > x^.conval^.intval) OR (x^.conval^.intval > maxExp) THEN err(208); p^.conval^.intval := 1
                       ELSIF x^.conval^.intval >= 0 THEN
                         IF ABS(p^.conval^.intval) <= MAX(LONGINT) DIV ASH(1, x^.conval^.intval) THEN
                           p^.conval^.intval := p^.conval^.intval * ASH(1, x^.conval^.intval)
                         ELSE err(208); p^.conval^.intval := 1
                         END
                       ELSE p^.conval^.intval := ASH(p^.conval^.intval, x^.conval^.intval)
                       END ;
                       p^.obj := NIL
                     ELSE p := NewOp(OPM.Ndop, OPM.ash, p, x); p^.typ := OPT.linttyp
                     END
                   ELSE err(111)
                   END
    |OPM.newfn:    (*NEW(p, x...)*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF p^.typ^.comp = OPM.DynArr THEN
                     IF f IN OPM.intSet THEN
                       IF (x^.class = OPM.Nconst) & ((x^.conval^.intval <= 0) OR (x^.conval^.intval > OPM.MaxIndex)) THEN err(63) END
                     ELSE err(111)
                     END ;
                     p^.right := x; p^.typ := p^.typ^.BaseTyp
                   ELSE err(64)
                   END
    |OPM.lshfn,
     OPM.rotfn:    (*SYSTEM.LSH, SYSTEM.ROT*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF ~(f IN OPM.intSet) THEN err(111)
                   ELSE
                     IF fctno = OPM.lshfn THEN p := NewOp(OPM.Ndop, OPM.lsh, p, x) ELSE p := NewOp(OPM.Ndop, OPM.rot, p, x) END ;
                     p^.typ := p^.left^.typ
                   END
    |OPM.getfn,
     OPM.putfn,
     OPM.getrfn,
     OPM.putrfn:   (*SYSTEM.GET, SYSTEM.PUT, SYSTEM.GETREG, SYSTEM.PUTREG*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f IN {OPM.Undef..OPM.Set, OPM.Pointer, OPM.ProcTyp} THEN
                     IF (fctno = OPM.getfn) OR (fctno = OPM.getrfn) THEN
                       IF NotVar(x) THEN err(112) END ;
                       t := x; x := p; p := t
                     END ;
                     p := NewOp(OPM.Nassign, fctno, p, x)
                   ELSE err(111)
                   END ;
                   p^.typ := OPT.notyp
    |OPM.bitfn:    (*SYSTEM.BIT*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f IN OPM.intSet THEN
                     p := NewOp(OPM.Ndop, OPM.bit, p, x)
                   ELSE err(111)
                   END ;
                   p^.typ := OPT.booltyp
    |OPM.valfn:    (*SYSTEM.VAL*)  (* type is changed without considering the byte ordering on the target machine *)
                   IF (x^.class = OPM.Ntype)
                   OR (x^.class = OPM.Nproc)
                   OR (f IN {OPM.Undef, OPM.String, OPM.NoTyp})
                   OR (x^.typ^.comp = OPM.DynArr) THEN
                     err(126)
                   END;
                   (* Warn if the result type includes memory past the end of the source variable *)
                   IF x.typ.size < p.typ.size THEN err(-308) END;
                   t := OPT.NewNode(OPM.Nmop); t^.subcl := OPM.val; t^.left := x; x := t;
                   (*
                   IF (x^.class >= OPM.Nconst) OR ((f IN OPM.realSet) # (p^.typ^.form IN OPM.realSet)) THEN
                     t := OPT.NewNode(OPM.Nmop); t^.subcl := val; t^.left := x; x := t
                   ELSE x^.readonly := FALSE
                   END ;
                   *)
                   x^.typ := p^.typ; p := x
    |OPM.sysnewfn: (*SYSTEM.NEW*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF f IN OPM.intSet THEN
                     p := NewOp(OPM.Nassign, OPM.sysnewfn, p, x)
                   ELSE err(111)
                   END ;
                   p^.typ := OPT.notyp
    |OPM.movefn:   (*SYSTEM.MOVE*)
                   IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
                   ELSIF (x^.class = OPM.Nconst) & (f IN OPM.intSet) & (x.typ.size < OPT.linttyp.size) THEN Convert(x, OPT.linttyp)
                   ELSIF ~((x.typ.form IN {OPM.Pointer} + OPM.intSet) & (x.typ.size = OPM.PointerSize)) THEN err(111); x^.typ := OPT.linttyp
                   END;
                   p^.link := x
    |OPM.assertfn: (*ASSERT*)
                   IF (f IN OPM.intSet) & (x^.class = OPM.Nconst) THEN
                     IF (OPM.MinHaltNr <= x^.conval^.intval) & (x^.conval^.intval <= OPM.MaxHaltNr) THEN
                       BindNodes(OPM.Ntrap, OPT.notyp, x, x);
                       x^.conval := OPT.NewConst(); x^.conval^.intval := OPM.errpos;
                       Construct(OPM.Nif, p, x); p^.conval := OPT.NewConst(); p^.conval^.intval := OPM.errpos;
                       Construct(OPM.Nifelse, p, NIL); OptIf(p);
                       IF p = NIL THEN  (* ASSERT(TRUE) *)
                       ELSIF p^.class = OPM.Ntrap THEN err(99)
                       ELSE p^.subcl := OPM.assertfn
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
    IF fctno = OPM.newfn THEN (*NEW(p, ..., x...*)
      IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
      ELSIF p^.typ^.comp # OPM.DynArr THEN err(64)
      ELSIF f IN OPM.intSet THEN
        IF (x^.class = OPM.Nconst) & ((x^.conval^.intval <= 0) OR (x^.conval^.intval > OPM.MaxIndex)) THEN err(63) END ;
        node := p^.right; WHILE node^.link # NIL DO node := node^.link END;
        node^.link := x; p^.typ := p^.typ^.BaseTyp
      ELSE err(111)
      END
    ELSIF (fctno = OPM.movefn) & (n = 2) THEN (*SYSTEM.MOVE*)
      IF (x^.class = OPM.Ntype) OR (x^.class = OPM.Nproc) THEN err(126)
      ELSIF f IN OPM.intSet THEN
        node := OPT.NewNode(OPM.Nassign); node^.subcl := OPM.movefn; node^.right := p;
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
    IF fctno <= OPM.ashfn THEN
      IF (fctno = OPM.newfn) & (p^.typ # OPT.notyp) THEN
        IF p^.typ^.comp = OPM.DynArr THEN err(65) END ;
        p^.typ := OPT.notyp
      ELSIF fctno <= OPM.sizefn THEN (* 1 param *)
        IF parno < 1 THEN err(65) END
      ELSE (* more than 1 param *)
        IF ((fctno = OPM.incfn) OR (fctno = OPM.decfn)) & (parno = 1) THEN (*INC, DEC*)
          BindNodes(OPM.Nassign, OPT.notyp, p, NewIntConst(1)); p^.subcl := fctno; p^.right^.typ := p^.left^.typ
        ELSIF (fctno = OPM.lenfn) & (parno = 1) THEN (*LEN*)
          IF p^.typ^.comp = OPM.DynArr THEN dim := 0;
            WHILE p^.class = OPM.Nindex DO p := p^.left; INC(dim) END ;  (* possible side effect ignored *)
            BindNodes(OPM.Ndop, OPT.linttyp, p, NewIntConst(dim)); p^.subcl := OPM.len
          ELSE
            p := NewIntConst(p^.typ^.n)
          END
        ELSIF parno < 2 THEN err(65)
        END
      END
    ELSIF fctno = OPM.assertfn THEN
      IF parno = 1 THEN x := NIL;
        BindNodes(OPM.Ntrap, OPT.notyp, x, NewIntConst(AssertTrap));
        x^.conval := OPT.NewConst(); x^.conval^.intval := OPM.errpos;
        Construct(OPM.Nif, p, x); p^.conval := OPT.NewConst(); p^.conval^.intval := OPM.errpos;
        Construct(OPM.Nifelse, p, NIL); OptIf(p);
        IF p = NIL THEN  (* ASSERT(TRUE) *)
        ELSIF p^.class = OPM.Ntrap THEN err(99)
        ELSE p^.subcl := OPM.assertfn
        END
      ELSIF parno < 1 THEN err(65)
      END
    ELSE (*SYSTEM*)
      IF (parno < 1) OR
        (fctno > OPM.ccfn) & (parno < 2) OR
        (fctno = OPM.movefn) & (parno < 3) THEN err(65)
      END
    END ;
    par0 := p
  END StFct;

  PROCEDURE DynArrParCheck(ftyp, atyp: OPT.Struct; fvarpar: BOOLEAN);
    VAR f: INTEGER;
  BEGIN (* ftyp^.comp = OPM.DynArr *)
    f := atyp^.comp; ftyp := ftyp^.BaseTyp; atyp := atyp^.BaseTyp;
    IF fvarpar & (ftyp = OPT.bytetyp) THEN (* ok, but ... *)
      IF ~(f IN {OPM.Array, OPM.DynArr}) OR ~((atyp.form IN {OPM.Byte..OPM.Char} + OPM.intSet) & (atyp.size = 1)) THEN
        IF OPM.verbose IN OPM.opt THEN err(-301) END
      END
    ELSIF f IN {OPM.Array, OPM.DynArr} THEN
      IF ftyp^.comp = OPM.DynArr THEN DynArrParCheck(ftyp, atyp, fvarpar)
      ELSIF ftyp # atyp THEN
        IF ~fvarpar & (ftyp.form = OPM.Pointer) & (atyp.form = OPM.Pointer) THEN
          ftyp := ftyp^.BaseTyp; atyp := atyp^.BaseTyp;
          IF (ftyp^.comp = OPM.Record) & (atyp^.comp = OPM.Record) THEN
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
    IF fp^.typ^.form = OPM.Pointer THEN
      IF x^.class = OPM.Nderef THEN x := x^.left (*undo DeRef*) ELSE (*x^.typ^.comp = OPM.Record*) err(71) END
    END
  END CheckReceiver;

  PROCEDURE PrepCall*(VAR x: OPT.Node; VAR fpar: OPT.Object);
  BEGIN
    IF (x^.obj # NIL) & (x^.obj^.mode IN {OPM.LProc, OPM.XProc, OPM.TProc, OPM.CProc}) THEN
      fpar := x^.obj^.link;
      IF x^.obj^.mode = OPM.TProc THEN CheckReceiver(x^.left, fpar); fpar := fpar^.link END
    ELSIF (x^.class # OPM.Ntype) & (x^.typ # NIL) & (x^.typ^.form = OPM.ProcTyp) THEN
      fpar := x^.typ^.link
    ELSE err(121); fpar := NIL; x^.typ := OPT.undftyp
    END
  END PrepCall;

  PROCEDURE Param*(ap: OPT.Node; fp: OPT.Object);
    VAR q: OPT.Struct;
  BEGIN
    IF fp.typ.form # OPM.Undef THEN
      IF fp^.mode = OPM.VarPar THEN
        IF NotVar(ap) THEN err(122)
        ELSE CheckLeaf(ap, FALSE)
        END ;
        IF ap^.readonly THEN err(76) END ;
        IF fp^.typ^.comp = OPM.DynArr THEN DynArrParCheck(fp^.typ, ap^.typ, TRUE)
        ELSIF (fp^.typ^.comp = OPM.Record) & (ap^.typ^.comp = OPM.Record) THEN
          q := ap^.typ;
          WHILE (q # fp^.typ) & (q # NIL) & (q # OPT.undftyp) DO q := q^.BaseTyp END ;
          IF q = NIL THEN err(111) END
        ELSIF (fp^.typ = OPT.sysptrtyp) & (ap^.typ^.form = OPM.Pointer) THEN (* ok *)
        ELSIF (ap^.typ # fp^.typ) & ~((fp^.typ^.form = OPM.Byte) & ((ap.typ.form IN {OPM.Byte..OPM.Char} + OPM.intSet) & (ap.typ.size = 1))) THEN err(123)
        ELSIF (fp^.typ^.form = OPM.Pointer) & (ap^.class = OPM.Nguard) THEN err(123)
        END
      ELSIF fp^.typ^.comp = OPM.DynArr THEN
        IF (ap^.class = OPM.Nconst) & (ap^.typ^.form = OPM.Char) THEN CharToString(ap) END ;
        IF (ap^.typ^.form = OPM.String) & (fp^.typ^.BaseTyp^.form = OPM.Char) THEN (* ok *)
        ELSIF ap^.class >= OPM.Nconst THEN err(59)
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
      INCL(scope^.link^.conval^.setval, OPM.slNeeded);
      scope := scope^.left
    END
  END StaticLink;

  PROCEDURE Call*(VAR x: OPT.Node; apar: OPT.Node; fp: OPT.Object);
    VAR typ: OPT.Struct; p: OPT.Node; lev: SHORTINT;
  BEGIN
    IF x^.class = OPM.Nproc THEN typ := x^.typ;
      lev := x^.obj^.mnolev;
      IF lev > 0 THEN StaticLink(OPT.topScope^.mnolev-lev) END ;
      IF x^.obj^.mode = OPM.IProc THEN err(121) END
    ELSIF (x^.class = OPM.Nfield) & (x^.obj^.mode = OPM.TProc) THEN typ := x^.typ;
      x^.class := OPM.Nproc; p := x^.left; x^.left := NIL; p^.link := apar; apar := p; fp := x^.obj^.link
    ELSE typ := x^.typ^.BaseTyp
    END ;
    BindNodes(OPM.Ncall, typ, x, apar); x^.obj := fp
  END Call;

  PROCEDURE Enter*(VAR procdec: OPT.Node; stat: OPT.Node; proc: OPT.Object);
    VAR x: OPT.Node;
  BEGIN
    x := OPT.NewNode(OPM.Nenter); x^.typ := OPT.notyp; x^.obj := proc;
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
    node := OPT.NewNode(OPM.Nreturn); node^.typ := OPT.notyp; node^.obj := proc; node^.left := x; x := node
  END Return;

  PROCEDURE Assign*(VAR x: OPT.Node; y: OPT.Node);
    VAR z: OPT.Node; subcl: SHORTINT;
  BEGIN
    IF x^.class >= OPM.Nconst THEN err(56) END ;
    CheckAssign(x^.typ, y);
    IF x^.readonly THEN err(76) END ;
    IF x^.typ^.comp = OPM.Record THEN
      IF x^.class = OPM.Nguard THEN z := x^.left ELSE z := x END ;
      IF (z^.class = OPM.Nderef) & (z^.left^.class = OPM.Nguard) THEN
        z^.left := z^.left^.left  (* skip guard before dereferencing *)
      END ;
      IF (x^.typ^.strobj # NIL) & ((z^.class = OPM.Nderef) OR (z^.class = OPM.Nvarpar)) THEN
        BindNodes(OPM.Neguard, x^.typ, z, NIL); x := z
      END
    ELSIF (x^.typ^.comp = OPM.Array) & (x^.typ^.BaseTyp = OPT.chartyp) &
        (y^.typ^.form = OPM.String) & (y^.conval^.intval2 = 1) THEN  (* replace array := "" with array[0] := 0X *)
      y^.typ := OPT.chartyp; y^.conval^.intval := 0;
      Index(x, NewIntConst(0))
    END ;
    IF (x.typ.comp IN {OPM.Array, OPM.DynArr}) & (x.typ.BaseTyp = OPT.chartyp)
     & (y.typ.comp IN {OPM.Array, OPM.DynArr}) & (y.typ.BaseTyp = OPT.chartyp) THEN
      subcl := OPM.copyfn
    ELSE
      subcl := OPM.assign
    END;
    BindNodes(OPM.Nassign, OPT.notyp, x, y);
    x^.subcl := subcl;
  END Assign;

  PROCEDURE Inittd*(VAR inittd, last: OPT.Node; typ: OPT.Struct);
    VAR node: OPT.Node;
  BEGIN
    node := OPT.NewNode(OPM.Ninittd); node^.typ := typ;
    node^.conval := OPT.NewConst(); node^.conval^.intval := typ^.txtpos;
    IF inittd = NIL THEN inittd := node ELSE last^.link := node END ;
    last := node
  END Inittd;

BEGIN
  maxExp := log(MAX(LONGINT) DIV 2 + 1); maxExp := exp
END OPB.
