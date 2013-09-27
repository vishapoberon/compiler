MODULE TextFrames;  (** CAS/MH/HM 20.4.94/JT 1.5.95 **)
 (* IMPORT SYSTEM, Modules, Input, Display, Fonts, Viewers, Oberon, MenuViewers, Texts;*)
    IMPORT  Oberon, Texts;

  CONST
    (** update message IDs **)
      replace* = 0; insert* = 1; delete* = 2;
    (** units **)
      mm* = 36000;  Unit* = 10000;
    (** parc options **)
      gridAdj* = 0;  leftAdj* = 1;  rightAdj* = 2;  pageBreak* = 3;  twoColumns* = 4;
    (** maximum number of TAB stops in Parc **)
      MaxTabs* = 32;

    AdjMask = {leftAdj, rightAdj};
    TAB = 9X; LF = 0AX; CR = 0DX; DEL = 7FX; BRK = 0ACX; ShiftBRK = 0ADX; CRSL = 0C4X; CRSR = 0C3X;
    AdjustSpan = 30; MinTabWidth = 1 * mm; StdTabWidth = 4 * mm;
    rightKey = 0; middleKey = 1; leftKey = 2; cancel = {rightKey, middleKey, leftKey};


  TYPE
    Parc* = POINTER TO ParcDesc;
    ParcDesc* = RECORD (Texts.ElemDesc)
      left*: LONGINT;  (** distance from (F.X + F.left); in units **)
      first*: LONGINT;  (** first line indentation from P.left; in units **)
      width*: LONGINT;  (** parc width; in units **)
      lead*: LONGINT;  (** distance to previous line; in units **)
      lsp*: LONGINT;  (** line spacing of text after P; in units **)
      dsr*: LONGINT;  (** descender of text after P; in units **)
      opts*: SET;
      nofTabs*: INTEGER;
      tab*: ARRAY MaxTabs OF LONGINT  (** in units **)
    END;

    TextLine = POINTER TO TextLineDesc;
    Location* = RECORD
      org*, pos*: LONGINT;
      x*, y*, dx*, dy*: INTEGER;
      line: TextLine
    END;
    TextLineDesc = RECORD
      next: TextLine;
      eot: BOOLEAN;        (* contains end of text *)  
      indent: LONGINT;        (* line indentation in units *)
      w, h, dsr: INTEGER;      (* bounding box clipped to frame (w including indent) *)
      w0, nob: INTEGER;      (* unclipped width (including indent), number of contained blanks: nob > 0 if text line wraps around *)
      org, len, span: LONGINT;  (* len ... characters w/o; span ... w/ trailing CR or white space, if any *)
      P: Parc;              (* last parc before this text line *)
      pbeg: LONGINT        (* position of P *)
    END;

    Frame* = POINTER TO FrameDesc;
    FrameDesc* = RECORD (Display.FrameDesc)
      text*: Texts.Text;
      org*: LONGINT;
      col*, left*, right*, top*, bot*: INTEGER;
      markH*: INTEGER;  (** position of tick mark in scroll bar (< 0 => no tick mark) **)
      barW*: INTEGER;  (** scroll bar width **)
      time*: LONGINT;  (** selection time **)
      hasCar*, hasSel*, showsParcs*: BOOLEAN;  (** caret/selection present; parcs visible **)
      carloc*, selbeg*, selend*: Location;
      focus*: Display.Frame;  (** frame of nested element if this element contains the focus **)
      trailer: TextLine  (* ring with trailer and header *)
    END;

    DisplayMsg* = RECORD (Texts.ElemMsg)
      prepare*: BOOLEAN;
      fnt*: Fonts.Font;
      col*: SHORTINT;
      pos*: LONGINT;  (** position in host text **)
      frame*: Display.Frame;  (** ~prepare => host frame **)
      X0*, Y0*: INTEGER;  (** ~prepare => receiver origin in screen space **)
      indent*: LONGINT;  (** prepare => width already consumed in line, in units **)
      elemFrame*: Display.Frame  (** optional return parameter **)
    END;
    
    TrackMsg* = RECORD (Texts.ElemMsg)
      X*, Y*: INTEGER;
      keys*: SET;
      fnt*: Fonts.Font;
      col*: SHORTINT;
      pos*: LONGINT;  (** position in host text **)
      frame*: Display.Frame;  (** host frame **)
      X0*, Y0*: INTEGER  (** receiver origin in screen space **)
    END;

    FocusMsg* = RECORD (Texts.ElemMsg)
      focus*: BOOLEAN;  (** whether to focus or to defocus **)
      elemFrame*: Display.Frame;  (** focus/defocus target **)
      frame*: Display.Frame  (** host frame **)
    END;
(*
    NotifyMsg* = RECORD (Display.FrameMsg)
      frame*: Display.Frame  (** host frame **)
    END;

    UpdateMsg* = RECORD (Display.FrameMsg)
      id*: INTEGER;
      text*: Texts.Text;
      beg*, end*: LONGINT
    END;
    
    InsertElemMsg* = RECORD (Display.FrameMsg)
      e*: Texts.Elem
    END;

    SelectMsg = RECORD (Display.FrameMsg)
      text: Texts.Text;
      beg, end: LONGINT;
      time: LONGINT
    END;

*)
  VAR
    menuH*, barW*, left*, right*, top*, bot*: INTEGER;
    defParc*: Parc;

    (*shared globals => get rid off in a later version?*)
    W, W0: Texts.Writer;
    B: Texts.Buffer;

    P: Parc;
    pbeg: LONGINT;  (*inv T[pbeg] = P*)
    R: Texts.Reader;
    nextCh: CHAR;  (*inv Base(R) = T => T[Pos(R)-1] = nextCh]*)
    par: Oberon.ParList;
    neutralize: Oberon.ControlMsg;


  PROCEDURE Min (x, y: INTEGER): INTEGER;
  BEGIN IF x < y THEN RETURN x ELSE RETURN y END
  END Min;

  PROCEDURE Max (x, y: INTEGER): INTEGER;
  BEGIN IF x > y THEN RETURN x ELSE RETURN y END
  END Max;
(*
  PROCEDURE MarkMenu (F: Frame);
    VAR R: Texts.Reader; V: Viewers.Viewer; T: Texts.Text; ch: CHAR;
  BEGIN V := Viewers.This(F.X, F.Y);
    IF (V IS MenuViewers.Viewer) & (V.dsc IS Frame) & (F # V.dsc) THEN
      T := V.dsc(Frame).text;
      IF T.len > 0 THEN Texts.OpenReader(R, T, T.len - 1); Texts.Read(R, ch) ELSE ch := 0X END;
      IF ch # "!" THEN Texts.Write(W0, "!"); Texts.Append(T, W0.buf) END
    END
  END MarkMenu;
  
*)
  (* Element Subframes *)
(*
  PROCEDURE InvertBorder (F: Display.Frame);
  BEGIN
    Display.ReplPattern(Display.white, Display.grey1, F.X-1, F.Y-1, F.W+2, 1, Display.invert);
    Display.ReplPattern(Display.white, Display.grey1, F.X-1, F.Y+F.H, F.W+2, 1, Display.invert);
    Display.ReplPattern(Display.white, Display.grey1, F.X-1, F.Y, 1, F.H, Display.invert);
    Display.ReplPattern(Display.white, Display.grey1, F.X+F.W, F.Y, 1, F.H, Display.invert)
  END InvertBorder;

  PROCEDURE InvalSubFrames (F: Frame; x, y, w, h: INTEGER);  (* removes and suspends all subframes partly in (x, y, w, h) *)
    VAR p, f: Display.Frame; msg: MenuViewers.ModifyMsg;
  BEGIN
    IF (w > 0) & (h > 0) THEN f := F.dsc;
      IF f # NIL THEN p := f; f := p.next END;
      WHILE f # NIL DO
        IF (f.X < x + w) & (f.X + f.W > x) & (f.Y < y + h) & (f.Y + f.H > y) THEN p.next := f.next;
          msg.id := MenuViewers.reduce; msg.dY := 0; msg.Y := f.Y; msg.H := 0;
          f.handle(f, msg)
        ELSE p := f
        END;
        f := p.next
      END;
      f := F.dsc;
      IF (f # NIL) & (f.X < x + w) & (f.X + f.W > x) & (f.Y < y + h) & (f.Y + f.H > y) THEN F.dsc := F.dsc.next;
        msg.id := MenuViewers.reduce; msg.dY := 0; msg.Y := f.Y; msg.H := 0;
        f.handle(f, msg)
      END
    END
  END InvalSubFrames;

  PROCEDURE ShiftSubFrames (F: Frame; oldY, newY, h: INTEGER);  (* shift (F.X, oldY, F.W, h) to (F.X, newY, F.W, h) *)
    VAR f: Display.Frame; msg: MenuViewers.ModifyMsg;
  BEGIN
    IF oldY > newY THEN InvalSubFrames(F, F.X, newY, F.W, oldY - newY)
    ELSE InvalSubFrames(F, F.X, oldY + h, F.W, newY - oldY)
    END;
    f := F.dsc;
    WHILE f # NIL DO
      IF (f.Y < oldY + h) & (f.Y + f.H > oldY) THEN INC(f.Y, newY - oldY);
        msg.id := MenuViewers.reduce; msg.dY := 0; msg.Y := f.Y; msg.H := f.H;
        f.handle(f, msg)
      END;
      f := f.next
    END
  END ShiftSubFrames;

  PROCEDURE NotifySubFrames (F: Frame; VAR msg: Display.FrameMsg);
    VAR p, f: Display.Frame;
  BEGIN f := F.dsc;
    IF msg IS NotifyMsg THEN msg(NotifyMsg).frame := F END;
    WHILE f # NIL DO p := f; f := f.next; p.handle(p, msg) END
  END NotifySubFrames;

*)
  (* Display Primitives *)
(*
  PROCEDURE DrawCursor (x, y: INTEGER);
  BEGIN Oberon.DrawCursor(Oberon.Mouse, Oberon.Arrow, x, y)
  END DrawCursor;

  PROCEDURE TrackMouse (VAR x, y: INTEGER; VAR keys, keysum: SET);
  BEGIN Input.Mouse(keys, x, y); keysum := keysum + keys; DrawCursor(x, y)
  END TrackMouse;

  PROCEDURE EraseRect (F: Frame; x, y, w, h: INTEGER);
  BEGIN Display.ReplConst(F.col, x, y, w, h, Display.replace); InvalSubFrames(F, x, y, w, h)
  END EraseRect;

  PROCEDURE Erase (F: Frame; x, y, w, h: INTEGER);  (*RemoveMarks optimization*)
  BEGIN
    IF h > 0 THEN Oberon.RemoveMarks(x, y, w, h); EraseRect(F, x, y, w, h) END
  END Erase;

  PROCEDURE Shift (F: Frame; oldY, newY, h: INTEGER);  (*RemoveMarks optimization*)
  BEGIN
    IF (oldY # newY) & (h > 0) THEN
      Oberon.RemoveMarks(F.X + F.left, Min(oldY, newY), F.W - F.left, Max(oldY, newY) + h);
      Display.CopyBlock(F.X + F.left, oldY, F.W - F.left, h, F.X + F.left, newY, Display.replace);
      ShiftSubFrames(F, oldY, newY, h)
    END
  END Shift;

  PROCEDURE InvertCaret (F: Frame);
    VAR loc: Location; bot: INTEGER;
  BEGIN loc := F.carloc; bot := loc.y + loc.line.dsr - 6;
    Display.CopyPatternC(F, Display.white, Display.hook, loc.x, bot, Display.invert)
  END InvertCaret;

  PROCEDURE InvertRect (F: Frame; x, y, w, h: INTEGER);  (*clips to right and bottom frame margin*)
  BEGIN
    IF x + w > F.X + F.W - F.right THEN w := F.X + F.W - F.right - x END;
    IF y >= F.Y + F.bot THEN Display.ReplConst(Display.white, x, y, w, h, Display.invert) END
  END InvertRect;

  PROCEDURE InvertSelection (F: Frame; beg, end: Location);
    VAR t: TextLine; ex, rx, w, py: INTEGER;
  BEGIN
    rx := F.X + F.W - F.right; t := end.line;
    IF t.eot OR (end.pos <= t.org + t.len) THEN ex := end.x ELSE ex := rx END;
    IF beg.line = end.line THEN InvertRect(F, beg.x, beg.y, ex - beg.x, beg.line.h)
    ELSE t := beg.line; py := beg.y; w := F.W - F.left - F.right;
      InvertRect(F, beg.x, py, rx - beg.x, t.h); t := t.next; DEC(py, t.h);
      WHILE t # end.line DO InvertRect(F, F.X + F.left, py, w, t.h); t := t.next; DEC(py, t.h) END;
      InvertRect(F, F.X + F.left, py, ex - (F.X + F.left), t.h)
    END
  END InvertSelection;

  PROCEDURE CoordToPos (F: Frame; mh: INTEGER): LONGINT;
    VAR h: INTEGER;
  BEGIN h := F.H - 1;
    IF h > 0 THEN RETURN ENTIER(F.text.len / h * (h - mh)) ELSE RETURN 0 END
  END CoordToPos;

  PROCEDURE ShowBar (F: Frame; botH, topH: INTEGER);
  BEGIN
    IF (F.left > F.barW) & (F.barW > 0) THEN
      Display.ReplConst(Display.white, F.X + F.barW - 1, F.Y + botH, 1, topH - botH, Display.replace)
    END
  END ShowBar;

  PROCEDURE Tick (F: Frame);
  BEGIN
    IF (0 <= F.markH) & (F.markH < F.H) & (F.left > F.barW) & (F.barW > 6) & (F.H > 2) THEN
      Display.ReplConst(Display.white, F.X + 1, F.Y + F.markH, F.barW - 6, 2, Display.invert)
    END
  END Tick;

  PROCEDURE ShowTick (F: Frame);  (* removes global marks as needed *)
    VAR h, mh: INTEGER; len: LONGINT;
  BEGIN
    h := F.H - 2; len := F.text.len;
    IF len > 0 THEN mh := SHORT(ENTIER(h - F.org / len * h)) ELSE mh := h END;
    IF F.markH # mh THEN Oberon.RemoveMarks(F.X, F.Y, F.barW, F.H);
      Tick(F); F.markH := mh; Tick(F)
    END
  END ShowTick;

  PROCEDURE Mark* (F: Frame; mark: INTEGER);
  BEGIN
    Erase(F, F.X, F.Y, F.barW - 1, F.H); F.markH := -1;
    IF (mark < 0) & (F.H >= 16) THEN
      Display.CopyPattern(Display.white, Display.downArrow, F.X, F.Y, Display.invert)
    ELSIF mark > 0 THEN
      ShowTick(F)
    END
  END Mark;
*)

  (** Parcs **)

  PROCEDURE ParcBefore* (T: Texts.Text; pos: LONGINT; VAR P: Parc; VAR beg: LONGINT);
    VAR R: Texts.Reader;
  BEGIN Texts.OpenReader(R, T, pos + 1);
    REPEAT Texts.ReadPrevElem(R) UNTIL R.eot OR (R.elem IS Parc);
    IF R.eot THEN P := defParc; beg := -1 ELSE P := R.elem(Parc); beg := Texts.Pos(R) END
  END ParcBefore;

  PROCEDURE -InitDefParc()  "ParcElems__init()";

  (* Screen Metrics *)

  PROCEDURE Tab (dw: INTEGER; VAR dx: INTEGER);  (*P set*)
    (* dw = line width from left margin to caret (in pixels); dx = distance from caret to next tab stop (in pixels) *)
    VAR i, n: INTEGER; w: LONGINT;
  BEGIN
    i := 0; n := P.nofTabs; w := LONG(dw) * Unit + MinTabWidth;
    IF dw < 0 THEN dx := -dw
    ELSE
      WHILE (i < n) & (P.tab[i] < w) DO INC(i) END;
      IF i < n THEN dx := SHORT((P.tab[i] - LONG(dw) * Unit) DIV Unit)
      ELSE dx := StdTabWidth DIV Unit
      END
    END
  END Tab;
(*
  PROCEDURE MeasureSpecial (dw: INTEGER; VAR dx, x, y, w, h: INTEGER);
    (* returns metrics of nextCh (nextCh <= " "); sends prepare message to elements; P, R, nextCh set *)
    VAR e: Texts.Elem; pat: Display.Pattern; msg: DisplayMsg;
  BEGIN
    IF nextCh = " " THEN Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat);
      x := 0; y := 0; w := dx; h := 0
    ELSIF nextCh = TAB THEN Tab(dw, dx); x := 0; y := 0; w := dx; h := 0
    ELSIF R.elem # NIL THEN e := R.elem;
      msg.prepare := TRUE; msg.indent := LONG(dw) * Unit;
      msg.fnt := R.fnt; msg.col := R.col; msg.pos := Texts.Pos(R)-1;
      msg.Y0 := -SHORT(P.dsr DIV Unit);  (*<<< 18-Nov-91*)
      e.handle(e, msg);
      w := SHORT(e.W DIV Unit);
      dx := w; x := 0; y := msg.Y0; h := SHORT(e.H DIV Unit)  (*<<< 18-Nov-91*)
    ELSE Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat)
    END
  END MeasureSpecial;

  PROCEDURE GetSpecial (F: Frame; VAR n: INTEGER; cn, ddx, dw: INTEGER; VAR dx, x, y, w, h: INTEGER);
    (* returns metrics of nextCh (nextCh <= " "); no prepare message to elements; extends blanks for block adjust *)
    (* cn ... add 1 pixel to first cn blanks (block adjust); ddx ... add ddx pixels to every blank (block adjust) *)
    (*P, R, nextCh set*)
    VAR e: Texts.Elem; pat: Display.Pattern;
  BEGIN
    IF nextCh = " " THEN Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat);
      x := 0; y := 0; INC(dx, ddx); INC(n); IF n <= cn THEN INC(dx) END;  (*space correction for block adjustment*)
      w := dx; h := 0
    ELSIF nextCh = TAB THEN Tab(dw, dx); x := 0; y := 0; w := dx; h := 0
    ELSIF R.elem # NIL THEN e := R.elem;
      IF (e IS Parc) & (P.W = 9999 * Unit) THEN (* P gets this value in prepare message *)
        w := Min(SHORT((P.width + P.left) DIV Unit), F.W - F.right - F.left);
        e.W := LONG(w) * Unit
      ELSE w := SHORT(e.W DIV Unit)
      END;
      dx := w; x := 0; y := -SHORT(P.dsr DIV Unit); h := SHORT(e.H DIV Unit)
    ELSE Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat)
    END
  END GetSpecial;

  PROCEDURE NextLine (T: Texts.Text; VAR org: LONGINT);  (*R, nextCh set; org = Texts.Pos(R)-1*)
    VAR pat: Display.Pattern; pos, bk, d: LONGINT; width, tw, dx, x, y, w, h: INTEGER;
      R1: Texts.Reader; peekCh: CHAR; indent: INTEGER;
  BEGIN
    tw := 0; dx := 0; w := 0; bk := -999;  (* bk = pos of last seperator *)
    pos := org; ParcBefore(T, pos, P, pbeg); width := SHORT(P.width DIV Unit);
    indent := 0;
    IF org > 0 THEN Texts.OpenReader(R1, T, org - 1); Texts.Read(R1, peekCh);
      IF (peekCh = CR) OR (R1.elem # NIL) & (R1.elem IS Parc) THEN indent := SHORT(P.first DIV Unit) END;
    END;
    INC(tw, indent);
    LOOP INC(pos);  (*inv pos = Texts.Pos(R), ~R.eof => nextCh = text[pos-1]*)
      IF R.eot OR (nextCh = CR) THEN EXIT END;
      INC(tw, dx);
      IF nextCh <= " " THEN MeasureSpecial(tw, dx, x, y, w, h)
      ELSE Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat)
      END;
      IF tw + x + w > width THEN d := pos - bk;
        IF (d < AdjustSpan) & (nextCh > " ") THEN pos := bk
        ELSIF ((nextCh > " ") OR (nextCh = Texts.ElemChar)) & (pos > org + 1) THEN DEC(pos)
        END;
        Texts.OpenReader(R, T, pos); Texts.Read(R, nextCh);
        EXIT
      END;
      IF (nextCh <= " ") & (nextCh # Texts.ElemChar) THEN bk := pos END;
      Texts.Read(R, nextCh)
    END;
    org := pos
  END NextLine;

  PROCEDURE BegOfLine (T: Texts.Text; VAR pos: LONGINT; adjust: BOOLEAN);
    (* returns origin of line containing pos *)
    VAR p, org: LONGINT;
  BEGIN
    IF pos <= 0 THEN pos := 0
    ELSE
      IF pos <= T.len THEN org := pos ELSE org := T.len END;
      LOOP  (*search backwards for CR*)
        IF org = 0 THEN EXIT END;
        Texts.OpenReader(R, T, org - 1); Texts.Read(R, nextCh);
        IF nextCh = CR THEN EXIT END;
        DEC(org)
      END;
      IF adjust THEN  (*search forward for actual line origin*)
        Texts.OpenReader(R, T, org); Texts.Read(R, nextCh); p := org;
        REPEAT org := p; NextLine(T, p) UNTIL (p > pos) OR R.eot
      END;
      pos := org
    END
  END BegOfLine;

  PROCEDURE AdjustMetrics (F: Frame; t: TextLine; VAR pw, tw, ddx, cn: INTEGER);  (*t.org set*)
    (* pw ... x-coord of first char in line (in pixels); tw ... width of text line; ddx, cn ... see GetSpecial *)
  BEGIN
    P := t.P; pbeg := t.pbeg;
    pw := F.left; tw := t.w; ddx := 0; cn := 0;
    IF t.pbeg # t.org THEN
      INC(pw, SHORT((P.left + t.indent) DIV Unit));
      IF leftAdj IN P.opts THEN
        IF (rightAdj IN P.opts) & (t.nob > 0) THEN
          tw := SHORT(P.width DIV Unit); ddx := (tw - t.w0) DIV t.nob; cn := (tw - t.w0) MOD t.nob
        END
      ELSIF rightAdj IN P.opts THEN INC(pw, SHORT(P.width DIV Unit) - t.w0)
      ELSE (*center*) INC(pw, (SHORT(P.width DIV Unit) - t.w0) DIV 2)
      END;
      DEC(tw, SHORT(t.indent DIV Unit));
    END
  END AdjustMetrics;

*)
  (* Screen Placement *)
(*
  PROCEDURE DrawSpecial (F: Frame; px, py, x, y: INTEGER);  (*R, nextCh set*)
    VAR e: Texts.Elem; pat: Display.Pattern; dx, w, h: INTEGER; msg: DisplayMsg;
  BEGIN
    IF (nextCh = TAB) OR (nextCh = CR) THEN (*skip*)
    ELSIF R.elem # NIL THEN e := R.elem;
      IF ~(e IS Parc) OR F.showsParcs THEN
        msg.prepare := FALSE; msg.fnt := R.fnt; msg.col := R.col; msg.pos := Texts.Pos(R) - 1;
        msg.frame := F; msg.X0 := px + x; msg.Y0 := py + y; msg.elemFrame := NIL;
        e.handle(e, msg);
        IF msg.elemFrame # NIL THEN msg.elemFrame.next := F.dsc; F.dsc := msg.elemFrame END;
      ELSIF pageBreak IN e(Parc).opts THEN (*(e IS Parc) & ~F.showsParcs*)
        Display.ReplPattern(Display.white, Display.grey1, px + x, py, SHORT(e.W DIV Unit), 1, Display.replace)
      END
    ELSE Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat);
      Display.CopyPattern(R.col, pat, px + x, py + y, Display.invert)
    END;
  END DrawSpecial;

  PROCEDURE ShowLine (F: Frame; t: TextLine; left, right, py: INTEGER);
    VAR pat: Display.Pattern; i: LONGINT; n, cn, lm, px, pw, tw, ddx, dx, x, y, w, h: INTEGER;
  BEGIN
    (* lm ... left parc margin in screen coord; pw ...  x of first char in frame coord *)
    Texts.OpenReader(R, F.text, t.org); AdjustMetrics(F, t, pw, tw, ddx, cn);
    lm := F.X + F.left + SHORT(P.left DIV Unit); px := F.X + pw; INC(py, t.dsr); i := 0; n := 0;
    WHILE i < t.len DO Texts.Read(R, nextCh);
      IF nextCh <= " " THEN GetSpecial(F, n, cn, ddx, px - lm, dx, x, y, w, h)
      ELSE Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat)
      END;
      INC(y, R.fnt.height * R.voff DIV 64);
      IF px + x + w <= right THEN
        IF px + x >= left THEN
          IF nextCh <= " " THEN DrawSpecial(F, px, py, x, y)
          ELSE Display.CopyPattern(R.col, pat, px + x, py + y, Display.invert)
          END
        END;
        INC(px, dx); INC(i)
      ELSE i := t.len
      END
    END
  END ShowLine;

  PROCEDURE ShowLines (F: Frame; botH, topH: INTEGER; erase: BOOLEAN);
    VAR t: TextLine; ph: INTEGER;
  BEGIN
    t := F.trailer.next; ph := F.H - F.top;
    WHILE (t # F.trailer) & (ph - t.h >= topH) DO DEC(ph, t.h); t := t.next END;
    WHILE (t # F.trailer) & (ph - t.h >= botH) DO DEC(ph, t.h);
      IF erase THEN Erase(F, F.X + F.left, F.Y + ph, F.W - F.right - F.left, t.h) END;
      ShowLine(F, t, F.X + F.left, F.X + F.W - F.right, F.Y + ph); t := t.next
    END
  END ShowLines;

*)
  (* Screen Casting *)
(*
  PROCEDURE MeasureLine (F: Frame; maxW: INTEGER; t: TextLine);  (* R, nextCh set *)
    VAR pat: Display.Pattern; len, bklen, d: LONGINT; eol: BOOLEAN;
      nob, bknob, width, minY, bkminY, maxY, bkmaxY, tw, bktw, lsp, dsr, dx, x, y, w, h: INTEGER;
      R1: Texts.Reader; peekCh: CHAR;
      (* bk* ... backup for last blank *)
  BEGIN
    len := 0; nob := 0; bklen := -999; tw := 0; dx := 0; minY := 0; maxY := 0;
    ParcBefore(F.text, t.org, P, pbeg);
    lsp := SHORT(P.lsp DIV Unit); dsr := SHORT(P.dsr DIV Unit); width := SHORT(P.width DIV Unit);
    t.indent := 0;
    IF t.org > 0 THEN Texts.OpenReader(R1, F.text, t.org - 1); Texts.Read(R1, peekCh);
      IF (peekCh = CR) OR (R1.elem # NIL) & (R1.elem IS Parc) THEN t.indent := P.first END;
    END;
    INC(tw, SHORT(t.indent DIV Unit));
    LOOP
      IF R.eot OR (nextCh = CR) THEN nob := 0; eol := ~R.eot; EXIT END;
      IF nextCh <= " " THEN MeasureSpecial(tw, dx, x, y, w, h)
      ELSE Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat)
      END;
      IF tw + x + w > width THEN d := len - bklen;
        IF (d < AdjustSpan) & (nextCh > " ") THEN eol := TRUE;
          Texts.OpenReader(R, F.text, Texts.Pos(R) - d);
          nob := bknob; len := bklen; tw := bktw; minY := bkminY; maxY := bkmaxY
        ELSIF len = 0 THEN  (* force at least one character on each line *)
          INC(len); INC(y, R.fnt.height * R.voff DIV 64); minY := Min(minY, y); maxY := Max(maxY, y + h);
          Texts.Read(R, nextCh); eol := FALSE; tw := maxW
        ELSE eol := (nextCh <= " ") & (nextCh # Texts.ElemChar)
        END;
        EXIT
      END;
      IF (nextCh <= " ") & (nextCh # Texts.ElemChar) THEN
        bknob := nob; bklen := len; bktw := tw; bkminY := minY; bkmaxY := maxY;
        IF nextCh = " " THEN INC(nob) END
      END;
      INC(len); INC(tw, dx); INC(y, R.fnt.height * R.voff DIV 64);
      IF y < minY THEN minY := y END;
      IF y + h > maxY THEN maxY := y + h END;
      Texts.Read(R, nextCh)
    END;
    IF ~F.showsParcs & (pbeg = t.org) THEN dsr := 0; t.h := SHORT(P.lead DIV Unit) + 1
    ELSIF gridAdj IN P.opts THEN
      WHILE dsr < -minY DO INC(dsr, lsp) END;
      t.h := Max(lsp, dsr + maxY); INC(t.h, (-t.h) MOD lsp)
    ELSE dsr := Max(dsr, -minY); t.h := Max(lsp, dsr + maxY)
    END;
    t.len := len; t.w0 := tw; t.w := Min(tw, maxW); t.dsr := dsr; t.nob := nob; t.eot := R.eot; t.P := P; t.pbeg := pbeg;
    IF eol THEN Texts.Read(R, nextCh); t.span := len + 1 ELSE t.span := len END
  END MeasureLine;

  PROCEDURE MeasureLines (F: Frame; org: LONGINT; VAR trailer: TextLine);
    VAR s, t: TextLine; ph: INTEGER;
  BEGIN
    NEW(trailer); s := trailer;
    Texts.OpenReader(R, F.text, org); Texts.Read(R, nextCh); ph := F.H - F.top;
    LOOP NEW(t); t.org := org; MeasureLine(F, F.W - F.left - F.right, t);
      IF ph - t.h < F.bot THEN EXIT END;
      s.next := t; s := t; INC(org, s.span); DEC(ph, s.h);
      IF R.eot THEN EXIT END
    END;
    s.next := trailer; trailer.eot := TRUE; trailer.org := org; (* start of first invisible line *) trailer.len := 0; trailer.w := 0;
    trailer.h := SHORT(defParc.lsp DIV Unit); trailer.P := P (* P set by MeasureLine *) ; trailer.pbeg := pbeg
  END MeasureLines;

*)
  (** Locators **)
(*
  PROCEDURE LocateLineTop (F: Frame; trailer: TextLine; org: LONGINT; VAR loc: Location);
    VAR t: TextLine; ph: INTEGER;
  BEGIN
    ph := F.H - F.top; t := trailer.next;
    WHILE (t # trailer) & (t.org # org) DO DEC(ph, t.h); t := t.next END;
    loc.org := org; loc.line := t; loc.y := F.Y + ph
  END LocateLineTop;

  PROCEDURE Width (F: Frame; t: TextLine; pos: LONGINT; VAR pw, dx, dy: INTEGER);
    VAR pat: Display.Pattern; i: LONGINT; n, mw, lm, tw, ddx, cn, x, y, w, h: INTEGER;
  BEGIN
    AdjustMetrics(F, t, pw, tw, ddx, cn); dy := 0; lm := F.left + SHORT(P.left DIV Unit);
    IF t # F.trailer THEN Texts.OpenReader(R, F.text, t.org); Texts.Read(R, nextCh);
      i := 0; n := 0; DEC(pos, t.org); dx := 0; mw := F.W - F.right;
      WHILE ~R.eot & (i < t.len) & (i <= pos) & (pw + dx <= mw) DO
        (* i ... pos of nextCh; dx ... width of char before nextCh; pw ... line width up to pos (or up to right margin) *)
        INC(i); INC(pw, dx);
        IF nextCh <= " " THEN GetSpecial(F, n, cn, ddx, pw - lm, dx, x, y, w, h)
        ELSE Display.GetChar(R.fnt.raster, nextCh, dx, x, y, w, h, pat)
        END;
        dy := R.fnt.height * R.voff DIV 64;
        Texts.Read(R, nextCh)
      END;
      IF (i <= pos) & (pw + dx <= mw) THEN INC(i); INC(pw, dx) END
    ELSE dx := 4
    END
  END Width;


  PROCEDURE LocatePos* (F: Frame; pos: LONGINT; VAR loc: Location);  (* loc.dx = dx of char at pos *)
    VAR t: TextLine; pw, dx, dy: INTEGER;
  BEGIN
    IF pos < F.org THEN pos := F.org; t := F.trailer.next
    ELSIF pos < F.trailer.org THEN t := F.trailer;
      WHILE (t.next # F.trailer) & (t.next.org <= pos) DO t := t.next END
    ELSE pos := F.trailer.org; t := F.trailer.next;
      WHILE ~t.eot DO t := t.next END
    END;
    Width(F, t, pos, pw, dx, dy); LocateLineTop(F, F.trailer, t.org, loc); DEC(loc.y, loc.line.h);
    loc.org := t.org; loc.pos := pos; loc.x := F.X + pw; loc.dx := dx; loc.dy := dy; loc.line := t
  END LocatePos;

  PROCEDURE LocateLine* (F: Frame; y: INTEGER; VAR loc: Location);
    (* loc.x = line start; loc.y = line bottom; loc.dx = line width *)
    VAR t: TextLine; h, ph, pw, tw, ddx, cn: INTEGER;
  BEGIN
    t := F.trailer.next; h := y - F.Y; ph := F.H - F.top - t.h;
    WHILE ~t.eot & (ph - t.next.h >= F.bot) & (ph > h) DO t := t.next; DEC(ph, t.h) END;
    AdjustMetrics(F, t, pw, tw, ddx, cn);
    IF pw >= F.W - F.right THEN pw := F.W - F.right - 4 END;
    loc.org := t.org; loc.pos := loc.org; loc.x := F.X + pw; loc.y := F.Y + ph; loc.dx := tw; loc.dy := 0; loc.line := t
  END LocateLine;

  PROCEDURE LocateChar* (F: Frame; x, y: INTEGER; VAR loc: Location);
    VAR t: TextLine; pat: Display.Pattern; i: LONGINT; n, w, lm, pw, tw, ddx, cn, dx, xc, yc, wc, hc: INTEGER;
  BEGIN
    LocateLine(F, y, loc); t := loc.line; w := x - F.X; AdjustMetrics(F, t, pw, tw, ddx, cn);
    lm := F.left + SHORT(P.left DIV Unit);
    IF (t # F.trailer) & (w > pw) THEN Texts.OpenReader(R, F.text, t.org);
      i := 0; n := 0; dx := 0; nextCh := 0X;
      WHILE (i < t.len) & (pw + dx < w) DO
        (* i = pos after nextCh; dx = width of nextCh; pw = line width without nextCh *)
        Texts.Read(R, nextCh); INC(i); INC(pw, dx);
        IF nextCh <= " " THEN GetSpecial(F, n, cn, ddx, pw - lm, dx, xc, yc, wc, hc)
        ELSE Display.GetChar(R.fnt.raster, nextCh, dx, xc, yc, wc, hc, pat)
        END
      END;
      IF pw + dx < w THEN INC(i); INC(pw, dx); R.elem := NIL END;
      INC(loc.pos, i - 1); loc.x := F.X + pw;
      IF i < t.len THEN loc.dx := dx; loc.dy := R.fnt.height * R.voff DIV 64 ELSE loc.dx := 4 END
    ELSE loc.dx := 4; R.elem := NIL
    END
  END LocateChar;

  PROCEDURE LocateWord* (F: Frame; x, y: INTEGER; VAR loc: Location);
    VAR t: TextLine; pos, i: LONGINT; px, rx: INTEGER; pat: Display.Pattern; dx, xc, yc, wc, hc: INTEGER;
  BEGIN
    LocateChar(F, x, y, loc); pos := loc.pos + 1;
    REPEAT DEC(pos); Texts.OpenReader(R, F.text, pos); Texts.Read(R, nextCh)
    UNTIL (pos < loc.org) OR (nextCh > " ");
    INC(pos);
    REPEAT DEC(pos); Texts.OpenReader(R, F.text, pos); Texts.Read(R, nextCh)
    UNTIL (pos < loc.org) OR (nextCh <= " ");
    LocatePos(F, pos + 1, loc); t := loc.line; i := loc.pos - loc.org;
    IF i < t.len THEN px := loc.x; rx := F.X + F.W - F.right;
      Texts.OpenReader(R, F.text, loc.pos); dx := 0; wc := 0; nextCh := "x";
      WHILE (i < t.len) & (nextCh > " ") & (px + dx < rx) DO
        Texts.Read(R, nextCh); INC(i); INC(px, dx);
        Display.GetChar(R.fnt.raster, nextCh, dx, xc, yc, wc, hc, pat)
      END;
      IF (nextCh > " ") & (px + dx < rx) THEN INC(i); INC(px, dx) END;
      loc.dx := px - loc.x
    ELSE loc.dx := 0
    END
  END LocateWord;

  PROCEDURE Pos* (F: Frame; x, y: INTEGER): LONGINT;
    VAR loc: Location;
  BEGIN LocateChar(F, x, y, loc); RETURN loc.pos
  END Pos;

  PROCEDURE ThisSubFrame (F: Frame; x, y: INTEGER): Display.Frame;
    VAR f: Display.Frame;
  BEGIN f := F.dsc;
    WHILE (f # NIL) & ((x < f.X) OR (x >= f.X + f.W) OR (y < f.Y) OR (y >= f.Y + f.H)) DO f := f.next END;
    RETURN f
  END ThisSubFrame;

*)
  (** Caret & Selection **)
(*
  PROCEDURE PassSubFocus (F: Frame; f: Display.Frame);
    (* pass focus from F.focus to f (f is also an element frame in F) *)
    VAR loc: Location; f1: Display.Frame; ctrl: Oberon.ControlMsg; focus: FocusMsg;
  BEGIN
    IF F.focus # NIL THEN f1 := F.focus;
      ctrl.id := Oberon.defocus; f1.handle(f1, ctrl);
      LocateChar(F, f1.X + 1, f1.Y + 1, loc);
      InvertBorder(f1); F.focus := NIL;
      focus.focus := FALSE; focus.elemFrame := f1; focus.frame := F; R.elem.handle(R.elem, focus)
    END;
    IF f # NIL THEN
      LocateChar(F, f.X + 1, f.Y + 1, loc);  (* side effect: set R to element *)
      focus.focus := TRUE; focus.elemFrame := f; focus.frame := F; R.elem.handle(R.elem, focus);
      InvertBorder(f)
    END;
    F.focus := f
  END PassSubFocus;

  PROCEDURE RemoveSelection* (F: Frame);
  BEGIN
    IF F.hasSel THEN InvertSelection(F, F.selbeg, F.selend); F.hasSel := FALSE END
  END RemoveSelection;

  PROCEDURE SetSelection* (F: Frame; beg, end: LONGINT);  (** forces range to visible bounds **)
    VAR loc: Location;
  BEGIN
    IF end > F.text.len THEN end := F.text.len END;
    IF end > beg THEN
      IF F.hasSel & (F.selbeg.pos = beg) THEN
        IF (F.selend.pos < end) & (F.selend.pos < F.trailer.org) THEN
          LocatePos(F, F.selend.pos, loc); LocatePos(F, end, F.selend); InvertSelection(F, loc, F.selend)
        ELSIF end < F.selend.pos THEN
          LocatePos(F, end, loc); InvertSelection(F, loc, F.selend); LocatePos(F, end, F.selend)
        END
      ELSE RemoveSelection(F); PassSubFocus(F, NIL);
        LocatePos(F, beg, F.selbeg); LocatePos(F, end, F.selend); InvertSelection(F, F.selbeg, F.selend)
      END;
      F.hasSel := TRUE; F.time := Oberon.Time()
    END
  END SetSelection;


  PROCEDURE RemoveCaret* (F: Frame);
    VAR msg: Oberon.ControlMsg;
  BEGIN
    IF F.focus # NIL THEN msg.id := Oberon.defocus; F.focus.handle(F.focus, msg) END;
    IF F.hasCar THEN InvertCaret(F); F.hasCar := FALSE END
  END RemoveCaret;

  PROCEDURE SetCaret* (F: Frame; pos: LONGINT);  (** only done if within visible bounds **)
  BEGIN
    IF ~F.hasCar OR (F.carloc.pos # pos) THEN RemoveCaret(F); PassSubFocus(F, NIL);
      LocatePos(F, pos, F.carloc);
      IF F.carloc.x <= F.X + F.W - F.right THEN InvertCaret(F); F.hasCar := TRUE END
    END
  END SetCaret;


*)
  (** Display Range **)
(*
  PROCEDURE Complete (F: Frame; trailer: TextLine; s: TextLine; org: LONGINT; ph: INTEGER);
    VAR u: TextLine;
  BEGIN
    IF ph > F.bot THEN  (*try to add new lines to the bottom*)
      Texts.OpenReader(R, F.text, org); Texts.Read(R, nextCh);
      LOOP
        IF R.eot THEN EXIT END;
        NEW(u); u.org := org; MeasureLine(F, F.W - F.left - F.right, u);
        IF ph - u.h < F.bot THEN EXIT END;
        s.next := u; s := s.next; DEC(ph, s.h); INC(org, s.span)
      END
    END;
    s.next := trailer; trailer.eot := TRUE; trailer.org := org; trailer.len := 0; trailer.w := 0;
    trailer.h := SHORT(defParc.lsp DIV Unit); trailer.P := P; trailer.pbeg := pbeg
  END Complete;

  PROCEDURE ShowFrom (F: Frame; pos: LONGINT);  (* removes global marks as needed and neutralizes F *)
    VAR new, s: TextLine; beg, end: Location; org: LONGINT; ph, y0, dy: INTEGER;
  BEGIN
    F.handle(F, neutralize);
    IF (F.trailer # NIL) & (F.org < pos) & (pos < F.trailer.org) THEN  (* shift up and extend to the bottom *)
      LocateLineTop(F, F.trailer, pos, beg); LocateLineTop(F, F.trailer, F.trailer.org, end);
      dy := (F.Y + F.H - F.top) - beg.y; Shift(F, end.y, end.y + dy, beg.y - end.y);
      Erase(F, F.X + F.left, end.y, F.W - F.left, dy);
      s := F.trailer.next; WHILE s.org # pos DO s := s.next END;
      F.trailer.next := s; org := s.org + s.span; ph := F.H - F.top - s.h;
      WHILE s.next # F.trailer DO s := s.next; org := org + s.span; ph := ph - s.h END;
      Complete(F, F.trailer, s, org, ph); F.org := pos; ShowLines(F, F.bot, end.y + dy - F.Y, FALSE)
    ELSIF (F.trailer = NIL) OR (pos # F.org) THEN
      MeasureLines(F, pos, new);
      IF (F.trailer # NIL) & (pos < F.org) & (F.org <= new.org) THEN  (* shift down and extend to the top *)
        LocateLineTop(F, new, F.org, beg); LocateLineTop(F, new, new.org, end);
        y0 := F.Y + F.H - F.top; Shift(F, y0 - (beg.y - end.y), end.y, beg.y - end.y);
        Erase(F, F.X + F.left, beg.y, F.W - F.left, y0 - beg.y);
        Erase(F, F.X + F.left, F.Y + F.bot, F.W - F.left, end.y - (F.Y + F.bot));
        F.org := pos; F.trailer := new; ShowLines(F, beg.y - F.Y, F.H - F.top, FALSE)
      ELSE  (* full redisplay *)
        IF F.trailer = NIL THEN Erase(F, F.X, F.Y, F.W, F.H); ShowBar(F, 0, F.H); F.markH := -1
        ELSE Erase(F, F.X + F.left, F.Y + F.bot, F.W - F.left, F.H - F.bot - F.top)
        END;
        F.org := pos; F.trailer := new; ShowLines(F, F.bot, F.H - F.top, FALSE)
      END
    END;
    ShowTick(F)
  END ShowFrom;

  PROCEDURE Show* (F: Frame; pos: LONGINT);  (** removes global marks as needed and neutralizes F **)
  BEGIN BegOfLine(F.text, pos, TRUE); ShowFrom(F, pos)
  END Show;


  PROCEDURE Resize (F: Frame; x, y, w, h: INTEGER);
    VAR oldY, oldH, dh, ph: INTEGER; t: TextLine;
  BEGIN
    IF (w = 0) OR (h = 0) THEN InvalSubFrames(F, F.X, F.Y, F.W, F.H);
      F.X := x; F.Y := y; F.W := w; F.H := h; F.trailer := NIL
    ELSIF (F.trailer # NIL) & (x = F.X) & (w = F.W) THEN
      oldY := F.Y; oldH := F.H; Tick(F); F.markH := -1; F.Y := y; F.H := h;
      IF h > oldH THEN dh := h - oldH;  (* extend *)
        IF y + h # oldY + oldH THEN
          Display.CopyBlock(x, oldY, w, oldH, x, y + dh, Display.replace);
          ShiftSubFrames(F, oldY, y + dh, oldH)
        END;
        EraseRect(F, x, y, w, dh); ShowBar(F, 0, dh);
        t := F.trailer; ph := F.H - F.top;
        WHILE t.next # F.trailer DO t := t.next; ph := ph - t.h END;
        Complete(F, F.trailer, t, F.trailer.org, ph); ShowLines(F, F.bot, ph, FALSE)
      ELSE dh := oldH - h;  (* reduce *)
        IF y + h # oldY + oldH THEN
          Display.CopyBlock(x, oldY + dh, w, h, x, y, Display.replace);
          ShiftSubFrames(F, oldY + dh, y, h)
        END;
        t := F.trailer; ph := F.H - F.top;
        WHILE (t.next # F.trailer) & (ph - t.next.h >= F.bot) DO t := t.next; DEC(ph, t.h) END;
        IF t = F.trailer THEN t.org := F.org; t.span := 0 END;
        Complete(F, F.trailer, t, t.org + t.span, ph);
        EraseRect(F, x + F.left, y, w - F.left, ph);
        InvalSubFrames(F, x, oldY, w, y - oldY); InvalSubFrames(F, x, y + h, w, dh - (y - oldY))
      END;
      ShowTick(F)
    ELSE F.X := x; F.Y := y; F.W := w; F.H := h; F.trailer := NIL; Show(F, F.org)
    END
  END Resize;
  
*)
  (** Contents Update **)
(*
  PROCEDURE Update (F: Frame; VAR msg: UpdateMsg);  (** removes global marks as needed **)
    VAR t: TextLine; org, d, Fbeg, Fend: LONGINT;
      foc: Display.Frame; beg, end: LONGINT; ch: CHAR; r: Texts.Reader; loc: Location;

    PROCEDURE Begin (VAR beg: LONGINT; VAR org0: LONGINT; VAR q: TextLine);
      (* org0 = origin of first affected line; beg = pos of first modified character; q = first affected line (if line origin has not moved).*)
      (* q = NIL => beg = org0; q # NIL => first (beg-org0) characters of q need not be redrawn *)
      VAR trailer, t: TextLine;
    BEGIN
      trailer := F.trailer; t := trailer;
      WHILE (t.next # trailer) & (beg >= t.next.org + t.next.span) & ~t.next.eot DO t := t.next END;
      q := t.next;
      IF (t # trailer) & (q # trailer) & (beg <= q.org + q.span) THEN
        Texts.OpenReader(R, F.text, t.org); Texts.Read(R, nextCh); org0 := t.org; NextLine(F.text, org0)
      ELSE org0 := beg; BegOfLine(F.text, org0, TRUE)
      END;
      IF org0 # q.org THEN
        IF t = trailer THEN org0 := q.org ELSE org0 := t.org END;
        beg := org0; q := NIL
      END
    END Begin;

    PROCEDURE Adjust (end, delta: LONGINT);
      (* H1 = top of synchronization line in old frame *)
      (* h0 = top of line that was modified *)
      (* h1 = top of block in new frame that could be reused *)
      (* h2 = bottom of last line in new frame *)
      (* h1 - h2 = height of block that could be reused *)
      VAR new, old, s, t, u, p, q: TextLine; bot: Location;
        org, org0, beg: LONGINT; ph, h0, h1, H1, h2, lm, dx, dy: INTEGER;
    BEGIN
      q := NIL; LocateLineTop(F, F.trailer, F.trailer.org, bot);
      IF msg.beg < F.org THEN org0 := F.org; beg := org0 ELSE beg := msg.beg; Begin(beg, org0, q) END;
      NEW(new); s := new; old := F.trailer; t := old; org := F.org; ph := F.H - F.top;
      WHILE (t.next # old) & (t.next.org # org0) DO t := t.next;  (*transfer unchanged prefix*)
        s.next := t; s := t; DEC(ph, s.h); INC(org, s.span)
      END;
      h0 := ph; H1 := h0; t := t.next; p := s;
      Texts.OpenReader(R, F.text, org); Texts.Read(R, nextCh);  (*rebuild at least one line descriptor*)
      LOOP NEW(u); u.org := org; MeasureLine(F, F.W - F.left - F.right, u);
        IF ph - u.h < F.bot THEN h1 := ph; h2 := h1; EXIT END;
        s.next := u; s := s.next; DEC(ph, s.h); INC(org, s.span);
        IF R.eot THEN h1 := ph; h2 := h1; EXIT END;
        IF org > end THEN
          WHILE (t # old) & (org > t.org + delta) DO DEC(H1, t.h); t := t.next END;
          IF (org = t.org + delta) & (P = t.P) THEN h1 := ph;  (*resynchronized*)
            WHILE (t # old) & (ph - t.h >= F.bot) DO  (*transfer unchanged suffix*)
              s.next := t; s := t; s.org := org; ParcBefore(F.text, s.org, s.P, s.pbeg);
              DEC(ph, s.h); INC(org, s.span); t := t.next
            END;
            h2 := ph; EXIT
          END
        END
      END;
      Shift(F, F.Y + H1 - (h1 - h2), F.Y + h2, h1 - h2);
      Complete(F, new, s, org, ph); F.trailer := new; t := p.next;
      IF (q # NIL) & (t # F.trailer) & (q.h = t.h) & (q.dsr = t.dsr) & (q.org = t.org) & (q.P = t.P) & (end <= t.org + t.span) THEN
        P := t.P; pbeg := t.pbeg;
        IF (P.opts * AdjMask = {leftAdj}) OR (P.opts * AdjMask = AdjMask) & (q.nob = 0) & (t.nob = 0) THEN
          Width(F, t, beg, lm, dx, dy);  (*preserve prefix of first affected line*)
          DEC(h0, t.h); Erase(F, F.X + lm, F.Y + h0, F.W - lm, t.h);
          ShowLine(F, t, F.X + lm, F.X + F.W - F.right, F.Y + h0)
        END
      END;
      ShowLines(F, h1, h0, TRUE);
      Erase(F, F.X + F.left, bot.y, F.W - F.left, h2 - (bot.y - F.Y)); ShowLines(F, F.bot, h2, FALSE)
    END Adjust;

  BEGIN
    foc := F.focus; beg := msg.beg; end := msg.end; 
    F.handle(F, neutralize); MarkMenu(F); Fbeg := F.org; Fend := F.trailer.org;
    IF (msg.id = Texts.insert) & (msg.beg < F.org) THEN t := F.trailer; d := msg.end - msg.beg; INC(F.org, d);
      REPEAT INC(t.org, d); t := t.next UNTIL t = F.trailer
    ELSIF msg.id = Texts.delete THEN
      IF msg.end <= F.org THEN t := F.trailer; d := msg.end - msg.beg; DEC(F.org, d);
        REPEAT DEC(t.org, d); t := t.next UNTIL t = F.trailer
      ELSIF msg.beg < F.org THEN F.org := msg.beg
      END
    END;
    org := F.org;
    IF msg.beg <= Fbeg + AdjustSpan THEN BegOfLine(F.text, org, TRUE) END;
    ParcBefore(F.text, org, P, d);
    IF (org # F.org) OR (P # F.trailer.next.P) THEN
      F.trailer := NIL; Show(F, F.org)
    ELSIF (msg.end > Fbeg) & (msg.beg < Fend + AdjustSpan) THEN
      IF msg.id = Texts.replace THEN Adjust(msg.end, 0);
        (* refocus element if necessary *)
        IF (foc # NIL) & (end-beg = 1) THEN
          Texts.OpenReader(r, F.text, beg); Texts.Read(r, ch);
          IF r.elem # NIL THEN
            LocatePos(F, beg, loc); foc := ThisSubFrame(F, loc.x, loc.y); PassSubFocus(F, foc);
          END
        END
      ELSIF msg.id = Texts.insert THEN Adjust(msg.end, msg.end - msg.beg)
      ELSIF msg.id = Texts.delete THEN Adjust(msg.beg, msg.beg - msg.end)
      END
    END;
    ShowTick(F)
  END Update;

*)
  (** User Interface **)
(*
  PROCEDURE Back (F: Frame; dY: INTEGER; (*inout*) VAR org: LONGINT);  (* mh 10.10.92 *)
    (* computes new org such that old org is (at most) dY pixels below new org *)
    VAR H: INTEGER; oldOrg: LONGINT;

    PROCEDURE TotalHeight (org1, org2: LONGINT): INTEGER;
      (* measures total height of text-lines starting at org1 and ending at the line before the line containing org2 *) 
      VAR h: INTEGER; line: TextLine;
    BEGIN
      Texts.OpenReader(R, F.text, org1); Texts.Read(R, nextCh); NEW(line); h := 0;
      LOOP line.org := org1;
        MeasureLine(F, F.W - F.left - F.right, line); INC(org1, line.span);
        IF Texts.Pos(R)-1 > org2 THEN EXIT END;
        INC(h, line.h);
        IF R.eot THEN EXIT END;
      END;
      RETURN h
    END TotalHeight;

    PROCEDURE Forward (h: INTEGER);
      (* increase org by n text-lines such that the sum of the n line-heights > h *)
      VAR line: TextLine;
    BEGIN
      Texts.OpenReader(R, F.text, org); Texts.Read(R, nextCh); NEW(line);
      WHILE h > 0 DO line.org := org;
        MeasureLine(F, F.W - F.left - F.right, line); INC(org, line.span); DEC(h, line.h);
      END;
      org := Texts.Pos(R)-1;
    END Forward;

  BEGIN H := 0;
    LOOP oldOrg := org;
      IF org = 0 THEN EXIT END;
      DEC(org, 800); BegOfLine(F.text, org, FALSE);
      INC(H, TotalHeight(org, oldOrg));
      IF H > dY THEN EXIT END;
    END;
    Forward(H - dY);
  END Back;

  PROCEDURE TrackLine* (F: Frame; VAR x, y: INTEGER; VAR org: LONGINT; VAR keysum: SET);
    VAR keys: SET; new, old: Location;
  BEGIN
    LocateLine(F, y, old); InvertRect(F, old.x, old.y, old.dx + 4, 2); keysum := {};
    REPEAT TrackMouse(x, y, keys, keysum); LocateLine(F, y, new);
      IF new.org # old.org THEN
        InvertRect(F, new.x, new.y, new.dx + 4, 2); InvertRect(F, old.x, old.y, old.dx + 4, 2); old := new
      END
    UNTIL keys = {};
    InvertRect(F, new.x, new.y, new.dx + 4, 2); org := new.org
  END TrackLine;

  PROCEDURE TrackWord* (F: Frame; VAR x, y: INTEGER; VAR pos: LONGINT; VAR keysum: SET);
    VAR keys: SET; new, old: Location;
  BEGIN 
    LocateWord(F, x, y, old); InvertRect(F, old.x, old.y, old.dx, 2); keysum := {};
    REPEAT TrackMouse(x, y, keys, keysum); LocateWord(F, x, y, new);
      IF new.pos # old.pos THEN
        InvertRect(F, new.x, new.y, new.dx, 2); InvertRect(F, old.x, old.y, old.dx, 2); old := new
      END
    UNTIL keys = {};
    InvertRect(F, new.x, new.y, new.dx, 2); pos := new.pos
  END TrackWord;

  PROCEDURE TrackCaret* (F: Frame; VAR x, y: INTEGER; VAR keysum: SET);
    VAR keys: SET;
  BEGIN keysum := {};
    REPEAT TrackMouse(x, y, keys, keysum); SetCaret(F, Pos(F, x, y)) UNTIL keys = {}
  END TrackCaret;

  PROCEDURE TrackSelection* (F: Frame; VAR x, y: INTEGER; VAR keysum: SET);
    VAR keys: SET; pos: LONGINT; V: Viewers.Viewer; f: Frame;
  BEGIN
    V := Viewers.This(F.X, F.Y); V := V.next(Viewers.Viewer);
    IF (V.dsc # NIL) & (V.dsc.next # NIL) & (V.dsc.next IS Frame) THEN f := V.dsc.next(Frame);
      IF f.hasSel & (f.text = F.text) THEN
        IF (f.selbeg.pos < f.trailer.org) & (f.org < f.selend.pos) & (f.selbeg.pos <= Pos(F, x, y)) THEN
          SetSelection(F, f.selbeg.pos, Pos(F, x, y) + 1)
        ELSE RemoveSelection(f); f := NIL
        END
      ELSE f := NIL
      END
    ELSE f := NIL
    END;
    IF f = NIL THEN
      IF F.hasSel & (F.selbeg.pos + 1 = F.selend.pos) & (Pos(F, x, y) = F.selbeg.pos) THEN
        SetSelection(F, F.selbeg.org, Pos(F, x, y) + 1)
      ELSE SetSelection(F, Pos(F, x, y), Pos(F, x, y) + 1)
      END
    END;
    keysum := {};
    REPEAT TrackMouse(x, y, keys, keysum);
      IF F.hasSel THEN
        pos := Pos(F, x, Min(y, F.selbeg.y)) + 1;
        IF pos <= F.selbeg.pos THEN pos := F.selbeg.pos + 1 END;
        SetSelection(F, F.selbeg.pos, pos);
        IF f # NIL THEN SetSelection(f, f.selbeg.pos, pos); f.selend.pos := F.selend.pos END
      ELSE SetSelection(F, Pos(F, x, y), Pos(F, x, y) + 1)
      END
    UNTIL keys = {};
    IF f # NIL THEN F.selbeg.pos := f.selbeg.pos END
  END TrackSelection;

  PROCEDURE Call (F: Frame; pos: LONGINT; keysum: SET);
    VAR S: Texts.Scanner; res, i, j: INTEGER;
  BEGIN
    Texts.OpenScanner(S, F.text, pos); Texts.Scan(S);
    IF (S.class = Texts.Name) & (S.line = 0) THEN i := 0;
      WHILE (i < S.len) & (S.s[i] # ".") DO INC(i) END;
      j := i + 1;
      WHILE (j < S.len) & (S.s[j] # ".") DO INC(j) END;
      IF (j >= S.len) & (S.s[i] = ".") OR (rightKey IN keysum) THEN
        par.vwr := Viewers.This(F.X, F.Y);
        IF rightKey IN keysum THEN S.s:="Edit.Open"; par.pos := pos ELSE par.pos := pos + S.len END;
        par.frame := F; par.text := F.text; Oberon.Call(S.s, par, keysum = {middleKey, leftKey}, res);
        IF res > 0 THEN
          Texts.WriteString(W0, "Call error: "); Texts.WriteString(W0, Modules.importing);
          IF res = 1 THEN
            Texts.WriteString(W0, " not found")
          ELSIF res = 2 THEN
            Texts.WriteString(W0, " not an obj-file")
          ELSIF res = 3 THEN
            Texts.WriteString(W0, " imports ");
            Texts.WriteString(W0, Modules.imported); Texts.WriteString(W0, " with bad key");
          ELSIF res = 4 THEN
            Texts.WriteString(W0, " corrupted obj file")
          ELSIF res = 6 THEN
            Texts.WriteString(W0, " has too many imports")
          ELSIF res = 7 THEN
            Texts.WriteString(W0, " not enough space")
          END
        ELSIF res < 0 THEN
          INC(i); WHILE i < S.len DO Texts.Write(W0, S.s[i]); INC(i) END;
          Texts.WriteString(W0, " not found")
        END;
        IF res # 0 THEN Texts.WriteLn(W0); Texts.Append(Oberon.Log, W0.buf) END
      END
    END
  END Call;

  PROCEDURE PickAttributes (VAR W: Texts.Writer; T: Texts.Text; pos: LONGINT; font: Fonts.Font; col, voff: SHORTINT);
    VAR R: Texts.Reader; ch: CHAR;
  BEGIN
    IF T.len > 0 THEN
      IF pos < T.len THEN Texts.OpenReader(R, T, pos); Texts.Read(R, ch) END;
      IF (pos > 0) & ((pos = T.len) OR (ch <= " ")) THEN
        Texts.OpenReader(R, T, pos - 1); Texts.Read(R, ch)
      END;
      Texts.SetFont(W, R.fnt); Texts.SetColor(W, R.col);
      IF (ch = CR) OR (ch = TAB) OR (ch = LF) THEN Texts.SetOffset(W, voff) ELSE Texts.SetOffset(W, R.voff) END
    ELSE Texts.SetFont(W, font); Texts.SetColor(W, col); Texts.SetOffset(W, voff)
    END
  END PickAttributes;

  PROCEDURE ShiftBlock (F: Frame; delta: INTEGER);  (* shift selected lines to left or right *)
    VAR text: Texts.Text; pos, beg, end, time: LONGINT; select: SelectMsg; ch: CHAR;
  BEGIN
    Oberon.GetSelection(text, beg, end, time);
    IF (time >= 0) & (text = F.text) THEN BegOfLine(F.text, beg, FALSE); pos := beg;
      WHILE pos < end DO Texts.OpenReader(R, F.text, pos); Texts.Read(R, ch);
        WHILE (R.elem # NIL) & (R.elem IS Parc) & (pos < end) DO Texts.Read(R, ch); INC(pos) END;
        IF pos < end THEN
          IF delta < 0 THEN
            IF (ch <= " ") & (ch # CR) & (ch # Texts.ElemChar) THEN
              Texts.Delete(F.text, pos, pos + 1); DEC(end)
            END
          ELSE
            PickAttributes(W, text, pos, Oberon.CurFnt, Oberon.CurCol, Oberon.CurOff);
            IF (ch <= " ") & (ch # CR) & (ch # Texts.ElemChar) THEN Texts.Write(W, ch)  (* first char extension *)
            ELSE Texts.Write(W, TAB)
            END;
            Texts.Insert(F.text, pos, W.buf); INC(end); INC(pos)
          END;
          Texts.OpenReader(R, F.text, pos);
          REPEAT Texts.Read(R, ch) UNTIL R.eot OR (ch = CR);
          pos := Texts.Pos(R)
        END
      END;
      select.text := F.text; select.beg := beg; select.end := pos; select.time := Oberon.Time();
      Viewers.Broadcast(select)
    END
  END ShiftBlock;

  PROCEDURE Write (F: Frame; ch: CHAR; fnt: Fonts.Font; col, voff: SHORTINT);
    VAR loc: Location; parc: Parc; org, pos, pbeg: LONGINT; i: INTEGER; ch0: CHAR;
      buf: ARRAY 32 OF CHAR;
      copy: Texts.CopyMsg; input: Oberon.InputMsg;

    PROCEDURE Visible(ch: CHAR): BOOLEAN;
      VAR pat: Display.Pattern; dx, x, y, w, h: INTEGER;
    BEGIN Display.GetChar(W.fnt.raster, ch, dx, x, y, w, h, pat); RETURN dx > 0
    END Visible;

    PROCEDURE InsertBuffer;
      VAR i, j: INTEGER; ch: CHAR;
    BEGIN i := 0; j := 0; ch := buf[i];
      WHILE ch # 0X DO
        IF (ch = TAB) OR (ch = CR) OR (ch = " ") OR Visible(ch) THEN Texts.Write(W, ch); INC(j) END;
        INC(i); ch := buf[i]
      END; 
      IF j > 0 THEN Texts.Insert(F.text, pos, W.buf); INC(pos, LONG(j)) END
    END InsertBuffer;

    PROCEDURE Flush;
      VAR ch: CHAR;
    BEGIN
      WHILE Input.Available() > 0 DO Input.Read(ch) END
    END Flush;
    
  BEGIN
    IF F.hasSel & (ch = CRSL) THEN ShiftBlock(F, -1)
    ELSIF F.hasSel & (ch = CRSR) THEN ShiftBlock(F, 1)
    ELSIF F.hasCar THEN pos := F.carloc.pos;
      IF (ch = DEL) & (pos > F.org) THEN DEC(pos); Texts.Delete(F.text, pos, pos + 1); Flush
      ELSIF (ch = CRSL) & (pos > 0) THEN DEC(pos)
      ELSIF (ch = CRSR) & (pos < F.text.len) THEN INC(pos)
      ELSIF (ch = BRK) OR (ch = ShiftBRK) THEN
        ParcBefore(F.text, pos, P, pbeg); P.handle(P, copy); parc := copy.e(Parc);
        IF ch = BRK THEN EXCL(parc.opts, pageBreak) ELSE INCL(parc.opts, pageBreak) END;
        PickAttributes(W, F.text, pos, fnt, col, voff);
        Texts.WriteElem(W, parc); Texts.Insert(F.text, pos, W.buf); INC(pos)
      ELSIF (ch = TAB) OR (ch = LF) OR (ch = CR) OR (ch >= " ") THEN
        PickAttributes(W, F.text, pos, fnt, col, voff);
        IF ch = LF THEN buf[0] := CR; i := 1; org := F.carloc.org; BegOfLine(F.text, org, FALSE);
          Texts.OpenReader(R, F.text, org);
          REPEAT Texts.Read(R, ch) UNTIL (R.elem = NIL) OR ~(R.elem IS Parc);
          WHILE (Texts.Pos(R) <= pos) & (ch <= " ") & (ch # Texts.ElemChar) & (i < 31) DO
            buf[i] := ch; INC(i); Texts.Read(R, ch)
          END
        ELSE buf[0] := ch; i := 1
        END;
        WHILE (Input.Available() > 0) & (i < 31) & (ch >= " ") & (ch < DEL) DO Input.Read(buf[i]); INC(i) END;
        buf[i] := 0X; InsertBuffer
      END;
      IF pos < F.org THEN Show(F, F.org - 1)
      ELSIF pos < F.text.len THEN org := -1;
        WHILE (pos >= F.trailer.org) & (pos > F.org) DO
          org := F.trailer.next.next.org; IF org = F.org THEN INC(org) END;
          ShowFrom(F, org); Flush
        END
      ELSE LocatePos(F, pos, loc); LocateChar(F, loc.x + 1, loc.y, loc);
        IF pos # loc.pos THEN Show(F, F.trailer.next.next.org); Flush END
      END;
      SetCaret(F, pos)
    ELSIF F.focus # NIL THEN input.id := Oberon.consume; input.ch := ch;
      input.fnt := fnt; input.col := col; input.voff := voff; F.focus.handle(F.focus, input)
    END
  END Write;


  PROCEDURE TouchElem (F: Frame; VAR x, y: INTEGER; VAR keysum: SET);
    VAR loc: Location; e: Texts.Elem; pbeg: LONGINT; y0: INTEGER;
      track: TrackMsg;
  BEGIN
    LocateChar(F, x, y, loc); e := R.elem;
    IF (e # NIL) & (loc.x + e.W DIV Unit <= F.X + F.W - F.right) THEN
      ParcBefore(F.text, loc.pos, P, pbeg); y0 := loc.y + loc.line.dsr - SHORT(P.dsr DIV Unit) + loc.dy;
      IF (loc.x <= x) & (x < loc.x + e.W DIV Unit) & (keysum= {middleKey}) THEN
        track.X := x; track.Y := y; track.keys := keysum;
        track.fnt := R.fnt; track.col := R.col; track.pos := Texts.Pos(R) - 1;
        track.frame := F; track.X0 := loc.x; track.Y0 := y0;
        e.handle(e, track); keysum := {}
      END
    END
  END TouchElem;


  PROCEDURE Edit (F: Frame; x, y: INTEGER; keysum: SET);
    VAR ef: Display.Frame; text: Texts.Text; beg, end, time, pos: LONGINT; keys: SET; ch: CHAR;
      loc: Location; delta: INTEGER; copyover: Oberon.CopyOverMsg; input: Oberon.InputMsg;
  BEGIN
    IF x < F.X + F.barW THEN pos := F.org;  (* scroll bar *)
      IF leftKey IN keysum THEN TrackLine(F, x, y, pos, keysum)
      ELSIF rightKey IN keysum THEN TrackLine(F, x, y, pos, keysum); LocateLine(F, y, loc);
        pos := F.org; delta := loc.y - (F.Y + F.bot); Back(F, delta, pos)
      ELSIF middleKey IN keysum THEN
        REPEAT TrackMouse(x, y, keys, keysum) UNTIL keys = {};
        IF keysum = {middleKey, leftKey} THEN pos := F.text.len; (*BegOfLine(F.text, pos, TRUE);*)
          Back(F, F.H - F.bot - F.top - 30 (*heuristic*), pos);
        ELSIF keysum = {middleKey, rightKey} THEN pos := 0
        ELSIF (F.Y <= y) & (y <= F.Y + F.H) THEN pos := CoordToPos(F, y - F.Y); BegOfLine(F.text, pos, TRUE)
        END
      ELSE DrawCursor(x, y); keysum := cancel
      END;
      IF keysum # cancel THEN ShowFrom(F, pos) END
    ELSE  (* text area *)
      ef := ThisSubFrame(F, x, y);
      IF ef # NIL THEN  (* within sub-frame *)
        IF (F.focus # ef) & (keysum = {leftKey}) THEN
          REPEAT TrackMouse(x, y, keys, keysum) UNTIL keys = {};
          IF keysum = {leftKey} THEN RemoveSelection(F); RemoveCaret(F); PassSubFocus(F, ef); RETURN END
        ELSIF F.focus = ef THEN input.id := Oberon.track; input.keys := keysum; input.X := x; input.Y := y;
          ef.handle(ef, input); RETURN
        END
      END;
      IF keysum # {} THEN TouchElem(F, x, y, keysum);
        IF keysum = {} THEN RETURN END
      END;
      IF leftKey IN keysum THEN Oberon.PassFocus(Viewers.This(F.X, F.Y)); TrackCaret(F, x, y, keysum);
        IF (keysum = {leftKey, middleKey}) & F.hasCar THEN Oberon.GetSelection(text, beg, end, time);
          IF time >= 0 THEN Texts.Save(text, beg, end, B);
            Texts.Insert(F.text, F.carloc.pos, B); SetCaret(F, F.carloc.pos + (end - beg))
          END
        ELSIF (keysum = {leftKey, rightKey}) & F.hasCar & (F.carloc.pos < F.text.len) THEN
          Oberon.GetSelection(text, beg, end, time);
          IF time >= 0 THEN Texts.OpenReader(R, F.text, F.carloc.pos); Texts.Read(R, ch);
            Texts.ChangeLooks(text, beg, end, {0, 1, 2}, R.fnt, R.col, R.voff)
          END
        END
      ELSIF middleKey IN keysum THEN TrackWord(F, x, y, pos, keysum);
        IF keysum # cancel THEN Call(F, pos, keysum) END
      ELSIF rightKey IN keysum THEN TrackSelection(F, x, y, keysum);
        IF (keysum = {rightKey, middleKey}) & F.hasSel THEN
          copyover.text := F.text; copyover.beg := F.selbeg.pos; copyover.end := F.selend.pos;
          Oberon.FocusViewer.handle(Oberon.FocusViewer, copyover)
        ELSIF (keysum = {rightKey, leftKey}) & F.hasSel THEN Oberon.PassFocus(Viewers.This(F.X, F.Y));
          Texts.Delete(F.text, F.selbeg.pos, F.selend.pos); SetCaret(F, F.selbeg.pos)
        END
      ELSE DrawCursor(x, y)
      END
    END
  END Edit;

*)
  (** General **)


  PROCEDURE Copy (SF, DF: Frame);
  BEGIN
    DF.handle := SF.handle; DF.text := SF.text; DF.org := SF.org;
    DF.col := SF.col; DF.left := SF.left; DF.right := SF.right; DF.top := SF.top; DF.bot := SF.bot;
    DF.barW := SF.barW; DF.hasCar := FALSE; DF.hasSel := FALSE; DF.showsParcs := SF.showsParcs;
    DF.focus := NIL; DF.trailer := NIL
  END Copy;
(*
  PROCEDURE Handle* (f: Display.Frame; VAR msg: Display.FrameMsg);
    VAR F, F1: Frame; pos: LONGINT;
  BEGIN F := f(Frame);
    IF msg IS Oberon.InputMsg THEN
      WITH msg: Oberon.InputMsg DO
        IF msg.id = Oberon.consume THEN Write(F, msg.ch, msg.fnt, msg.col, msg.voff)
        ELSIF msg.id = Oberon.track THEN Edit(F, msg.X, msg.Y, msg.keys)
        END
      END
    ELSIF msg IS Oberon.ControlMsg THEN
      WITH msg: Oberon.ControlMsg DO
        IF msg.id = Oberon.defocus THEN RemoveCaret(F)
        ELSIF msg.id = Oberon.neutralize THEN
          RemoveCaret(F); RemoveSelection(F); PassSubFocus(F, NIL); NotifySubFrames(F, msg)
        ELSE NotifySubFrames(F, msg)
        END
      END
    ELSIF msg IS Oberon.CopyMsg THEN
      WITH msg: Oberon.CopyMsg DO
        IF msg.F = NIL THEN NEW(F1); msg.F := F1 END;
        Copy(F, msg.F(Frame))
      END
    ELSIF msg IS UpdateMsg THEN NotifySubFrames(F, msg);
      WITH msg: UpdateMsg DO
        IF msg.text = F.text THEN Update(F, msg) END
      END
    ELSIF msg IS InsertElemMsg THEN
      IF F.hasCar THEN pos := F.carloc.pos;
        PickAttributes(W, F.text, pos, Oberon.CurFnt, Oberon.CurCol, Oberon.CurOff);
        Texts.WriteElem(W, msg(InsertElemMsg).e);
        Texts.Insert(F.text, pos, W.buf);
        SetCaret(F, pos + 1)
      END
    ELSIF msg IS Oberon.SelectionMsg THEN NotifySubFrames(F, msg);
      WITH msg: Oberon.SelectionMsg DO
        IF F.hasSel & (F.time > msg.time) THEN
          msg.text := F.text; msg.beg := F.selbeg.pos; msg.end := F.selend.pos; msg.time := F.time
        END
      END
    ELSIF msg IS Oberon.CopyOverMsg THEN NotifySubFrames(F, msg);
      WITH msg: Oberon.CopyOverMsg DO
        IF F.hasCar THEN Texts.Save(msg.text, msg.beg, msg.end, B);
          Texts.Insert(F.text, F.carloc.pos, B); SetCaret(F, F.carloc.pos + (msg.end - msg.beg))
        END
      END
    ELSIF msg IS MenuViewers.ModifyMsg THEN
      WITH msg: MenuViewers.ModifyMsg DO
        F.handle(F, neutralize); Resize(F, F.X, msg.Y, F.W, msg.H)
      END
    ELSIF msg IS SelectMsg THEN NotifySubFrames(F, msg);
      WITH msg: SelectMsg DO
        IF (msg.text = F.text) & ~F.hasSel THEN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);
          F.handle(F, neutralize);
          SetSelection(F, msg.beg, msg.end); F.time := msg.time;
          IF F.hasSel THEN F.selbeg.pos := msg.beg; F.selend.pos := msg.end END
        END
      END
    ELSE NotifySubFrames(F, msg)
    END
  END Handle;

*)
  PROCEDURE Open* (F: Frame; T: Texts.Text; pos: LONGINT);
  BEGIN
    F.handle := Handle; F.text := T; F.org := pos; F.col := Display.black;
    F.left := left; F.right := right; F.top := top; F.bot := bot;
    F.barW := barW; F.hasCar := FALSE; F.hasSel := FALSE; F.showsParcs := FALSE; F.trailer := NIL
  END Open;

(*
  PROCEDURE NotifyDisplay* (T: Texts.Text; op: INTEGER; beg, end: LONGINT);
    VAR msg: UpdateMsg;
  BEGIN
    msg.text := T; msg.id := op; msg.beg := beg; msg.end := end; Viewers.Broadcast(msg)
  END NotifyDisplay;

  PROCEDURE Text* (name: ARRAY OF CHAR): Texts.Text;
    VAR text: Texts.Text;
  BEGIN
    NEW(text); Texts.Open(text, name); text.notify := NotifyDisplay; RETURN text
  END Text;
*)
  PROCEDURE NewText* (T: Texts.Text; pos: LONGINT): Frame;
    VAR frame: Frame;
  BEGIN
    NEW(frame); Open(frame, T, pos);
    RETURN frame
  END NewText;
(*
  PROCEDURE NewMenu* (name, commands: ARRAY OF CHAR): Frame;
    VAR T: Texts.Text; frame: Frame;
  BEGIN
    T := Text("");
    Texts.WriteString(W0, name); Texts.WriteString(W0, " | "); Texts.WriteString(W0, commands);
    Texts.Append(T, W0.buf);
    NEW(frame); Open(frame, T, 0);
    frame.col := Display.white; frame.left := 6; frame.top := 0; frame.bot := 0; frame.barW := 0;
    RETURN frame
  END NewMenu;
*)
BEGIN
  Texts.OpenWriter(W); Texts.OpenWriter(W0);
  Texts.SetFont(W0, Fonts.Default); Texts.SetColor(W0, Display.white); Texts.SetOffset(W0, 0);
  neutralize.id := Oberon.neutralize;
  NEW(par);
  NEW(B); Texts.OpenBuf(B);
  menuH := Fonts.Default.height + 2;
  barW := 14; left := barW + 6; right := 8; top := 6; bot := 6;
  Oberon.Log := Text("");
  InitDefParc
END TextFrames.
