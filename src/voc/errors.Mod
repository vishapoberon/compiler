MODULE errors;

TYPE string* = ARRAY 128 OF CHAR;

VAR errors- : ARRAY 350 OF string;


BEGIN
(* Incorrect use of the language Oberon *)
errors[0] := "undeclared identifier";
errors[1] := "multiply defined identifier";
errors[2] := "illegal character in number";
errors[3] := "illegal character in string";
errors[4] := "identifier does not match procedure name";
errors[5] := "comment not closed";
errors[6] := "";
errors[6] := "";
errors[6] := "";
errors[9] := "'=' expected";
errors[10] :="";
errors[11] :="";
errors[12] := "type definition starts with incorrect symbol";
errors[13] := "factor starts with incorrect symbol";
errors[14] := "statement starts with incorrect symbol";
errors[15] := "declaration followed by incorrect symbol";
errors[16] := "MODULE expected";
errors[17] := "";
errors[18] := "'.' missing";
errors[19] := "',' missing";
errors[20] := "':' missing";
errors[21] := "";
errors[22] := "')' missing";
errors[23] := "']' missing";
errors[24] := "'}' missing";
errors[25] := "OF missing";
errors[26] := "THEN missing";
errors[27] := "DO missing";
errors[28] := "TO missing";
errors[29] := "";
errors[30] := "'(' missing";
errors[31] := "";
errors[32] := "";
errors[33] := "";
errors[34] := "':=' missing";
errors[35] := "',' or OF expected";
errors[36] := "";
errors[37] := "";
errors[38] := "identifier expected";
errors[39] := "';' missing";
errors[40] := "";
errors[41] := "END missing";
errors[42] := "";
errors[43] := "";
errors[44] := "UNTIL missing";
errors[45] := "";
errors[46] := "EXIT not within loop statement";
errors[47] := "illegally marked identifier";
errors[48] := "";
errors[49] := "";
errors[50] := "expression should be constant";
errors[51] := "constant not an integer";
errors[52] := "identifier does not denote a type";
errors[53] := "identifier does not denote a record type";
errors[54] := "result type of procedure is not a basic type";
errors[55] := "procedure call of a function";
errors[56] := "assignment to non-variable";
errors[57] := "pointer not bound to record or array type";
errors[58] := "recursive type definition";
errors[59] := "illegal open array parameter";
errors[60] := "wrong type of case label";
errors[61] := "inadmissible type of case label";
errors[62] := "case label defined more than once";
errors[63] := "illegal value of constant";
errors[64] := "more actual than formal parameters";
errors[65] := "fewer actual than formal parameters";
errors[66] := "element types of actual array and formal open array differ";
errors[67] := "actual parameter corresponding to open array is not an array";
errors[68] := "control variable must be integer";
errors[69] := "parameter must be an integer constant";
errors[70] := "pointer or VAR record required as formal receiver";
errors[71] := "pointer expected as actual receiver";
errors[72] := "procedure must be bound to a record of the same scope";
errors[73] := "procedure must have level 0";
errors[74] := "procedure unknown in base type";
errors[75] := "invalid call of base procedure";
errors[76] := "this variable (field) is read only";
errors[77] := "object is not a record";
errors[78] := "dereferenced object is not a variable";
errors[79] := "indexed object is not a variable";
errors[80] := "index expression is not an integer";
errors[81] := "index out of specified bounds";
errors[82] := "indexed variable is not an array";
errors[83] := "undefined record field";
errors[84] := "dereferenced variable is not a pointer";
errors[85] := "guard or test type is not an extension of variable type";
errors[86] := "guard or testtype is not a pointer";
errors[87] := "guarded or tested variable is neither a pointer nor a VAR-parameter record";
errors[88] := "open array not allowed as variable, record field or array element";
errors[89] := "";
errors[90] := "";
errors[91] := "";
errors[92] := "operand of IN not an integer, or not a set";
errors[93] := "set element type is not an integer";
errors[94] := "operand of & is not of type BOOLEAN";
errors[95] := "operand of OR is not of type BOOLEAN";
errors[96] := "operand not applicable to (unary) +";
errors[97] := "operand not applicable to (unary) -";
errors[98] := "operand of ~ is not of type BOOLEAN";
errors[99] := "ASSERT fault";
errors[100] := "incompatible operands of dyadic operator";
errors[101] := "operand type inapplicable to *";
errors[102] := "operand type inapplicable to /";
errors[103] := "operand type inapplicable to DIV";
errors[104] := "operand type inapplicable to MOD";
errors[105] := "operand type inapplicable to +";
errors[106] := "operand type inapplicable to -";
errors[107] := "operand type inapplicable to = or #";
errors[108] := "operand type inapplicable to relation";
errors[109] := "overriding method must be exported";
errors[110] := "operand is not a type";
errors[111] := "operand inapplicable to (this) function";
errors[112] := "operand is not a variable";
errors[113] := "incompatible assignment";
errors[114] := "string too long to be assigned";
errors[115] := "parameter doesn't match";
errors[116] := "number of parameters doesn't match";
errors[117] := "result type doesn't match";
errors[118] := "export mark doesn't match with forward declaration";
errors[119] := "redefinition textually precedes procedure bound to base type";
errors[120] := "type of expression following IF, WHILE, UNTIL or ASSERT is not BOOLEAN";
errors[121] := "called object is not a procedure (or is an interrupt procedure)";
errors[122] := "actual VAR-parameter is not a variable";
errors[123] := "type of actual parameter is not identical with that of formal VAR-parameter";
errors[124] := "type of result expression differs from that of procedure";
errors[125] := "type of case expression is neither INTEGER nor CHAR";
errors[126] := "this expression cannot be a type or a procedure";
errors[127] := "illegal use of object";
errors[128] := "unsatisfied forward reference";
errors[129] := "unsatisfied forward procedure";
errors[130] := "WITH clause does not specify a variable";
errors[131] := "LEN not applied to array";
errors[132] := "dimension in LEN too large or negative";
errors[135] := "SYSTEM not imported";
errors[150] := "key inconsistency of imported module";
errors[151] := "incorrect symbol file";
errors[152] := "symbol file of imported module not found";
errors[153] := "object or symbol file not opened (disk full?)";
errors[154] := "recursive import not allowed";
errors[155] := "generation of new symbol file not allowed";
errors[156] := "parameter file not found";
errors[157] := "syntax error in parameter file";
(* Limitations of implementation*)
errors[200] := "not yet implemented";
errors[201] := "lower bound of set range greater than higher bound";
errors[202] := "set element greater than MAX(SET) or less than 0";
errors[203] := "number too large";
errors[204] := "product too large";
errors[205] := "division by zero";
errors[206] := "sum too large";
errors[207] := "difference too large";
errors[208] := "overflow in arithmetic shift";
errors[209] := "case range too large";
errors[213] := "too many cases in case statement";
errors[218] := "illegal value of parameter (0 <= p < 256)";
errors[219] := "machine registers cannot be accessed";
errors[220] := "illegal value of parameter";
errors[221] := "too many pointers in a record";
errors[222] := "too many global pointers";
errors[223] := "too many record types";
errors[224] := "too many pointer types";
errors[225] := "address of pointer variable too large (move forward in text)";
errors[226] := "too many exported procedures";
errors[227] := "too many imported modules";
errors[228] := "too many exported structures";
errors[229] := "too many nested records for import";
errors[230] := "too many constants (strings) in module";
errors[231] := "too many link table entries (external procedures)";
errors[232] := "too many commands in module";
errors[233] := "record extension hierarchy too high";
errors[234] := "export of recursive type not allowed";
errors[240] := "identifier too long";
errors[241] := "string too long";
errors[242] := "address overflow";
errors[244] := "cyclic type definition not allowed";
errors[245] := "guarded pointer variable may be manipulated by non-local operations; use auxiliary pointer variable";
(* Compiler Warnings *)

errors[301] := "implicit type cast";
errors[306] := "inappropriate symbol file ignored";
errors[307] := "no ELSE symbol after CASE statement sequence may lead to trap"; (* new warning,  -- noch *)

END errors.
(*
Run-time Error Messages
	SYSTEM_halt
	0 silent HALT(0)
	1..255  HALT(n), cf. SYSTEM_halt
	-1 assertion failed, cf. SYSTEM_assert
	-2 invalid array index  
	-3 function procedure without RETURN statement  
	-4 invalid case in CASE statement
	-5 type guard failed
	-6 implicit type guard in record assignment failed
	-7 invalid case in WITH statement
	-8 value out of range
	-9 (delayed) interrupt
	-10 NIL access
	-11 alignment error
	-12 zero divide
	-13 arithmetic overflow/underflow
	-14 invalid function argument
	-15 internal error
*)

