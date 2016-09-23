MODULE BrowserCmd;  (* RC 29.10.93 *)  (* object model 4.12.93, command line version jt 4.4.95 *)

 IMPORT
    OPM, OPS, OPT, OPV, Texts, Console, Platform, SYSTEM;


  CONST
    OptionChar = "-";

  VAR
    W: Texts.Writer;
    option: CHAR;

  PROCEDURE Ws(s: ARRAY OF CHAR); BEGIN Texts.WriteString(W, s) END Ws;
  PROCEDURE Wch(ch: CHAR);        BEGIN Texts.Write(W, ch)      END Wch;
  PROCEDURE Wi(i: SYSTEM.INT64);  BEGIN Texts.WriteInt(W, i, 0) END Wi;
  PROCEDURE Wln;                  BEGIN Texts.WriteLn(W)        END Wln;

  PROCEDURE Indent(i: INTEGER);
  BEGIN WHILE i > 0 DO Wch(" "); Wch(" "); DEC(i) END
  END Indent;

  PROCEDURE ^Wtype(typ: OPT.Struct);
  PROCEDURE ^Wstruct(typ: OPT.Struct);

  PROCEDURE Wsign(result: OPT.Struct; par: OPT.Object);
    VAR paren, res, first: BOOLEAN;
  BEGIN first := TRUE;
    res := (result # NIL) (* hidden mthd *) & (result # OPT.notyp);
    paren := res OR (par # NIL);
    IF paren THEN Wch("(") END ;
    WHILE par # NIL DO
      IF ~first THEN Ws("; ") ELSE first := FALSE END ;
      IF option = "x" THEN Wi(par^.adr); Wch(" ") END ;
      IF par^.mode = OPT.VarPar THEN Ws("VAR ") END ;
      Ws(par^.name); Ws(": "); Wtype(par^.typ);
      par := par^.link
    END ;
    IF paren THEN Wch(")") END ;
    IF res THEN Ws(": "); Wtype(result) END
  END Wsign;

  PROCEDURE Objects(obj: OPT.Object; mode: SET);
    VAR i: SYSTEM.INT64; m: INTEGER; s: SET; ext: OPT.ConstExt;
  BEGIN
    IF obj # NIL THEN
      Objects(obj^.left, mode);
      IF obj^.mode IN mode THEN
        CASE obj^.mode OF
        |OPT.Con:   Indent(2); Ws(obj^.name); Ws(" = ");
                    CASE obj^.typ^.form OF
                    |OPT.Bool:   IF obj^.conval^.intval = 1 THEN Ws("TRUE") ELSE Ws("FALSE") END
                    |OPT.Char:   IF (obj^.conval^.intval >= 32) & (obj^.conval^.intval <= 126) THEN
                                   Wch(22X); Wch(CHR(obj^.conval^.intval)); Wch(22X)
                                 ELSE
                                   i := obj^.conval^.intval DIV 16;
                                   IF i > 9 THEN Wch(CHR(55 + i)) ELSE Wch(CHR(48 + i)) END ;
                                   i := obj^.conval^.intval MOD 16;
                                   IF i > 9 THEN Wch(CHR(55 + i)) ELSE Wch(CHR(48 + i)) END ;
                                   Wch("X")
                                 END
                    |OPT.Int:    Wi(obj^.conval^.intval)
                    |OPT.Set:    Wch("{"); i := 0; s := obj^.conval^.setval;
                                 WHILE i <= MAX(SET) DO
                                   IF i IN s THEN Wi(i); EXCL(s, i);
                                     IF s # {} THEN Ws(", ") END
                                   END ;
                                   INC(i)
                                 END ;
                                 Wch("}")
                    |OPT.Real:   Texts.WriteReal(W, SHORT(obj^.conval^.realval), 16)
                    |OPT.LReal:  Texts.WriteLongReal(W, obj^.conval^.realval, 23)
                    |OPT.String: Ws(obj^.conval^.ext^)
                    |OPT.NilTyp: Ws("NIL")
                    ELSE (* Ignore other forms *)
                    END ;
                    Wch(";"); Wln
        |OPT.Typ:   IF obj^.name # "" THEN Indent(2);
                      IF obj^.typ^.strobj = obj THEN  (* canonical name *)
                        Wtype(obj^.typ); Ws(" = "); Wstruct(obj^.typ)
                      ELSE  (* alias *)
                        Ws(obj^.name); Ws(" = "); Wtype(obj^.typ)
                      END ;
                      Wch(";"); Wln
                    END
        |OPT.Var:   Indent(2); Ws(obj^.name);
                    IF obj^.vis = OPT.externalR THEN Ws("-: ") ELSE Ws(": ") END ;
                    Wtype(obj^.typ); Wch(";"); Wln
        |OPT.XProc,
         OPT.CProc,
         OPT.IProc: Indent(1); Ws("PROCEDURE ");
                    IF obj^.mode = OPT.IProc THEN Wch("+")
                    ELSIF obj^.mode = OPT.CProc THEN Wch("-")
                    END ;
                    Ws(obj^.name);
                    Wsign(obj^.typ, obj^.link);
                    IF obj^.mode = OPT.CProc THEN
                      ext := obj^.conval^.ext; m := ORD(ext^[0]); i := 1; Ws('  "');
                      WHILE i <= m DO Wch(ext^[i]); INC(i) END ;
                      Wch('"');
                    END ;
                    Wch(";"); Wln
        ELSE (* Ignore other modes *)
        END
      END ;
      Objects(obj^.right, mode)
    END
  END Objects;

  PROCEDURE Wmthd(obj: OPT.Object);
    VAR
  BEGIN
    IF obj # NIL THEN
      Wmthd(obj^.left);
      IF (obj^.mode = OPT.TProc) & ((obj^.name # OPM.HdTProcName) OR (option = "x")) THEN
        Indent(3); Ws("PROCEDURE (");
        IF obj^.name # OPM.HdTProcName THEN
          IF obj^.link^.mode = OPT.VarPar THEN Ws("VAR ") END ;
          Ws(obj^.link^.name); Ws(": "); Wtype(obj^.link^.typ)
        END ;
        Ws(") "); Ws(obj^.name);
        Wsign(obj^.typ, obj^.link^.link);
        Wch(";");
        IF option = "x" THEN Indent(1);
          Ws("(* methno: "); Wi(obj^.adr DIV 10000H);  Ws(" *)")
        END ;
        Wln;
      END ;
      Wmthd(obj^.right)
    END
  END Wmthd;

  PROCEDURE Wstruct(typ: OPT.Struct);
    VAR fld: OPT.Object;

    PROCEDURE SysFlag;
    BEGIN
      IF typ^.sysflag # 0 THEN
        Wch("["); Wi(typ^.sysflag); Ws("] ")
      END
    END SysFlag;

  BEGIN
    CASE typ^.form OF
    |OPT.Undef:   Ws("Undef")
    |OPT.Pointer: Ws("POINTER "); SysFlag; Ws("TO "); Wtype(typ^.BaseTyp)
    |OPT.ProcTyp: Ws("PROCEDURE "); SysFlag; Wsign(typ^.BaseTyp, typ^.link)
    |OPT.Comp:    CASE typ^.comp OF
                  |OPT.Array:  Ws("ARRAY "); SysFlag; Wi(typ^.n); Ws(" OF "); Wtype(typ^.BaseTyp)
                  |OPT.DynArr: Ws("ARRAY "); SysFlag; Ws("OF "); Wtype(typ^.BaseTyp)
                  |OPT.Record: Ws("RECORD ");SysFlag;
                               IF typ^.BaseTyp # NIL THEN Wch("("); Wtype(typ^.BaseTyp); Wch(")") END ;
                               Wln; fld := typ^.link;
                               WHILE (fld # NIL) & (fld^.mode = OPT.Fld) DO
                                 IF (option = "x") OR (fld^.name[0] # "@") THEN Indent(3);
                                   IF option = "x" THEN Wi(fld^.adr); Wch(" ") END ;
                                   Ws(fld^.name);
                                   IF fld^.vis = OPT.externalR THEN Wch("-") END ;
                                   Ws(": "); Wtype(fld^.typ); Wch(";");
                                   Wln
                                 END ;
                                 fld := fld^.link
                               END ;
                               Wmthd(typ^.link);
                               Indent(2); Ws("END ");
                               IF option = "x" THEN Indent(1);
                                 Ws("(* size: "); Wi(typ^.size); Ws(" align: "); Wi(typ^.align);
                                 Ws(" nofm: "); Wi(typ^.n); Ws(" *)")
                               END
                  ELSE (* Ignore other comps *)
                  END
    ELSE (* Ignore other froms *)
    END
  END Wstruct;

  PROCEDURE Wtype(typ: OPT.Struct);
    VAR obj: OPT.Object;
  BEGIN
    obj := typ^.strobj;
    IF obj^.name # "" THEN
      IF typ^.mno # 0 THEN Ws(OPT.GlbMod[typ^.mno].name); Wch(".")
      ELSIF (typ = OPT.bytetyp) OR (typ = OPT.sysptrtyp) THEN Ws("SYSTEM.")
      ELSIF obj^.vis = OPT.internal THEN Wch("#")
      END ;
      Ws(obj^.name)
    ELSE
      IF (option = "x") & (typ^.ref > OPM.MaxStruct) THEN Wch("#"); Wi(typ^.ref - OPM.MaxStruct); Wch(" ") END ;
      Wstruct(typ)
    END
  END Wtype;

  PROCEDURE WModule(name: OPS.Name; T: Texts.Text);
    VAR i: INTEGER;
      beg, end: LONGINT; first, done: BOOLEAN;

    PROCEDURE Header(s: ARRAY OF CHAR);
    BEGIN
      beg := W.buf.len; Indent(1); Ws(s); Wln; end := W.buf.len
    END Header;

    PROCEDURE CheckHeader;
       VAR len: LONGINT;
    BEGIN
      len := T.len;
      IF end = W.buf.len THEN Texts.Append(T, W.buf); Texts.Delete(T, len+beg, len+end)
      ELSE Wln
      END
    END CheckHeader;

  BEGIN
    OPT.Import("@notself", name, done);
    IF done THEN
      Ws("DEFINITION "); Ws(name); Wch(";"); Wln; Wln;
      Header("IMPORT"); i := 1; first := TRUE;
      WHILE i < OPT.nofGmod DO
        IF first THEN first := FALSE; Indent(2) ELSE Ws(", ") END ;
        Ws(OPT.GlbMod[i].name);
        INC(i)
      END ;
      IF ~first THEN Wch(";"); Wln END ;
      CheckHeader;
      Header("CONST"); Objects(OPT.GlbMod[0].right, {OPT.Con}); CheckHeader;
      Header("TYPE"); Objects(OPT.GlbMod[0].right, {OPT.Typ}); CheckHeader;
      Header("VAR"); Objects(OPT.GlbMod[0].right, {OPT.Var}); CheckHeader;
      Objects(OPT.GlbMod[0].right, {OPT.XProc, OPT.IProc, OPT.CProc});
      Wln;
      Ws("END "); Ws(name); Wch("."); Wln; Texts.Append(T, W.buf)
    ELSE
      Texts.WriteString(W, name); Texts.WriteString(W, " -- symbol file not found");
      Texts.WriteLn(W); Texts.Append(T, W.buf)
    END
  END WModule;

  PROCEDURE Ident(VAR name, first: ARRAY OF CHAR);
    VAR i, j: INTEGER; ch: CHAR;
  BEGIN i := 0;
    WHILE name[i] # 0X DO INC(i) END ;
    WHILE (i >= 0) & (name[i] # "/") DO DEC(i) END ;
    INC(i); j := 0; ch := name[i];
    WHILE (ch # ".") & (ch # 0X) DO first[j] := ch; INC(i); INC(j); ch := name[i] END ;
    first[j] := 0X
  END Ident;

  PROCEDURE ShowDef*;
    VAR T, dummyT: Texts.Text; S, vname, name: OPS.Name; R: Texts.Reader; ch: CHAR;
      s: ARRAY 1024 OF CHAR; i: INTEGER;
  BEGIN
    option := 0X; Platform.GetArg(1, S);
    IF Platform.ArgCount > 2 THEN
      IF S[0] = OptionChar THEN option := S[1]; Platform.GetArg(2, S)
      ELSE Platform.GetArg(2, vname); option := vname[1]
      END
    END ;
    IF Platform.ArgCount >= 2 THEN
      Ident(S, name);
      NEW(T); Texts.Open(T, "");
      OPT.Init(name, {}); OPT.SelfName := "AvoidErr154"; WModule(name, T); OPT.Close;
      Texts.OpenReader(R, T, 0); Texts.Read(R, ch); i := 0;
      WHILE ~R.eot DO
        IF ch = 0DX THEN s[i] := 0X; i := 0; Console.String(s); Console.Ln
        ELSE s[i] := ch; INC(i)
        END ;
        Texts.Read(R, ch)
      END ;
      s[i] := 0X; Console.String(s)
    END
  END ShowDef;

BEGIN
  Texts.OpenWriter(W); ShowDef
END BrowserCmd.
