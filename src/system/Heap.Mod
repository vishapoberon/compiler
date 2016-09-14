MODULE Heap;

  IMPORT S := SYSTEM;  (* Cannot import anything else as heap initialization must complete
                          before any other modules are initialized. *)

  CONST
    ModNameLen = 20;
    CmdNameLen = 24;
    SZA        = SIZE(S.ADDRESS);  (* Size of address *)
    Unit       = 4*SZA;            (* smallest possible heap block *)
    nofLists   = 9;                (* number of free_lists *)
    heapSize0  = 8000*Unit;        (* startup heap size *)

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
    blkOff      = S.VAL(S.ADDRESS, 3*SZA);  (* first block in a chunk *)

  (* heap blocks *)
    tagOff      = S.VAL(S.ADDRESS, 0);      (* block starts with tag *)
    sizeOff     = S.VAL(S.ADDRESS, SZA);    (* block size in free block relative to block start *)
    sntlOff     = S.VAL(S.ADDRESS, 2*SZA);  (* pointer offset table sentinel in free block relative to block start *)
    nextOff     = S.VAL(S.ADDRESS, 3*SZA);  (* next pointer in free block relative to block start *)
    NoPtrSntl   = S.VAL(S.ADDRESS, -SZA);
    AddressZero = S.VAL(S.ADDRESS, 0);

  TYPE
    ModuleName = ARRAY ModNameLen OF CHAR;
    CmdName    = ARRAY CmdNameLen OF CHAR;

    Module = POINTER TO ModuleDesc;
    Cmd    = POINTER TO CmdDesc;

    EnumProc   = PROCEDURE(P: PROCEDURE(p: S.PTR));

    ModuleDesc = RECORD
      next:     Module;
      name:     ModuleName;
      refcnt:   LONGINT;
      cmds:     Cmd;
      types:    S.ADDRESS;
      enumPtrs: EnumProc;
      reserved1, reserved2: LONGINT
    END ;

    Command = PROCEDURE;

    CmdDesc = RECORD
      next: Cmd;
      name: CmdName;
      cmd:  Command
    END ;

    Finalizer = PROCEDURE(obj: S.PTR);

    FinNode   = POINTER TO FinDesc;
    FinDesc   = RECORD
      next:     FinNode;
      obj:      S.ADDRESS;  (* weak pointer *)
      marked:   BOOLEAN;
      finalize: Finalizer;
    END ;

  VAR
    (* the list of loaded (=initialization started) modules *)
    modules*: S.PTR;

    freeList:   ARRAY nofLists + 1 OF S.ADDRESS;  (* dummy, 16, 32, 48, 64, 80, 96, 112, 128, sentinel *)
    bigBlocks:  S.ADDRESS;
    allocated*: S.ADDRESS;
    firstTry:   BOOLEAN;

    (* extensible heap *)
    heap:      S.ADDRESS;  (* the sorted list of heap chunks *)
    heapend:   S.ADDRESS;  (* max possible pointer value (used for stack collection) *)
    heapsize*: S.ADDRESS;  (* the sum of all heap chunk sizes *)

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
    COPY(name, m.name); m.refcnt := 0; m.enumPtrs := enumPtrs; m.next := S.VAL(Module, modules);
    modules := m;
    RETURN m
  END REGMOD;

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

  PROCEDURE INCREF*(m: Module);
  BEGIN INC(m.refcnt)
  END INCREF;


  PROCEDURE -ExternPlatformOSAllocate "extern address Platform_OSAllocate(address size);";
  PROCEDURE -OSAllocate(size: S.ADDRESS): S.ADDRESS "Platform_OSAllocate(size)";

  PROCEDURE NewChunk(blksz: S.ADDRESS): S.ADDRESS;
    VAR chnk: S.ADDRESS;
  BEGIN
    chnk := OSAllocate(blksz + blkOff);
    IF chnk # 0 THEN
      S.PUT(chnk + endOff,             chnk + (blkOff + blksz));
      S.PUT(chnk + blkOff,             chnk + (blkOff + sizeOff));
      S.PUT(chnk + (blkOff + sizeOff), blksz);
      S.PUT(chnk + (blkOff + sntlOff), NoPtrSntl);
      S.PUT(chnk + (blkOff + nextOff), bigBlocks);
      bigBlocks := chnk + blkOff;
      INC(heapsize, blksz)
    END ;
    RETURN chnk
  END NewChunk;

  PROCEDURE ExtendHeap(blksz: S.ADDRESS);
    VAR size, chnk, j, next: S.ADDRESS;
  BEGIN
    IF blksz > 10000*Unit THEN size := blksz
    ELSE size := 10000*Unit  (* additional heuristics *)
    END ;
    chnk := NewChunk(size);
    IF chnk # 0 THEN
      (*sorted insertion*)
      IF chnk < heap THEN
        S.PUT(chnk, heap); heap := chnk
      ELSE
        j := heap; S.GET(j, next);
        WHILE (next # 0) & (chnk > next) DO
          j := next;
          S.GET(j, next)
        END;
        S.PUT(chnk, next); S.PUT(j, chnk)
      END ;
      IF next = 0 THEN S.GET(chnk+endOff, heapend) END
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

    ASSERT((Unit = 16) OR (Unit = 32));
    ASSERT(SIZE(S.PTR) = SIZE(S.ADDRESS));
    ASSERT(blksz MOD Unit = 0);

    i0 := blksz DIV Unit; i := i0;
    IF i < nofLists THEN adr := freeList[i];
      WHILE adr = 0 DO INC(i); adr := freeList[i] END
    END ;
    IF i < nofLists THEN (* unlink *)
      S.GET(adr + nextOff, next);
      freeList[i] := next;
      IF i # i0 THEN (* split *)
        di := i - i0; restsize := di * Unit; end := adr + restsize;
        S.PUT(end + sizeOff, blksz);
        S.PUT(end + sntlOff, NoPtrSntl);
        S.PUT(end,           end + sizeOff);
        S.PUT(adr + sizeOff, restsize);
        S.PUT(adr + nextOff, freeList[di]);
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
        S.GET(adr+sizeOff, t);
        IF t >= blksz THEN EXIT END ;
        prev := adr; S.GET(adr + nextOff, adr)
      END ;
      restsize := t - blksz; end := adr + restsize;
      S.PUT(end + sizeOff, blksz);
      S.PUT(end + sntlOff, NoPtrSntl);
      S.PUT(end,           end + sizeOff);
      IF restsize > nofLists * Unit THEN (*resize*)
        S.PUT(adr + sizeOff, restsize)
      ELSE (*unlink*)
        S.GET(adr + nextOff, next);
        IF prev = 0 THEN bigBlocks := next
        ELSE S.PUT(prev + nextOff, next);
        END ;
        IF restsize > 0 THEN (*move*)
          di := restsize DIV Unit;
          S.PUT(adr + sizeOff, restsize);
          S.PUT(adr + nextOff, freeList[di]);
          freeList[di] := adr
        END
      END ;
      INC(adr, restsize)
    END ;
    i := adr + 4*SZA; end := adr + blksz;
    WHILE i < end DO  (*deliberately unrolled*)
      S.PUT(i,         AddressZero);
      S.PUT(i + SZA,   AddressZero);
      S.PUT(i + 2*SZA, AddressZero);
      S.PUT(i + 3*SZA, AddressZero);
      INC(i, 4*SZA)
    END ;
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
      S.GET(q - SZA, tagbits);             (* Load the tag for the record at q *)
      IF ~ODD(tagbits) THEN                         (* If it has not already been marked *)
        S.PUT(q - SZA, tagbits + 1);           (* Mark it *)
        p := 0;
        tag := tagbits + SZA;                       (* Tag addresses first offset *)
        LOOP
          S.GET(tag, offset);                  (* Get next ptr field offset *)
          IF offset < 0 THEN                        (* Sentinel reached: Value is -8*(#fields+1) *)
            S.PUT(q - SZA, tag + offset + 1);  (* Rotate base ptr into tag *)
            IF p = 0 THEN EXIT END ;
            n := q; q := p;
            S.GET(q - SZA, tag); DEC(tag, 1);
            S.GET(tag, offset); fld := q + offset;
            S.GET(fld, p); S.PUT(fld, S.VAL(S.PTR, n))
          ELSE                                      (* offset references a ptr field *)
            fld := q + offset;                      (* S.ADDRESS the pointer *)
            S.GET(fld, n);                 (* Load the pointer *)
            IF n # 0 THEN                           (* If pointer is not NIL *)
              S.GET(n - SZA, tagbits);     (* Consider record pointed to by this field *)
              IF ~ODD(tagbits) THEN
                S.PUT(n - SZA, tagbits + 1);
                S.PUT(q - SZA, tag + 1);
                S.PUT(fld, S.VAL(S.PTR, p));
                p := q; q := n;
                tag := tagbits
              END
            END
          END ;
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
    WHILE i < nofLists DO freeList[i] := 0; INC(i) END ;
    freesize := 0; allocated := 0; chnk := heap;
    WHILE chnk # 0 DO
      adr := chnk + blkOff;
      S.GET(chnk + endOff, end);
      WHILE adr < end DO
        S.GET(adr, tag);
        IF ODD(tag) THEN  (*marked*)
          IF freesize > 0 THEN
            start := adr - freesize;
            S.PUT(start,         start+SZA);
            S.PUT(start+sizeOff, freesize);
            S.PUT(start+sntlOff, NoPtrSntl);
            i := freesize DIV Unit; freesize := 0;
            IF i < nofLists THEN S.PUT(start + nextOff, freeList[i]); freeList[i] := start
            ELSE                 S.PUT(start + nextOff, bigBlocks);   bigBlocks   := start
            END
          END ;
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
      END ;
      IF freesize > 0 THEN (*collect last block*)
        start := adr - freesize;
        S.PUT(start,         start+SZA);
        S.PUT(start+sizeOff, freesize);
        S.PUT(start+sntlOff, NoPtrSntl);
        i := freesize DIV Unit; freesize := 0;
        IF i < nofLists THEN S.PUT(start + nextOff, freeList[i]); freeList[i] := start
        ELSE                 S.PUT(start + nextOff, bigBlocks);   bigBlocks   := start
        END
      END ;
      S.GET(chnk, chnk)
    END
  END Scan;

  PROCEDURE Sift (l, r: S.ADDRESS; VAR a: ARRAY OF S.ADDRESS);
    VAR i, j, x: S.ADDRESS;
  BEGIN j := l; x := a[j];
    LOOP i := j; j := 2*j + 1;
      IF (j < r) & (a[j] < a[j+1]) THEN INC(j) END;
      IF (j > r) OR (a[j] <= x) THEN EXIT END;
      a[i] := a[j]
    END;
    a[i] := x
  END Sift;

  PROCEDURE HeapSort (n: S.ADDRESS; VAR a: ARRAY OF S.ADDRESS);
    VAR l, r, x: S.ADDRESS;
  BEGIN l := n DIV 2; r := n - 1;
    WHILE l > 0 DO DEC(l); Sift(l, r, a) END;
    WHILE r > 0 DO x := a[0]; a[0] := a[r]; a[r] := x; DEC(r); Sift(l, r, a) END
  END HeapSort;

  PROCEDURE MarkCandidates(n: S.ADDRESS; VAR cand: ARRAY OF S.ADDRESS);
    VAR chnk, adr, tag, next, lim, lim1, i, ptr, size: S.ADDRESS;
  BEGIN
    chnk := heap; i := 0; lim := cand[n-1];
    WHILE (chnk # 0 ) & (chnk < lim) DO
      adr := chnk + blkOff;
      S.GET(chnk + endOff, lim1);
      IF lim < lim1 THEN lim1 := lim END ;
      WHILE adr < lim1 DO
        S.GET(adr, tag);
        IF ODD(tag) THEN (*already marked*)
          S.GET(tag-1, size); INC(adr, size)
        ELSE
          S.GET(tag, size);
          ptr := adr + SZA;
          WHILE cand[i] < ptr DO INC(i) END ;
          IF i = n THEN RETURN END ;
          next := adr + size;
          IF cand[i] < next THEN Mark(ptr) END ;
          adr := next
        END
      END ;
      S.GET(chnk, chnk)
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
        n.finalize(S.VAL(S.PTR, n.obj));
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
      n.finalize(S.VAL(S.PTR, n.obj))
    END
  END FINALL;

  PROCEDURE -ExternMainStackFrame                     "extern address Platform_MainStackFrame;";
  PROCEDURE -PlatformMainStackFrame(): S.ADDRESS "Platform_MainStackFrame";

  PROCEDURE MarkStack(n: S.ADDRESS; VAR cand: ARRAY OF S.ADDRESS);
    VAR
      frame: S.PTR;
      inc, nofcand: S.ADDRESS;
      sp, p, stack0: S.ADDRESS;
      align: RECORD ch: CHAR; p: S.PTR END ;
  BEGIN
    IF n > 0 THEN MarkStack(n-1, cand);  (* flush register windows by means of recursive calls *)
      IF n > 100 THEN RETURN END   (* prevent tail recursion optimization *)
    END ;
    IF n = 0 THEN
      nofcand := 0; sp := S.ADR(frame);
      stack0 := PlatformMainStackFrame();
      (* check for minimum alignment of pointers *)
      inc := S.ADR(align.p) - S.ADR(align);
      IF sp > stack0 THEN inc := -inc END ;
      WHILE sp # stack0 DO
        S.GET(sp, p);
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
      i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15, i16, i17, i18, i19, i20, i21, i22, i23: S.ADDRESS;
      cand: ARRAY 10000 OF S.ADDRESS;
  BEGIN
    IF (lockdepth = 0) OR (lockdepth = 1) & ~markStack THEN
      Lock();
      m := S.VAL(Module, modules);
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
    heap    := NewChunk(heapSize0);
    S.GET(heap + endOff, heapend);
    S.PUT(heap, AddressZero);
    allocated := 0; firstTry := TRUE; freeList[nofLists] := 1; lockdepth := 0;
    FileCount := 0; modules := NIL; heapsize := 0; bigBlocks := 0; fin := NIL;
    interrupted := FALSE;

    HeapModuleInit;
  END InitHeap;

END Heap.
