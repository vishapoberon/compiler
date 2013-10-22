(* Oberon Library      -    SunOS 4.1    -      AFB 8/90 *)
(* (c) University of Ulm, Sektion Informatik, D-7900 Ulm *)

MODULE ulmMC68881;

   (* library interface to MC68881 instructions *)

   IMPORT SYS := SYSTEM;

   CONST
      available* = FALSE; (* TRUE if MC68881 present *)

      (* rounding modes *)
      toNearest* = 0;
      towardZero* = 1;
      towardMinusInfinity* = 2;
      towardPlusInfinity* = 3;

      (* rounding precision *)
      extended* = 0;
      single* = 1;
      double* = 2;

      (* exceptions *)
      branchOnUnordered* = 0;
      signalingNotANumber* = 1;
      operandError* = 2;
      overflow* = 3;
      underflow* = 4;
      divideByZero* = 5;
      inexactOperation* = 6;
      inexactDecimalInput* = 7;

   CONST
      floatlen* = 4; (* length of a single precision real number *)

   (* monadic operations *)

   PROCEDURE FACOS*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FACOS;

   PROCEDURE FASIN*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FASIN;

   PROCEDURE FATAN*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FATAN;

   PROCEDURE FATANH*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FATANH;

   PROCEDURE FCOS*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FCOS;

   PROCEDURE FCOSH*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FCOSH;

   PROCEDURE FETOX*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FETOX;

   PROCEDURE FETOXM1*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FETOXM1;

   PROCEDURE FGETEXP*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FGETEXP;

   PROCEDURE FGETMAN*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FGETMAN;

   PROCEDURE FLOG10*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FLOG10;

   PROCEDURE FLOG2*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FLOG2;

   PROCEDURE FLOGN*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FLOGN;

   PROCEDURE FLOGNP1*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FLOGNP1;

   PROCEDURE FSIN*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FSIN;

   PROCEDURE FSINH*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FSINH;

   PROCEDURE FSQRT*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FSQRT;

   PROCEDURE FTAN*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FTAN;

   PROCEDURE FTANH*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FTANH;

   PROCEDURE FTENTOX*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FTENTOX;

   PROCEDURE FTWOTOX*(x: LONGREAL) : LONGREAL;
   BEGIN
      RETURN ABS(x)
   END FTWOTOX;


   PROCEDURE GetExceptionEnable*(VAR exceptions: SET);
   BEGIN
      exceptions := {};
   END GetExceptionEnable;

   PROCEDURE SetExceptionEnable*(exceptions: SET);
   BEGIN
      exceptions := {};
   END SetExceptionEnable;


   PROCEDURE GetRoundingMode*(VAR precision, mode: INTEGER);
   BEGIN
      precision := 1;
      mode := 2;
   END GetRoundingMode;

   PROCEDURE SetRoundingMode*(precision, mode: INTEGER);
   BEGIN
      precision := 1;
      mode := 2;
   END SetRoundingMode;


   (* conversions to and from single precision (C's float);
      float must consist of at least floatlen bytes
   *)

   PROCEDURE RealToFloat*(real: LONGREAL; VAR float: ARRAY OF SYS.BYTE);
   BEGIN
      (*SYS.WMOVE(SYS.ADR(real), SYS.ADR(float), floatlen DIV 4);*)
   END RealToFloat;

   PROCEDURE FloatToReal*(float: ARRAY OF SYS.BYTE; VAR real: LONGREAL);
   BEGIN
      (*SYS.WMOVE(SYS.ADR(float), SYS.ADR(real), floatlen DIV 4);*)
   END FloatToReal;

END ulmMC68881.
