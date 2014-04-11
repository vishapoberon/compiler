MODULE vt100;

IMPORT Console, Strings, IntStr := oocIntStr;

CONST

Escape* = 1BX;
SynchronousIdle = 16X;
LeftCrotchet* = '[';

(* colors *)
Black*        = "22;30m";
Red*          = "22;31m";
Green*        = "22;32m";
Brown*        = "22;33m";
Blue*         = "22;34m";
Magenta*      = "22;35m";
Cyan*         = "22;36m";
Gray*         = "22;37m";
DarkGray*     = "01;30m";
LightRed*     = "01;31m";
LightGreen*   = "01;32m";
Yellow*       = "01;33m";
LightBlue*    = "01;34m";
LightMagenta* = "01;35m";
LightCyan*    = "01;36m";
White*        = "01;37m";

VAR 
CSI* : ARRAY 5 OF CHAR;
tmpstr : ARRAY 32 OF CHAR;

(* if n = 0 then clears from cursor to end of the screen
   if n = 1 then clears from cursor to beginning of the screen
   if n = 2 then clears entire screen *)
PROCEDURE ED* (n : INTEGER);
VAR nstr : ARRAY 2 OF CHAR;
    mstr : ARRAY 5 OF CHAR;
BEGIN
   IntStr.IntToStr (n, nstr);
   COPY(CSI, mstr);
   Strings.Append(nstr, mstr);
   Strings.Append("J", mstr);
   Console.String(mstr);
END ED;

PROCEDURE EraseDisplay*;
BEGIN
   ED(2);
END EraseDisplay;

(* pascal crt like wrapper *)
PROCEDURE ClrScr*;
BEGIN
   ED(2);
END ClrScr;

(* Cursor position, moves cursor to row n, column m *)
PROCEDURE CUP*(n, m : INTEGER);
VAR nstr, mstr : ARRAY 5 OF CHAR;
    str : ARRAY 12 OF CHAR;
BEGIN
   IF n < 1 THEN n := 1 END;
   IF m < 1 THEN m := 1 END;
   IntStr.IntToStr(n, nstr);
   IntStr.IntToStr(m, mstr);

   COPY (CSI, str);
   Strings.Append (nstr, str);
   Strings.Append (';', str);
   Strings.Append (mstr, str);
   Strings.Append ("H", str);
   Console.String (str); 

END CUP;

 (* pascal crt like wrapper *)
PROCEDURE GotoXY* (x, y: INTEGER);
BEGIN
   CUP (y, x);
END GotoXY;

BEGIN
(* init CSI sequence *)
COPY(Escape, CSI);
Strings.Append(LeftCrotchet, CSI);

EraseDisplay;
GotoXY (0, 0);
COPY(CSI, tmpstr);
Strings.Append(Green, tmpstr);
Strings.Append("hello", tmpstr);
Console.String(tmpstr); Console.Ln;

END vt100.
