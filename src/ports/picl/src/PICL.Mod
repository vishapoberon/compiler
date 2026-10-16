MODULE PICL;  (*NW 22.2.2005 / 16.10.2014*)
IMPORT Texts, Oberon, PICS, SYSTEM,
       POutput,(*to dump generated code, voc adaptation; -- noch *)
       PErrors(*for better error reporting; -- noch *);

CONST var = 1; con = 2; proc = 3;   (*item forms*)
  intT = 1; setT = 2; boolT = 3;    (*types*)
  gpio = - 32; gpoc = - 28;  (*general-purpose, 2-bit I/O data and output control*)

  (*symbols*) null = 0;
  ast = 1; slash = 2; plus = 3; minus = 4; not = 5; and = 6; or = 7;
  eql = 10; neq = 11; geq = 12; lss = 13; leq = 14; gtr = 15;
  period = 16; comma = 17; colon = 18;
  op = 20; query = 21; lparen = 22; becomes = 23;
  ident = 24; if = 25; while = 26; repeat = 27;
  inc = 28; dec = 29; rol = 30; ror = 31;
  number = 32; rparen = 33; then = 34; do =  35;
  semicolon = 36; end = 37; else = 38 ; elsif =  39; until =  40; return = 41;
  int = 42; set = 43; bool = 44;
  const = 50; begin = 51; proced = 52; module = 53; eof = 54;

TYPE Object = POINTER TO ObjDesc;
  ObjDesc = RECORD
    name: ARRAY PICS.IdLen OF CHAR;
    form, typ, ptyp, a: LONGINT;
    next: Object
  END ;

  OpCode = ARRAY 8 OF CHAR;

  VAR sym: LONGINT;  (*last symbol read by scanner*)
  IdList, IdList0, undef: Object;
  pc, dc: LONGINT;
  error: BOOLEAN;
  errpos: LONGINT;
  Statement: PROCEDURE;
  W: Texts.Writer;
  code: ARRAY 1024 OF LONGINT;
  name: ARRAY PICS.IdLen OF CHAR; (* for dumping generated code; -- noch *)

  table0, table3: ARRAY 16 OF OpCode;  (*for decoding only*)
  table1: ARRAY 4 OF OpCode;
  table2: ARRAY 2 OF OpCode;

PROCEDURE Mark (num: LONGINT);
  VAR p: LONGINT;
BEGIN p := PICS.position();
  IF p > errpos + 2 THEN
    Texts.WriteString(W, "  pos "); Texts.WriteInt(W, p, 1);
    Texts.WriteString(W, "  err "); Texts.WriteInt(W, num, 1);
    Texts.WriteString(W, " "); Texts.WriteString(W, PErrors.errors[num]);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END ;
  errpos := p; error := TRUE
END Mark;

PROCEDURE this (id: ARRAY OF CHAR): Object;
  VAR obj: Object;
BEGIN obj := IdList;
  WHILE (obj # NIL) & (obj.name # id) DO obj := obj.next END ;
  IF obj = NIL THEN Mark(0); obj := undef END ;
  RETURN obj
END this;

PROCEDURE enter (id: ARRAY OF CHAR; form, typ, a: LONGINT);
  VAR obj: Object;
BEGIN NEW(obj); obj.name := id; obj.form := form; obj.typ := typ; obj.a := a;
  obj.next := IdList; IdList := obj
END enter;

PROCEDURE emit (op, a: LONGINT);
BEGIN code[pc] := op * 100H + a; INC(pc)
END emit;

PROCEDURE emit1 (op, n, a: LONGINT);
BEGIN code[pc] := ((op + 4) * 8 + n) * 80H + a; INC(pc)
END emit1;

PROCEDURE index (VAR n: LONGINT);
BEGIN n := 0;
  IF sym = period THEN
    PICS.Get(sym);
    IF sym = number THEN n := PICS.val; PICS.Get(sym) ELSE Mark(11) END
  END
END index;

PROCEDURE expression;
  VAR x, y: Object; op, xf, xt, xval, yt, yval: LONGINT;
BEGIN xval := 0;
  IF sym = ident THEN x := this(PICS.id); xf := x.form; xt := x.typ; xval := x.a; PICS.Get(sym)
  ELSIF sym = number THEN xf := con; xval := PICS.val; xt := PICS.typ; PICS.Get(sym)
  ELSE Mark(10)
  END ;
  IF sym = lparen THEN  (*function call*)
    PICS.Get(sym);
    IF x.form # proc THEN Mark(3) END ;
    IF sym # rparen THEN expression END ;
    emit(20H, x.a);   (*CALL x*)
    IF sym = rparen THEN PICS.Get(sym) ELSE Mark(8) END
  ELSIF (sym >= ast) & (sym <= minus) THEN
    op := sym; PICS.Get(sym); yval := 0; ;
    IF sym = ident THEN
      y := this(PICS.id); yt := y.typ; PICS.Get(sym);
      IF y.form = var THEN emit(8, y.a)    (*MOVFW y*)
      ELSIF y.form = con THEN emit(30H, y.a)   (*MOVLW y*)
      ELSE Mark(10)
      END
    ELSIF sym = number THEN
      yval := PICS.val; yt := PICS.typ; emit(30H, yval); PICS.Get(sym)
    END ;
    IF xt # yt THEN Mark(111) END ;
    IF xf = var THEN
      IF op = plus THEN
        IF xt = intT THEN emit(7, x.a) ELSE emit(4, x.a) END   (*ADDFW/IORFW*)
      ELSIF op = minus THEN
        IF xt = intT THEN emit(2, x.a) ELSE emit(6, x.a) END   (*SUBFW/XORFW*)
      ELSIF op = ast THEN
        IF xt = intT THEN Mark(11) ELSE emit(5, x.a) END   (*ANDFW*)
      END
    ELSIF xf = con THEN
      IF op = plus THEN
        IF xt = intT THEN emit(3EH, xval) ELSE emit(38H, xval) END   (*ADDLW/IORLW*)
      ELSIF op = minus THEN
        IF xt = intT THEN emit(3CH, xval) ELSE emit(3AH, xval) END   (*SUBLW/XORLW*)
      ELSIF op = ast THEN
        IF xt = intT THEN Mark(11) ELSE emit(39H, xval) END   (*ANDLW*)
      ELSE Mark(9)
      END
    ELSE Mark(10)
    END
  ELSIF xf = var THEN emit(8, x.a);    (*MOVFW x*)
  ELSIF xf = con THEN emit(30H, xval)
  ELSE Mark(10)
  END
END expression;

PROCEDURE term;
  VAR x, y: Object; n, rel, yf, ya: LONGINT;
BEGIN
  IF sym = ident THEN
    x := this(PICS.id); PICS.Get(sym);
    IF (sym >= eql) & (sym <= gtr) THEN
      rel := sym; PICS.Get(sym);
      IF sym = ident THEN y := this(PICS.id); PICS.Get(sym); yf := y.form; ya := y.a;
      ELSIF sym = number THEN yf := con; ya := PICS.val; PICS.Get(sym)
      END ;
      IF rel < leq THEN  (* eql neq geq lss:  x-y*)
        IF yf = var THEN emit(8, ya); emit(2, x.a)   (*MOVFW y  SUBFW x*)
        ELSIF yf = con THEN
          IF ya = 0 THEN emit(8, x.a)    (*MOVLW x*)
          ELSE emit(30H, ya); emit(2, x.a)   (*MOVLW y  SUBFW x*)
          END
        END
      ELSE  (* leq gtr:   y-x*)
        emit(8, x.a);   (*MOVFW x*)
        IF yf = var THEN emit(2, ya)   (*SUBFW y*)
        ELSIF (yf = con) & (ya # 0) THEN emit(60, ya)   (*SUBLW y*)
        END
      END ;
      IF rel = eql THEN emit1(3, 2, 3)     (*BTFSS S.Z*)
      ELSIF rel = neq THEN emit1(2, 2, 3)  (*BTFSC S.Z*)
      ELSIF (rel = geq) OR (rel = leq) THEN emit1(3, 0, 3)  (*BTFSS S.C*)
      ELSIF (rel = lss) OR( rel = gtr) THEN emit1(2, 0, 3)  (*BTFSC S.C*)
      END
    ELSE index(n); emit1(3, n, x.a)  (*BTFSC n, x*)
    END
  ELSIF sym = not THEN
    PICS.Get(sym);
    IF sym = ident THEN
      x := this(PICS.id); PICS.Get(sym);
      index(n); emit1(2, n, x.a)  (*BTFSS n, x*)
    ELSE Mark(10)
    END
  ELSE Mark(10)
  END
END term;

PROCEDURE condition (VAR link: LONGINT);
  VAR L, L0, L1: LONGINT;
BEGIN term; code[pc] := 0; L := pc; INC(pc);
  IF sym = and THEN
    REPEAT PICS.Get(sym); term; code[pc] := L; L := pc; INC(pc)
    UNTIL sym # and
  ELSIF sym = or THEN
    REPEAT PICS.Get(sym); term; code[pc] := L; L := pc; INC(pc)
    UNTIL sym # or;
    L0 := code[L]; code[L] := 0;
    REPEAT (*invert skip sense*)
      IF code[L0 - 1] DIV 400H = 6 THEN (*BITFSC*) INC(code[L0 - 1], 400H)
      ELSE (*BITFSS*) DEC(code[L0 - 1], 400H)
      END ;
      L1 := code[L0]; code[L0] := pc + 2800H; L0 := L1
    UNTIL L0 = 0
  END ;
  link := L
END condition;

PROCEDURE fixup (L, k: LONGINT);
  VAR L1: LONGINT;
BEGIN
  WHILE L # 0 DO L1 := code[L]; code[L] := k + 2800H; L := L1 END
END fixup;

PROCEDURE StatSeq;
BEGIN Statement;
  WHILE sym = semicolon DO PICS.Get(sym); Statement END
END StatSeq;

PROCEDURE Guarded (VAR L: LONGINT);
BEGIN condition(L);
  IF sym = then THEN PICS.Get(sym) ELSE Mark(14) END ;
  StatSeq
END Guarded;

PROCEDURE IfStat;
  VAR L0, L: LONGINT;
BEGIN condition(L);
  IF sym = then THEN PICS.Get(sym) ELSE Mark(14) END ;
  StatSeq; L0 := 0;
  WHILE sym = elsif DO
    code[pc] := L0; L0 := pc; INC(pc); fixup(L, pc);
    PICS.Get(sym); condition(L);
    IF sym = then THEN PICS.Get(sym) ELSE Mark(14) END ;
    StatSeq
  END ;
  IF sym = else THEN
    code[pc] := L0; L0 := pc; INC(pc); fixup(L, pc);
    PICS.Get(sym); StatSeq
  ELSE fixup(L, pc)
  END ;
  IF sym = end THEN PICS.Get(sym) ELSE Mark(15) END ;
  fixup(L0, pc)
END IfStat;

PROCEDURE WhileStat;
  VAR L0, L: LONGINT;
BEGIN L0 := pc; condition(L);
  IF sym = do THEN PICS.Get(sym) ELSE Mark(14) END ;
  StatSeq; emit(28H, L0); fixup(L, pc);
  WHILE sym = elsif DO
    PICS.Get(sym); condition(L);
    IF sym = do THEN PICS.Get(sym) ELSE Mark(14) END ;
    StatSeq; emit(28H, L0); fixup(L, pc)
  END ;
  IF sym = end THEN PICS.Get(sym) ELSE Mark(16) END
END WhileStat;

PROCEDURE RepeatStat;
  VAR L0, L: LONGINT;
BEGIN L0 := pc; StatSeq;
  IF sym = until THEN
    PICS.Get(sym); condition(L);  (*try to use DECFSZ*)
    IF (code[pc - 4] DIV 100H = 3) & (code[pc - 3] DIV 100H = 8) &
        (code[pc-2] = 1D03H) & (code[pc-4] MOD 80H = code[pc-3] MOD 100H) THEN
          INC(code[pc-4], 800H); code[pc-3] := 0; DEC(pc, 2); L := pc-1
      END ;
      fixup(L, L0)
    ELSIF sym = end THEN PICS.Get(sym); emit(28H, L0)
    ELSE Mark(25)
    END
  END RepeatStat;

  PROCEDURE Operand1(cd: LONGINT);
    VAR x: Object;
  BEGIN
    IF sym = ident THEN
      x := this(PICS.id); PICS.Get(sym);
      IF x.form # var THEN Mark(2) END ;
      emit(cd, x.a + 80H)  (*INCF/DECF/RRF/RLF*)
    ELSE Mark(10)
    END
  END Operand1;

  PROCEDURE Operand2(cd: LONGINT);
    VAR x: Object; op, n: LONGINT;
  BEGIN
    IF sym = ident THEN
      x := this(PICS.id); PICS.Get(sym);
      IF x.form # var THEN Mark(2) END ;
      index(n); emit1(cd, n, x.a)  (*BSF/BCF*)
    ELSE Mark(10)
    END
  END Operand2;

  PROCEDURE Statement0;
    VAR x: Object; w: LONGINT;
  BEGIN
    IF sym = ident THEN
      x := this(PICS.id); PICS.Get(sym);
      IF sym = becomes THEN
        PICS.Get(sym);
        IF x.form # var THEN Mark(2) END ;
        expression; w := code[pc-1];
        IF w = 3000H THEN code[pc-1] := x.a + 180H   (*CLR x*)
        ELSIF (w DIV 100H <= 13) & (w MOD 100H = x.a) THEN INC(code[pc-1], 80H)
        ELSE emit(0, x.a + 80H)   (*MOVWF*)
        END
      ELSE (*proc call*)
        IF x.form # proc THEN Mark(3) END ;
        IF sym = lparen THEN
          PICS.Get(sym); expression; emit(20H, x.a);   (*CALL*)
          IF sym = rparen THEN PICS.Get(sym) ELSE Mark(8) END
        ELSE
          emit(20H, x.a)   (*CALL*)
        END
      END
    ELSIF sym = inc THEN PICS.Get(sym); Operand1(10)   (*INCF*)
    ELSIF sym = dec THEN PICS.Get(sym); Operand1(3)   (*DECF*)
    ELSIF sym = rol THEN PICS.Get(sym); Operand1(13)   (*RLF*)
    ELSIF sym = ror THEN PICS.Get(sym); Operand1(12)   (*RRF*)
    ELSIF sym = op THEN PICS.Get(sym);
      IF sym = not THEN PICS.Get(sym); Operand2(0)   (*BCF*)
      ELSE Operand2(1)    (*BSF*)
      END ;
    ELSIF sym = query THEN PICS.Get(sym);
      IF sym = not THEN PICS.Get(sym); Operand2(2) ELSE Operand2(3) END ;
      emit(28H, pc-1)   (*BTFSS/BTFSC*)
    ELSIF sym = lparen THEN
      PICS.Get(sym); StatSeq;
      IF sym = rparen THEN PICS.Get(sym) ELSE Mark(8) END
    ELSIF sym = if THEN PICS.Get(sym); IfStat
    ELSIF sym = while THEN PICS.Get(sym); WhileStat
    ELSIF sym = repeat THEN PICS.Get(sym); RepeatStat
    END
  END Statement0;

  PROCEDURE ProcDecl;
    VAR typ, partyp, restyp, pc0: LONGINT;
      obj, res: Object;
      name: ARRAY PICS.IdLen OF CHAR;
  BEGIN obj := IdList; partyp := 0; restyp := 0; pc0 := pc;
    IF sym = ident THEN name := PICS.id; PICS.Get(sym) ELSE Mark(10) END ;
    IF sym = lparen THEN (*parameter*)
      PICS.Get(sym);
      IF (sym >= int) & (sym <= bool) THEN
        partyp := sym - int + 1; PICS.Get(sym);
        IF sym = ident THEN enter(PICS.id, var, partyp, dc); PICS.Get(sym); emit(0, dc+80H); INC(dc)
        ELSE Mark(10)
        END
      END ;
      IF sym = rparen THEN PICS.Get(sym) ELSE Mark(8) END
    END ;
    IF sym = colon THEN  (*result type*)
      PICS.Get(sym);
      IF (sym >= int) & (sym <= bool) THEN restyp := sym - int + 1; PICS.Get(sym);
      ELSE Mark(10)
      END
    END ;
    IF sym = semicolon THEN PICS.Get(sym) ELSE Mark(20) END ;
    WHILE (sym >= int) & (sym <= bool) DO  (*variable declarations*)
      typ := sym - int + 1; PICS.Get(sym);
      WHILE sym = ident DO
        enter(PICS.id, var, typ, dc); INC(dc); PICS.Get(sym);
        IF sym = comma THEN PICS.Get(sym) END
      END ;
      IF sym = semicolon THEN PICS.Get(sym) ELSE Mark(20) END ;
    END ;
    IF sym = begin THEN PICS.Get(sym); StatSeq ELSE Mark(21) END ;
    IF sym = return THEN PICS.Get(sym); expression END ;
    emit(0, 8);  (*RET*)
    IF sym = end THEN PICS.Get(sym);
      IF sym = ident THEN
        IF PICS.id # name THEN Mark(22) END ;
        PICS.Get(sym)
      ELSE Mark(10)
      END
    ELSE Mark(18)
    END ;
    IF sym = semicolon THEN PICS.Get(sym) ELSE Mark(20) END ;
    IdList := obj;    (*reset scope*)
    enter(name, proc, restyp, pc0); IdList.ptyp := partyp
  END ProcDecl;

  PROCEDURE Module;
    VAR typ: LONGINT; (*name: ARRAY PICS.IdLen OF CHAR;*)
  BEGIN name[0] := 0X;
    IF sym = module THEN
      PICS.Get(sym);
      IF sym = ident THEN name := PICS.id; PICS.Get(sym) ELSE Mark(10) END ;
      IF sym = semicolon THEN PICS.Get(sym) ELSE Mark(20) END ;
    END ;
    Texts.WriteString(W, "PIC compiling "); Texts.WriteString(W, name); Texts.WriteLn(W);
    IF sym = const THEN
      PICS.Get(sym);
      WHILE sym = ident DO
        enter(PICS.id, 2, 1, 0); PICS.Get(sym);
        IF sym = eql THEN
          PICS.Get(sym);
          IF sym = number THEN IdList.a := PICS.val; PICS.Get(sym) ELSE Mark(10) END
        ELSE Mark(5)
        END ;
        IF sym = semicolon THEN PICS.Get(sym) ELSE Mark(20) END
      END
    END ;
    WHILE (sym >= int) & (sym <= bool) DO
      typ := sym - int + 1; PICS.Get(sym);
      WHILE sym = ident DO
        enter(PICS.id, var, typ, dc); INC(dc); PICS.Get(sym);
        IF sym = comma THEN PICS.Get(sym) END
      END ;
      IF sym = semicolon THEN PICS.Get(sym) END
    END ;
    WHILE sym = proced DO PICS.Get(sym); ProcDecl END ;
    IF pc > 1 THEN code[0] := pc + 2800H ELSE pc := 0 END ;
    IF sym = begin THEN PICS.Get(sym); StatSeq END ;
    IF sym = end THEN PICS.Get(sym);
      IF PICS.id # name THEN Mark(22) END
    ELSE Mark(18) 
    END ;
    Texts.WriteInt(W, pc, 5); Texts.WriteLn(W)
  END Module;

  PROCEDURE Compile*;
    VAR i, u, v: LONGINT; obj: Object;
      T: Texts.Text;
      S: Texts.Scanner; (* voc adaptation, for scanning commandline arguments -- noch *)
      beg, end, time: LONGINT;
  BEGIN 
    (*Oberon.GetSelection(T, beg, end, time);
    IF time >= 0 THEN*)
    beg := 0; (* voc adaptation; -- noch *)
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    NEW(T);
    Texts.Open(T, S.s);
    IF T.len > 0 THEN
      IdList := IdList0; PICS.Init(T, beg); pc := 1; dc := 12; error := FALSE; errpos := 0;
      PICS.Get(sym); Module;
      Texts.Append(Oberon.Log, W.buf)
    END
  END Compile;

  PROCEDURE Decode*;
    VAR i, u, v: LONGINT; obj: Object;
  BEGIN obj := IdList;
      WHILE obj # IdList0 DO
        Texts.WriteInt(W, obj.form, 4); Texts.WriteInt(W, obj.typ, 4); Texts.WriteInt(W, obj.a, 4);
        Texts.Write(W, " "); Texts.WriteString(W, obj.name); Texts.WriteLn(W);
        obj := obj.next
      END ;
      Texts.Append(Oberon.Log, W.buf);
      FOR i := 0 TO pc-1 DO
        Texts.WriteInt(W, i, 4); u := code[i]; Texts.WriteHex(W, u); Texts.Write(W, " ");
        v := u DIV 1000H; u := u MOD 1000H;
        IF v = 0 THEN
          IF u = 8 THEN Texts.WriteString(W, "RET"); Texts.WriteLn(W)
          ELSE Texts.WriteString(W, table0[u DIV 100H]);
            Texts.WriteInt(W, u DIV 80H MOD 2, 3); Texts.WriteInt(W, u MOD 80H, 4)
          END
        ELSIF v = 1 THEN
          Texts.WriteString(W, table1[u DIV 400H]);
          Texts.WriteInt(W, u DIV 80H MOD 8, 3);  Texts.WriteInt(W, u MOD 80H, 4)
        ELSIF v = 2 THEN
          Texts.WriteString(W, table2[u DIV 800H]);
          Texts.WriteInt(W, u MOD 100H, 5)
        ELSIF v = 3 THEN
          Texts.WriteString(W, table3[u DIV 100H]);
          Texts.WriteInt(W, u MOD 100H, 6)
        END ;
        Texts.WriteLn(W)
      END ;
      Texts.Append(Oberon.Log, W.buf)
  END Decode;

  (*------------ Procedures for loading code into PIC ------------*)
  
  (* Port represents a 2-wire connection to the PIC-board:
    bit 0: data, PIC B7
    bit 1: clock, PIC B6 *)
(*
  PROCEDURE delay;  (* >3us *)
    VAR t: LONGINT;
  BEGIN t :=8;
    REPEAT DEC(t) UNTIL t = 0
  END delay;

  PROCEDURE delay1;  (*10ms*)
    VAR T: LONGINT;
  BEGIN T := Oberon.Time() + 10;
    REPEAT UNTIL Oberon.Time() >= T
  END delay1;

  PROCEDURE bits(x, n: LONGINT);
    VAR b: LONGINT;
  BEGIN (*send n bits of x*)
    REPEAT DEC(n); b := x MOD 2; x := x DIV 2;
      SYSTEM.PUT(gpio, b+2); SYSTEM.PUT(gpio, b)
    UNTIL n = 0
  END bits;

  PROCEDURE SendWord(x: LONGINT);
    VAR i: LONGINT;
  BEGIN bits(2, 6);  (*load cmd*)
    bits(x*2, 16);  (*data*)
    bits(8, 6);  (*program cmd*)
    delay1;
    bits(6, 6);  (*inc adr cmd*)
  END SendWord;
  
  PROCEDURE ReceiveWord(VAR x: LONGINT);
    VAR a,  i: LONGINT; b: SYSTEM.BYTE;
  BEGIN SYSTEM.PUT(gpio, 3); bits(4, 6);  (*read cmd*)
    delay; a := 0; i := 16;
    REPEAT SYSTEM.PUT(gpio, 3); SYSTEM.PUT(gpio, 1); delay;
      SYSTEM.PUT(gpoc, 2); (*switch to input*)
      SYSTEM.GET(gpio, b); b := b DIV 40H MOD 2;  (*bit 6*)
      a := ORD(SYSTEM.BIT(gpio, 0)) * 8000H + (a DIV 2);
      SYSTEM.PUT(gpoc, 3); delay; (*switch back to output*); DEC(i)
    UNTIL i = 0;
    x := a DIV 2 MOD 4000H;
    SYSTEM.PUT(gpio, 0); bits(6, 6);  (*inc adr cmd*)
  END ReceiveWord;

  PROCEDURE Reset*;
  BEGIN SYSTEM.PUT(gpio, 0); SYSTEM.PUT(gpoc, 3)
  END Reset;

  PROCEDURE Program*;
    VAR i: LONGINT;
  BEGIN Reset; Texts.WriteString(W, "programming PIC ... "); Texts.Append(Oberon.Log, W.buf);
    delay1; i := 0;
    WHILE i < pc DO SendWord(code[i]); INC(i) END ;
    Texts.WriteString(W, "done"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Program;

  PROCEDURE Configure*;
    VAR i, x: LONGINT; S: Texts.Scanner;
  BEGIN Reset;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    Texts.WriteString(W, "confirguring PIC  "); Texts.WriteHex(W, S.i);
    SYSTEM.PUT(gpio, 0); delay1;
    bits(0, 6); bits(S.i * 2, 16); i := 0;
    REPEAT bits(6, 6); INC(i) UNTIL i = 7;
    bits(1, 6); bits(7, 6); bits(8, 6); delay; bits(1, 6); bits(7, 6);
    ReceiveWord(x);
    Texts.WriteHex(W, x); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
  END Configure;

  PROCEDURE EraseProgram*;
  BEGIN Reset; Texts.WriteString(W, "erase program"); Texts.Append(Oberon.Log, W.buf);
    SYSTEM.PUT(gpio, 0); delay1;
    SendWord(-1); bits(9, 6); bits(8, 6); delay1;
    Texts.WriteString(W, "done"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END EraseProgram;
  
  PROCEDURE EraseData*;
  BEGIN Reset; Texts.WriteString(W, "erase data"); Texts.Append(Oberon.Log, W.buf);
    SYSTEM.PUT(gpio, 0); delay1;
    SendWord(-1); bits(11, 6); bits(8, 6); delay1;
    Texts.WriteString(W, "done"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END EraseData;
  
  PROCEDURE Verify*;
    VAR i, x: LONGINT;
  BEGIN Reset; Texts.WriteString(W, "verifying PIC ... "); Texts.Append(Oberon.Log, W.buf);
    SYSTEM.PUT(gpio, 0); delay1;
    i := 0;
    WHILE i < pc DO
      ReceiveWord(x);
      IF code[i] # x THEN
        Texts.WriteString(W, " error at"); Texts.WriteInt(W, i, 5); Texts.WriteHex(W, x); i := pc 
      ELSE INC(i)
      END
    END ;
    Texts.WriteString(W, " done"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Verify;
*)
  PROCEDURE enter1(id: CHAR; form, typ, a: LONGINT);
    VAR obj: Object;
  BEGIN NEW(obj); obj.name[0] := id; obj.form := form; obj.typ := typ; obj.a := a;
    obj.next := IdList; IdList := obj
  END enter1;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "PICL  8.8.2014");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); NEW(undef);
  (* instruction names for decoder*)
  table0[0] := "MOVWF"; table0[1] := "CLRF "; table0[2] := "SUBWF"; table0[3] := "DECF ";
  table0[4] := "IORWF"; table0[5] := "ANDWF"; table0[6] := "XORWF"; table0[7] := "ADDWF";
  table0[8] := "MOVFW"; table0[9] := "COMF "; table0[10] := "INCF "; table0[11] := "DECFSZ";
  table0[12] := "RRF  "; table0[13] := "RLF  "; table0[14] := "SWAPF"; table0[15] := "INCFSZ";

  table1[0] := "BCF  "; table1[1] := "BSF  "; table1[2] := "BTFSC"; table1[3] := "BTFSS";
  table2[0] := "CALL "; table2[1] := "GOTO ";

  table3[0] := "MOVLW"; table3[4] := "RETLW";
  table3[8] := "IORLW"; table3[9] := "ANDLW"; table3[10] := "XORLW";
  table3[12] := "SUBLW"; table3[14] := "ADDLW";

  (*predefined registers A, B, S, T / timer or option*)
  enter1("T", 1, 2, 1); enter1("S", 1, 2, 3); enter1("A", 1, 2, 5); enter1("B", 1, 2, 6);
  IdList0 := IdList; Statement := Statement0; (*Reset*)
  Compile;
  POutput.DumpCode(name, code, pc)
END PICL.
