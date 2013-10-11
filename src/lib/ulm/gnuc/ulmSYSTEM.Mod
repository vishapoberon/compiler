MODULE ulmSYSTEM;
IMPORT SYSTEM;

CONST
      READ = 3;
      WRITE = 4;
      
TYPE pchar = POINTER TO ARRAY 1 OF CHAR;

        PROCEDURE -Write(adr, n: LONGINT): LONGINT
	  "write(1/*stdout*/, adr, n)";

	PROCEDURE -read(VAR ch: CHAR): LONGINT
	  "read(0/*stdin*/, ch, 1)";


  PROCEDURE TAS*(VAR flag:BOOLEAN): BOOLEAN; (* added for compatibility with ulmSYSTEM module; noch *)
  VAR oldflag : BOOLEAN;
  BEGIN
     oldflag := flag;
     flag := TRUE;
     RETURN oldflag;
  END TAS;

  PROCEDURE UNIXCALL*(syscall: LONGINT; VAR d0, d1: LONGINT; (* in ulm version both LONGINT and INTEGER are 4 byte size *)
                     arg1, arg2, arg3: LONGINT) : BOOLEAN;  
  VAR
      n : LONGINT;
      ch : CHAR;
      pch : pchar;
  BEGIN
  
  IF syscall = READ THEN
    NEW(pch);
    pch := SYSTEM.VAL(pchar, arg2);
    ch := pch^[0];
    n := read(ch);
    IF n # 1 THEN 
       ch := 0X;
       RETURN FALSE
    ELSE
       pch^[0] := ch;
       RETURN TRUE
    END;
  ELSIF syscall = WRITE THEN
    NEW(pch);
    pch := SYSTEM.VAL(pchar, arg2);
    n := Write(SYSTEM.VAL(LONGINT, pch), 1);
    IF n # 1 THEN RETURN FALSE ELSE RETURN TRUE END
  END

  END UNIXCALL;


  PROCEDURE UNIXFORK(VAR pid: LONGINT) : BOOLEAN;
  BEGIN

  END UNIXFORK;

  PROCEDURE UNIXSIGNAL(signo: INTEGER; p: PROCEDURE;
                       VAR old: PROCEDURE; VAR error: INTEGER) : BOOLEAN;
  BEGIN

  END UNIXSIGNAL;


END ulmSYSTEM.
