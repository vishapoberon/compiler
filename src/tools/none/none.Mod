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
   go to the terminal's clipboard too (OSC 52); a paste from the terminal is taken as it is. *)

IMPORT SYSTEM, Platform, Heap, Files, Texts, termios, Oberon, Out, Modules;

CONST
  ESC = 1BX; CR = 0DX; LF = 0AX; TAB = 09X;
  (* keys above the characters *)
  KUp = 1001; KDown = 1002; KRight = 1003; KLeft = 1004;
  KHome = 1005; KEnd = 1006; KPgUp = 1007; KPgDn = 1008; KDel = 1009; KNone = 1010;
  KPaste = 1011;  (* the start of a bracketed paste of the terminal *)
  KEsc = 1012;    (* Esc alone *)
  Shift = 1; Alt = 2; Ctrl = 4;  (* mods *)

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
  LooksAt(pos); Texts.Write(W, c); Texts.Insert(T, pos, W.buf); modified := TRUE
END InsertAt;

(* insert c at the caret *)
PROCEDURE Insert(c: CHAR);
BEGIN
  InsertAt(cur, c); INC(cur)
END Insert;

PROCEDURE Delete(beg, end: LONGINT);
BEGIN
  IF end > beg THEN Texts.Delete(T, beg, end); modified := TRUE END
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
        Texts.Insert(T, PosAtCol(ls, col), buf); modified := TRUE
      END;
      p := rowEnd + 1; INC(ln)
    END;
    cur := PosAtCol(LineStartNo(LineNo(cur)), col)
  ELSE
    NEW(buf); Texts.OpenBuf(buf); Texts.Copy(clip, buf);
    n := buf.len; Texts.Insert(T, cur, buf); cur := cur + n; modified := TRUE
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
  IF n > 0 THEN Texts.Insert(T, cur, W.buf); cur := cur + n; modified := TRUE END
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
  Texts.OpenWriter(W);
  running := TRUE;
  WHILE running DO
    Draw;
    k := ReadKey();
    IF (k = 3) & ~selOn THEN Draw; Location; Flush; k := ReadKey() END;  (* ^C shows the location until the next key *)
    Key(k)
  END;
  Restore;
  T := NIL; clip := NIL; blockText := NIL;
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
  raw := FALSE; opos := 0; search := "";
  IF Standalone() THEN Main END
END none.
