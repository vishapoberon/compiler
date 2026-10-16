MODULE PErrors;

TYPE str* = ARRAY 42 OF CHAR;
VAR errors* : ARRAY 112 OF str;


BEGIN

errors[0] := "undeclared identifier";
errors[2] := "variable expected";
errors[3] := "not a function";
errors[4] := "";
errors[5] := "'=' expected";
errors[8] := "')' expected";
errors[9] := "";
errors[10] := "identifier or number expected";
errors[11] := "number expected";
errors[12] := "";
errors[13] := "";
errors[14] := "statement starts with incorrect symbol";
errors[15] := "closing end of if condition expected";
errors[16] := "closing end of while loop expected";
errors[17] := "";
errors[18] := "procedure end expected";
errors[19] := "";
errors[20] := "';' expected";
errors[21] := "'BEGIN' expected";
errors[22] := "procedure name mismatch";
errors[25] := "'until' or 'end' expected";
errors[111] := "type mismatch";



END PErrors.
