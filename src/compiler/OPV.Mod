MODULE OPV;  (* J. Templ 16.2.95 / 3.7.96

  26.7.2002 jt bug fix OPM.in Len: wrong result if called for fixed OPM.Array
  31.1.2007 jt synchronized with BlackBox version, in particular:
    various promotion rules changed (long) => (LONGINT), xxxL avoided
*)

  IMPORT OPT, OPC, OPM, OPS;

  CONST
    UndefinedType  = 0; (* named type not yet defined *)
    ProcessingType = 1; (* pointer type is being processed *)
    PredefinedType = 2; (* for all predefined types *)
    DefinedInHdr   = 3+OPM.HeaderFile; (* named type has been defined in header file *)
    DefinedInBdy   = 3+OPM.BodyFile; (* named type has been defined in body file *)

    OpenParen    = "(";
    CloseParen   = ")";
    OpenBracket  = "[";
    CloseBracket = "]";
    Blank        = " ";
    Comma        = ", ";
    Deref        = "*";
    EntierFunc   = "__ENTIER(";
    IsFunc       = "__IS(";
    IsPFunc      = "__ISP(";
    GuardPtrFunc = "__GUARDP(";
    GuardRecFunc = "__GUARDR(";
    TypeFunc     = "__TYPEOF(";
    SetOfFunc    = "__SETOF(";
    SetRangeFunc = "__SETRNG(";
    CopyFunc     = "__COPY(";
    MoveFunc     = "__MOVE(";
    GetFunc      = "__GET(";
    PutFunc      = "__PUT(";
    DynTypExt    = "__typ";
    WithChk      = "__WITHCHK";
    Break        = "break";
    ElseStat     = "else ";

    MinPrec     = -1;
    MaxPrec     = 12;
    ProcTypeVar = 11; (* precedence number when a call is made with a proc type variable *)


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
      IF c = OPM.Record THEN btyp := typ^.BaseTyp;
        IF btyp = NIL THEN offset := 0; base := (*OPM.RecAlign*)OPC.SizeAlignment(OPM.RecSize);
        ELSE TypSize(btyp); offset := btyp^.size - btyp^.sysflag DIV 100H; base := btyp^.align;
        END;
        fld := typ^.link;
        WHILE (fld # NIL) & (fld^.mode = OPM.Fld) DO
          btyp := fld^.typ; TypSize(btyp);
          size := btyp^.size; fbase := OPC.BaseAlignment(btyp);
          OPC.Align(offset, fbase);
          fld^.adr := offset; INC(offset, size);
          IF fbase > base THEN base := fbase END ;
          fld := fld^.link
        END ;
        off0 := offset;
        IF offset = 0 THEN offset := 1 END ;  (* 1 byte filler to avoid empty struct *)
        IF OPM.RecSize = 0 THEN base := NaturalAlignment(offset, (*OPM.RecAlign*)OPC.SizeAlignment(OPM.RecSize)) END ;
        OPC.Align(offset, base);
        IF (typ^.strobj = NIL) & (typ^.align MOD 10000H = 0) THEN INC(recno); INC(base, recno * 10000H) END ;
        typ^.size := offset; typ^.align := base;
        (* encode the trailing gap into the symbol table to allow dense packing of extended records *)
        typ^.sysflag := typ^.sysflag MOD 100H + SHORT((offset - off0)*100H)
      ELSIF c = OPM.Array THEN
        TypSize(typ^.BaseTyp);
        typ^.size := typ^.n * typ^.BaseTyp^.size;
      ELSIF f = OPM.Pointer THEN
        typ^.size := OPM.PointerSize;
        IF typ^.BaseTyp = OPT.undftyp THEN OPM.Mark(128, typ^.n)
        ELSE TypSize(typ^.BaseTyp)
        END
      ELSIF f = OPM.ProcTyp THEN
        typ^.size := OPM.ProcSize;
      ELSIF c = OPM.DynArr THEN
        btyp := typ^.BaseTyp; TypSize(btyp);
        IF btyp^.comp = OPM.DynArr THEN typ^.size := btyp^.size + 4  (* describes dim not size *)
        ELSE typ^.size := 8
        END
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
    IF typ^.form = OPM.Pointer THEN typ := typ^.BaseTyp END ;
    OPT.FindField(obj^.name, typ^.BaseTyp, redef);
    IF redef # NIL THEN obj^.adr := 10000H*(redef^.adr DIV 10000H) (*mthno*);
      IF ~(OPM.isRedef IN obj^.conval^.setval) THEN OPM.err(119) END
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
      IF (mode = OPM.Typ) & ((obj^.vis # OPM.internal) = exported) THEN
        typ := obj^.typ; TypSize(obj^.typ);
        IF typ^.form = OPM.Pointer THEN typ := typ^.BaseTyp END ;
        IF typ^.comp = OPM.Record THEN TraverseRecord(typ) END
      ELSIF mode = OPM.TProc THEN GetTProcNum(obj)
      ELSIF mode = OPM.Var THEN TypSize(obj^.typ)
      END ;
      IF ~exported THEN (* do this only once *)
        IF (mode IN {OPM.LProc, OPM.Typ}) & (obj^.mnolev > 0) THEN Stamp(obj^.name) END ;
        IF mode IN {OPM.Var, OPM.VarPar, OPM.Typ} THEN
          obj^.scope := outerScope
        ELSIF mode IN {OPM.LProc, OPM.XProc, OPM.TProc, OPM.CProc, OPM.IProc} THEN
          IF obj^.conval^.setval = {} THEN OPM.err(129) END ;
          scope := obj^.scope;
          scope^.leaf := TRUE;
          scope^.name := obj^.name; Stamp(scope^.name);
          IF mode = OPM.CProc THEN obj^.adr := 1 (* c.f. OPC.CProcDefs *) END ;
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
    OPT.chartyp^.strobj^.linkadr   := PredefinedType;
    OPT.settyp^.strobj^.linkadr    := PredefinedType;
    OPT.realtyp^.strobj^.linkadr   := PredefinedType;
    OPT.inttyp^.strobj^.linkadr    := PredefinedType;
    OPT.linttyp^.strobj^.linkadr   := PredefinedType;
    OPT.lrltyp^.strobj^.linkadr    := PredefinedType;
    OPT.sinttyp^.strobj^.linkadr   := PredefinedType;
    OPT.booltyp^.strobj^.linkadr   := PredefinedType;
    OPT.bytetyp^.strobj^.linkadr   := PredefinedType;
    OPT.sysptrtyp^.strobj^.linkadr := PredefinedType;
  END AdrAndSize;

(* ____________________________________________________________________________________________________________________________________________________________________ *)

  PROCEDURE Precedence (class, subclass, form, comp: INTEGER): INTEGER;
  BEGIN
    CASE class OF
    | OPM.Nconst,
      OPM.Nvar,
      OPM.Nfield,
      OPM.Nindex,
      OPM.Nproc,
      OPM.Ncall:   RETURN 10
    | OPM.Nguard:  IF OPM.typchk IN OPM.opt THEN RETURN 10 ELSE RETURN 9 (*cast*) END
    | OPM.Nvarpar: IF comp IN {OPM.Array, OPM.DynArr} THEN RETURN 10 ELSE RETURN 9 END (* arrays don't need deref *)
    | OPM.Nderef:  RETURN 9
    | OPM.Nmop:    CASE subclass OF
                   | OPM.not, OPM.minus, OPM.adr, OPM.val, OPM.conv: RETURN 9
                   | OPM.is, OPM.abs, OPM.cap, OPM.odd, OPM.cc:      RETURN 10
                   ELSE OPM.LogWStr("unhandled case in OPV.Precedence OPM.Nmop, subclass = "); OPM.LogWNum(subclass, 0); OPM.LogWLn;
                   END
    | OPM.Ndop:    CASE subclass OF
                   | OPM.times: IF form = OPM.Set THEN RETURN 4 ELSE RETURN 8 END
                   | OPM.slash: IF form = OPM.Set THEN RETURN 3 ELSE RETURN 8 END
                   | OPM.div,
                     OPM.mod:   RETURN 10 (* div/mod are replaced by functions *)
                   | OPM.plus:  IF form = OPM.Set THEN RETURN 2 ELSE RETURN 7 END
                   | OPM.minus: IF form = OPM.Set THEN RETURN 4 ELSE RETURN 7 END
                   | OPM.lss,
                     OPM.leq,
                     OPM.gtr,
                     OPM.geq:   RETURN 6
                   | OPM.eql,
                     OPM.neq:   RETURN 5
                   | OPM.and:   RETURN 1
                   | OPM.or:    RETURN 0
                   | OPM.len,
                     OPM.in,
                     OPM.ash,
                     OPM.msk,
                     OPM.bit,
                     OPM.lsh,
                     OPM.rot:   RETURN 10
      	           ELSE OPM.LogWStr("unhandled case in OPV.Precedence OPM.Ndop, subclass = "); OPM.LogWNum(subclass, 0); OPM.LogWLn;
                   END;
    | OPM.Nupto:   RETURN 10
    | OPM.Ntype,
      OPM.Neguard: (* ignored anyway *) RETURN MaxPrec
    ELSE OPM.LogWStr("unhandled case in OPV.Precedence, class = "); OPM.LogWNum(class, 0); OPM.LogWLn;
    END;
  END Precedence;

  PROCEDURE^ expr (n: OPT.Node; prec: INTEGER);
  PROCEDURE^ design(n: OPT.Node; prec: INTEGER);

  PROCEDURE Len(n: OPT.Node; dim: LONGINT);
  BEGIN
    WHILE (n^.class = OPM.Nindex) & (n^.typ^.comp = OPM.DynArr(*26.7.2002*)) DO INC(dim); n := n^.left END ;
    IF (n^.class = OPM.Nderef) & (n^.typ^.comp = OPM.DynArr) THEN
      design(n^.left, 10); OPM.WriteString("->len["); OPM.WriteInt(dim); OPM.Write("]")
    ELSE
      OPC.Len(n^.obj, n^.typ, dim)
    END
  END Len;

  PROCEDURE SideEffects(n: OPT.Node): BOOLEAN;
  BEGIN
    IF n # NIL THEN RETURN (n^.class = OPM.Ncall) OR SideEffects(n^.left) OR SideEffects(n^.right)
    ELSE RETURN FALSE
    END
  END SideEffects;

  PROCEDURE Entier(n: OPT.Node; prec: INTEGER);
  BEGIN
    IF n^.typ^.form IN {OPM.Real, OPM.LReal} THEN
      OPM.WriteString(EntierFunc); expr(n, MinPrec); OPM.Write(CloseParen)
    ELSE expr(n, prec)
    END
  END Entier;

  PROCEDURE SizeCast(size: LONGINT);
  BEGIN
    IF    size <= OPM.SIntSize THEN OPM.WriteString("(SHORTINT)")
    ELSIF size <= OPM.IntSize  THEN OPM.WriteString("(INTEGER)")
    ELSE                            OPM.WriteString("(LONGINT)")
    END
  END SizeCast;

  PROCEDURE Convert(n: OPT.Node; typ: OPT.Struct; prec: INTEGER);
    VAR from, to: INTEGER;
  BEGIN from := n^.typ^.form; to := typ.form;
    IF to = OPM.Set THEN OPM.WriteString(SetOfFunc); Entier(n, MinPrec); OPM.Write(CloseParen)

    ELSIF to = OPM.LInt THEN
      IF from < OPM.LInt THEN OPM.WriteString("(LONGINT)") END ;
      Entier(n, 9)
    ELSIF to = OPM.Int THEN
      IF from < OPM.Int THEN OPM.WriteString("(int)"); expr(n, 9)
      ELSE
        IF OPM.ranchk IN OPM.opt THEN OPM.WriteString("__SHORT");
          IF SideEffects(n) THEN OPM.Write("F") END ;
          OPM.Write(OpenParen); Entier(n, MinPrec);
          OPM.WriteString(Comma); OPM.WriteInt(OPM.SignedMaximum(OPM.IntSize) + 1); OPM.Write(CloseParen)
        ELSE OPM.WriteString("(int)"); Entier(n, 9)
        END
      END
    ELSIF to = OPM.SInt THEN
      IF OPM.ranchk IN OPM.opt THEN OPM.WriteString("__SHORT");
        IF SideEffects(n) THEN OPM.Write("F") END ;
        OPM.Write(OpenParen); Entier(n, MinPrec);
        OPM.WriteString(Comma); OPM.WriteInt(OPM.SignedMaximum(OPM.SIntSize) + 1); OPM.Write(CloseParen)
      ELSE OPM.WriteString("(int)"); Entier(n, 9)
      END

    (*
    ELSIF to IN OPM.intSet THEN
      IF from IN OPM.intSet
        IF typ.size > n.typ.size (* Result is  larger *)
          SizeCast(typ.size); Entier(n, 9)
        ELSIF typ.size = n.typ.size THEN
          Entier(n, 9)
        ELSE (* Result is smaller *)
          IF OPM.ranchk IN OPM.opt THEN
            OPM.WriteString("__SHORT"); IF SideEffects(n) THEN OPM.Write("F") END;
            OPM.Write(OpenParen); Entier(n, MinPrec); OPM.WriteString(Comma);
            OPM.WriteInt(OPM.SignedMaximum(typ.size) + 1); OPM.Write(CloseParen)
          ELSE
            SizeCast(typ.size); Entier(n, 9)
          END
        END
      ELSE
        IF (from < OPM.SInt) & (typ.size > OPM.SIntSize) THEN SizeCast(typ.size) END;
        Entier(n, 9)
      END
    *)

    ELSIF to = OPM.Char THEN
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
    IF n^.typ^.form = OPM.Pointer THEN
      OPM.WriteString(TypeFunc); expr(n, MinPrec); OPM.Write(")")
    ELSIF n^.class IN {OPM.Nvar, OPM.Nindex, OPM.Nfield} THEN  (* dyn rec type = stat rec type *)
      OPC.Andent(n^.typ); OPM.WriteString(DynTypExt)
    ELSIF n^.class = OPM.Nderef THEN  (* p^ *)
      OPM.WriteString(TypeFunc); expr(n^.left, MinPrec); OPM.Write(")")
    ELSIF n^.class = OPM.Nguard THEN  (* r(T) *)
      TypeOf(n^.left)  (* skip guard *)
    ELSIF (n^.class = OPM.Nmop) & (n^.subcl = OPM.val) THEN
      (*SYSTEM.VAL(typ, var par rec)*)
      OPC.TypeOf(n^.left^.obj)
    ELSE  (* var par rec *)
      OPC.TypeOf(n^.obj)
    END
  END TypeOf;

  PROCEDURE Index(n, d: OPT.Node; prec, dim: INTEGER);
  BEGIN
    IF ~inxchk
    OR (n^.right^.class = OPM.Nconst) & ((n^.right^.conval^.intval = 0) OR (n^.left^.typ^.comp # OPM.DynArr)) THEN
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
    IF (class = OPM.Nvar) & (obj^.mnolev > 0) & (obj^.mnolev # OPM.level) & (prec = 10) THEN designPrec := 9 END ;
    IF prec > designPrec THEN OPM.Write(OpenParen) END;
    IF prec = ProcTypeVar THEN OPM.Write(Deref) END; (* proc var calls must be dereferenced in K&R C *)
    CASE class OF
    | OPM.Nproc:   OPC.Ident(n^.obj)
    | OPM.Nvar:    OPC.CompleteIdent(n^.obj)
    | OPM.Nvarpar: IF ~(comp IN {OPM.Array, OPM.DynArr}) THEN OPM.Write(Deref) END; (* deref var parameter *)
                   OPC.CompleteIdent(n^.obj)
    | OPM.Nfield:  IF n^.left^.class = OPM.Nderef THEN design(n^.left^.left, designPrec); OPM.WriteString("->")
                   ELSE design(n^.left, designPrec); OPM.Write(".")
                   END ;
                   OPC.Ident(n^.obj)
    | OPM.Nderef:  IF n^.typ^.comp = OPM.DynArr THEN design(n^.left, 10); OPM.WriteString("->data")
                   ELSE OPM.Write(Deref); design(n^.left, designPrec)
                   END
    | OPM.Nindex:  d := n^.left;
                   IF d^.typ^.comp = OPM.DynArr THEN dims := 0;
                     WHILE d^.class = OPM.Nindex DO d := d^.left; INC(dims) END ;
                     IF n^.typ^.comp = OPM.DynArr THEN OPM.Write("&") END ;
                     design(d, designPrec);
                     OPM.Write(OpenBracket);
                     IF n^.typ^.comp = OPM.DynArr THEN OPM.Write("(") END ;
                     i := dims; x := n;
                     WHILE x # d DO  (* apply Horner schema *)
                       IF x^.left # d THEN Index(x, d, 7, i); OPM.WriteString(" + "); Len(d, i);  OPM.WriteString(" * ("); DEC(i)
                       ELSE Index(x, d, MinPrec, i)
                       END ;
                       x := x^.left
                     END ;
                     FOR i := 1 TO dims DO OPM.Write(")") END ;
                     IF n^.typ^.comp = OPM.DynArr THEN
                       (*  element type is OPM.DynArr; finish Horner schema with virtual indices = 0*)
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
    | OPM.Nguard:  typ := n^.typ; obj := n^.left^.obj;
                   IF OPM.typchk IN OPM.opt THEN
                     IF typ^.comp = OPM.Record THEN OPM.WriteString(GuardRecFunc);
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
                     IF typ^.comp = OPM.Record THEN (* do not cast record directly, cast pointer to record *)
                       OPM.WriteString("*("); OPC.Ident(typ^.strobj); OPM.WriteString("*)"); OPC.CompleteIdent(obj)
                     ELSE (*simply cast pointer*)
                       OPM.Write("("); OPC.Ident(typ^.strobj); OPM.Write(")"); expr(n^.left, designPrec)
                     END
                   END
    | OPM.Neguard: IF OPM.typchk IN OPM.opt THEN
                     IF n^.left^.class = OPM.Nvarpar THEN OPM.WriteString("__GUARDEQR(");
                       OPC.CompleteIdent(n^.left^.obj); OPM.WriteString(Comma); TypeOf(n^.left);
                     ELSE OPM.WriteString("__GUARDEQP("); expr(n^.left^.left, MinPrec)
                     END ; (* __GUARDEQx includes deref *)
                     OPM.WriteString(Comma); OPC.Ident(n^.left^.typ^.strobj); OPM.Write(")")
                   ELSE
                     expr(n^.left, MinPrec)  (* always lhs of assignment *)
                   END
    | OPM.Nmop:    IF n^.subcl = OPM.val THEN design(n^.left, prec) END
    ELSE OPM.LogWStr("unhandled case in OPV.design, class = "); OPM.LogWNum(class, 0); OPM.LogWLn;
    END ;
    IF prec > designPrec THEN OPM.Write(CloseParen) END
  END design;

  PROCEDURE ActualPar(n: OPT.Node; fp: OPT.Object);
    VAR typ, aptyp: OPT.Struct; comp, form, mode, prec, dim: INTEGER;
  BEGIN
    OPM.Write(OpenParen);
    WHILE n # NIL DO typ := fp^.typ;
      comp := typ^.comp; form := typ^.form; mode := fp^.mode; prec := MinPrec;
      IF (mode = OPM.VarPar) & (n^.class = OPM.Nmop) & (n^.subcl = OPM.val) THEN  (* avoid cast in lvalue *)
        OPM.Write(OpenParen); OPC.Ident(n^.typ^.strobj); OPM.WriteString("*)"); prec := 10
      END ;
      IF ~(n^.typ^.comp IN {OPM.Array, OPM.DynArr}) THEN
        IF mode = OPM.VarPar THEN
          IF ansi & (typ # n^.typ) THEN OPM.WriteString("(void*)") END ;
          OPM.Write("&"); prec := 9
        ELSIF ansi THEN
          IF (comp IN {OPM.Array, OPM.DynArr}) & (n^.class = OPM.Nconst) THEN
            OPM.WriteString("(CHAR*)")  (* force to unsigned char *)
          ELSIF (form = OPM.Pointer) & (typ # n^.typ) & (n^.typ # OPT.niltyp) THEN
            OPM.WriteString("(void*)")  (* type extension *)
          END
        ELSE
          IF (form IN {OPM.Real, OPM.LReal}) & (n^.typ^.form IN OPM.intSet) THEN (* real promotion *)
            OPM.WriteString("(double)"); prec := 9
          ELSIF (form = OPM.LInt) & (n^.typ^.form < OPM.LInt) THEN (* integral promotion *)
            OPM.WriteString("(LONGINT)"); prec := 9
          END
        END
      ELSIF ansi THEN
        (* casting of params should be simplified eventually *)
        IF (mode = OPM.VarPar) & (typ # n^.typ) & (prec = MinPrec) THEN OPM.WriteString("(void*)") END
      END;
      IF (mode = OPM.VarPar) & (n^.class = OPM.Nmop) & (n^.subcl = OPM.val) THEN
        expr(n^.left, prec)  (* avoid cast in lvalue *)
      ELSIF (form = OPM.LInt) & (n^.class = OPM.Nconst)
          & (n^.conval^.intval <= OPM.SignedMaximum(OPM.IntSize)) & (n^.conval^.intval >= OPM.SignedMinimum(OPM.IntSize)) THEN
        OPM.WriteString("((LONGINT)("); expr(n, prec); OPM.WriteString("))");
      ELSE
        expr(n, prec)
      END;
      IF (comp = OPM.Record) & (mode = OPM.VarPar) THEN
        OPM.WriteString(", "); TypeOf(n)
      ELSIF comp = OPM.DynArr THEN
        IF n^.class = OPM.Nconst THEN (* ap is string constant *)
          OPM.WriteString(Comma); OPM.WriteString("(LONGINT)"); OPM.WriteInt(n^.conval^.intval2)
        ELSE
          aptyp := n^.typ; dim := 0;
          WHILE (typ^.comp = OPM.DynArr) & (typ^.BaseTyp^.form # OPM.Byte) DO
            OPM.WriteString(Comma); Len(n, dim);
            typ := typ^.BaseTyp; aptyp := aptyp^.BaseTyp; INC(dim)
          END ;
          IF (typ^.comp = OPM.DynArr) & (typ^.BaseTyp^.form = OPM.Byte) THEN
            OPM.WriteString(Comma);
            WHILE aptyp^.comp = OPM.DynArr DO
              Len(n, dim); OPM.WriteString(" * "); INC(dim); aptyp := aptyp^.BaseTyp
            END ;
            OPM.WriteString("((LONGINT)("); OPM.WriteInt(aptyp^.size); OPM.WriteString("))");
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
    IF typ^.form = OPM.Pointer THEN typ := typ^.BaseTyp END ;
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
    IF (exprPrec <= prec) & (class IN {OPM.Nconst, OPM.Nupto, OPM.Nmop, OPM.Ndop, OPM.Ncall, OPM.Nguard, OPM.Neguard}) THEN
      OPM.Write(OpenParen);
    END;
    CASE class OF
    | OPM.Nconst: OPC.Constant(n^.conval, form)
    | OPM.Nupto:  (* n^.typ = OPT.settyp *)
                  OPM.WriteString(SetRangeFunc); expr(l, MinPrec); OPM.WriteString(Comma); expr (r, MinPrec);
                  OPM.Write(CloseParen)
    | OPM.Nmop:
                  CASE subclass OF
                  | OPM.not:   OPM.Write("!"); expr(l, exprPrec)
                  | OPM.minus: IF form = OPM.Set THEN OPM.Write("~") ELSE OPM.Write("-") END;
                               expr(l, exprPrec)
                  | OPM.is:    typ := n^.obj^.typ;
                               IF l^.typ^.comp = OPM.Record THEN OPM.WriteString(IsFunc); OPC.TypeOf(l^.obj)
                               ELSE OPM.WriteString(IsPFunc); expr(l, MinPrec); typ := typ^.BaseTyp
                               END ;
                               OPM.WriteString(Comma);
                               OPC.Andent(typ); OPM.WriteString(Comma);
                               OPM.WriteInt(typ^.extlev); OPM.Write(")")
                  | OPM.conv:  Convert(l, n.typ, exprPrec)
                  | OPM.abs:   IF SideEffects(l) THEN
                                 IF l^.typ^.form < OPM.Real THEN
                                   IF l^.typ^.form < OPM.LInt THEN OPM.WriteString("(int)") END ;
                                   OPM.WriteString("__ABSF(")
                                 ELSE OPM.WriteString("__ABSFD(")
                                 END
                               ELSE OPM.WriteString("__ABS(")
                               END ;
                               expr(l, MinPrec); OPM.Write(CloseParen)
                  | OPM.cap:   OPM.WriteString("__CAP("); expr(l, MinPrec); OPM.Write(CloseParen)
                  | OPM.odd:   OPM.WriteString("__ODD("); expr(l, MinPrec); OPM.Write(CloseParen)
                  | OPM.adr:   OPM.WriteString("(LONGINT)(uintptr_t)");                             (*SYSTEM*)
                               IF l^.class = OPM.Nvarpar THEN OPC.CompleteIdent(l^.obj)
                               ELSE
                                 IF (l^.typ^.form # OPM.String) & ~(l^.typ^.comp IN {OPM.Array, OPM.DynArr}) THEN OPM.Write("&") END ;
                                 expr(l, exprPrec)
                               END
                  | OPM.val:   IF ~(l^.class IN {OPM.Nvar, OPM.Nvarpar, OPM.Nfield, OPM.Nindex})    (*SYSTEM*)
                               OR   (n^.typ^.form IN {OPM.LInt, OPM.Pointer, OPM.Set, OPM.ProcTyp})
                                  & (l^.typ^.form IN {OPM.LInt, OPM.Pointer, OPM.Set, OPM.ProcTyp})
                                  & (n^.typ^.size = l^.typ^.size)
                               THEN
                                 OPM.Write(OpenParen); OPC.Ident(n^.typ^.strobj); OPM.Write(CloseParen);
                                 IF (n^.typ^.form IN {OPM.Pointer, OPM.ProcTyp}) OR (l^.typ^.form IN {OPM.Pointer, OPM.ProcTyp}) THEN
                                   OPM.WriteString("(uintptr_t)")
                                 END;
                                 expr(l, exprPrec)
                               ELSE
                                 OPM.WriteString("__VAL(");
                                 OPC.Ident(n^.typ^.strobj); OPM.WriteString(Comma);
                                 expr(l, MinPrec); OPM.Write(CloseParen)
                               END
                  ELSE OPM.err(200)
                  END
    | OPM.Ndop:   CASE subclass OF
                  | OPM.len:  Len(l, r^.conval^.intval)
                  | OPM.in,
                    OPM.ash,
                    OPM.msk,
                    OPM.bit,
                    OPM.lsh,
                    OPM.rot,
                    OPM.div,
                    OPM.mod:  CASE subclass OF
                              | OPM.in:   OPM.WriteString("__IN(")
                              | OPM.ash:  IF r^.class = OPM.Nconst THEN
                                            IF r^.conval^.intval >= 0 THEN OPM.WriteString("__ASHL(")
                                            ELSE OPM.WriteString("__ASHR(")
                                            END
                                          ELSIF SideEffects(r) THEN OPM.WriteString("__ASHF(")
                                          ELSE OPM.WriteString("__ASH(")
                                          END
                              | OPM.msk:  OPM.WriteString("__MASK(");
                              | OPM.bit:  OPM.WriteString("__BIT(")
                              | OPM.lsh:  IF r^.class = OPM.Nconst THEN
                                            IF r^.conval^.intval >= 0 THEN OPM.WriteString("__LSHL(")
                                            ELSE OPM.WriteString("__LSHR(")
                                            END
                                          ELSE OPM.WriteString("__LSH(")
                                          END
                              | OPM.rot:  IF r^.class = OPM.Nconst THEN
                                            IF r^.conval^.intval >= 0 THEN OPM.WriteString("__ROTL(")
                                            ELSE OPM.WriteString("__ROTR(")
                                            END
                                          ELSE OPM.WriteString("__ROT(")
                                          END
                              | OPM.div:  IF SideEffects(n) THEN
                                            IF form < OPM.LInt THEN OPM.WriteString("(int)") END ;
                                            OPM.WriteString("__DIVF(")
                                          ELSE OPM.WriteString("__DIV(")
                                          END
                              | OPM.mod:  IF form < OPM.LInt THEN OPM.WriteString("(int)") END ;
                                          IF SideEffects(n) THEN OPM.WriteString("__MODF(")
                                          ELSE OPM.WriteString("__MOD(")
                                          END;
	                           ELSE OPM.LogWStr("unhandled case in OPV.expr, subclass = "); OPM.LogWNum(subclass, 0); OPM.LogWLn;
                              END ;
                              expr(l, MinPrec);
                              OPM.WriteString(Comma);
                              IF (subclass IN {OPM.ash, OPM.lsh, OPM.rot}) & (r^.class = OPM.Nconst) & (r^.conval^.intval < 0) THEN
                                OPM.WriteInt(-r^.conval^.intval)
                              ELSE expr(r, MinPrec)
                              END ;
                              IF subclass IN {OPM.lsh, OPM.rot} THEN OPM.WriteString(Comma); OPC.Ident(l^.typ^.strobj) END ;
                              OPM.Write(CloseParen)
                  | OPM.eql
                  .. OPM.geq: IF l^.typ^.form IN {OPM.String, OPM.Comp} THEN
                                OPM.WriteString("__STRCMP(");
                                expr(l, MinPrec); OPM.WriteString(Comma); expr(r, MinPrec); OPM.Write(CloseParen);
                                OPC.Cmp(subclass); OPM.Write("0")
                              ELSE
                                expr(l, exprPrec); OPC.Cmp(subclass);
                                typ := l^.typ;
                                IF (typ^.form = OPM.Pointer) & (r^.typ.form # OPM.NilTyp) & (r^.typ # typ) & (r^.typ # OPT.sysptrtyp) THEN
                                  OPM.WriteString("(void *) ")
                                END ;
                                expr(r, exprPrec)
                              END
                  ELSE        IF (subclass = OPM.and) OR ((form = OPM.Set) & ((subclass = OPM.times) OR (subclass = OPM.minus))) THEN OPM.Write(OpenParen); END; (* to silence clang warnings; -- noch *)
                              expr(l, exprPrec);
                              CASE subclass OF
                              | OPM.times: IF form = OPM.Set THEN OPM.WriteString(" & ")
                                             ELSE OPM.WriteString(" * ")
                                           END
                              | OPM.slash: IF form = OPM.Set THEN OPM.WriteString(" ^ ")
                                           ELSE OPM.WriteString(" / ");
                                             IF (r^.obj = NIL) OR (r^.obj^.typ^.form IN OPM.intSet) THEN
                                               OPM.Write(OpenParen); OPC.Ident(n^.typ^.strobj); OPM.Write(CloseParen)
                                             END
                                           END
                              | OPM.and:   OPM.WriteString(" && ")
                              | OPM.plus:  IF form = OPM.Set THEN OPM.WriteString(" | ")
                                           ELSE OPM.WriteString(" + ")
                                           END
                              | OPM.minus: IF form = OPM.Set THEN OPM.WriteString(" & ~")
                                           ELSE OPM.WriteString(" - ")
                                           END;
                              | OPM.or:    OPM.WriteString(" || ");
	                            ELSE OPM.LogWStr("unhandled case in OPV.expr, subclass = "); OPM.LogWNum(subclass, 0); OPM.LogWLn;
                              END;
                              expr(r, exprPrec);
	                            IF (subclass = OPM.and) OR ((form = OPM.Set) & ((subclass = OPM.times) OR (subclass = OPM.minus))) THEN OPM.Write(CloseParen) END; (* to silence clang warnings, -- noch*)
                  END
    | OPM.Ncall:  IF (l^.obj # NIL) & (l^.obj^.mode = OPM.TProc) THEN
                    IF l^.subcl = OPM.super THEN proc := SuperProc(n)
                    ELSE OPM.WriteString("__"); proc := OPC.BaseTProc(l^.obj)
                    END ;
                    OPC.Ident(proc);
                    n^.obj := proc^.link
                  ELSIF l^.class = OPM.Nproc THEN design(l, 10)
                  ELSE design(l, ProcTypeVar)
                  END ;
                  ActualPar(r, n^.obj)
    ELSE          design(n, prec); (* not exprPrec! *)
    END;
    IF (exprPrec <= prec) & (class IN {OPM.Nconst, OPM.Nupto, OPM.Nmop, OPM.Ndop, OPM.Ncall, OPM.Nguard}) THEN
      OPM.Write(CloseParen)
    END
  END expr;

  PROCEDURE^ stat(n: OPT.Node; outerProc: OPT.Object);

  PROCEDURE IfStat(n: OPT.Node; withtrap: BOOLEAN; outerProc: OPT.Object);
    VAR if: OPT.Node; obj: OPT.Object; typ: OPT.Struct; adr: LONGINT;
  BEGIN  (* n^.class IN {OPM.Nifelse, OPM.Nwith} *)
    if := n^.left; (* name := ""; *)
    WHILE if # NIL DO
      OPM.WriteString("if "); expr(if^.left, MaxPrec);  (* if *)
      OPM.Write(Blank); OPC.BegBlk;
      IF (n^.class = OPM.Nwith) & (if^.left^.left # NIL) THEN (* watch out for const expr *)
        obj := if^.left^.left^.obj; typ := obj^.typ; adr := obj^.adr;
        IF typ^.comp = OPM.Record THEN
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
    WHILE (n # NIL) & (n.class # OPM.Nreturn) DO n := n^.link END ;
    RETURN n = NIL
  END ImplicitReturn;

  PROCEDURE NewArr(d, x: OPT.Node);
    VAR typ, base: OPT.Struct; nofdim, nofdyn: INTEGER;
  BEGIN
    typ := d^.typ^.BaseTyp; base := typ; nofdim := 0; nofdyn := 0;
    WHILE base^.comp = OPM.DynArr DO INC(nofdim); INC(nofdyn); base := base^.BaseTyp END ;
    design(d, MinPrec); OPM.WriteString(" = __NEWARR(");
    WHILE base^.comp = OPM.Array DO INC(nofdim); base := base^.BaseTyp END ;
    IF (base^.comp = OPM.Record) & (OPC.NofPtrs(base) # 0) THEN
      OPC.Ident(base^.strobj); OPM.WriteString(DynTypExt)
    ELSIF base^.form = OPM.Pointer THEN OPM.WriteString("POINTER__typ")
    ELSE OPM.WriteString("NIL")
    END ;
    OPM.WriteString(", "); OPM.WriteString("((LONGINT)("); OPM.WriteInt(base^.size); OPM.WriteString("))");
    OPM.WriteString(", "); OPM.WriteInt(OPC.BaseAlignment(base));  (* element alignment *)
    OPM.WriteString(", "); OPM.WriteInt(nofdim);  (* total number of dimensions = number of additional parameters *)
    OPM.WriteString(", "); OPM.WriteInt(nofdyn);  (* number of dynamic dimensions *)
    WHILE typ # base DO
      OPM.WriteString(", ");
      IF typ^.comp = OPM.DynArr THEN
        IF x^.class = OPM.Nconst THEN OPM.WriteString("(LONGINT)("); expr(x, MinPrec); OPM.WriteString(")")
        ELSE OPM.WriteString("(LONGINT)"); expr(x, 10)
        END ;
        x := x^.link
      ELSE OPM.WriteString("(LONGINT)"); OPM.WriteInt(typ^.n)
      END ;
      typ := typ^.BaseTyp
    END ;
    OPM.Write(")")
  END NewArr;

  PROCEDURE DefineTDescs(n: OPT.Node);
  BEGIN
    WHILE (n # NIL) & (n^.class = OPM.Ninittd) DO OPC.TDescDecl(n^.typ); n := n^.link END
  END DefineTDescs;

  PROCEDURE InitTDescs(n: OPT.Node);
  BEGIN
    WHILE (n # NIL) & (n^.class = OPM.Ninittd) DO OPC.InitTDesc(n^.typ); n := n^.link END
  END InitTDescs;

  PROCEDURE stat(n: OPT.Node; outerProc: OPT.Object);
    VAR proc: OPT.Object; saved: ExitInfo; l, r: OPT.Node;
  BEGIN
    WHILE (n # NIL) & OPM.noerr DO
      OPM.errpos := n^.conval^.intval;
      IF n^.class # OPM.Ninittd THEN OPC.BegStat END;
      CASE n^.class OF
      | OPM.Nenter:  IF n^.obj = NIL THEN (* enter module *)
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
      | OPM.Ninittd: (* done in enter module *)
      | OPM.Nassign: CASE n^.subcl OF
                     | OPM.assign:    l := n^.left; r := n^.right;
                                      IF l^.typ^.comp = OPM.Array THEN (* includes string assignment but not COPY *)
                                        OPM.WriteString(MoveFunc);
                                        expr(r, MinPrec); OPM.WriteString(Comma); expr(l, MinPrec); OPM.WriteString(Comma);
                                        IF r^.typ = OPT.stringtyp THEN OPM.WriteInt(r^.conval^.intval2)
                                        ELSE OPM.WriteInt(r^.typ^.size)
                                        END ;
                                        OPM.Write(CloseParen)
                                      ELSE
                                        IF (l^.typ^.form = OPM.Pointer) & (l^.obj # NIL) & (l^.obj^.adr = 1) & (l^.obj^.mode = OPM.Var) THEN
                                          l^.obj^.adr := 0; design(l, MinPrec); l^.obj^.adr := 1;      (* avoid cast of WITH-variable *)
                                          IF r^.typ^.form # OPM.NilTyp THEN OPM.WriteString(" = (void*)")
                                          ELSE OPM.WriteString(" = ")
                                          END
                                        ELSE
                                          design(l, MinPrec); OPM.WriteString(" = ")
                                        END ;
                                        IF l^.typ = r^.typ THEN expr(r, MinPrec)
                                        ELSIF (l^.typ^.form = OPM.Pointer) & (r^.typ^.form # OPM.NilTyp) & (l^.typ^.strobj # NIL) THEN
                                          OPM.Write("("); OPC.Ident(l^.typ^.strobj); OPM.Write(")"); expr(r, MinPrec)
                                        ELSIF l^.typ^.comp = OPM.Record THEN
                                          OPM.WriteString("*("); OPC.Andent(l^.typ); OPM.WriteString("*)&"); expr(r, 9)
                                        ELSE expr(r, MinPrec)
                                        END
                                      END
                     | OPM.newfn:     IF n^.left^.typ^.BaseTyp^.comp = OPM.Record THEN
                                        OPM.WriteString("__NEW("); design(n^.left, MinPrec); OPM.WriteString(", ");
                                        OPC.Andent(n^.left^.typ^.BaseTyp); OPM.WriteString(")")
                                      ELSIF n^.left^.typ^.BaseTyp^.comp IN {OPM.Array, OPM.DynArr} THEN
                                        NewArr(n^.left, n^.right)
                                      END
                     | OPM.incfn,
                       OPM.decfn:     expr(n^.left, MinPrec); OPC.Increment(n^.subcl = OPM.decfn); expr(n^.right, MinPrec)
                     | OPM.inclfn,
                       OPM.exclfn:    expr(n^.left, MinPrec); OPC.SetInclude(n^.subcl = OPM.exclfn); OPM.WriteString(SetOfFunc); expr(n^.right, MinPrec);
                                      OPM.Write(CloseParen)
                     | OPM.copyfn:    OPM.WriteString(CopyFunc);
                                      expr(n^.right, MinPrec); OPM.WriteString(Comma); expr(n^.left, MinPrec); OPM.WriteString(Comma);
                                      Len(n^.left, 0); OPM.Write(CloseParen)
                     |  OPM.movefn:   (*SYSTEM*)
                                      OPM.WriteString(MoveFunc);
                                      expr(n^.right, MinPrec); OPM.WriteString(Comma); expr(n^.left, MinPrec); OPM.WriteString(Comma);
                                      expr(n^.right^.link, MinPrec);
                                      OPM.Write(CloseParen)
                     |  OPM.getfn:    (*SYSTEM*)
                                      OPM.WriteString(GetFunc); expr(n^.right, MinPrec); OPM.WriteString(Comma); expr(n^.left, MinPrec);
                                      OPM.WriteString(Comma); OPC.Ident(n^.left^.typ^.strobj); OPM.Write(CloseParen)
                     |  OPM.putfn:    (*SYSTEM*)
                                      OPM.WriteString(PutFunc); expr(n^.left, MinPrec); OPM.WriteString(Comma); expr(n^.right, MinPrec);
                                      OPM.WriteString(Comma); OPC.Ident(n^.right^.typ^.strobj); OPM.Write(CloseParen)
                     |  OPM.getrfn,   (*SYSTEM*)
                        OPM.putrfn:   (*SYSTEM*) OPM.err(200)
                     |  OPM.sysnewfn: (*SYSTEM*)
                                      OPM.WriteString("__SYSNEW(");
                                      design(n^.left, MinPrec); OPM.WriteString(", ");
                                      expr(n^.right, MinPrec);
                                      OPM.Write(")")
	                   ELSE OPM.LogWStr("unhandled case in OPV.expr, n^.subcl = "); OPM.LogWNum(n^.subcl, 0); OPM.LogWLn;
                     END
      | OPM.Ncall:   IF (n^.left^.obj # NIL) & (n^.left^.obj^.mode = OPM.TProc) THEN
                       IF n^.left^.subcl = OPM.super THEN proc := SuperProc(n)
                       ELSE OPM.WriteString("__"); proc := OPC.BaseTProc(n^.left^.obj)
                       END ;
                       OPC.Ident(proc);
                       n^.obj := proc^.link
                     ELSIF n^.left^.class = OPM.Nproc THEN design(n^.left, 10)
                     ELSE design(n^.left, ProcTypeVar)
                     END ;
                     ActualPar(n^.right, n^.obj)
      | OPM.Nifelse: IF n^.subcl # OPM.assertfn THEN IfStat(n, FALSE, outerProc)
                     ELSIF assert THEN OPM.WriteString("__ASSERT("); expr(n^.left^.left^.left, MinPrec); OPM.WriteString(Comma);
                       OPM.WriteInt(n^.left^.right^.right^.conval^.intval); OPM.Write(CloseParen); OPC.EndStat
                     END
      | OPM.Ncase:   INC(exit.level); CaseStat(n, outerProc); DEC(exit.level)
      | OPM.Nwhile:  INC(exit.level); OPM.WriteString("while "); expr(n^.left, MaxPrec);
                     OPM.Write(Blank); OPC.BegBlk; stat(n^.right, outerProc); OPC.EndBlk;
                     DEC(exit.level)
      | OPM.Nrepeat: INC(exit.level); OPM.WriteString("do "); OPC.BegBlk; stat(n^.left, outerProc); OPC.EndBlk0;
                     OPM.WriteString(" while (!");  expr(n^.right, 9); OPM.Write(CloseParen);
                     DEC(exit.level)
      | OPM.Nloop:   saved := exit; exit.level := 0; exit.label := -1;
                     OPM.WriteString("for (;;) "); OPC.BegBlk; stat(n^.left, outerProc); OPC.EndBlk;
                     IF exit.label # -1 THEN
                       OPC.BegStat; OPM.WriteString("exit__"); OPM.WriteInt(exit.label); OPM.Write(":"); OPC.EndStat
                     END ;
                     exit := saved
      | OPM.Nexit:   IF exit.level = 0 THEN OPM.WriteString(Break)
                     ELSE
                       IF exit.label = -1 THEN exit.label := nofExitLabels; INC(nofExitLabels) END ;
                       OPM.WriteString("goto exit__"); OPM.WriteInt(exit.label)
                     END
      | OPM.Nreturn: IF OPM.level = 0 THEN
                       IF mainprog THEN OPM.WriteString("__FINI") ELSE OPM.WriteString("__ENDMOD") END
                     ELSE
                       IF n^.left # NIL THEN
                         (* Make local copy of result before ExitProc deletes dynamic vars *)
                         OPM.WriteString("_o_result = ");
                         IF (n^.left^.typ^.form = OPM.Pointer) & (n^.obj^.typ # n^.left^.typ) THEN
                           OPM.WriteString("(void*)"); expr(n^.left, 10)
                         ELSE
                           expr(n^.left, MinPrec)
                         END;
                         OPM.WriteString(";"); OPM.WriteLn; OPC.BegStat;
                         OPC.ExitProc(outerProc, FALSE, FALSE);
                         OPM.WriteString("return _o_result");
                       ELSE
                         OPM.WriteString("return");
                       END
                     END
      | OPM.Nwith:   IfStat(n, n^.subcl = 0, outerProc)
      | OPM.Ntrap:   OPC.Halt(n^.right^.conval^.intval)
      ELSE OPM.LogWStr("unhandled case in OPV.expr, n^.class = "); OPM.LogWNum(n^.class, 0); OPM.LogWLn;
      END;
      IF ~(n^.class IN {OPM.Nenter, OPM.Ninittd, OPM.Nifelse, OPM.Nwith, OPM.Ncase, OPM.Nwhile, OPM.Nloop}) THEN OPC.EndStat END ;
      n := n^.link
    END
  END stat;

  PROCEDURE Module*(prog: OPT.Node);
  BEGIN
    IF ~mainprog THEN OPC.GenHdr(prog^.right); OPC.GenHdrIncludes END ;
    OPC.GenBdy(prog^.right); stat(prog, NIL)
  END Module;

END OPV.
