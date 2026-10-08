MODULE Compiler;  (* J. Templ 3.2.95 *)

  IMPORT
    SYSTEM, Heap, Platform, Configuration,
    OPP, OPB, OPT,
    OPV, OPC, OPM,
    extTools, Strings, VT100;

  PROCEDURE Module*(VAR done: BOOLEAN);
    VAR ext, new: BOOLEAN; p: OPT.Node;
  BEGIN
    OPP.Module(p, OPM.Options);
    IF (OPM.permodules IN OPM.Options) & (Strings.Length(OPT.SelfName) >= OPM.ModularNameLen) THEN
      OPM.LogWStr("Modular-build names must fit the 63-character runtime registry.");
      OPM.LogWLn; OPM.noerr := FALSE
    END;
    IF (OPM.permodules IN OPM.Options) & (OPT.SelfName = "core") THEN
      OPM.LogWStr("The library name core is reserved for the minimal runtime.");
      OPM.LogWLn; OPM.noerr := FALSE
    END;
    IF (OPM.sharedmodule IN OPM.Options) &
        ((OPT.SelfName = "SYSTEM") OR (OPT.SelfName = "Platform") OR
         (OPT.SelfName = "Heap") OR (OPT.SelfName = "Modules")) THEN
      OPM.LogWStr("SYSTEM, Platform, Heap and Modules belong to the minimal core, not separate modules.");
      OPM.LogWLn; OPM.noerr := FALSE
    END;
    IF (OPM.dynamicmain IN OPM.Options) & (OPT.SelfName = "ModuleLoader") THEN
      OPM.LogWStr("ModuleLoader is the launcher's loader; build it as a library, not an application.");
      OPM.LogWLn; OPM.noerr := FALSE
    END;
    IF OPM.noerr THEN
      OPV.Init;
      OPT.InitRecno;
      OPV.AdrAndSize(OPT.topScope);
      OPT.Export(ext, new);
      IF OPM.noerr THEN
        OPM.OpenFiles(OPT.SelfName);
        OPM.DeleteObj(OPT.SelfName); (* Make sure old object file isn't left hanging around. *)
        OPC.Init;
        OPV.Module(p);
        IF OPM.noerr THEN
          IF (OPM.mainprog IN OPM.Options) & (OPM.modName # "SYSTEM") THEN
            OPM.DeleteSym(OPT.SelfName);
            OPM.LogVT100(VT100.Green); OPM.LogWStr("  Main program."); OPM.LogVT100(VT100.ResetAll);
          ELSE
            IF new THEN
              OPM.LogVT100(VT100.Green); OPM.LogWStr("  New symbol file."); OPM.LogVT100(VT100.ResetAll);
	            OPM.RegisterNewSym
            ELSIF ext THEN
              OPM.LogWStr("  Extended symbol file.");
              OPM.RegisterNewSym
            END
          END;
      	ELSE
          OPM.DeleteSym(OPT.SelfName)
        END
      END
    END;
    OPM.CloseFiles; OPT.Close;
    OPM.LogWLn;
    done := OPM.noerr;
  END Module;


  PROCEDURE PropagateElementaryTypeSizes;
    VAR adrinttyp: OPT.Struct;
  BEGIN
    OPT.sysptrtyp.size := OPM.AddressSize;
    OPT.sysptrtyp.idfp := OPT.sysptrtyp.form;
    OPM.FPrint(OPT.sysptrtyp.idfp, OPT.sysptrtyp.size);

    OPT.adrtyp.size := OPM.AddressSize;
    OPT.adrtyp.idfp := OPT.adrtyp.form;
    OPM.FPrint(OPT.adrtyp.idfp, OPT.adrtyp.size);

    adrinttyp := OPT.IntType(OPM.AddressSize);
    OPT.adrtyp.strobj := adrinttyp.strobj;

    OPT.sinttyp := OPT.IntType(OPM.ShortintSize);
    OPT.inttyp  := OPT.IntType(OPM.IntegerSize);
    OPT.linttyp := OPT.IntType(OPM.LongintSize);

    OPT.sintobj.typ   := OPT.sinttyp;
    OPT.intobj.typ    := OPT.inttyp;
    OPT.lintobj.typ   := OPT.linttyp;

    CASE OPM.SetSize OF
    |4:  OPT.settyp := OPT.set32typ
    ELSE OPT.settyp := OPT.set64typ
    END;
    OPT.setobj.typ := OPT.settyp;

    (* Enable or disable (non-system) BYTE type *)
    IF OPM.Model = "C" THEN
      OPT.cpbytetyp.strobj.name[4] := 0X  (* Enable Component Pascal non-system BYTE type *)
    ELSE
      OPT.cpbytetyp.strobj.name[4] := '@' (* Disable Component Pascal non-system BYTE type *)
    END
  END PropagateElementaryTypeSizes;


  PROCEDURE FindLocalObjectFiles(VAR objectnames: ARRAY OF CHAR);
    VAR
      l:  OPT.Link;
      fn: ARRAY 64 OF CHAR;
      id: Platform.FileIdentity;
  BEGIN
    objectnames[0] := 0X;
    l := OPT.Links; WHILE l # NIL DO
      (* Tell linker to link this module as an object file if both a symbol
         and an object file exist in the current directory. *)
      COPY(l.name, fn); Strings.Append('.sym', fn);
      IF Platform.IdentifyByName(fn, id) = 0 THEN
        COPY(l.name, fn); Strings.Append(Configuration.objext, fn);
        IF Platform.IdentifyByName(fn, id) = 0 THEN
          Strings.Append(' ', objectnames);
          Strings.Append(fn,  objectnames)
        ELSE
          (* Found symbol file but no object file. *)
          OPM.LogVT100(VT100.LightRed);
          OPM.LogWStr("Link warning: a local symbol file is present for module "); OPM.LogWStr(l.name);
          OPM.LogWStr(", but local object file '"); OPM.LogWStr(fn); OPM.LogWStr("' is missing.");
          OPM.LogVT100(VT100.ResetAll); OPM.LogWLn
        END
      ELSE
        (* No symbol file present in current directory.
           Assume this referenced module is in a library. *)
      END;
      l := l.next
    END
  END FindLocalObjectFiles;


  PROCEDURE Translate*;
    VAR
      done:      BOOLEAN;
      linkfiles: ARRAY 2048 OF CHAR; (* Object files to be linked into main program. *)
  BEGIN
    IF OPM.OpenPar() THEN
      (* gclock();   slightly faster translation but may lead to opening "too many files" *)

      LOOP
        OPM.Init(done); (* Get next module name from command line *)
        IF ~done THEN RETURN END ;

        OPM.InitOptions; (* Get options for this module *)
        PropagateElementaryTypeSizes;

        (* Compile source to .c and .h files *)
        Heap.GC(FALSE);
        Module(done);
        IF ~done THEN
          OPM.LogWLn; OPM.LogWStr("Module compilation failed."); OPM.LogWLn;
          Platform.Exit(1)
        END;

        (* 'assemble' (i.e. c compile) .c to object or executable. *)
        IF OPM.dynamicmain IN OPM.Options THEN extTools.GenerateLauncher(OPM.modName) END;
        IF ~(OPM.dontasm IN OPM.Options) THEN
          IF (OPM.sharedmodule IN OPM.Options) & ~(OPM.dontlink IN OPM.Options) THEN
            extTools.LinkModule(OPM.modName);
            IF OPM.dynamicmain IN OPM.Options THEN
              extTools.LinkLauncher(OPM.modName, OPM.embeddedcore IN OPM.Options)
            END
          ELSIF OPM.dontlink IN OPM.Options THEN
            (* If not linking, just assemble each module. *)
            extTools.Assemble(OPM.modName)
          ELSE
            IF ~(OPM.mainprog IN OPM.Options) THEN
              (* Assemble non main program and add object name to link list *)
              extTools.Assemble(OPM.modName);
            ELSE
              (* Assemble and link main program *)
              linkfiles := "";
              IF ~(OPM.permodules IN OPM.Options) THEN FindLocalObjectFiles(linkfiles) END;
              extTools.LinkMain(OPM.modName, OPM.mainlinkstat IN OPM.Options, linkfiles)
            END
          END
  	    END
      END (* loop *)
    END
  END Translate;

  PROCEDURE Trap(sig: SYSTEM.INT32);
  BEGIN
    Heap.FINALL();
    IF sig = 3 THEN
      Platform.Exit(0)
    ELSE
      IF sig = 4 THEN
        OPM.LogWStr(" --- Oberon compiler internal error"); OPM.LogWLn
      END ;
      Platform.Exit(2)
    END
  END Trap;

BEGIN
  Platform.SetInterruptHandler(Trap);
  Platform.SetQuitHandler(Trap);
  Platform.SetBadInstructionHandler(Trap);
  Translate
END Compiler.
