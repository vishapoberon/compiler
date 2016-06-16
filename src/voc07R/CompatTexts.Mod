MODULE CompatTexts; (*JG 21.11.90 / NW 11.7.90 / 24.12.95 / 22.11.10 / 26.3.2014*)
  IMPORT Files := CompatFiles, Fonts;

  TYPE INTEGER = LONGINT; (* voc adaptation by noch *)
       BYTE = CHAR;

  CONST (*scanner symbol classes*)
    Inval* = 0;         (*invalid symbol*)
    Name* = 1;          (*name s (length len)*)
    String* = 2;        (*literal string s (length len)*)
    Int* = 3;           (*integer i (decimal or hexadecimal)*)
    Real* = 4;          (*real number x*)
    Char* = 6;          (*special character c*)

    (* TextBlock = TextTag "1" offset run {run} "0" len {AsciiCode}.
      run = fnt [name] col voff len. *)

    TAB = 9X; CR = 0DX; maxD = 9;
    TextTag = 0F1X;
    replace* = 0; insert* = 1; delete* = 2; unmark* = 3;  (*op-codes*)

  TYPE Piece = POINTER TO PieceDesc;
    PieceDesc = RECORD
      f: Files.File;
      off, len: LONGINT;
      fnt: Fonts.Font;
      col, voff: INTEGER;
      prev, next: Piece
    END;

    Text* = POINTER TO TextDesc;
    Notifier* = PROCEDURE (T: Text; op: INTEGER; beg, end: LONGINT);
    TextDesc* = RECORD
      len*: LONGINT;
      changed*: BOOLEAN;
      notify*: Notifier;
      trailer: Piece;
      pce: Piece;  (*cache*)
      org: LONGINT; (*cache*)
    END;

    Reader* = RECORD
      eot*: BOOLEAN;
      fnt*: Fonts.Font;
      col*, voff*: INTEGER;
      ref: Piece;
      org: LONGINT;
      off: LONGINT;
      rider: Files.Rider
    END;

    Scanner* = RECORD (Reader)
      nextCh*: CHAR;
      line*, class*: INTEGER;
      i*: LONGINT;
      x*: REAL;
      y*: LONGREAL;
      c*: CHAR;
      len*: INTEGER;
      s*: ARRAY 32 OF CHAR
    END;

    Buffer* = POINTER TO BufDesc;
    BufDesc* = RECORD
      len*: LONGINT;
      header, last: Piece
    END;

    Writer* = RECORD
      buf*: Buffer;
      fnt*: Fonts.Font;
      col*, voff*: INTEGER;
      rider: Files.Rider
    END;

  VAR TrailerFile: Files.File;

  (* voc adaptation by noch *)
  PROCEDURE FLOOR(x : REAL): INTEGER;
  BEGIN
     RETURN ENTIER(x)
  END FLOOR;

   PROCEDURE LSL (x, n : INTEGER): INTEGER;
   BEGIN
     RETURN ASH(x, n);
   END LSL;

   PROCEDURE ASR (x, n : INTEGER): INTEGER;
   BEGIN
     RETURN ASH(x, n);
   END ASR;


  (* -------------------- Filing ------------------------*)

  PROCEDURE Trailer(): Piece;
    VAR Q: Piece;
  BEGIN NEW(Q);
    Q.f := TrailerFile; Q.off := -1; Q.len := 1; Q.fnt := NIL; Q.col := 0; Q.voff := 0; RETURN Q
  END Trailer;

  PROCEDURE Load* (VAR R: Files.Rider; T: Text);
    VAR Q, q, p: Piece;
      off: LONGINT;
      N, fno: INTEGER; bt: BYTE;
      f: Files.File;
      FName: ARRAY 32 OF CHAR;
      Dict: ARRAY 32 OF Fonts.Font;
  BEGIN f := Files.Base(R); N := 1; Q := Trailer(); p := Q;
    Files.ReadInt(R, off); Files.ReadByte(R, bt);
    (*fno := bt;*)
    fno := ORD(bt); (* voc adaptation by noch *)
    WHILE fno # 0 DO
      IF fno = N THEN
        Files.ReadString(R, FName);
        Dict[N] := Fonts.This(FName); INC(N)
      END;
      NEW(q); q.fnt := Dict[fno];
      Files.ReadByte(R, bt);
      (*q.col := bt;*)
      q.col := ORD(bt); (* voc adaptation by noch *)
      Files.ReadByte(R, bt);
      (*q.voff := ASR(LSL(bt, -24), 24);*)
      q.voff := ASR(LSL(ORD(bt), -24), 24); (* voc adaptation by noch *)
      Files.ReadInt(R, q.len);
      Files.ReadByte(R, bt);
      (*fno := bt;*)
      fno := ORD(bt); (* voc adaptation by noch *)
      q.f := f; q.off := off; off := off + q.len;
      p.next := q; q.prev := p; p := q
    END;
    p.next := Q; Q.prev := p;
    T.trailer := Q; Files.ReadInt(R, T.len); (*Files.Set(R, f, Files.Pos(R) + T.len)*)
  END Load;

  PROCEDURE Open* (T: Text; name: ARRAY OF CHAR);
    VAR f: Files.File; R: Files.Rider; Q, q: Piece;
      tag: CHAR; len: LONGINT;
  BEGIN f := Files.Old(name);
    IF f # NIL THEN
      Files.Set(R, f, 0); Files.Read(R, tag);
      IF tag = TextTag THEN Load(R, T)
      ELSE (*Ascii file*)
        len := Files.Length(f); Q := Trailer();
        NEW(q); q.fnt := Fonts.Default; q.col := 1; q.voff := 0; q.f := f; q.off := 0; q.len := len;
        Q.next := q; q.prev := Q; q.next := Q; Q.prev := q; T.trailer := Q; T.len := len
      END
    ELSE (*create new text*)
      Q := Trailer(); Q.next := Q; Q.prev := Q; T.trailer := Q; T.len := 0
    END ;
    T.changed := FALSE; T.org := -1; T.pce := T.trailer (*init cache*)
  END Open;

  PROCEDURE Store* (VAR W: Files.Rider; T: Text);
    VAR p, q: Piece;
      R: Files.Rider;
      off, rlen, pos: LONGINT;
      N, n: INTEGER;
      ch: CHAR;
      Dict: ARRAY 32, 32 OF CHAR;
  BEGIN pos := Files.Pos(W); Files.WriteInt(W, 0); (*place holder*)
    N := 1; p := T.trailer.next;
    WHILE p # T.trailer DO
      rlen := p.len; q := p.next;
      WHILE (q # T.trailer) & (q.fnt = p.fnt) & (q.col = p.col) & (q.voff = p.voff) DO
        rlen := rlen + q.len; q := q.next
      END;
      (*Dict[N] := p.fnt.name;*)
      IF p.fnt # NIL THEN COPY(p.fnt.name, Dict[N]) END; (* voc adaptation by noch *)
      n := 1;
      IF p.fnt # NIL THEN (* voc adaptation by noch *)
         WHILE Dict[n] # p.fnt.name DO INC(n) END;
      END;
      (*Files.WriteByte(W, n);*)
      Files.WriteByte(W, SHORT(SHORT(n))); (* voc adaptation by noch *)
      IF p.fnt # NIL THEN (* voc adaptation by noch *)
         IF n = N THEN Files.WriteString(W, p.fnt.name); INC(N) END;
      END;
      (*Files.WriteByte(W, p.col);*)
      Files.WriteByte(W, SHORT(SHORT(p.col))); (* voc adaptation by noch *)
      (*Files.WriteByte(W, p.voff);*)
      Files.WriteByte(W, SHORT(SHORT(p.voff))); (* voc adaptation by noch *)
      Files.WriteInt(W, rlen);
      p := q
    END;
    Files.WriteByte(W, 0); Files.WriteInt(W, T.len);
    off := Files.Pos(W); p := T.trailer.next;
    WHILE p # T.trailer DO
      rlen := p.len; Files.Set(R, p.f, p.off);
      WHILE rlen > 0 DO Files.Read(R, ch); Files.Write(W, ch); DEC(rlen) END ;
      p := p.next
    END ;
    Files.Set(W, Files.Base(W), pos); Files.WriteInt(W, off); (*fixup*)
    T.changed := FALSE;
    IF T.notify # NIL THEN T.notify(T, unmark, 0, 0) END
  END Store;

  PROCEDURE Close*(T: Text; name: ARRAY OF CHAR);
    VAR f: Files.File; w: Files.Rider;
  BEGIN f := Files.New(name); Files.Set(w, f, 0);
    Files.Write(w, TextTag); Store(w, T); Files.Register(f)
  END Close;

  (* -------------------- Editing ----------------------- *)

  PROCEDURE OpenBuf* (B: Buffer);
  BEGIN NEW(B.header); (*null piece*)
    B.last := B.header; B.len := 0
  END OpenBuf;

  PROCEDURE FindPiece (T: Text; pos: LONGINT; VAR org: LONGINT; VAR pce: Piece);
    VAR p: Piece; porg: LONGINT;
  BEGIN p := T.pce; porg := T.org;
    IF pos >= porg THEN
      WHILE pos >= porg + p.len DO INC(porg, p.len); p := p.next END
    ELSE p := p.prev; DEC(porg, p.len);
      WHILE pos < porg DO p := p.prev; DEC(porg, p.len) END
    END ;
    T.pce := p; T.org := porg;  (*update cache*)
    pce := p; org := porg
  END FindPiece;

  PROCEDURE SplitPiece (p: Piece; off: LONGINT; VAR pr: Piece);
    VAR q: Piece;
  BEGIN
    IF off > 0 THEN NEW(q);
      q.fnt := p.fnt; q.col := p.col; q.voff := p.voff;
      q.len := p.len - off;
      q.f := p.f; q.off := p.off + off;
      p.len := off;
      q.next := p.next; p.next := q;
      q.prev := p; q.next.prev := q;
      pr := q
    ELSE pr := p
    END
  END SplitPiece;

  PROCEDURE Save* (T: Text; beg, end: LONGINT; B: Buffer);
    VAR p, q, qb, qe: Piece; org: LONGINT;
  BEGIN
    IF end > T.len THEN end := T.len END;
    FindPiece(T, beg, org, p);
    NEW(qb); qb^ := p^;
    qb.len := qb.len - (beg - org);
    qb.off := qb.off + (beg - org);
    qe := qb;
    WHILE end > org + p.len DO
      org := org + p.len; p := p.next;
      NEW(q); q^ := p^; qe.next := q; q.prev := qe; qe := q
    END;
    qe.next := NIL; qe.len := qe.len - (org + p.len - end);
    B.last.next := qb; qb.prev := B.last; B.last := qe;
    B.len := B.len + (end - beg)
  END Save;

  PROCEDURE Copy* (SB, DB: Buffer);
    VAR Q, q, p: Piece;
  BEGIN p := SB.header; Q := DB.last;
    WHILE p # SB.last DO p := p.next;
      NEW(q); q^ := p^; Q.next := q; q.prev := Q; Q := q
    END;
    DB.last := Q; DB.len := DB.len + SB.len
  END Copy;

  PROCEDURE Insert* (T: Text; pos: LONGINT; B: Buffer);
    VAR pl, pr, p, qb, qe: Piece; org, end: LONGINT;
  BEGIN
    FindPiece(T, pos, org, p); SplitPiece(p, pos - org, pr);
    IF T.org >= org THEN T.org := org - p.prev.len; T.pce := p.prev END ;
    pl := pr.prev; qb := B.header.next;
    IF (qb # NIL) & (qb.f = pl.f) & (qb.off = pl.off + pl.len)
        & (qb.fnt = pl.fnt) & (qb.col = pl.col) & (qb.voff = pl.voff) THEN
      pl.len := pl.len + qb.len; qb := qb.next
    END;
    IF qb # NIL THEN qe := B.last;
      qb.prev := pl; pl.next := qb; qe.next := pr; pr.prev := qe
    END;
    T.len := T.len + B.len; end := pos + B.len;
    B.last := B.header; B.last.next := NIL; B.len := 0;
    T.changed := TRUE;
    (*T.notify(T, insert, pos, end)*)
    IF T.notify # NIL THEN
       T.notify(T, insert, pos, end)
    END(* voc adaptation by noch *)
  END Insert;

  PROCEDURE Append* (T: Text; B: Buffer);
  BEGIN Insert(T, T.len, B)
  END Append;

  PROCEDURE Delete* (T: Text; beg, end: LONGINT; B: Buffer);
    VAR pb, pe, pbr, per: Piece; orgb, orge: LONGINT;
  BEGIN
    IF end > T.len THEN end := T.len END;
    FindPiece(T, beg, orgb, pb); SplitPiece(pb, beg - orgb, pbr);
    FindPiece(T, end, orge, pe);
    SplitPiece(pe, end - orge, per);
    IF T.org >= orgb THEN (*adjust cache*)
      T.org := orgb - pb.prev.len; T.pce := pb.prev
    END;
    B.header.next := pbr; B.last := per.prev;
    B.last.next := NIL; B.len := end - beg;
    per.prev := pbr.prev; pbr.prev.next := per;
    T.len := T.len - B.len;
    T.changed := TRUE;
    IF T.notify # NIL THEN (* noch *)
       T.notify(T, delete, beg, end)
    END
  END Delete;

  PROCEDURE ChangeLooks* (T: Text; beg, end: LONGINT; sel: SET; fnt: Fonts.Font; col, voff: INTEGER);
    VAR pb, pe, p: Piece; org: LONGINT;
  BEGIN
    IF end > T.len THEN end := T.len END;
    FindPiece(T, beg, org, p); SplitPiece(p, beg - org, pb);
    FindPiece(T, end, org, p); SplitPiece(p, end - org, pe);
    p := pb;
    REPEAT
      IF 0 IN sel THEN p.fnt := fnt END;
      IF 1 IN sel THEN p.col := col END;
      IF 2 IN sel THEN p.voff := voff END;
      p := p.next
    UNTIL p = pe;
    T.changed := TRUE;
    IF T.notify # NIL THEN (* noch *)
       T.notify(T, replace, beg, end)
    END
  END ChangeLooks;

  PROCEDURE Attributes*(T: Text; pos: LONGINT; VAR fnt: Fonts.Font; VAR col, voff: INTEGER);
    VAR p: Piece; org: LONGINT;
  BEGIN FindPiece(T, pos, org, p); fnt := p.fnt; col := p.col; voff := p.voff
  END Attributes;

  (* ------------------ Access: Readers ------------------------- *)

  PROCEDURE OpenReader* (VAR R: Reader; T: Text; pos: LONGINT);
    VAR p: Piece; org: LONGINT;
  BEGIN FindPiece(T, pos, org, p);
    R.ref := p; R.org := org; R.off := pos - org;
    Files.Set(R.rider, p.f, p.off + R.off); R.eot := FALSE
  END OpenReader;

  PROCEDURE Read* (VAR R: Reader; VAR ch: CHAR);
  BEGIN Files.Read(R.rider, ch);
    R.fnt := R.ref.fnt; R.col := R.ref.col; R.voff := R.ref.voff;
    INC(R.off);
    IF R.off = R.ref.len THEN
      IF R.ref.f = TrailerFile THEN R.eot := TRUE END;
      R.org := R.org + R.off; R.off := 0;
      R.ref := R.ref.next; R.org := R.org + R.off; R.off := 0;
      Files.Set(R.rider, R.ref.f, R.ref.off)
    END
  END Read;

  PROCEDURE Pos* (VAR R: Reader): LONGINT;
  BEGIN RETURN R.org + R.off
  END Pos;

  (* ------------------ Access: Scanners (NW) ------------------------- *)

  PROCEDURE OpenScanner* (VAR S: Scanner; T: Text; pos: LONGINT);
  BEGIN OpenReader(S, T, pos); S.line := 0; S.nextCh := " "
  END OpenScanner;

  (*floating point formats:
    x = 1.m * 2^(e-127)   bit 0: sign, bits 1- 8: e, bits  9-31: m
    x = 1.m * 2^(e-1023)  bit 0: sign, bits 1-11: e, bits 12-63: m *)

  PROCEDURE Ten(n: INTEGER): REAL;
    VAR t, p: REAL;
  BEGIN t := 1.0; p := 10.0;   (*compute 10^n *)
    WHILE n > 0 DO
      IF ODD(n) THEN t := p * t END ;
      p := p*p; n := n DIV 2
    END ;
    RETURN t
  END Ten;

  PROCEDURE Scan* (VAR S: Scanner);
    CONST maxExp = 38; maxM = 16777216; (*2^24*)
    VAR ch, term: CHAR;
      neg, negE, hex: BOOLEAN;
      i, j, h, d, e, n, s: INTEGER;
      k: LONGINT;
      x: REAL;
  BEGIN ch := S.nextCh; i := 0;
    WHILE (ch = " ") OR (ch = TAB) OR (ch = CR) DO
      IF ch = CR THEN INC(S.line) END ;
      Read(S, ch)
    END ;
    IF ("A" <= ch) & (ch <= "Z") OR ("a" <= ch) & (ch <= "z") THEN (*name*)
      REPEAT S.s[i] := ch; INC(i); Read(S, ch)
      UNTIL ((ch < "0") & (ch # ".") OR ("9" < ch) & (ch < "A") OR ("Z" < ch) & (ch < "a") OR ("z" < ch)) OR (i = 31);
      S.s[i] := 0X; S.len := i; S.class := Name
    ELSIF ch = 22X THEN (*string*)
      Read(S, ch);
      WHILE (ch # 22X) & (ch >= " ") & (i # 31) DO S.s[i] := ch; INC(i); Read(S, ch) END;
      S.s[i] := 0X; S.len := i+1; Read(S, ch); S.class := String
    ELSE hex := FALSE;
      IF ch = "-" THEN neg := TRUE; Read(S, ch) ELSE neg := FALSE END ;
      IF ("0" <= ch) & (ch <= "9") THEN (*number*)
        n := ORD(ch) - 30H; h := n; Read(S, ch);
        WHILE ("0" <= ch) & (ch <= "9") OR ("A" <= ch) & (ch <= "F") DO
          IF ch <= "9" THEN d := ORD(ch) - 30H ELSE d := ORD(ch) - 37H; hex := TRUE END ;
          n := 10*n + d; h := 10H*h + d; Read(S, ch)
        END ;
        IF ch = "H" THEN (*hex integer*) Read(S, ch); S.i := h; S.class := Int  (*neg?*)
        ELSIF ch = "." THEN (*real number*)
          Read(S, ch); x := 0.0; e := 0; j := 0;
          WHILE ("0" <= ch) & (ch <= "9") DO  (*fraction*)
            h := 10*n + (ORD(ch) - 30H);
            IF h < maxM THEN n := h; INC(j) END ;
            Read(S, ch)
          END ;
          IF ch = "E" THEN (*scale factor*)
            s := 0; Read(S, ch);
            IF ch = "-" THEN negE := TRUE; Read(S, ch)
            ELSE negE := FALSE;
              IF ch = "+" THEN Read(S, ch) END
            END ;
            WHILE ("0" <= ch) & (ch <= "9") DO
              s := s*10 + ORD(ch) - 30H; Read(S, ch)
            END ;
            IF negE THEN DEC(e, s) ELSE INC(e, s) END ;
          END ;
          (*x := FLT(n);*)
          x := n; (* voc adaptation by noch *)
          DEC(e, j);
          IF e < 0 THEN
            IF e >= -maxExp THEN x := x / Ten(-e) ELSE x := 0.0 END
          ELSIF e > 0 THEN
            IF e <= maxExp THEN x := Ten(e) * x ELSE x := 0.0 END
          END ;
          IF neg THEN S.x := -x ELSE S.x := x END ;
          IF hex THEN S.class := 0 ELSE S.class := Real END
        ELSE (*decimal integer*)
          IF neg THEN S.i := -n ELSE S.i := n END;
          IF hex THEN S.class := Inval ELSE S.class := Int END
        END
      ELSE (*spectal character*) S.class := Char;
        IF neg THEN S.c := "-" ELSE S.c := ch; Read(S, ch) END
      END
    END ;
    S.nextCh := ch
  END Scan;

  (* --------------- Access: Writers (NW) ------------------ *)

  PROCEDURE OpenWriter* (VAR W: Writer);
  BEGIN NEW(W.buf);
    OpenBuf(W.buf); W.fnt := Fonts.Default; W.col := 15; W.voff := 0;
    Files.Set(W.rider, Files.New(""), 0)
  END OpenWriter;

  PROCEDURE SetFont* (VAR W: Writer; fnt: Fonts.Font);
  BEGIN W.fnt := fnt
  END SetFont;

  PROCEDURE SetColor* (VAR W: Writer; col: INTEGER);
  BEGIN W.col := col
  END SetColor;

  PROCEDURE SetOffset* (VAR W: Writer; voff: INTEGER);
  BEGIN W.voff := voff
  END SetOffset;

  PROCEDURE Write* (VAR W: Writer; ch: CHAR);
    VAR p: Piece;
  BEGIN
    IF (W.buf.last.fnt # W.fnt) OR (W.buf.last.col # W.col) OR (W.buf.last.voff # W.voff) THEN
      NEW(p); p.f := Files.Base(W.rider); p.off := Files.Pos(W.rider); p.len := 0;
      p.fnt := W.fnt; p.col := W.col; p.voff:= W.voff;
      p.next := NIL; W.buf.last.next := p;
      p.prev := W.buf.last; W.buf.last := p
    END;
    Files.Write(W.rider, ch);
    INC(W.buf.last.len); INC(W.buf.len)
  END Write;

  PROCEDURE WriteLn* (VAR W: Writer);
  BEGIN Write(W, CR)
  END WriteLn;

  PROCEDURE WriteString* (VAR W: Writer; s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE s[i] >= " " DO Write(W, s[i]); INC(i) END
  END WriteString;

  PROCEDURE WriteInt* (VAR W: Writer; x, n: LONGINT);
    VAR i: INTEGER; x0: LONGINT;
      a: ARRAY 10 OF CHAR;
  BEGIN
    (*IF ROR(x, 31) = 1 THEN WriteString(W, " -2147483648")
    ELSE*) i := 0; (* voc adaptation by noch *)
      IF x < 0 THEN DEC(n); x0 := -x ELSE x0 := x END;
      REPEAT
        a[i] := CHR(x0 MOD 10 + 30H); x0 := x0 DIV 10; INC(i)
      UNTIL x0 = 0;
      WHILE n > i DO Write(W, " "); DEC(n) END;
      IF x < 0 THEN Write(W, "-") END;
      REPEAT DEC(i); Write(W, a[i]) UNTIL i = 0
    (*END*)
  END WriteInt;

  PROCEDURE WriteHex* (VAR W: Writer; x: LONGINT);
    VAR i: INTEGER; y: LONGINT;
      a: ARRAY 10 OF CHAR;
  BEGIN i := 0; Write(W, " ");
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END;
      x := x DIV 10H; INC(i)
    UNTIL i = 8;
    REPEAT DEC(i); Write(W, a[i]) UNTIL i = 0
  END WriteHex;
(* commented out because it's not necessary to compile OR compiler; -- noch
  PROCEDURE WriteReal* (VAR W: Writer; x: REAL; n: INTEGER);
    VAR e, i, m: INTEGER; x0: REAL; neg: BOOLEAN;
      d: ARRAY 16 OF CHAR;
  BEGIN
    IF x = 0.0 THEN
      WriteString(W, "  0.0"); i := 5;
      WHILE i < n DO Write(W, " "); INC(i) END
    ELSE
      IF x < 0.0 THEN x := -x; neg := TRUE ELSE neg := FALSE END ;
      x0 := x; UNPK(x0, e);
      IF e = 255 THEN WriteString(W, " NaN")
      ELSE
        REPEAT Write(W, " "); DEC(n) UNTIL n <= 14;
        IF neg THEN Write(W, "-") ELSE Write(W, " ") END ;
        e := e * 77 DIV 256 - 6;
        IF e >= 0 THEN x := x / Ten(e) ELSE x := x * Ten(-e) END ;
        IF x >= 10.0E6 THEN x := 0.1*x; INC(e) END ;
        m := FLOOR(x + 0.5); i := 0;
        IF x >= 10.0E6 THEN x := 0.1*x; INC(e) END ;
        REPEAT d[i] := CHR(m MOD 10 + 30H); m := m DIV 10; INC(i) UNTIL m = 0;
        DEC(i); Write(W, d[i]); Write(W, ".");
        IF i < n-6 THEN n := 0 ELSE n := 13-n END ;
        WHILE i > n DO DEC(i); Write(W, d[i]) END ;
        Write(W, "E"); INC(e, 6);
        IF e < 0 THEN Write(W, "-"); e := -e ELSE Write(W, "+") END ;
        Write(W, CHR(e DIV 10 + 30H)); Write(W, CHR(e MOD 10 + 30H))
      END
    END
  END WriteReal;
  *)
  PROCEDURE WriteRealFix* (VAR W: Writer; x: REAL; n, k: INTEGER);
    VAR i, m: INTEGER; neg: BOOLEAN;
      d: ARRAY 12 OF CHAR;
  BEGIN
    IF x = 0.0 THEN WriteString(W, "  0")
    ELSE
      IF x < 0.0 THEN x := -x; neg := TRUE ELSE neg := FALSE END ;
      IF k > 7 THEN k := 7 END ;
      x := Ten(k) * x; m := FLOOR(x + 0.5);
      i := 0;
      REPEAT d[i] := CHR(m MOD 10 + 30H); m := m DIV 10; INC(i) UNTIL m = 0;
      REPEAT Write(W, " "); DEC(n) UNTIL n <= i+3;
      IF neg THEN Write(W, "-"); DEC(n) ELSE Write(W, " ") END ;
      WHILE i > k DO DEC(i); Write(W, d[i]) END ;
      Write(W, ".");
      WHILE k > i DO DEC(k); Write(W, "0") END ;
      WHILE i > 0 DO DEC(i); Write(W, d[i]) END
    END
  END WriteRealFix;

  PROCEDURE WritePair(VAR W: Writer; ch: CHAR; x: LONGINT);
  BEGIN Write(W, ch);
    Write(W, CHR(x DIV 10 + 30H)); Write(W, CHR(x MOD 10 + 30H))
  END WritePair;

  PROCEDURE WriteClock* (VAR W: Writer; d: LONGINT);
  BEGIN
    WritePair(W, " ", d DIV 20000H MOD 20H);   (*day*)
    WritePair(W, ".", d DIV 400000H MOD 10H); (*month*)
    WritePair(W, ".", d DIV 4000000H MOD 40H);   (*year*)
    WritePair(W, " ", d DIV 1000H MOD 20H);   (*hour*)
    WritePair(W, ":", d DIV 40H MOD 40H);  (*min*)
    WritePair(W, ":", d MOD 40H)  (*sec*)
  END WriteClock;

BEGIN TrailerFile := Files.New("")
END CompatTexts.
