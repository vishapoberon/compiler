MODULE crt;

IMPORT vt100, Unix, Console,
   Strings; (* strings to remove later ? *)

CONST

(* Foreground and background color constants *)
  Black*         = 0;
  Blue*          = 1;
  Green*         = 2;
  Cyan*          = 3;
  Red*           = 4;
  Magenta*       = 5;
  Brown*         = 6;
  LightGray*     = 7;

(* Foreground color constants *)
  DarkGray*      = 8;
  LightBlue*     = 9;
  LightGreen*    = 10;
  LightCyan*     = 11;
  LightRed*      = 12;
  LightMagenta*  = 13;
  Yellow*        = 14;
  White*         = 15;

(* Add-in for blinking *)
   Blink*         = 128;

TYPE
   PFdSet = POINTER TO Unix.FdSet;

VAR tmpstr : ARRAY 23 OF CHAR;

   PROCEDURE EraseDisplay*;
   BEGIN
      vt100.ED(2);
   END EraseDisplay;

   PROCEDURE ClrScr*;
   BEGIN
      vt100.ED(2);
   END ClrScr;

   PROCEDURE ClrEol*;
   BEGIN
      vt100.EL(0);
   END ClrEol;

   PROCEDURE cursoroff*;
   BEGIN
      vt100.DECTCEMl;
   END cursoroff;

   PROCEDURE cursoron*;
   BEGIN
      vt100.DECTCEMh;
   END cursoron;

   PROCEDURE Delay*( ms : INTEGER);
   VAR i : LONGINT;
       tv : Unix.Timeval;
       pfd : PFdSet;
   BEGIN
      tv.sec := 0;
      tv.usec := ms * 1000;
      pfd := NIL;
      i := Unix.Select(0, pfd^, pfd^, pfd^, tv);
   END Delay;

   PROCEDURE GotoXY* (x, y: INTEGER);
   BEGIN
      vt100.CUP (y, x);
   END GotoXY;

   PROCEDURE HighVideo*;
   VAR tmpstr: ARRAY 5 OF CHAR;
   BEGIN
      COPY (vt100.CSI, tmpstr);
      Strings.Append(vt100.Bold, tmpstr);
      Console.String(tmpstr);
   END HighVideo;
   
   PROCEDURE DelLine*;
   BEGIN
      vt100.EL(2);
   END DelLine;

   PROCEDURE InsLine*;
   BEGIN
      vt100.SCP;
      Console.Ln;
      vt100.RCP;
   END InsLine;

   PROCEDURE LowVideo*;
   VAR tmpstr : ARRAY 7 OF CHAR;
   BEGIN
      COPY (vt100.CSI, tmpstr);
      Strings.Append(vt100.ResetBold, tmpstr);
      Console.String(tmpstr);
   END LowVideo;

   PROCEDURE NormVideo*;
   VAR tmpstr : ARRAY 7 OF CHAR;
   BEGIN
      COPY(vt100.CSI, tmpstr);
      Strings.Append(vt100.ResetAll, tmpstr);
      Console.String(tmpstr);
   END NormVideo;
   
   PROCEDURE SetAttr(attr : ARRAY OF CHAR);
   VAR tmpstr : ARRAY 16 OF CHAR;
   BEGIN
      COPY(vt100.CSI, tmpstr);
      Strings.Append(attr, tmpstr);
      Console.String(tmpstr);
   END SetAttr;

   PROCEDURE TextBackground*(color : SHORTINT);
   BEGIN
      IF    color = Black THEN
         SetAttr(vt100.BBlack)
      ELSIF color = Blue  THEN
         SetAttr(vt100.BBlue)
      ELSIF color = Green THEN
         SetAttr(vt100.BGreen)
      ELSIF color = Cyan  THEN
         SetAttr(vt100.BCyan)
      ELSIF color = Red   THEN
         SetAttr(vt100.BRed)
      ELSIF color = Magenta THEN
         SetAttr(vt100.BMagenta)
      ELSIF color = Brown   THEN
         SetAttr(vt100.BYellow)
      ELSIF color = LightGray  THEN
         SetAttr(vt100.BLightGray)
      ELSIF color = DarkGray   THEN
         SetAttr(vt100.BDarkGray)
      ELSIF color = LightBlue  THEN
         SetAttr(vt100.BLightBlue)
      ELSIF color = LightGreen THEN
         SetAttr(vt100.BLightBlue)
      ELSIF color = LightCyan  THEN
         SetAttr(vt100.BLightCyan)
      ELSIF color = LightRed THEN
         SetAttr(vt100.BLightRed)
      ELSIF color = LightMagenta THEN
         SetAttr(vt100.BLightMagenta)
      ELSIF color = Yellow THEN
         SetAttr(vt100.BLightYellow)
      ELSIF color = White THEN
         SetAttr(vt100.BWhite)
      END;
   END TextBackground;

   PROCEDURE TextColor*(color : SHORTINT);
   BEGIN
      IF    color = Black THEN
         SetAttr(vt100.Black)
      ELSIF color = Blue  THEN
         SetAttr(vt100.Blue)
      ELSIF color = Green THEN
         SetAttr(vt100.Green)
      ELSIF color = Cyan  THEN
         SetAttr(vt100.Cyan)
      ELSIF color = Red   THEN
         SetAttr(vt100.Red)
      ELSIF color = Magenta THEN
         SetAttr(vt100.Magenta)
      ELSIF color = Brown   THEN
         SetAttr(vt100.Yellow)
      ELSIF color = LightGray  THEN
         SetAttr(vt100.LightGray)
      ELSIF color = DarkGray   THEN
         SetAttr(vt100.DarkGray)
      ELSIF color = LightBlue  THEN
         SetAttr(vt100.LightBlue)
      ELSIF color = LightGreen THEN
         SetAttr(vt100.LightBlue)
      ELSIF color = LightCyan  THEN
         SetAttr(vt100.LightCyan)
      ELSIF color = LightRed THEN
         SetAttr(vt100.LightRed)
      ELSIF color = LightMagenta THEN
         SetAttr(vt100.LightMagenta)
      ELSIF color = Yellow THEN
         SetAttr(vt100.LightYellow)
      ELSIF color = White THEN
         SetAttr(vt100.White)
      END;
   END TextColor;

END crt.
