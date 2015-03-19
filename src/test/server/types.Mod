MODULE types;
IMPORT SYS := SYSTEM;


TYPE
     intarr64 = ARRAY 8 OF SYS.BYTE; (* to emulate int16 on x86_64; -- noch *)
     intarr32 = ARRAY 4 OF SYS.BYTE;
     intarr16 = ARRAY 2 OF SYS.BYTE;
     Int16* = intarr16; (* INTEGER on 32 bit platform *)
     Int32* = INTEGER;
     Int64* = LONGINT;
     String* = ARRAY 256 OF CHAR;
     
     PROCEDURE LongintToInt16*(int: LONGINT; VAR int16: Int16);
      VAR longintarr : intarr64;
   BEGIN
      (*RETURN SYS.VAL(Int16, int)*)
      longintarr := SYS.VAL(intarr64, int);
      int16[0] := longintarr[0];
      int16[1] := longintarr[1]; (* this will work for little endian -- noch *)
   END LongintToInt16;

   PROCEDURE IntegerToInt16*(int: INTEGER; VAR int16: Int16);
      VAR intarr : intarr32;
   BEGIN
      int16 := SYS.VAL(Int16, int)
      (*intarr := SYS.VAL(intarr32, int);
      int16[0] := intarr[0];
      int16[1] := intarr[1];*) (* this will work for little endian -- noch *)
   END IntegerToInt16;

   PROCEDURE htons*(in: Int16; VAR out : Int16);
   BEGIN
      out[0] := in[1];
      out[1] := in[0];
   END htons;

END types.
