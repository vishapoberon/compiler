MODULE compatIn;
(* module created to compile Make utility from Trianus v4 system with less changes in original file ; -- noch *)
IMPORT Args;

VAR Done* : BOOLEAN;
    argnum : INTEGER;
PROCEDURE Open*;
BEGIN
argnum := 0;
Done := FALSE;
END Open;

PROCEDURE Name*(VAR name : ARRAY OF CHAR);
BEGIN
INC(argnum);

IF argnum < Args.argc THEN 
   Args.Get(argnum, name);
   Done := TRUE
ELSE
   Done := FALSE
END
END Name;

BEGIN
   Open();
END compatIn.
