MODULE OPV;  (* J. Templ 16.2.95 / 3.7.96 

  26.7.2002 jt bug fix in Len: wrong result if called for fixed Array
  31.1.2007 jt synchronized with BlackBox version, in particular:
    various promotion rules changed (long) => (LONGINT), xxxL avoided
*)

  IMPORT OPT, OPC, OPM, OPS;
  
  CONST
    (* object modes *)
    Var = 1; VarPar = 2; Fld = 4; Typ = 5; LProc = 6; XProc = 7;
    CProc = 9; IProc = 10; Mod = 11; TProc = 13;

    (* symbol values or ops *)
    times = 1; slash = 2; div = 3; mod = 4;
    and = 5; plus = 6; minus = 7; or = 8; eql = 9;
    neq = 10; lss = 11; leq = 12; gtr = 13; geq = 14;
    in = 15; is = 16; ash = 17; msk = 18; len = 19;
    conv = 20; abs = 21; cap = 22; odd = 23; not = 33;
    (*SYSTEM*)
    adr = 24; cc = 25; bit = 26; lsh = 27; rot = 28; val = 29;

    (* structure forms *)
    Byte = 1; Bool = 2; Char = 3;
    SInt = 4; Int = 5; LInt = 6;
    Real = 7; LReal = 8; Set = 9; String = 10; NilTyp = 11; NoTyp = 12;
    Pointer = 13; ProcTyp = 14;
    Comp = 15;
    (*Int8 = 7; Int16 = 8; Int32 = 9; Int64 = 10;
    Real = 11; LReal = 12; Set = 13; String = 14; NilTyp = 15; NoTyp = 16;
    Pointer = 17; ProcTyp = 18;
    Comp = 19;*)
    (*Real = 7; LReal = 8; Set = 9; String = 10; NilTyp = 11; Pointer = 13; ProcTyp = 14; 
    Int8 = 15; Int16 = 16; Int32 = 17; Int64 = 18; 
    Comp = (*15*)19;*)

    (* composite structure forms *)
    Array = 2; DynArr = 3; Record = 4;

    (* nodes classes *)
    Nvar = 0; Nvarpar = 1; Nfield = 2; Nderef = 3; Nindex = 4; Nguard = 5; Neguard = 6;
    Nconst = 7; Ntype = 8; Nproc = 9; Nupto = 10; Nmop = 11; Ndop = 12; Ncall = 13;
    Ninittd = 14; Nenter = 18; Nassign = 19;
    Nifelse =20; Ncase = 21; Nwhile = 22; Nrepeat = 23; Nloop = 24; Nexit = 25;
    Nreturn = 26; Nwith = 27; Ntrap = 28;

    (*function number*)
    assign = 0; newfn = 1; incfn = 13; decfn = 14;
    inclfn = 15; exclfn = 16; copyfn = 18; assertfn = 32;

    (*SYSTEM function number*)
    getfn = 24; putfn = 25; getrfn = 26; putrfn = 27; sysnewfn = 30; movefn = 31;

    (*procedure flags*)
    isRedef = 2;

    super = 1;

    UndefinedType = 0; (* named type not yet defined *)
    ProcessingType = 1; (* pointer type is being processed *)
    PredefinedType = 2; (* for all predefined types *)
    DefinedInHdr = 3+OPM.HeaderFile; (* named type has been defined in header file *)
    DefinedInBdy = 3+OPM.BodyFile; (* named type has been defined in body file *)

    OpenParen = "(";
    CloseParen = ")";
    OpenBracket = "[";
    CloseBracket = "]";
    Blank = " ";
    Comma = ", ";
    Deref = "*";
    EntierFunc = "__ENTIER(";
    IsFunc = "__IS(";
    IsPFunc = "__ISP(";
    GuardPtrFunc = "__GUARDP(";
    GuardRecFunc = "__GUARDR(";
    TypeFunc = "__TYPEOF(";
    SetOfFunc = "__SETOF(";
    SetRangeFunc = "__SETRNG(";
    CopyFunc = "__COPY(";
    MoveFunc = "__MOVE(";
    GetFunc = "__GET(";
    PutFunc = "__PUT(";
    DynTypExt = "__typ";
    WithChk = "__WITHCHK";
    Break = "break";
    ElseStat = "else ";

    MinPrec = -1;
    MaxPrec = 12;
    ProcTypeVar = 11; (* precedence number when a call is made with a proc type variable *)

    internal = 0;

  TYPE
    ExitInfo = RECORD level, label: INTEGER END ;


  VAR
    assert, inxchk, mainprog, ansi: BOOLEAN;
    stamp: INTEGER;  (* unique number for nested objects *)
    (*recno: INTEGER;*)  (* number of anonymous record types *)
    recno: LONGINT;  (* number of anonymous record types *)

    exit: ExitInfo;  (* to check if EXIT is simply a break *)
    nofExitLabels: INTEGER;
    naturalAlignment: BOOLEAN;


  PROCEDURE NaturalAlignment(size, max: LONGINT): LONGINT;
    VAR i: LONGINT;
  BEGIN
    IF size >= max THEN RETURN max
    ELSE i := 1;
      WHILE i < size DO INC(i, i) END ;
      RETURN i
    END
  END NaturalAlignment;

  PROCEDURE TypSize*(typ: OPT.Struct);
    VAR f, c: INTEGER; offset, size, base, fbase, off0: LONGINT;
      fld: OPT.Object; btyp: OPT.Struct;
  BEGIN
    IF typ = OPT.undftyp THEN OPM.err(58)
    ELSIF typ^.size = -1 THEN
      f := typ^.form; c := typ^.comp;
      IF c = Record THEN btyp := typ^.BaseTyp;
        IF btyp = NIL THEN offset := 0; base := OPM.RecAlign;
        ELSE TypSize(btyp); offset := btyp^.size - btyp^.sysflag DIV 100H; base := btyp^.align;
        END;
        fld := typ^.link;
        WHILE (fld # NIL) & (fld^.mode = Fld) DO
          btyp := fld^.typ; TypSize(btyp);
          size := btyp^.size; fbase := OPC.Base(btyp);
          OPC.Align(offset, fbase);
          fld^.adr := offset; INC(offset, size);
          IF fbase > base THEN base := fbase END ;
          fld := fld^.link
        END ;
        off0 := offset;
        IF offset = 0 THEN offset := 1 END ;  (* 1 byte filler to avoid empty struct *)
        IF OPM.RecSize = 0 THEN base := NaturalAlignment(offset, OPM.RecAlign) END ;
        OPC.Align(offset, base);
        IF (typ^.strobj = NIL) & (typ^.align MOD 10000H = 0) THEN INC(recno); INC(base, recno * 10000H) END ;
        typ^.size := offset; typ^.align := base;
        (* encode the trailing gap into the symbol table to allow dense packing of extended records *)
        typ^.sysflag := typ^.sysflag MOD 100H + SHORT((offset - off0)*100H)  
      ELSIF c = Array THEN
        TypSize(typ^.BaseTyp);
        typ^.size := typ^.n * typ^.BaseTyp^.size;
      ELSIF f = Pointer THEN
        typ^.size := OPM.PointerSize;
        IF typ^.BaseTyp = OPT.undftyp THEN OPM.Mark(128, typ^.n)
        ELSE TypSize(typ^.BaseTyp)
        END
      ELSIF f = ProcTyp THEN
        typ^.size := OPM.ProcSize;
      ELSIF c = DynArr THEN
        btyp := typ^.BaseTyp; TypSize(btyp);
        IF btyp^.comp = DynArr THEN typ^.size := btyp^.size + 4  (* describes dim not size *)
        ELSE typ^.size := 8
        END ;
      END
    END
  END TypSize;

  PROCEDURE Init*;
  BEGIN
    stamp := 0; recno := 0; nofExitLabels := 0;
    assert := OPM.assert IN OPM.opt;
    inxchk := OPM.inxchk IN OPM.opt;
    mainprog := OPM.mainprog IN OPM.opt;
    ansi := OPM.ansi IN OPM.opt
  END Init;
  
  PROCEDURE ^Traverse (obj, outerScope: OPT.Object; exported: BOOLEAN);

  PROCEDURE GetTProcNum(obj: OPT.Object);
    VAR oldPos: LONGINT; typ: OPT.Struct; redef: OPT.Object;
  BEGIN
    oldPos := OPM.errpos; OPM.errpos := obj^.scope^.adr;
    typ := obj^.link^.typ;
    IF typ^.form = Pointer THEN typ := typ^.BaseTyp END ;
    OPT.FindField(obj^.name, typ^.BaseTyp, redef);
    IF redef # NIL THEN obj^.adr := 10000H*(redef^.adr DIV 10000H) (*mthno*);
      IF ~(isRedef IN obj^.conval^.setval) THEN OPM.err(119) END
    ELSE INC(obj^.adr, 10000H*typ^.n); INC(typ^.n)
    END ;
    OPM.errpos := oldPos
  END GetTProcNum;

  PROCEDURE TraverseRecord(typ: OPT.Struct);
  BEGIN
    IF ~typ^.allocated THEN
      IF typ^.BaseTyp # NIL THEN TraverseRecord(typ^.BaseTyp); typ^.n := typ^.BaseTyp^.n END ;
       typ^.allocated := TRUE; Traverse(typ^.link, typ^.strobj, FALSE)
    END
  END TraverseRecord;

  PROCEDURE Stamp(VAR s: OPS.Name);
    VAR i, j, k: INTEGER; n: ARRAY 10 OF CHAR;
  BEGIN INC(stamp);
    i := 0; j := stamp;
    WHILE s[i] # 0X DO INC(i) END ;
    IF i > 25 THEN i := 25 END ;
    s[i] := "_"; s[i+1] := "_"; INC(i, 2); k := 0;
    REPEAT n[k] := CHR((j MOD 10) + ORD("0")); j := j DIV 10; INC(k) UNTIL j = 0;
    REPEAT DEC(k); s[i] := n[k]; INC(i) UNTIL k = 0;
    s[i] := 0X;
  END Stamp;

  PROCEDURE Traverse (obj, outerScope: OPT.Object; exported: BOOLEAN);
    VAR mode: INTEGER; scope: OPT.Object; typ: OPT.Struct;
  BEGIN
    IF obj # NIL THEN
      Traverse(obj^.left, outerScope, exported);
      IF obj^.name[0] = "@" THEN obj^.name[0] := "_"; Stamp(obj^.name) END ;  (* translate and make unique @for, ... *)
      obj^.linkadr := UndefinedType;
      mode := obj^.mode;
      IF (mode = Typ) & ((obj^.vis # internal) = exported) THEN
        typ := obj^.typ; TypSize(obj^.typ);
        IF typ^.form = Pointer THEN typ := typ^.BaseTyp END ;
        IF typ^.comp = Record THEN TraverseRecord(typ) END
      ELSIF mode = TProc THEN GetTProcNum(obj)
      ELSIF mode = Var THEN TypSize(obj^.typ)
      END ;
      IF ~exported THEN (* do this only once *)
        IF (mode IN {LProc, Typ}) & (obj^.mnolev > 0) THEN Stamp(obj^.name) END ;
        IF mode IN {Var, VarPar, Typ} THEN
          obj^.scope := outerScope
        ELSIF mode IN {LProc, XProc, TProc, CProc, IProc} THEN
          IF obj^.conval^.setval = {} THEN OPM.err(129) END ;
          scope := obj^.scope;
          scope^.leaf := TRUE;
          scope^.name := obj^.name; Stamp(scope^.name);
          IF mode = CProc THEN obj^.adr := 1 (* c.f. OPC.CProcDefs *) END ;
          IF scope^.mnolev > 1 THEN outerScope^.leaf := FALSE END ;
          Traverse (obj^.scope^.right, obj^.scope, FALSE)
        END
      END;
      Traverse(obj^.right, outerScope, exported);
    END
  END Traverse;

  PROCEDURE AdrAndSize* (topScope: OPT.Object);
  BEGIN
    OPM.errpos := topScope^.adr;  (* text position of scope used if error *)
    topScope^.leaf := TRUE;
    Traverse(topScope^.right, topScope, TRUE);  (* first pass only on exported types and procedures  *)
    Traverse(topScope^.right, topScope, FALSE);  (* second pass *)
    (* mark basic types as predefined, OPC.Ident can avoid qualification*)
    OPT.chartyp^.strobj^.linkadr := PredefinedType;
    OPT.settyp^.strobj^.linkadr := PredefinedType;
    OPT.realtyp^.strobj^.linkadr := PredefinedType;
    OPT.inttyp^.strobj^.linkadr := PredefinedType;
    OPT.linttyp^.strobj^.linkadr := PredefinedType;
    OPT.lrltyp^.strobj^.linkadr := PredefinedType;
    OPT.sinttyp^.strobj^.linkadr := PredefinedType;
    OPT.booltyp^.strobj^.linkadr := PredefinedType;
    OPT.bytetyp^.strobj^.linkadr := PredefinedType;
    (*OPT.int8typ^.strobj^.linkadr := PredefinedType;
    OPT.int16typ^.strobj^.linkadr := PredefinedType;
    OPT.int32typ^.strobj^.linkadr := PredefinedType;
    OPT.int64typ^.strobj^.linkadr := PredefinedType;*)
    OPT.sysptrtyp^.strobj^.linkadr := PredefinedType;
  END AdrAndSize;

(* ____________________________________________________________________________________________________________________________________________________________________ *)

  PROCEDURE Precedence (class, subclass, form, comp: INTEGER): INTEGER;
  BEGIN
    CASE class OF
      Nconst, Nvar, Nfield, Nindex, Nproc, Ncall:
          RETURN 10
    |  Nguard: IF OPM.typchk IN OPM.opt THEN RETURN 10 ELSE RETURN 9 (*cast*) END
    |  Nvarpar:
          IF comp IN {Array, DynArr} THEN RETURN 10 ELSE RETURN 9 END (* arrays don't need deref *)
    |  Nderef:
          RETURN 9
    |  Nmop:
          CASE subclass OF
            not, minus, adr, val, conv:
                RETURN 9
          |  is, abs, cap, odd, cc:
                RETURN 10
          END
    |  Ndop:
          CASE subclass OF
            times:
                IF form = Set THEN RETURN 4 ELSE RETURN 8 END
          |  slash:
                IF form = Set THEN RETURN 3 ELSE RETURN 8 END
          |  div, mod:
                RETURN 10 (* div/mod are replaced by functions *)
          |  plus:
                IF form = Set THEN RETURN 2 ELSE RETURN 7 END
          |  minus:
                IF form = Set THEN RETURN 4 ELSE RETURN 7 END
          |  lss, leq, gtr, geq:
                RETURN 6
          |  eql, neq:
                RETURN 5
          |  and:
                RETURN 1
          |  or:
                RETURN 0
          |  len, in, ash, msk, bit, lsh, rot:
                RETURN 10
	  ELSE
	     OPM.LogWStr("unhandled case in OPV.Precedence, subclass = "); OPM.LogWNum(subclass, 0); OPM.LogWLn;
          END;
    |  Nupto:
          RETURN 10
    |  Ntype, Neguard: (* ignored anyway *)
          RETURN MaxPrec
    ELSE
       OPM.LogWStr("unhandled case in OPV.Precedence, class = "); OPM.LogWNum(class, 0); OPM.LogWLn;
    END;
  END Precedence;

  PROCEDURE^ expr (n: OPT.Node; prec: INTEGER);
  PROCEDURE^ design(n: OPT.Node; prec: INTEGER);

  PROCEDURE Len(n: OPT.Node; dim: LONGINT);
  BEGIN
    WHILE (n^.class = Nindex) & (n^.typ^.comp = DynArr(*26.7.2002*)) DO INC(dim); n := n^.left END ;
    IF (n^.class = Nderef) & (n^.typ^.comp = DynArr) THEN
      design(n^.left, 10); OPM.WriteString("->len["); OPM.WriteInt(dim); OPM.Write("]")
    ELSE
      OPC.Len(n^.obj, n^.typ, dim)
    END
  END Len;

  PROCEDURE SideEffects(n: OPT.Node): BOOLEAN;
  BEGIN
    IF n # NIL THEN RETURN (n^.class = Ncall) OR SideEffects(n^.left) OR SideEffects(n^.right)
    ELSE RETURN FALSE
    END
  END SideEffects;

  PROCEDURE Entier(n: OPT.Node; prec: INTEGER);
  BEGIN
    IF n^.typ^.form IN {Real, LReal} THEN
      OPM.WriteString(EntierFunc); expr(n, MinPrec); OPM.Write(CloseParen)
    ELSE expr(n, prec)
    END
  END Entier;

  PROCEDURE Convert(n: OPT.Node; form, prec: INTEGER);
    VAR from: INTEGER;
  BEGIN from := n^.typ^.form;
    IF form = Set THEN OPM.WriteString(SetOfFunc); Entier(n, MinPrec); OPM.Write(CloseParen)
    ELSIF form = LInt THEN
      IF from < LInt THEN OPM.WriteString("(LONGINT)") END ;
      Entier(n, 9)
    (*ELSIF form = Int64 THEN
       IF (from >= SInt) & (from <= LInt) OR (from >= Int8) & (from < Int64) THEN OPM.WriteString("(SYSTEM_INT64)") END; 
       Entier(n, 9);*)
    ELSIF form = Int THEN
      IF from < Int THEN OPM.WriteString("(int)"); expr(n, 9)
      ELSE
        IF OPM.ranchk IN OPM.opt THEN OPM.WriteString("__SHORT");
          IF SideEffects(n) THEN OPM.Write("F") END ;
          OPM.Write(OpenParen); Entier(n, MinPrec);
          OPM.WriteString(Comma); OPM.WriteInt(OPM.MaxInt + 1); OPM.Write(CloseParen)
        ELSE OPM.WriteString("(int)"); Entier(n, 9)
        END
      END
    ELSIF form = SInt THEN
      IF OPM.ranchk IN OPM.opt THEN OPM.WriteString("__SHORT");
        IF SideEffects(n) THEN OPM.Write("F") END ;
        OPM.Write(OpenParen); Entier(n, MinPrec);
        OPM.WriteString(Comma); OPM.WriteInt(OPM.MaxSInt + 1); OPM.Write(CloseParen)
      ELSE OPM.WriteString("(int)"); Entier(n, 9)
      END
    ELSIF form = Char THEN
      IF OPM.ranchk IN OPM.opt THEN OPM.WriteString("__CHR");
        IF SideEffects(n) THEN OPM.Write("F") END ;
        OPM.Write(OpenParen); Entier(n, MinPrec); OPM.Write(CloseParen)
      ELSE OPM.WriteString("(CHAR)"); Entier(n, 9)
      END
    ELSE expr(n, prec)
    END
  END Convert;

  PROCEDURE TypeOf(n: OPT.Node);
  BEGIN
    IF n^.typ^.form = Pointer THEN
      OPM.WriteString(TypeFunc); expr(n, MinPrec); OPM.Write(")")
    ELSIF n^.class IN {Nvar, Nindex, Nfield} THEN  (* dyn rec type = stat rec type *)
      OPC.Andent(n^.typ); OPM.WriteString(DynTypExt)
    ELSIF n^.class = Nderef THEN  (* p^ *)
      OPM.WriteString(TypeFunc); expr(n^.left, MinPrec); OPM.Write(")")
    ELSIF n^.class = Nguard THEN  (* r(T) *)
      TypeOf(n^.left)  (* skip guard *)
    ELSIF (n^.class = Nmop) & (n^.subcl = val) THEN
      (*SYSTEM.VAL(typ, var par rec)*)
      OPC.TypeOf(n^.left^.obj)
    ELSE  (* var par rec *)
      OPC.TypeOf(n^.obj)
    END
  END TypeOf;

  PROCEDURE Index(n, d: OPT.Node; prec, dim: INTEGER);
  BEGIN
    IF ~inxchk
    OR (n^.right^.class = Nconst) & ((n^.right^.conval^.intval = 0) OR (n^.left^.typ^.comp # DynArr)) THEN
      expr(n^.right, prec)
    ELSE
      IF SideEffects(n^.right) THEN OPM.WriteString("__XF(") ELSE OPM.WriteString("__X(") END ;
      expr(n^.right, MinPrec); OPM.WriteString(Comma); Len(d, dim); OPM.Write(CloseParen)
    END
  END Index;

  PROCEDURE design(n: OPT.Node; prec: INTEGER);
    VAR obj: OPT.Object; typ: OPT.Struct;
      class, designPrec, comp: INTEGER;
      d, x: OPT.Node; dims, i: INTEGER;
  BEGIN
    comp := n^.typ^.comp; obj := n^.obj; class := n^.class;
    designPrec := Precedence(class, n^.subcl, n^.typ^.form, comp);
    IF (class = Nvar) & (obj^.mnolev > 0) & (obj^.mnolev # OPM.level) & (prec = 10) THEN designPrec := 9 END ;
    IF prec > designPrec THEN OPM.Write(OpenParen) END;
    IF prec = ProcTypeVar THEN OPM.Write(Deref) END; (* proc var calls must be dereferenced in K&R C *)
    CASE class OF
      Nproc:
          OPC.Ident(n^.obj)
    |  Nvar:
          OPC.CompleteIdent(n^.obj)
    |  Nvarpar:
          IF ~(comp IN {Array, DynArr}) THEN OPM.Write(Deref) END; (* deref var parameter *)
          OPC.CompleteIdent(n^.obj)
    |  Nfield:
          IF n^.left^.class = Nderef THEN design(n^.left^.left, designPrec); OPM.WriteString("->")
          ELSE design(n^.left, designPrec); OPM.Write(".")
          END ;
          OPC.Ident(n^.obj)
    |  Nderef:
          IF n^.typ^.comp = DynArr THEN design(n^.left, 10); OPM.WriteString("->data")
          ELSE OPM.Write(Deref); design(n^.left, designPrec)
          END
    |  Nindex:
          d := n^.left;
          IF d^.typ^.comp = DynArr THEN dims := 0;
            WHILE d^.class = Nindex DO d := d^.left; INC(dims) END ;
            IF n^.typ^.comp = DynArr THEN OPM.Write("&") END ;
            design(d, designPrec);
            OPM.Write(OpenBracket);
            IF n^.typ^.comp = DynArr THEN OPM.Write("(") END ;
            i := dims; x := n;
            WHILE x # d DO  (* apply Horner schema *)
              IF x^.left # d THEN Index(x, d, 7, i); OPM.WriteString(" + "); Len(d, i);  OPM.WriteString(" * ("); DEC(i)
              ELSE Index(x, d, MinPrec, i)
              END ;
              x := x^.left
            END ;
            FOR i := 1 TO dims DO OPM.Write(")") END ;
            IF n^.typ^.comp = DynArr THEN
              (*  element type is DynArr; finish Horner schema with virtual indices = 0*)
              OPM.Write(")");
              WHILE i < (d^.typ^.size - 4) DIV 4 DO
                OPM.WriteString(" * "); Len(d, i);
                INC(i)
              END
            END ;
            OPM.Write(CloseBracket)
          ELSE
            design(n^.left, designPrec);
            OPM.Write(OpenBracket);
            Index(n, n^.left, MinPrec, 0);
            OPM.Write(CloseBracket)
          END
    |  Nguard:
          typ := n^.typ; obj := n^.left^.obj;
          IF OPM.typchk IN OPM.opt THEN
            IF typ^.comp = Record THEN OPM.WriteString(GuardRecFunc); 
              IF obj^.mnolev # OPM.level THEN (*intermediate level var-par record*)
                OPM.WriteStringVar(obj^.scope^.name); OPM.WriteString("__curr->"); OPC.Ident(obj)
              ELSE (*local var-par record*)
                OPC.Ident(obj)
              END ;
            ELSE (*Pointer*)
              IF typ^.BaseTyp^.strobj = NIL THEN OPM.WriteString("__GUARDA(") ELSE OPM.WriteString(GuardPtrFunc) END ;
              expr(n^.left, MinPrec); typ := typ^.BaseTyp
            END ;
            OPM.WriteString(Comma);
            OPC.Andent(typ); OPM.WriteString(Comma);
            OPM.WriteInt(typ^.extlev); OPM.Write(")")
          ELSE
            IF typ^.comp = Record THEN (* do not cast record directly, cast pointer to record *)
              OPM.WriteString("*("); OPC.Ident(typ^.strobj); OPM.WriteString("*)"); OPC.CompleteIdent(obj)
            ELSE (*simply cast pointer*)
              OPM.Write("("); OPC.Ident(typ^.strobj); OPM.Write(")"); expr(n^.left, designPrec)
            END
          END
    |  Neguard:
          IF OPM.typchk IN OPM.opt THEN
            IF n^.left^.class = Nvarpar THEN OPM.WriteString("__GUARDEQR(");
              OPC.CompleteIdent(n^.left^.obj); OPM.WriteString(Comma); TypeOf(n^.left); 
            ELSE OPM.WriteString("__GUARDEQP("); expr(n^.left^.left, MinPrec)
            END ; (* __GUARDEQx includes deref *)
            OPM.WriteString(Comma); OPC.Ident(n^.left^.typ^.strobj); OPM.Write(")")
          ELSE
            expr(n^.left, MinPrec)  (* always lhs of assignment *)
          END
    |  Nmop:
          IF n^.subcl = val THEN design(n^.left, prec) END
    ELSE
       OPM.LogWStr("unhandled case in OPV.design, class = "); OPM.LogWNum(class, 0); OPM.LogWLn;
    END ;
    IF prec > designPrec THEN OPM.Write(CloseParen) END
  END design;

  PROCEDURE ActualPar(n: OPT.Node; fp: OPT.Object);
    VAR typ, aptyp: OPT.Struct; comp, form, mode, prec, dim: INTEGER;
  BEGIN
    OPM.Write(OpenParen);
    WHILE n # NIL DO typ := fp^.typ;
      comp := typ^.comp; form := typ^.form; mode := fp^.mode; prec := MinPrec;
      IF (mode = VarPar) & (n^.class = Nmop) & (n^.subcl = val) THEN  (* avoid cast in lvalue *)
        OPM.Write(OpenParen); OPC.Ident(n^.typ^.strobj); OPM.WriteString("*)"); prec := 10
      END ;
      IF ~(n^.typ^.comp IN {Array, DynArr}) THEN
        IF mode = VarPar THEN
          IF ansi & (typ # n^.typ) THEN OPM.WriteString("(void*)") END ;
          OPM.Write("&"); prec := 9
        ELSIF ansi THEN
          IF (comp IN {Array, DynArr}) & (n^.class = Nconst) THEN
            OPM.WriteString("(CHAR*)")  (* force to unsigned char *)
          ELSIF (form = Pointer) & (typ # n^.typ) & (n^.typ # OPT.niltyp) THEN
            OPM.WriteString("(void*)")  (* type extension *)
          END
        ELSE
          IF (form IN {Real, LReal}) & (n^.typ^.form IN {SInt, Int, LInt(*, Int8, Int16, Int32, Int64*)}) THEN (* real promotion *)
            OPM.WriteString("(double)"); prec := 9
          ELSIF (form = LInt) & (n^.typ^.form < LInt) THEN (* integral promotion *)
            OPM.WriteString("(LONGINT)"); prec := 9
	  (*ELSIF (form = Int64) & (n^.typ^.form < Int64) THEN
	    OPM.WriteString("(SYSTEM_INT64)"); prec := 9;*)
          END
        END
      ELSIF ansi THEN
        (* casting of params should be simplified eventually *)
        IF (mode = VarPar) & (typ # n^.typ) & (prec = MinPrec) THEN OPM.WriteString("(void*)") END
      END ;
      IF (mode = VarPar) & (n^.class = Nmop) & (n^.subcl = val) THEN expr(n^.left, prec)  (* avoid cast in lvalue *)
      ELSE expr(n, prec)
      END ;
      IF (form = LInt) & (n^.class = Nconst)
      & (n^.conval^.intval <= OPM.MaxInt) & (n^.conval^.intval >= OPM.MinInt) THEN
        OPM.PromoteIntConstToLInt()
      ELSIF (comp = Record) & (mode = VarPar) THEN
        OPM.WriteString(", "); TypeOf(n)
      ELSIF comp = DynArr THEN
        IF n^.class = Nconst THEN (* ap is string constant *)
          OPM.WriteString(Comma); OPM.WriteString("(LONGINT)"); OPM.WriteInt(n^.conval^.intval2)
        ELSE
          aptyp := n^.typ; dim := 0;
          WHILE (typ^.comp = DynArr) & (typ^.BaseTyp^.form # Byte) DO
            OPM.WriteString(Comma); Len(n, dim);
            typ := typ^.BaseTyp; aptyp := aptyp^.BaseTyp; INC(dim)
          END ;
          IF (typ^.comp = DynArr) & (typ^.BaseTyp^.form = Byte) THEN
            OPM.WriteString(Comma);
            WHILE aptyp^.comp = DynArr DO
              Len(n, dim); OPM.WriteString(" * "); INC(dim); aptyp := aptyp^.BaseTyp
            END ;
            OPM.WriteInt(aptyp^.size); OPM.PromoteIntConstToLInt()
          END
        END
      END ;
      n := n^.link; fp := fp^.link;
      IF n # NIL THEN OPM.WriteString(Comma) END
    END ;
    OPM.Write(CloseParen)
  END ActualPar;

  PROCEDURE SuperProc(n: OPT.Node): OPT.Object;
    VAR obj: OPT.Object; typ: OPT.Struct;
  BEGIN typ := n^.right^.typ;  (* receiver type *)
    IF typ^.form = Pointer THEN typ := typ^.BaseTyp END ;
    OPT.FindField(n^.left^.obj^.name, typ^.BaseTyp, obj);
    RETURN obj
  END SuperProc;

  PROCEDURE expr (n: OPT.Node; prec: INTEGER);
    VAR
      class: INTEGER;
      subclass: INTEGER;
      form: INTEGER;
      exprPrec: INTEGER;
      typ: OPT.Struct;
      l, r: OPT.Node;
      proc: OPT.Object;
  BEGIN
    class := n^.class; subclass := n^.subcl; form := n^.typ^.form;
    l := n^.left; r := n^.right;
    exprPrec := Precedence (class, subclass, form, n^.typ^.comp);
    IF (exprPrec <= prec) & (class IN {Nconst, Nupto, Nmop, Ndop, Ncall, Nguard, Neguard}) THEN
      OPM.Write(OpenParen);
    END;
    CASE class OF
      Nconst:
          OPC.Constant(n^.conval, form)
    |  Nupto:  (* n^.typ = OPT.settyp *)
          OPM.WriteString(SetRangeFunc); expr(l, MinPrec); OPM.WriteString(Comma); expr (r, MinPrec);
          OPM.Write(CloseParen)
    |  Nmop:
          CASE subclass OF
            not:
                OPM.Write("!"); expr(l, exprPrec)
          |  minus:
                IF form = Set THEN OPM.Write("~") ELSE OPM.Write("-"); END ;
                expr(l, exprPrec)
          |  is:  
                typ := n^.obj^.typ;
                IF l^.typ^.comp = Record THEN OPM.WriteString(IsFunc); OPC.TypeOf(l^.obj)
                ELSE OPM.WriteString(IsPFunc); expr(l, MinPrec); typ := typ^.BaseTyp
                END ;
                OPM.WriteString(Comma);
                OPC.Andent(typ); OPM.WriteString(Comma);
                OPM.WriteInt(typ^.extlev); OPM.Write(")")
          |  conv:
                Convert(l, form, exprPrec)
          |  abs:
                IF SideEffects(l) THEN
                  IF l^.typ^.form < Real THEN
                    IF l^.typ^.form < LInt THEN OPM.WriteString("(int)") END ;
                    OPM.WriteString("__ABSF(")
                  ELSE OPM.WriteString("__ABSFD(")
                  END
                ELSE OPM.WriteString("__ABS(")
                END ;
                expr(l, MinPrec); OPM.Write(CloseParen)
          |  cap:
                OPM.WriteString("__CAP("); expr(l, MinPrec); OPM.Write(CloseParen)
          |  odd:
                OPM.WriteString("__ODD("); expr(l, MinPrec); OPM.Write(CloseParen)
          |  adr: (*SYSTEM*)
                OPM.WriteString("(LONGINT)");
                IF l^.class = Nvarpar THEN OPC.CompleteIdent(l^.obj)
                ELSE
                  IF (l^.typ^.form # String) & ~(l^.typ^.comp IN {Array, DynArr}) THEN OPM.Write("&") END ;
                  expr(l, exprPrec)
                END
          |  val: (*SYSTEM*)
                IF (n^.typ^.form IN {LInt, Pointer, Set, ProcTyp}) & (l^.typ^.form IN {LInt, Pointer, Set, ProcTyp})
                & (n^.typ^.size = l^.typ^.size) OR ~(l^.class IN {Nvar, Nvarpar, Nfield, Nindex}) THEN
                  OPM.Write(OpenParen); OPC.Ident(n^.typ^.strobj); OPM.Write(CloseParen);
                  expr(l, exprPrec)
                ELSE
                  OPM.WriteString("__VAL("); OPC.Ident(n^.typ^.strobj); OPM.WriteString(Comma);
                  expr(l, MinPrec); OPM.Write(CloseParen)
                END
          ELSE OPM.err(200)
          END
    |  Ndop:
          CASE subclass OF
            len:
                Len(l, r^.conval^.intval)
          | in, ash, msk, bit, lsh, rot, div, mod:
              CASE subclass OF
              |  in:
                    OPM.WriteString("__IN(")
              |  ash:
                    IF r^.class = Nconst THEN
                      IF r^.conval^.intval >= 0 THEN OPM.WriteString("__ASHL(")
                      ELSE OPM.WriteString("__ASHR(")
                      END
                    ELSIF SideEffects(r) THEN OPM.WriteString("__ASHF(")
                    ELSE OPM.WriteString("__ASH(")
                    END
              |  msk:
                    OPM.WriteString("__MASK(");
              |  bit:
                    OPM.WriteString("__BIT(")
              |  lsh:
                    IF r^.class = Nconst THEN
                      IF r^.conval^.intval >= 0 THEN OPM.WriteString("__LSHL(")
                      ELSE OPM.WriteString("__LSHR(")
                      END
                    ELSE OPM.WriteString("__LSH(")
                    END
              |  rot:
                    IF r^.class = Nconst THEN
                      IF r^.conval^.intval >= 0 THEN OPM.WriteString("__ROTL(")
                      ELSE OPM.WriteString("__ROTR(")
                      END
                    ELSE OPM.WriteString("__ROT(")
                    END
              |  div:
                    IF SideEffects(n) THEN
                      IF form < LInt THEN OPM.WriteString("(int)") END ;
                      OPM.WriteString("__DIVF(")
                    ELSE OPM.WriteString("__DIV(")
                    END
              |  mod:
                    IF form < LInt THEN OPM.WriteString("(int)") END ;
                    IF SideEffects(n) THEN OPM.WriteString("__MODF(")
                    ELSE OPM.WriteString("__MOD(")
                    END;
	      ELSE
	      OPM.LogWStr("unhandled case in OPV.expr, subclass = "); OPM.LogWNum(subclass, 0); OPM.LogWLn;
              END ;
              expr(l, MinPrec);
              OPM.WriteString(Comma);
              IF (subclass IN {ash, lsh, rot}) & (r^.class = Nconst) & (r^.conval^.intval < 0) THEN
                OPM.WriteInt(-r^.conval^.intval)
              ELSE expr(r, MinPrec)
              END ;
              IF subclass IN {lsh, rot} THEN OPM.WriteString(Comma); OPC.Ident(l^.typ^.strobj) END ;
              OPM.Write(CloseParen)
          | eql .. geq:
              IF l^.typ^.form IN {String, Comp} THEN
                OPM.WriteString("__STRCMP(");
                expr(l, MinPrec); OPM.WriteString(Comma); expr(r, MinPrec); OPM.Write(CloseParen);
                OPC.Cmp(subclass); OPM.Write("0")
              ELSE
                expr(l, exprPrec); OPC.Cmp(subclass);
                typ := l^.typ;
                IF (typ^.form = Pointer) & (r^.typ.form # NilTyp) & (r^.typ # typ) & (r^.typ # OPT.sysptrtyp) THEN
                  OPM.WriteString("(void *) ")
                END ;
                expr(r, exprPrec)
              END
          ELSE
	    IF (subclass = and) OR ((form = Set) & ((subclass = times) OR (subclass = minus))) THEN OPM.Write(OpenParen); END; (* to silence clang warnings; -- noch *)
            expr(l, exprPrec);
            CASE subclass OF
              times:
                  IF form = Set THEN OPM.WriteString(" & ")
                    ELSE OPM.WriteString(" * ")
                  END
            |  slash:
                  IF form = Set THEN OPM.WriteString(" ^ ")
                  ELSE OPM.WriteString(" / ");
                    IF (r^.obj = NIL) OR (r^.obj^.typ^.form IN {SInt, Int, LInt(*, Int8, Int16, Int32, Int64*)}) THEN
                      OPM.Write(OpenParen); OPC.Ident(n^.typ^.strobj); OPM.Write(CloseParen)
                    END
                  END
            |  and:
                  OPM.WriteString(" && ")
            |  plus:
                  IF form = Set THEN OPM.WriteString(" | ")
                  ELSE OPM.WriteString(" + ")
                  END
            |  minus:
                  IF form = Set THEN OPM.WriteString(" & ~")
                  ELSE OPM.WriteString(" - ")
                  END;
            |  or:
                  OPM.WriteString(" || ");
	    ELSE
	    OPM.LogWStr("unhandled case in OPV.expr, subclass = "); OPM.LogWNum(subclass, 0); OPM.LogWLn;
            END;
            expr(r, exprPrec);
	    IF (subclass = and) OR ((form = Set) & ((subclass = times) OR (subclass = minus))) THEN OPM.Write(CloseParen) END; (* to silence clang warnings, -- noch*)
          END
    |  Ncall:
          IF (l^.obj # NIL) & (l^.obj^.mode = TProc) THEN
            IF l^.subcl = super THEN proc := SuperProc(n)
            ELSE OPM.WriteString("__"); proc := OPC.BaseTProc(l^.obj) 
            END ;
            OPC.Ident(proc);
            n^.obj := proc^.link
          ELSIF l^.class = Nproc THEN design(l, 10)
          ELSE design(l, ProcTypeVar)
          END ;
          ActualPar(r, n^.obj)
    ELSE
          design(n, prec); (* not exprPrec! *)
    END ;
    IF (exprPrec <= prec) & (class IN {Nconst, Nupto, Nmop, Ndop, Ncall, Nguard}) THEN
      OPM.Write(CloseParen)
    END
  END expr;

  PROCEDURE^ stat(n: OPT.Node; outerProc: OPT.Object);

  PROCEDURE IfStat(n: OPT.Node; withtrap: BOOLEAN; outerProc: OPT.Object);
    VAR if: OPT.Node; obj: OPT.Object; typ: OPT.Struct; adr: LONGINT;
  BEGIN  (* n^.class IN {Nifelse, Nwith} *)
    if := n^.left; (* name := ""; *)
    WHILE if # NIL DO
      OPM.WriteString("if "); expr(if^.left, MaxPrec);  (* if *)
      OPM.Write(Blank); OPC.BegBlk; 
      IF (n^.class = Nwith) & (if^.left^.left # NIL) THEN (* watch out for const expr *)
        obj := if^.left^.left^.obj; typ := obj^.typ; adr := obj^.adr;
        IF typ^.comp = Record THEN
          (* introduce alias pointer for var records; T1 *name__ = rec; *)
          OPC.BegStat; OPC.Ident(if^.left^.obj); OPM.WriteString(" *");
          OPM.WriteString(obj.name); OPM.WriteString("__ = (void*)");
          obj^.adr := 0; (* for nested WITH with same variable; always take the original name *)
          OPC.CompleteIdent(obj);
          OPC.EndStat
        END ;
        obj^.adr := 1;  (* signal special handling of variable name to OPC.CompleteIdent *)
        obj^.typ := if^.left^.obj^.typ;
        stat(if^.right, outerProc);
        obj^.typ := typ; obj^.adr := adr
      ELSE
        stat(if^.right, outerProc)
      END ;
      if := if^.link;
      IF (if # NIL) OR (n^.right # NIL) OR withtrap THEN OPC.EndBlk0(); OPM.WriteString(" else ");
      ELSE OPC.EndBlk()
      END
    END ;
    IF withtrap THEN OPM.WriteString(WithChk); OPC.EndStat()
    ELSIF n^.right # NIL THEN OPC.BegBlk; stat(n^.right, outerProc); OPC.EndBlk
    END
  END IfStat;

  PROCEDURE CaseStat(n: OPT.Node; outerProc: OPT.Object);
    VAR switchCase, label: OPT.Node;
      low, high: LONGINT; form, i: INTEGER;
  BEGIN
    OPM.WriteString("switch "); expr(n^.left, MaxPrec);
    OPM.Write(Blank); OPC.BegBlk;
    form := n^.left^.typ^.form;
    switchCase := n^.right^.left;
    WHILE switchCase # NIL DO  (* switchCase^.class = Ncasedo *)
      label := switchCase^.left;
      i := 0;
      WHILE label # NIL DO (* label^.class = NConst *)
        low := label^.conval^.intval;
        high := label^.conval^.intval2;
        WHILE low <= high DO
          IF i = 0 THEN OPC.BegStat END ;
          OPC.Case(low, form);
          INC(low); INC(i);
          IF i = 5 THEN OPM.WriteLn; i := 0 END
        END ;
        label := label^.link
      END ;
      IF i > 0 THEN OPM.WriteLn END ;
      OPC.Indent(1);
      stat(switchCase^.right, outerProc);
      OPC.BegStat; OPM.WriteString(Break); OPC.EndStat;
      OPC.Indent(-1);
      switchCase := switchCase^.link
    END ;
    OPC.BegStat; OPM.WriteString("default: ");
    IF n^.right^.conval^.setval # {} THEN  (* else branch *)
      OPC.Indent(1); OPM.WriteLn; stat(n^.right^.right, outerProc);
      OPC.BegStat; OPM.WriteString(Break); OPC.Indent(-1)
    ELSE
      OPM.WriteString("__CASECHK")
    END ;
    OPC.EndStat; OPC.EndBlk
  END CaseStat;

  PROCEDURE ImplicitReturn(n: OPT.Node): BOOLEAN;
  BEGIN
    WHILE (n # NIL) & (n.class # Nreturn) DO n := n^.link END ;
    RETURN n = NIL
  END ImplicitReturn;

  PROCEDURE NewArr(d, x: OPT.Node);
    VAR typ, base: OPT.Struct; nofdim, nofdyn: INTEGER;
  BEGIN
    typ := d^.typ^.BaseTyp; base := typ; nofdim := 0; nofdyn := 0;
    WHILE base^.comp = DynArr DO INC(nofdim); INC(nofdyn); base := base^.BaseTyp END ;
    design(d, MinPrec); OPM.WriteString(" = __NEWARR(");
    WHILE base^.comp = Array DO INC(nofdim); base := base^.BaseTyp END ;
    IF (base^.comp = Record) & (OPC.NofPtrs(base) # 0) THEN
      OPC.Ident(base^.strobj); OPM.WriteString(DynTypExt)
    ELSIF base^.form = Pointer THEN OPM.WriteString("POINTER__typ")
    ELSE OPM.WriteString("NIL")
    END ;
    OPM.WriteString(", "); OPM.WriteInt(base^.size); OPM.PromoteIntConstToLInt();  (* element size *)
    OPM.WriteString(", "); OPM.WriteInt(OPC.Base(base));  (* element alignment *)
    OPM.WriteString(", "); OPM.WriteInt(nofdim);  (* total number of dimensions = number of additional parameters *) 
    OPM.WriteString(", "); OPM.WriteInt(nofdyn);  (* number of dynamic dimensions *)
    WHILE typ # base DO
      OPM.WriteString(", ");
      IF typ^.comp = DynArr THEN
        IF x^.class = Nconst THEN expr(x, MinPrec); OPM.PromoteIntConstToLInt()
        ELSE OPM.WriteString("(LONGINT)"); expr(x, 10)
        END ;
        x := x^.link
      ELSE OPM.WriteInt(typ^.n); OPM.PromoteIntConstToLInt()
      END ;
      typ := typ^.BaseTyp
    END ;
    OPM.Write(")")
  END NewArr;

  PROCEDURE DefineTDescs(n: OPT.Node);
  BEGIN
    WHILE (n # NIL) & (n^.class = Ninittd) DO OPC.TDescDecl(n^.typ); n := n^.link END
  END DefineTDescs;

  PROCEDURE InitTDescs(n: OPT.Node);
  BEGIN
    WHILE (n # NIL) & (n^.class = Ninittd) DO OPC.InitTDesc(n^.typ); n := n^.link END
  END InitTDescs;

  PROCEDURE stat(n: OPT.Node; outerProc: OPT.Object);
    VAR proc: OPT.Object; saved: ExitInfo; l, r: OPT.Node;
  BEGIN
    WHILE (n # NIL) & OPM.noerr DO
      OPM.errpos := n^.conval^.intval;
      IF n^.class # Ninittd THEN OPC.BegStat; END;
      CASE n^.class OF
        Nenter:
            IF n^.obj = NIL THEN (* enter module *)
              INC(OPM.level); stat(n^.left, outerProc); DEC(OPM.level);
              OPC.GenEnumPtrs(OPT.topScope^.scope);
              DefineTDescs(n^.right); OPC.EnterBody; InitTDescs(n^.right);
              OPM.WriteString("/* BEGIN */"); OPM.WriteLn;
              stat(n^.right, outerProc); OPC.ExitBody
            ELSE (* enter proc *)
              proc := n^.obj;
              OPC.TypeDefs(proc^.scope^.right, 0);
              IF ~proc^.scope^.leaf THEN OPC.DefineInter (proc) END ; (* define intermediate procedure scope *)
              INC(OPM.level); stat(n^.left, proc); DEC(OPM.level);
              OPC.EnterProc(proc); stat(n^.right, proc);
              OPC.ExitProc(proc, TRUE, ImplicitReturn(n^.right));
            END
      |  Ninittd: (* done in enter module *)
      |  Nassign:
          CASE n^.subcl OF
            assign:
                l := n^.left; r := n^.right;
                IF l^.typ^.comp = Array THEN (* includes string assignment but not COPY *)
                  OPM.WriteString(MoveFunc);
                  expr(r, MinPrec); OPM.WriteString(Comma); expr(l, MinPrec); OPM.WriteString(Comma);
                  IF r^.typ = OPT.stringtyp THEN OPM.WriteInt(r^.conval^.intval2)
                  ELSE OPM.WriteInt(r^.typ^.size)
                  END ;
                  OPM.Write(CloseParen)
                ELSE
                  IF (l^.typ^.form = Pointer) & (l^.obj # NIL) & (l^.obj^.adr = 1) & (l^.obj^.mode = Var) THEN
                    l^.obj^.adr := 0; design(l, MinPrec); l^.obj^.adr := 1;      (* avoid cast of WITH-variable *)
                    IF r^.typ^.form # NilTyp THEN OPM.WriteString(" = (void*)")
                    ELSE OPM.WriteString(" = ")
                    END
                  ELSE
                    design(l, MinPrec); OPM.WriteString(" = ")
                  END ;
                  IF l^.typ = r^.typ THEN expr(r, MinPrec)
                  ELSIF (l^.typ^.form = Pointer) & (r^.typ^.form # NilTyp) & (l^.typ^.strobj # NIL) THEN
                    OPM.Write("("); OPC.Ident(l^.typ^.strobj); OPM.Write(")"); expr(r, MinPrec)
                  ELSIF l^.typ^.comp = Record THEN
                    OPM.WriteString("*("); OPC.Andent(l^.typ); OPM.WriteString("*)&"); expr(r, 9)
                  ELSE expr(r, MinPrec)
                  END
                END
          |  newfn:
                IF n^.left^.typ^.BaseTyp^.comp = Record THEN
                  OPM.WriteString("__NEW("); design(n^.left, MinPrec); OPM.WriteString(", ");
                  OPC.Andent(n^.left^.typ^.BaseTyp); OPM.WriteString(")")
                ELSIF n^.left^.typ^.BaseTyp^.comp IN {Array, DynArr} THEN
                  NewArr(n^.left, n^.right)
                END
          |  incfn, decfn:
                expr(n^.left, MinPrec); OPC.Increment(n^.subcl = decfn); expr(n^.right, MinPrec)
          |  inclfn, exclfn:
                expr(n^.left, MinPrec); OPC.SetInclude(n^.subcl = exclfn); OPM.WriteString(SetOfFunc); expr(n^.right, MinPrec);
                OPM.Write(CloseParen)
          |  copyfn:
                OPM.WriteString(CopyFunc);
                expr(n^.right, MinPrec); OPM.WriteString(Comma); expr(n^.left, MinPrec); OPM.WriteString(Comma);
                Len(n^.left, 0); OPM.Write(CloseParen)
          |  (*SYSTEM*)movefn:
                OPM.WriteString(MoveFunc);
                expr(n^.right, MinPrec); OPM.WriteString(Comma); expr(n^.left, MinPrec); OPM.WriteString(Comma);
                expr(n^.right^.link, MinPrec);
                OPM.Write(CloseParen)
          |  (*SYSTEM*)getfn:
                OPM.WriteString(GetFunc); expr(n^.right, MinPrec); OPM.WriteString(Comma); expr(n^.left, MinPrec);
                OPM.WriteString(Comma); OPC.Ident(n^.left^.typ^.strobj); OPM.Write(CloseParen)
          |  (*SYSTEM*)putfn:
                OPM.WriteString(PutFunc); expr(n^.left, MinPrec); OPM.WriteString(Comma); expr(n^.right, MinPrec);
                OPM.WriteString(Comma); OPC.Ident(n^.right^.typ^.strobj); OPM.Write(CloseParen)
          |  (*SYSTEM*)getrfn, putrfn: OPM.err(200)
          |  (*SYSTEM*)sysnewfn:
                OPM.WriteString("__SYSNEW(");
                design(n^.left, MinPrec); OPM.WriteString(", ");
                expr(n^.right, MinPrec);
                OPM.Write(")")
	  ELSE
	     OPM.LogWStr("unhandled case in OPV.expr, n^.subcl = "); OPM.LogWNum(n^.subcl, 0); OPM.LogWLn;
          END
      |  Ncall:
            IF (n^.left^.obj # NIL) & (n^.left^.obj^.mode = TProc) THEN
              IF n^.left^.subcl = super THEN proc := SuperProc(n)
              ELSE OPM.WriteString("__"); proc := OPC.BaseTProc(n^.left^.obj)
              END ;
              OPC.Ident(proc);
              n^.obj := proc^.link
            ELSIF n^.left^.class = Nproc THEN design(n^.left, 10)
            ELSE design(n^.left, ProcTypeVar)
            END ;
            ActualPar(n^.right, n^.obj)
      |  Nifelse:
            IF n^.subcl # assertfn THEN IfStat(n, FALSE, outerProc)
            ELSIF assert THEN OPM.WriteString("__ASSERT("); expr(n^.left^.left^.left, MinPrec); OPM.WriteString(Comma);
              OPM.WriteInt(n^.left^.right^.right^.conval^.intval); OPM.Write(CloseParen); OPC.EndStat
            END
      |  Ncase:
            INC(exit.level); CaseStat(n, outerProc); DEC(exit.level)
      |  Nwhile:
            INC(exit.level); OPM.WriteString("while "); expr(n^.left, MaxPrec);
            OPM.Write(Blank); OPC.BegBlk; stat(n^.right, outerProc); OPC.EndBlk;
            DEC(exit.level)
      |  Nrepeat:
            INC(exit.level); OPM.WriteString("do "); OPC.BegBlk; stat(n^.left, outerProc); OPC.EndBlk0;
            OPM.WriteString(" while (!");  expr(n^.right, 9); OPM.Write(CloseParen);
            DEC(exit.level)
      |  Nloop:
            saved := exit; exit.level := 0; exit.label := -1;
            OPM.WriteString("for (;;) "); OPC.BegBlk; stat(n^.left, outerProc); OPC.EndBlk;
            IF exit.label # -1 THEN
              OPC.BegStat; OPM.WriteString("exit__"); OPM.WriteInt(exit.label); OPM.Write(":"); OPC.EndStat
            END ;
            exit := saved
      |  Nexit:
            IF exit.level = 0 THEN OPM.WriteString(Break)
            ELSE
              IF exit.label = -1 THEN exit.label := nofExitLabels; INC(nofExitLabels) END ;
              OPM.WriteString("goto exit__"); OPM.WriteInt(exit.label)
            END
      |  Nreturn:
            IF OPM.level = 0 THEN
              IF mainprog THEN OPM.WriteString("__FINI") ELSE OPM.WriteString("__ENDMOD") END
            ELSE
              OPC.ExitProc(outerProc, FALSE, FALSE);
              OPM.WriteString("return");
              IF n^.left # NIL THEN OPM.Write(Blank);
                IF (n^.left^.typ^.form = Pointer) & (n^.obj^.typ # n^.left^.typ) THEN
                  OPM.WriteString("(void*)"); expr(n^.left, 10)
                ELSE
                  expr(n^.left, MinPrec)
                END
              END
            END
      |  Nwith:
            IfStat(n, n^.subcl = 0, outerProc)
      |  Ntrap:
            OPC.Halt(n^.right^.conval^.intval)
      ELSE
                                   (* this else is necessary cause
                                   it can happen that
                                   n^.class is something which is not handled,
                                   like Nconst (7)
                                   which I actually experienced
                                   when compiling Texts0.Mod on raspberry pi
                                   it generates __CASECHK and cause Halt,
                                   noch *)
	OPM.LogWStr("unhandled case in OPV.expr, n^.class = "); OPM.LogWNum(n^.class, 0); OPM.LogWLn;			   
      END ;
      IF ~(n^.class IN {Nenter, Ninittd, Nifelse, Nwith, Ncase, Nwhile, Nloop}) THEN OPC.EndStat END ;
      n := n^.link
    END
  END stat;

  PROCEDURE Module*(prog: OPT.Node);
  BEGIN
    IF ~mainprog THEN OPC.GenHdr(prog^.right); OPC.GenHdrIncludes END ;
    OPC.GenBdy(prog^.right); stat(prog, NIL)
  END Module;

END OPV.
