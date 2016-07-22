MODULE Heap;

  IMPORT SYSTEM;  (* Cannot import anything else as heap initialization must complete
                     before any other modules are initialized. *)

  CONST
    ModNameLen = 20;
    CmdNameLen = 24;
    SZL        = SIZE(LONGINT);
    Unit       = 4*SZL;     (* smallest possible heap block *)
    nofLists   = 9;         (* number of free_lists *)
    heapSize0  = 8000*Unit; (* startup heap size *)

  (* all blocks look the same:
    free blocks describe themselves: size = Unit
    tag = &tag++
  ->block size
    sentinel = -SZL
    next
  *)

  (* heap chunks *)
    nextChnkOff = LONG(LONG(0));      (* next heap chunk, sorted ascendingly! *)
    endOff      = LONG(LONG(SZL));    (* end of heap chunk *)
    blkOff      = LONG(LONG(3*SZL));  (* first block in a chunk *)

  (* heap blocks *)
    tagOff    = LONG(LONG(0));        (* block starts with tag *)
    sizeOff   = LONG(LONG(SZL));      (* block size in free block relative to block start *)
    sntlOff   = LONG(LONG(2*SZL));    (* pointer offset table sentinel in free block relative to block start *)
    nextOff   = LONG(LONG(3*SZL));    (* next pointer in free block relative to block start *)
    NoPtrSntl = LONG(LONG(-SZL));
    LongZero  = LONG(LONG(0));

  TYPE
    ModuleName = ARRAY ModNameLen OF CHAR;
    CmdName    = ARRAY CmdNameLen OF CHAR;

    Module = POINTER TO ModuleDesc;
    Cmd    = POINTER TO CmdDesc;

    EnumProc   = PROCEDURE(P: PROCEDURE(p: SYSTEM.PTR));

    ModuleDesc = RECORD
      next:     Module;
      name:     ModuleName;
      refcnt:   LONGINT;
      cmds:     Cmd;
      types:    LONGINT;
      enumPtrs: EnumProc;
      reserved1, reserved2: LONGINT
    END ;

    Command = PROCEDURE;

    CmdDesc = RECORD
      next: Cmd;
      name: CmdName;
      cmd:  Command
    END ;

    Finalizer = PROCEDURE(obj: SYSTEM.PTR);

    FinNode   = POINTER TO FinDesc;
    FinDesc   = RECORD
      next:     FinNode;
      obj:      LONGINT;  (* weak pointer *)
      marked:   BOOLEAN;
      finalize: Finalizer;
    END ;

  VAR
    (* the list of loaded (=initialization started) modules *)
    modules*: SYSTEM.PTR;

    freeList:   ARRAY nofLists + 1 OF LONGINT;  (* dummy, 16, 32, 48, 64, 80, 96, 112, 128, sentinel *)
    bigBlocks:  LONGINT;
    allocated*: LONGINT;
    firstTry:   BOOLEAN;

    (* extensible heap *)
    heap:      LONGINT;  (* the sorted list of heap chunks *)
    heapend:   LONGINT;  (* max possible pointer value (used for stack collection) *)
    heapsize*: LONGINT;  (* the sum of all heap chunk sizes *)

    (* finalization candidates *)
    fin: FinNode;

    (* garbage collector locking *)
    lockdepth:   INTEGER;
    interrupted: BOOLEAN;

    (* File system file count monitor *)
    FileCount*: INTEGER;


  PROCEDURE Lock*;
  BEGIN
    INC(lockdepth);
  END Lock;

  PROCEDURE -PlatformHalt(code: LONGINT) "Platform_Halt(code)";

  PROCEDURE Unlock*;
  BEGIN
    DEC(lockdepth);
    IF interrupted & (lockdepth = 0) THEN
      PlatformHalt(-9);
    END
  END Unlock;


  (*
    PROCEDURE TAS*(VAR flag:BOOLEAN): BOOLEAN; (* added for compatibility with ulmSYSTEM module; noch *)
    VAR oldflag : BOOLEAN;
    BEGIN
       oldflag := flag;
       flag := TRUE;
       RETURN oldflag;
    END TAS;
  *)

  PROCEDURE REGMOD*(VAR name: ModuleName; enumPtrs: EnumProc): SYSTEM.PTR;
    VAR m: Module;
  BEGIN
    (* REGMOD is called at the start of module initialisation code before that modules
       type descriptors have been set up. 'NEW' depends on the Heap modules type
       descriptors being ready for use, therefore, just for the Heap module itself, we
       must use SYSTEM.NEW. *)
    IF name = "Heap" THEN
      SYSTEM.NEW(m, SIZE(ModuleDesc))
    ELSE
      NEW(m)
    END;
    m.types := 0; m.cmds := NIL;
    COPY(name, m.name); m.refcnt := 0; m.enumPtrs := enumPtrs; m.next := SYSTEM.VAL(Module, modules);
    modules := m;
    RETURN m
  END REGMOD;

  PROCEDURE REGCMD*(m: Module; VAR name: CmdName; cmd: Command);
    VAR c: Cmd;
  BEGIN
    (* REGCMD is called during module initialisation code before that modules
       type descriptors have been set up. 'NEW' depends on the Heap modules type
       descriptors being ready for use, therefore, just for the commands registered
       by the Heap module itself, we must use SYSTEM.NEW. *)
    IF m.name = "Heap" THEN
      SYSTEM.NEW(c, SIZE(CmdDesc))
    ELSE
      NEW(c)
    END;
    COPY(name, c.name); c.cmd := cmd; c.next := m.cmds; m.cmds := c
  END REGCMD;

  PROCEDURE REGTYP*(m: Module; typ: LONGINT);
  BEGIN SYSTEM.PUT(typ, m.types); m.types := typ
  END REGTYP;

  PROCEDURE INCREF*(m: Module);
  BEGIN INC(m.refcnt)
  END INCREF;


  PROCEDURE -ExternPlatformOSAllocate           "extern LONGINT Platform_OSAllocate(LONGINT size);";
  PROCEDURE -OSAllocate(size: LONGINT): LONGINT "Platform_OSAllocate(size)";

  PROCEDURE NewChunk(blksz: LONGINT): LONGINT;
    VAR chnk: LONGINT;
  BEGIN
    chnk := OSAllocate(blksz + blkOff);
    IF chnk # 0 THEN
      SYSTEM.PUT(chnk + endOff,             chnk + (blkOff + blksz));
      SYSTEM.PUT(chnk + blkOff,             chnk + (blkOff + sizeOff));
      SYSTEM.PUT(chnk + (blkOff + sizeOff), blksz);
      SYSTEM.PUT(chnk + (blkOff + sntlOff), NoPtrSntl);
      SYSTEM.PUT(chnk + (blkOff + nextOff), bigBlocks);
      bigBlocks := chnk + blkOff;
      INC(heapsize, blksz)
    END ;
    RETURN chnk
  END NewChunk;


  (* FetchAddress fetches a pointer from memory and returns it as a LONGINT. It works
     correctly regardless of the size of an address. Specifically on 32 bit address
     architectures with 64 bit LONGINT, it loads 32 bits and extends it to LONGINT
     rather than loading 64 bits. *)
  PROCEDURE -FetchAddress(pointer: LONGINT): LONGINT "(LONGINT)(uintptr_t)(*((void**)((uintptr_t)pointer)))";

  PROCEDURE ExtendHeap(blksz: LONGINT);
    VAR size, chnk, j, next: LONGINT;
  BEGIN
    IF blksz > 10000*Unit THEN size := blksz
    ELSE size := 10000*Unit  (* additional heuristics *)
    END ;
    chnk := NewChunk(size);
    IF chnk # 0 THEN
      (*sorted insertion*)
      IF chnk < heap THEN
        SYSTEM.PUT(chnk, heap); heap := chnk
      ELSE
        j := heap; next := FetchAddress(j);
        WHILE (next # 0) & (chnk > next) DO
          j := next;
          next := FetchAddress(j)
        END;
        SYSTEM.PUT(chnk, next); SYSTEM.PUT(j, chnk)
      END ;
      IF next = 0 THEN heapend := FetchAddress(chnk+endOff) END
    END
  END ExtendHeap;

  PROCEDURE ^GC*(markStack: BOOLEAN);

  PROCEDURE NEWREC*(tag: LONGINT): SYSTEM.PTR;
    VAR
      i, i0, di, blksz, restsize, t, adr, end, next, prev: LONGINT;
      new:   SYSTEM.PTR;
  BEGIN
    Lock();
    blksz := FetchAddress(tag);

    ASSERT((Unit = 16) OR (Unit = 32));
    ASSERT(SIZE(SYSTEM.PTR) <= SIZE(LONGINT));
    ASSERT(blksz MOD Unit = 0);

    i0 := blksz DIV Unit; i := i0;
    IF i < nofLists THEN adr := freeList[i];
      WHILE adr = 0 DO INC(i); adr := freeList[i] END
    END ;
    IF i < nofLists THEN (* unlink *)
      next := FetchAddress(adr + nextOff);
      freeList[i] := next;
      IF i # i0 THEN (* split *)
        di := i - i0; restsize := di * Unit; end := adr + restsize;
        SYSTEM.PUT(end + sizeOff, blksz);
        SYSTEM.PUT(end + sntlOff, NoPtrSntl);
        SYSTEM.PUT(end,           end + sizeOff);
        SYSTEM.PUT(adr + sizeOff, restsize);
        SYSTEM.PUT(adr + nextOff, freeList[di]);
        freeList[di] := adr;
        INC(adr, restsize)
      END
    ELSE
      adr := bigBlocks; prev := 0;
      LOOP
        IF adr = 0 THEN
          IF firstTry THEN
            GC(TRUE); INC(blksz, Unit);
            IF (heapsize - allocated - blksz) * 4 < heapsize THEN
              (* heap is still almost full; expand to avoid thrashing *)
              ExtendHeap((allocated + blksz) DIV (3*Unit) * (4*Unit) - heapsize)
            END ;
            firstTry := FALSE; new := NEWREC(tag); firstTry := TRUE;
            IF new = NIL THEN
              (* depending on the fragmentation, the heap may not have been extended by
                the anti-thrashing heuristics above *)
              ExtendHeap((allocated + blksz) DIV (3*Unit) * (4*Unit) - heapsize);
              new := NEWREC(tag);  (* will find a free block if heap has been expanded properly *)
            END ;
            Unlock(); RETURN new
          ELSE
            Unlock(); RETURN NIL
          END
        END ;
        t := FetchAddress(adr+sizeOff);
        IF t >= blksz THEN EXIT END ;
        prev := adr; adr := FetchAddress(adr + nextOff)
      END ;
      restsize := t - blksz; end := adr + restsize;
      SYSTEM.PUT(end + sizeOff, blksz);
      SYSTEM.PUT(end + sntlOff, NoPtrSntl);
      SYSTEM.PUT(end,           end + sizeOff);
      IF restsize > nofLists * Unit THEN (*resize*)
        SYSTEM.PUT(adr + sizeOff, restsize)
      ELSE (*unlink*)
        next := FetchAddress(adr + nextOff);
        IF prev = 0 THEN bigBlocks := next
        ELSE SYSTEM.PUT(prev + nextOff, next);
        END ;
        IF restsize > 0 THEN (*move*)
          di := restsize DIV Unit;
          SYSTEM.PUT(adr + sizeOff, restsize);
          SYSTEM.PUT(adr + nextOff, freeList[di]);
          freeList[di] := adr
        END
      END ;
      INC(adr, restsize)
    END ;
    i := adr + 4*SZL; end := adr + blksz;
    WHILE i < end DO  (*deliberately unrolled*)
      SYSTEM.PUT(i,         LongZero);
      SYSTEM.PUT(i + SZL,   LongZero);
      SYSTEM.PUT(i + 2*SZL, LongZero);
      SYSTEM.PUT(i + 3*SZL, LongZero);
      INC(i, 4*SZL)
    END ;
    SYSTEM.PUT(adr + nextOff, LongZero);
    SYSTEM.PUT(adr,           tag);
    SYSTEM.PUT(adr + sizeOff, LongZero);
    SYSTEM.PUT(adr + sntlOff, LongZero);
    INC(allocated, blksz);
    Unlock();
    RETURN SYSTEM.VAL(SYSTEM.PTR, adr + SZL)
  END NEWREC;

  PROCEDURE NEWBLK*(size: LONGINT): SYSTEM.PTR;
     VAR blksz, tag: LONGINT; new: SYSTEM.PTR;
  BEGIN
    Lock();
    blksz := (size + (4*SZL + Unit - 1)) DIV Unit * Unit;  (*size + tag + meta + blksz + sntnl + UnitAlignment*)
    new := NEWREC(SYSTEM.ADR(blksz));
    tag := SYSTEM.VAL(LONGINT, new) + blksz - 3*SZL;
    SYSTEM.PUT(tag - SZL,                      LongZero); (*reserved for meta info*)
    SYSTEM.PUT(tag,                            blksz);
    SYSTEM.PUT(tag + SZL,                      NoPtrSntl);
    SYSTEM.PUT(SYSTEM.VAL(LONGINT, new) - SZL, tag);
    Unlock();
    RETURN new
  END NEWBLK;

  PROCEDURE Mark(q: LONGINT);
    VAR p, tag, fld, n, offset, tagbits: LONGINT;
  BEGIN
    IF q # 0 THEN
      tagbits := FetchAddress(q - SZL);             (* Load the tag for the record at q *)
      IF ~ODD(tagbits) THEN                         (* If it has not already been marked *)
        SYSTEM.PUT(q - SZL, tagbits + 1);           (* Mark it *)
        p := 0;
        tag := tagbits + SZL;                       (* Tag addresses first offset *)
        LOOP
          SYSTEM.GET(tag, offset);                  (* Get next ptr field offset *)
          IF offset < 0 THEN                        (* If sentinel. (Value is -8*(#fields+1) *)
            SYSTEM.PUT(q - SZL, tag + offset + 1);  (* Rotate base ptr into tag *)
            IF p = 0 THEN EXIT END ;
            n := q; q := p;
            tag := FetchAddress(q - SZL); DEC(tag, 1);
            SYSTEM.GET(tag, offset); fld := q + offset;
            p := FetchAddress(fld); SYSTEM.PUT(fld, SYSTEM.VAL(SYSTEM.PTR, n))
          ELSE                                      (* offset references a ptr field *)
            fld := q + offset;                      (* Address the pointer *)
            n := FetchAddress(fld);                 (* Load the pointer *)
            IF n # 0 THEN                           (* If pointer is not NIL *)
              tagbits := FetchAddress(n - SZL);     (* Consider record pointed to by this field *)
              IF ~ODD(tagbits) THEN
                SYSTEM.PUT(n - SZL, tagbits + 1);
                SYSTEM.PUT(q - SZL, tag + 1);
                SYSTEM.PUT(fld, SYSTEM.VAL(SYSTEM.PTR, p));
                p := q; q := n;
                tag := tagbits
              END
            END
          END ;
          INC(tag, SZL)
        END
      END
    END
  END Mark;

  PROCEDURE MarkP(p: SYSTEM.PTR);  (* for compatibility with EnumPtrs in ANSI mode *)
  BEGIN
    Mark(SYSTEM.VAL(LONGINT, p))
  END MarkP;

  PROCEDURE Scan;
    VAR chnk, adr, end, start, tag, i, size, freesize: LONGINT;
  BEGIN bigBlocks := 0; i := 1;
    WHILE i < nofLists DO freeList[i] := 0; INC(i) END ;
    freesize := 0; allocated := 0; chnk := heap;
    WHILE chnk # 0 DO
      adr := chnk + blkOff;
      end := FetchAddress(chnk + endOff);
      WHILE adr < end DO
        tag := FetchAddress(adr);
        IF ODD(tag) THEN  (*marked*)
          IF freesize > 0 THEN
            start := adr - freesize;
            SYSTEM.PUT(start,         start+SZL);
            SYSTEM.PUT(start+sizeOff, freesize);
            SYSTEM.PUT(start+sntlOff, NoPtrSntl);
            i := freesize DIV Unit; freesize := 0;
            IF i < nofLists THEN SYSTEM.PUT(start + nextOff, freeList[i]); freeList[i] := start
            ELSE                 SYSTEM.PUT(start + nextOff, bigBlocks);   bigBlocks   := start
            END
          END ;
          DEC(tag, 1);
          SYSTEM.PUT(adr, tag);
          size := FetchAddress(tag);
          INC(allocated, size);
          INC(adr, size)
        ELSE  (*unmarked*)
          size := FetchAddress(tag);
          INC(freesize, size);
          INC(adr, size)
        END
      END ;
      IF freesize > 0 THEN (*collect last block*)
        start := adr - freesize;
        SYSTEM.PUT(start,         start+SZL);
        SYSTEM.PUT(start+sizeOff, freesize);
        SYSTEM.PUT(start+sntlOff, NoPtrSntl);
        i := freesize DIV Unit; freesize := 0;
        IF i < nofLists THEN SYSTEM.PUT(start + nextOff, freeList[i]); freeList[i] := start
        ELSE                 SYSTEM.PUT(start + nextOff, bigBlocks);   bigBlocks   := start
        END
      END ;
      chnk := FetchAddress(chnk)
    END
  END Scan;

  PROCEDURE Sift (l, r: LONGINT; VAR a: ARRAY OF LONGINT);
    VAR i, j, x: LONGINT;
  BEGIN j := l; x := a[j];
    LOOP i := j; j := 2*j + 1;
      IF (j < r) & (a[j] < a[j+1]) THEN INC(j) END;
      IF (j > r) OR (a[j] <= x) THEN EXIT END;
      a[i] := a[j]
    END;
    a[i] := x
  END Sift;

  PROCEDURE HeapSort (n: LONGINT; VAR a: ARRAY OF LONGINT);
    VAR l, r, x: LONGINT;
  BEGIN l := n DIV 2; r := n - 1;
    WHILE l > 0 DO DEC(l); Sift(l, r, a) END;
    WHILE r > 0 DO x := a[0]; a[0] := a[r]; a[r] := x; DEC(r); Sift(l, r, a) END
  END HeapSort;

  PROCEDURE MarkCandidates(n: LONGINT; VAR cand: ARRAY OF LONGINT);
    VAR chnk, adr, tag, next, lim, lim1, i, ptr, size: LONGINT;
  BEGIN
    chnk := heap; i := 0; lim := cand[n-1];
    WHILE (chnk # 0 ) & (chnk < lim) DO
      adr := chnk + blkOff;
      lim1 := FetchAddress(chnk + endOff);
      IF lim < lim1 THEN lim1 := lim END ;
      WHILE adr < lim1 DO
        tag := FetchAddress(adr);
        IF ODD(tag) THEN (*already marked*)
          size := FetchAddress(tag-1); INC(adr, size)
        ELSE
          size := FetchAddress(tag);
          ptr := adr + SZL;
          WHILE cand[i] < ptr DO INC(i) END ;
          IF i = n THEN RETURN END ;
          next := adr + size;
          IF cand[i] < next THEN Mark(ptr) END ;
          adr := next
        END
      END ;
      chnk := FetchAddress(chnk)
    END
  END MarkCandidates;

  PROCEDURE CheckFin;
    VAR n: FinNode; tag: LONGINT;
  BEGIN
    n := fin;
    WHILE n # NIL DO
      tag := FetchAddress(n.obj - SZL);
      IF ~ODD(tag) THEN n.marked := FALSE; Mark(n.obj)
      ELSE n.marked := TRUE
      END ;
      n := n.next
    END
  END CheckFin;

  PROCEDURE Finalize;
    VAR n, prev: FinNode;
  BEGIN n := fin; prev := NIL;
    WHILE n # NIL DO
      IF ~n.marked THEN
        IF n = fin THEN fin := fin.next ELSE prev.next := n.next END ;
        n.finalize(SYSTEM.VAL(SYSTEM.PTR, n.obj));
        (* new nodes may have been pushed in n.finalize, therefore: *)
        IF prev = NIL THEN n := fin ELSE n := n.next END
      ELSE
        prev := n; n := n.next
      END
    END
  END Finalize;

  PROCEDURE FINALL*;
    VAR n: FinNode;
  BEGIN
    WHILE fin # NIL DO
      n := fin; fin := fin.next;
      n.finalize(SYSTEM.VAL(SYSTEM.PTR, n.obj))
    END
  END FINALL;

  PROCEDURE -ExternMainStackFrame              "extern LONGINT Platform_MainStackFrame;";
  PROCEDURE -PlatformMainStackFrame(): LONGINT "Platform_MainStackFrame";

  PROCEDURE MarkStack(n: LONGINT; VAR cand: ARRAY OF LONGINT);
    VAR
      frame: SYSTEM.PTR;
      inc, nofcand: LONGINT;
      sp, p, stack0: LONGINT;
      align: RECORD ch: CHAR; p: SYSTEM.PTR END ;
  BEGIN
    IF n > 0 THEN MarkStack(n-1, cand);  (* flush register windows by means of recursive calls *)
      IF n > 100 THEN RETURN END   (* prevent tail recursion optimization *)
    END ;
    IF n = 0 THEN
      nofcand := 0; sp := SYSTEM.ADR(frame);
      stack0 := PlatformMainStackFrame();
      (* check for minimum alignment of pointers *)
      inc := SYSTEM.ADR(align.p) - SYSTEM.ADR(align);
      IF sp > stack0 THEN inc := -inc END ;
      WHILE sp # stack0 DO
        SYSTEM.GET(sp, p);
        IF (p > heap) & (p < heapend) THEN
          IF nofcand = LEN(cand) THEN HeapSort(nofcand, cand); MarkCandidates(nofcand, cand); nofcand := 0 END ;
          cand[nofcand] := p; INC(nofcand)
        END ;
        INC(sp, inc)
      END ;
      IF nofcand > 0 THEN HeapSort(nofcand, cand); MarkCandidates(nofcand, cand) END
    END
  END MarkStack;

  PROCEDURE GC*(markStack: BOOLEAN);
    VAR
      m: Module;
      i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15, i16, i17, i18, i19, i20, i21, i22, i23: LONGINT;
      cand: ARRAY 10000 OF LONGINT;
  BEGIN
    IF (lockdepth = 0) OR (lockdepth = 1) & ~markStack THEN
      Lock();
      m := SYSTEM.VAL(Module, modules);
      WHILE m # NIL DO
        IF m.enumPtrs # NIL THEN m.enumPtrs(MarkP) END ;
        m := m^.next
      END ;
      IF markStack THEN
        (* generate register pressure to force callee saved registers to memory;
          may be simplified by inlining OS calls or processor specific instructions
        *)
        i0 := -100; i1 := -101; i2 := -102; i3 := -103; i4 := -104; i5 := -105; i6 := -106; i7 := -107;
        i8 := 1; i9 := 2; i10 := 3; i11 := 4; i12 := 5; i13 := 6; i14 := 7; i15 := 8;
        i16 := 9; i17 := 10; i18 := 11; i19 := 12; i20 := 13; i21 := 14; i22 := 15; i23 := 16;
        LOOP INC(i0, 1); INC(i1, 2); INC(i2, 3); INC(i3, 4); INC(i4, 5); INC(i5, 6); INC(i6, 7); INC(i7, 8);
          INC(i8, 9); INC(i9, 10); INC(i10, 11); INC(i11, 12); INC(i12, 13); INC(i13, 14); INC(i14, 15); INC(i15, 16);
          INC(i16, 17); INC(i17, 18); INC(i18, 19); INC(i19, 20); INC(i20, 21); INC(i21, 22); INC(i22, 23); INC(i23, 24);
          IF (i0 = -99) & (i15 = 24) THEN MarkStack(32, cand); EXIT END
        END ;
        IF i0 + i1 + i2 + i3 + i4 + i5 + i6 + i7 + i8 + i9 + i10 + i11 + i12 + i13 + i14 + i15
          + i16 + i17 + i18 + i19 + i20 + i21 + i22 + i23 > 10000 THEN RETURN    (* use all variables *)
        END ;
      END;
      CheckFin;
      Scan;
      Finalize;
      Unlock()
    END
  END GC;

  PROCEDURE RegisterFinalizer*(obj: SYSTEM.PTR; finalize: Finalizer);
    VAR f: FinNode;
  BEGIN NEW(f);
    f.obj := SYSTEM.VAL(LONGINT, obj); f.finalize := finalize; f.marked := TRUE;
    f.next := fin; fin := f;
  END RegisterFinalizer;


PROCEDURE -ExternHeapInit "extern void *Heap__init();";
PROCEDURE -HeapModuleInit 'Heap__init()';

  PROCEDURE InitHeap*;
  (* InitHeap is called by Platform.init before any module bodies have been
     initialised, to enable NEW, SYSTEM.NEW *)
  BEGIN
    heap    := NewChunk(heapSize0);
    heapend := FetchAddress(heap + endOff);
    SYSTEM.PUT(heap, LongZero);
    allocated := 0; firstTry := TRUE; freeList[nofLists] := 1; lockdepth := 0;
    FileCount := 0; modules := NIL; heapsize := 0; bigBlocks := 0; fin := NIL;
    interrupted := FALSE;

    HeapModuleInit;
  END InitHeap;

END Heap.
