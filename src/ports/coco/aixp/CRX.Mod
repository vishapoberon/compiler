(* ETH Oberon, Copyright 2001 ETH Zuerich Institut fuer Computersysteme, ETH Zentrum, CH-8092 Zuerich.
  (* Adapted from Shiryaev's Coco/R 2012.01 for Vishap Oberon Compiler *)
Refer to the "General ETH Oberon System Source License" contract available at: http://www.oberon.ethz.ch/ *)

MODULE CRX;  (** portable *)

IMPORT Oberon, Texts, Sets, CRS, CRT, CRA;

CONST
  symSetSize  = 100;
  maxTerm     =   3;   (* sets of size < maxTerm are enumerated *)

  tErr = 0; altErr = 1; syncErr = 2;
  EOL = 0DX;

VAR
  maxSS:    INTEGER;       (* number of symbol sets *)
  errorNr:  INTEGER;       (* highest parser error number *)
  curSy:    INTEGER;       (* symbol whose production is currently generated *)
  err, w:   Texts.Writer;
  fram:     Texts.Reader;
  syn:      Texts.Writer;
  scanner:  ARRAY 32 OF CHAR;
  symSet:   ARRAY symSetSize OF CRT.Set;


PROCEDURE Restriction(n: INTEGER);
BEGIN
  Texts.WriteLn(w); Texts.WriteString(w, "Restriction ");
  Texts.WriteInt(w, n, 0); Texts.WriteLn(w); Texts.Append(Oberon.Log, w.buf);
  HALT(99)
END Restriction;

PROCEDURE PutS(s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    IF s[i] = "$" THEN Texts.WriteLn(syn) ELSE Texts.Write(syn, s[i]) END ;
    INC(i)
  END
END PutS;

PROCEDURE PutI(i: INTEGER);
BEGIN Texts.WriteInt(syn, i, 0)
END PutI;

PROCEDURE Indent(n: INTEGER);
  VAR i: INTEGER;
BEGIN i := 0; WHILE i < n DO Texts.Write(syn, " "); INC(i) END
END Indent;

PROCEDURE PutSet(s: SET);
  VAR i: INTEGER; first: BOOLEAN;
BEGIN
  i := 0; first := TRUE;
  WHILE i < Sets.size DO
    IF i IN s THEN
      IF first THEN first := FALSE ELSE Texts.Write(syn, ",") END ;
      PutI(i)
    END ;
    INC(i)
  END
END PutSet;

PROCEDURE PutSet1(s: CRT.Set);
  VAR i: INTEGER; first: BOOLEAN;
BEGIN
  i := 0; first := TRUE;
  WHILE i <= CRT.maxT DO
    IF Sets.In(s, i) THEN
      IF first THEN first := FALSE ELSE Texts.Write(syn, ",") END ;
      PutI(i)
    END ;
    INC(i)
  END
END PutSet1;

PROCEDURE Length* (VAR s: ARRAY OF CHAR): INTEGER;
  VAR i: INTEGER;
BEGIN
  i:=0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END ;
  RETURN i
END Length;

(*
PROCEDURE Alternatives(gp: INTEGER): INTEGER;
  VAR gn: CRT.GraphNode; n: INTEGER;
BEGIN
  n := 0;
  WHILE gp > 0 DO
    CRT.GetNode(gp, gn); gp := gn.p2; INC(n)
  END ;
  RETURN n
END Alternatives;
*)

(* A. V. Shiryaev, 2012.01 *)
PROCEDURE Overlaps (VAR s1, s2: CRT.Set): BOOLEAN;
  VAR s3: CRT.Set;
BEGIN
  Sets.Intersect(s1, s2, s3);
  RETURN ~Sets.Empty(s3)
END Overlaps;

(* A. V. Shiryaev, 2012.01 *)
PROCEDURE UseCase (gp: INTEGER): BOOLEAN;
  VAR gn, gn2: CRT.GraphNode; nAlts: INTEGER;
    res: BOOLEAN;
    s1, s2: CRT.Set;
BEGIN
  IF gp > 0 THEN
    CRT.GetNode(gp, gn);
    IF gn.typ # CRT.alt THEN res := FALSE
    ELSE
      nAlts := 0;
      Sets.Clear(s1);
      res := TRUE;
      REPEAT
        CRT.GetNode(gp, gn);
        IF gn.p1 > 0 THEN
          CRT.CompExpected0(gn.p1, curSy, s2);
          IF Overlaps(s1, s2) THEN res := FALSE (* must not optimiza with CASE statement, if there are LL(1) warning(s) *)
          ELSE Sets.Unite(s1, s2);
            CRT.GetNode(gn.p1, gn2);
            IF gn2.typ = CRT.rslv THEN res := FALSE
            END (* must not optimize with CASE statement, if alt uses a resolver expression *)
          END
        END;
        gp := gn.p2; INC(nAlts)
      UNTIL ~res OR (gp <= 0);
      res := res & (nAlts > 5)
    END
  ELSE
    res := FALSE
  END;
RETURN res
END UseCase;

PROCEDURE CopyFramePart (stopStr: ARRAY OF CHAR); (*Copy from file <fram> to file <syn> until <stopStr>*)
  VAR ch, startCh: CHAR; i, j, high: INTEGER;
BEGIN
  startCh := stopStr[0]; high := Length(stopStr) - 1; Texts.Read (fram, ch);
  WHILE ch # 0X DO
    IF ch = startCh THEN (* check if stopString occurs *)
      i := 0;
      REPEAT
        IF i = high THEN RETURN END ;  (*stopStr[0..i] found; no unrecognized character*)
        Texts.Read (fram, ch); INC(i);
      UNTIL ch # stopStr[i];
      (*stopStr[0..i-1] found; 1 unrecognized character*)
      j := 0; WHILE j < i DO Texts.Write(syn, stopStr[j]); INC(j) END
    ELSE Texts.Write (syn, ch); Texts.Read(fram, ch)
    END
  END
END CopyFramePart;

PROCEDURE CopySourcePart (pos: CRT.Position; indent: INTEGER);
(*Copy sequence <position> from <src> to <syn>*)
  VAR ch: CHAR; i: INTEGER; nChars: INTEGER; r: Texts.Reader;
BEGIN
  IF (pos.beg >= 0) & (pos.len > 0) THEN
    Texts.OpenReader(r, CRS.src, pos.beg); Texts.Read(r, ch);
    nChars := pos.len - 1;
    Indent(indent);
    LOOP
      WHILE ch = EOL DO
        Texts.WriteLn(syn); Indent(indent);
        IF nChars > 0 THEN Texts.Read(r, ch); DEC(nChars) ELSE EXIT END ;
        i := pos.col;
        WHILE (ch = " ") & (i > 0) DO (* skip blanks at beginning of line *)
          IF nChars > 0 THEN Texts.Read(r, ch); DEC (nChars) ELSE EXIT END ;
          DEC(i)
        END
      END ;
      Texts.Write (syn, ch);
      IF nChars > 0 THEN Texts.Read(r, ch); DEC (nChars) ELSE EXIT END
    END
  END

(*  IF pos.beg >= 0 THEN
    Texts.OpenReader(r, CRS.src, pos.beg);
    nChars := pos.len; col := pos.col - 1; ch := " ";
    WHILE (nChars > 0) & (ch = " ") DO  (*skip leading blanks*)
      Texts.Read(r, ch); DEC(nChars); INC(col)
    END ;
    Indent(indent);
    LOOP
      WHILE ch = EOL DO
        Texts.WriteLn(syn); Indent(indent);
        IF nChars > 0 THEN Texts.Read(r, ch); DEC(nChars) ELSE EXIT END ;
        i := col - 1;
        WHILE (ch = " ") & (i > 0) DO (* skip blanks at beginning of line *)
          IF nChars > 0 THEN Texts.Read(r, ch); DEC (nChars) ELSE EXIT END ;
          DEC(i)
        END
      END ;
      Texts.Write (syn, ch);
      IF nChars > 0 THEN Texts.Read(r, ch); DEC (nChars) ELSE EXIT END
    END (* LOOP *)
  END *)
END CopySourcePart;

PROCEDURE GenErrorMsg (errTyp, errSym: INTEGER; VAR errNr: INTEGER);
  VAR i: INTEGER; name: ARRAY 32 OF CHAR; sn: CRT.SymbolNode;
BEGIN
  INC (errorNr); errNr := errorNr;
  CRT.GetSym (errSym, sn); COPY(sn.name, name);
  i := 0; WHILE name[i] # 0X DO IF name[i] = CHR(34) THEN name[i] := "'" END ; INC(i) END ;
  Texts.WriteString(err, "  |");
  Texts.WriteInt (err, errNr, 3); Texts.WriteString (err, ": Msg("); Texts.Write(err, CHR(34));
  CASE errTyp OF
  | tErr   : Texts.WriteString (err, name); Texts.WriteString (err, " expected")
  | altErr : Texts.WriteString (err, "invalid "); Texts.WriteString (err, name)
  | syncErr: Texts.WriteString (err, "this symbol not expected in "); Texts.WriteString (err, name)
  END ;
  Texts.Write(err, CHR(34)); Texts.Write(err, ")"); Texts.WriteLn(err)
END GenErrorMsg;

PROCEDURE NewCondSet (set: CRT.Set): INTEGER;
  VAR i: INTEGER;
BEGIN
  i := 1; (*skip symSet[0]*)
  WHILE i <= maxSS DO
    IF Sets.Equal(set, symSet[i]) THEN RETURN i END ;
    INC(i)
  END ;
  INC(maxSS); IF maxSS > symSetSize THEN Restriction (9) END ;
  symSet[maxSS] := set;
  RETURN maxSS
END NewCondSet;

PROCEDURE GenCond (set: CRT.Set; gp: INTEGER);
  VAR i, n: INTEGER;
    gn: CRT.GraphNode;

BEGIN
  CRT.GetNode(gp, gn);
  IF gn.typ = CRT.rslv THEN
    PutS(" "); CopySourcePart(gn.pos, 0)
  ELSE
    n := Sets.Elements(set, i);
    (*IF n = 0 THEN PutS(" FALSE")  (*this branch should never be taken*)
    ELSIF (n > 1) & Small(set) THEN
      PutS(" sym IN {"); PutSet(set[0]); PutS("} ")
    ELSIF n <= maxTerm THEN
      i := 0;
      WHILE i <= CRT.maxT DO
        IF Sets.In (set, i) THEN
          PutS(" (sym = "); PutI(i); Texts.Write(syn, ")");
          DEC(n); IF n > 0 THEN PutS(" OR") END
        END ;
        INC(i)
      END
    ELSE PutS(" sym IN symSet["); PutI(NewCondSet(set)); PutS(",0]")
    END ;*)
    IF n = 0 THEN PutS(" FALSE")  (*this branch should never be taken*)
    ELSIF n <= maxTerm THEN
      i := 0;
      WHILE i <= CRT.maxT DO
        IF Sets.In (set, i) THEN
          PutS(" (sym = "); PutI(i); Texts.Write(syn, ")");
          DEC(n); IF n > 0 THEN PutS(" OR") END
        END ;
        INC(i)
      END
    ELSE PutS(" StartOf("); PutI(NewCondSet(set)); PutS(") ")
    END ;
  END
END GenCond;

PROCEDURE GenCode (gp, indent: INTEGER; checked: CRT.Set);
  VAR gn, gn2: CRT.GraphNode; sn: CRT.SymbolNode; gp2: INTEGER;
      s1, s2: CRT.Set; errNr (*, alts*): INTEGER; equal: BOOLEAN;
      useCase: BOOLEAN;
BEGIN
  WHILE gp > 0 DO
    CRT.GetNode (gp, gn);
    CASE gn.typ OF

    | CRT.nt:
        Indent(indent);
        CRT.GetSym(gn.p1, sn); PutS(sn.name);
        IF gn.pos.beg >= 0 THEN
          Texts.Write(syn, "("); CopySourcePart(gn.pos, 0); Texts.Write(syn, ")")
        END ;
        PutS(";$")

    | CRT.t:
        CRT.GetSym(gn.p1, sn); Indent(indent);
        IF Sets.In(checked, gn.p1) THEN
          PutS("Get;$")
        ELSE
          PutS("Expect("); PutI(gn.p1); PutS(");$")
        END

    | CRT.wt:
        CRT.CompExpected(ABS(gn.next), curSy, s1);
        CRT.GetSet(0, s2); Sets.Unite(s1, s2);
        CRT.GetSym(gn.p1, sn); Indent(indent);
        PutS("ExpectWeak("); PutI(gn.p1); PutS(", "); PutI(NewCondSet(s1)); PutS(");$")

    | CRT.any:
        Indent(indent); PutS("Get;$")

    | CRT.eps: (* nothing *)

    | CRT.rslv: (* nothing *)

    | CRT.sem:
        CopySourcePart(gn.pos, indent); PutS(";$");

    | CRT.sync:
        CRT.GetSet(gn.p1, s1);
        GenErrorMsg (syncErr, curSy, errNr);
        Indent(indent);
        PutS("WHILE ~("); GenCond(s1, gn.p1 (* FIXME?: gp or gn.p1 ? *)); PutS(") DO Error(");
        PutI(errNr); PutS("); Get END ;$")

    | CRT.alt:
        CRT.CompFirstSet(gp, s1); equal := Sets.Equal(s1, checked);
        (* alts := Alternatives(gp); *)
        useCase := UseCase(gp);
        IF (* alts > 5 *) useCase THEN Indent(indent); PutS("CASE sym OF$") END ;
        gp2 := gp;
        WHILE gp2 # 0 DO
          CRT.GetNode(gp2, gn2);
          CRT.CompExpected(gn2.p1, curSy, s1);
          Indent(indent);
          IF (* alts > 5 *) useCase THEN PutS("| "); PutSet1(s1); PutS(": ") (*case labels*)
          ELSIF gp2 = gp THEN PutS("IF"); GenCond(s1, gn.p1); PutS(" THEN$")
          ELSIF (gn2.p2 = 0) & equal THEN PutS("ELSE$")
          ELSE PutS("ELSIF"); GenCond(s1, gn2.p1); PutS(" THEN$")
          END ;
          Sets.Unite(s1, checked);
          GenCode(gn2.p1, indent + 2, s1);
          gp2 := gn2.p2
        END ;
        IF ~ equal THEN
          GenErrorMsg(altErr, curSy, errNr);
          Indent(indent); PutS("ELSE Error("); PutI(errNr); PutS(")$")
        END ;
        Indent(indent); PutS("END ;$")

    | CRT.iter:
        CRT.GetNode(gn.p1, gn2);
        Indent(indent); PutS("WHILE");
        IF gn2.typ = CRT.wt THEN
          CRT.CompExpected(ABS(gn2.next), curSy, s1);
          CRT.CompExpected(ABS(gn.next), curSy, s2);
          CRT.GetSym(gn2.p1, sn);
          PutS(" WeakSeparator("); PutI(gn2.p1); PutS(", "); PutI(NewCondSet(s1));
          PutS(", "); PutI(NewCondSet(s2)); PutS(") ");
          Sets.Clear(s1); (*for inner structure*)
          IF gn2.next > 0 THEN gp2 := gn2.next ELSE gp2 := 0 END
        ELSE
          gp2 := gn.p1; CRT.CompFirstSet(gp2, s1); GenCond(s1, gn.p1)
        END ;
        PutS(" DO$");
        GenCode(gp2, indent + 2, s1);
        Indent(indent); PutS("END ;$")

    | CRT.opt:
        CRT.CompFirstSet(gn.p1, s1);
        IF ~ Sets.Equal(checked, s1) THEN
          Indent(indent); PutS("IF"); GenCond(s1, gn.p1); PutS(" THEN$");
          GenCode(gn.p1, indent + 2, s1);
          Indent(indent); PutS("END ;$")
        ELSE GenCode(gn.p1, indent, checked)
        END

    END ; (*CASE*)
    IF ~ (gn.typ IN {CRT.eps, CRT.sem, CRT.sync}) THEN Sets.Clear(checked) END ;
    gp := gn.next
  END
END GenCode;

PROCEDURE IsLetter (c: CHAR): BOOLEAN;
BEGIN
  RETURN (c >= "A") & (c <= "Z") OR (c >= "a") & (c <= "z")
END IsLetter;

(* A. V. Shiryaev, 2012.01 *)
PROCEDURE GenTokens;
  VAR i: INTEGER; sn: CRT.SymbolNode;
BEGIN
  i := 0;
  WHILE i < CRT.maxT DO
    CRT.GetSym(i, sn);
    IF IsLetter(sn.name[0]) THEN
      PutS("  "); PutS(sn.name); PutS("Token = "); PutI(i); PutS(";$") (* do not use '_' in Oberon identifiers *)
    END;
    INC(i)
  END
END GenTokens;

PROCEDURE GenCodePragmas;
  VAR i: INTEGER; sn: CRT.SymbolNode;

  PROCEDURE P(s1, s2: ARRAY OF CHAR);
  BEGIN
    PutS("      "); PutS(scanner); PutS(s1); PutS(" := "); PutS(scanner); PutS(s2); PutS(";$")
  END P;

BEGIN
  i := CRT.maxT + 1;
  WHILE i <= CRT.maxP DO
    CRT.GetSym(i, sn);
    PutS("      IF sym = "); PutI(i); PutS(" THEN$"); CopySourcePart(sn.semPos, 9); PutS("$      END ;$");
    INC(i)
  END ;
  P(".nextPos", ".pos"); P(".nextCol", ".col"); P(".nextLine", ".line"); P(".nextLen", ".len")
END GenCodePragmas;

PROCEDURE GenProcedureHeading (sn: CRT.SymbolNode; forward: BOOLEAN);
BEGIN
  PutS("PROCEDURE ");
  IF forward THEN Texts.Write(syn, "^") END ;
  PutS(sn.name);
  IF sn.attrPos.beg >= 0 THEN
    Texts.Write(syn, "("); CopySourcePart(sn.attrPos, 0); Texts.Write(syn, ")")
  END ;
  PutS(";$")
END GenProcedureHeading;

PROCEDURE GenForwardRefs;
  VAR sp: INTEGER; sn: CRT.SymbolNode;
BEGIN
  IF ~ CRT.ddt[5] THEN
    sp := CRT.firstNt;
    WHILE sp <= CRT.lastNt DO (* for all nonterminals *)
      CRT.GetSym (sp, sn); GenProcedureHeading(sn, TRUE);
      INC(sp)
    END ;
    Texts.WriteLn(syn)
  END
END GenForwardRefs;

PROCEDURE GenProductions;
  VAR sn: CRT.SymbolNode; checked: CRT.Set;
BEGIN
  curSy := CRT.firstNt;
  WHILE curSy <= CRT.lastNt DO (* for all nonterminals *)
    CRT.GetSym (curSy, sn); GenProcedureHeading (sn, FALSE);
    IF sn.semPos.beg >= 0 THEN CopySourcePart(sn.semPos, 2); PutS(" $") END ;
    PutS("BEGIN$"); Sets.Clear(checked);
    GenCode (sn.struct, 2, checked);
    PutS("END "); PutS(sn.name); PutS(";$$");
    INC (curSy);
  END ;
END GenProductions;

PROCEDURE InitSets;
  VAR i, j: INTEGER;
BEGIN
  i := 0; CRT.GetSet(0, symSet[0]);
  WHILE i <= maxSS DO
    j := 0;
    WHILE j <= CRT.maxT DIV Sets.size DO
      PutS("  symSet["); PutI(i); PutS(", ");PutI(j);
      PutS("] := {"); PutSet(symSet[i, j]); PutS("};$");
      INC(j)
    END ;
    INC(i)
  END
END InitSets;

(* A. V. Shiryaev, 2012.01 *)
(* d := s0 + s1 *)
PROCEDURE Append1 (VAR d: ARRAY OF CHAR; s0, s1: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  COPY(s0, d);
  i := Length(d);
  j := Length(s1);
  d[i+j] := 0X;
  WHILE j > 0 DO
    DEC(j);
    d[i+j] := s1[j]
  END
END Append1;

PROCEDURE GenCompiler*;
  VAR name, parser, driver: ARRAY 32 OF CHAR;
    err1: Texts.Buffer;

  PROCEDURE Names;
    VAR gn: CRT.GraphNode; sn: CRT.SymbolNode;
  BEGIN
    CRT.GetNode(CRT.root, gn); CRT.GetSym(gn.p1, sn);
    COPY(sn.name, name);
    Append1(parser, name, "P"); (* parser := name + "P" *)
    Append1(scanner, name, "S"); (* scanner := name + "S" *)
    Append1(driver, name, "Compile") (* driver := name + "Compile" *)
  END Names;

  PROCEDURE Errors1;
    VAR errNr, i: INTEGER;
  BEGIN
    Texts.OpenWriter(err); Texts.WriteLn(err);
    i := 0;
    WHILE i <= CRT.maxT DO GenErrorMsg(tErr, i, errNr); INC(i) END
  END Errors1;

  PROCEDURE Store (t: Texts.Text; VAR name: ARRAY OF CHAR);
    VAR fileName: ARRAY 32 OF CHAR;
  BEGIN
    Append1(fileName, name, ".Mod"); (* fileName := name + ".Mod" *)
    Texts.Close(t, fileName);
  END Store;

  PROCEDURE GenParser;
    VAR checked: CRT.Set;
      t: Texts.Text; pos: INTEGER;
  BEGIN
    NEW(t); Texts.Open(t, "Parser.FRM"); Texts.OpenReader(fram, t, 0);
    IF t.len = 0 THEN
      Texts.WriteString(w, "Parser.FRM not found"); Texts.WriteLn(w);
      Texts.Append(Oberon.Log, w.buf); HALT(99)
    END ;

    (*----- write *P.Mod -----*)
    Texts.OpenWriter(syn);
    NEW(t);  (* t.notify := Show;  *)  Texts.Open(t, "");
    CopyFramePart("-->modulename"); PutS(parser);
    CopyFramePart("-->scanner"); PutS(scanner);
    IF CRT.importPos.beg >= 0 THEN PutS(", "); CopySourcePart(CRT.importPos, 0) END ;
    CopyFramePart("-->constants");
    GenTokens; (* A. V. Shiryaev, 2012.01 *)
    PutS("maxP        = "); PutI(CRT.maxP); PutS(";$");
    PutS("  maxT        = "); PutI(CRT.maxT); PutS(";$");
    PutS("  nrSets = ;$"); Texts.Append(t, syn.buf); pos := SHORT(t.len - 2);
    CopyFramePart("-->declarations"); CopySourcePart(CRT.semDeclPos, 0);
    CopyFramePart("-->errors"); PutS(scanner); PutS(".Error(n, "); PutS(scanner); PutS(".nextPos)");
    CopyFramePart("-->scanProc");
    IF CRT.maxT = CRT.maxP THEN PutS(scanner); PutS(".Get(sym)")
    ELSE
      PutS("LOOP "); PutS(scanner); PutS(".Get(sym);$");
      PutS("    IF sym > maxT THEN$");
      GenCodePragmas;
      PutS("    ELSE EXIT$");
      PutS("    END$");
      PutS("END$")
    END ;
    CopyFramePart("-->productions"); GenForwardRefs; GenProductions;
    CopyFramePart("-->parseRoot"); Sets.Clear(checked); GenCode (CRT.root, 2, checked);
    CopyFramePart("-->initialization"); InitSets;
    CopyFramePart("-->modulename"); PutS(parser); Texts.Write(syn, ".");
    Texts.Append(t, syn.buf); NEW(err1); Texts.OpenBuf(err1); Texts.Copy(err.buf, err1); Texts.Append(t, err.buf);
    PutI(maxSS+1); (*if no set, maxSS = -1*) Texts.Insert(t, pos, syn.buf);
    Store(t, parser)
  END GenParser;

  (* A. V. Shiryaev, 2012.01 *)
  PROCEDURE GenDriver;
    VAR t: Texts.Text;
      dfName: ARRAY 32 OF CHAR;

    PROCEDURE TryDriver;
    BEGIN
      NEW(t); Texts.Open(t, dfName);
      IF t.len = 0 THEN
        Texts.WriteString(w, dfName); Texts.WriteString(w, " not found"); Texts.WriteLn(w);
        Texts.Append(Oberon.Log, w.buf)
      END
    END TryDriver;

  BEGIN
    Append1(dfName, name, "Driver.FRM"); (* dfName := name + "Driver.FRM" *)
    TryDriver;
    IF t.len = 0 THEN
      dfName := "Driver.FRM";
      TryDriver
    END;
    IF t.len # 0 THEN
      Texts.OpenReader(fram, t, 0);
      Texts.WriteString(w, " +driver"); Texts.Append(Oberon.Log, w.buf);
      (*----- write *Compile.Mod -----*)
      Texts.OpenWriter(syn);
      NEW(t); Texts.Open(t, "");
      CopyFramePart("-->modulename"); PutS(driver);
      CopyFramePart("-->scanner"); PutS(scanner);
      CopyFramePart("-->parser"); PutS(parser);
      CopyFramePart("-->errors"); Texts.Append(t, syn.buf); Texts.Append(t, err1);
      CopyFramePart("-->name"); PutS(name);
      CopyFramePart("-->modulename"); PutS(driver); Texts.Write(syn, ".");
      Texts.Append(t, syn.buf);
      Store(t, driver)
    END
  END GenDriver;

BEGIN
  Names;
  Errors1;
  GenParser; (* required *)
  GenDriver (* optional *)
END GenCompiler;

PROCEDURE WriteStatistics*;
BEGIN
  Texts.WriteInt (w, CRT.maxT + 1, 0); Texts.WriteString(w, " t, ");
  Texts.WriteInt (w, CRT.maxSymbols - CRT.firstNt + CRT.maxT + 1, 0); Texts.WriteString(w, " syms, ");
  Texts.WriteInt (w, CRT.nNodes, 0); Texts.WriteString(w, " nodes, ");
  Texts.WriteInt (w, maxSS, 0); Texts.WriteString(w, "sets");
  Texts.WriteLn(w); Texts.Append(Oberon.Log, w.buf)
END WriteStatistics;

PROCEDURE Init*;
BEGIN
  errorNr := -1; maxSS := 0  (*symSet[0] reserved for all SYNC sets*)
END Init;

BEGIN
  Texts.OpenWriter(w)
END CRX.
