MODULE Dot;   (* :file: Dot.Mod  --  Print to Stdout. *) 
(* VOC adaptation, 2026-10-16: fixed-width types and the VOC system adapter. *)
IMPORT ssqTypes, Sys := ssqSys, Ink, I := Int;

CONST
        esc = 1BX;
        ErrTab = 27;                           (* errmess tabulator position *)
TYPE INTEGER = ssqTypes.Integer;
        
VAR
        atLineStart:   BOOLEAN;
        ddx          : BOOLEAN;
        currentInk:    ARRAY 32 OF CHAR;
        currentGrink:  ARRAY 32 OF CHAR;


(* ========================================================================= *)
(* :chapter: OUT *)
PROCEDURE Chr*(c: CHAR);
BEGIN
  Sys.OutChr(c);
  atLineStart := FALSE;
END Chr;

PROCEDURE Mess*(mess: ARRAY OF CHAR);
BEGIN
  Sys.Out(mess);
  atLineStart := FALSE;
END Mess;

PROCEDURE Spc*;
BEGIN
  Chr(" ")
END Spc;

PROCEDURE Int*(n, width: I.T);
VAR
  a   : ARRAY 128 OF CHAR;
  i,j : I.T;
BEGIN
  I.Show(a, n, width);
  Mess(a);
END Int;

PROCEDURE Bool*(b: BOOLEAN; width: INTEGER);
VAR i,w : INTEGER;
BEGIN
  IF b THEN 
     w := width - 4 
  ELSE w := width - 5 
  END;
  FOR i := 1 TO w DO Spc END;
  IF b THEN
    Mess("TRUE")
  ELSE Mess("FALSE")
  END
END Bool;

PROCEDURE Lf*;
VAR
  i: INTEGER;
BEGIN
  IF ~atLineStart THEN
    IF Sys.mouseTracking THEN Sys.OutChr (0DX) END;
    Chr (0AX);
    atLineStart := TRUE;
  END;
END Lf;

PROCEDURE Lff*;
BEGIN
  Lf;
  atLineStart := FALSE;
  Lf;
END Lff;

PROCEDURE Tab* (tab : I.T);
VAR c, d : CHAR;
BEGIN
   c := CHR (tab DIV 10 + 48);
   d := CHR (tab MOD 10 + 48);
   Chr (1BX); Chr ('['); Chr(c); Chr(d); Chr('G');
   Chr (' '); Chr ('|');
   atLineStart := FALSE;
END Tab;



(* ========================================================================= *)
(* :chapter: CSI and OSC *)
PROCEDURE cout(c: CHAR);                BEGIN Sys.OutChr(c); END cout;    (* don't mess up lf *)
PROCEDURE out(a: ARRAY OF CHAR);        BEGIN Sys.Out(a);    END out;     (* don't mess up lf *)

PROCEDURE Csi(seq: ARRAY OF CHAR);      BEGIN cout(esc);      out(seq);                 END Csi;
PROCEDURE Osc(seq: ARRAY OF CHAR);      BEGIN cout(esc);      out(seq);   cout( 07X );  END Osc;

PROCEDURE In(color: ARRAY OF CHAR);
BEGIN
  IF color # currentInk THEN
    Csi("[38;2;"); out(color); cout("m");
    COPY(color, currentInk)
  END
END In;

PROCEDURE On(color: ARRAY OF CHAR);
BEGIN
  IF color # currentGrink THEN
    Csi("[48;2;"); out(color); cout("m");
    COPY(color, currentGrink)
  END
END On;

PROCEDURE AsSection*;                   BEGIN In( Ink.YELLOW );         END AsSection;
PROCEDURE AsText*;                      BEGIN In( Ink.LIGHTGRAY );      END AsText;
PROCEDURE AsComment*;                   BEGIN In( Ink.GRAY );           END AsComment;
PROCEDURE AsName*;                      BEGIN In( Ink.STRAW );          END AsName;
PROCEDURE AsString*;                    BEGIN In( Ink.YELLOW );         END AsString;
PROCEDURE AsDbg*;                       BEGIN In( Ink.PINK );           END AsDbg;
PROCEDURE AsErr*;                       BEGIN In( Ink.RED );            END AsErr;
PROCEDURE AsStd*;                       BEGIN In( Ink.WHITE );          END AsStd;
PROCEDURE AsStatus*;                    BEGIN In( Ink.SANDY );          END AsStatus;
PROCEDURE AsPinkMark*;                  BEGIN In( Ink.PINK );           END AsPinkMark;
PROCEDURE AsPrompt*;                    BEGIN In( Ink.SKY );            END AsPrompt;

PROCEDURE OnStd*;                       BEGIN On( Ink.STDBG );          END OnStd;
PROCEDURE OnStatus*;                    BEGIN On( Ink.OLIVEBG );        END OnStatus;
PROCEDURE OnBacklight*;                 BEGIN On( Ink.SANDYBG );        END OnBacklight;
PROCEDURE OnSelection*;                 BEGIN On( Ink.ROSEBG );         END OnSelection;
(* PROCEDURE OnText*;                      BEGIN On( Ink.DARKBG );         END OnText; *)
(* PROCEDURE OnRuler*;                     BEGIN On( Ink.GRAYBG );         END OnRuler; *)

(* darker text and ruler background on laptop *)
PROCEDURE OnText*;                      BEGIN On( Ink.BLACKBG );        END OnText;
PROCEDURE OnRuler*;                     BEGIN On( Ink.DARKBG );         END OnRuler;

PROCEDURE Clear*;                       BEGIN Csi("[2J"); Csi("[H")     END Clear;
PROCEDURE ClearLineTail*;               BEGIN Csi("[0K");               END ClearLineTail;
PROCEDURE ClearLineHead*;               BEGIN Csi("[1K");               END ClearLineHead;
PROCEDURE ClearLine*;                   BEGIN Csi("[2K");               END ClearLine;

PROCEDURE CursorHide*;                  BEGIN Csi("[?25l")              END CursorHide;
PROCEDURE CursorShow*;                  BEGIN Csi("[?25h")              END CursorShow;

PROCEDURE CursorSave*;                  BEGIN Csi("[s")                 END CursorSave;
PROCEDURE CursorRestore*;               BEGIN Csi("[u")                 END CursorRestore;

PROCEDURE CursorAsBlinkingBlock*;       BEGIN Csi("[1 q")               END CursorAsBlinkingBlock;
PROCEDURE CursorAsSteadyBlock*;         BEGIN Csi("[2 q")               END CursorAsSteadyBlock;
PROCEDURE CursorAsBlinkingLine*;        BEGIN Csi("[3 q")               END CursorAsBlinkingLine;
PROCEDURE CursorAsSteadyLine*;          BEGIN Csi("[4 q")               END CursorAsSteadyLine;
PROCEDURE CursorAsBlinkingBar*;         BEGIN Csi("[5 q")               END CursorAsBlinkingBar;
PROCEDURE CursorAsSteadyBar*;           BEGIN Csi("[6 q")               END CursorAsSteadyBar;

PROCEDURE CursorInRed*;                 BEGIN Osc("]12;red")            END CursorInRed;
PROCEDURE CursorInGreen*;               BEGIN Osc("]12;green")          END CursorInGreen;
PROCEDURE CursorInBlue*;                BEGIN Osc("]12;blue")           END CursorInBlue;
PROCEDURE CursorInWhite*;               BEGIN Osc("]12;white")          END CursorInWhite;
PROCEDURE CursorInYellow*;              BEGIN Osc("]12;yellow")         END CursorInYellow;
PROCEDURE CursorInMagenta*;             BEGIN Osc("]12;magenta")        END CursorInMagenta;
PROCEDURE CursorInCyan*;                BEGIN Osc("]12;cyan")           END CursorInCyan;
PROCEDURE CursorInBlack*;               BEGIN Osc("]12;black")          END CursorInBlack;
PROCEDURE CursorInGray*;                BEGIN Osc("]12;gray")           END CursorInGray;

PROCEDURE At* (line, col: INTEGER);
(** Move cursor to line/col. *)
VAR
  a: ARRAY 32 OF CHAR;
BEGIN
  cout(esc); cout("[");
  I.Show(a, line, 0); out(a); cout(";");
  I.Show(a, col, 0);  out(a); cout("H");
END At;

PROCEDURE ScrollUp*(n: INTEGER);
VAR
  a: ARRAY 32 OF CHAR;
BEGIN
  cout(esc);
  cout("[");
  I.Show(a, n, 0); out(a);
  cout("S");
END ScrollUp;

PROCEDURE ScrollDown*(n: INTEGER);
VAR
  a: ARRAY 32 OF CHAR;
BEGIN
  cout(esc);
  cout("[");
  I.Show(a, n, 0); out(a);
  cout("T");
END ScrollDown;

PROCEDURE SetWindowTitle*(text: ARRAY OF CHAR);
BEGIN
  cout (esc);
  out  ("]0;");
  out  (text);
  cout (07X);
END SetWindowTitle;



(* ========================================================================= *)
(* :chapter: MACROS *)
PROCEDURE Chapter*( mess : ARRAY OF CHAR );
BEGIN
  Lff; AsSection; Mess( "============  " ); Mess( mess );
  Lf; AsText;
END Chapter;

PROCEDURE Section*( mess : ARRAY OF CHAR );
BEGIN
  Lff; AsSection; Mess( "------------  " ); Mess( mess );
  Lf; AsText;
END Section;

PROCEDURE Errmess*(mess: ARRAY OF CHAR);
BEGIN
   (* OnStd; *)
   AsErr;
   Lf; Mess ("############  Errmess   "); Tab (ErrTab); Mess(mess);
   Lf;
END Errmess;

PROCEDURE Errint* (n: I.T);
VAR a: ARRAY 32 OF CHAR;
BEGIN
   I.Show (a, n, 8);
   Lf; Mess ("############  Errint  "); Tab (ErrTab); Mess (a);
END Errint; 

PROCEDURE Errno* (errno : INTEGER);
BEGIN
   Lf; Mess ("############  Errno "); Int (errno, 5); Tab (ErrTab);
   CASE errno OF
    |  -2: Mess ("No such file or dircetory.")
    |  -9: Mess ("Bad file number.")
    | -13: Mess ("Permission denied.")
   ELSE   Mess ("$ errno <n> knows more...")
   END;
   Lf;
END Errno;

PROCEDURE Error*(mess: ARRAY OF CHAR);
BEGIN
   (* OnStd; *)
   AsErr;
   Lf; Mess ("############  Error  "); Tab (ErrTab); Mess(mess);
   AsStd;
   Lff;
   Sys.ExitFail;
END Error;

PROCEDURE ROADWORK*(mess: ARRAY OF CHAR);
BEGIN
  (* OnStd; *)
  AsErr;
  Lff;
  Lff;
  Lf; Mess("############  ROADWORK");
  Lf; Mess(mess);
  AsStd;
  Lff;
  Sys.ExitFail;
END ROADWORK;

PROCEDURE SWW*( mess: ARRAY OF CHAR);
BEGIN
  AsErr;
  Lff;
  Lff;
  Lf; Mess("############  Something went wrong:");
  Lf; Mess(mess);
  AsStd;
  Lff;
  Sys.ExitFail;
END SWW;

PROCEDURE DDX*;
BEGIN
   IF ddx THEN
      AsText; ddx := FALSE
   ELSE AsDbg; ddx := TRUE
   END
END DDX;

(* ========================================================================= *)
(* :chapter: MAIN *)
BEGIN

  atLineStart     := TRUE;
  currentInk[0]   := 0X;
  currentGrink[0] := 0X;
  ddx             := FALSE;

END Dot.   :file: (c) sts-q 2022-Sep,Nov  2024-Feb
