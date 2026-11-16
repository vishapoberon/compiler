MODULE none;  (** a small nano-like editor for Oberon texts and plain files *)

(* none.Open file   edit a file, a new one when it does not exist
   none file        standalone invocation

   Plain files stay plain, Oberon texts keep their fonts and colours; in the Write Out
   prompt (^O), ^T switches between storing as Oberon text and as plain text.
   Keys as in nano: ^O write out, ^X exit, ^W where is, ^G help, ^E line end, ^Y page up, arrows,
   Home, End, PgUp, PgDn; Ctrl+Left/Right by words.
   Selection as in TextFrames: Shift with the movement keys selects, ^A selects all. ^B starts a
   block (columns over lines) that the movement keys then extend; once something is typed, deleted
   or copied they end it and move, as Esc and ^B do (no modifier needed: works in every terminal);
   Alt+Shift with the movement keys selects a block too. ^C copies the selection (without one: the location), ^K cuts it (without
   one: the line), ^V and ^U paste. Typing, Backspace and Delete replace a selection; with a block
   they act on every line of it (a block of width 0 types into all its lines: indenting). Copies
   go to the terminal's clipboard too (OSC 52); a paste from the terminal is taken as it is.

   In .Mod and .mod files, Module. lists an imported module's exports, including aliases.
   Ctrl+Space also completes unimported modules, local declarations and predeclared procedures.
   Typing filters without regard to case; arrows and page keys choose, Enter or Tab accepts,
   and Esc closes the list. Calls show parameter hints, including across line breaks. *)

IMPORT SYSTEM, Platform, Heap, Files, Texts, termios, Oberon, Out, Modules,
  BrowserCmd, OPM, OPS, Strings, NonePaths;

CONST
  ESC = 1BX; CR = 0DX; LF = 0AX; TAB = 09X;
  (* keys above the characters *)
  KUp = 1001; KDown = 1002; KRight = 1003; KLeft = 1004;
  KHome = 1005; KEnd = 1006; KPgUp = 1007; KPgDn = 1008; KDel = 1009; KNone = 1010;
  KPaste = 1011;  (* the start of a bracketed paste of the terminal *)
  KEsc = 1012;    (* Esc alone *)
  Shift = 1; Alt = 2; Ctrl = 4;  (* mods *)
  ListRows = 8;
  BoxColour = "0;38;5;252;48;5;238m"; ChosenColour = "0;1;38;5;234;48;5;250m";
  ParamOn = "1;38;5;231m"; ParamOff = "22;38;5;252m";
  MaxMatch = 512;

TYPE
  Entry = POINTER TO EntryDesc;
  EntryDesc = RECORD
    kind: CHAR;  (* procedure, variable, constant, type, module or standard procedure *)
    params: BOOLEAN;
    name: ARRAY 256 OF CHAR;
    sig: ARRAY 256 OF CHAR;
    next: Entry
  END;
  Def = POINTER TO DefDesc;
  DefDesc = RECORD
    mod: ARRAY 256 OF CHAR;
    first: Entry;
    next: Def
  END;
  Matches = POINTER TO ARRAY MaxMatch OF Entry;
  Lists = RECORD first, last: ARRAY 6 OF Entry END;

VAR
  T: Texts.Text;
  name: ARRAY 256 OF CHAR;
  plain, modified, running, raw: BOOLEAN;
  cur, top, hcol, goalCol: LONGINT;  (* caret, first line shown, first column shown, column for up/down *)
  rows, cols, height: LONGINT;  (* terminal size, lines of text shown *)
  clip: Texts.Buffer; lastCut: BOOLEAN;  (* what ^C, ^K copied; ^K of lines adds to it *)
  clipBlock: BOOLEAN; blockText: Texts.Text;  (* a copied block: its rows, separated by CR *)
  mods: LONGINT;  (* Shift, Alt, Ctrl with the last key *)
  selOn, block: BOOLEAN;  (* a selection: from anchor to cur, or a block *)
  marking: BOOLEAN;  (* a block started by ^B: the movement keys extend it *)
  anchor: LONGINT;
  aLn, aCol, cCol: LONGINT;  (* a block: the line and column of its anchor, the column of the caret *)
  msg, search: ARRAY 256 OF CHAR;
  terminal: POINTER TO RECORD state: Platform.TerminalState END;
  saved, rawT, timedT: termios.Termios;
  obuf: ARRAY 65536 OF CHAR; opos: LONGINT;
  W: Texts.Writer;
  source: BOOLEAN;
  defs: Def;
  compOn, compAll: BOOLEAN; compFrom: LONGINT; compDef: Def;
  edits, ownEdits: LONGINT; ownDef: Def;
  sR: Texts.Reader; sc: CHAR; sp: LONGINT; seot: BOOLEAN;
  tok: ARRAY 256 OF CHAR; tokKind: INTEGER; tokCh: CHAR; tokPos: LONGINT;
  match: Matches; nMatch, compSel, compTop: LONGINT;
  previousPath: ARRAY 4096 OF CHAR; pathSaved: BOOLEAN;

(* ----- terminal ----- *)

PROCEDURE -Standalone(): BOOLEAN 'VOC_MAIN_PROGRAM';

PROCEDURE Flush;
VAR error: Platform.ErrorCode; offset, written: LONGINT;
BEGIN
  offset := 0;
  WHILE offset < opos DO
    error := Platform.WriteCount(Platform.StdOut, SYSTEM.ADR(obuf[0]) + offset, opos - offset, written);
    IF (error = 0) & (written > 0) THEN INC(offset, written)
    ELSIF ~Platform.Interrupted(error) THEN running := FALSE; opos := 0; RETURN
    END
  END;
  opos := 0
END Flush;

PROCEDURE Ch(c: CHAR);
BEGIN
  IF opos >= LEN(obuf) THEN Flush END;
  obuf[opos] := c; INC(opos)
END Ch;

PROCEDURE Str(s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Ch(s[i]); INC(i) END
END Str;

PROCEDURE Int(n: LONGINT);
VAR a: ARRAY 12 OF CHAR; i: LONGINT;
BEGIN
  IF n < 0 THEN Ch("-"); n := -n END;
  i := 0; REPEAT a[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
  WHILE i > 0 DO DEC(i); Ch(a[i]) END
END Int;

PROCEDURE CSI(s: ARRAY OF CHAR);
BEGIN Ch(ESC); Ch("["); Str(s)
END CSI;

PROCEDURE Goto(row, col: LONGINT);  (* 1-based *)
BEGIN Ch(ESC); Ch("["); Int(row); Ch(";"); Int(col); Ch("H")
END Goto;

PROCEDURE Attr(n: LONGINT);
BEGIN Ch(ESC); Ch("["); Int(n); Ch("m")
END Attr;

PROCEDURE GetSize;
BEGIN
  IF ~termios.WinSize(1, rows, cols) OR (rows < 5) OR (cols < 10) THEN rows := 24; cols := 80 END;
  height := rows - 4;  (* title, message and two help lines *)
  IF height < 1 THEN height := 1 END
END GetSize;

PROCEDURE Restore;
VAR r: Platform.ErrorCode;
BEGIN
  IF pathSaved THEN Files.SetSearchPath(previousPath); pathSaved := FALSE END;
  IF raw THEN
    raw := FALSE;
    running := FALSE; opos := 0;
    Attr(0); CSI("?2004l"); CSI("?1049l"); Flush;  (* no bracketed paste, leave the alternate screen *)
    (* This snapshot outlives the termios objects even during FINALL. *)
    REPEAT r := Platform.RestoreTerminalState(Platform.StdIn, terminal.state)
    UNTIL (r = 0) OR ~Platform.Interrupted(r);
  END;
  IF terminal # NIL THEN Platform.ReleaseTerminalState(terminal.state) END
END Restore;

PROCEDURE Finalize(obj: SYSTEM.PTR);
BEGIN IF obj = SYSTEM.VAL(SYSTEM.PTR, terminal) THEN Restore END
END Finalize;

PROCEDURE Raw(): BOOLEAN;
VAR t: termios.Termios;
BEGIN
  Oberon.OnStop(Restore);
  Heap.Lock;
  IF terminal = NIL THEN NEW(terminal); Heap.RegisterFinalizer(terminal, Finalize) END;
  Heap.Unlock;
  IF termios.Get(0, saved) # 0 THEN RETURN FALSE END;
  Heap.Lock;
  IF Platform.CaptureTerminalState(Platform.StdIn, terminal.state) # 0 THEN Heap.Unlock; RETURN FALSE END;
  t := saved; termios.MakeRaw(t);
  IF termios.Set(0, t) # 0 THEN Platform.ReleaseTerminalState(terminal.state); Heap.Unlock; RETURN FALSE END;
  raw := TRUE; (* Finalization must restore the terminal if allocation below fails. *)
  rawT := t; timedT := t; termios.Timeout(timedT, 1);
  Heap.Unlock;
  CSI("?1049h"); CSI("?2004h"); Flush;  (* the alternate screen (the old contents come back at the end), bracketed paste *)
  RETURN TRUE
END Raw;

PROCEDURE ReadByte(): LONGINT;
VAR c: CHAR; n: LONGINT; error: Platform.ErrorCode;
BEGIN
  REPEAT error := Platform.Read(Platform.StdIn, SYSTEM.ADR(c), 1, n)
  UNTIL ~Platform.Interrupted(error);
  IF (error # 0) OR (n <= 0) THEN RETURN -1 END;
  RETURN ORD(c)
END ReadByte;

(* a key: a character, or KUp .. KDel; escape sequences of xterm and the Linux console *)
PROCEDURE ReadKey(): LONGINT;
VAR c, n, m: LONGINT;
BEGIN
  mods := 0;
  c := ReadByte();
  IF c # ORD(ESC) THEN RETURN c END;
  n := termios.Set(0, timedT); c := ReadByte(); n := termios.Set(0, rawT);
  IF c < 0 THEN RETURN KEsc END;
  IF c = ORD("O") THEN
    c := ReadByte();
    IF c = ORD("A") THEN RETURN KUp ELSIF c = ORD("B") THEN RETURN KDown
    ELSIF c = ORD("C") THEN RETURN KRight ELSIF c = ORD("D") THEN RETURN KLeft
    ELSIF c = ORD("H") THEN RETURN KHome ELSIF c = ORD("F") THEN RETURN KEnd
    END;
    RETURN KNone
  ELSIF c = ORD("[") THEN
    n := 0; c := ReadByte();
    WHILE (c >= ORD("0")) & (c <= ORD("9")) DO n := n * 10 + c - ORD("0"); c := ReadByte() END;
    WHILE c = ORD(";") DO  (* xterm modifiers: 1 + Shift 1, Alt 2, Ctrl 4 *)
      m := 0; c := ReadByte(); WHILE (c >= ORD("0")) & (c <= ORD("9")) DO m := m * 10 + c - ORD("0"); c := ReadByte() END;
      IF m > 1 THEN mods := m - 1 END
    END;
    IF c = ORD("A") THEN RETURN KUp ELSIF c = ORD("B") THEN RETURN KDown
    ELSIF c = ORD("C") THEN RETURN KRight ELSIF c = ORD("D") THEN RETURN KLeft
    ELSIF c = ORD("H") THEN RETURN KHome ELSIF c = ORD("F") THEN RETURN KEnd
    ELSIF c = ORD("~") THEN
      IF (n = 1) OR (n = 7) THEN RETURN KHome ELSIF (n = 4) OR (n = 8) THEN RETURN KEnd
      ELSIF n = 3 THEN RETURN KDel ELSIF n = 5 THEN RETURN KPgUp ELSIF n = 6 THEN RETURN KPgDn
      ELSIF n = 200 THEN RETURN KPaste
      END
    END;
    RETURN KNone
  END;
  RETURN KNone  (* Meta keys are not used *)
END ReadKey;

(* ----- text ----- *)

PROCEDURE CharAt(pos: LONGINT): CHAR;
VAR R: Texts.Reader; c: CHAR;
BEGIN
  IF (pos < 0) OR (pos >= T.len) THEN RETURN 0X END;
  Texts.OpenReader(R, T, pos); Texts.Read(R, c); RETURN c
END CharAt;

PROCEDURE IsEol(c: CHAR): BOOLEAN;
BEGIN RETURN (c = CR) OR (c = LF)
END IsEol;

PROCEDURE LineStart(pos: LONGINT): LONGINT;
BEGIN
  WHILE (pos > 0) & ~IsEol(CharAt(pos - 1)) DO DEC(pos) END;
  RETURN pos
END LineStart;

PROCEDURE LineEnd(pos: LONGINT): LONGINT;  (* position of the line end, or T.len *)
VAR R: Texts.Reader; c: CHAR;
BEGIN
  IF pos >= T.len THEN RETURN T.len END;
  Texts.OpenReader(R, T, pos); Texts.Read(R, c);
  WHILE ~R.eot & ~IsEol(c) DO INC(pos); Texts.Read(R, c) END;
  RETURN pos
END LineEnd;

PROCEDURE NextLine(pos: LONGINT): LONGINT;  (* start of the next line, or -1 *)
BEGIN
  pos := LineEnd(pos);
  IF pos >= T.len THEN RETURN -1 END;
  RETURN pos + 1
END NextLine;

PROCEDURE Cont(c: CHAR): BOOLEAN;  (* a UTF-8 continuation byte, no column of its own *)
BEGIN RETURN (ORD(c) >= 80H) & (ORD(c) < 0C0H)
END Cont;

PROCEDURE NextPos(pos: LONGINT): LONGINT;
BEGIN
  IF pos < T.len THEN INC(pos) END;
  WHILE (pos < T.len) & Cont(CharAt(pos)) DO INC(pos) END;
  RETURN pos
END NextPos;

PROCEDURE PrevPos(pos: LONGINT): LONGINT;
BEGIN
  IF pos > 0 THEN DEC(pos) END;
  WHILE (pos > 0) & Cont(CharAt(pos)) DO DEC(pos) END;
  RETURN pos
END PrevPos;

(* the screen column of pos in its line; tabs every 8 columns *)
PROCEDURE Col(pos: LONGINT): LONGINT;
VAR R: Texts.Reader; p, col: LONGINT; c: CHAR;
BEGIN
  p := LineStart(pos); col := 0;
  IF p < pos THEN
    Texts.OpenReader(R, T, p);
    WHILE p < pos DO
      Texts.Read(R, c);
      IF c = TAB THEN col := col + 8 - col MOD 8 ELSIF ~Cont(c) THEN INC(col) END;
      INC(p)
    END
  END;
  RETURN col
END Col;

(* the position in the line starting at ls nearest to column col *)
PROCEDURE PosAtCol(ls, col: LONGINT): LONGINT;
VAR R: Texts.Reader; p, c0, w: LONGINT; c: CHAR;
BEGIN
  p := ls; c0 := 0;
  IF p >= T.len THEN RETURN T.len END;
  Texts.OpenReader(R, T, p); Texts.Read(R, c);
  WHILE ~R.eot & ~IsEol(c) DO
    IF c = TAB THEN w := 8 - c0 MOD 8 ELSIF Cont(c) THEN w := 0 ELSE w := 1 END;
    IF (w > 0) & (c0 + w > col) THEN RETURN p END;
    c0 := c0 + w; INC(p); Texts.Read(R, c)
  END;
  RETURN p
END PosAtCol;

PROCEDURE LineNo(pos: LONGINT): LONGINT;  (* 1-based *)
VAR R: Texts.Reader; p, n: LONGINT; c: CHAR;
BEGIN
  n := 1; p := 0; Texts.OpenReader(R, T, 0);
  WHILE p < pos DO Texts.Read(R, c); IF IsEol(c) THEN INC(n) END; INC(p) END;
  RETURN n
END LineNo;

PROCEDURE Newline(): CHAR;  (* line end of this text: LF in plain files, CR in Oberon texts *)
BEGIN
  IF plain THEN RETURN LF ELSE RETURN CR END
END Newline;

(* W writes in the looks of the character before pos *)
PROCEDURE LooksAt(pos: LONGINT);
VAR R: Texts.Reader; ch: CHAR;
BEGIN
  IF pos > 0 THEN Texts.OpenReader(R, T, pos - 1) ELSE Texts.OpenReader(R, T, 0) END;
  Texts.Read(R, ch);
  IF (T.len = 0) OR R.eot THEN R.col := 15; R.voff := 0 END;
  IF R.fnt # NIL THEN Texts.SetFont(W, R.fnt) END;
  Texts.SetColor(W, R.col); Texts.SetOffset(W, R.voff)
END LooksAt;

(* insert c at pos, in the looks of the character before *)
PROCEDURE InsertAt(pos: LONGINT; c: CHAR);
BEGIN
  LooksAt(pos); Texts.Write(W, c); Texts.Insert(T, pos, W.buf); modified := TRUE; INC(edits)
END InsertAt;

(* insert c at the caret *)
PROCEDURE Insert(c: CHAR);
BEGIN
  InsertAt(cur, c); INC(cur)
END Insert;

PROCEDURE Delete(beg, end: LONGINT);
BEGIN
  IF end > beg THEN Texts.Delete(T, beg, end); modified := TRUE; INC(edits) END
END Delete;

(* ----- selection ----- *)

PROCEDURE LineStartNo(n: LONGINT): LONGINT;  (* the start of line n (1-based), -1 beyond the end *)
VAR p: LONGINT;
BEGIN
  p := 0;
  WHILE (n > 1) & (p >= 0) DO p := NextLine(p); DEC(n) END;
  RETURN p
END LineStartNo;

PROCEDURE SelRange(VAR b, e: LONGINT);  (* the selected stretch *)
BEGIN
  IF anchor < cur THEN b := anchor; e := cur ELSE b := cur; e := anchor END
END SelRange;

(* the block: its first and last line (numbers), its columns l (included) to r (excluded) *)
PROCEDURE BlockArea(VAR first, last, l, r: LONGINT);
VAR cl: LONGINT;
BEGIN
  cl := LineNo(cur);
  IF aLn <= cl THEN first := aLn; last := cl ELSE first := cl; last := aLn END;
  IF aCol <= cCol THEN l := aCol; r := cCol ELSE l := cCol; r := aCol END
END BlockArea;

PROCEDURE EndCol(ls: LONGINT): LONGINT;  (* the column of the end of the line starting at ls *)
BEGIN RETURN Col(LineEnd(ls))
END EndCol;

(* start a stretch (Shift) or a block (Alt+Shift) at the caret, unless one of that kind is there *)
PROCEDURE StartSel(blk: BOOLEAN);
BEGIN
  IF ~selOn OR (block # blk) THEN
    selOn := TRUE; block := blk; anchor := cur;
    aLn := LineNo(cur); IF goalCol >= 0 THEN aCol := goalCol ELSE aCol := Col(cur) END; cCol := aCol
  END
END StartSel;

PROCEDURE ClearSel;
BEGIN selOn := FALSE; block := FALSE; marking := FALSE
END ClearSel;

(* the block of the caret's line moves to column c: cur follows it *)
PROCEDURE BlockCaret(c: LONGINT);
BEGIN
  IF c < 0 THEN c := 0 END;
  cCol := c; cur := PosAtCol(LineStart(cur), c)
END BlockCaret;

(* ----- the terminal's clipboard (OSC 52) ----- *)

PROCEDURE B64(v: LONGINT): CHAR;
BEGIN
  IF v < 26 THEN RETURN CHR(ORD("A") + v) ELSIF v < 52 THEN RETURN CHR(ORD("a") + v - 26)
  ELSIF v < 62 THEN RETURN CHR(ORD("0") + v - 52) ELSIF v = 62 THEN RETURN "+" ELSE RETURN "/"
  END
END B64;

(* the characters of t from beg to end, line ends as LF, to the terminal's clipboard *)
PROCEDURE ToTerminal(t: Texts.Text; beg, end: LONGINT);
VAR R: Texts.Reader; c: CHAR; acc, n, v: LONGINT;
BEGIN
  IF end - beg > 100000 THEN RETURN END;  (* terminals take little *)
  Ch(ESC); Str("]52;c;");
  Texts.OpenReader(R, t, beg); acc := 0; n := 0;
  WHILE beg < end DO
    Texts.Read(R, c); IF c = CR THEN c := LF END;
    acc := acc * 256 + ORD(c); INC(n);
    IF n = 3 THEN
      Ch(B64(acc DIV 40000H)); Ch(B64(acc DIV 1000H MOD 64)); Ch(B64(acc DIV 40H MOD 64)); Ch(B64(acc MOD 64));
      acc := 0; n := 0
    END;
    INC(beg)
  END;
  IF n = 1 THEN v := acc * 10000H; Ch(B64(v DIV 40000H)); Ch(B64(v DIV 1000H MOD 64)); Str("==")
  ELSIF n = 2 THEN v := acc * 100H; Ch(B64(v DIV 40000H)); Ch(B64(v DIV 1000H MOD 64)); Ch(B64(v DIV 40H MOD 64)); Ch("=")
  END;
  Ch(7X); Flush
END ToTerminal;

(* ----- copy, cut, paste ----- *)

(* the selection into the clipboard (and the terminal's) *)
PROCEDURE CopySel;
VAR b, e, first, last, l, r, ls, ln: LONGINT; buf: Texts.Buffer;
BEGIN
  NEW(clip); Texts.OpenBuf(clip);
  IF block THEN
    BlockArea(first, last, l, r);
    NEW(blockText); Texts.Open(blockText, "");
    ls := LineStartNo(first); ln := first;
    WHILE (ln <= last) & (ls >= 0) DO
      b := PosAtCol(ls, l); e := PosAtCol(ls, r);
      IF e > b THEN NEW(buf); Texts.OpenBuf(buf); Texts.Save(T, b, e, buf); Texts.Append(blockText, buf) END;
      IF ln < last THEN Texts.Write(W, CR); Texts.Append(blockText, W.buf) END;
      ls := NextLine(ls); INC(ln)
    END;
    clipBlock := TRUE; marking := FALSE; ToTerminal(blockText, 0, blockText.len)
  ELSE
    SelRange(b, e); Texts.Save(T, b, e, clip); clipBlock := FALSE; ToTerminal(T, b, e)
  END
END CopySel;

(* delete the block's columns on its lines; it keeps width 0 at its left column *)
PROCEDURE DeleteBlock;
VAR first, last, l, r, ls, ln, cl: LONGINT;
BEGIN
  BlockArea(first, last, l, r); cl := LineNo(cur);
  ls := LineStartNo(first); ln := first;
  WHILE (ln <= last) & (ls >= 0) DO
    Delete(PosAtCol(ls, l), PosAtCol(ls, r));
    ls := NextLine(ls); INC(ln)
  END;
  aCol := l; cur := LineStartNo(cl); BlockCaret(l); marking := FALSE
END DeleteBlock;

(* delete the selection *)
PROCEDURE DeleteSel;
VAR b, e: LONGINT;
BEGIN
  IF block THEN DeleteBlock
  ELSE SelRange(b, e); Delete(b, e); cur := b; ClearSel
  END
END DeleteSel;

(* type c into every line of the block that reaches its column, after deleting its columns *)
PROCEDURE BlockType(c: CHAR);
VAR first, last, l, r, ls, ln, cl: LONGINT;
BEGIN
  IF aCol # cCol THEN DeleteBlock END;
  BlockArea(first, last, l, r); cl := LineNo(cur);
  ls := LineStartNo(first); ln := first;
  WHILE (ln <= last) & (ls >= 0) DO
    IF EndCol(ls) >= l THEN InsertAt(PosAtCol(ls, l), c) END;
    ls := NextLine(ls); INC(ln)
  END;
  cur := LineStartNo(cl); cur := NextPos(PosAtCol(cur, l));
  aCol := Col(cur); cCol := aCol; marking := FALSE
END BlockType;

(* Backspace (back) or Delete in a block of width 0: the character before or at its column, in
   every line that has one *)
PROCEDURE BlockErase(back: BOOLEAN);
VAR first, last, l, r, ls, ln, cl, p: LONGINT;
BEGIN
  BlockArea(first, last, l, r); cl := LineNo(cur);
  IF back & (l = 0) THEN RETURN END;
  ls := LineStartNo(first); ln := first;
  WHILE (ln <= last) & (ls >= 0) DO
    IF back & (EndCol(ls) >= l) THEN p := PosAtCol(ls, l - 1); Delete(p, NextPos(p))
    ELSIF ~back & (EndCol(ls) > l) THEN p := PosAtCol(ls, l); Delete(p, NextPos(p))
    END;
    ls := NextLine(ls); INC(ln)
  END;
  cur := LineStartNo(cl);
  IF back THEN cur := PosAtCol(cur, l - 1) ELSE cur := PosAtCol(cur, l) END;
  aCol := Col(cur); cCol := aCol; marking := FALSE
END BlockErase;

(* the clipboard at the caret; a block goes into the following lines at the caret's column,
   lines are lengthened with blanks and added at the end as needed *)
PROCEDURE Paste;
VAR buf: Texts.Buffer; R: Texts.Reader; c: CHAR; col, ln, ls, p, n, rowEnd: LONGINT;
BEGIN
  IF selOn THEN DeleteSel END;
  IF clip = NIL THEN RETURN END;
  IF clipBlock THEN
    col := Col(cur); ln := LineNo(cur); p := 0;
    WHILE p <= blockText.len DO
      rowEnd := p; Texts.OpenReader(R, blockText, p); Texts.Read(R, c);
      WHILE ~R.eot & (c # CR) DO INC(rowEnd); Texts.Read(R, c) END;
      ls := LineStartNo(ln);
      IF ls < 0 THEN InsertAt(T.len, Newline()); ls := LineStartNo(ln) END;
      WHILE EndCol(ls) < col DO InsertAt(LineEnd(ls), " ") END;
      IF rowEnd > p THEN
        NEW(buf); Texts.OpenBuf(buf); Texts.Save(blockText, p, rowEnd, buf);
        Texts.Insert(T, PosAtCol(ls, col), buf); modified := TRUE; INC(edits)
      END;
      p := rowEnd + 1; INC(ln)
    END;
    cur := PosAtCol(LineStartNo(LineNo(cur)), col)
  ELSE
    NEW(buf); Texts.OpenBuf(buf); Texts.Copy(clip, buf);
    n := buf.len; Texts.Insert(T, cur, buf); cur := cur + n; modified := TRUE; INC(edits)
  END
END Paste;

(* a paste of the terminal (bracketed: up to ESC [ 201 ~), inserted as it is; CR LF, CR and LF
   are line ends *)
PROCEDURE TerminalPaste;
VAR c, st, n, i: LONGINT; pending: BOOLEAN; endSeq: ARRAY 8 OF CHAR;

  PROCEDURE Put(c: LONGINT);
  BEGIN
    IF c = 0DH THEN Texts.Write(W, Newline()); INC(n); pending := TRUE
    ELSIF (c = 0AH) & pending THEN pending := FALSE  (* the LF of CR LF *)
    ELSIF c = 0AH THEN Texts.Write(W, Newline()); INC(n)
    ELSE Texts.Write(W, CHR(c)); INC(n); pending := FALSE
    END
  END Put;

BEGIN
  IF selOn THEN DeleteSel END;
  endSeq[0] := ESC; endSeq[1] := "["; endSeq[2] := "2"; endSeq[3] := "0"; endSeq[4] := "1"; endSeq[5] := "~";
  LooksAt(cur); n := 0; st := 0; pending := FALSE;
  LOOP
    c := ReadByte();
    IF c < 0 THEN EXIT END;
    IF c = ORD(endSeq[st]) THEN
      INC(st); IF st = 6 THEN EXIT END
    ELSE  (* not the end: what matched so far is text *)
      i := 0; WHILE i < st DO Put(ORD(endSeq[i])); INC(i) END;
      IF c = 1BH THEN st := 1 ELSE st := 0; Put(c) END
    END
  END;
  IF n > 0 THEN Texts.Insert(T, cur, W.buf); cur := cur + n; modified := TRUE; INC(edits) END
END TerminalPaste;

(* ----- words ----- *)

PROCEDURE IsWord(c: CHAR): BOOLEAN;
BEGIN RETURN (c >= "0") & (c <= "9") OR (CAP(c) >= "A") & (CAP(c) <= "Z") OR (c = "_") OR (ORD(c) >= 80H)
END IsWord;

PROCEDURE WordRight(pos: LONGINT): LONGINT;
BEGIN
  WHILE (pos < T.len) & ~IsWord(CharAt(pos)) DO INC(pos) END;
  WHILE (pos < T.len) & IsWord(CharAt(pos)) DO INC(pos) END;
  RETURN pos
END WordRight;

PROCEDURE WordLeft(pos: LONGINT): LONGINT;
BEGIN
  WHILE (pos > 0) & ~IsWord(CharAt(pos - 1)) DO DEC(pos) END;
  WHILE (pos > 0) & IsWord(CharAt(pos - 1)) DO DEC(pos) END;
  RETURN pos
END WordLeft;

(* ----- screen ----- *)

(* terminal attributes for the looks of R: colours, bold and italic fonts (Oberon texts) *)
PROCEDURE Looks(VAR R: Texts.Reader);
VAR i: LONGINT; bold, italic: BOOLEAN;
BEGIN
  Attr(0); bold := FALSE; italic := FALSE;
  IF R.fnt # NIL THEN
    i := 0;
    WHILE (R.fnt.name[i] # 0X) & ((R.fnt.name[i] < "0") OR (R.fnt.name[i] > "9")) DO INC(i) END;
    WHILE (R.fnt.name[i] >= "0") & (R.fnt.name[i] <= "9") DO INC(i) END;
    WHILE (R.fnt.name[i] # 0X) & (R.fnt.name[i] # ".") DO
      IF CAP(R.fnt.name[i]) = "B" THEN bold := TRUE ELSIF CAP(R.fnt.name[i]) = "I" THEN italic := TRUE END;
      INC(i)
    END
  END;
  IF bold THEN Attr(1) END;
  IF italic THEN Attr(3) END;
  IF R.col = 1 THEN Attr(31) ELSIF R.col = 2 THEN Attr(32)
  ELSIF R.col = 3 THEN Attr(33) ELSIF R.col = 4 THEN Attr(34)
  ELSIF R.col = 5 THEN Attr(35) ELSIF R.col = 6 THEN Attr(36)
  END
END Looks;

(* the line starting at pos; positions hb..he are selected (reverse), eolSel: its line end too, ucol:
   the column of a block of width 0 (underlined), or -1 *)
PROCEDURE DrawLine(pos, hb, he: LONGINT; eolSel: BOOLEAN; ucol: LONGINT);
VAR R: Texts.Reader; c: CHAR; col, n, p: LONGINT; show, sel, under, curSel, curUnder: BOOLEAN; lib: Texts.FontsFont; lcol: SHORTINT;

  PROCEDURE Set;  (* the attributes for sel, under and the looks of R *)
  BEGIN
    IF (sel # curSel) OR (under # curUnder) OR ~plain & ((R.fnt # lib) OR (R.col # lcol)) THEN
      Attr(0); IF ~plain THEN lib := R.fnt; lcol := R.col; Looks(R) END;
      IF sel THEN Attr(7) END;
      IF under THEN Attr(4) END;
      curSel := sel; curUnder := under
    END
  END Set;

BEGIN
  col := 0; show := FALSE; lib := NIL; lcol := 15; p := pos; curSel := FALSE; curUnder := FALSE;
  IF pos < T.len THEN
    Texts.OpenReader(R, T, pos); Texts.Read(R, c);
    WHILE ~R.eot & ~IsEol(c) & (col < hcol + cols) DO
      sel := (p >= hb) & (p < he); under := (col = ucol) & ~Cont(c);
      IF ~Cont(c) THEN Set END;
      IF R.elem # NIL THEN  (* an object *)
        IF col >= hcol THEN Ch("?") END; INC(col)
      ELSIF c = TAB THEN
        n := 8 - col MOD 8;
        WHILE n > 0 DO IF (col >= hcol) & (col < hcol + cols) THEN Ch(" ") END; INC(col); DEC(n) END
      ELSIF Cont(c) THEN
        IF show THEN Ch(c) END
      ELSIF c < " " THEN
        show := FALSE; IF col >= hcol THEN Ch("?") END; INC(col)
      ELSE
        show := (col >= hcol) & (col < hcol + cols);
        IF show THEN Ch(c) END;
        INC(col)
      END;
      Texts.Read(R, c); INC(p)
    END
  END;
  IF (eolSel OR (ucol = col)) & (col >= hcol) & (col < hcol + cols) THEN  (* the line end *)
    Attr(0); IF eolSel THEN Attr(7) ELSE Attr(4) END; Ch(" ")
  END;
  Attr(0); CSI("K")
END DrawLine;

PROCEDURE Append(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE (t[j] # 0X) & (i < LEN(s) - 1) DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Append;

PROCEDURE Help(k, label: ARRAY OF CHAR);
BEGIN Attr(7); Str(k); Attr(0); Ch(" "); Str(label); Str("  ")
END Help;

PROCEDURE Ends(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR): BOOLEAN;
VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE t[j] # 0X DO INC(j) END;
  IF j > i THEN RETURN FALSE END;
  WHILE (j > 0) & (s[i-1] = t[j-1]) DO DEC(i); DEC(j) END;
  RETURN j = 0
END Ends;

(* ----- completion in Oberon sources ----- *)

PROCEDURE ParseDef(d: Def; text: Texts.Text);
VAR R: Texts.Reader; c: CHAR; i, j, indent, section: LONGINT;
  line: ARRAY 1024 OF CHAR; name: ARRAY 256 OF CHAR;
  first, last: ARRAY 4 OF Entry; x: Entry; k: INTEGER;

  PROCEDURE Add(kind: CHAR; from: LONGINT);
  VAR x: Entry; n: LONGINT; k: INTEGER;
  BEGIN
    NEW(x); x.kind := kind; COPY(name, x.name); n := 0;
    WHILE (line[from] # 0X) & (n < LEN(x.sig) - 1) DO x.sig[n] := line[from]; INC(n); INC(from) END;
    WHILE (n > 0) & (x.sig[n-1] = ";") DO DEC(n) END;
    x.sig[n] := 0X; x.params := (x.sig[0] = "(") & (x.sig[1] # ")"); x.next := NIL;
    IF kind = "p" THEN k := 0 ELSIF kind = "v" THEN k := 1 ELSIF kind = "c" THEN k := 2 ELSE k := 3 END;
    IF first[k] = NIL THEN first[k] := x ELSE last[k].next := x END;
    last[k] := x
  END Add;

  PROCEDURE Word(VAR i: LONGINT);
  VAR n: LONGINT;
  BEGIN
    n := 0;
    WHILE IsWord(line[i]) DO IF n < LEN(name) - 1 THEN name[n] := line[i]; INC(n) END; INC(i) END;
    name[n] := 0X
  END Word;

BEGIN
  k := 0; WHILE k < 4 DO first[k] := NIL; last[k] := NIL; INC(k) END;
  section := 0; Texts.OpenReader(R, text, 0); Texts.Read(R, c);
  WHILE ~R.eot DO
    i := 0;
    WHILE ~R.eot & ~IsEol(c) DO
      IF i < LEN(line) - 1 THEN line[i] := c; INC(i) END;
      Texts.Read(R, c)
    END;
    line[i] := 0X;
    IF ~R.eot THEN Texts.Read(R, c) END;
    indent := 0; WHILE line[indent] = " " DO INC(indent) END;
    i := indent; Word(i);
    IF indent = 2 THEN
      IF name = "CONST" THEN section := 1
      ELSIF name = "TYPE" THEN section := 2
      ELSIF name = "VAR" THEN section := 3
      ELSIF name = "PROCEDURE" THEN
        section := 0;
        WHILE (line[i] = " ") OR (line[i] = "+") OR (line[i] = "-") DO INC(i) END;
        Word(i); IF name # "" THEN Add("p", i) END
      END
    ELSIF (indent = 4) & (name # "") & (name # "END") THEN
      IF line[i] = "-" THEN INC(i) END;
      j := i; WHILE line[j] = " " DO INC(j) END;
      IF (section = 1) & (line[j] = "=") THEN Add("c", i)
      ELSIF (section = 2) & (line[j] = "=") THEN Add("t", i)
      ELSIF (section = 3) & (line[j] = ":") THEN Add("v", i)
      END
    END
  END;
  d.first := NIL; x := NIL; k := 0;
  WHILE k < 4 DO
    IF first[k] # NIL THEN
      IF x = NIL THEN d.first := first[k] ELSE x.next := first[k] END;
      x := last[k]
    END;
    INC(k)
  END
END ParseDef;

PROCEDURE Directories(s: ARRAY OF CHAR; VAR path: ARRAY OF CHAR): BOOLEAN;
VAR i, n: LONGINT;
BEGIN
  IF s = "" THEN RETURN TRUE END;
  n := Strings.Length(path); i := 0;
  IF n + Strings.Length(s) + 1 >= LEN(path) THEN RETURN FALSE END;
  path[n] := ";"; INC(n);
  WHILE s[i] # 0X DO
    IF s[i] = ":" THEN path[n] := ";" ELSE path[n] := s[i] END;
    INC(i); INC(n)
  END;
  path[n] := 0X; RETURN TRUE
END Directories;

PROCEDURE ReadDef(VAR mod: ARRAY OF CHAR): Def;
VAR d: Def; text: Texts.Text; path, extra: ARRAY 4096 OF CHAR; module: OPS.Name; i: LONGINT; valid: BOOLEAN;
BEGIN
  d := defs; WHILE (d # NIL) & (d.mod # mod) DO d := d.next END;
  IF d = NIL THEN
    NEW(d); COPY(mod, d.mod); d.first := NIL; d.next := defs; defs := d;
    IF ~Files.GetSearchPath(previousPath) THEN RETURN d END;
    path := "."; COPY(name, extra); i := Strings.Length(extra) - 1;
    WHILE (i >= 0) & (extra[i] # "/") DO DEC(i) END;
    IF i >= 0 THEN
      IF i = 0 THEN extra := "/" ELSE extra[i] := 0X END;
      valid := Directories(extra, path)
    ELSE valid := TRUE
    END;
    NonePaths.Get(extra); valid := Directories(extra, path) & valid;
    Platform.GetEnv("VOC_SYM_PATH", extra); valid := Directories(extra, path) & valid;
    Platform.GetEnv("VOC_MODULE_PATH", extra); valid := Directories(extra, path) & valid;
    Platform.GetEnv("OBERON", extra); valid := Directories(extra, path) & valid;
    Platform.GetEnv("MODULES", extra); valid := Directories(extra, path) & valid;
    valid := Directories(previousPath, path) & valid;
    COPY(OPM.InstallDir, extra); Strings.Append("/modular/2/sym", extra);
    valid := Directories(extra, path) & valid;
    COPY(OPM.InstallDir, extra); Strings.Append("/2/sym", extra);
    valid := Directories(extra, path) & valid;
    IF ~valid THEN msg := "Symbol search path is too long"; RETURN d END;
    pathSaved := TRUE; Files.SetSearchPath(path);
    NEW(text); Texts.Open(text, ""); COPY(mod, module); BrowserCmd.Definition(module, 0X, text);
    Files.SetSearchPath(previousPath); pathSaved := FALSE;
    ParseDef(d, text)
  END;
  RETURN d
END ReadDef;

PROCEDURE Imported(VAR id, mod: ARRAY OF CHAR): BOOLEAN;
VAR R: Texts.Reader; c: CHAR; w, a: ARRAY 256 OF CHAR; n, depth: LONGINT; inImport, assign: BOOLEAN;
BEGIN
  Texts.OpenReader(R, T, 0); Texts.Read(R, c); inImport := FALSE; assign := FALSE; a[0] := 0X;
  LOOP
    IF R.eot THEN RETURN FALSE END;
    IF c = "(" THEN
      Texts.Read(R, c);
      IF c = "*" THEN
        depth := 1; Texts.Read(R, c);
        WHILE ~R.eot & (depth > 0) DO
          IF c = "(" THEN Texts.Read(R, c); IF c = "*" THEN INC(depth); Texts.Read(R, c) END
          ELSIF c = "*" THEN Texts.Read(R, c); IF c = ")" THEN DEC(depth); Texts.Read(R, c) END
          ELSE Texts.Read(R, c)
          END
        END
      END
    ELSIF IsWord(c) THEN
      n := 0;
      WHILE ~R.eot & IsWord(c) DO IF n < LEN(w) - 1 THEN w[n] := c; INC(n) END; Texts.Read(R, c) END;
      w[n] := 0X;
      IF ~inImport THEN
        IF w = "IMPORT" THEN inImport := TRUE
        ELSIF (w = "CONST") OR (w = "TYPE") OR (w = "VAR") OR (w = "PROCEDURE") OR (w = "BEGIN") THEN RETURN FALSE
        END
      ELSIF assign THEN
        IF a = id THEN COPY(w, mod); RETURN TRUE END;
        assign := FALSE; a[0] := 0X
      ELSE COPY(w, a)
      END
    ELSIF c = ":" THEN
      Texts.Read(R, c); IF inImport & (c = "=") THEN assign := TRUE; Texts.Read(R, c) END
    ELSIF (c = ",") OR (c = ";") THEN
      IF inImport & ~assign & (a[0] # 0X) & (a = id) THEN COPY(a, mod); RETURN TRUE END;
      IF inImport & (c = ";") THEN RETURN FALSE END;
      a[0] := 0X; assign := FALSE; Texts.Read(R, c)
    ELSE Texts.Read(R, c)
    END
  END
END Imported;

PROCEDURE WordBefore(pos: LONGINT; VAR w: ARRAY OF CHAR; VAR start: LONGINT);
VAR n: LONGINT;
BEGIN
  start := pos; WHILE (start > 0) & IsWord(CharAt(start - 1)) DO DEC(start) END;
  n := 0; WHILE (start + n < pos) & (n < LEN(w) - 1) DO w[n] := CharAt(start + n); INC(n) END;
  w[n] := 0X
END WordBefore;

(* ----- the names of the text itself ----- *)

PROCEDURE SAdv;
BEGIN INC(sp); Texts.Read(sR, sc); seot := sR.eot
END SAdv;

PROCEDURE SOpen;
BEGIN Texts.OpenReader(sR, T, 0); sp := -1; SAdv
END SOpen;

(* Token kinds: end, name, punctuation, number or string. Nested comments are skipped. *)
PROCEDURE SNext;
VAR n, depth: LONGINT; q, prev: CHAR;
BEGIN
  LOOP
    WHILE ~seot & (sc <= " ") DO SAdv END;
    tokPos := sp;
    IF seot THEN tokKind := 0; RETURN END;
    IF IsWord(sc) THEN
      n := 0;
      WHILE ~seot & IsWord(sc) DO IF n < LEN(tok) - 1 THEN tok[n] := sc; INC(n) END; SAdv END;
      tok[n] := 0X;
      IF (tok[0] >= "0") & (tok[0] <= "9") THEN tokKind := 3 ELSE tokKind := 1 END;
      RETURN
    ELSIF (sc = 22X) OR (sc = "'") THEN
      q := sc; SAdv; WHILE ~seot & (sc # q) DO SAdv END;
      IF ~seot THEN SAdv END;
      tokKind := 3; RETURN
    ELSIF sc = "(" THEN
      SAdv;
      IF seot OR (sc # "*") THEN tokKind := 2; tokCh := "("; RETURN END;
      depth := 1; SAdv; prev := 0X;
      WHILE ~seot & (depth > 0) DO
        IF (prev = "(") & (sc = "*") THEN INC(depth); prev := 0X
        ELSIF (prev = "*") & (sc = ")") THEN DEC(depth); prev := 0X
        ELSE prev := sc
        END;
        SAdv
      END
    ELSE
      tokKind := 2; tokCh := sc; SAdv; RETURN
    END
  END
END SNext;

PROCEDURE TextOf(beg, end: LONGINT; VAR s: ARRAY OF CHAR; oneLine: BOOLEAN);
VAR R: Texts.Reader; c: CHAR; n: LONGINT; blank: BOOLEAN;
BEGIN
  Texts.OpenReader(R, T, beg); n := 0; blank := FALSE;
  WHILE (beg < end) & (n < LEN(s) - 1) DO
    Texts.Read(R, c); INC(beg);
    IF IsEol(c) & oneLine THEN beg := end
    ELSIF (c = " ") OR (c = TAB) OR IsEol(c) THEN
      IF ~blank & (n > 0) THEN s[n] := " "; INC(n) END;
      blank := TRUE
    ELSE s[n] := c; INC(n); blank := FALSE
    END
  END;
  WHILE (n > 0) & (s[n-1] = " ") DO DEC(n) END;
  s[n] := 0X
END TextOf;

PROCEDURE NewEntry(kind: CHAR; VAR name, sig: ARRAY OF CHAR): Entry;
VAR x: Entry;
BEGIN
  NEW(x); x.kind := kind; COPY(name, x.name); COPY(sig, x.sig);
  x.params := (x.sig[0] = "(") & (x.sig[1] # ")"); x.next := NIL;
  RETURN x
END NewEntry;

PROCEDURE KindNo(kind: CHAR): INTEGER;
BEGIN
  IF kind = "p" THEN RETURN 0 ELSIF kind = "v" THEN RETURN 1 ELSIF kind = "c" THEN RETURN 2
  ELSIF kind = "t" THEN RETURN 3 ELSIF kind = "m" THEN RETURN 4 ELSE RETURN 5
  END
END KindNo;

PROCEDURE Put(VAR L: Lists; x: Entry);
VAR k: INTEGER;
BEGIN
  k := KindNo(x.kind);
  IF L.first[k] = NIL THEN L.first[k] := x ELSE L.last[k].next := x END;
  L.last[k] := x
END Put;

PROCEDURE Has(VAR L: Lists; kind: CHAR; VAR name: ARRAY OF CHAR): BOOLEAN;
VAR x: Entry;
BEGIN
  x := L.first[KindNo(kind)]; WHILE (x # NIL) & (x.name # name) DO x := x.next END;
  RETURN x # NIL
END Has;

PROCEDURE Std(VAR L: Lists; name, sig: ARRAY OF CHAR);
BEGIN Put(L, NewEntry("s", name, sig))
END Std;

PROCEDURE SectionEnd(VAR s: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN (s = "BEGIN") OR (s = "PROCEDURE") OR (s = "END") OR (s = "VAR") OR (s = "CONST") OR (s = "TYPE")
    OR (s = "IMPORT")
END SectionEnd;

(* the token starts the next declaration or a body, so a declaration before it is not finished: BEGIN,
   END, CONST, TYPE, IMPORT, VAR (where depth = 0) or PROCEDURE and a name (not a procedure type) *)
PROCEDURE NextDecl(depth: LONGINT): BOOLEAN;
VAR R: Texts.Reader; c: CHAR; p, pos: LONGINT; eot: BOOLEAN; t: ARRAY 32 OF CHAR; kind: INTEGER; ch: CHAR;
  name: BOOLEAN;
BEGIN
  IF tokKind # 1 THEN RETURN FALSE END;
  IF (tok = "BEGIN") OR (tok = "END") OR (tok = "CONST") OR (tok = "TYPE") OR (tok = "IMPORT") THEN RETURN TRUE END;
  IF tok = "VAR" THEN RETURN depth = 0 END;
  IF tok # "PROCEDURE" THEN RETURN FALSE END;
  R := sR; c := sc; p := sp; eot := seot; COPY(tok, t); kind := tokKind; ch := tokCh; pos := tokPos;
  SNext;
  WHILE (tokKind = 2) & ((tokCh = "^") OR (tokCh = "*") OR (tokCh = "-") OR (tokCh = "+") OR (tokCh = "&")) DO SNext END;
  name := tokKind = 1;
  sR := R; sc := c; sp := p; seot := eot; COPY(t, tok); tokKind := kind; tokCh := ch; tokPos := pos;
  RETURN name
END NextDecl;

PROCEDURE OwnDef(): Def;
VAR d: Def; L: Lists; k: INTEGER; x: Entry; kind: CHAR; names: ARRAY 16 OF ARRAY 256 OF CHAR;
  nn, i, from, pdepth, rdepth: LONGINT; name: ARRAY 256 OF CHAR; sig, val: ARRAY 256 OF CHAR;
BEGIN
  IF (ownDef # NIL) & (ownEdits = edits) THEN RETURN ownDef END;
  NEW(d); d.mod := ""; d.next := NIL;
  k := 0; WHILE k < 6 DO L.first[k] := NIL; L.last[k] := NIL; INC(k) END;
  SOpen; SNext;
  IF (tokKind = 1) & (tok = "MODULE") THEN SNext; IF tokKind = 1 THEN COPY(tok, d.mod) END END;
  WHILE tokKind # 0 DO
    IF (tokKind = 1) & (tok = "PROCEDURE") THEN
      SNext;
      WHILE (tokKind = 2) & ((tokCh = "^") OR (tokCh = "*") OR (tokCh = "-") OR (tokCh = "+") OR (tokCh = "&")) DO SNext END;
      IF tokKind = 1 THEN
        COPY(tok, name); SNext;
        IF (tokKind = 2) & ((tokCh = "*") OR (tokCh = "-")) THEN SNext END;
        from := tokPos; sig := ""; pdepth := 0;
        IF (tokKind = 2) & ((tokCh = "(") OR (tokCh = ":")) THEN
          WHILE (tokKind # 0) & ~((tokKind = 2) & (tokCh = ";") & (pdepth = 0)) & ~NextDecl(pdepth) DO
            IF (tokKind = 2) & (tokCh = "(") THEN INC(pdepth) ELSIF (tokKind = 2) & (tokCh = ")") THEN DEC(pdepth) END;
            SNext
          END;
          TextOf(from, tokPos, sig, FALSE)
        END;
        (* a heading whose parameters are not closed yet is not listed *)
        IF (pdepth = 0) & ~Has(L, "p", name) THEN Put(L, NewEntry("p", name, sig)) END
      END
    ELSIF (tokKind = 1) & (tok = "IMPORT") THEN
      SNext;
      WHILE tokKind = 1 DO
        COPY(tok, name); SNext; sig := "";
        IF (tokKind = 2) & (tokCh = ":") THEN
          SNext; IF (tokKind = 2) & (tokCh = "=") THEN SNext END;
          IF tokKind = 1 THEN sig := " := "; i := 4; nn := 0;
            WHILE (tok[nn] # 0X) & (i < LEN(sig) - 1) DO sig[i] := tok[nn]; INC(i); INC(nn) END; sig[i] := 0X; SNext
          END
        END;
        Put(L, NewEntry("m", name, sig));
        IF (tokKind = 2) & (tokCh = ",") THEN SNext END
      END
    ELSIF (tokKind = 1) & ((tok = "VAR") OR (tok = "CONST") OR (tok = "TYPE")) THEN
      IF tok = "VAR" THEN kind := "v" ELSIF tok = "CONST" THEN kind := "c" ELSE kind := "t" END;
      SNext;
      WHILE (tokKind = 1) & ~SectionEnd(tok) DO
        nn := 0;
        LOOP
          IF tokKind # 1 THEN EXIT END;
          IF nn < LEN(names) THEN COPY(tok, names[nn]); INC(nn) END;
          SNext;
          IF (tokKind = 2) & ((tokCh = "*") OR (tokCh = "-")) THEN SNext END;
          IF (tokKind = 2) & (tokCh = ",") THEN SNext ELSE EXIT END
        END;
        from := tokPos; pdepth := 0; rdepth := 0;
        WHILE (tokKind # 0) & ~((tokKind = 2) & (tokCh = ";") & (pdepth = 0) & (rdepth = 0)) &
          ~((rdepth = 0) & NextDecl(pdepth)) DO
          IF tokKind = 2 THEN
            IF tokCh = "(" THEN INC(pdepth) ELSIF tokCh = ")" THEN DEC(pdepth) END
          ELSIF (tokKind = 1) & (tok = "RECORD") THEN INC(rdepth)
          ELSIF (tokKind = 1) & (tok = "END") & (rdepth > 0) THEN DEC(rdepth)
          END;
          SNext
        END;
        TextOf(from, tokPos, val, TRUE);
        IF kind = "v" THEN COPY(val, sig)
        ELSE sig[0] := " "; i := 0; WHILE (val[i] # 0X) & (i < LEN(sig) - 2) DO sig[i+1] := val[i]; INC(i) END; sig[i+1] := 0X
        END;
        i := 0; WHILE i < nn DO Put(L, NewEntry(kind, names[i], sig)); INC(i) END;
        IF (tokKind = 2) & (tokCh = ";") THEN SNext END
      END
    ELSE SNext
    END
  END;
  Std(L, "ABS", "(x)"); Std(L, "ASH", "(x, n)"); Std(L, "ASSERT", "(b)"); Std(L, "CAP", "(c)");
  Std(L, "CHR", "(n)"); Std(L, "COPY", "(source, dest)"); Std(L, "DEC", "(v, n)"); Std(L, "ENTIER", "(x)");
  Std(L, "EXCL", "(s, i)"); Std(L, "HALT", "(n)"); Std(L, "INC", "(v, n)"); Std(L, "INCL", "(s, i)");
  Std(L, "LEN", "(a, dim)"); Std(L, "LONG", "(x)"); Std(L, "MAX", "(T)"); Std(L, "MIN", "(T)");
  Std(L, "NEW", "(p, len)"); Std(L, "ODD", "(n)"); Std(L, "ORD", "(c)"); Std(L, "SHORT", "(x)");
  Std(L, "SIZE", "(T)");
  d.first := NIL; x := NIL; k := 0;
  WHILE k < 6 DO
    IF L.first[k] # NIL THEN
      IF x = NIL THEN d.first := L.first[k] ELSE x.next := L.first[k] END;
      x := L.last[k]
    END;
    INC(k)
  END;
  ownDef := d; ownEdits := edits;
  RETURN d
END OwnDef;

(* ----- completion ----- *)

PROCEDURE CompOpen(any: BOOLEAN): BOOLEAN;
VAR p, s: LONGINT; id, mod: ARRAY 256 OF CHAR; d: Def;
BEGIN
  IF selOn THEN RETURN FALSE END;
  p := cur; WHILE (p > 0) & IsWord(CharAt(p - 1)) DO DEC(p) END;
  IF (p > 0) & (CharAt(p - 1) = ".") THEN
    WordBefore(p - 1, id, s);
    IF (id[0] = 0X) OR (id[0] >= "0") & (id[0] <= "9") OR (s > 0) & (CharAt(s - 1) = ".") THEN RETURN FALSE END;
    IF ~Imported(id, mod) THEN
      IF any THEN COPY(id, mod) ELSE RETURN FALSE END
    END;
    d := ReadDef(mod); compAll := FALSE
  ELSIF any THEN
    IF (p < cur) & (CharAt(p) >= "0") & (CharAt(p) <= "9") THEN RETURN FALSE END;
    d := OwnDef(); compAll := TRUE
  ELSE RETURN FALSE
  END;
  IF d.first = NIL THEN RETURN FALSE END;
  compDef := d; compFrom := p; compOn := TRUE; compSel := 0; compTop := 0;
  RETURN TRUE
END CompOpen;

PROCEDURE CompValid(): BOOLEAN;
VAR p: LONGINT;
BEGIN
  IF ~compOn OR selOn OR (cur < compFrom) OR ~compAll & ((compFrom = 0) OR (CharAt(compFrom - 1) # ".")) THEN RETURN FALSE END;
  p := compFrom; WHILE p < cur DO IF ~IsWord(CharAt(p)) THEN RETURN FALSE END; INC(p) END;
  RETURN TRUE
END CompValid;

PROCEDURE Filter;
VAR prefix: ARRAY 256 OF CHAR; e: Entry; n, i, p: LONGINT;
BEGIN
  n := 0; p := compFrom;
  WHILE (p < cur) & (n < LEN(prefix) - 1) DO prefix[n] := CharAt(p); INC(n); INC(p) END;
  prefix[n] := 0X;
  nMatch := 0; e := compDef.first;
  WHILE (e # NIL) & (nMatch < MaxMatch) DO
    i := 0; WHILE (prefix[i] # 0X) & (CAP(prefix[i]) = CAP(e.name[i])) DO INC(i) END;
    IF prefix[i] = 0X THEN match[nMatch] := e; INC(nMatch) END;
    e := e.next
  END;
  IF compSel >= nMatch THEN compSel := nMatch - 1 END;
  IF compSel < 0 THEN compSel := 0 END
END Filter;

PROCEDURE Accept;
VAR e: Entry; i: LONGINT;
BEGIN
  e := match[compSel]; Delete(compFrom, cur); cur := compFrom;
  i := 0; WHILE e.name[i] # 0X DO Insert(e.name[i]); INC(i) END;
  IF e.params THEN Insert("(") END;
  compOn := FALSE
END Accept;

PROCEDURE CompKey(k: LONGINT): BOOLEAN;
BEGIN
  IF ~compOn THEN RETURN FALSE END;
  IF k = KEsc THEN compOn := FALSE; RETURN TRUE END;
  IF (nMatch = 0) OR (mods # 0) THEN RETURN FALSE END;
  IF k = KUp THEN IF compSel > 0 THEN DEC(compSel) END
  ELSIF k = KDown THEN IF compSel < nMatch - 1 THEN INC(compSel) END
  ELSIF k = KPgUp THEN DEC(compSel, ListRows); IF compSel < 0 THEN compSel := 0 END
  ELSIF k = KPgDn THEN INC(compSel, ListRows); IF compSel >= nMatch THEN compSel := nMatch - 1 END
  ELSIF (k = 0DH) OR (k = 0AH) OR (k = 9) THEN Accept
  ELSE RETURN FALSE
  END;
  RETURN TRUE
END CompKey;

PROCEDURE AfterKey(k: LONGINT);
BEGIN
  IF compOn & ~CompValid() THEN compOn := FALSE END;
  IF source & ~compOn & (k = ORD(".")) THEN IF CompOpen(FALSE) THEN END END;
  IF source & (k = 0) & ~CompOpen(TRUE) THEN msg := "Nothing to complete here" END;
  IF compOn THEN
    IF (k = 7FH) OR (k = 8) OR (k >= 20H) & (k < 100H) THEN compSel := 0; compTop := 0 END;
    Filter
  END
END AfterKey;

PROCEDURE CallAt(VAR e: Entry; VAR arg, pos: LONGINT): BOOLEAN;
VAR p, limit, depth, q, s: LONGINT; c, quote: CHAR; name, id, mod: ARRAY 256 OF CHAR; d: Def;
BEGIN
  p := cur; limit := cur - 4000; depth := 0; arg := 0;
  LOOP
    IF (p <= 0) OR (p <= limit) THEN RETURN FALSE END;
    DEC(p); c := CharAt(p);
    IF (c = ")") & (p > 0) & (CharAt(p - 1) = "*") THEN
      DEC(p);
      REPEAT DEC(p) UNTIL (p < 0) OR (CharAt(p) = "(") & (CharAt(p + 1) = "*");
      IF p < 0 THEN RETURN FALSE END
    ELSIF c = ")" THEN INC(depth)
    ELSIF c = "(" THEN
      IF depth = 0 THEN EXIT END;
      DEC(depth)
    ELSIF (c = ",") & (depth = 0) THEN INC(arg)
    ELSIF c = ";" THEN RETURN FALSE
    ELSIF (c = 22X) OR (c = "'") THEN
      quote := c;
      REPEAT DEC(p) UNTIL (p < 0) OR (CharAt(p) = quote);
      IF p < 0 THEN RETURN FALSE END
    END
  END;
  q := p; WHILE (q > 0) & ((CharAt(q - 1) = " ") OR (CharAt(q - 1) = TAB)) DO DEC(q) END;
  WordBefore(q, name, s);
  IF name[0] = 0X THEN RETURN FALSE END;
  pos := s;
  (* PROCEDURE Name( or PROCEDURE (r: T) Name( is a heading being written, not a call *)
  q := s; WHILE (q > 0) & (CharAt(q - 1) <= " ") DO DEC(q) END;
  IF (q > 0) & (CharAt(q - 1) = ")") THEN RETURN FALSE END;  (* a receiver before the name *)
  WHILE (q > 0) & ((CharAt(q - 1) = "^") OR (CharAt(q - 1) = "*") OR (CharAt(q - 1) = "-") OR (CharAt(q - 1) = "+")
    OR (CharAt(q - 1) = "&")) DO DEC(q) END;
  WHILE (q > 0) & (CharAt(q - 1) <= " ") DO DEC(q) END;
  WordBefore(q, id, q);
  IF id = "PROCEDURE" THEN RETURN FALSE END;
  IF (s > 0) & (CharAt(s - 1) = ".") THEN
    WordBefore(s - 1, id, q);
    IF (id[0] = 0X) OR ~Imported(id, mod) THEN RETURN FALSE END;
    d := ReadDef(mod)
  ELSE d := OwnDef()
  END;
  e := d.first;
  WHILE (e # NIL) & ~(((e.kind = "p") OR (e.kind = "s")) & (e.name = name)) DO e := e.next END;
  RETURN (e # NIL) & e.params
END CallAt;

PROCEDURE DrawHint;
VAR e: Entry; arg, pos, row, col, w, i, k, hb, he, depth: LONGINT;
BEGIN
  IF ~CallAt(e, arg, pos) THEN RETURN END;
  i := 1; k := 0; hb := -1; he := -1;
  LOOP
    WHILE e.sig[i] = " " DO INC(i) END;
    IF (i + 3 < LEN(e.sig)) & (e.sig[i] = "V") & (e.sig[i+1] = "A") & (e.sig[i+2] = "R") & (e.sig[i+3] = " ") THEN INC(i, 4) END;
    LOOP
      WHILE e.sig[i] = " " DO INC(i) END;
      IF k = arg THEN hb := i END;
      WHILE IsWord(e.sig[i]) DO INC(i) END;
      IF k = arg THEN he := i END;
      INC(k);
      WHILE e.sig[i] = " " DO INC(i) END;
      IF e.sig[i] = "," THEN INC(i) ELSE EXIT END
    END;
    depth := 0;
    WHILE (e.sig[i] # 0X) & ~((depth = 0) & ((e.sig[i] = ";") OR (e.sig[i] = ")"))) DO
      IF e.sig[i] = "(" THEN INC(depth) ELSIF e.sig[i] = ")" THEN DEC(depth) END;
      INC(i)
    END;
    IF e.sig[i] = ";" THEN INC(i) ELSE EXIT END
  END;
  w := 2; i := 0; WHILE e.name[i] # 0X DO INC(w); INC(i) END;
  i := 0; WHILE e.sig[i] # 0X DO INC(w); INC(i) END;
  IF w > cols THEN w := cols END;
  row := LineNo(cur) - LineNo(top) + 2; IF row > 2 THEN DEC(row) ELSE INC(row) END;
  col := Col(pos) - hcol; IF col + w > cols + 1 THEN col := cols - w + 1 END; IF col < 1 THEN col := 1 END;
  Goto(row, col); CSI(BoxColour); Ch(" "); k := 1; i := 0;
  WHILE (e.name[i] # 0X) & (k < w - 1) DO Ch(e.name[i]); INC(k); INC(i) END;
  i := 0;
  WHILE (e.sig[i] # 0X) & (k < w - 1) DO
    IF i = hb THEN CSI(ParamOn) ELSIF i = he THEN CSI(ParamOff) END;
    Ch(e.sig[i]); INC(i); INC(k)
  END;
  CSI(ParamOff); Ch(" "); Attr(0)
END DrawHint;

PROCEDURE DrawList;
VAR n, r, row, col, w, len, i, j: LONGINT; e: Entry; line: ARRAY 520 OF CHAR; tag: ARRAY 8 OF CHAR;

  PROCEDURE Put(s: ARRAY OF CHAR);
  VAR i: LONGINT;
  BEGIN i := 0; WHILE (s[i] # 0X) & (len < LEN(line) - 1) DO line[len] := s[i]; INC(len); INC(i) END
  END Put;

BEGIN
  n := nMatch; IF n > ListRows THEN n := ListRows END;
  IF compSel < compTop THEN compTop := compSel ELSIF compSel >= compTop + n THEN compTop := compSel - n + 1 END;
  r := LineNo(cur) - LineNo(top) + 2;
  IF r + n <= height + 1 THEN row := r + 1
  ELSIF r - n >= 2 THEN row := r - n
  ELSE row := 2; n := r - 2; IF n < 1 THEN RETURN END
  END;
  w := 0; i := compTop;
  WHILE i < compTop + n DO
    e := match[i]; len := 9;
    j := 0; WHILE e.name[j] # 0X DO INC(len); INC(j) END;
    j := 0; WHILE e.sig[j] # 0X DO INC(len); INC(j) END;
    IF len > w THEN w := len END;
    INC(i)
  END;
  IF w > cols THEN w := cols END;
  IF w >= LEN(line) THEN w := LEN(line) - 1 END;
  col := Col(compFrom) - hcol + 1 - 7; IF col + w > cols + 1 THEN col := cols - w + 1 END; IF col < 1 THEN col := 1 END;
  i := compTop;
  WHILE i < compTop + n DO
    e := match[i];
    IF e.kind = "p" THEN tag := "proc " ELSIF e.kind = "v" THEN tag := "var  "
    ELSIF e.kind = "c" THEN tag := "const" ELSIF e.kind = "t" THEN tag := "type "
    ELSIF e.kind = "m" THEN tag := "mod  " ELSE tag := "std  "
    END;
    len := 0; Put(" "); Put(tag); Put(" "); Put(e.name); Put(e.sig);
    WHILE len < w DO line[len] := " "; INC(len) END;
    line[w] := 0X;
    Goto(row + i - compTop, col);
    IF i = compSel THEN CSI(ChosenColour) ELSE CSI(BoxColour) END;
    Str(line); Attr(0);
    INC(i)
  END;
  Goto(rows - 2, 1); Attr(7); Ch(" "); Str(compDef.mod); Ch(" "); Int(compSel + 1); Ch("/"); Int(nMatch);
  Str("  arrows choose, Enter or Tab takes, Esc closes "); Attr(0); CSI("K")
END DrawList;

(* keep the caret on the screen *)
PROCEDURE Follow;
VAR ls, p, n, c: LONGINT;
BEGIN
  ls := LineStart(cur);
  IF ls < top THEN top := ls
  ELSE
    n := 0; p := top;
    WHILE (p # ls) & (p >= 0) DO p := NextLine(p); INC(n) END;
    WHILE n >= height DO top := NextLine(top); DEC(n) END
  END;
  IF selOn & block THEN c := cCol ELSE c := Col(cur) END;
  IF c < hcol THEN hcol := c - c MOD (cols DIV 2)
  ELSIF c >= hcol + cols - 1 THEN hcol := c - cols DIV 2
  END;
  IF hcol < 0 THEN hcol := 0 END
END Follow;

PROCEDURE Draw;
VAR i, p, ln, sb, se, first, last, l, r, hb, he, ucol, e: LONGINT; eolSel: BOOLEAN;
BEGIN
  GetSize; Follow;
  CSI("?25l"); Goto(1, 1);
  Attr(7); Str("  none  "); Str(name);
  IF plain THEN Str("  [plain text]") ELSE Str("  [Oberon text]") END;
  IF modified THEN Str("  Modified") END;
  CSI("K"); Attr(0);
  IF selOn & ~block THEN SelRange(sb, se) ELSE sb := 0; se := 0 END;
  IF selOn & block THEN BlockArea(first, last, l, r) END;
  i := 0; p := top; ln := LineNo(top);
  WHILE i < height DO
    Goto(i + 2, 1);
    IF p >= 0 THEN
      hb := sb; he := se; e := LineEnd(p); eolSel := (e >= sb) & (e < se) & (e < T.len); ucol := -1;
      IF selOn & block & (ln >= first) & (ln <= last) THEN
        hb := PosAtCol(p, l); he := PosAtCol(p, r); eolSel := FALSE;
        IF l = r THEN ucol := l END
      END;
      DrawLine(p, hb, he, eolSel, ucol); p := NextLine(p)
    ELSE CSI("K")
    END;
    INC(i); INC(ln)
  END;
  Goto(rows - 2, 1); IF msg # "" THEN Attr(7); Str(" "); Str(msg); Str(" "); Attr(0) END; CSI("K");
  Goto(rows - 1, 1);
  Help("^G", "Help"); Help("^O", "Write Out"); Help("^W", "Where Is"); Help("^K", "Cut"); Help("^C", "Copy"); Help("^V", "Paste");
  CSI("K"); Goto(rows, 1);
  Help("^X", "Exit"); Help("^A", "Select All"); Help("^E", "Line End"); Help("Shift", "Select"); Help("^B", "Block");
  CSI("K");
  IF source & ~selOn THEN IF compOn & (nMatch > 0) THEN DrawList ELSE DrawHint END END;
  IF selOn & block THEN Goto(LineNo(cur) - LineNo(top) + 2, cCol - hcol + 1)
  ELSE Goto(LineNo(cur) - LineNo(top) + 2, Col(cur) - hcol + 1)
  END;
  CSI("?25h");
  Flush
END Draw;

(* ask on the message line; ^C cancels (FALSE); tab: ^T toggles the storing format *)
PROCEDURE Prompt(q: ARRAY OF CHAR; VAR s: ARRAY OF CHAR; toggle: BOOLEAN; VAR asPlain: BOOLEAN): BOOLEAN;
VAR k, i: LONGINT;
BEGIN
  LOOP
    GetSize;
    Goto(rows - 2, 1); Attr(7); Str(q);
    IF toggle THEN IF asPlain THEN Str(" [plain text]") ELSE Str(" [Oberon text]") END END;
    Str(": "); Str(s); CSI("K"); Attr(0);
    Goto(rows - 1, 1); Help("Enter", "Accept"); Help("^C", "Cancel");
    IF toggle THEN IF asPlain THEN Help("^T", "As Oberon text") ELSE Help("^T", "As plain text") END END;
    CSI("K"); Goto(rows, 1); CSI("K");
    i := 0; WHILE s[i] # 0X DO INC(i) END;
    Goto(rows - 2, 1); Flush;
    k := ReadKey();
    IF (k = 0DH) OR (k = 0AH) THEN RETURN TRUE
    ELSIF (k = 3) OR (k = -1) THEN RETURN FALSE
    ELSIF (k = 14H) & toggle THEN asPlain := ~asPlain
    ELSIF (k = 7FH) OR (k = 8) THEN IF i > 0 THEN s[i-1] := 0X END
    ELSIF (k >= 20H) & (k < 100H) & (i < LEN(s) - 1) THEN s[i] := CHR(k); s[i+1] := 0X
    END
  END
END Prompt;

PROCEDURE WriteOut(): BOOLEAN;
VAR fname: ARRAY 256 OF CHAR; asPlain: BOOLEAN;
  f: Files.File; rider: Files.Rider; reader: Texts.Reader; c: CHAR;
BEGIN
  COPY(name, fname); asPlain := plain;
  IF ~Prompt("File Name to Write", fname, TRUE, asPlain) THEN msg := "Cancelled"; RETURN FALSE END;
  IF fname = "" THEN msg := "Cancelled"; RETURN FALSE END;
  f := Files.New(fname);
  IF f = NIL THEN msg := "Cannot create file"; RETURN FALSE END;
  Files.Set(rider, f, 0);
  IF asPlain THEN
    Texts.OpenReader(reader, T, 0); Texts.Read(reader, c);
    WHILE ~reader.eot DO
      IF reader.elem # NIL THEN msg := "Cannot store embedded objects as plain text"; RETURN FALSE END;
      IF ~plain & (c = CR) THEN c := LF END;
      Files.Write(rider, c); Texts.Read(reader, c)
    END
  ELSE
    Files.Write(rider, 0F0X); Files.Write(rider, 01X); Texts.Store(rider, T)
  END;
  IF rider.res # 0 THEN msg := "Cannot write file"; RETURN FALSE END;
  Files.Register(f); Files.Close(f);
  COPY(fname, name); plain := asPlain; modified := FALSE;
  msg := "Wrote "; Append(msg, fname);
  IF plain THEN Append(msg, " as plain text") ELSE Append(msg, " as Oberon text") END;
  RETURN TRUE
END WriteOut;

PROCEDURE Find;
VAR s: ARRAY 256 OF CHAR; dummy: BOOLEAN; R, R1: Texts.Reader; p, start, i: LONGINT; c, c1: CHAR; wrapped: BOOLEAN;
BEGIN
  COPY(search, s); dummy := FALSE;
  IF ~Prompt("Search", s, FALSE, dummy) OR (s = "") THEN msg := "Cancelled"; RETURN END;
  COPY(s, search);
  start := cur + 1; IF start > T.len THEN start := 0 END;
  p := start; wrapped := FALSE;
  LOOP
    IF p >= T.len THEN
      IF wrapped THEN EXIT END;
      p := 0; wrapped := TRUE
    END;
    IF wrapped & (p >= start) THEN EXIT END;
    Texts.OpenReader(R, T, p); Texts.Read(R, c);
    IF c = s[0] THEN
      i := 1; Texts.OpenReader(R1, T, p + 1); Texts.Read(R1, c1);
      WHILE (s[i] # 0X) & ~R1.eot & (c1 = s[i]) DO INC(i); Texts.Read(R1, c1) END;
      IF s[i] = 0X THEN cur := p; goalCol := -1; IF wrapped THEN msg := "Search Wrapped" END; RETURN END
    END;
    INC(p)
  END;
  msg := "Not found"
END Find;

PROCEDURE ShowHelp;
VAR k: LONGINT;
BEGIN
  Goto(1, 1); CSI("2J"); Goto(1, 1);
  Str("none - a nano-like editor for Oberon texts and plain files"); Ch(CR); Ch(LF); Ch(CR); Ch(LF);
  Str("^O  Write Out: store the file; in the prompt ^T stores as plain or Oberon text"); Ch(CR); Ch(LF);
  Str("^X  Exit, asking to store changes"); Ch(CR); Ch(LF);
  Str("Shift+arrows, Home, End, PgUp, PgDn  select;  ^A  select all"); Ch(CR); Ch(LF);
  Str("^B  a block: the arrows extend it; after typing they end it, as Esc does (also Alt+Shift)"); Ch(CR); Ch(LF);
  Str("^C  Copy the selection (also to the terminal); without one: line, column, position"); Ch(CR); Ch(LF);
  Str("^K  Cut the selection; without one the line (^K again adds the next line)"); Ch(CR); Ch(LF);
  Str("^V  Paste (also ^U); a block goes into the lines below at the caret's column"); Ch(CR); Ch(LF);
  Str("    Typing, Backspace, Delete replace the selection; with a block on every line of"); Ch(CR); Ch(LF);
  Str("    it: a block of width 0 types into all its lines (indent), Delete takes columns out"); Ch(CR); Ch(LF);
  Str("^W  Where Is: search forward, from the top again at the end"); Ch(CR); Ch(LF);
  Str("Home  Line Start   ^E  Line End   (also End)   Ctrl+Left/Right  by words"); Ch(CR); Ch(LF);
  Str("^Y  Prev Page    (also PgUp; Next Page: PgDn)"); Ch(CR); Ch(LF);
  Str("^L  Refresh the screen"); Ch(CR); Ch(LF); Ch(CR); Ch(LF);
  Str("In .Mod files: Module. lists exports; Ctrl+Space also completes local names"); Ch(CR); Ch(LF);
  Str("    typing filters; arrows choose; Enter or Tab accepts; Esc closes"); Ch(CR); Ch(LF);
  Str("    parameter hints highlight the argument at the caret, including multiline calls"); Ch(CR); Ch(LF); Ch(CR); Ch(LF);
  Str("Plain files stay plain; Oberon texts keep their fonts and colours, new text"); Ch(CR); Ch(LF);
  Str("gets the looks of the character before it."); Ch(CR); Ch(LF); Ch(CR); Ch(LF);
  Attr(7); Str(" Press any key "); Attr(0); Flush;
  k := ReadKey()
END ShowHelp;

(* move the caret for a movement key k (as in a stretch) *)
PROCEDURE Move(k: LONGINT);
VAR p, ls, n: LONGINT;
BEGIN
  IF (k = KUp) OR (k = KDown) THEN
    IF goalCol < 0 THEN goalCol := Col(cur) END;
    ls := LineStart(cur);
    IF k = KUp THEN IF ls > 0 THEN cur := PosAtCol(LineStart(ls - 1), goalCol) END
    ELSE p := NextLine(cur); IF p >= 0 THEN cur := PosAtCol(p, goalCol) END
    END
  ELSIF (k = KPgUp) OR (k = 19H) OR (k = KPgDn) THEN
    IF goalCol < 0 THEN goalCol := Col(cur) END;
    n := height - 1; IF n < 1 THEN n := 1 END;
    p := LineStart(cur);
    WHILE n > 0 DO
      IF k # KPgDn THEN
        IF p > 0 THEN p := LineStart(p - 1); IF top > 0 THEN top := LineStart(top - 1) END END
      ELSE
        ls := NextLine(p); IF ls >= 0 THEN p := ls; ls := NextLine(top); IF ls >= 0 THEN top := ls END END
      END;
      DEC(n)
    END;
    cur := PosAtCol(p, goalCol)
  ELSIF k = KLeft THEN IF ODD(mods DIV Ctrl) THEN cur := WordLeft(cur) ELSE cur := PrevPos(cur) END
  ELSIF k = KRight THEN IF ODD(mods DIV Ctrl) THEN cur := WordRight(cur) ELSE cur := NextPos(cur) END
  ELSIF k = KHome THEN cur := LineStart(cur)
  ELSIF (k = KEnd) OR (k = 5) THEN cur := LineEnd(cur)
  END
END Move;

(* move the caret of a block: columns may lie beyond the end of a line *)
PROCEDURE MoveBlock(k: LONGINT);
VAR ls, p, n: LONGINT;
BEGIN
  ls := LineStart(cur);
  IF k = KLeft THEN BlockCaret(cCol - 1)
  ELSIF k = KRight THEN BlockCaret(cCol + 1)
  ELSIF k = KHome THEN BlockCaret(0)
  ELSIF k = KEnd THEN BlockCaret(EndCol(ls))
  ELSE  (* up, down, pages *)
    IF (k = KUp) OR (k = KDown) THEN n := 1 ELSE n := height - 1; IF n < 1 THEN n := 1 END END;
    WHILE n > 0 DO
      IF (k = KUp) OR (k = KPgUp) THEN IF ls > 0 THEN ls := LineStart(ls - 1) END
      ELSE p := NextLine(ls); IF p >= 0 THEN ls := p END
      END;
      DEC(n)
    END;
    cur := ls; BlockCaret(cCol)
  END
END MoveBlock;

PROCEDURE IsMove(k: LONGINT): BOOLEAN;
BEGIN
  RETURN (k = KUp) OR (k = KDown) OR (k = KLeft) OR (k = KRight) OR (k = KHome) OR (k = KEnd) OR
    (k = KPgUp) OR (k = KPgDn)
END IsMove;

PROCEDURE Key(k: LONGINT);
VAR p, ls, n: LONGINT; buf: Texts.Buffer; cut: BOOLEAN;
BEGIN
  cut := FALSE; msg := "";
  IF (k # KUp) & (k # KDown) & (k # KPgUp) & (k # KPgDn) & (k # 19H) THEN goalCol := -1 END;
  IF IsMove(k) & (ODD(mods DIV Shift) & ODD(mods DIV Alt) OR marking & selOn & block) THEN StartSel(TRUE); MoveBlock(k)
  ELSIF IsMove(k) & ODD(mods DIV Shift) THEN StartSel(FALSE); Move(k)
  ELSIF IsMove(k) OR (k = 19H) OR (k = 5) THEN ClearSel; Move(k)
  ELSIF k = 2 THEN  (* ^B: a block from here, a stretch becomes a block, or the block ends *)
    IF selOn & block THEN ClearSel
    ELSIF selOn THEN
      p := cur; cur := anchor; aLn := LineNo(cur); aCol := Col(cur); cur := p; cCol := Col(cur);
      block := TRUE; marking := TRUE
    ELSE selOn := FALSE; StartSel(TRUE); marking := TRUE
    END;
    IF marking THEN msg := "Block: arrows extend it; after typing they end it, as Esc and ^B do" END
  ELSIF k = 1 THEN  (* ^A: select all *)
    ClearSel; anchor := 0; cur := T.len; selOn := TRUE
  ELSIF (k = 7FH) OR (k = 8) THEN  (* Backspace *)
    IF selOn & block & (aCol = cCol) THEN BlockErase(TRUE)
    ELSIF selOn THEN DeleteSel
    ELSIF cur > 0 THEN p := PrevPos(cur); Delete(p, cur); cur := p
    END
  ELSIF k = KDel THEN
    IF selOn & block & (aCol = cCol) THEN BlockErase(FALSE)
    ELSIF selOn THEN DeleteSel
    ELSIF cur < T.len THEN Delete(cur, NextPos(cur))
    END
  ELSIF (k = 0DH) OR (k = 0AH) THEN IF selOn THEN DeleteSel; ClearSel END; Insert(Newline())
  ELSIF k = 3 THEN  (* ^C: copy (without a selection Edit shows the location) *)
    IF selOn THEN CopySel; msg := "Copied" END
  ELSIF k = 0BH THEN  (* ^K: cut the selection, or the line *)
    IF selOn THEN CopySel; DeleteSel; ClearSel; msg := "Cut"
    ELSE
      ls := LineStart(cur); p := NextLine(cur); IF p < 0 THEN p := T.len END;
      IF p > ls THEN
        IF ~lastCut OR (clip = NIL) OR clipBlock THEN NEW(clip); Texts.OpenBuf(clip); clipBlock := FALSE END;
        NEW(buf); Texts.OpenBuf(buf); Texts.Save(T, ls, p, buf); Texts.Copy(buf, clip);
        Delete(ls, p); cur := ls
      END;
      cut := TRUE
    END
  ELSIF (k = 16H) OR (k = 15H) THEN Paste; ClearSel  (* ^V, ^U *)
  ELSIF k = KPaste THEN TerminalPaste; ClearSel
  ELSIF k = KEsc THEN ClearSel
  ELSIF k = 0FH THEN IF WriteOut() THEN END
  ELSIF k = 17H THEN ClearSel; Find
  ELSIF k = 7 THEN ShowHelp
  ELSIF k = 0CH THEN (* ^L refresh *) Goto(1, 1); CSI("2J")
  ELSIF k = 18H THEN  (* ^X exit *)
    IF modified THEN
      Goto(rows - 2, 1); Attr(7); Str("Save modified buffer?  Y Yes  N No  ^C Cancel"); Attr(0); CSI("K"); Flush;
      LOOP
        n := ReadKey();
        IF (n = ORD("y")) OR (n = ORD("Y")) THEN IF WriteOut() THEN running := FALSE END; EXIT
        ELSIF (n = ORD("n")) OR (n = ORD("N")) THEN running := FALSE; EXIT
        ELSIF (n = 3) OR (n = -1) THEN msg := "Cancelled"; EXIT
        END
      END
    ELSE running := FALSE
    END
  ELSIF (k = 9) OR (k >= 20H) & (k < 100H) THEN  (* a character: replaces the selection *)
    IF k = 9 THEN k := ORD(TAB) END;
    IF selOn & block THEN BlockType(CHR(k))
    ELSE IF selOn THEN DeleteSel END; Insert(CHR(k))
    END
  ELSIF k = -1 THEN running := FALSE  (* end of input *)
  END;
  lastCut := cut
END Key;

(* the location for ^C: line, column and position *)
PROCEDURE Location;
VAR ln, lines, p: LONGINT;
BEGIN
  ln := LineNo(cur); lines := LineNo(T.len);
  Goto(rows - 2, 1); Attr(7);
  Str(" line "); Int(ln); Ch("/"); Int(lines);
  Str(", col "); Int(Col(cur) + 1);
  Str(", char "); Int(cur); Ch("/"); Int(T.len); Ch(" ");
  Attr(0); CSI("K");
  p := 0
END Location;

PROCEDURE Edit(VAR fname: ARRAY OF CHAR): BOOLEAN;
VAR f: Files.File; R: Files.Rider; c: CHAR; k: LONGINT; input: Texts.Writer;
BEGIN
  IF raw THEN Out.String("none is already editing"); Out.Ln; RETURN FALSE END;
  IF ~Raw() THEN Out.String("none: an interactive terminal is required"); Out.Ln; RETURN FALSE END;
  COPY(fname, name); NEW(T);
  f := Files.Old(name);
  IF f # NIL THEN
    Files.Set(R, f, 0); Files.Read(R, c);
    plain := (Files.Length(f) = 0) OR (c # 0F0X) & (c # 0F7X) & (c # 01X);
    IF plain THEN
      (* Texts.Open normalizes LF; a plain editor must preserve the actual bytes. *)
      Texts.Open(T, ""); Texts.OpenWriter(input);
      Files.Set(R, f, 0); Files.Read(R, c);
      WHILE ~R.eof DO Texts.Write(input, c); Files.Read(R, c) END;
      Texts.Append(T, input.buf)
    ELSE Texts.Open(T, name)
    END;
    msg := ""
  ELSE Texts.Open(T, name); plain := TRUE; msg := "New File"
  END;
  cur := 0; top := 0; hcol := 0; goalCol := -1; modified := FALSE; lastCut := FALSE; clip := NIL; clipBlock := FALSE;
  selOn := FALSE; block := FALSE; marking := FALSE; mods := 0;
  source := Ends(name, ".Mod") OR Ends(name, ".mod"); defs := NIL; compOn := FALSE; nMatch := 0;
  edits := 0; ownDef := NIL; ownEdits := -1;
  IF match = NIL THEN NEW(match) END;
  Texts.OpenWriter(W);
  running := TRUE;
  WHILE running DO
    Draw;
    k := ReadKey();
    IF (k = 3) & ~selOn THEN Draw; Location; Flush; k := ReadKey() END;  (* ^C shows the location until the next key *)
    IF ~CompKey(k) THEN Key(k); AfterKey(k) END
  END;
  Restore;
  T := NIL; clip := NIL; blockText := NIL;
  defs := NIL; ownDef := NIL; compDef := NIL; match := NIL;
  RETURN TRUE
END Edit;

(** none.Open file -- edit file, a new one when it does not exist *)
PROCEDURE Open*;
VAR A: Texts.Scanner; fname: ARRAY 256 OF CHAR; opened: BOOLEAN;
BEGIN
  Texts.OpenScanner(A, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(A);
  IF ((A.class = Texts.Name) OR (A.class = Texts.String)) &
      (A.s # "") & (A.len < LEN(A.s) - 1) THEN
    COPY(A.s, fname); opened := Edit(fname)
  ELSE
    Out.String("usage: none.Open file"); Out.Ln
  END
END Open;

PROCEDURE Main;
VAR fname: ARRAY 257 OF CHAR; length: LONGINT;
BEGIN
  IF Modules.ArgCount # 2 THEN Out.String("usage: none file"); Out.Ln; Platform.Exit(2) END;
  Modules.GetArg(1, fname);
  IF fname = "--help" THEN Out.String("usage: none file"); Out.Ln; RETURN END;
  length := 0;
  WHILE (length < LEN(fname) - 1) & (fname[length] # 0X) DO INC(length) END;
  IF (length = 0) OR (length >= LEN(name)) THEN
    Out.String("none: file name must contain 1 to 255 bytes"); Out.Ln; Platform.Exit(2)
  END;
  IF ~Edit(fname) THEN Platform.Exit(2) END
END Main;

BEGIN
  raw := FALSE; opos := 0; search := ""; match := NIL; pathSaved := FALSE;
  IF Standalone() THEN Main END
END none.
