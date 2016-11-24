MODULE Modules;  (* jt 6.1.96 *)

  (* access to list of modules and commands, based on ETH Oberon *)


  IMPORT SYSTEM, Heap, Platform;

  CONST
    ModNameLen* = 20;

  TYPE
    ModuleName* = ARRAY ModNameLen OF CHAR;
    Module* = POINTER TO ModuleDesc;
    Cmd* = POINTER TO CmdDesc;
    ModuleDesc* = RECORD  (* cf. SYSTEM.Mod *)
      next-: Module;
      name-: ModuleName;
      refcnt-: LONGINT;
      cmds-: Cmd;
      types-: LONGINT;
      enumPtrs-: PROCEDURE (P: PROCEDURE(p: LONGINT));
      reserved1, reserved2: LONGINT;
    END ;

    Command* = PROCEDURE;

    CmdDesc* = RECORD
      next-: Cmd;
      name-: ARRAY 24 OF CHAR;
      cmd-: Command
    END ;

  VAR
    res*: INTEGER;
    resMsg*: ARRAY 256 OF CHAR;
    imported*, importing*: ModuleName;


  PROCEDURE Append(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN
    i := 0; WHILE a[i] # 0X DO INC(i) END;
    j := 0; WHILE b[j] # 0X DO a[i] := b[j]; INC(i); INC(j) END;
    a[i] := 0X
  END Append;


  PROCEDURE -modules(): Module     "(Modules_Module)Heap_modules";
  PROCEDURE -setmodules(m: Module) "Heap_modules = m";

  PROCEDURE ThisMod* (name: ARRAY OF CHAR): Module;
    VAR m: Module; bodyname: ARRAY 64 OF CHAR; body: Command;
  BEGIN m := modules();
    WHILE (m # NIL) & (m.name # name) DO m := m.next END ;
    IF m # NIL THEN res := 0; resMsg := ""
    ELSE res := 1; COPY(name, importing);
      resMsg := ' module "'; Append(resMsg, name); Append(resMsg, '" not found');
    END ;
    RETURN m
  END ThisMod;

  PROCEDURE ThisCommand* (mod: Module; name: ARRAY OF CHAR): Command;
    VAR c: Cmd;
  BEGIN c := mod.cmds;
    WHILE (c # NIL) & (c.name # name) DO c := c.next END ;
    IF c # NIL THEN res := 0; resMsg := ""; RETURN c.cmd
    ELSE res := 2; resMsg := ' command "'; COPY(name, importing);
      Append(resMsg, mod.name); Append(resMsg, "."); Append(resMsg, name); Append(resMsg, '" not found');
      RETURN NIL
    END
  END ThisCommand;

  PROCEDURE Free*(name: ARRAY OF CHAR; all: BOOLEAN);
    VAR m, p: Module;
  BEGIN m := modules();
    IF all THEN
      res := 1; resMsg := 'unloading "all" not yet supported'
    ELSE
      WHILE (m # NIL) & (m.name # name) DO p := m; m := m.next END ;
      IF (m # NIL) & (m.refcnt = 0) THEN
        IF m = modules() THEN setmodules(m.next)
        ELSE p.next := m.next
        END ;
        res := 0
      ELSE res := 1;
        IF m = NIL THEN resMsg := "module not found"
        ELSE resMsg := "clients of this module exist"
        END
      END
    END
  END Free;


  (* Run time error reporting. *)

  PROCEDURE errch(c: CHAR);  (* Here we favour simplicity over efficiency, so no buffering. *)
  VAR e: Platform.ErrorCode;
  BEGIN e := Platform.Write(1, SYSTEM.ADR(c), 1)
  END errch;

  PROCEDURE errstring(s: ARRAY OF CHAR);
  VAR i: LONGINT;
  BEGIN
    i := 0; WHILE (i<LEN(s)) & (s[i] # 0X) DO errch(s[i]); INC(i) END
  END errstring;

  PROCEDURE errint(l: SYSTEM.INT32);
  BEGIN
    IF l <  0  THEN errch('-'); l := -l END;
    IF l >= 10 THEN errint(l DIV 10) END;
    errch(CHR(l MOD 10 + 30H))
  END errint;

  PROCEDURE DisplayHaltCode(code: SYSTEM.INT32);
  BEGIN
    CASE code OF
    | -1: errstring("Assertion failure.")
    | -2: errstring("Index out of range.")
    | -3: errstring("Reached end of function without reaching RETURN.")
    | -4: errstring("CASE statement: no matching label and no ELSE.")
    | -5: errstring("Type guard failed.")
    | -6: errstring("Implicit type guard in record assignment failed.")
    | -7: errstring("Invalid case in WITH statement.")
    | -8: errstring("Value out of range.")
    | -9: errstring("Heap interrupted while locked, but lockdepth = 0 at unlock.")
    |-10: errstring("NIL access.");
    |-11: errstring("Alignment error.");
    |-12: errstring("Divide by zero.");
    |-13: errstring("Arithmetic overflow/underflow.");
    |-14: errstring("Invalid function argument.");
    |-15: errstring("Internal error, e.g. Type descriptor size mismatch.")
    |-20: errstring("Too many, or negative number of, elements in dynamic array.")
    ELSE
    END
  END DisplayHaltCode;

  PROCEDURE Halt*(code: SYSTEM.INT32);
  BEGIN
    (*IF HaltHandler # NIL THEN HaltHandler(code) END;*)
    errstring("Terminated by Halt("); errint(code); errstring("). ");
    IF code < 0 THEN DisplayHaltCode(code) END;
    errstring(Platform.NL);
    Platform.Exit(code);
  END Halt;

  PROCEDURE AssertFail*(code: SYSTEM.INT32);
  BEGIN
    errstring("Assertion failure.");
    IF code # 0 THEN errstring(" ASSERT code "); errint(code); errstring("."); END;
    errstring(Platform.NL);
    Platform.Exit(code);
  END AssertFail;

END Modules.
