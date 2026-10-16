MODULE Clist;   (* :file: Clist.ob  --  Character lists *)
(* VOC adaptation, 2026-10-16: retain upstream's 32-bit integer contract. *)
IMPORT ssqTypes, Int, Dot;


TYPE
        INTEGER = ssqTypes.Integer;
        T* = POINTER TO TDesc;
        TDesc = RECORD
                   c:    INTEGER;
                   next: T;
                END;


(* ========================================================================= *)
(* :chapter: STANDARD PROCEDURES TO BE INLINED IN OTHER MODULES *)

PROCEDURE lf;                                   BEGIN Dot.Lf                    END lf;
PROCEDURE lff;                                  BEGIN Dot.Lff                   END lff;
PROCEDURE spc;                                  BEGIN Dot.Spc                   END spc;
PROCEDURE ddx;                                  BEGIN Dot.DDX                   END ddx;

PROCEDURE tab     (w: INTEGER);                 BEGIN Dot.Tab (w)               END tab;

PROCEDURE cprint  (c: CHAR);                    BEGIN Dot.Chr  (c)              END cprint;
PROCEDURE iprint  (n,w: INTEGER);               BEGIN Dot.Int  (n,w)            END iprint;
PROCEDURE bprint  (b: BOOLEAN);                 BEGIN Dot.Bool (b, 0)           END bprint;

PROCEDURE print   (mess: ARRAY OF CHAR);        BEGIN Dot.Mess    (mess)        END print;
PROCEDURE section (mess: ARRAY OF CHAR);        BEGIN Dot.Section (mess)        END section;


(* ========================================================================= *)
(* :chapter: LIB *)
PROCEDURE Cx (c: INTEGER; next: T): T;
VAR cx: T;
BEGIN
   NEW (cx);
   cx.c    := c;
   cx.next := next;
   RETURN cx;
END Cx;

PROCEDURE Conc (VAR cx: T; c: INTEGER);
VAR ncn: T;
BEGIN
   ncn     := Cx (c, NIL);
   cx.next := ncn;
   cx      := ncn;
END Conc;

PROCEDURE LastOf (cl: T): T;
VAR cn: T;
BEGIN
   cn:= cl;
   WHILE cn.next # NIL DO cn:= cn.next END;
   RETURN cn;
END LastOf;


(* ========================================================================= *)
(* :chapter: Clist *)
PROCEDURE AsAOC* (cl: T; VAR a: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
   i := 0;
   WHILE cl # NIL DO
      a[i] := CHR (cl.c);
      cl   := cl.next;
      INC (i);
   END;
   a[i] := 0X;
END AsAOC;

PROCEDURE Length* (cl: T): INTEGER;
VAR i: INTEGER;
BEGIN
   i := 0;
   WHILE (cl # NIL) DO
      cl := cl.next;
      INC (i);
   END;
   RETURN i
END Length;

PROCEDURE New* (VAR cl: T);
BEGIN
   NEW (cl);
   cl := NIL;
END New;

PROCEDURE Print* (cl: T);
BEGIN
   WHILE cl # NIL DO
      cprint (CHR(cl.c));
      cl := cl.next;
   END
END Print;

(* ========================================================================= *)
(* :chapter: APPEND *)
PROCEDURE AppendAOC*  (VAR cl: T; a: ARRAY OF CHAR);
VAR cn, ncn: T;
   i: INTEGER;
BEGIN
   i := 0;
   IF a[0] = 0X THEN
      (* done *)
   ELSE
      IF cl = NIL THEN
         cn := Cx (ORD (a[0]), NIL);
         INC (i);
         cl := cn;
      ELSE cn := LastOf (cl);
      END;
      WHILE a[i] # 0X DO
         Conc (cn, ORD(a[i]));
         INC (i);
      END;
   END
END AppendAOC;

PROCEDURE AppendChar* (VAR cl: T; c: CHAR);
VAR cn,ncn: T;
BEGIN
   IF cl = NIL THEN
      cl := Cx (ORD (c), NIL);
   ELSE
      cn := LastOf (cl);
      Conc (cn, ORD(c));
   END;
END AppendChar;

PROCEDURE AppendClist* (VAR cl: T; ca: T);
VAR cn,ncn: T;
BEGIN
   IF cl = NIL THEN cl := ca
   ELSE
      cn := LastOf (cl);
      WHILE ca # NIL DO Conc (cn, ca.c); ca := ca.next END
   END
END AppendClist;

PROCEDURE AppendInt* (VAR cl: T; n, width: INTEGER);
VAR a: ARRAY 32 OF CHAR;
BEGIN
   Int.Show (a, n, width);
   AppendAOC (cl, a);
END AppendInt;

(* ========================================================================= *)
(* :chapter: TESTS *)
PROCEDURE HasChar* (cl: T; c: CHAR): BOOLEAN;
BEGIN
   WHILE (cl # NIL) & (cl.c # ORD (c)) DO cl := cl.next END;
   RETURN cl # NIL
END HasChar;


(* ========================================================================= *)
(* :chapter: MAIN *)
BEGIN
END Clist. :file:  sts-q 2024-Aug
