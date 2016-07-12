MODULE errors;

(* errors.o 14172 bytes *)
(* original 17724 bytes *)

IMPORT Console, SYSTEM;

TYPE MsgPtr = POINTER[1] TO ARRAY 1024 OF CHAR;

VAR msg: ARRAY 350 OF MsgPtr;  i: INTEGER;

PROCEDURE Write*(n: INTEGER);
BEGIN IF msg[n] # NIL THEN Console.String(msg[n]^) END
END Write;

BEGIN
  FOR i := 0 TO LEN(msg)-1 DO msg[i] := NIL END;

  (* Incorrect use of the language Oberon *)
  msg[0]   := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("undeclared identifier"));
  msg[1]   := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("multiply defined identifier"));
  msg[2]   := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("illegal character in number"));
  msg[3]   := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("illegal character in string"));
  msg[4]   := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("identifier does not match procedure name"));
  msg[5]   := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("comment not closed"));

  msg[9]   := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("'=' expected"));

  msg[12]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("type definition starts with incorrect symbol"));
  msg[13]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("factor starts with incorrect symbol"));
  msg[14]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("statement starts with incorrect symbol"));
  msg[15]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("declaration followed by incorrect symbol"));
  msg[16]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("MODULE expected"));

  msg[18]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("'.' missing"));
  msg[19]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("',' missing"));
  msg[20]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("':' missing"));

  msg[22]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("')' missing"));
  msg[23]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("']' missing"));
  msg[24]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("'}' missing"));
  msg[25]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("OF missing"));
  msg[26]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("THEN missing"));
  msg[27]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("DO missing"));
  msg[28]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("TO missing"));

  msg[30]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("'(' missing"));

  msg[34]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("':=' missing"));
  msg[35]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("',' or OF expected"));

  msg[38]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("identifier expected"));
  msg[39]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("';' missing"));

  msg[41]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("END missing"));

  msg[44]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("UNTIL missing"));

  msg[46]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("EXIT not within loop statement"));
  msg[47]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("illegally marked identifier"));

  msg[50]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("expression should be constant"));
  msg[51]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("constant not an integer"));
  msg[52]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("identifier does not denote a type"));
  msg[53]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("identifier does not denote a record type"));
  msg[54]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("result type of procedure is not a basic type"));
  msg[55]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("procedure call of a function"));
  msg[56]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("assignment to non-variable"));
  msg[57]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("pointer not bound to record or array type"));
  msg[58]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("recursive type definition"));
  msg[59]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("illegal open array parameter"));
  msg[60]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("wrong type of case label"));
  msg[61]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("inadmissible type of case label"));
  msg[62]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("case label defined more than once"));
  msg[63]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("illegal value of constant"));
  msg[64]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("more actual than formal parameters"));
  msg[65]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("fewer actual than formal parameters"));
  msg[66]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("element types of actual array and formal open array differ"));
  msg[67]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("actual parameter corresponding to open array is not an array"));
  msg[68]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("control variable must be integer"));
  msg[69]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("parameter must be an integer constant"));
  msg[70]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("pointer or VAR record required as formal receiver"));
  msg[71]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("pointer expected as actual receiver"));
  msg[72]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("procedure must be bound to a record of the same scope"));
  msg[73]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("procedure must have level 0"));
  msg[74]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("procedure unknown in base type"));
  msg[75]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("invalid call of base procedure"));
  msg[76]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("this variable (field) is read only"));
  msg[77]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("object is not a record"));
  msg[78]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("dereferenced object is not a variable"));
  msg[79]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("indexed object is not a variable"));
  msg[80]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("index expression is not an integer"));
  msg[81]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("index out of specified bounds"));
  msg[82]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("indexed variable is not an array"));
  msg[83]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("undefined record field"));
  msg[84]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("dereferenced variable is not a pointer"));
  msg[85]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("guard or test type is not an extension of variable type"));
  msg[86]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("guard or testtype is not a pointer"));
  msg[87]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("guarded or tested variable is neither a pointer nor a VAR-parameter record"));
  msg[88]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("open array not allowed as variable, record field or array element"));

  msg[92]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand of IN not an integer, or not a set"));
  msg[93]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("set element type is not an integer"));
  msg[94]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand of & is not of type BOOLEAN"));
  msg[95]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand of OR is not of type BOOLEAN"));
  msg[96]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand not applicable to (unary) +"));
  msg[97]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand not applicable to (unary) -"));
  msg[98]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand of ~ is not of type BOOLEAN"));
  msg[99]  := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("ASSERT fault"));
  msg[100] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("incompatible operands of dyadic operator"));
  msg[101] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand type inapplicable to *"));
  msg[102] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand type inapplicable to /"));
  msg[103] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand type inapplicable to DIV"));
  msg[104] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand type inapplicable to MOD"));
  msg[105] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand type inapplicable to +"));
  msg[106] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand type inapplicable to -"));
  msg[107] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand type inapplicable to = or #"));
  msg[108] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand type inapplicable to relation"));
  msg[109] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("overriding method must be exported"));
  msg[110] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand is not a type"));
  msg[111] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand inapplicable to (this) function"));
  msg[112] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("operand is not a variable"));
  msg[113] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("incompatible assignment"));
  msg[114] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("string too long to be assigned"));
  msg[115] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("parameter doesn't match"));
  msg[116] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("number of parameters doesn't match"));
  msg[117] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("result type doesn't match"));
  msg[118] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("export mark doesn't match with forward declaration"));
  msg[119] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("redefinition textually precedes procedure bound to base type"));
  msg[120] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("type of expression following IF, WHILE, UNTIL or ASSERT is not BOOLEAN"));
  msg[121] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("called object is not a procedure (or is an interrupt procedure)"));
  msg[122] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("actual VAR-parameter is not a variable"));
  msg[123] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("type of actual parameter is not identical with that of formal VAR-parameter"));
  msg[124] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("type of result expression differs from that of procedure"));
  msg[125] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("type of case expression is neither INTEGER nor CHAR"));
  msg[126] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("this expression cannot be a type or a procedure"));
  msg[127] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("illegal use of object"));
  msg[128] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("unsatisfied forward reference"));
  msg[129] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("unsatisfied forward procedure"));
  msg[130] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("WITH clause does not specify a variable"));
  msg[131] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("LEN not applied to array"));
  msg[132] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("dimension in LEN too large or negative"));
  msg[135] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("SYSTEM not imported"));
  msg[150] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("key inconsistency of imported module"));
  msg[151] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("incorrect symbol file"));
  msg[152] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("symbol file of imported module not found"));
  msg[153] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("object or symbol file not opened (disk full?)"));
  msg[154] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("recursive import not allowed"));
  msg[155] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("generation of new symbol file not allowed"));
  msg[156] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("parameter file not found"));
  msg[157] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("syntax error in parameter file"));
  (* Limitations of implementation*)
  msg[200] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("not yet implemented"));
  msg[201] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("lower bound of set range greater than higher bound"));
  msg[202] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("set element greater than MAX(SET) or less than 0"));
  msg[203] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("number too large"));
  msg[204] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("product too large"));
  msg[205] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("division by zero"));
  msg[206] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("sum too large"));
  msg[207] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("difference too large"));
  msg[208] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("overflow in arithmetic shift"));
  msg[209] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("case range too large"));
  msg[213] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many cases in case statement"));
  msg[218] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("illegal value of parameter (0 <= p < 256)"));
  msg[219] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("machine registers cannot be accessed"));
  msg[220] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("illegal value of parameter"));
  msg[221] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many pointers in a record"));
  msg[222] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many global pointers"));
  msg[223] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many record types"));
  msg[224] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many pointer types"));
  msg[225] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("address of pointer variable too large (move forward in text)"));
  msg[226] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many exported procedures"));
  msg[227] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many imported modules"));
  msg[228] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many exported structures"));
  msg[229] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many nested records for import"));
  msg[230] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many constants (strings) in module"));
  msg[231] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many link table entries (external procedures)"));
  msg[232] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("too many commands in module"));
  msg[233] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("record extension hierarchy too high"));
  msg[234] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("export of recursive type not allowed"));
  msg[240] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("identifier too long"));
  msg[241] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("string too long"));
  msg[242] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("address overflow"));
  msg[244] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("cyclic type definition not allowed"));
  msg[245] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("guarded pointer variable may be manipulated by non-local operations; use auxiliary pointer variable"));
  (* Compiler Warnings *)
  msg[301] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("implicit type cast"));
  msg[306] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("inappropriate symbol file ignored"));
  msg[307] := SYSTEM.VAL(MsgPtr, SYSTEM.ADR("no ELSE symbol after CASE statement sequence may lead to trap")); (* new warning,  -- noch *)
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
