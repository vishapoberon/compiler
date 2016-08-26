MODULE Vishap;  (* J. Templ 3.2.95 *)

  IMPORT
    SYSTEM, Heap, Platform, Configuration,
    OPP, OPB, OPT,
    OPV, OPC, OPM,
    extTools, Strings, vt100;

  VAR mname :  ARRAY 256 OF CHAR; (* noch *)


  PROCEDURE Module*(VAR done: BOOLEAN);
    VAR ext, new: BOOLEAN; p: OPT.Node;
  BEGIN
    OPP.Module(p, OPM.opt);
    IF OPM.noerr THEN
      OPV.Init;
      OPV.AdrAndSize(OPT.topScope);
      OPT.Export(ext, new);
      IF OPM.noerr THEN
        OPM.OpenFiles(OPT.SelfName);
        OPC.Init;
        OPV.Module(p);
        IF OPM.noerr THEN
          IF (OPM.mainProg OR OPM.mainLinkStat) & (OPM.modName # "SYSTEM") THEN
            OPM.DeleteNewSym;
            IF ~OPM.notColorOutput THEN vt100.SetAttr(vt100.Green) END;
            OPM.LogWStr("  Main program.");
            IF ~OPM.notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;
          ELSE
            IF new THEN
              IF ~OPM.notColorOutput THEN vt100.SetAttr(vt100.Green) END;
              OPM.LogWStr("  New symbol file.");
              IF ~OPM.notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;
	            OPM.RegisterNewSym
            ELSIF ext THEN
              OPM.LogWStr("  Extended symbol file.");
              OPM.RegisterNewSym
            END
          END;
      	ELSE
          OPM.DeleteNewSym
        END
      END
    END;
    OPM.CloseFiles; OPT.Close;
    OPM.LogWLn;
    done := OPM.noerr;
  END Module;


  PROCEDURE PropagateElementaryTypeSizes;
  BEGIN
    OPT.bytetyp.size   := OPM.ByteSize;
    OPT.sysptrtyp.size := OPM.PointerSize;
    OPT.chartyp.size   := OPM.CharSize;
    OPT.settyp.size    := OPM.SetSize;
    OPT.realtyp.size   := OPM.RealSize;
    OPT.inttyp.size    := OPM.IntSize;
    OPT.linttyp.size   := OPM.LIntSize;
    OPT.ainttyp.size   := OPM.LIntSize;
    OPT.lrltyp.size    := OPM.LRealSize;
    OPT.sinttyp.size   := OPM.SIntSize;
    OPT.booltyp.size   := OPM.BoolSize;
  END PropagateElementaryTypeSizes;


  PROCEDURE Translate*;
    VAR
      done:       BOOLEAN;
      modulesobj: ARRAY 2048 OF CHAR; (* here we hold all modules name given on the command line, to add corresponding .o files to the external compiler options *)
  BEGIN
    modulesobj := "";
    IF OPM.OpenPar() THEN
      (* gclock();   slightly faster translation but may lead to opening "too many files" *)

      LOOP
        OPM.Init(done, mname); (* Get next module name from command line *)
        IF ~done THEN RETURN END ;

        OPM.InitOptions; (* Get options ofr this module *)
        PropagateElementaryTypeSizes;

        (* Compile source to .c and .h files *)
        Heap.GC(FALSE);
        Module(done);
        IF ~done THEN
          OPM.LogWLn; OPM.LogWStr("Module compilation failed."); OPM.LogWLn;
          Platform.Exit(1)
        END;

        (* 'assemble' (i.e. c compile) .c to object or executable. *)
        IF ~OPM.dontAsm THEN
          IF OPM.dontLink THEN
            (* If not linking, just assemble each module. *)
            extTools.Assemble(OPM.modName)
          ELSE
            IF ~(OPM.mainProg OR OPM.mainLinkStat) THEN
              (* Assemble non main rogram and add object name to link list *)
              extTools.Assemble(OPM.modName);
              Strings.Append(" ",                  modulesobj);
              Strings.Append(OPM.modName,          modulesobj);
              Strings.Append(Configuration.objext, modulesobj)
            ELSE
              (* Assemble and link main program *)
              extTools.LinkMain (OPM.modName, OPM.mainLinkStat, modulesobj)
            END
          END
  	    END
      END (* loop *)
    END
  END Translate;

  PROCEDURE Trap(sig: INTEGER);
  BEGIN
    Heap.FINALL();
    IF sig = 3 THEN
      Platform.Exit(0)
    ELSE
      IF (sig = 4) & (Platform.HaltCode = -15) THEN
        OPM.LogWStr(" --- Vishap Oberon: internal error");
        OPM.LogWLn
      END ;
      Platform.Exit(2)
    END
  END Trap;

BEGIN
  Platform.SetInterruptHandler(Trap);
  Platform.SetQuitHandler(Trap);
  Platform.SetBadInstructionHandler(Trap);
  OPB.typSize := OPV.TypSize; OPT.typSize := OPV.TypSize; Translate
END Vishap.
