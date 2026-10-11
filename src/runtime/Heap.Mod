MODULE Heap;

  IMPORT S := SYSTEM;  (* Cannot import anything else as heap initialization must complete
                          before any other modules are initialized. *)

  CONST
    ModNameLen    = 20;
    CmdNameLen    = 24;
    PinModules    = FALSE;  (* The persistent modular core overrides this. *)
    SZA           = SIZE(S.ADDRESS);  (* Size of address *)
    Unit          = 4*SZA;            (* Smallest possible heap block *)
    nofLists      = 9;                (* Number of freelist entries excluding sentinel *)
    heapSize0     = 8000*Unit;        (* Startup heap size *)

  (* all blocks look the same:
    free blocks describe themselves: size = Unit
    tag = &tag++
  ->block size
    sentinel = -SZA
    next
  *)

  (* heap chunks *)
    nextChnkOff = S.VAL(S.ADDRESS, 0);      (* next heap chunk, sorted ascendingly! *)
    endOff      = S.VAL(S.ADDRESS, SZA);    (* end of heap chunk *)
    blkOff      = S.VAL(S.ADDRESS, 3*SZA);  (* first block in a chunk, starts with tag *)

  (* heap blocks *)
    tagOff      = S.VAL(S.ADDRESS, 0);      (* block starts with tag *)
    sizeOff     = S.VAL(S.ADDRESS, SZA);    (* block size in free block relative to block start *)
    sntlOff     = S.VAL(S.ADDRESS, 2*SZA);  (* pointer offset table sentinel in free block relative to block start *)
    nextOff     = S.VAL(S.ADDRESS, 3*SZA);  (* next pointer in free block relative to block start *)
    NoPtrSntl   = S.VAL(S.ADDRESS, -SZA);
    AddressZero = S.VAL(S.ADDRESS, 0);

  TYPE
    ModuleName- = ARRAY ModNameLen OF CHAR;
    CmdName-    = ARRAY CmdNameLen OF CHAR;

    Module- = POINTER TO ModuleDesc;
    Cmd-    = POINTER TO CmdDesc;

    EnumProc-   = PROCEDURE(P: PROCEDURE(p: S.PTR));

    ModuleDesc- = RECORD
      next-:     Module;
      name-:     ModuleName;
      refcnt-:   LONGINT;
      cmds-:     Cmd;
      types-:    S.ADDRESS;
      enumPtrs-: EnumProc;
      reserved1,
      reserved2: LONGINT
    END;

    Command- = PROCEDURE;

    Import = POINTER TO ImportDesc;
    ImportDesc = RECORD next: Import; imported: Module END;
    Lifetime = POINTER TO LifetimeDesc;
    LifetimeDesc = RECORD
      next: Lifetime; owner: Module; imports: Import;
      state: INTEGER; retained: LONGINT; initializer: S.ADDRESS
    END;
    Retention* = POINTER TO RetentionDesc;
    RetentionDesc = RECORD next: Retention; owner: Module END;
    ModuleNotifier* = PROCEDURE(owner: Module; initializer: S.ADDRESS);
    UnloadHandler* = PROCEDURE(owner: Module);
    UnloadHook = POINTER TO UnloadHookDesc;
    UnloadHookDesc = RECORD next: UnloadHook; owner: Module; handler: UnloadHandler END;

    Procedure = POINTER TO ProcedureDesc;
    ProcedureDesc = RECORD
      next: Procedure;
      owner: Module;
      address: S.ADDRESS
    END;

    Termination = POINTER TO TerminationDesc;
    TerminationDesc = RECORD
      next: Termination;
      owner: Module;
      handler: Command
    END;

    CmdDesc- = RECORD
      next-: Cmd;
      name-: CmdName;
      cmd-:  Command
    END;

    Finalizer = PROCEDURE(obj: S.PTR);

    FinNode   = POINTER TO FinDesc;
    FinDesc   = RECORD
      next:     FinNode;
      obj:      S.ADDRESS;  (* weak pointer *)
      marked:   BOOLEAN;
      finalize: Finalizer;
    END;

  VAR
    (* the list of loaded (=initialization started) modules *)
    modules-:   S.PTR; (*POINTER [1] TO ModuleDesc;*)

    freeList:   ARRAY nofLists + 1 OF S.ADDRESS;  (* dummy, 16, 32, 48, 64, 80, 96, 112, 128, sentinel *)
    bigBlocks:  S.ADDRESS;
    allocated*: S.ADDRESS;
    firstTry:   BOOLEAN;
    ldUnit:     INTEGER;    (* Unit = 2^ldUnit, for unsigned division expressed as logical shift right *)


    (* extensible heap *)
    heap-:          S.ADDRESS;  (* the sorted list of heap chunks *)
    heapMin:        S.ADDRESS;  (* Range of valid pointer values, used for stack collection *)
    heapMax:        S.ADDRESS;
    heapsize*:      S.ADDRESS;  (* the sum of all heap chunk sizes *)
    heapMinExpand*: S.ADDRESS;  (* minimum heap expansion size *)

    (* finalization candidates *)
    fin: FinNode;
    procedures: Procedure;
    terminations: Termination;
    lifetimes: Lifetime;
    retentions: Retention;
    notifier: ModuleNotifier;
    notifierRetention: Retention;
    unloadHooks: UnloadHook;

    (* garbage collector busy flag *)
    lockdepth:   INTEGER;
    interrupted: BOOLEAN;

    (* File system file count monitor *)
    FileCount*: INTEGER;


  PROCEDURE -CommandCritical(enter: BOOLEAN) "SYSTEM_CommandCritical(enter)";

  PROCEDURE Lock*;
  BEGIN
    CommandCritical(TRUE);
    INC(lockdepth);
  END Lock;

  PROCEDURE -ModulesHalt(code: LONGINT) "Modules_Halt(code)";

  PROCEDURE Unlock*;
  BEGIN
    DEC(lockdepth);
    IF interrupted & (lockdepth = 0) THEN
      ModulesHalt(-9);
    END;
    CommandCritical(FALSE)
  END Unlock;


  PROCEDURE -uLT(x, y: S.ADDRESS): BOOLEAN  "((size_t)x <  (size_t)y)";
  PROCEDURE -uLE(x, y: S.ADDRESS): BOOLEAN  "((size_t)x <= (size_t)y)";

  (*
    PROCEDURE TAS*(VAR flag:BOOLEAN): BOOLEAN; (* added for compatibility with ulmSYSTEM module; noch *)
    VAR oldflag : BOOLEAN;
    BEGIN
       oldflag := flag;
       flag := TRUE;
       RETURN oldflag;
    END TAS;
  *)

  PROCEDURE REGMOD*(VAR name: ModuleName; enumPtrs: EnumProc): S.PTR;
    VAR m: Module;
  BEGIN
    (* REGMOD is called at the start of module initialisation code before that modules
       type descriptors have been set up. 'NEW' depends on the Heap modules type
       descriptors being ready for use, therefore, just for the Heap module itself, we
       must use S.NEW. *)
    IF name = "Heap" THEN
      S.NEW(m, SIZE(ModuleDesc))
    ELSE
      NEW(m)
    END;
    m.types := 0; m.cmds := NIL;
    COPY(name, m.name);
    IF PinModules THEN m.refcnt := 1 ELSE m.refcnt := 0 END;
    m.enumPtrs := enumPtrs; m.next := S.VAL(Module, modules);
    modules := m;
    RETURN m
  END REGMOD;

  PROCEDURE FreeModule*(name: ARRAY OF CHAR): LONGINT;
  (* Returns 0 if freed, -1 if not found, refcount if found and refcount > 0. *)
    VAR m, p: Module;
  BEGIN m := S.VAL(Module, modules);
    WHILE (m # NIL) & (m.name # name) DO p := m; m := m.next END;
    IF (m # NIL) & (m.refcnt = 0) THEN
      IF m = S.VAL(Module, modules) THEN modules := m.next
      ELSE p.next := m.next
      END;
      RETURN 0
    ELSE
      IF m = NIL THEN RETURN -1 ELSE RETURN m.refcnt END
    END
  END FreeModule;


  PROCEDURE REGCMD*(m: Module; VAR name: CmdName; cmd: Command);
    VAR c: Cmd;
  BEGIN
    (* REGCMD is called during module initialisation code before that modules
       type descriptors have been set up. 'NEW' depends on the Heap modules type
       descriptors being ready for use, therefore, just for the commands registered
       by the Heap module itself, we must use S.NEW. *)
    IF m.name = "Heap" THEN
      S.NEW(c, SIZE(CmdDesc))
    ELSE
      NEW(c)
    END;
    COPY(name, c.name); c.cmd := cmd; c.next := m.cmds; m.cmds := c
  END REGCMD;

  PROCEDURE REGTYP*(m: Module; typ: S.ADDRESS);
  BEGIN S.PUT(typ, m.types); m.types := typ
  END REGTYP;

  PROCEDURE ^ModuleState*(owner: Module): INTEGER;

  PROCEDURE INCREF*(m: Module);
  BEGIN
    IF PinModules & (ModuleState(m) > 2) THEN ModulesHalt(-15) END;
    INC(m.refcnt)
  END INCREF;

  PROCEDURE Life(owner: Module; create: BOOLEAN): Lifetime;
    VAR l: Lifetime;
  BEGIN
    l := lifetimes;
    WHILE (l # NIL) & (l.owner # owner) DO l := l.next END;
    IF (l = NIL) & create THEN
      NEW(l); l.owner := owner; l.state := 1;
      l.next := lifetimes; lifetimes := l
    END;
    RETURN l
  END Life;

  PROCEDURE ModuleState*(owner: Module): INTEGER;
    VAR l: Lifetime;
  BEGIN
    l := Life(owner, FALSE);
    IF l = NIL THEN RETURN 0 ELSE RETURN l.state END
  END ModuleState;

  PROCEDURE REGIMPORT*(owner, imported: Module);
    VAR l: Lifetime; i: Import;
  BEGIN
    l := Life(owner, TRUE);
    NEW(i); i.imported := imported; i.next := l.imports; l.imports := i
  END REGIMPORT;

  PROCEDURE MODREADY*(owner: Module; initializer: S.ADDRESS);
    VAR l: Lifetime;
  BEGIN
    l := Life(owner, TRUE); l.state := 2; l.initializer := initializer;
    IF notifier # NIL THEN notifier(owner, initializer) END
  END MODREADY;

  PROCEDURE ^RetainProcedure*(address: S.ADDRESS): Retention;
  PROCEDURE -NotifierAddress(handler: ModuleNotifier): S.ADDRESS "(ADDRESS)handler";

  PROCEDURE SetModuleNotifier*(handler: ModuleNotifier);
    VAR l: Lifetime;
  BEGIN
    ASSERT(notifier = NIL); notifier := handler;
    notifierRetention := RetainProcedure(NotifierAddress(handler));
    ASSERT(notifierRetention # NIL);
    (* Startup import order can initialize ordinary libraries before the loader
       itself. Acquire their independent native ownership now, while mapped. *)
    l := lifetimes;
    WHILE l # NIL DO
      IF (l.state = 2) & (l.initializer # 0) THEN notifier(l.owner, l.initializer) END;
      l := l.next
    END
  END SetModuleNotifier;

  PROCEDURE RetainModule*(owner: Module): Retention;
    VAR l: Lifetime; r: Retention;
  BEGIN
    IF owner = NIL THEN RETURN NIL END;
    l := Life(owner, FALSE);
    IF (l = NIL) OR (l.state # 2) THEN RETURN NIL END;
    NEW(r); r.owner := owner; r.next := retentions; retentions := r;
    INC(l.retained);
    RETURN r
  END RetainModule;

  PROCEDURE ReleaseModule*(r: Retention): BOOLEAN;
    VAR p, previous: Retention; l: Lifetime;
  BEGIN
    p := retentions; previous := NIL;
    WHILE (p # NIL) & (p # r) DO previous := p; p := p.next END;
    IF p = NIL THEN RETURN FALSE END;
    l := Life(p.owner, FALSE); ASSERT(l # NIL); ASSERT(l.retained > 0);
    DEC(l.retained);
    IF previous = NIL THEN retentions := p.next ELSE previous.next := p.next END;
    p.owner := NIL; p.next := NIL;
    RETURN TRUE
  END ReleaseModule;

  PROCEDURE Retained*(owner: Module): LONGINT;
    VAR l: Lifetime;
  BEGIN
    l := Life(owner, FALSE);
    IF l = NIL THEN RETURN 0 ELSE RETURN l.retained END
  END Retained;

  PROCEDURE Imported*(owner: Module; index: INTEGER): Module;
    VAR l: Lifetime; i: Import;
  BEGIN
    l := Life(owner, FALSE);
    IF l = NIL THEN RETURN NIL END;
    i := l.imports;
    WHILE (i # NIL) & (index > 0) DO i := i.next; DEC(index) END;
    IF i = NIL THEN RETURN NIL ELSE RETURN i.imported END
  END Imported;

  (* The compiler registers native procedure addresses, including private
     callbacks. This avoids guessing ownership from libc/ELF struct layouts. *)
  PROCEDURE REGPROC*(m: Module; address: S.ADDRESS);
    VAR p: Procedure;
  BEGIN
    NEW(p); p.owner := m; p.address := address;
    p.next := procedures; procedures := p
  END REGPROC;

  PROCEDURE ProcedureModule*(address: S.ADDRESS): Module;
    VAR p: Procedure;
  BEGIN
    p := procedures;
    WHILE (p # NIL) & (p.address # address) DO p := p.next END;
    IF p = NIL THEN RETURN NIL ELSE RETURN p.owner END
  END ProcedureModule;

  (* Runtime callback registration may happen during its owner's initializer.
     Unlike a raw external lease, its owner is known from generated metadata. *)
  PROCEDURE RetainProcedure*(address: S.ADDRESS): Retention;
    VAR owner: Module; l: Lifetime; r: Retention;
  BEGIN
    owner := ProcedureModule(address);
    IF owner = NIL THEN RETURN NIL END;
    l := Life(owner, TRUE);
    IF l.state > 2 THEN RETURN NIL END;
    NEW(r); r.owner := owner; r.next := retentions; retentions := r;
    INC(l.retained);
    RETURN r
  END RetainProcedure;

  PROCEDURE -CommandAddress(handler: Command): S.ADDRESS "(ADDRESS)handler";
  PROCEDURE -FinalizerAddress(handler: Finalizer): S.ADDRESS "(ADDRESS)handler";
  PROCEDURE -HookAddress(handler: UnloadHandler): S.ADDRESS "(ADDRESS)handler";

  PROCEDURE RegisterUnloadHook*(handler: UnloadHandler): BOOLEAN;
    VAR h: UnloadHook; owner: Module; l: Lifetime;
  BEGIN
    IF handler = NIL THEN RETURN FALSE END;
    h := unloadHooks;
    WHILE (h # NIL) & (h.handler # handler) DO h := h.next END;
    IF h # NIL THEN RETURN TRUE END;
    owner := ProcedureModule(HookAddress(handler));
    IF owner = NIL THEN RETURN FALSE END;
    l := Life(owner, TRUE);
    IF l.state > 2 THEN RETURN FALSE END;
    NEW(h); h.owner := owner; h.handler := handler;
    h.next := unloadHooks; unloadHooks := h; INC(l.retained);
    RETURN TRUE
  END RegisterUnloadHook;

  PROCEDURE UnregisterUnloadHook*(handler: UnloadHandler): BOOLEAN;
    VAR h, previous: UnloadHook; l: Lifetime;
  BEGIN
    h := unloadHooks; previous := NIL;
    WHILE (h # NIL) & (h.handler # handler) DO previous := h; h := h.next END;
    IF h = NIL THEN RETURN FALSE END;
    l := Life(h.owner, FALSE); DEC(l.retained);
    IF previous = NIL THEN unloadHooks := h.next ELSE previous.next := h.next END;
    RETURN TRUE
  END UnregisterUnloadHook;

  PROCEDURE DetachCallbacks*(owner: Module);
    VAR h: UnloadHook;
  BEGIN
    h := unloadHooks;
    WHILE h # NIL DO h.handler(owner); h := h.next END
  END DetachCallbacks;

  PROCEDURE -Active(owner: Module): BOOLEAN "SYSTEM_ModuleActive(owner)";
  PROCEDURE -NativeCallback(index: INTEGER): S.ADDRESS "SYSTEM_ModuleCallback(index)";

  PROCEDURE NativeCallbacks(owner: Module): BOOLEAN;
    VAR i: INTEGER; address: S.ADDRESS;
  BEGIN
    i := 0;
    WHILE i < 10 DO
      address := NativeCallback(i);
      IF (address # 0) & (ProcedureModule(address) = owner) THEN RETURN TRUE END;
      INC(i)
    END;
    RETURN FALSE
  END NativeCallbacks;

  PROCEDURE CheckModule*(owner: Module): INTEGER;
    VAR l: Lifetime;
  BEGIN
    l := Life(owner, FALSE);
    IF l = NIL THEN RETURN 1 END; (* Permanent core/legacy registration. *)
    IF l.state # 2 THEN RETURN 2 END;
    IF owner.refcnt # 1 THEN RETURN 3 END;
    IF Active(owner) THEN RETURN 4 END;
    IF (l.retained # 0) OR NativeCallbacks(owner) THEN RETURN 5 END;
    IF lockdepth # 0 THEN RETURN 6 END;
    RETURN 0
  END CheckModule;

  PROCEDURE BeginFree*(owner: Module);
    VAR l: Lifetime;
  BEGIN l := Life(owner, FALSE); ASSERT(l # NIL); l.state := 3
  END BeginFree;

  PROCEDURE Finishable*(owner: Module): BOOLEAN;
    VAR l: Lifetime;
  BEGIN
    l := Life(owner, FALSE);
    RETURN (l # NIL) & (l.state = 3) & (l.retained = 0) & (owner.refcnt = 1) &
      ~Active(owner) & ~NativeCallbacks(owner)
  END Finishable;

  PROCEDURE HasFinalizers*(owner: Module): BOOLEAN;
    VAR f: FinNode;
  BEGIN
    f := fin;
    WHILE f # NIL DO
      IF ProcedureModule(FinalizerAddress(f.finalize)) = owner THEN RETURN TRUE END;
      f := f.next
    END;
    RETURN FALSE
  END HasFinalizers;

  PROCEDURE DisableModule*(owner: Module);
    VAR l: Lifetime;
  BEGIN
    l := Life(owner, FALSE); ASSERT(l # NIL); l.state := 4;
    owner.cmds := NIL; owner.enumPtrs := NIL
  END DisableModule;

  PROCEDURE CommitFree*(owner: Module);
    VAR m, previous: Module; l, lp: Lifetime; i: Import;
      p, pp, pn: Procedure; t, tp: Termination;
  BEGIN
    l := lifetimes; lp := NIL;
    WHILE (l # NIL) & (l.owner # owner) DO lp := l; l := l.next END;
    ASSERT(l # NIL); ASSERT(l.retained = 0);
    i := l.imports;
    WHILE i # NIL DO ASSERT(i.imported.refcnt > 0); DEC(i.imported.refcnt); i := i.next END;
    IF lp = NIL THEN lifetimes := l.next ELSE lp.next := l.next END;
    p := procedures; pp := NIL;
    WHILE p # NIL DO
      pn := p.next;
      IF p.owner = owner THEN
        IF pp = NIL THEN procedures := pn ELSE pp.next := pn END
      ELSE pp := p END;
      p := pn
    END;
    t := terminations; tp := NIL;
    WHILE (t # NIL) & (t.owner # owner) DO tp := t; t := t.next END;
    IF t # NIL THEN
      IF tp = NIL THEN terminations := t.next ELSE tp.next := t.next END
    END;
    m := S.VAL(Module, modules); previous := NIL;
    WHILE (m # NIL) & (m # owner) DO previous := m; m := m.next END;
    ASSERT(m # NIL);
    IF previous = NIL THEN modules := m.next ELSE previous.next := m.next END;
    m.cmds := NIL; m.enumPtrs := NIL; m.types := 0; m.next := NIL; m.refcnt := 0
  END CommitFree;

  PROCEDURE InstallTermHandler*(handler: Command): BOOLEAN;
    VAR owner: Module; t: Termination;
  BEGIN
    IF handler = NIL THEN RETURN FALSE END;
    owner := ProcedureModule(CommandAddress(handler));
    IF owner = NIL THEN RETURN FALSE END;
    IF ModuleState(owner) > 2 THEN RETURN FALSE END;
    t := terminations;
    WHILE (t # NIL) & (t.owner # owner) DO t := t.next END;
    IF t = NIL THEN
      NEW(t); t.owner := owner; t.next := terminations; terminations := t
    END;
    t.handler := handler;
    RETURN TRUE
  END InstallTermHandler;

  PROCEDURE Terminate(owner: Module);
    VAR t: Termination; handler: Command;
  BEGIN
    t := terminations;
    WHILE (t # NIL) & (t.owner # owner) DO t := t.next END;
    IF (t # NIL) & (t.handler # NIL) THEN
      handler := t.handler; t.handler := NIL; (* Clear before calling: no double cleanup after HALT. *)
      handler
    END
  END Terminate;


  PROCEDURE -ExternPlatformOSAllocate "extern ADDRESS Platform_OSAllocate(ADDRESS size);";
  PROCEDURE -OSAllocate(size: S.ADDRESS): S.ADDRESS "Platform_OSAllocate(size)";

  PROCEDURE NewChunk(blksz: S.ADDRESS): S.ADDRESS;
    VAR chnk, blk, end: S.ADDRESS;
  BEGIN
    chnk := OSAllocate(blksz + blkOff);
    IF chnk # 0 THEN
      blk := chnk + blkOff; (* Heap chunk consists of a single block *)
      end := blk  + blksz;
      S.PUT(chnk + endOff,   end);
      S.PUT(blk  + tagOff,   blk + sizeOff);
      S.PUT(blk  + sizeOff,  blksz);
      S.PUT(blk  + sntlOff,  NoPtrSntl);
      S.PUT(blk  + nextOff,  bigBlocks);
      bigBlocks := blk;  (* Prepend block to list of big blocks *)
      INC(heapsize, blksz);
      (* Maintain heap range limits *)
      IF uLT(blk + SZA, heapMin) THEN heapMin := blk + SZA END;
      IF uLT(heapMax,   end)     THEN heapMax := end       END
    END;
    RETURN chnk
  END NewChunk;

  PROCEDURE ExtendHeap(blksz: S.ADDRESS);
    VAR size, chnk, j, next: S.ADDRESS;
  BEGIN
    ASSERT(blksz MOD Unit = 0);
    IF uLT(heapMinExpand, blksz) THEN size := blksz
    ELSE size := heapMinExpand  (* additional heuristics for avoiding many small heap expansions *)
    END;
    chnk := NewChunk(size);
    IF chnk # 0 THEN
      (*sorted insertion*)
      IF uLT(chnk, heap) THEN
        S.PUT(chnk, heap); heap := chnk
      ELSE
        j := heap; S.GET(j, next);
        WHILE (next # 0) & uLT(next, chnk) DO
          j := next;
          S.GET(j, next)
        END;
        S.PUT(chnk, next); S.PUT(j, chnk)
      END
    ELSIF ~firstTry THEN
      (* Heap memory exhausted, i.e. heap is not expanded and NEWREC() will return NIL.
         In order to be able to report a trap due to NIL access, there is more
         memory needed, which may be available by reducing heapMinExpand. *)
      heapMinExpand := Unit
    (* ELSE firstTry: ignore failed heap expansion for anti-thrashing heuristics. *)
    END
  END ExtendHeap;

  PROCEDURE ^GC*(markStack: BOOLEAN);

  PROCEDURE NEWREC*(tag: S.ADDRESS): S.PTR;
    VAR
      i, i0, di, blksz, restsize, t, adr, end, next, prev: S.ADDRESS;
      new:   S.PTR;
  BEGIN
    Lock();
    S.GET(tag, blksz);

    ASSERT(SIZE(S.PTR) = SIZE(S.ADDRESS));
    ASSERT(blksz MOD Unit = 0);

    i0 := S.LSH(blksz, -ldUnit); (*uDIV Unit*)
    i := i0;
    IF i < nofLists THEN adr := freeList[i];
      WHILE adr = 0 DO INC(i); adr := freeList[i] END
    END;
    IF i < nofLists THEN (* Unlink from freelist[i] *)
      S.GET(adr + nextOff, next);
      freeList[i] := next;
      IF i # i0 THEN (* Split *)
        di := i - i0; restsize := di * Unit; end := adr + restsize;
        S.PUT(end + sizeOff, blksz);
        S.PUT(end + sntlOff, NoPtrSntl);
        S.PUT(end,           end + sizeOff);
        S.PUT(adr + sizeOff, restsize);
        S.PUT(adr + nextOff, freeList[di]);
        freeList[di] := adr;
        INC(adr, restsize)
      END
    ELSE (* Search in bigBlocks *)
      adr := bigBlocks; prev := 0;
      LOOP
        IF adr = 0 THEN (* Nothing free *)
          IF firstTry THEN
            GC(TRUE); INC(blksz, Unit);
            (* Anti-thrashing heuristics: ensure 1/5 of the heap will not be allocated. *)
            t := S.LSH(allocated + blksz, -(2+ldUnit)) (*uDIV 4*Unit*) * (5*Unit) ; (* Minimum preferred heapsize *)
            IF uLT(heapsize, t) THEN ExtendHeap(t - heapsize)
              (* If there is not enough heap memory then the heap will be expanded below by blksz *)
            END;
            firstTry := FALSE; new := NEWREC(tag);
            IF new = NIL THEN (* Heap is 1/5 free but fragmentation prevented allocation *)
              ExtendHeap(blksz);
              new := NEWREC(tag)  (* Will find a free block if heap has been expanded successfully *)
            END;
            firstTry := TRUE;
            Unlock(); RETURN new
          ELSE
            Unlock(); RETURN NIL
          END
        END;
        S.GET(adr+sizeOff, t);
        IF uLE(blksz, t) THEN EXIT END;
        prev := adr; S.GET(adr + nextOff, adr)
      END;
      restsize := t - blksz; end := adr + restsize;
      S.PUT(end + sizeOff, blksz);
      S.PUT(end + sntlOff, NoPtrSntl);
      S.PUT(end,           end + sizeOff);
      IF uLT(nofLists * Unit, restsize) THEN (* Resize *)
        S.PUT(adr + sizeOff, restsize)
      ELSE (* Unlink *)
        S.GET(adr + nextOff, next);
        IF prev = 0 THEN bigBlocks := next
        ELSE S.PUT(prev + nextOff, next);
        END;
        IF restsize # 0 THEN (* Move *)
          di := restsize DIV Unit;
          S.PUT(adr + sizeOff, restsize);
          S.PUT(adr + nextOff, freeList[di]);
          freeList[di] := adr
        END
      END;
      INC(adr, restsize)
    END;
    i := adr + 4*SZA; end := adr + blksz;
    WHILE uLT(i, end) DO  (* Deliberately unrolled *)
      S.PUT(i,         AddressZero);
      S.PUT(i + SZA,   AddressZero);
      S.PUT(i + 2*SZA, AddressZero);
      S.PUT(i + 3*SZA, AddressZero);
      INC(i, 4*SZA)
    END;
    S.PUT(adr + nextOff, AddressZero);
    S.PUT(adr,           tag);
    S.PUT(adr + sizeOff, AddressZero);
    S.PUT(adr + sntlOff, AddressZero);
    INC(allocated, blksz);
    Unlock();
    RETURN S.VAL(S.PTR, adr + SZA)
  END NEWREC;

  PROCEDURE NEWBLK*(size: S.ADDRESS): S.PTR;
     VAR blksz, tag: S.ADDRESS; new: S.PTR;
  BEGIN
    Lock();
    blksz := (size + (4*SZA + Unit - 1)) DIV Unit * Unit;  (*size + tag + meta + blksz + sntnl + UnitAlignment*)
    new := NEWREC(S.ADR(blksz));
    tag := S.VAL(S.ADDRESS, new) + blksz - 3*SZA;
    S.PUT(tag - SZA,                      AddressZero); (*reserved for meta info*)
    S.PUT(tag,                            blksz);
    S.PUT(tag + SZA,                      NoPtrSntl);
    S.PUT(S.VAL(S.ADDRESS, new) - SZA, tag);
    Unlock();
    RETURN new
  END NEWBLK;

  PROCEDURE Mark(q: S.ADDRESS);
    VAR p, tag, offset, fld, n, tagbits: S.ADDRESS;
  BEGIN
    IF q # 0 THEN
      S.GET(q - SZA, tagbits);                 (* Load the tag for the record at q *)
      IF ~ODD(tagbits) THEN                    (* If it has not already been marked *)
        S.PUT(q - SZA, tagbits + 1);           (* Mark it *)
        p := 0;
        tag := tagbits + SZA;                  (* Tag addresses first offset *)
        LOOP
          S.GET(tag, offset);                  (* Get next ptr field offset *)
          IF offset < 0 THEN                   (* Sentinel reached: Value is -8*(#fields+1) *)
            S.PUT(q - SZA, tag + offset + 1);  (* Rotate base ptr into tag *)
            IF p = 0 THEN EXIT END;
            n := q; q := p;
            S.GET(q - SZA, tag); DEC(tag, 1);
            S.GET(tag, offset); fld := q + offset;
            S.GET(fld, p); S.PUT(fld, S.VAL(S.PTR, n))
          ELSE                                 (* offset references a ptr field *)
            fld := q + offset;                 (* S.ADDRESS the pointer *)
            S.GET(fld, n);                     (* Load the pointer *)
            IF n # 0 THEN                      (* If pointer is not NIL *)
              S.GET(n - SZA, tagbits);         (* Consider record pointed to by this field *)
              IF ~ODD(tagbits) THEN
                S.PUT(n - SZA, tagbits + 1);
                S.PUT(q - SZA, tag + 1);
                S.PUT(fld, S.VAL(S.PTR, p));
                p := q; q := n;
                tag := tagbits
              END
            END
          END;
          INC(tag, SZA)
        END
      END
    END
  END Mark;

  PROCEDURE MarkP(p: S.PTR);  (* for compatibility with EnumPtrs in ANSI mode *)
  BEGIN
    Mark(S.VAL(S.ADDRESS, p))
  END MarkP;

  PROCEDURE Scan;
    VAR chnk, adr, end, start, tag, i, size, freesize: S.ADDRESS;
  BEGIN bigBlocks := 0; i := 1;
    WHILE i < nofLists DO freeList[i] := 0; INC(i) END;
    freesize := 0; allocated := 0; chnk := heap;
    WHILE chnk # 0 DO
      adr := chnk + blkOff;
      S.GET(chnk + endOff, end);
      WHILE uLT(adr, end) DO
        S.GET(adr, tag);
        IF ODD(tag) THEN  (* Marked *)
          IF freesize # 0 THEN
            start := adr - freesize;
            S.PUT(start,         start+SZA);
            S.PUT(start+sizeOff, freesize);
            S.PUT(start+sntlOff, NoPtrSntl);
            i := S.LSH(freesize, -ldUnit) (*uDIV Unit*);
            freesize := 0;
            IF uLT(i, nofLists) THEN S.PUT(start + nextOff, freeList[i]); freeList[i] := start
            ELSE                     S.PUT(start + nextOff, bigBlocks);   bigBlocks   := start
            END
          END;
          DEC(tag, 1);
          S.PUT(adr, tag);
          S.GET(tag, size);
          INC(allocated, size);
          INC(adr, size)
        ELSE  (*unmarked*)
          S.GET(tag, size);
          INC(freesize, size);
          INC(adr, size)
        END
      END;
      IF freesize # 0 THEN (* Collect last block *)
        start := adr - freesize;
        S.PUT(start,         start+SZA);
        S.PUT(start+sizeOff, freesize);
        S.PUT(start+sntlOff, NoPtrSntl);
        i := S.LSH(freesize, -ldUnit) (*uDIV Unit*);
        freesize := 0;
        IF uLT(i, nofLists) THEN S.PUT(start + nextOff, freeList[i]); freeList[i] := start
        ELSE                     S.PUT(start + nextOff, bigBlocks);   bigBlocks   := start
        END
      END;
      S.GET(chnk, chnk)
    END
  END Scan;

  PROCEDURE Sift (l, r: LONGINT; VAR a: ARRAY OF S.ADDRESS);
    VAR i, j: LONGINT; x: S.ADDRESS;
  BEGIN j := l; x := a[j];
    LOOP i := j; j := 2*j + 1;
      IF (j < r) &  uLT(a[j], a[j+1]) THEN INC(j) END;
      IF (j > r) OR uLE(a[j], x) THEN EXIT END;
      a[i] := a[j]
    END;
    a[i] := x
  END Sift;

  PROCEDURE HeapSort (n: LONGINT; VAR a: ARRAY OF S.ADDRESS);
    VAR l, r: LONGINT; x: S.ADDRESS;
  BEGIN l := n DIV 2; r := n - 1;
    WHILE l > 0 DO DEC(l); Sift(l, r, a) END;
    WHILE r > 0 DO x := a[0]; a[0] := a[r]; a[r] := x; DEC(r); Sift(l, r, a) END
  END HeapSort;

  PROCEDURE MarkCandidates(n: LONGINT; VAR cand: ARRAY OF S.ADDRESS);
    VAR chnk, end, adr, tag, next, i, ptr, size: S.ADDRESS;
  BEGIN
    ASSERT(n > 0);
    chnk := heap; i := 0;
    WHILE chnk # 0 DO
      S.GET(chnk + endOff, end);
      adr := chnk + blkOff;
      WHILE uLT(adr, end) DO
        S.GET(adr, tag);
        IF ODD(tag) THEN (*already marked*)
          S.GET(tag-1, size); INC(adr, size); ptr := adr + SZA;
          WHILE uLT(cand[i], ptr) DO INC(i); IF i = n THEN RETURN END END ;
        ELSE
          S.GET(tag, size); ptr := adr + SZA; INC(adr, size);
          WHILE uLT(cand[i], ptr) DO INC(i); IF i = n THEN RETURN END END ;
          IF uLT(cand[i], adr) THEN Mark(ptr) END
        END ;
        IF uLE(end, cand[i]) THEN (*skip rest of this heap chunk*) adr := end END
      END ;
      S.GET(chnk + nextChnkOff, chnk)
    END
  END MarkCandidates;

  PROCEDURE CheckFin;
    VAR n: FinNode; tag: S.ADDRESS;
  BEGIN
    n := fin;
    WHILE n # NIL DO
      S.GET(n.obj - SZA, tag);
      IF ~ODD(tag) THEN n.marked := FALSE; Mark(n.obj)
      ELSE n.marked := TRUE
      END;
      n := n.next
    END
  END CheckFin;

  PROCEDURE Finalize;
    VAR n, prev: FinNode;
  BEGIN n := fin; prev := NIL;
    WHILE n # NIL DO
      IF ~n.marked THEN
        IF n = fin THEN fin := fin.next ELSE prev.next := n.next END;
        n.finalize(S.VAL(S.PTR, n.obj));
        (* new nodes may have been pushed in n.finalize, therefore: *)
        IF prev = NIL THEN n := fin ELSE n := n.next END
      ELSE
        prev := n; n := n.next
      END
    END
  END Finalize;

  PROCEDURE FINALL*;
    VAR n: FinNode; m: Module;
  BEGIN
    Lock;
    WHILE fin # NIL DO
      n := fin; fin := fin.next;
      n.finalize(S.VAL(S.PTR, n.obj))
    END;
    (* Registration order is reverse import order: clients terminate first. *)
    m := S.VAL(Module, modules);
    WHILE m # NIL DO Terminate(m); m := m.next END;
    Unlock
  END FINALL;

  PROCEDURE FINALMOD*(owner: Module);
    VAR n, previous, next: FinNode;
  BEGIN
    IF owner = NIL THEN RETURN END;
    Lock;
    (* Unlink each callback before calling it; finalizers may register others. *)
    n := fin; previous := NIL;
    WHILE n # NIL DO
      next := n.next;
      IF ProcedureModule(FinalizerAddress(n.finalize)) = owner THEN
        IF previous = NIL THEN fin := next ELSE previous.next := next END;
        n.finalize(S.VAL(S.PTR, n.obj));
        n := fin; previous := NIL
      ELSE previous := n; n := next
      END
    END;
    Terminate(owner);
    Unlock
  END FINALMOD;

  PROCEDURE -ExternMainStackFrame               "extern ADDRESS Modules_MainStackFrame;";
  PROCEDURE -ModulesMainStackFrame(): S.ADDRESS "Modules_MainStackFrame";

  PROCEDURE MarkStack(n: S.ADDRESS; VAR cand: ARRAY OF S.ADDRESS);
    VAR
      frame: S.PTR;
      nofcand: LONGINT;
      inc, sp, p, stack0: S.ADDRESS;
      align: RECORD ch: CHAR; p: S.PTR END;
  BEGIN
    IF n > 0 THEN MarkStack(n-1, cand);  (* flush register windows by means of recursive calls *)
      IF n > 100 THEN RETURN END   (* prevent tail recursion optimization *)
    END;
    IF n = 0 THEN
      nofcand := 0; sp := S.ADR(frame);
      stack0 := ModulesMainStackFrame();
      (* check for minimum alignment of pointers *)
      inc := S.ADR(align.p) - S.ADR(align);
      IF uLT(stack0, sp) THEN inc := -inc END;
      WHILE sp # stack0 DO
        S.GET(sp, p);
        IF uLE(heapMin, p) & uLT(p, heapMax) THEN
          IF nofcand = LEN(cand) THEN HeapSort(nofcand, cand); MarkCandidates(nofcand, cand); nofcand := 0 END;
          cand[nofcand] := p; INC(nofcand)
        END;
        INC(sp, inc)
      END;
      IF nofcand > 0 THEN HeapSort(nofcand, cand); MarkCandidates(nofcand, cand) END
    END
  END MarkStack;



  PROCEDURE MarkRoots(excluded: Module; markStack: BOOLEAN);
    VAR
      m: Module;
      i0,  i1,  i2,  i3,  i4,  i5,  i6,  i7,  i8,  i9,  i10, i11,
      i12, i13, i14, i15, i16, i17, i18, i19, i20, i21, i22, i23: S.ADDRESS;
      cand: ARRAY 10000 OF S.ADDRESS;
  BEGIN
    m := S.VAL(Module, modules);
    WHILE m # NIL DO
      IF (m # excluded) & (m.enumPtrs # NIL) THEN m.enumPtrs(MarkP) END;
      m := m^.next
    END;
    IF markStack THEN
      (* generate register pressure to force callee saved registers to memory;
         may be simplified by inlining OS calls or processor specific instructions
      *)
      i0  := -100; i1  := -101; i2  := -102; i3  := -103; i4  := -104; i5  := -105; i6  := -106; i7  := -107;
      i8  :=    1; i9  :=    2; i10 :=    3; i11 :=    4; i12 :=    5; i13 :=    6; i14 :=    7; i15 :=    8;
      i16 :=    9; i17 :=   10; i18 :=   11; i19 :=   12; i20 :=   13; i21 :=   14; i22 :=   15; i23 :=   16;
      LOOP
        INC(i0,   1); INC(i1,   2); INC(i2,   3); INC(i3,   4); INC(i4,   5); INC(i5,   6); INC(i6,   7); INC(i7,   8);
        INC(i8,   9); INC(i9,  10); INC(i10, 11); INC(i11, 12); INC(i12, 13); INC(i13, 14); INC(i14, 15); INC(i15, 16);
        INC(i16, 17); INC(i17, 18); INC(i18, 19); INC(i19, 20); INC(i20, 21); INC(i21, 22); INC(i22, 23); INC(i23, 24);
        IF (i0 = -99) & (i15 = 24) THEN  (* True at first iteration *)
          MarkStack(32, cand); EXIT
        END
      END;
      IF i0  + i1  + i2  + i3  + i4  + i5  + i6  + i7  (* use all variables *)
       + i8  + i9  + i10 + i11 + i12 + i13 + i14 + i15
       + i16 + i17 + i18 + i19 + i20 + i21 + i22 + i23 > 10000 THEN  (* Always false *)
        RETURN
      END;
    END;
  END MarkRoots;

  PROCEDURE -TypeTag(link: S.ADDRESS): S.ADDRESS
    "link + (__MAXEXT + 24/sizeof(ADDRESS) + 4)*sizeof(ADDRESS)";

  PROCEDURE OwnedType(owner: Module; tag: S.ADDRESS): BOOLEAN;
    VAR t: S.ADDRESS;
  BEGIN
    t := owner.types;
    WHILE t # 0 DO
      IF TypeTag(t) = tag THEN RETURN TRUE END;
      S.GET(t, t)
    END;
    RETURN FALSE
  END OwnedType;

  (* Inspect tags while mapped. In check-only mode, unmark without reclaiming
     anything: a refused free must not destroy the module's private state. *)
  PROCEDURE TypeReferences(owner: Module; markedOnly: BOOLEAN): BOOLEAN;
    VAR chnk, adr, end, tag, size: S.ADDRESS; found: BOOLEAN;
  BEGIN
    chnk := heap; found := FALSE;
    WHILE chnk # 0 DO
      adr := chnk + blkOff; S.GET(chnk + endOff, end);
      WHILE uLT(adr, end) DO
        S.GET(adr, tag);
        IF ODD(tag) THEN
          DEC(tag); S.PUT(adr, tag);
          IF OwnedType(owner, tag) THEN found := TRUE END
        ELSIF ~markedOnly THEN
          IF OwnedType(owner, tag) THEN found := TRUE END
        END;
        S.GET(tag, size); INC(adr, size)
      END;
      S.GET(chnk, chnk)
    END;
    RETURN found
  END TypeReferences;

  PROCEDURE LiveTypes*(owner: Module): BOOLEAN;
    VAR n: FinNode; found: BOOLEAN;
  BEGIN
    Lock;
    MarkRoots(owner, TRUE);
    (* Other owners' finalizers are future users even of otherwise dead objects. *)
    n := fin;
    WHILE n # NIL DO
      IF ProcedureModule(FinalizerAddress(n.finalize)) # owner THEN Mark(n.obj) END;
      n := n.next
    END;
    found := TypeReferences(owner, TRUE);
    Unlock;
    RETURN found
  END LiveTypes;

  PROCEDURE Collect(excluded: Module; markStack: BOOLEAN);
  BEGIN
    Lock(); MarkRoots(excluded, markStack); CheckFin;
    Scan;
    Finalize;
    Unlock()
  END Collect;

  PROCEDURE GC*(markStack: BOOLEAN);
  BEGIN Collect(NIL, markStack)
  END GC;

  PROCEDURE CollectModule*(owner: Module): BOOLEAN;
    VAR found: BOOLEAN;
  BEGIN
    Collect(owner, TRUE);
    Lock; found := TypeReferences(owner, FALSE); Unlock;
    RETURN ~found
  END CollectModule;

  PROCEDURE RegisterFinalizer*(obj: S.PTR; finalize: Finalizer);
    VAR f: FinNode;
  BEGIN NEW(f);
    f.obj := S.VAL(S.ADDRESS, obj); f.finalize := finalize; f.marked := TRUE;
    f.next := fin; fin := f;
  END RegisterFinalizer;


  PROCEDURE -ExternHeapInit "extern void *Heap__init();";
  PROCEDURE -HeapModuleInit 'Heap__init()';

  PROCEDURE InitHeap*;
  (* InitHeap is called by Platform.init before any module bodies have been
     initialised, to enable NEW, S.NEW *)
  BEGIN
    heap          := 0;
    heapsize      := 0;
    allocated     := 0;
    lockdepth     := 0;
    heapMin       := -1;        (* all bits set = max unsigned value *)
    heapMax       := 0;
    bigBlocks     := 0;
    heapMinExpand := heapSize0;

    ASSERT((Unit = 16) OR (Unit = 32));
    IF Unit = 16 THEN ldUnit := 4 ELSE ldUnit := 5 END;

    heap := NewChunk(heapSize0);
    S.PUT(heap + nextChnkOff, AddressZero);

    firstTry    := TRUE;
    freeList[nofLists] := 1; (* Sentinel, # 0 *)

    FileCount   := 0;
    modules     := NIL;
    fin         := NIL;
    procedures  := NIL;
    terminations := NIL;
    lifetimes := NIL; retentions := NIL; notifier := NIL; notifierRetention := NIL; unloadHooks := NIL;
    interrupted := FALSE;

    HeapModuleInit;
  END InitHeap;

END Heap.
