MODULE Viewer;   (* :file: Viewer.Mod  --  Text Viewer. *)
(* VOC adaptation, 2026-10-16: fixed-width types and the VOC system adapter. *)
IMPORT ssqTypes, Sys := ssqSys, Char, Int, Str, Path, String, Line, Dot, Kbd, Text;
(* Dome error fasm lisp petline *)

(* ------------------------------------------------------------------------- *)
(* :section:     constants *)
CONST
        CursorActive   = 1;                     (* cursor style *)
        CursorPassive  = 2;
        CursorReadOnly = 3;

        MdOk*           =   1;                  (* screen mode *)
        MdExit*         =  99;                  (* just save and exit *)
        MdChangeFile *  = 999;                  (* exit viewer and select an other file *)
        MdTextContents* = 998;                  (* exit viewer and show text contents *)

        NormalMode    = 1;
        InsertMode    = 2;
        OverwriteMode = 3;

        LinesSelected = 1;                                                      (* #SEL *)
        WordsSelected = 2;                                                      (* #SEL *)

        ScTop   =  1;                           (* scroll-to Top: PROCEDURE  *)
        ScOne   =  2;                           (*           One: chapter,.. *)
        ScMid   =  3;                           (*           Mid: _xmark ,.. *)

        FlipColumn   =  4;
        ScrollColumn = 64;
        RulerColumn  = 79;
        TabSize      =  8;


(* ------------------------------------------------------------------------- *)
(* :section:     types *)
TYPE
        INTEGER = ssqTypes.Integer;
        Frame*    = POINTER TO FrameDesc;
        FrameDesc = RECORD
                       x*: INTEGER;
                       y*: INTEGER;
                       h*: INTEGER;
                       w*: INTEGER;
                       moved*: BOOLEAN;
                    END;

        Pos*    = POINTER TO PosDesc;
        PosDesc = RECORD
                     x0* : INTEGER;
                     y0* : INTEGER;
                     cx* : INTEGER;
                     cy* : INTEGER;
                  END;

        Screen* = POINTER TO ScreenDesc;
        ScreenDesc = RECORD
                      name*:  Line.T;
                      f*:     Frame;
                      t*:     Text.T;
                      p*:     Pos;
                      next*:  Screen;
                   END;

        Cmt = RECORD
                 long  : BOOLEAN;                       (* line comment '#...' or long comment '/* ... */' *)
                 len   : INTEGER;                       (* 1 or 2 characters indicating comment start *)
                 c1,c2 : CHAR;
              END;

        LastDoProc = PROCEDURE (f:Frame; t:Text.T; p:Pos);


(* ------------------------------------------------------------------------- *)
(* :section:     vars *)
VAR
        exitOnIterfile*   : BOOLEAN;                    (* module parameter *)
        currentSearchStr* : ARRAY 32 OF CHAR;           (* from commandline argv or B1-doubleclick *)
        
        xw, xh        : INTEGER;                        (* xterm width height *)
        keyinfo       : ARRAY 32 OF CHAR;               (* about which key was read *)
        info          : ARRAY 256 OF CHAR;              (* about what command to do *)
        activeScreen  : Line.T;                         (* name of active screen *)
        PattChapter, PattSection, PattProc, PattXMark: ARRAY 32 OF CHAR;
        PattConst, PattType, PattVar, PattBegin: ARRAY 32 OF CHAR;
        mode          : INTEGER;                        (* NormaMode InsertMode ... *)

        B1Drag        : BOOLEAN;
        B1On, B3On    : BOOLEAN;                        (* chorded mouse: B1-On: B1 is down, now B3 *)
        B1Double      : BOOLEAN;                        (* is B1 a double click ? *)
        dragStart, dragEnd: INTEGER;
        lastcy        : INTEGER;                        (* cy of last B1 *)
        lastB1Time    : INTEGER;
        lastdo        : LastDoProc;

        selectionOn   : BOOLEAN;                                                          (* #SEL *)
        selectedWords : Line.T;                         (* hmm, selected words *)         (* #SEL *)
        selectedText  : Text.T;                         (* well, yes, selected Text *)    (* #SEL *)
        selectedLinesStart, selectedLinesEnd: INTEGER;                                    (* #SEL *)
        selectionType : INTEGER;                                                          (* #SEL *)

        cmt: Cmt;
        lastfChar     : CHAR;

        vimselFilename: ARRAY 64 OF CHAR;


(* ------------------------------------------------------------------------- *)
(* :chapter: LIB *)
PROCEDURE cout(c: CHAR);
BEGIN Sys.OutChr (c) END cout;

PROCEDURE out(a: ARRAY OF CHAR);
BEGIN Sys.Out (a) END out;

PROCEDURE lout(l: Line.T);
BEGIN Sys.Out (l^) END lout;

PROCEDURE iout(i: INTEGER);
VAR a: ARRAY 32 OF CHAR;
BEGIN
  Int.Show (a, i, 0);
  out (a);
END iout;

PROCEDURE cr;
BEGIN cout (0DX); END cr;

PROCEDURE lf;
BEGIN cout (0DX); cout (0AX) END lf;

PROCEDURE spc;
BEGIN cout (" ") END spc;

PROCEDURE Info(a: ARRAY OF CHAR);
BEGIN COPY (a, info) END Info;

PROCEDURE DotTime;
VAR
   hh,mm,ss: INTEGER;
   a: ARRAY 32 OF CHAR;
BEGIN
   Sys.TimeValues (hh,mm,ss, Sys.Time());
   Int.Show00 (a, hh); out (a); cout (':');
   Int.Show00 (a, mm); out (a); cout (':');
   Int.Show00 (a, ss); out (a);
END DotTime;

PROCEDURE MicroPause;
VAR p: INTEGER;
BEGIN
  IF xw <= 112 THEN 
     p := 1000
  ELSE p := 4000
  END;
  Sys.NanoSleep (0,p);
  IF Kbd.HasKey() THEN Sys.NanoSleep (0,p) END;
END MicroPause;

PROCEDURE DotHasKey;
BEGIN  IF Kbd.HasKey() THEN cout("W") ELSE cout("-") END END DotHasKey;

PROCEDURE Break (mess: ARRAY OF CHAR);
BEGIN
   Dot.At (1,1);
   Dot.Errmess ("BREAK (Sleeping 5 sec)  ");
   Dot.Errmess (mess);
   Sys.Sleep (5000);
   Sys.XtermStd;
   Dot.SetWindowTitle (Sys.pwd);
   Dot.Lf;
   Dot.Errmess ("BREAK (Sleeping 5 sec)  ");
   Dot.Errmess (mess);
   Dot.Error   ("Break");
END Break;

PROCEDURE Assert (b: BOOLEAN; mess: ARRAY OF CHAR);
BEGIN
   IF ~b THEN
      Dot.At (1,1);
      Dot.Errmess ("Viewer.Assert (Sleeping 5 sec)  ");
      Dot.Errmess (mess);
      Sys.Sleep (5000);
      Sys.XtermStd;
      Dot.SetWindowTitle (Sys.pwd);
      Dot.Lf;
      Dot.Errmess ("Viewer.Assert (Sleeping 5 sec)  ");
      Dot.Errmess (mess);
      Dot.Error   ("Viewer.Assert");
   END;
END Assert;

PROCEDURE IsAboveFrame (f:Frame; p:Pos): BOOLEAN;
BEGIN
   RETURN p.cy < p.y0
END IsAboveFrame;

PROCEDURE IsBelowFrame (f:Frame; p:Pos): BOOLEAN;
BEGIN
   RETURN p.cy > (p.y0 + f.h - 1)
END IsBelowFrame;

PROCEDURE IsWithinFrame (f:Frame; p:Pos): BOOLEAN;
BEGIN
   RETURN ~IsAboveFrame (f,p) & ~ IsBelowFrame (f,p)
END IsWithinFrame;

PROCEDURE ScrollCyToBottom (f: Frame; p:Pos);
BEGIN
   p.y0 := p.cy - f.h + 1
END ScrollCyToBottom;

PROCEDURE MayJmpToLastline (t:Text.T; p:Pos);
BEGIN
   p.cy := Int.ShortMin (p.cy, Text.Length (t) - 1)
END MayJmpToLastline;

PROCEDURE ScTo (f:Frame; t:Text.T; p:Pos; scDest: INTEGER);     (* ScrollTo *)
BEGIN
   IF (p.y0 = 0) & (p.cy = 0) & (p.cx = 0) THEN
      (* no prev found *)
   ELSIF (p.cy = Text.Length (t) - 1) & (p.cx = 0) THEN
      (* no next found *)
   ELSE
      CASE scDest OF
       ScTop:  p.cy := p.y0
      | ScOne: p.y0 := Int.ShortMax (0, p.y0 - 1); p.cy := p.y0 + 1
      | ScMid: p.cy := p.y0; p.y0 := Int.ShortMax (0, p.y0 - f.h DIV 2)
      ELSE Dot.SWW ("Viewer.ScTo: no such ScDest")
      END;
   END;
   f.moved := TRUE;
END ScTo;

PROCEDURE IsContFile (t: Text.T): BOOLEAN;
VAR name: Line.T;
BEGIN
   name := Text.Name (t);
   RETURN name^ = "textcontents"
END IsContFile;

PROCEDURE IsPetFiles (t: Text.T): BOOLEAN;
VAR name: Line.T;
BEGIN
   name := Text.Name (t);
   RETURN name^ = ".petfiles"
END IsPetFiles;


(* ------------------------------------------------------------------------- *)
(* :chapter: SELECTION *)
PROCEDURE SelectLines (f:Frame; t:Text.T; p:Pos);                               (* #SEL *)
VAR
   a: ARRAY 32 OF CHAR;
   b: ARRAY 32 OF CHAR;
   start,end: INTEGER;
BEGIN
   a := "SelectLines ";
   start := lastcy;
   end   := p.cy + 1;
   IF start < end THEN
      Text.CopyLines (selectedText, t, start, end, "selectedText");
      Int.Show (b, start, 3); Str.Append (a, b);
      Int.Show (b, end, 3); Str.Append (a, b);
      selectionOn := TRUE;
      selectionType := LinesSelected;
      selectedLinesStart := start;
      selectedLinesEnd   := end;
      f.moved     := TRUE;
      Info (a);
   ELSE
      Info ("start >= end")
   END
END SelectLines;

PROCEDURE InsertSelection (f:Frame; t:Text.T; p:Pos);                           (* #SEL *)
VAR
   a: ARRAY 32 OF CHAR;
   b: ARRAY 32 OF CHAR;
BEGIN
   IF Text.InsertLines (t, p.cy, selectedText) THEN
      a := "InsertSelection ";
      selectionOn := TRUE;
      selectionType := LinesSelected;
      selectedLinesStart := p.cy;
      selectedLinesEnd   := p.cy + Text.Length (selectedText);
      f.moved := TRUE;
      Info (a);
   ELSE
      Info ("INSERTSELECTION FAILED");
   END;
END InsertSelection;

PROCEDURE DeleteSelection (f:Frame; t:Text.T; p:Pos);                           (* #SEL *)
VAR len: INTEGER;
BEGIN
   IF selectionOn THEN
      len := p.cy - lastcy;
      Text.DeleteLines (t, lastcy, p.cy + 1);
      DEC (p.cy, len);
      p.cx := 0;
      selectionOn := FALSE;
      Info ("Delete Lines");
   ELSE
      Info ("no selection");
   END
END DeleteSelection;

(* ========================================================================= *)
(* :chapter: TEXT PROCESSING *)
(* ------------------------------------------------------------------------- *)
PROCEDURE DomZut (f:Frame; t:Text.T; p:Pos);                                    (** untabbify selected lines *)
VAR
   i: INTEGER;
   l: Line.T;
BEGIN
   IF selectionOn & (selectionType = LinesSelected) THEN
      FOR i := selectedLinesStart TO selectedLinesEnd - 1 DO
         IF Text.HasLine (l, t, i) THEN
            l := Line.Untabify (l);
            Text.ChangeLine (t, l, i);
         END;
      END;
      Info ("selection untabified");
   ELSE Info ("no lines selected")
   END
END DomZut;

PROCEDURE DomF (f:Frame; t:Text.T; p:Pos);                                      (** format paragraph *)
VAR
   i: INTEGER;
   l: Line.T;
   at,nt: Text.T;
   start,end: INTEGER;
BEGIN
   IF selectionOn & (selectionType = LinesSelected) THEN
      start := selectedLinesStart;
      end   := selectedLinesEnd;
      Text.CopyLines   (at, t, start, end, "paragraph");
      IF Text.Format (nt, at) THEN
         Text.DeleteLines (t, start, end);
         IF Text.InsertLines (t, start, nt) THEN
            selectedLinesEnd := start + Text.Length (nt);
            selectedText := nt;
            f.moved := TRUE;
            Info ("selection formated");
         ELSE Info ("DomF: Text.InsertLines failed")
         END
      ELSE Info ("Text.Format failed")
      END
   ELSE Info ("no lines selected")
   END
END DomF;

PROCEDURE DomS (f:Frame; t:Text.T; p:Pos);
VAR a: ARRAY 64 OF CHAR;
BEGIN
   a := "DomS: sort selection: ";
   IF selectionOn & (selectionType = LinesSelected) THEN
       DeleteSelection (f,t,p);
       Text.Sort (selectedText);
       InsertSelection (f,t,p);
       Str.Append (a, "sorted");
   ELSE Str.Append (a, "no lines selected")
   END;
   Info (a);
END DomS;

PROCEDURE DomEnter (f:Frame; t:Text.T; p:Pos);                                  (** split-line&indent-to-cursor *)
VAR a: ARRAY 64 OF CHAR;
   l,head,tail,spaces: Line.T;
BEGIN
   a := "DomEnter";
   Info (a);
   IF Text.HasLine (l, t, p.cy) THEN
      IF p.cx > Line.Length (l) THEN
         p.cx := Line.Length(l);
      END;
      head := Line.Head (l, p.cx);
      tail := Line.Tail (l, p.cx);
      spaces := Line.Spaces (p.cx);
      Text.ChangeLine (t, head, p.cy);
      INC (p.cy);
      Text.InsertLine (t, p.cy, Line.Concat2 (spaces, tail));
   END;
END DomEnter;


(* ------------------------------------------------------------------------- *)
(* :chapter: COMMENTS *)
PROCEDURE IsCommentStart (l:Line.T; pos: INTEGER): BOOLEAN;
VAR res: BOOLEAN;
BEGIN
   IF pos > Line.Length (l) - cmt.len THEN
      res := FALSE
   ELSE
      CASE cmt.len OF
       1: res :=  l[pos] = cmt.c1
      |2: res := (l[pos] = cmt.c1) & (l[pos + 1] = cmt.c2)
      ELSE Dot.SWW ("Viewer.IsCommentStart: commentChars")
      END
   END;
   RETURN res;
END IsCommentStart;

PROCEDURE IsLongCommentEnd (l:Line.T; pos: INTEGER): BOOLEAN;
VAR res: BOOLEAN;
BEGIN
   IF pos > Line.Length (l) - cmt.len THEN
      res := FALSE
   ELSE
      CASE cmt.len OF
       2: res := (l[pos] = cmt.c2) & (l[pos + 1] = cmt.c1)
      ELSE Dot.SWW ("Viewer.IsLongCommentEnd: commentChars")
      END
   END;
   RETURN res;
END IsLongCommentEnd;

PROCEDURE ToggleComment (f:Frame; t:Text.T; p:Pos);
VAR
   a,b,typ: ARRAY 32 OF CHAR;
   l,open,close,nl,path: Line.T;
   ind,len: INTEGER;
BEGIN
   a := "ToggleComment ";
   path := Text.Path (t);
   IF ~Path.FileType (typ, path^) THEN
      typ := "??";
   END;
   IF Text.HasLine (l, t, p.cy) THEN
      ind := Line.Indentation (l);
      len := Line.Length (l);
      IF (typ = "obn/voc") OR (typ = "obn/kir") OR (typ = "obn/oc7")
      OR (typ = "pas") OR (typ = "m3") THEN                                    (* oberon *)
         IF IsCommentStart (l, ind) THEN
            b := "YES";
            l := Line.Body (l, 3, len - 3);
            Text.ChangeLine (t, l, p.cy);
         ELSE
            b := "NO";
            IF ~Line.IsEmpty (l) THEN
               open := Line.Create  ("(* ");
               close := Line.Create (" *)");
               nl := Line.Concat3 (open, l, close);
               Text.ChangeLine (t, nl, p.cy);
            END
         END;
      ELSIF (typ = "clean") OR (typ = "zig") OR (typ = "v") THEN                (* susel clean zig v *)
         IF (len > 2) & (l[0] = '/') & (l[1] = '/') & (l[2] = ' ') THEN
            l := Line.Tail (l, 3);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create ("// ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSIF typ = "miranda" THEN                                                (* miranda *)
         IF (len > 2) & (l[0] = '|') & (l[1] = '|') & (l[2] = ' ') THEN
            l := Line.Tail (l, 3);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create ("|| ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSIF typ = "prolog" THEN                                                (* prolog *)
         IF (len > 1) & (l[0] = '%') & (l[1] = ' ') THEN
            l := Line.Tail (l, 2);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create ("% ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSIF (typ = "python") OR (typ = "susel2") THEN                           (* python susel2 *)
         IF (len > 1) & (l[0] = '#') & (l[1] = ' ') THEN
            l := Line.Tail (l, 2);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create ("# ");
            nl   := Line.Concat2 (open, l);
         Text.ChangeLine (t, nl, p.cy)
         END
      ELSIF (typ = "curry") OR (typ = "haskell") OR (typ = "susel") THEN        (* curry haskell susel *)
         IF (len > 2) & (l[0] = '-') & (l[1] = '-') & (l[2] = ' ') THEN
            l := Line.Tail (l, 3);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create ("-- ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSIF (typ = "minal") OR (typ = "bash") OR (typ = "tila") THEN            (* # minal bash tila *)
         IF (len > 1) & (l[0] = '#') & (l[1] = ' ') THEN
            l := Line.Tail (l, 2);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSIF Line.HasHead (Line.DespaceLeft (l), Line.Create ("#")) THEN (* nothing *)
         ELSIF ~((len > 1) & (l[0] ='#') & (l[1] = '#')) THEN
            open := Line.Create ("# ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSIF (typ = "lisp") OR (typ = "rabbit") OR (typ = "fasm") THEN           (* lisp rabbit fasm *)
         IF (len > 1) & (l[0] = ';') & (l[1] = ';') & (l[2] = ' ') THEN
            l := Line.Tail (l, 3);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create (";; ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSIF (typ = "forth") THEN                                                (* forth *)
         IF (len > 1) & (l[0] = '\') & (l[1] = ' ') THEN
            l := Line.Tail (l, 2);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create ("\ ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSIF (typ = "c") THEN                                                    (* c *)
         IF (len > 2) & (l[0] = '/') & (l[1] = "/") & (l[2] = ' ') THEN
            l := Line.Tail (l, 3);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create ("// ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSIF (typ = "j") THEN                                                    (* j *)
         IF (len > 3) & (l[0] = 'N') & (l[1] = "B") & (l[2] = '.') & (l[3] = ' ') THEN
            l := Line.Tail (l, 4);
            Text.ChangeLine (t, l, p.cy)
         ELSIF Line.IsEmpty (l) THEN (* nothing *)
         ELSE
            open := Line.Create ("NB. ");
            nl   := Line.Concat2 (open, l);
            Text.ChangeLine (t, nl, p.cy);
         END
      ELSE Info ("type not found")                                              (* others / not found *)
      END
   ELSE
   END;
   INC (p.cy);
   p.cx := 0;
   Str.Append (a, typ);
   Info (a);
   f.moved := TRUE;
END ToggleComment;

PROCEDURE DoRedo (f:Frame; t:Text.T; p:Pos);
BEGIN
   Info ("DoRedo");
END DoRedo;


(* ------------------------------------------------------------------------- *)
(* :chapter: COMMANDS *)
PROCEDURE Save (t: Text.T);
VAR name: Line.T;
BEGIN
   IF Text.IsModified (t) THEN
      IF Text.Save (t) THEN
         Info ("SAVED")
      ELSE
         name := Text.Name (t);
         Dot.Errmess (name^);
         Dot.Errmess (Sys.errmess);
         Dot.Error   ("Viewer.Save: failed")
      END;
   END
END Save;

PROCEDURE DoBackspace (VAR sx: Screen);
VAR
   nt: Text.T;
   name: Line.T;
BEGIN
   Save (sx.t);
   IF Text.Load (nt, "bookmarks.md", "/home/heiko/q/oberon-voc/bookmarks.md") THEN
      sx.t := nt;
      sx.f.moved := TRUE;
      name := Text.Name (sx.t); Info (name^);
   ELSE
      Info ("DoSpace FAILED");
   END;
(*    Info ("DoBackspace"); *)
END DoBackspace;

PROCEDURE DoSpace (VAR sx: Screen);
BEGIN
   Save (sx.t);
   Info ("DoSpace");
END DoSpace;


(* ------------------------------------------------------------------------- *)
(* :chapter: REDRAW *)
PROCEDURE RedrawCursor (f:Frame; t:Text.T; p:Pos; style: INTEGER);
VAR
   line: Line.T;
   cc: CHAR;
BEGIN
   Dot.At (f.y + p.cy - p.y0, f.x + p.cx);
   IF Text.Length (t)  > p.cy THEN
      line := Text.GetLine (t, p.cy);
      IF Line.Length (line) > p.cx THEN
         cc := line[p.cx];
      ELSE cc := ' '
      END;
   ELSE cc := ' '
   END;
   IF style = CursorActive THEN
      IF mode = NormalMode       THEN Dot.CursorAsSteadyBlock
      ELSIF mode = InsertMode    THEN Dot.CursorAsBlinkingBar
      ELSIF mode = OverwriteMode THEN Dot.CursorAsBlinkingLine
      ELSE Dot.CursorAsBlinkingLine
      END
   ELSE
      Dot.OnBacklight;
      CASE style OF
        (* CursorActive:   Dot.AsPinkMark *)
      | CursorPassive:  Dot.AsPrompt
(*       | CursorSleeping: Dot.AsErr *)
      | CursorReadOnly: Dot.AsStd
      ELSE Dot.Error ("Viewer.RedrawCursor: no such cursor style.")
      END;
      cout (cc);
      Dot.OnStatus;
      Dot.AsText;
   END;
END RedrawCursor;

PROCEDURE RedrawStatus (scs: Screen);
VAR
   sx: Screen;
   f: Frame;
   t: Text.T;
   p: Pos;
   i,n: INTEGER;
   len: INTEGER;
BEGIN
   IF Kbd.HasKey() THEN RETURN END;
   sx := scs;
   n  := 0;
   Dot.CursorHide;
   WHILE sx # NIL DO
      f := sx.f;
      t := sx.t;
      p := sx.p;
      Dot.At (f.y - 1, f.x); Dot.OnStatus; FOR i := 1 TO f.w DO spc END;
      Dot.OnBacklight;
      Dot.At (f.y - 1, f.x + ScrollColumn); spc;
      Dot.OnStatus;
      Dot.At (f.y - 1, f.x); Dot.AsStatus;
      IF f.w >= 80 THEN
         spc; cout (Text.ModfChar(t));
         spc; iout (p.cy);
         spc; iout (p.cx);
         spc; cout ('('); iout (Text.Length (t)); cout (')');
         Dot.Mess("    ");  lout(Text.Name (sx.t));
         IF n = 0 THEN 
            spc;spc; out(keyinfo); out(" [");out(info);out("] ");
            len := Str.Length (currentSearchStr);
            Dot.At (f.y - 1, f.x + f.w - 22 - len);
            cout ("<"); out (currentSearchStr); cout (">"); spc;
            iout(xw); cout("x"); iout(xh); spc; DotTime; spc; DotHasKey;
         END;
      ELSE
         Dot.Mess (sx.name^)
      END;
      IF sx.name # activeScreen THEN
         RedrawCursor (f,t,p, CursorPassive);
      END;
      sx := sx.next;
      INC (n);
   END;
   Dot.CursorShow;
END RedrawStatus;

PROCEDURE RedrawLine(f:Frame; t: Text.T; pos: INTEGER);
(** Redraw current screen line with text starting from pos.
  * Update pos.
  *)
VAR
  len: INTEGER;
BEGIN
END RedrawLine;

PROCEDURE RedrawText(scs: Screen);
CONST
   AsText    = 0;
   AsString  = 1;
   AsComment = 2;
   AsName    = 3;
VAR
  l,i,j,ll,len: INTEGER;
  line : Line.T;
  sx: Screen;
  f: Frame;
  t: Text.T;
  p: Pos;
  style: INTEGER;
  c: CHAR;
BEGIN
  IF Kbd.HasKey() THEN RETURN END;
  Dot.CursorHide;
  Dot.OnText;
  Dot.AsStd; Dot.AsText;                                          (* XXX someone switches color without Dot? *)
  sx := scs;
  style := AsText;
  WHILE sx # NIL DO
     IF Text.IsModified (sx.t) OR sx.f.moved THEN
        t := sx.t;
        f := sx.f;
        p := sx.p;
        len := Text.Length (t);
        FOR l := 0 TO f.h - 1 DO
          Dot.At (f.y + l, f.x);
          IF selectionOn 
                & (selectedLinesStart <= p.y0 + l) 
                & (p.y0 + l < selectedLinesEnd) 
          THEN 
             Dot.OnSelection 
          ELSIF p.y0 + l = p.cy THEN 
             Dot.OnRuler
          ELSE Dot.OnText
          END;
           IF (p.y0 + l < len) & (l < f.h) THEN
              line := Text.GetLine (t, p.y0 + l);
              ll   := Line.Length (line);
              j := 0;
              WHILE j < f.w - 1 DO
                 IF j = RulerColumn THEN Dot.OnRuler END;
                 IF j < ll THEN
                    c := line[j];
                    (* IF (c = '"') & (style = AsText) THEN  *)
                       (* Dot.AsString;  *)
                       (* style := AsString; *)
                       (* cout (c); *)
                    (* ELSIF (c = '"') THEN  *)
                       (* cout (c); *)
                       (* Dot.AsText;  *)
                       (* style := AsText; *)
                    (* ELSIF (c = '#') THEN  *)
                       (* cout (c); *)
                       (* Dot.AsComment;  *)
                       (* style := AsComment; *)
                    (* ELSIF style # AsText THEN *)
                       (* Dot.AsText; *)
                       (* style := AsText; *)
                    (* ELSE *)
                       cout (c)
                    (* END; *)
                 ELSE spc
                 END;
                 IF (j = RulerColumn) & (p.y0 + l # p.cy) THEN Dot.OnText END;
                 INC (j)
              END;
              IF ll = f.w  THEN
                 cout (line[j])
              ELSIF ll < f.w THEN
                 spc
              ELSE Dot.AsDbg; cout ('#'); Dot.AsText
              END
           ELSE
              FOR j := 1 TO f.w DO spc END
           END;
           MicroPause;
        END;
        f.moved := FALSE;
     END;
     sx := sx.next;
  END;
  Dot.CursorShow;
END RedrawText;



(* ------------------------------------------------------------------------- *)
(* :chapter: THING-AT-POINT *)


(* ------------------------------------------------------------------------- *)
(* :chapter: SCROLL *)
PROCEDURE ScrollUp(f:Frame; t: Text.T; p:Pos; n: INTEGER);
VAR a: ARRAY 32 OF CHAR;
    d: INTEGER;
BEGIN
  IF n = 0 THEN n := 1 END;
  IF p.y0 > 0 THEN
      p.y0 := ssqTypes.Short (Int.Max (0, p.y0 - n));
     Int.Show (a, n,0);
  ELSE a := "HOME";
  END;
  IF p.cy >= p.y0 + f.h THEN p.cy := p.y0 + f.h - 1 END;
  Str.Append (a, " Scrollup");
  Info(a);
  f.moved := TRUE;
END ScrollUp;

PROCEDURE ScrollDown(f:Frame; t:Text.T; p:Pos; n: INTEGER);
VAR a: ARRAY 32 OF CHAR;
BEGIN
  IF n = 0 THEN n := 1 END;
  IF p.y0 < Text.Length (t) - f.h THEN
     p.y0 := Int.ShortMin (
                Int.Max (0, Text.Length (t) - f.h),
                p.y0 + n);
     Int.Show (a, n,0);
  ELSE a := "END"
  END;
  IF p.y0 > p.cy THEN p.cy := p.y0 END;
  Str.Append (a, " Scrolldown");
  Info(a);
  f.moved := TRUE;
END ScrollDown;

PROCEDURE ScrollHome(f:Frame; t:Text.T; p:Pos);
BEGIN
  Info("Home");
  p.y0 := 0;
  p.cx := 0;
  p.cy := 0;
  f.moved := TRUE;
END ScrollHome;

PROCEDURE ScrollEnd(f:Frame; t: Text.T; p:Pos);
VAR
  l: INTEGER;
BEGIN
  Info("End");
  p.y0 := Int.ShortMax (0, Text.Length (t) - f.h);
  p.cx := 0;
  p.cy := Text.Length (t) - 1;
  f.moved := TRUE;
END ScrollEnd;


(* ------------------------------------------------------------------------- *)
(* :section:    find *)
PROCEDURE FindFirstParen (c:CHAR; f:Frame; t:Text.T; p:Pos);
VAR
   l: Line.T;
   d,len,i: INTEGER;
BEGIN
   l   := Text.GetLine (t, p.cy);
   len := Line.Length (l);
   i   := 0;
   WHILE (i < len) & (l[i] # c) DO
      INC (i);
   END;
   IF i < len THEN p.cx := i END;
END FindFirstParen;

PROCEDURE FindPrevParen (c1,c2:CHAR; f:Frame; t:Text.T; p:Pos);
VAR a: ARRAY 32 OF CHAR;
   l: Line.T;
   d,len,i,j: INTEGER;
   firstTime: BOOLEAN;
   c: CHAR;
BEGIN
   COPY ("----", a);
   a[0] := '<';
   a[1] := c1;
   a[2] := c2;
   Info (a);
   d   := 1;
   i   := p.cx - 1;
   j   := p.cy;
   firstTime := TRUE;
   WHILE (d # 0) & (j >= 0) DO
      l   := Text.GetLine (t, j);
      len := Line.Length  (l);
      IF ~firstTime THEN i := len - 1 END;
      firstTime := FALSE;
      WHILE (d # 0) & (i >= 0) DO
         c := l[i];
         IF    c = c1 THEN DEC (d)
         ELSIF c = c2 THEN INC (d)
         END;
         DEC (i);
      END;
      DEC (j);
   END;
   IF d = 0 THEN
      p.cx := i + 1;
      p.cy := j + 1;
   ELSE Info ("Not found")
   END;
END FindPrevParen;

PROCEDURE FindNextParen (c1,c2:CHAR; f:Frame; t:Text.T; p:Pos);
VAR a: ARRAY 32 OF CHAR;
   l: Line.T;
   d,len,i,j: INTEGER;
   c: CHAR;
BEGIN
   COPY ("----", a);
   a[1] := c1;
   a[2] := c2;
   a[3] := '>';
   Info (a);
   d   := 1;
   i   := p.cx;
   j   := p.cy - 1;
   WHILE (d # 0) & (j < Text.Length (t) - 1) DO
      INC (j);
      l   := Text.GetLine (t, j);
      len := Line.Length  (l);
      WHILE (d # 0) & (i < len - 1) DO
         INC (i);
         c := l[i];
         IF    c = c1 THEN INC (d)
         ELSIF c = c2 THEN DEC (d)
         END
      END;
      IF d # 0 THEN i := -1 END;
   END;
   IF d = 0 THEN
      p.cx := i;
      p.cy := j;
   ELSE Info ("nOt found")
   END;
END FindNextParen;

PROCEDURE FindPrev (f:Frame; t:Text.T; p:Pos; VAR seq: ARRAY OF CHAR);
VAR
   a:   ARRAY  32 OF CHAR;
   l,x: INTEGER;
BEGIN
   l := Int.ShortMax (0, p.cy - 1);
   x := 0;
   IF Text.FindSeqBackwards (t, seq, l, x) THEN
      p.y0 := l;
      p.cx := x;
   ELSE
      p.y0 := 0;
      p.cx := 0;
      p.cy := 0;
   END;
   Int.Show (a, l, 0);
   Str.Append (a, " FP ");
   Str.Append (a, seq);
   Info (a);
   f.moved := TRUE;
END FindPrev;

PROCEDURE FindNext (f:Frame; t:Text.T; p:Pos; VAR seq: ARRAY OF CHAR);
VAR
   a:   ARRAY  32 OF CHAR;
   l,x,tlen: INTEGER;
BEGIN
   l := p.cy;
   x := Int.ShortMin (p.cx + 1, Line.Length (Text.GetLine (t, p.cy)) - 1);
   IF Text.FindSeq (t, seq, l, x) THEN
      p.y0 := l;
      p.cx := x;
      Int.Show (a, l, 0);
      Str.Append (a, " FN ");
      Str.Append (a, seq);
      Info (a);
      f.moved := TRUE;
   ELSE
      tlen := Text.Length (t);
      p.cy := tlen - 1;
      p.cx := 0;
      p.y0 := Int.ShortMax (0, tlen - f.h);
      f.moved := TRUE;
      Info ("not found");
   END;
END FindNext;

PROCEDURE FindPrevSection (f:Frame; t:Text.T; p:Pos);
VAR
   cx,cy,pos: INTEGER;
   l: Line.T;
BEGIN
   p.cx := 0;
   p.cy := p.y0;
   IF p.cy >= Text.Length (t) THEN p.cy := Text.Length (t) - 1 END;
   cy := p.cy;
   cx := p.cx;
   pos := 0;
   DEC (cy, 1);
   WHILE (cy >= 0)           (* works because it is ok to find one of both, no need to find the second then *)
        & Text.HasLine (l, t, cy)
        & ~(Line.FindSeq (l, PattSection, pos) OR Line.FindSeq (l, PattChapter, pos))
    DO
      pos := 0;
      DEC (cy);
   END;
   p.cy := cy;
   p.cx := 0;
   p.y0 := cy;
END FindPrevSection;

PROCEDURE FindNextSection (f:Frame; t:Text.T; p:Pos);
VAR
   cx,cy,pos,tlen: INTEGER;
   found: BOOLEAN;
   l: Line.T;
BEGIN
   p.cx := 0;
   p.cy := p.y0 + 1;
   tlen := Text.Length (t);
   cy := p.cy;
   cx := p.cx;
   pos := 0;
   found := FALSE;
   INC (cy);
   WHILE (cy < tlen) & Text.HasLine (l, t, cy) & ~found DO
      IF Line.FindSeq (l, PattSection, pos) OR Line.FindSeq (l, PattChapter, pos) THEN
         found := TRUE
      ELSE
         INC (cy);
         pos := 0;
      END;
   END;
   p.cy := cy;
   p.cx := 0;
   p.y0 := cy;
END FindNextSection;

PROCEDURE FindPrevDefinition (f:Frame; t:Text.T; p:Pos);
VAR
   cx,cy,pos: INTEGER;
   l: Line.T;
BEGIN
   p.cx := 0;
   p.cy := p.y0;
   IF p.cy >= Text.Length (t) THEN p.cy := Text.Length (t) - 1 END;
   cy := p.cy;
   cx := p.cx;
   pos := 0;
   DEC (cy, 1);
   WHILE (cy >= 0)           (* works because it is ok to find one of both, no need to find the second then *)
        & Text.HasLine (l, t, cy)
        & ~(Line.FindSeq (l, PattSection, pos)
                OR Line.FindSeq (l, PattChapter, pos)
                OR Line.FindSeq (l, PattProc,    pos)
                OR Line.FindSeq (l, PattConst,   pos)
(*                 OR Line.FindSeq (l, PattType,    pos) *)
(*                 OR Line.FindSeq (l, PattVar,     pos) *)
(*                 OR Line.FindSeq (l, PattBegin,   pos) *)
                )
    DO
      pos := 0;
      DEC (cy);
   END;
   p.cy := cy;
   p.cx := 0;
   p.y0 := cy;
END FindPrevDefinition;

PROCEDURE FindNextDefinition (f:Frame; t:Text.T; p:Pos);
VAR
   cx,cy,pos,tlen: INTEGER;
   found: BOOLEAN;
   l: Line.T;
BEGIN
   p.cx := 99;
   p.cy := p.y0;
   tlen := Text.Length (t);
   cy := p.cy;
   cx := p.cx;
   pos := 0;
   found := FALSE;
   INC (cy);
   WHILE (cy < tlen) & Text.HasLine (l, t, cy) & ~found DO
      IF Line.FindSeq (l, PattSection, pos)
                OR Line.FindSeq (l, PattChapter, pos)
                OR Line.FindSeq (l, PattProc,    pos)
                OR Line.FindSeq (l, PattConst,   pos)
                OR Line.FindSeq (l, PattType,    pos)
(*                 OR Line.FindSeq (l, PattVar,     pos) *)
(*                 OR Line.FindSeq (l, PattBegin,   pos) *)
      THEN
         found := TRUE
      ELSE
         INC (cy);
         pos := 0;
      END;
   END;
   p.cy := cy;
   p.cx := 0;
   p.y0 := cy;
END FindNextDefinition;

(* ------------------------------------------------------------------------- *)
(* :chapter: DOWHAT  Tab STab <Enter> 0 $ ^ *  *)
(* :section:    hallo *)
PROCEDURE JmpSTab (f:Frame; t:Text.T; p:Pos);
BEGIN
   IF    p.cx < 24 THEN p.cx := 24
   ELSIF p.cx < 48 THEN p.cx := 48
   ELSIF p.cx < 80 THEN p.cx := 80
   ELSE  p.cx := 24
   END
END JmpSTab;

PROCEDURE JmpTab (f:Frame; t:Text.T; p:Pos);
VAR size: INTEGER;
BEGIN
   size := TabSize - p.cx MOD TabSize;
   INC (p.cx, size);
END JmpTab;

PROCEDURE DoEnter (f:Frame; t:Text.T; p:Pos);
VAR ind: INTEGER;
BEGIN
   p.cy := Int.ShortMin (Text.Length (t) - 1, p.cy);
   ind := Line.Indentation (Text.GetLine (t, p.cy));
   INC (p.cy);
   Text.InsertLine (t, p.cy, Line.Spaces (ind));
   IF p.cy > p.y0 + f.h - 1 THEN INC (p.y0) END;
   p.cx := ind;
   f.moved := TRUE;
END DoEnter;

PROCEDURE DoEscape (f:Frame; t:Text.T; p:Pos);
BEGIN
   selectionOn := FALSE;
   f.moved     := TRUE;
END DoEscape;

PROCEDURE Do0 (f:Frame; t:Text.T; p:Pos);
BEGIN p.cx := 0 END Do0;

PROCEDURE DoDollar (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   IF Text.HasLine (l, t, p.cy) THEN
      p.cx := Line.Length (l)
   ELSE p.cx := 0
   END
END DoDollar;

PROCEDURE DoPercent (f:Frame; t:Text.T; p:Pos);
VAR
   a: ARRAY 32 OF CHAR;
   l: Line.T;
   c: CHAR;
BEGIN
   COPY ("DoPercent         >", a);
   IF Text.HasLine (l, t, p.cy) THEN
      IF Line.Length (l) > p.cx THEN
         c := l[p.cx];
         a[10] := c;
         IF    c = '(' THEN a[10] := c; FindNextParen (c, ')', f,t,p)
         ELSIF c = '[' THEN a[10] := c; FindNextParen (c, ']', f,t,p)
         ELSIF c = '{' THEN a[10] := c; FindNextParen (c, '}', f,t,p)
         ELSIF c = ')' THEN a[10] := c; FindPrevParen ('(', c, f,t,p)
         ELSIF c = ']' THEN a[10] := c; FindPrevParen ('[', c, f,t,p)
         ELSIF c = '}' THEN a[10] := c; FindPrevParen ('{', c, f,t,p)
         ELSE (* stay on place *)
         END;
      ELSE p.cx := 0; FindFirstParen ('(', f,t,p)            (* cx far right -> find first paren in this line *)
      END;
   ELSE Info (a);
   END;
   f.moved   := TRUE;
   IF ~IsWithinFrame (f, p) THEN
      IF p.cy < p.y0 THEN
         p.y0 := Int.ShortMax (0, p.cy - 7)
      ELSE
         p.y0 := Int.ShortMin (Text.Length (t) - f.h, p.cy - f.h + 4)
      END;
   END;
END DoPercent;

PROCEDURE MoveCursorRight (VAR cy,cx: INTEGER; t:Text.T; n: INTEGER): BOOLEAN;
VAR
   l: Line.T;
   res: BOOLEAN;
BEGIN
   WHILE (n > 0) & Text.HasLine (l, t, cy) DO
      WHILE (n > 0) & (cx < Line.Length (l)) DO
         INC (cx);
         DEC (n);
      END;
      IF n > 0 THEN INC (cy); cx := -1; END;
   END;
   RETURN n = 0;
END MoveCursorRight;

PROCEDURE DoPercentToNext (f:Frame; t:Text.T; p:Pos);
VAR
   l: Line.T;
   c: CHAR;
   cx,cy,i,j: INTEGER;
   done,ok,go: BOOLEAN;
BEGIN
   IF Text.HasLine (l, t, p.cy) & (p.cx < Line.Length (l)) THEN
      c := l[p.cx];
      IF c = '(' THEN
         cx := p.cx;
         cy := p.cy;
         FindNextParen (c, ')', f,t,p);
         IF (cx # p.cx) OR (cy #p.cy) THEN
            cx := p.cx;
            cy := p.cy;
            go := TRUE;
            WHILE go DO
               go := MoveCursorRight (cy,cx, t, 1);
               IF go & Text.HasChar (c, t, cy,cx) & ((c = '(') OR (c = ')')) THEN
                  go := FALSE
               END;
            END;
            IF cy < Text.Length (t) THEN
               p.cx := cx;
               p.cy := cy;
            END;
         ELSE Info ("  ]: no matching ')' found")
         END;
      ELSIF c = ')' THEN
(*          FindPrevParen ('(', c, f,t,p); *)
(*          DEC (p.cx); *)
(*          WHILE (p.cx > 0) & (l[p.cx] # ')') DO DEC (p.cx) END; *)
      END
   END;
   f.moved := TRUE;
   IF ~IsWithinFrame (f, p) THEN
      IF p.cy < p.y0 THEN
           p.y0 := Int.ShortMax (0, p.cy - 7)
      ELSE p.y0 := Int.ShortMin (Text.Length (t) - f.h, p.cy - f.h + 4)
      END;
   END;
END DoPercentToNext;

PROCEDURE DoCaret (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   IF Text.HasLine (l, t, p.cy) THEN 
      p.cx := Line.Indentation (l)
   ELSE
      p.cx := 0
   END
END DoCaret;

PROCEDURE DoDouble1 (f:Frame; t:Text.T; p:Pos);
VAR
   a,s: ARRAY 64 OF CHAR;
   start,end: INTEGER;
   l: Line.T;
BEGIN
   a := "DoDouble1: <";
   IF ~Text.TapThisWord (start, end, p.cy, p.cx, t) THEN
      s := "NIX"
   ELSE
      Str.AppendInt (a, start, 4);
      Str.AppendInt (a, end, 4);
      IF ~Text.HasLine (l, t, p.cy) THEN
         Dot.SWW ("Viewer.DoAsterix: line not found")
      ELSE
         Str.Sub (s, l^, start, end + 1)
      END;
      Str.AppendChar(a, ' ');
      COPY (s, currentSearchStr);
   END;
   Str.Append (a, s);
   Str.Append (a, ">");
   Info (a);
END DoDouble1;

PROCEDURE DoAsterix (f:Frame; t:Text.T; p:Pos);
BEGIN
   DoDouble1 (f,t,p);
   FindNext (f,t,p, currentSearchStr);
   ScTo (f,t,p, ScMid);
END DoAsterix;

PROCEDURE DoHash (f:Frame; t:Text.T; p:Pos);
BEGIN
   DoDouble1 (f,t,p);
   FindPrev (f,t,p, currentSearchStr);
   ScTo (f,t,p, ScMid);
END DoHash;

PROCEDURE DoLesser (f:Frame; t:Text.T; p:Pos);
VAR
   a: ARRAY 32 OF CHAR;
   i,width: INTEGER;
   l,path: Line.T;
BEGIN
   a := "DoLesser ";
   path  := Text.Path (t);
   width := Path.TabWidth (path^);
   IF selectionOn THEN
      DeleteSelection (f,t,p);
      FOR i := 0 TO Text.Length (selectedText) - 1 DO
         l := Text.GetLine (selectedText, i);
         IF Line.Indentation (l) >= width THEN
            l := Line.Tail (l, width);
         END;
         Text.ChangeLine (selectedText, l, i);
      END;
      InsertSelection (f,t,p);
      Info (a);
   ELSE
      IF Text.HasLine (l, t, p.cy) & (Line.Indentation (l) >= width) THEN
         Text.ChangeLine (t, Line.Tail (l, width), p.cy);
      ELSE Info ("no line or indentation too small")
      END;
      INC (p.cy)
   END;
END DoLesser;

PROCEDURE DoGreater (f:Frame; t:Text.T; p:Pos);
VAR
   a: ARRAY 32 OF CHAR;
   i,width: INTEGER;
   l,path: Line.T;
BEGIN
   a := "DoGreater ";
   path  := Text.Path (t);
   IF p.cx = 0 THEN
      width := 8
   ELSE width := Path.TabWidth (path^)
   END;
   IF selectionOn THEN
      DeleteSelection (f,t,p);
      FOR i := 0 TO Text.Length (selectedText) - 1 DO
         l := Text.GetLine (selectedText, i);
         l := Line.Concat2 (Line.Spaces (width), l);
         Text.ChangeLine (selectedText, l, i);
      END;
      InsertSelection (f,t,p);
   ELSE
      IF Text.HasLine (l, t, p.cy) THEN
         l := Line.Concat2 (Line.Spaces (width), l);
         Text.ChangeLine (t, l, p.cy);
         INC (p.cy)
      END
   END;
   Info (a);
END DoGreater;

PROCEDURE DoOpenBrace (f:Frame; t:Text.T; p:Pos);
(** {: jmp before start of [previous] paragraph *)
VAR l: Line.T;
BEGIN
   IF p.cy >= Text.Length (t) THEN
      MayJmpToLastline (t,p)
   END;
   WHILE (p.cy > 0) & Text.HasLine (l, t, p.cy) &  Line.IsEmpty(l) DO DEC (p.cy) END;
   WHILE (p.cy > 0) & Text.HasLine (l, t, p.cy) & ~Line.IsEmpty(l) DO DEC (p.cy) END;
   IF IsAboveFrame (f,p) THEN
      p.y0 := p.cy
   END;
   p.cx    := 0;
   f.moved := TRUE;
   Info ("{ done");
END DoOpenBrace;

PROCEDURE DoCloseBrace (f:Frame; t:Text.T; p:Pos);
(** }: jmp behind end of [next] paragraph *)
VAR l: Line.T;
BEGIN
   WHILE Text.HasLine (l, t, p.cy) &   Line.IsEmpty(l) DO INC (p.cy) END;
   WHILE Text.HasLine (l, t, p.cy) &  ~Line.IsEmpty(l) DO INC (p.cy) END;
   IF IsBelowFrame (f,p) THEN
      ScrollCyToBottom (f,p)
   END;
   p.cx    := 0;
   f.moved := TRUE;
   Info ("} done");
END DoCloseBrace;


(* ------------------------------------------------------------------------- *)
(* :section:    Do-a..z *)
PROCEDURE Jmph (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   IF p.cx > 0 THEN DEC (p.cx) END;
   f.moved := TRUE;
END Jmph;

PROCEDURE Jmpl (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   IF p.cx < 256 THEN INC (p.cx) END;
   f.moved := TRUE;
END Jmpl;

PROCEDURE Jmpj (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   IF p.cy < Text.Length (t) THEN INC (p.cy) END;
   IF p.cy > p.y0 + f.h - 1 THEN INC (p.y0) END;
   f.moved := TRUE;
END Jmpj;

PROCEDURE Jmpk (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   IF p.cy > 0 THEN DEC (p.cy) END;
   IF p.cy < p.y0 THEN p.y0 := p.cy END;
   f.moved := TRUE;
END Jmpk;

PROCEDURE Doa (f:Frame; t:Text.T; p:Pos);
BEGIN
   MayJmpToLastline (t,p);
   INC (p.cx);
   mode := InsertMode;
END Doa;

PROCEDURE Dob (f:Frame; t:Text.T; p:Pos);
VAR res: BOOLEAN;
BEGIN
   res := Text.FindWordStart (p.cy, p.cx, t);
   f.moved := TRUE;
END Dob;

PROCEDURE Doe (f:Frame; t:Text.T; p:Pos);
VAR res: BOOLEAN;
BEGIN
   res := Text.FindWordEnd (p.cy, p.cx, t);
   f.moved := TRUE;
END Doe;

PROCEDURE FindfChar (t:Text.T; p:Pos; c: CHAR);
VAR
   l: Line.T;
   pos: INTEGER;
BEGIN
   pos := p.cx;
   IF (' ' <= c) & (c <= '~')
        & Text.HasLine (l, t, p.cy)
        & (p.cx < Line.Length (l))
        & Str.FindChar (l^, c, pos)
   THEN
      p.cx := pos
   END
END FindfChar;

PROCEDURE Dof (f:Frame; t:Text.T; p:Pos);
VAR
   k: Kbd.KEY;
   l: Line.T;
   pos: INTEGER;
BEGIN
   Dot.CursorInYellow;
   k := Kbd.GetKey();
   Dot.CursorInRed;
   lastfChar := Kbd.Chr (k);
   FindfChar (t,p, lastfChar);
END Dof;

PROCEDURE RepeatFindf (f:Frame; t:Text.T; p:Pos);
VAR
   l: Line.T;
   pos: INTEGER;
BEGIN
   pos := p.cx + 1;
   IF Text.HasLine (l, t, p.cy) & (pos < Line.Length (l)) & Str.FindChar (l^, lastfChar, pos) THEN
      INC (p.cx);
      FindfChar (t, p, lastfChar);
   END;
END RepeatFindf;

PROCEDURE RepeatFindfRev (f:Frame; t:Text.T; p:Pos);
VAR
   l: Line.T;
   pos: INTEGER;
BEGIN
   pos := Int.ShortMax (0, p.cx - 1);
   IF Text.HasLine (l, t, p.cy) & (pos > 0) & Str.FindCharBackwards (l^, lastfChar, pos) THEN
      p.cx := pos
   END;
END RepeatFindfRev;

PROCEDURE Dode (f:Frame; t:Text.T; p:Pos);
VAR
   l,nl,head,tail: Line.T;
   cy,cx: INTEGER;
BEGIN
   IF Text.HasLine (l, t, p.cy) THEN
      cy := p.cy;
      cx := p.cx;
      IF Text.FindWordEnd (cy, cx, t) THEN
         head := Line.Head (l, p.cx);
         tail := Line.Tail (l, cx + 1);
         nl   := Line.Concat2 (head, tail);
         Text.ChangeLine (t, nl, p.cy);
      ELSE
         Info ("Dode: no word found")
      END;
   ELSE
      Info ("Dode: no line, here")
   END;
END Dode;

PROCEDURE Dodd (f:Frame; t:Text.T; p:Pos);
BEGIN
   MayJmpToLastline (t,p);
   Text.CopyLines (selectedText, t, p.cy, p.cy + 1, "dd");
   selectionType := LinesSelected;
   Text.DeleteLine (t, p.cy);
   MayJmpToLastline (t,p);
END Dodd;

PROCEDURE Dodw (f:Frame; t:Text.T; p:Pos);
VAR
   l,nl,head,tail: Line.T;
   cy,cx: INTEGER;
BEGIN
   IF Text.HasLine (l, t, p.cy) THEN
      cy := p.cy;
      cx := p.cx;
      IF Text.FindWord (cy, cx, t) THEN
         head := Line.Head (l, p.cx);
         tail := Line.Tail (l, cx);
         nl   := Line.Concat2 (head, tail);
         Text.ChangeLine (t, nl, p.cy);
      ELSE
         Info ("Dodw: no word found")
      END;
   ELSE
      Info ("Dodw: no line, here")
   END;
END Dodw;

PROCEDURE Domb (f:Frame; t:Text.T; p:Pos);
(** m backup: create backup of current file, prepending '.bak' *)
VAR
   a,path,name: ARRAY 256 OF CHAR;
   pt: Line.T;
BEGIN
   pt := Text.Path (t);
   Path.Directory (path, pt^);
   Path.FileName  (name, pt^);
   Str.Append (path, ".bak.");
   Str.Append (path, name);
   Text.SetPath     (t, path);
   Text.SetModified (t, TRUE);
   IF Text.Save (t) THEN
      a := "<";
      Str.Append     (a, path);
      Str.AppendChar (a, '>');
      Info (a);
   ELSE Info ("BAK FAILED")
   END;
   Text.SetPath (t, pt^);
END Domb;

PROCEDURE Domd (f:Frame; t:Text.T; p:Pos);       (** write iterfile:"docs" and docsfile:"<module>" for ./now *)
VAR a,word: ARRAY 256 OF CHAR;
   l: Line.T;
   start,end,i,cx: INTEGER;
BEGIN
   COPY ("Domd: <", a);
   word := "";
   IF Text.HasLine (l, t, p.cy) & (p.cx < Line.Length (l)) THEN
      cx := p.cx;
      IF Text.TapThisWord (start, end, p.cy, cx, t) THEN
         FOR i := start TO end DO
            Str.AppendChar (word, l[i]);
         END;
         Str.AppendChar (word, 0X);
         IF    Sys.FileWrite (Sys.iterfile, "docs", 4)
             & Sys.FileWrite (Sys.docsfile, word, Str.Length (word))
         THEN Str.Append (a, word);
         ELSE Str.Append (a, "FILE WRITE FAILED")
         END;
      ELSE Str.Append (a, "?")
      END;
   END;
   Str.AppendChar (a, ">");
   Info (a);
END Domd;

PROCEDURE Dome (f:Frame; t:Text.T; p:Pos);
CONST VimerrposFile = "r/vimerrpos";                                         (* compiler/.now writes errmess here *)
VAR
   a:        ARRAY 256 OF CHAR;
   filename: ARRAY 128 OF CHAR;
   ftyp: ARRAY 32 OF CHAR;
   path: Line.T;
   errtext: Text.T;
   errmess: Line.T;
   cpos: Int.T;
   pos:  INTEGER;
BEGIN
   a := "";
   Str.Copy   (filename, Sys.home);
   Str.Append (filename, VimerrposFile);
   IF ~Text.Load (errtext, "vimerrpos", filename) THEN Str.Append (a, "vimerrpos not found")
   ELSE
      path := Text.Path (t);
      IF ~Path.FileType (ftyp, path^) THEN
         Str.Copy (ftyp, "???")
      END;
      IF ftyp = "obn/voc" THEN                                                  (* vishaps/voc: .Mod *)
         IF ~Text.HasLine (errmess, errtext, 0) THEN Str.Append  (a, "No errmess found. [.Mod]")
         ELSE
            Str.Append (a, errmess^);
            Assert (Line.Length (errmess) > 10, "voc errmess too short");
            pos := 8; WHILE errmess[pos] = ' ' DO INC (pos) END;
            Assert (Char.IsDigit (errmess[pos]), "strange errmess: digit expected.");
            cpos := Int.Read (errmess^, pos);
            Assert ((cpos >0) & (cpos < 256000), "Viewer.Dome: cpos out of bounds");
            Str.AppendInt (a, cpos, 8);
             IF ~Text.FindPosition (p.cy, p.cx, t, ssqTypes.Short (cpos)) THEN Str.Append (a, "cpos not found") END;
         END;
      ELSIF ftyp = "obn/oc7" THEN                                               (* oberon-compiler*)
         IF Text.HasLine (errmess, errtext, 0) THEN
            Str.Append (a, errmess^);
            Str.Append (a, "|");
            Assert (Line.Length (errmess) > 10, "oc7 errmess too short");
            pos := 0;
            cpos := -1;
            IF Str.FindChar (errmess^, '!', pos) THEN
               INC (pos);
               IF Str.FindChar (errmess^, '!', pos) THEN
                  INC (pos);
                  cpos := Int.Read (errmess^, pos);
               ELSE Str.Append (a, "| snd ! not found")
               END
            ELSE Str.Append (a, "| fst ! not found")
            END;
            Assert ((cpos > 0) & (cpos < 256000), "Viewer.Dome: cpos out of bounds");
            Str.AppendInt (a, cpos, 8);
             IF ~Text.FindPosition (p.cy, p.cx, t, ssqTypes.Short (cpos)) THEN Str.Append (a, "cpos not found") END;
         ELSE Str.Append (a, "No errmess found. [obn/oc7]")
         END
      ELSIF (ftyp = "obn/kir") OR (ftyp = "susel")
         OR (ftyp = "susel2" ) OR (ftyp = "tila")
         OR (ftyp = "minal")
      THEN   (* kiran susel tila *)
         IF ~Text.HasLine (errmess, errtext, 0) THEN Str.Append  (a, "No errmess found. [.obn/kir]")
         ELSE
            Str.Append (a, errmess^);
            pos := 0;     WHILE errmess[pos] # 'E' DO INC (pos) END;            (* skip esc-seq/color  until Err *)
            INC (pos, 3); WHILE errmess[pos] = ' ' DO INC (pos) END;
            Assert (Char.IsDigit (errmess[pos]), "strange errmess: digit expected.");
            cpos := Int.Read (errmess^, pos);
            Assert ((cpos >0) & (cpos < 256000),                     "Viewer.Dome: cpos out of bounds, obn/kir");
             Assert (Text.FindPosition (p.cy, p.cx, t, ssqTypes.Short (cpos)), "Viewer.Dome: cpos not found: obn/kir");
         END;
      ELSIF (ftyp = "m3") THEN                                                  (* modula-3 cm3 *)
         IF ~Text.HasLine (errmess, errtext, 0) THEN Str.Append  (a, "No errmess found. [.m3/cm3]")
         ELSE
            pos := 0;     WHILE errmess[pos] # 'l' DO INC (pos) END;            (* skip until line *)
            INC (pos, 5);
            IF Char.IsDigit (errmess[pos]) THEN
               cpos := Int.Read (errmess^, pos);                                   (* is a line number *)
                p.cy := ssqTypes.Short (cpos); p.cx := 0;
            ELSE Str.Append (a, "err not lokated")
            END;
            f.moved := TRUE;
            Str.Append (a, errmess^);
         END;
      ELSIF (ftyp = "zig") THEN
         Str.Append (a, "zig ");
         IF ~Text.HasLine (errmess, errtext, 0) THEN Str.Append  (a, "No errmess found for zig.")
         ELSE
            pos := 0; WHILE errmess[pos] # ':' DO INC (pos) END;
            INC (pos, 1);
            IF Char.IsDigit (errmess[pos]) THEN
               cpos := Int.Read (errmess^, pos);
                p.cy := ssqTypes.Short (cpos) - 1; p.cx := 0;
               INC (pos, 1);
               cpos := Int.Read (errmess^, pos);
                p.cx := ssqTypes.Short (cpos);
            ELSE Str.Append (a, "err not located")
            END;
         END;
         f.moved := TRUE;
         Str.Append (a, errmess^);
      ELSE Str.Append (a, "unknown filetype")
      END;
   END;
   f.moved := TRUE;
   IF ~IsWithinFrame (f, p) THEN p.y0 := Int.ShortMax (0, p.cy - 10); END;
   Info (a);
END Dome;

PROCEDURE Domi (f:Frame; t:Text.T; p:Pos);
VAR
   name: ARRAY 64 OF CHAR;
   a:    ARRAY 32 OF CHAR;
   pth:    Line.T;
BEGIN
   pth := Text.Path (t);
   Save (t);
   (* write to iterfile FileName of t *)
   Path.FileName (name, pth^);
   IF ~Sys.FileWrite (Sys.iterfile, name, Str.Length (name)) THEN
      Dot.Errmess (pth^);
      Dot.Errmess (name);
      Dot.Error ("Domi failed.");
   END;
   a := "Domi: "; Str.Append (a, name); Info (a);
END Domi;

PROCEDURE VimselCopy;
BEGIN
(*    Sys.Assert (selectionOn, "Viewer.VimselCopy: selectionOn"); *)
   Text.SetPath (selectedText, vimselFilename);
   Text.SetModified (selectedText, TRUE);
   IF Text.Save (selectedText) THEN
      Info (vimselFilename);
   ELSE Info ("Domc: Text.Save FAILED");
   END
END VimselCopy;

PROCEDURE Domc (f:Frame; t:Text.T; p:Pos);                                      (* __ vimsel *)
BEGIN
   VimselCopy;
END Domc;

PROCEDURE Domx (f:Frame; t:Text.T; p:Pos);
BEGIN
   Info ("roadwork: use mc instead");
(*    IF selectionOn THEN *)
(*       VimselCopy; *)
(*       DeleteSelection (f,t,p); *)
(*    ELSE Info ("no selection") *)
(*    END *)
END Domx;

PROCEDURE Domv (f:Frame; t:Text.T; p:Pos);
BEGIN
   IF Text.Load (selectedText, "vimsel", vimselFilename) THEN
      INC (p.cy);
      InsertSelection (f,t,p)
   ELSE Info ("Domv: Text.Load FAILED")
   END
END Domv;

PROCEDURE Doo (f:Frame; t:Text.T; p:Pos);
VAR ind: INTEGER;
BEGIN
   ind := Line.Indentation (Text.GetLine (t, p.cy));
   INC (p.cy);
   Text.InsertLine (t, p.cy, Line.Spaces (ind));
   p.cx := ind;
   mode := InsertMode;
END Doo;

PROCEDURE Dop (f:Frame; t:Text.T; p:Pos);
BEGIN
   IF selectedText # NIL THEN
      IF selectionType = LinesSelected THEN
         INC (p.cy);
         IF ~Text.InsertLines (t, p.cy, selectedText) THEN
            Info ("Dop FAILED")
         END
      END
   END
END Dop;

PROCEDURE Dos (f:Frame; t:Text.T; p:Pos);
BEGIN
   Text.CharDelete (t, p.cy, p.cx);
   mode := InsertMode;
   f.moved := TRUE;
END Dos;

PROCEDURE Dou (f:Frame; t:Text.T; p:Pos);
BEGIN
   Info ("Dou");
END Dou;

PROCEDURE Dow (f:Frame; t:Text.T; p:Pos);
VAR res: BOOLEAN;
BEGIN
   res := Text.FindWord (p.cy, p.cx, t);
   f.moved := TRUE;
END Dow;

PROCEDURE Dox (f:Frame; t:Text.T; p:Pos);
BEGIN
   Text.CharDelete (t, p.cy, p.cx);
   Info (Text.mess);
END Dox;

PROCEDURE Doyy (f:Frame; t:Text.T; p:Pos);
BEGIN
   MayJmpToLastline (t,p);
   Text.CopyLines (selectedText, t, p.cy, p.cy + 1, "yy");
   selectionType := LinesSelected;
   Info ("Doyy");
END Doyy;

(* ------------------------------------------------------------------------- *)
(* :section:    Do-A..Z *)
PROCEDURE DoA (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   IF Text.HasLine (l, t, p.cy) THEN
      p.cx := Line.Length (l)
   ELSE p.cx := 0
   END;
   mode := InsertMode;
   f.moved := TRUE;
END DoA;

   PROCEDURE FHead (l:Line.T; cy,cx: INTEGER): Line.T;
   BEGIN RETURN Line.Head (l, cx) END FHead;
PROCEDURE DoD (f:Frame; t:Text.T; p:Pos);
BEGIN
   IF Text.IsPosValid (t, p.cy, p.cx) THEN
      Text.ModifyLine (t, p.cy, p.cx, FHead);
   ELSE
      Info ("DoD: not valid");
   END
END DoD;

PROCEDURE DoF (f:Frame; t:Text.T; p:Pos);
BEGIN
   Info ("DoF");
END DoF;

PROCEDURE DoI (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   IF Text.HasLine (l, t, p.cy) THEN
      p.cx := Line.Indentation (l);
      mode := InsertMode;
   ELSE
      Info ("DoI: no line, here ...");
   END;
END DoI;

PROCEDURE DoJ (f:Frame; t:Text.T; p:Pos);
VAR l1,l2,l: Line.T;
BEGIN
   l1 := Line.Despace1 (Text.GetLine (t, p.cy));
   l2 := Line.Indent  (Text.GetLine (t, p.cy + 1), 0);
   l  := Line.Concat2 (l1, l2);
   Text.DeleteLine (t, p.cy + 1);
   Text.ChangeLine (t, l, p.cy);
   p.cx := Line.Length (l1);
END DoJ;

PROCEDURE DoO (f:Frame; t:Text.T; p:Pos);
BEGIN
   Text.InsertLine (t, p.cy, Line.Create (""));
   p.cx := 0;
   mode := InsertMode;
END DoO;

PROCEDURE DoP (f:Frame; t:Text.T; p:Pos);
BEGIN
   IF selectedText # NIL THEN
      IF selectionType = LinesSelected THEN
         IF ~Text.InsertLines (t, p.cy, selectedText) THEN
            Info ("DoP FAILED")
         END
      END
   END
END DoP;

PROCEDURE DoS (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
BEGIN
   DoCaret (f,t,p);
   Text.ModifyLine (t, p.cy,p.cx, FHead);
   mode := InsertMode
END DoS;

PROCEDURE DoU (f:Frame; t:Text.T; p:Pos);
BEGIN
   Info ("DoU");
END DoU;

PROCEDURE DoX (f:Frame; t:Text.T; p:Pos);
BEGIN 
   IF (p.cx > 0) THEN DEC (p.cx) END;
   IF (p.cx >= 0) & (p.cx < Line.Length (Text.GetLine (t, p.cy))) THEN
      Text.CharDelete (t, p.cy, p.cx)
   END;
END DoX;


(* ------------------------------------------------------------------------- *)
(* :section: others *)
PROCEDURE DoUpcase (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
   cy,cx,start,end: INTEGER;
BEGIN
   IF Text.HasLine (l, t, p.cy) THEN
      IF (p.cx = 0) THEN
         l := Line.Upcase (l, 0, Line.Length (l));
         Text.ChangeLine (t, l, p.cy)
      ELSE
         cx := p.cx;
         cy := p.cy;
         IF (((cx < Line.Length (l)) & Text.IsWordStart (cx, l)) OR Text.FindWordStart (cy,cx, t))
            & (cy = p.cy) & Text.TapThisWord (start,end, cy,cx, t)
         THEN
            l := Line.Upcase (l, start, end + 1);
            Text.ChangeLine (t, l, p.cy)
         END
      END
   ELSE Info ("no line")
   END
END DoUpcase;

PROCEDURE DoDowncase (f:Frame; t:Text.T; p:Pos);
VAR l: Line.T;
   cy,cx,start,end: INTEGER;
BEGIN
   IF Text.HasLine (l, t, p.cy) THEN
      IF (p.cx = 0) THEN
         l := Line.Downcase (l, 0, Line.Length (l));
         Text.ChangeLine (t, l, p.cy)
      ELSE
         cx := p.cx;
         cy := p.cy;
         IF (((cx < Line.Length (l)) & Text.IsWordStart (cx, l)) OR Text.FindWordStart (cy,cx, t))
            & (cy = p.cy) & Text.TapThisWord (start,end, cy,cx, t)
         THEN
            l := Line.Downcase (l, start, end + 1);
            Text.ChangeLine (t, l, p.cy)
         END
      END
   ELSE Info ("no line")
   END
END DoDowncase;

PROCEDURE SendCurrentLine (f:Frame; t:Text.T; p:Pos);                           (* Meta-i *)
CONST
   SicSend   = "/home/heiko/r/sic-chat-send.txt";
   SicText   = "/home/heiko/r/sic-chat-text.txt";
   SuselFile = "/home/heiko/r/petline.susel";
   MinalFile = "/home/heiko/r/petline.minal";
   BookmarksFile = "/home/heiko/q/system/bookmarks.md";
VAR a,b: ARRAY 64 OF CHAR;
   path,l: Line.T;
   ext: ARRAY 32 OF CHAR;
   susel: ARRAY 256 OF CHAR;
   minal: ARRAY 256 OF CHAR;
   suselFileName: ARRAY 32 OF CHAR;
   minalFileName: ARRAY 32 OF CHAR;
   ffcmd: ARRAY 1024 OF CHAR;
   pos: INTEGER;
BEGIN
   suselFileName := "petline.susel";
   minalFileName := "petline.minal";
   a := "SendCurrentLine ";
   path := Text.Path (t);
   Path.FileExtension (ext, path^);
   IF path^ = SicText THEN                                                      (* append line to SicText *)
      Str.Append (a, "> ");
      IF Text.HasLine (l, t, p.cy) THEN
         IF Sys.FileAppendLine (SicSend, l^) THEN
            INC (p.cy);
            Str.Append (a, "OK")
         ELSE Str.Append (a, "FAILURE")
         END;
      ELSE Str.Append (a, "no-line")
      END
   ELSIF path^ = BookmarksFile THEN                                             (* open page in firefox *)
      Str.Append (a, "ffcmd: ");
      ffcmd := "firefox ";
      IF Text.HasLine (l, t, p.cy) THEN
         pos := 0;
         b   := "http";
         IF Line.FindSeq (l, b, pos) THEN
            l := Line.Tail (l, pos);
            Str.Append (ffcmd, l^);
            Sys.System (ffcmd);
         ELSE Str.Append (a, "NO HTTP")
         END
      ELSE Str.Append (a, "???")
      END;
   ELSIF (ext = "susel") & Text.HasLine (l, t, p.cy) THEN                       (* write petline.susel *)
      IF ~Text.Save (t) THEN
         Str.Append (a, "Text.Save FAILED")
      END;
      IF Line.HasHead (l, Line.Create ("--!")) THEN
         l := Line.Tail (l, 3)
      END;
      Str.Append (a, "SUSEL ");
      susel := "";
      Str.Append (susel, "-- module petline autogenerated by voc");     Str.AppendChar (susel, 0AX);
      Str.Append (susel, "module petline");                             Str.AppendChar (susel, 0AX);
      Str.Append (susel, " ");                                          Str.AppendChar (susel, 0AX);
      Str.Append (susel, "fun __petline__ () is  ");                    Str.AppendChar (susel, 0AX);
      Str.Append (susel, "   Int a Int b Int c Int f Int t ");          Str.AppendChar (susel, 0AX);
      Str.Append (susel, "   lff;");                Str.AppendChar (susel, 0AX);
      Str.Append (susel, l^);                                           Str.AppendChar (susel, 0AX);
      Str.Append (susel, "   lff");                                     Str.AppendChar (susel, 0AX);
      Str.Append (susel, " ");                                          Str.AppendChar (susel, 0AX);
      Str.Append (susel, "end petline.");                               Str.AppendChar (susel, 0AX);
      Str.Append (susel, " ");                                          Str.AppendChar (susel, 0AX);
      IF Sys.FileWrite (SuselFile, susel, Str.Length (susel))
         & Sys.FileWrite (Sys.iterfile, suselFileName, Str.Length (suselFileName))
      THEN
         Str.Append (a, "written");
      ELSE Str.Append (a, "FAILED")
      END;
   ELSIF (ext = "minal") & Text.HasLine (l, t, p.cy) THEN                       (* write petline.minal*)
      IF ~Text.Save (t) THEN
         Str.Append (a, "Text.Save FAILED")
      END;
      IF Line.HasHead (l, Line.Create ("##!")) THEN
         l := Line.Tail (l, 3)
      END;
      Str.Append (a, "MINAL");
      minal:= "";
      Str.Append (minal, "## module petline autogenerated by voc"); Str.AppendChar (minal, 0AX);
      Str.Append (minal, " ");                                      Str.AppendChar (minal, 0AX);
      Str.Append (minal, ":petline {}   ");                         Str.AppendChar (minal, 0AX);
      Str.Append (minal, "   lf");                                  Str.AppendChar (minal, 0AX);
      Str.Append (minal, "   (");                                   Str.AppendChar (minal, 0AX);
      Str.Append (minal, l^);                                       Str.AppendChar (minal, 0AX);
      Str.Append (minal, "   ) dup asPrompt print asText lf i  xx Stack.clear");
                                                                    Str.AppendChar (minal, 0AX);
      Str.Append (minal, "   lff");                                 Str.AppendChar (minal, 0AX);
      Str.Append (minal, " ");                                      Str.AppendChar (minal, 0AX);
      Str.Append (minal, " ");                                      Str.AppendChar (minal, 0AX);
      IF Sys.FileWrite (MinalFile, minal, Str.Length (minal))
         & Sys.FileWrite (Sys.iterfile, minalFileName, Str.Length (minalFileName))
      THEN
         Str.Append (a, "written");
      ELSE Str.Append (a, "FAILED")
      END;
   ELSE Str.Append (a, "wrong-file");                                           (* nothing to do here *)
   END;
   Info (a);
END SendCurrentLine;

PROCEDURE SendLastPetline (f:Frame; t:Text.T; p:Pos);
VAR a: ARRAY 64 OF CHAR;
   minalFileName: ARRAY 32 OF CHAR;
   b: BOOLEAN;
BEGIN
   b := Text.Save (t);
   Sys.Sleep (100);
   minalFileName := "petline.minal";
   a := "SendLastPetline";
   b := Sys.FileWrite (Sys.iterfile, minalFileName, Str.Length (minalFileName));
   Info (a)
END SendLastPetline;


(* ------------------------------------------------------------------------- *)
(* :section:    insert *)
PROCEDURE InsertEnter (f:Frame; t:Text.T; p:Pos);
VAR
   l,nl: Line.T;
   ind,i: INTEGER;
BEGIN
   IF Text.HasLine (l, t,p.cy) THEN
      ind := Line.Indentation (Text.GetLine (t, p.cy));
      IF p.cx < Line.Length (l) THEN
         Text.SplitLine (t, p.cy, p.cx);
      ELSE
         INC (p.cy);
         p.cx := ind;
         NEW (nl, ind + 1);
         FOR i := 0 TO ind - 1 DO nl[i] := ' ' END;
         nl[ind] := 0X;
         Text.InsertLine (t, p.cy, nl);
      END
   ELSE Info ("InsertEnter:EOT")
   END;
END InsertEnter;

PROCEDURE InsertTab (f:Frame; t:Text.T; p:Pos);
VAR 
   s: ARRAY 16 OF CHAR;
   i,size: INTEGER;
BEGIN
   size := TabSize - p.cx MOD TabSize;
   FOR i := 0 TO size - 1 DO s[i] := ' ' END;
   s[size] := 0X;
   Text.InsertStr (t, p.cy, p.cx, s);
   INC (p.cx, size);
END InsertTab;

PROCEDURE InsertChar (f:Frame; t:Text.T; p:Pos; k:Kbd.KEY);
BEGIN
   IF    k = Kbd.Escape                         THEN mode := NormalMode
   ELSIF k = Kbd.Backspace                      THEN DoX         (f,t,p)
   ELSIF k = Kbd.Enter                          THEN InsertEnter (f,t,p)
   ELSIF k = Kbd.Tab                            THEN InsertTab   (f,t,p)
   ELSIF k = Kbd.FKey( Kbd.Shift,Kbd.STab)      THEN JmpSTab     (f,t,p)
   ELSIF k = Kbd.AKey (Kbd.Meta, "u")           THEN DoUpcase    (f,t,p)
   ELSIF k = Kbd.AKey (Kbd.Meta, "U")           THEN DoDowncase  (f,t,p)
   ELSIF (32 <= k) & (k < 127)  THEN
      Text.CharInsert (t, p.cy, p.cx, Kbd.Chr (k));
      Info (Text.mess);
      INC (p.cx)
   ELSE Info ("strange-character in InsertMode")
   END;
END InsertChar;

PROCEDURE OverwriteChar (f:Frame; t:Text.T; p:Pos; k:Kbd.KEY);
BEGIN
   IF    k = Kbd.Escape                         THEN mode := NormalMode
   ELSIF k = Kbd.Backspace                      THEN p.cx := Int.ShortMax (0, p.cx - 1)
   ELSIF k = Kbd.Enter                          THEN InsertEnter (f,t,p)
   ELSIF k = Kbd.Tab                            THEN INC (p.cx, 8 - p.cx MOD 8)
   ELSIF k = Kbd.AKey (Kbd.Meta, "u")           THEN DoUpcase   (f,t,p)
   ELSIF k = Kbd.AKey (Kbd.Meta, "U")           THEN DoDowncase (f,t,p)
   ELSIF (32 <= k) & (k < 127)  THEN
      Text.CharChange (t, p.cy, p.cx, Kbd.Chr (k));
      INC (p.cx)
   ELSE Info ("strange-character in InsertMode")
   END;
   f.moved := TRUE;
END OverwriteChar;


(* ------------------------------------------------------------------------- *)
(* :chapter: TEST *)
PROCEDURE Domt (f:Frame; t:Text.T; p:Pos);
VAR i: INTEGER;
BEGIN
   Info ("Domt: Test");
(*    Break ("Domt: Break"); *)
   i := 10; Sys.Assert (i < 10, "Domt: some assert test");
END Domt;

(* ------------------------------------------------------------------------- *)
(* :chapter: DISPATCH *)
PROCEDURE LastDo (p: LastDoProc);
BEGIN
   lastdo := p
END LastDo;

PROCEDURE ExitOnIterfile (VAR md: INTEGER);
BEGIN IF Sys.FileExists (Sys.iterfile) THEN md := MdExit END END ExitOnIterfile;

PROCEDURE IsCx (c, x: INTEGER): BOOLEAN;
BEGIN RETURN c < x END IsCx;

PROCEDURE IsMouseKeyWithin (k: Kbd.KEY; f:Frame): BOOLEAN;
VAR m,l,c: INTEGER;
BEGIN
   Kbd.Mouse (m,l,c, k);
   RETURN (f.x <= c) & (c < f.x + f.w)
        & (f.y <= l) & (l < f.y + f.h)
END IsMouseKeyWithin;

PROCEDURE FindScreen (VAR screen: Screen; VAR f:Frame; VAR t:Text.T; VAR p:Pos; scs: Screen; k:Kbd.KEY);
VAR
   sx: Screen;
   m,l,c: INTEGER;
BEGIN
   sx := scs;
   WHILE (sx # NIL) & ~IsMouseKeyWithin (k, sx.f) DO sx := sx.next END;
   IF (sx # NIL) & (activeScreen # sx.name) THEN
      activeScreen := sx.name;
      screen := sx;
      f := sx.f;
      t := sx.t;
      p := sx.p;
   END;
END FindScreen;

PROCEDURE DispatchKey (k:Kbd.KEY; f:Frame; t:Text.T; p:Pos; VAR md:INTEGER; scs: Screen);
VAR a: ARRAY 32 OF CHAR;
   doloop: BOOLEAN;
BEGIN
   IF    mode = InsertMode    THEN InsertChar    (f,t,p, k)
   ELSIF mode = OverwriteMode THEN OverwriteChar (f,t,p, k)
   (* --------------------------------------------------------------------- *)
   ELSIF k = Kbd.Enter                          THEN DoEnter    (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.Escape                         THEN DoEscape   (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.Tab                            THEN JmpTab     (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.FKey( Kbd.Shift,Kbd.STab)      THEN JmpSTab    (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.AKey( 0,       "|")            THEN JmpSTab    (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Meta,"k" )           THEN ScrollUp   (f,t,p, 2)      (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Meta,"j" )           THEN ScrollDown (f,t,p, 1)      (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Meta,"," )           THEN ToggleComment (f,t,p)      (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Ctrl,"C" )           THEN Break ("Ctrl-C");          (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Ctrl,"D" )           THEN md := MdExit               (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Ctrl,"R" )           THEN DoRedo (f,t,p);            (* #KEY *)
   ELSIF k = Kbd.FKey( 0,        Kbd.Insert )   THEN md := MdChangeFile         (* #KEY change file *)
   ELSIF k = Kbd.FKey( 0,        Kbd.Delete)    THEN md := MdTextContents       (* #KEY show file cont*)
   ELSIF k = Kbd.FKey( Kbd.Ctrl, Kbd.Home )     THEN ScrollHome (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.FKey( Kbd.Ctrl, Kbd.End  )     THEN ScrollEnd  (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.FKey( 0,         Kbd.Home)     THEN ScrollDown (f,t,p, p.cy - p.y0)             (* #KEY *)
   ELSIF k = Kbd.FKey( 0,         Kbd.End)      THEN ScrollUp   (f,t,p, f.h - 1 - (p.cy - p.y0)) (* #KEY *)
   ELSIF k = Kbd.FKey( 0,         Kbd.PageUp)   THEN ScrollUp   (f,t,p, f.h-1)  (* #KEY *)
   ELSIF k = Kbd.FKey( 0,         Kbd.PageDown) THEN ScrollDown (f,t,p, f.h-1)  (* #KEY *)
(*    ELSIF k = Kbd.FKey( Kbd.sM,    Kbd.PageUp)   THEN ScrollUp   (f,t,p, f.h)    (* #KEY *) *)
(*    ELSIF k = Kbd.FKey( Kbd.sM,    Kbd.PageDown) THEN ScrollDown (f,t,p, f.h)    (* #KEY *) *)
   ELSIF k = Kbd.AKey( 0,  "(")                 THEN FindPrev(f,t,p, PattChapter); ScTo (f,t,p, ScOne) (* #KEY *)
   ELSIF k = Kbd.AKey( 0,  ")")                 THEN FindNext(f,t,p, PattChapter); ScTo (f,t,p, ScOne) (* #KEY *)
   ELSIF k = Kbd.AKey( 0,  "8")                 THEN FindPrevSection (f,t,p);     ScTo (f,t,p, ScOne) (* #KEY *)
   ELSIF k = Kbd.AKey( 0,  "9")                 THEN FindNextSection (f,t,p);     ScTo (f,t,p, ScOne) (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Meta,         "8")   THEN ScrollUp   (f,t,p, f.h-1)  (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Meta,         "9")   THEN ScrollDown (f,t,p, f.h-1)  (* #KEY *)
(*    ELSIF k = Kbd.FKey( 0,  Kbd.Up)   THEN FindPrevSection (f,t,p);     ScTo (f,t,p, ScOne) (* #KEY *) *)
(*    ELSIF k = Kbd.FKey( 0,  Kbd.Down) THEN FindNextSection (f,t,p);     ScTo (f,t,p, ScOne) (* #KEY *) *)
(* ELSIF k=Kbd.FKey(Kbd.CM,Kbd.PageUp)  THEN p.cx:=0;p.cy:=p.y0; FindPrev(f,t,p,PattProc);ScTo(f,t,p,ScTop)(*#KEY*) *)
(* ELSIF k=Kbd.FKey(Kbd.CM,Kbd.PageDown)THEN p.cx:=99;p.cy:=p.y0;FindNext(f,t,p,PattProc);ScTo(f,t,p,ScTop)(*#KEY*) *)
   ELSIF k = Kbd.AKey( Kbd.Meta,  "b")  THEN a := PattXMark; FindPrev(f,t,p, a); ScTo (f,t,p, ScOne)  (* #KEY *)
   ELSIF k = Kbd.AKey( Kbd.Meta,  "n")  THEN a := PattXMark; FindNext(f,t,p, a); ScTo (f,t,p, ScOne)  (* #KEY *)
   ELSIF (k = Kbd.AKey (0," ")) & IsContFile(t) THEN md := MdTextContents       (* #KEY ms: move-to section *)
   ELSIF (k = Kbd.AKey (0," ")) & IsPetFiles(t) THEN md := MdChangeFile         (* #KEY mf: move-to file *)
   (* --------------------------------------------------------------------- *)  (* _xmark_ *)
   ELSIF k = Kbd.AKey (0,"^")                   THEN DoCaret        (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"*")                   THEN DoAsterix      (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"#")                   THEN DoHash         (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"0")                   THEN Do0            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"$")                   THEN DoDollar       (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"%")                   THEN DoPercent      (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"[")                   THEN DoPercentToNext(f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"]")                   THEN DoPercentToNext(f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,".")                   THEN lastdo         (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,",")                   THEN RepeatFindfRev (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,";")                   THEN RepeatFindf    (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"<")                   THEN DoLesser       (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,">")                   THEN DoGreater      (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"{")                   THEN DoOpenBrace    (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"}")                   THEN DoCloseBrace   (f,t,p)     (* #KEY *)
   (* --------------------------------------------------------------------- *)
   ELSIF k = Kbd.AKey (0,"a")                   THEN Doa            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"b")                   THEN Dob            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"e")                   THEN Doe            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"f")                   THEN Dof            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"i")                   THEN mode := InsertMode         (* #KEY *)
   ELSIF k = Kbd.AKey (0,"h")                   THEN Jmph           (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"j")                   THEN Jmpj           (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"k")                   THEN Jmpk           (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"l")                   THEN Jmpl           (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"n")   THEN a := currentSearchStr;FindNext(f,t,p,a);ScTo(f,t,p,ScMid) (* #KEY *)
   ELSIF k = Kbd.AKey (0,"o")                   THEN Doo            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"p")                   THEN Dop            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"s")                   THEN Dos            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"u")                   THEN Dou            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"w")                   THEN Dow            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"x")                   THEN Dox            (f,t,p)     (* #KEY *)
   (* --------------------------------------------------------------------- *)
   ELSIF k = Kbd.AKey (0,"A")                   THEN DoA            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"C")   THEN DoD            (f,t,p); mode := InsertMode (* #KEY *)
   ELSIF k = Kbd.AKey (0,"D")                   THEN DoD            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"F")                   THEN DoF            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"G")                   THEN ScrollEnd      (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"I")                   THEN DoI            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"J")                   THEN DoJ            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"N")   THEN a := currentSearchStr;FindPrev(f,t,p,a);ScTo(f,t,p,ScMid) (* #KEY *)
   ELSIF k = Kbd.AKey (0,"O")                   THEN DoO            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"P")                   THEN DoP            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"R")                   THEN mode := OverwriteMode      (* #KEY *)
   ELSIF k = Kbd.AKey (0,"S")                   THEN DoS            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"U")                   THEN DoU            (f,t,p)     (* #KEY *)
   ELSIF k = Kbd.AKey (0,"X")                   THEN DoX            (f,t,p)     (* #KEY *)
   (* --------------------------------------------------------------------- *)
   ELSIF k = Kbd.AKey (Kbd.Meta,"u")            THEN DoUpcase   (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.AKey (Kbd.Meta,"U")            THEN DoDowncase (f,t,p)         (* #KEY *)
   ELSIF k = Kbd.AKey (Kbd.Meta,"i")            THEN SendCurrentLine (f,t,p)    (* #KEY SendCurrentLine *)
   ELSIF k = Kbd.AKey (Kbd.Meta,"I")            THEN SendLastPetline (f,t,p)    (* #KEY SendCurrentLine *)
   (* --------------------------------------------------------------------- *)
   ELSIF k = Kbd.AKey( Kbd.Ctrl,"J" )           THEN Info("C-J")
   ELSIF k = Kbd.AKey( Kbd.Ctrl,"K" )           THEN Info("C-K")
   ELSIF k = Kbd.AKey( Kbd.CM,  "J" )           THEN Info("CM-J")
   ELSIF k = Kbd.AKey( Kbd.CM,  "K" )           THEN Info("CM-K")
   ELSIF k = Kbd.AKey( Kbd.Meta,"J" )           THEN Info("M-J")
   ELSIF k = Kbd.AKey( Kbd.Meta,"K" )           THEN Info("M-K")
   ELSIF k = Kbd.AKey( Kbd.CM,  "J" )           THEN Info("CM-J")
   ELSIF k = Kbd.AKey( Kbd.CM,  "K" )           THEN Info("CM-K")
   ELSIF k = Kbd.FKey( 0,         Kbd.Home )    THEN Info ("Home")
   ELSIF k = Kbd.FKey( 0,         Kbd.End )     THEN Info ("End")
   ELSIF k = Kbd.FKey( Kbd.Ctrl,  Kbd.Home )    THEN Info("C-Home")
   ELSIF k = Kbd.FKey( Kbd.Shift, Kbd.Home )    THEN Info("s-Home")
   ELSIF k = Kbd.FKey( Kbd.Meta,  Kbd.Home )    THEN Info("M-Home")
   ELSIF k = Kbd.FKey( Kbd.CM,    Kbd.Home )    THEN Info("CM-Home")
   ELSIF k = Kbd.FKey( Kbd.sM,    Kbd.Home )    THEN Info("sM-Home")
   ELSIF k = Kbd.FKey( Kbd.sC,    Kbd.Home )    THEN Info("sC-Home")
   ELSIF k = Kbd.FKey( Kbd.sCM,   Kbd.Home )    THEN Info("sCM-Home")
   (* --------------------------------------------------------------------- *)  (* _xmark_ *)
   ELSIF k = Kbd.AKey( 0,"c" ) THEN                                             (* keycord:   c *)
      Dot.CursorInMagenta;
      k := Kbd.GetKey();
      IF    k = Kbd.AKey( 0,"c" )       THEN DoS  (f,t,p)  (* S == cc *)        (* #KEY cc *)
      ELSIF k = Kbd.AKey( 0,"e" )       THEN Dode (f,t,p); mode := InsertMode   (* #KEY ce *)
      ELSIF k = Kbd.AKey( 0,"w" )       THEN Dodw (f,t,p); mode := InsertMode   (* #KEY cw *)
      ELSE Info ("no-such-cord")
      END;
      Dot.CursorInRed;
   ELSIF k = Kbd.AKey( 0,"d" ) THEN                                             (* keycord:   d *)
      Dot.CursorInMagenta;
      k := Kbd.GetKey();
      IF    k = Kbd.AKey( 0,"e" )       THEN Dode (f,t,p); LastDo (Dode)        (* #KEY de *)
      ELSIF k = Kbd.AKey( 0,"d" )       THEN Dodd (f,t,p); LastDo (Dodd)        (* #KEY dd *)
      ELSIF k = Kbd.AKey( 0,"w" )       THEN Dodw (f,t,p); LastDo (Dodw)        (* #KEY dw *)
      ELSE Info ("no-such-cord")
      END;
      Dot.CursorInRed;
   ELSIF k = Kbd.AKey (0,"g")  THEN                                             (* keycord:   g *)
      Dot.CursorInYellow;
      k := Kbd.GetKey();
      IF k = Kbd.AKey (0,'g')           THEN ScrollHome     (f,t,p)             (* #KEY gg *)
      ELSE Info ("no-such-cord")
      END;
      Dot.CursorInRed;
   ELSIF k = Kbd.AKey( 0,"m" ) THEN                                             (* leaderkey: m *)
      Dot.CursorInYellow;
      k := Kbd.GetKey();
      IF    k = Kbd.AKey (0,"l")        THEN md := MdExit               (* #KEY ml leave *)
      ELSIF k = Kbd.AKey (0,"b")        THEN Domb (f,t,p)               (* #KEY mb backup: .bak.myfile *)
      ELSIF k = Kbd.AKey (0,"d")        THEN Domd (f,t,p)               (* #KEY md docs print *)
      ELSIF k = Kbd.AKey (0,"e")        THEN Dome (f,t,p)               (* #KEY me error: jmp to error *)
      ELSIF k = Kbd.AKey (0,"i")        THEN Domi (f,t,p)               (* #KEY mi iter: run corr test *)
      ELSIF k = Kbd.AKey (0,"m")        THEN Save (t)                   (* #KEY mm:    save *)
      ELSIF k = Kbd.AKey (0,"t")        THEN Domt (f,t,p)               (* #KEY mt some test *)
      ELSIF k = Kbd.AKey (0,"c")        THEN Domc (f,t,p)               (* #KEY mc: write select/vimsel *)
      ELSIF k = Kbd.AKey (0,"v")        THEN Domv (f,t,p)               (* #KEY mv: paste vimsel *)
      ELSIF k = Kbd.AKey (0,"x")        THEN Domx (f,t,p)               (* #KEY mx: write to vimsel/del *)
      ELSIF k = Kbd.AKey (0,"F")        THEN DomF (f,t,p)               (* #KEY mF: format paragraph *)
      ELSIF k = Kbd.Enter               THEN DomEnter (f,t,p)           (* #KEY m<CR>: split-line/indent *)
      ELSIF k = Kbd.AKey (0,"f")        THEN md := MdChangeFile         (* #KEY mf: move-to file    *)
      ELSIF k = Kbd.AKey (0,"s")        THEN md := MdTextContents       (* #KEY ms: move-to section *)
      ELSIF k = Kbd.AKey (0,"S")        THEN DomS (f,t,p)               (* #KEY mS: sort-selection  *)
      ELSIF k = Kbd.AKey (0,"Z") THEN
         Dot.CursorInMagenta;
         Info ("mZ: ut:untabify|...");
         RedrawStatus (scs);
         k := Kbd.GetKey();
         IF k = Kbd.AKey (0,"u") THEN
            k := Kbd.GetKey();
            IF k = Kbd.AKey (0,"t")     THEN DomZut (f,t,p)             (* #KEY mZut: untabify selection *)
            ELSE Info ("no-such-cord")
            END
         ELSE Info ("no-such-cord")
         END
      ELSE Info ("no-such-cord")
      END;
      Dot.CursorInRed;
   ELSIF k = Kbd.AKey (0,'r')  THEN                                     (* #KEY *)
      Dot.CursorInYellow;
      k := Kbd.GetKey();
      Text.CharChange (t, p.cy, p.cx, Kbd.Chr (k));
      Dot.CursorInRed;
   ELSIF k = Kbd.AKey( 0,"y" ) THEN                                             (* keycord:   y *)
      Dot.CursorInMagenta;
      k := Kbd.GetKey();
      IF k = Kbd.AKey (0, 'y')          THEN Doyy (f,t,p)               (* #KEY yy *)
      ELSE Info ("no-such-cord")
      END;
      Dot.CursorInRed;
   ELSIF k = Kbd.AKey( 0,"Z" ) THEN                                             (* keycord:   Z *)
      k := Kbd.GetKey();
      IF k = Kbd.AKey( 0,"Z" )          THEN md := MdExit               (* #KEY ZZ *)
      ELSE Info ("no-such-cord")
      END;
   ELSIF k = Kbd.AKey( 0,"V" ) THEN                                             (* visual mode   _xmark_ *)
      doloop := TRUE;
      lastcy := p.cy;
      WHILE doloop DO
         SelectLines (f,t,p);
         Dot.CursorInMagenta;
         RedrawText (scs);
         RedrawStatus (scs);
         k := Kbd.GetKey();
         IF k = Kbd.Escape THEN                                         (* #KEY V<escape> *)
            DoEscape (f,t,p);
            doloop := FALSE
         ELSIF k = Kbd.AKey (0, "j")    THEN                            (* #KEY Vj *)
            INC (p.cy)
         ELSIF k = Kbd.AKey (0, "k")    THEN                            (* #KEY Vk *)
            IF p.cy > lastcy THEN DEC (p.cy) END
         ELSIF k = Kbd.AKey (0, "d")    THEN                            (* #KEY Vd *)
            DeleteSelection (f,t,p);
            doloop := FALSE;
         ELSIF k = Kbd.AKey (0, "S")    THEN                            (* #KEY VS: DomS *)
            DomS (f,t,p);
            doloop := FALSE
         ELSE Info ("V: no such command"); RedrawStatus (scs);
         END;
      END;
      Dot.CursorInRed;
   ELSE Info ("no-such-key")
   END;
END DispatchKey;
 
PROCEDURE DispatchMouse (k:Kbd.KEY; f:Frame; t:Text.T; p:Pos; VAR md:INTEGER);
VAR
   m,l,c,n: INTEGER;
   a: ARRAY 32 OF CHAR;
   mk: Kbd.KEY;
BEGIN
   Kbd.Mouse (m,l,c, k);
   l := l - f.y;
   c := c - f.x;
   IF (l >= 0) & (l < f.h) & (c >= 0) & (c < f.w) THEN
      mk := Kbd.MouseKey (k);
      Sys.Assert (~(B1On & B3On), "Viewer.DispatchMouse: B1 and B3 should not be on together.");
      IF B1On THEN
        IF   (mk = Kbd.B1) & B1Double THEN                                      (* B1Double: select-word-at-curs *)
                p.cx := p.x0 + c; p.cy := p.y0 + l;
                lastcy  := p.cy;
                B1Drag  := FALSE;
                mode    := NormalMode;
                f.moved := TRUE;
                selectionOn := FALSE;
                DoDouble1 (f,t,p);

        ELSIF mk = Kbd.B1 THEN                                                  (* B1: just B1 *)
                p.cx := p.x0 + c; p.cy := p.y0 + l; 
                lastcy  := p.cy;
                B1Drag  := FALSE;
                mode    := NormalMode;
                f.moved := TRUE;
                selectionOn := FALSE;
        ELSIF  mk = Kbd.B3    THEN   InsertSelection (f,t,p)                    (* B1B3: insertSelection *)
        (* mousewheel *)
        ELSIF (mk = Kbd.B5) & IsCx(c, FlipColumn)   THEN n := f.h - l - 1; ScrollDown (f,t,p, n)
        ELSIF (mk = Kbd.B4) & IsCx(c, FlipColumn)   THEN n := l;           ScrollUp   (f,t,p, n)
        ELSIF (mk = Kbd.B4) & IsCx(c, ScrollColumn) THEN FindPrevDefinition (f,t,p); ScTo (f,t,p, ScTop)
        ELSIF (mk = Kbd.B5) & IsCx(c, ScrollColumn) THEN FindNextDefinition (f,t,p); ScTo (f,t,p, ScTop)
        ELSIF (mk = Kbd.B4) & IsCx(c, RulerColumn)  THEN a := PattChapter; FindPrev (f,t,p, a); ScTo(f,t,p, ScOne)
        ELSIF (mk = Kbd.B5) & IsCx(c, RulerColumn)  THEN a := PattChapter; FindNext (f,t,p, a); ScTo(f,t,p, ScOne)
        ELSIF  mk = Kbd.B4               THEN a := PattXMark;   FindPrev (f,t,p, a); ScTo(f,t,p, ScOne)
        ELSIF  mk = Kbd.B5               THEN a := PattXMark;   FindNext (f,t,p, a); ScTo(f,t,p, ScOne)
        END
      ELSIF B3On THEN
        IF     mk = Kbd.B1               THEN                                   (* B3B1: DelelteSelection *)
                p.cx := p.x0 + c; p.cy := p.y0 + l;
                DeleteSelection (f,t,p)
        ELSIF  mk = Kbd.B3               THEN                                   (* B3: SelectLines *)
                lastcy := p.cy;
                p.cx := p.x0 + c; p.cy := p.y0 + l;
                SelectLines (f,t,p)
        END
      ELSE
        IF     mk = Kbd.B1               THEN Dot.SWW ("B1 without B1On")
        ELSIF  mk = Kbd.B2up             THEN DoAsterix (f,t,p)                 (* B2: select-W-under-C and find *)
        ELSIF  mk = Kbd.B3               THEN Dot.SWW ("B3 without B3On")
        (* mousewheel *)
        ELSIF (mk = Kbd.B5) & IsCx(c, FlipColumn)   THEN n := l;           ScrollDown (f,t,p, n)
        ELSIF (mk = Kbd.B4) & IsCx(c, FlipColumn)   THEN n := f.h - l - 1; ScrollUp   (f,t,p, n)
        ELSIF (mk = Kbd.B4) & IsCx(c, ScrollColumn) THEN                 ScrollUp   (f,t,p, 1)
        ELSIF (mk = Kbd.B5) & IsCx(c, ScrollColumn) THEN                 ScrollDown (f,t,p, 1)
        ELSIF (mk = Kbd.B4) & IsCx(c, RulerColumn)  THEN           FindPrevSection (f,t,p); ScTo(f,t,p, ScOne)
        ELSIF (mk = Kbd.B5) & IsCx(c, RulerColumn)  THEN           FindNextSection (f,t,p); ScTo(f,t,p, ScOne)
        ELSIF  mk = Kbd.B4               THEN a := currentSearchStr;    FindPrev (f,t,p, a); ScTo(f,t,p, ScMid)
        ELSIF  mk = Kbd.B5               THEN a := currentSearchStr;    FindNext (f,t,p, a); ScTo(f,t,p, ScMid)
        END
      END
   END
END DispatchMouse;


PROCEDURE Dispatch(VAR md:INTEGER; scs: Screen);
VAR
  tm,kk : INTEGER;            (* time kountkey *)
  sx: Screen;
  f:  Frame;
  t:  Text.T;
  p:  Pos;
  k:  Kbd.KEY;
BEGIN
  md   := MdOk;
  tm   := Sys.Time();
  f := scs.f;                                   (* start with first screen *)
  t := scs.t;
  p := scs.p;
  kk := 0;
  REPEAT
    k := Kbd.NextKey();
    IF k # 0 THEN
       IF Kbd.IsMKey(k) THEN
          FindScreen (sx, f,t,p, scs, k);           (* change screen only on mouse-click *)
          IF (Kbd.MouseKey (k) = Kbd.B1) & ~B3On        THEN B1On := TRUE END;
          IF (Kbd.MouseKey (k) = Kbd.B3) & ~B1On        THEN B3On := TRUE END;
          IF (Kbd.MouseKey (k) = Kbd.B1up)              THEN B1On := FALSE; B1Drag := FALSE END;
          IF (Kbd.MouseKey (k) = Kbd.B3up)              THEN B3On := FALSE END;
          IF  Kbd.MouseKey (k) = Kbd.B1 THEN
             IF Sys.mTime() - lastB1Time < 250 THEN
                B1Double := TRUE
             ELSE B1Double := FALSE
             END;
             lastB1Time := Sys.mTime();
          END;
          DispatchMouse (k, f,t,p, md)
       ELSE
(*           IF    (mode = NormalMode) & (k = Kbd.Backspace)    THEN DoBackspace (sx) *)
(*           ELSIF (mode = NormalMode) & (k = Kbd.AKey (0,' ')) THEN DoSpace     (sx) *)
(*           ELSE  DispatchKey (k, f,t,p, md) *)
(*           END *)
          DispatchKey (k, f,t,p, md, scs)
       END;
       Kbd.ShowKey(keyinfo, k);
       RedrawStatus (scs);
       RedrawText (scs);
       RedrawCursor (f,t,p, CursorActive);
       kk := 0
    ELSE
       Sys.Sleep(100);
       INC(kk);
       IF kk > 30 THEN
          kk := 0;
          Info("");
          keyinfo := "<>";
          Save (t);
          RedrawStatus (scs);
          RedrawCursor (f,t,p, CursorActive);
       END
    END;
    IF exitOnIterfile & (tm # Sys.Time()) THEN
       ExitOnIterfile (md);
       tm := Sys.Time()
    END;
  UNTIL (md = MdExit) OR (md = MdChangeFile) OR (md = MdTextContents);
  scs.p := p;
END Dispatch;


(* ------------------------------------------------------------------------- *)
(* :chapter: START *)
PROCEDURE CheckForCy (scs: Screen; xh: INTEGER);                (** xh < cursur-position ? *)
BEGIN
   IF xh <= (scs.p.cy - scs.p.y0) THEN
      scs.p.cy := scs.p.y0
   END
END CheckForCy;

PROCEDURE Start*(VAR md: INTEGER; scs: Screen);                  (** start viewer with screens *)
VAR
   a,b : ARRAY 256 OF CHAR;
   path : Line.T;
BEGIN
   Sys.XtermSize (xh, xw);
   CheckForCy (scs, xh);
   Dot.CursorInRed; Dot.CursorAsBlinkingBlock;
   Dot.OnStatus; Dot.Clear;
   path := Text.Path (scs.t);
   activeScreen := Line.Create ("");
   a := "PET - "; Str.Append (a, path^); Dot.SetWindowTitle (a);
   IF scs.p.cy >= Text.Length (scs.t) THEN
      scs.p.y0 := 0;
      scs.p.cy := 0;
      scs.p.cx := 0;
   END;
   RedrawText   (scs);
   RedrawStatus (scs);
   Dispatch (md, scs);
   Dot.CursorShow;
   Dot.SetWindowTitle (Sys.pwd);
END Start;

PROCEDURE NewScreen* (name: ARRAY OF CHAR; line,col, lines,cols: INTEGER; t:Text.T; pos:Pos): Screen;
VAR
   f: Frame;
   p: Pos;
   sc: Screen;
BEGIN
   NEW (f);
   f.y := line;
   f.x := col;
   f.h := lines;
   f.w := cols;
   f.moved := TRUE;
   NEW (p);
   p.x0 := pos.x0;
   p.y0 := pos.y0;
   p.cx := pos.cx;
   p.cy := pos.cy;
   NEW (sc);
   sc.name := Line.New (name);
   sc.f := f;
   sc.t := t;
   sc.p := p;
   sc.next := NIL;
   RETURN sc;
END NewScreen;

PROCEDURE Append* (VAR scs: Screen; sc: Screen);        (** append screen to screens *)
VAR sn,sx: Screen;
BEGIN
   IF scs # NIL THEN
      sx := scs;
      WHILE sx.next # NIL DO sx := sx.next END;
      sx.next := sc;
   ELSE
      scs := sc;
   END;
END Append;

PROCEDURE Dott* (scs: Screen);                  (** print list of screens *)
BEGIN
   WHILE scs # NIL DO
      Dot.Lf;
      Dot.Mess (scs.name^);
      Dot.Tab (12);
         Dot.Int (scs.f.x, 4);
         Dot.Int (scs.f.y, 4);
         Dot.Int (scs.f.w, 4);
         Dot.Int (scs.f.h, 4);
      Dot.Tab (32);
         spc; Dot.Chr (Text.ModfChar (scs.t)); spc;
         Line.Print (Text.Name (scs.t));
      Dot.Tab (48);
         Dot.Int (scs.p.x0, 4);
         Dot.Int (scs.p.y0, 4);
         Dot.Int (scs.p.cx, 4);
         Dot.Int (scs.p.cy, 4);
      scs := scs.next;
   END;
   Dot.Lff;
END Dott;


(* ------------------------------------------------------------------------- *)
(* :chapter: MAIN *)
BEGIN

        PattChapter := ":chapter"; Str.AppendChar (PattChapter, ':');
        PattSection := ":section"; Str.AppendChar (PattSection, ':');
        PattProc    := "PROCEDURE";
        PattXMark   := "_xmark";   Str.AppendChar (PattXMark, '_');
        PattConst   := "CONST";
        PattType    := "TYPE";
        PattVar     := "VAR";
        PattBegin   := "BEGIN";
        currentSearchStr := PattChapter;

        mode := NormalMode;
        exitOnIterfile := TRUE;
        selectedText := NIL;                                                    (* #SEL *)
        selectionOn  := FALSE;                                                  (* #SEL *)
        B1On         := FALSE;
        B3On         := FALSE;
        B1Drag       := FALSE;
        B1Double     := FALSE;
        keyinfo      := "<>";
        lastB1Time   := Sys.mTime();
        lastdo       := Jmpl;
        cmt.long := TRUE;
        cmt.len  := 2;
        cmt.c1   := '(';
        cmt.c2   := '*';
        lastfChar := 0X;
        COPY (Sys.home, vimselFilename); Str.Append (vimselFilename, "r/vimsel");

END Viewer.
(* ------------------------------------------------------------------------- *)
(* :file: (c) sts-q 2022-Sep  2024-Feb  *)

