MODULE vt100;

IMPORT Console, Strings, IntStr := oocIntStr;
 (* reference http://en.wikipedia.org/wiki/ANSI_escape_code *)
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

   PROCEDURE EscSeq0 (letter : ARRAY OF CHAR);
      VAR
       cmd : ARRAY 9 OF CHAR;
   BEGIN
      COPY(CSI, cmd);
      Strings.Append (letter, cmd);
      Console.String (cmd);
   END EscSeq0;

   PROCEDURE EscSeq (n : INTEGER; letter : ARRAY OF CHAR);
      VAR nstr : ARRAY 2 OF CHAR;
       cmd : ARRAY 7 OF CHAR;
   BEGIN
      IntStr.IntToStr (n, nstr);
      COPY(CSI, cmd);
      Strings.Append (nstr, cmd);
      Strings.Append (letter, cmd);
      Console.String (cmd);
   END EscSeq;

  PROCEDURE EscSeqSwapped (n : INTEGER; letter : ARRAY OF CHAR);
      VAR nstr : ARRAY 2 OF CHAR;
       cmd : ARRAY 7 OF CHAR;
   BEGIN
      IntStr.IntToStr (n, nstr);
      COPY(CSI, cmd);
      Strings.Append (letter, cmd);
      Strings.Append (nstr, cmd);
      Console.String (cmd);
   END EscSeqSwapped;

   PROCEDURE EscSeq2(n, m : INTEGER; letter : ARRAY OF CHAR);
      VAR nstr, mstr : ARRAY 5 OF CHAR;
          cmd : ARRAY 12 OF CHAR;
   BEGIN
      IntStr.IntToStr(n, nstr);
      IntStr.IntToStr(m, mstr);

      COPY (CSI, cmd);
      Strings.Append (nstr, cmd);
      Strings.Append (';', cmd);
      Strings.Append (mstr, cmd);
      Strings.Append (letter, cmd);
      Console.String (cmd); 

   END EscSeq2;



(* Cursor up 
   moves cursor n cells in the given direction. if the cursor is already at the edge of the screen, this has no effect *)

   PROCEDURE CUU*(n : INTEGER);
   BEGIN
      EscSeq (n, 'A');
   END CUU;

(* Cursor down
   moves cursor n cells in the given direction. if the cursor is already at the edge of the screen, this has no effect *)

   PROCEDURE CUD*(n : INTEGER);
   BEGIN
      EscSeq (n, 'B');
   END CUD;


(* Cursor forward 
   moves cursor n cells in the given direction. if the cursor is already at the edge of the screen, this has no effect *)

   PROCEDURE CUF*(n : INTEGER);
   BEGIN
      EscSeq (n, 'C');
   END CUF;

(* Cursor back 
   moves cursor n cells in the given direction. if the cursor is already at the edge of the screen, this has no effect *)

   PROCEDURE CUB*(n : INTEGER);
   BEGIN
      EscSeq (n, 'D');
   END CUB;

(* Curnser Next Line
   moves cursor to beginning of the line n lines down *)

   PROCEDURE CNL*( n: INTEGER);
   BEGIN
      EscSeq (n, 'E');
   END CNL;


(* Cursor Previous Line
   Moves cursor to beginning of the line n lines down *)

   PROCEDURE CPL*( n : INTEGER);
   BEGIN
      EscSeq (n, 'F');
   END CPL;

(* Cursor Horizontal Absolute
   Moves the cursor to column n *)

   PROCEDURE CHA*( n : INTEGER);
   BEGIN
      EscSeq (n, 'G');
   END CHA;

 (* Cursor position, moves cursor to row n, column m *)
   PROCEDURE CUP*(n, m : INTEGER);
   BEGIN
      EscSeq2 (n, m, 'H');
   END CUP;

   (* Erase Display
   if n = 0 then clears from cursor to end of the screen
   if n = 1 then clears from cursor to beginning of the screen
   if n = 2 then clears entire screen *)

   PROCEDURE ED* (n : INTEGER);
   BEGIN
      EscSeq(n, 'J');
   END ED;

   (* Erase in Line
      Erases part of the line. If n is zero, clear from cursor to the end of the line. If n is one, clear from cursor to beginning of the line. If n is two, clear entire line. Cursor position does not change *)
   PROCEDURE EL*( n : INTEGER);
   BEGIN
      EscSeq(n, 'K');
   END EL;

(* Scroll Up
   Scroll whole page up by n lines. New lines are added at the bottom *)
   PROCEDURE SU*( n : INTEGER);
   BEGIN
      EscSeq(n, 'S')
   END SU;

(* Scroll Down
   Scroll whole page down by n (default 1) lines. New lines are added at the top *)  
   PROCEDURE SD*( n : INTEGER);
   BEGIN
      EscSeq(n, 'T');
   END SD;

(* Horizontal and Vertical Position,
   Moves the cursor to row n, column m. Both default to 1 if omitted. Same as CUP *)
   PROCEDURE HVP*(n, m : INTEGER);
   BEGIN
      EscSeq2 (n, m, 'f');
   END HVP;

(* Select Graphic Rendition
   Sets SGR parameters, including text color. After CSI can be zero or more parameters separated with ;. With no parameters, CSI m is treated as CSI 0 m (reset / normal), which is typical of most of the ANSI escape sequences *)

   PROCEDURE SGR*( n : INTEGER);
   BEGIN
         EscSeq(n, 'm');
   END SGR;

   PROCEDURE SGR2*( n, m : INTEGER);
   BEGIN
         EscSeq2(n, m, 'm');
   END SGR2;

(* Device Status Report
   Reports the cursor position (CPR) to the application as (as though typed at the keyboard) ESC[n;mR, where n is the row and m is the column.)  *)

   PROCEDURE DSR*(n : INTEGER);
   BEGIN
         EscSeq(6, 'n');
   END DSR;

(* Save Cursor Position *)

   PROCEDURE SCP*;
   BEGIN
      EscSeq0('s');
   END SCP;

(* Restore Cursor Position *)

   PROCEDURE RCP*;
   BEGIN
      EscSeq0('u');
   END RCP;

(* Hide the cursor *)
   PROCEDURE DECTCEMl*;
   BEGIN
      EscSeq0("?25l")
   END DECTCEMl;

(* shows the cursor *)
   PROCEDURE DECTCEMh*;
   BEGIN
      EscSeq0("?25h")
   END DECTCEMh;

   BEGIN
   (* init CSI sequence *)
      COPY(Escape, CSI);
      Strings.Append(LeftCrotchet, CSI);
(*
      EraseDisplay;
      GotoXY (0, 0);
      COPY(CSI, tmpstr);
      Strings.Append(Green, tmpstr);
      Strings.Append("hello", tmpstr);
      Console.String(tmpstr); Console.Ln;
*)
   END vt100.
