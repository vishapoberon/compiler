MODULE errors;

(* adr array 14172 bytes *)
(* str array 17724 bytes (original) *)
(* case stmt 19715 bytes *)

IMPORT Console;

PROCEDURE Write*(n: INTEGER);
BEGIN
  CASE n OF
  (* Incorrect use of the language Oberon *)
  |0:   Console.String("undeclared identifier")
  |1:   Console.String("multiply defined identifier")
  |2:   Console.String("illegal character in number")
  |3:   Console.String("illegal character in string")
  |4:   Console.String("identifier does not match procedure name")
  |5:   Console.String("comment not closed")

  |9:   Console.String("'=' expected")

  |12:  Console.String("type definition starts with incorrect symbol")
  |13:  Console.String("factor starts with incorrect symbol")
  |14:  Console.String("statement starts with incorrect symbol")
  |15:  Console.String("declaration followed by incorrect symbol")
  |16:  Console.String("MODULE expected")

  |18:  Console.String("'.' missing")
  |19:  Console.String("',' missing")
  |20:  Console.String("':' missing")

  |22:  Console.String("')' missing")
  |23:  Console.String("']' missing")
  |24:  Console.String("'}' missing")
  |25:  Console.String("OF missing")
  |26:  Console.String("THEN missing")
  |27:  Console.String("DO missing")
  |28:  Console.String("TO missing")

  |30:  Console.String("'(' missing")

  |34:  Console.String("':=' missing")
  |35:  Console.String("',' or OF expected")

  |38:  Console.String("identifier expected")
  |39:  Console.String("';' missing")

  |41:  Console.String("END missing")

  |44:  Console.String("UNTIL missing")

  |46:  Console.String("EXIT not within loop statement")
  |47:  Console.String("illegally marked identifier")

  |50:  Console.String("expression should be constant")
  |51:  Console.String("constant not an integer")
  |52:  Console.String("identifier does not denote a type")
  |53:  Console.String("identifier does not denote a record type")
  |54:  Console.String("result type of procedure is not a basic type")
  |55:  Console.String("procedure call of a function")
  |56:  Console.String("assignment to non-variable")
  |57:  Console.String("pointer not bound to record or array type")
  |58:  Console.String("recursive type definition")
  |59:  Console.String("illegal open array parameter")
  |60:  Console.String("wrong type of case label")
  |61:  Console.String("inadmissible type of case label")
  |62:  Console.String("case label defined more than once")
  |63:  Console.String("illegal value of constant")
  |64:  Console.String("more actual than formal parameters")
  |65:  Console.String("fewer actual than formal parameters")
  |66:  Console.String("element types of actual array and formal open array differ")
  |67:  Console.String("actual parameter corresponding to open array is not an array")
  |68:  Console.String("control variable must be integer")
  |69:  Console.String("parameter must be an integer constant")
  |70:  Console.String("pointer or VAR record required as formal receiver")
  |71:  Console.String("pointer expected as actual receiver")
  |72:  Console.String("procedure must be bound to a record of the same scope")
  |73:  Console.String("procedure must have level 0")
  |74:  Console.String("procedure unknown in base type")
  |75:  Console.String("invalid call of base procedure")
  |76:  Console.String("this variable (field) is read only")
  |77:  Console.String("object is not a record")
  |78:  Console.String("dereferenced object is not a variable")
  |79:  Console.String("indexed object is not a variable")
  |80:  Console.String("index expression is not an integer")
  |81:  Console.String("index out of specified bounds")
  |82:  Console.String("indexed variable is not an array")
  |83:  Console.String("undefined record field")
  |84:  Console.String("dereferenced variable is not a pointer")
  |85:  Console.String("guard or test type is not an extension of variable type")
  |86:  Console.String("guard or testtype is not a pointer")
  |87:  Console.String("guarded or tested variable is neither a pointer nor a VAR-parameter record")
  |88:  Console.String("open array not allowed as variable, record field or array element")

  |92:  Console.String("operand of IN not an integer, or not a set")
  |93:  Console.String("set element type is not an integer")
  |94:  Console.String("operand of & is not of type BOOLEAN")
  |95:  Console.String("operand of OR is not of type BOOLEAN")
  |96:  Console.String("operand not applicable to (unary) +")
  |97:  Console.String("operand not applicable to (unary) -")
  |98:  Console.String("operand of ~ is not of type BOOLEAN")
  |99:  Console.String("ASSERT fault")
  |100: Console.String("incompatible operands of dyadic operator")
  |101: Console.String("operand type inapplicable to *")
  |102: Console.String("operand type inapplicable to /")
  |103: Console.String("operand type inapplicable to DIV")
  |104: Console.String("operand type inapplicable to MOD")
  |105: Console.String("operand type inapplicable to +")
  |106: Console.String("operand type inapplicable to -")
  |107: Console.String("operand type inapplicable to = or #")
  |108: Console.String("operand type inapplicable to relation")
  |109: Console.String("overriding method must be exported")
  |110: Console.String("operand is not a type")
  |111: Console.String("operand inapplicable to (this) function")
  |112: Console.String("operand is not a variable")
  |113: Console.String("incompatible assignment")
  |114: Console.String("string too long to be assigned")
  |115: Console.String("parameter doesn't match")
  |116: Console.String("number of parameters doesn't match")
  |117: Console.String("result type doesn't match")
  |118: Console.String("export mark doesn't match with forward declaration")
  |119: Console.String("redefinition textually precedes procedure bound to base type")
  |120: Console.String("type of expression following IF, WHILE, UNTIL or ASSERT is not BOOLEAN")
  |121: Console.String("called object is not a procedure (or is an interrupt procedure)")
  |122: Console.String("actual VAR-parameter is not a variable")
  |123: Console.String("type of actual parameter is not identical with that of formal VAR-parameter")
  |124: Console.String("type of result expression differs from that of procedure")
  |125: Console.String("type of case expression is neither INTEGER nor CHAR")
  |126: Console.String("this expression cannot be a type or a procedure")
  |127: Console.String("illegal use of object")
  |128: Console.String("unsatisfied forward reference")
  |129: Console.String("unsatisfied forward procedure")
  |130: Console.String("WITH clause does not specify a variable")
  |131: Console.String("LEN not applied to array")
  |132: Console.String("dimension in LEN too large or negative")
  |135: Console.String("SYSTEM not imported")
  |150: Console.String("key inconsistency of imported module")
  |151: Console.String("incorrect symbol file")
  |152: Console.String("symbol file of imported module not found")
  |153: Console.String("object or symbol file not opened (disk full?)")
  |154: Console.String("recursive import not allowed")
  |155: Console.String("generation of new symbol file not allowed")
  |156: Console.String("parameter file not found")
  |157: Console.String("syntax error in parameter file")
  (* Limitations of implementation *)
  |200: Console.String("not yet implemented")
  |201: Console.String("lower bound of set range greater than higher bound")
  |202: Console.String("set element greater than MAX(SET) or less than 0")
  |203: Console.String("number too large")
  |204: Console.String("product too large")
  |205: Console.String("division by zero")
  |206: Console.String("sum too large")
  |207: Console.String("difference too large")
  |208: Console.String("overflow in arithmetic shift")
  |209: Console.String("case range too large")
  |213: Console.String("too many cases in case statement")
  |218: Console.String("illegal value of parameter (0 <= p < 256)")
  |219: Console.String("machine registers cannot be accessed")
  |220: Console.String("illegal value of parameter")
  |221: Console.String("too many pointers in a record")
  |222: Console.String("too many global pointers")
  |223: Console.String("too many record types")
  |224: Console.String("too many pointer types")
  |225: Console.String("address of pointer variable too large (move forward in text)")
  |226: Console.String("too many exported procedures")
  |227: Console.String("too many imported modules")
  |228: Console.String("too many exported structures")
  |229: Console.String("too many nested records for import")
  |230: Console.String("too many constants (strings) in module")
  |231: Console.String("too many link table entries (external procedures)")
  |232: Console.String("too many commands in module")
  |233: Console.String("record extension hierarchy too high")
  |234: Console.String("export of recursive type not allowed")
  |240: Console.String("identifier too long")
  |241: Console.String("string too long")
  |242: Console.String("address overflow")
  |244: Console.String("cyclic type definition not allowed")
  |245: Console.String("guarded pointer variable may be manipulated by non-local operations; use auxiliary pointer variable")
	(* Compiler Warnings *)
  |301: Console.String("implicit type cast")
  |306: Console.String("inappropriate symbol file ignored")
  |307: Console.String("no ELSE symbol after CASE statement sequence may lead to trap") (* new warning,  -- noch *)
  ELSE END
END Write;

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
