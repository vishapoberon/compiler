MODULE Modules;  (* jt 6.1.96 *)

  (* access to list of modules and commands, based on ETH Oberon *)


  IMPORT SYSTEM, Console, Heap;

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


  PROCEDURE -modules*(): Module
      "(Modules_Module)Heap_modules";

  PROCEDURE -setmodules*(m: Module)
      "Heap_modules = m";


  PROCEDURE Append(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN
    i := 0; WHILE a[i] # 0X DO INC(i) END;
    j := 0; WHILE b[j] # 0X DO a[i] := b[j]; INC(i); INC(j) END;
    a[i] := 0X
  END Append;

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

END Modules.
