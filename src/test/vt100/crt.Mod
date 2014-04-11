MODULE crt;

IMPORT vt100, Unix, Console,
   Strings; (* strings to remove later ? *)

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

BEGIN
(* test *)
      EraseDisplay;
      GotoXY (0, 0);
      COPY(vt100.CSI, tmpstr);
      Strings.Append(vt100.Green, tmpstr);
      Strings.Append("hello", tmpstr);
      Console.String(tmpstr); Console.Ln;
      Delay (2000);


END crt.
