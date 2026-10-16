MODULE Kbd;   (* :file: Kbd.Mod  --  Read keys from keyboard. *)
(* VOC adaptation, 2026-10-16: using only existing VOC runtime modules.
   Keeping the editor's generic helpers private to the source examples. *)
IMPORT SYSTEM, Platform, Strings, Out;

CONST
(* ------------------------------------------------------------------------- *)
(* :section:    consts key encoding *)
        (**
          *  [------------------------------------------]
          *  [     Encoding KEY in 32-bit integer.      ]
          *  [------------------------------------------]
          *  [ 0..7    8..15   16..23   24..28   29..30 ]
          *  [ 8       8       8        5        2      ]       ; Bit per field.
          *  [------------------------------------------]
          *  [ ASCII   0       0        mdf      kchar  ]
          *  [ utf-8   xxx     xxx      mdf      kutf   ]       ; Not yet if ever, just in case.
          *  [ funkey  0       0        mdf      kfun   ]
          *  [ m-key   m-line  m-col    mdf      kmouse ]       ; Max window size: 256*256 chars.
          *  [------------------------------------------]
          *
          * Ctrl-A..Z,<esc>4567 --> 01..26, 27  28 29 30 31
          * Ctrl-A is represented as 01X+kchar, but without Ctrl-mdf-bit.
          * AKey(    0,01X ) and AKey( Ctrl,"A" ) are equal.
          * AKey( Meta,01X ) and AKey(   CM,"A" ) are equal.
          * There is no such thing as Shift-Ctrl-A or Ctrl-a or Shift-Meta-Ctrl-a or Ctrl-ö.
          *
          * Well, there are both: Meta-A and Meta-a, of cause.
          *)
        SHL24   = 256 * 256 * 256;                      (* shift to byte 4 *)
        SHL29   = 256 * 256 * 256 * 32;                 (* shift to type-bits of k *)

        (** KEY type codes. *)
        kchar   = 0 * SHL29;                            (* k: KEY: just a simple ASCII char *)
        kutf    = 1 * SHL29;                            (* k: uft-8, not jet but just in case ... *)
        kfun    = 2 * SHL29;                            (* k: function key: <Insert> ... *)
        kmouse  = 3 * SHL29;                            (* k: mouse event *)

        kmask   = 3 * SHL29;                            (* k: type mask *)

        (** ASCII chars: 0..127,                         *)
        Tab*    = 09H + kchar;                          (* shift-Tab: shift-STab *)
        Enter*  = 0DH + kchar;
        Escape* = 1BH + kchar;
        Backspace* = 7FH + kchar;

        (** Modifier keys for mouse and keyboard.        *)
        Shift*  =  1 * SHL24;
        Ctrl*   =  2 * SHL24;
        Super*  =  4 * SHL24;                           (* Not at xterm? *)
        Meta*   =  8 * SHL24;
        Drag*   = 16 * SHL24;                           (* Mouse only *)

        (* None  *)
        (* Shift *)
        (* Ctrl  *)
        (* Meta  *)
        sC*     = Shift + Ctrl;
        sM*     = Shift        + Meta;
        CM*     =         Ctrl + Meta;
        sCM*    = Shift + Ctrl + Meta;


(* ------------------------------------------------------------------------- *)
(* :section:    consts function key encoding *)
        (** Function keys.                              *)
        F1*     =     1;
        F2*     =     2;
        F3*     =     3;
        F4*     =     4;
        F5*     =     5;
        F6*     =     6;
        F7*     =     7;
        F8*     =     8;
        F9*     =     9;
        F10*    =    10;
        F11*    =    11;
        F12*    =    12;

        Print*  =    21;
        Roll*   =    22;
        Pause*  =    23;

        Insert* =    31;
        Home*   =    32;
        PageUp* =    33;
        Delete* =    34;
        End*    =    35;
        PageDown* =  36;

        Up*     =    41;
        Left*   =    42;
        Down*   =    43;
        Right*  =    44;

        STab*   =    51;

        (** Function keys: Mouse bottons.               *)
        B1*     =   101;
        B2*     =   102;
        B3*     =   103;
        B4*     =   104;
        B5*     =   105;
        B1up*   =   B1  + 16;
        B2up*   =   B2  + 16;
        B3up*   =   B3  + 16;
        B4up*   =   B4  + 16;
        B5up*   =   B5  + 16;



(* ------------------------------------------------------------------------- *)
(* :section:    types and vars *)
        TableSize    = 128;
        BuBufferSize = 256;
        EscapeDelay* = 50; (* ms for a lone escape or an incomplete sequence *)

TYPE
        Int32 = SYSTEM.INT32;
        KEY* = Int32;

        Keypath = RECORD
                    path: ARRAY 64 OF CHAR;
                    k:    KEY;
                  END;

VAR
        bubuffer:       ARRAY BuBufferSize OF CHAR;     (* Keyboard raw char buffer. *)
        buk, bun:       Int32;                          (* Read- and fill-pointer    *)
        pending:        BOOLEAN;
        pendingSince:   LONGINT;

        table:          ARRAY TableSize OF Keypath;     (* Table of (fun-key * escape-seq) *)
        tableFF:        Int32;                          (* ff: first-free *)

        escseq*:        ARRAY 64 OF CHAR;               (* Last read escape sequence. *)

PROCEDURE -Aerrno '#include <errno.h>';
PROCEDURE -again(error: Platform.ErrorCode): BOOLEAN
  '(error == EAGAIN || error == EWOULDBLOCK)';

PROCEDURE And(i, j: Int32): Int32;
BEGIN RETURN SYSTEM.VAL(Int32, SYSTEM.VAL(SET, i) * SYSTEM.VAL(SET, j)) END And;

PROCEDURE Append(VAR a: ARRAY OF CHAR; extra: ARRAY OF CHAR);
BEGIN
  ASSERT(LONG(Strings.Length(a)) + Strings.Length(extra) < LEN(a));
  Strings.Append(extra, a)
END Append;

PROCEDURE AppendChar(VAR a: ARRAY OF CHAR; c: CHAR);
  VAR extra: ARRAY 2 OF CHAR;
BEGIN extra[0] := c; extra[1] := 0X; Append(a, extra) END AppendChar;

PROCEDURE AppendNumber(VAR a: ARRAY OF CHAR; n: Int32);
  VAR digits: ARRAY 10 OF CHAR; i: INTEGER;
BEGIN
  ASSERT(n >= 0); i := 0;
  REPEAT digits[i] := CHR(ORD('0') + n MOD 10); INC(i); n := n DIV 10 UNTIL n = 0;
  WHILE i > 0 DO DEC(i); AppendChar(a, digits[i]) END
END AppendNumber;

PROCEDURE Error(message: ARRAY OF CHAR);
BEGIN Out.String(message); Out.Ln; HALT(1) END Error;


(* ========================================================================= *)
(* :chapter: KEY-ENCODING *)
PROCEDURE AKey*(mdf: Int32; c: CHAR): KEY;              (* make ASCII KEY *)
VAR k : KEY;
BEGIN
   IF And (mdf, Ctrl) = 0 THEN
      k := ORD(c) + mdf + kchar                (* hint: kchar for ASCII is 0 *)
   ELSIF ("A" <= c) & (c <= "Z") THEN
      k := ORD(c) - 64 + mdf + kchar - Ctrl    (* hint: kchar for ASCII is 0 *)
    ELSE Error("Kbd.AKey: Kbd.AKey( Ctrl,c )  only for c in A..Z, use Kbd.AKey( 0,xxX ) instead.")
   END;
   RETURN k
END AKey;

PROCEDURE FKey*(mdf, fun: Int32): KEY;                  (* make Function KEY *)
BEGIN RETURN   kfun + mdf + fun END FKey;

PROCEDURE MKey*(mdf, button, line, col: Int32): KEY;    (* make Mouse KEY *)
BEGIN RETURN  kmouse + mdf + button + 256*line + 256*256*col END MKey;


PROCEDURE IsAKey*(k: KEY): BOOLEAN;
BEGIN RETURN And (k, kmask) = kchar END IsAKey;

PROCEDURE IsFKey*(k: KEY): BOOLEAN;
BEGIN RETURN And (k, kmask) = kfun END IsFKey;

PROCEDURE IsMKey*(k: KEY): BOOLEAN;
BEGIN RETURN And (k, kmask) = kmouse END IsMKey;


PROCEDURE Chr*(key: KEY): CHAR;
BEGIN
  ASSERT (IsAKey (key), 80);
  RETURN CHR (And (key, 255))
END Chr;

PROCEDURE Fun*(key: KEY): Int32;
BEGIN
  ASSERT (IsFKey (key), 80);
  RETURN And(key, 255)
END Fun;

PROCEDURE Mouse*(VAR mkey, line, col: Int32; k: KEY);
BEGIN
  ASSERT (IsMKey (k), 80);
  mkey := And(k, 255);
  line := And(k, (255 * 256)) DIV 256;
  col  := And(k, (255 * 256 * 256)) DIV (256 * 256);
END Mouse;

PROCEDURE MouseKey*(k: KEY): Int32;
BEGIN
  ASSERT (IsMKey(k), 80);
  RETURN And (k, 255)
END MouseKey;


(* ========================================================================= *)
(* :chapter: SHOW KEY *)
PROCEDURE ShowKey* (VAR a: ARRAY OF CHAR; k : KEY);
VAR
   cv,f,line,col: Int32;
   modf : BOOLEAN;
   c    : CHAR;

        PROCEDURE append (VAR a: ARRAY OF CHAR; c: CHAR; VAR mdf:BOOLEAN);
        BEGIN
          AppendChar(a, c);
          mdf := TRUE
        END append;
        PROCEDURE Funk (VAR a: ARRAY OF CHAR; f,value: Int32; name: ARRAY OF CHAR);
        BEGIN
          IF f = value THEN Append(a, name) END
        END Funk;
        
BEGIN
  a[0] := "<";
  a[1] := 0X;
  modf := FALSE;
  IF And(k, Shift)   # 0 THEN append(a, "s", modf) END;
  IF And(k, Ctrl)    # 0 THEN append(a, "C", modf) END;
  IF And(k, Super)   # 0 THEN append(a, "S", modf) END;
  IF And(k, Meta)    # 0 THEN append(a, "M", modf) END;
  IF And(k, Drag)    # 0 THEN append(a, "D", modf) END;
  IF modf THEN AppendChar(a, "-") END;
  
  IF IsAKey( k ) THEN
                c := Chr(k);
                cv := ORD(c);
                IF cv = 0 THEN                          (* NULL *)
                ELSIF cv < 32 THEN                      (* Ctrl-a..?z *)
                  IF    k = Enter  THEN Append(a, "Enter")
                  ELSIF k = Tab    THEN Append(a, "Tab")
                  ELSIF k = Escape THEN Append(a, "Escape")
                  ELSE
                      AppendChar(a, "C");
                      AppendChar(a, "-");
                      AppendChar(a, CHR(cv + 65 - 1));
                  END
                ELSIF cv < 127 THEN                     (* <space> .. ~ *)
                  AppendChar(a, c)
                ELSIF k = Backspace THEN                (* <Backspace> *)
                  Append(a, "Backspace")  (* 127 *)
                ELSE                                    (* ??? *)
                  Append(a, "Kbd.ShowKey: IsAKey > 127");
                END;
                
  ELSIF IsFKey( k ) THEN
                f := Fun(k);
                Funk(a, f, F1,              "F1");
                Funk(a, f, F2,              "F2");
                Funk(a, f, F3,              "F3");
                Funk(a, f, F4,              "F4");
                Funk(a, f, F5,              "F5");
                Funk(a, f, F6,              "F6");
                Funk(a, f, F7,              "F7");
                Funk(a, f, F8,              "F8");
                Funk(a, f, F9,              "F9");
                Funk(a, f, F10,             "F10");
                Funk(a, f, F11,             "F11");
                Funk(a, f, F12,             "F12");
                Funk(a, f, Print,           "Print");
                Funk(a, f, Roll,            "Roll");
                Funk(a, f, Pause,           "Pause");
                Funk(a, f, Insert,          "Insert");
                Funk(a, f, Home,            "Home");
                Funk(a, f, PageUp,          "Pageup");
                Funk(a, f, Delete,          "Delete");
                Funk(a, f, End,             "End");
                Funk(a, f, PageDown,        "Pagedown");
                Funk(a, f, Up,              "Up");
                Funk(a, f, Left,            "Left");
                Funk(a, f, Down,            "Down");
                Funk(a, f, Right,           "Right");
                Funk(a, f, STab,            "STab");
                
  ELSIF IsMKey( k ) THEN
                Mouse(f, line, col, k);
                Funk(a, f, B1,   "B1");
                Funk(a, f, B2,   "B2");
                Funk(a, f, B3,   "B3");
                Funk(a, f, B4,   "B4");
                Funk(a, f, B5,   "B5");
                Funk(a, f, B1up, "B1up");
                Funk(a, f, B2up, "B2up");
                Funk(a, f, B3up, "B3up");
                Funk(a, f, B4up, "B4up");
                Funk(a, f, B5up, "B5up");
                AppendChar(a, "-");
                AppendNumber(a, line);
                AppendChar(a, "-");
                AppendNumber(a, col);
  ELSE Error("Kbd.ShowKey: strange key to show.")
  END;
  AppendChar(a, ">");
END ShowKey;


(* ========================================================================= *)
(* :chapter: READ KEYS *)
PROCEDURE ReadKeys;                             (** fill bubuffer *)
VAR res, i, left: Int32; chunk: ARRAY 128 OF CHAR;
  n: LONGINT; error: Platform.ErrorCode;
BEGIN
   left := bun - buk;
   IF left > BuBufferSize - LEN(chunk) THEN RETURN END;
   FOR i := 0 TO left - 1 DO bubuffer[i] := bubuffer[buk + i] END;
   buk := 0; bun := left;
   REPEAT error := Platform.Read(Platform.StdIn, SYSTEM.ADR(chunk), LEN(chunk), n)
   UNTIL ~Platform.Interrupted(error);
   IF error # 0 THEN
     IF again(error) THEN RETURN END;
     Error('Kbd.ReadKeys: stdin read failed')
   END;
   res := SHORT(n); (* The read is bounded to 128 bytes in either type model. *)
   FOR i := 0 TO res - 1 DO bubuffer[bun + i] := chunk[i] END;
   INC(bun, res)
END ReadKeys;

PROCEDURE Next0():CHAR;                         (** read next char from bubuffer *)
VAR c : CHAR;
BEGIN
  IF buk = bun THEN ReadKeys END;
  IF buk = bun THEN
    c := 0X
  ELSE
    c := bubuffer[buk];
    INC(buk);
  END;
  RETURN c
END Next0;

PROCEDURE HasKey*():BOOLEAN;                    (** Is a char before ESC translation waiting? *)
BEGIN
  IF buk = bun THEN ReadKeys END;
  RETURN buk <bun
END HasKey;

PROCEDURE IsNext*(c :CHAR): BOOLEAN;            (** Is c waiting as next char before ESC translation? *)
(** 0X --> no char waiting *)
VAR res: BOOLEAN;
BEGIN
   IF HasKey() THEN
      res := bubuffer[buk] = c
   ELSE res := c = 0X
   END;
   RETURN res
END IsNext;

(* ========================================================================= *)
(* :chapter: TRANSLATE KEYS *)
PROCEDURE Number(VAR a: ARRAY OF CHAR; VAR pos, value: Int32): BOOLEAN;
VAR start, digit: Int32;
BEGIN
   start := pos; value := 0;
   WHILE (pos < LEN(a)) & (a[pos] >= '0') & (a[pos] <= '9') DO
     digit := ORD(a[pos]) - ORD('0');
     IF value > (MAX(Int32) - digit) DIV 10 THEN RETURN FALSE END;
     value := value * 10 + digit; INC(pos)
   END;
   RETURN pos > start
END Number;

PROCEDURE ReadMouse():KEY;
(**
  *     just    ctrl    drag    cd      Button
  *     0Mm     16Mm    32M     48M     B1                      .... ..00
  *     1m      17m     --              B2/wheel-press          .... ..01
  *     2Mm     18Mm    34M     50M     B3                      .... ..10
  *     64M     80M                     B4/wheel-up             0100 0000
  *     65M     81M                     B5/wheel-down           0100 0001
  *
  *     bit-0   button
  *     bit-1   button
  *     bit-2
  *     bit-3
  *     bit-4   ctrl
  *     bit-5   drag
  *     bit-6   wheel
  *     bit-7
  *
  *  MouseKey: [ m-key   m-line  m-col    mdf      kmouse ]       ; Max window size: 256*256 chars.
  *)
CONST
   mctrl  = 16;
   mdrag  = 32;
   mwheel = 64;
VAR
   a : ARRAY 64 OF CHAR;
   c : CHAR;
   i, pos : Int32;
   mkey,col,line : Int32;
   key,mdf  : Int32;
   up,wheel : BOOLEAN;
BEGIN
  i := 0;
  REPEAT
    c := Next0();
    a[i] := c;
    INC(i)
   UNTIL (c = 'm') OR (c = 'M') OR (c = 0X) OR (i = LEN(a) - 1);
   a[i] := 0X;
   (* ------------------------------------- *)
   pos := 0;
   IF ~Number(a, pos, mkey) OR (a[pos] # ';') THEN RETURN 0 END;
   INC(pos);
   IF ~Number(a, pos, col) OR (a[pos] # ';') THEN RETURN 0 END;
   INC(pos);
   IF ~Number(a, pos, line) THEN RETURN 0 END;
   IF ((a[pos] # 'M') & (a[pos] # 'm')) OR (a[pos+1] # 0X) THEN RETURN 0 END;
   IF (line < 1) OR (line > 255) OR (col < 1) OR (col > 255) OR (mkey > 127) THEN RETURN 0 END;
   up := a[pos] = 'm';
  mdf := 0;
  wheel := FALSE;
  IF And(mkey, mctrl)  # 0 THEN mdf   := mdf + Ctrl END;
  IF And(mkey, mdrag)  # 0 THEN mdf   := mdf + Drag END;
   IF And(mkey, mwheel) # 0 THEN wheel := TRUE       END;
   IF And(mkey, 4) # 0 THEN mdf := mdf + Shift END;
   IF And(mkey, 8) # 0 THEN mdf := mdf + Meta END;
   mkey := And(mkey, 3);
  IF wheel THEN
    IF    mkey = 0 THEN key := B4
    ELSIF mkey = 1 THEN key := B5
    ELSE RETURN 0
    END
  ELSE
    IF    mkey = 0 THEN key := B1
    ELSIF mkey = 1 THEN key := B2
    ELSIF mkey = 2 THEN key := B3
    ELSE RETURN 0
    END
  END;
  IF up THEN key := key + 16 END;
  RETURN MKey (mdf, key, line, col)
END ReadMouse;

PROCEDURE ReadEscapeSequence (): KEY;
(** return KEY, set escseq := a which is exported (to viewer etc) *)
VAR
   c : CHAR;
   i : Int32;
   a : ARRAY 64 OF CHAR;
BEGIN
   a[0] := '['; i := 1;
   REPEAT
     c := Next0(); a[i] := c; INC(i)
   UNTIL ((c >= '@') & (c <= '~')) OR (c = 0X) OR (i = LEN(a) - 1);
   a[i] := 0X;
   escseq := a;
  i := 0;
  WHILE (i < tableFF) & (a # table[i].path) DO
    INC(i)
  END;
  IF i = tableFF THEN
     RETURN 0
  END;
   RETURN table[i].k
END ReadEscapeSequence;

PROCEDURE Translate(c: CHAR): KEY;
(** a          -->  a        (8: Ctrl-Backspace)
  * ESC <>     -->  <Escape>
  * ESC ESC    -->  <Escape> (leave second escape in queue)
  * ESC a      -->  Meta-a   (Meta-Tab, Meta-Backspace)
  * ESC [
  *       < ... until m|M             -->  Mouse
  *         ... until (A..H)|~        -->  fun
  *)
VAR k: KEY;
BEGIN
   IF c # 1BX THEN
      k := AKey( 0,c )                          (* [Ctrl-]a     --> [Ctrl-]a *)
   ELSE (* c = esc *)
      IF IsNext (0X) THEN
         k := Escape                            (* ESC          --> <Escape> *)
      ELSIF IsNext (1BX) THEN
         k := Escape                            (* ESC ESC      --> <Escape> *)
      ELSE
         c := Next0();
         IF c # "[" THEN
            k := AKey( Meta,c)                  (* ESC a        --> Meta-a *)
         ELSE
            IF IsNext("<") THEN                 (* ESC[< *)
               c := Next0();                    (* drop '<' *)
               k := ReadMouse()                 (* ESC[<        --> Mouse *)
            ELSE
               k := ReadEscapeSequence()        (* ESC[         --> now *)
            END
         END
      END
   END;
   RETURN k
END Translate;


(* ========================================================================= *)
(* :chapter: RETURN KEYS *)
PROCEDURE Next():KEY;
(* Frame escape sequences before translating: reads may split anywhere.
   Unsupported, malformed and overlong sequences return 0, not a halt. *)
VAR i, count: Int32; c: CHAR; elapsed: LONGINT;
BEGIN
   ReadKeys;
   IF buk = bun THEN RETURN 0 END;
   IF bubuffer[buk] # 1BX THEN
     pending := FALSE; RETURN Translate(Next0())
   END;
   count := bun - buk;
   IF count > 1 THEN
     c := bubuffer[buk+1];
     IF c # '[' THEN pending := FALSE; RETURN Translate(Next0()) END;
     i := buk + 2;
     WHILE (i < bun) & (i - buk < 63) DO
       c := bubuffer[i];
       IF (c >= '@') & (c <= '~') THEN
         pending := FALSE; RETURN Translate(Next0())
       END;
       IF (c < ' ') OR (c > '~') THEN
         buk := i + 1; pending := FALSE; RETURN 0
       END;
       INC(i)
     END;
     IF count >= 63 THEN buk := i; pending := FALSE; RETURN 0 END
   END;
   IF ~pending THEN pendingSince := Platform.Time(); pending := TRUE END;
   elapsed := (Platform.Time() - pendingSince) MOD 2147483647;
   IF elapsed < EscapeDelay THEN RETURN 0 END;
   pending := FALSE;
   IF count = 1 THEN INC(buk); RETURN Escape END;
   buk := bun; RETURN 0
END Next;

PROCEDURE NextKey*():KEY;                               (* Return next key or 0X. *)
(** Return next key waiting at stdin.
  * Return X0, if no key waiting.
  *)
BEGIN RETURN Next() END NextKey;

PROCEDURE GetKey*():KEY;                                (* Return next key, wait if none. *)
(** Return next key from stdin.
  * Wait, if no key available.
  *)
VAR k: KEY;
BEGIN
   REPEAT
     k := Next();
     IF k = 0 THEN Platform.Delay(25) END;
   UNTIL k # 0;
   RETURN k
END GetKey;

PROCEDURE Skip*():BOOLEAN;                              (* Skip at max 1 key, return true if *)
(** Skip one key from stdin, if one or more are waiting. 
  * Return TRUE, if a key was skipped.
  *)
BEGIN RETURN Next() # 0 END Skip;

PROCEDURE SkipAll*;                                     (* Skip all waiting keys. *)
(** Skip all waiting keys from stdin. *)
BEGIN WHILE Skip() DO END END SkipAll;

PROCEDURE Wait*;                                        (* Skip all keys, wait, skip. *)
(** Skip all pressed keys and wait for the next one, which is discarded. *)
VAR k: KEY;
BEGIN SkipAll; k := GetKey() END Wait;


(* ========================================================================= *)
(* :chapter: TEST *)
PROCEDURE ShowTable*;
VAR
   i : Int32;
   a : ARRAY 64 OF CHAR;
BEGIN
   FOR i := 0 TO tableFF - 1 DO
      Out.Ln; ShowKey(a, table[i].k); Out.String(a);
      Out.Char(1BX); Out.String('[16G |'); Out.String(table[i].path)
   END;
   Out.Ln; Out.String('    '); Out.Int(tableFF, 0);
   Out.String(' key/paths in table.'); Out.Flush
END ShowTable;

PROCEDURE DisplayChars*;
(** In order to print Escape sequences. *)
VAR c: CHAR;
BEGIN
   Out.String("(Exit with 'x'.)");
   Out.Char(1BX); Out.String('[?1002;1006;1015h'); Out.Flush;
   REPEAT
      c := Next0();
      IF    c = 0X  THEN Platform.Delay(100)
      ELSIF c = 1BX THEN Out.Ln; Out.String('<ESC>')
      ELSIF c = 0DX THEN Out.Ln; Out.String('<Return>')
      ELSE Out.Char(c)
      END; Out.Flush;
   UNTIL c = 'x';
   Out.Char(1BX); Out.String('[?1002;1006;1015l'); Out.Flush
END DisplayChars;

PROCEDURE DisplayKeys*;
VAR 
   a : ARRAY 32 OF CHAR;
   k,exitKey : KEY;
BEGIN
   Out.String("DisplayKeys  (Exit with 'x'.)"); Out.Flush;
   exitKey := AKey (0, 'x');
   REPEAT
      k := GetKey();
      ShowKey (a, k);
      Out.String(a); Out.String('  ');
      IF k = Enter THEN Out.Ln ELSE Out.Flush END;
   UNTIL k = exitKey;
END DisplayKeys;


(* ========================================================================= *)
(* :chapter: MAIN *)
PROCEDURE Escseq( seq: ARRAY OF CHAR; mdf, fun: Int32);
(* Fill table. *)
BEGIN
  ASSERT (tableFF < TableSize, 80);
(*   table[tableFF].path := seq; *)
  COPY (seq, table[tableFF].path);
  table[tableFF].k    := FKey (mdf, fun);
  INC (tableFF);
END Escseq;

BEGIN
  buk := 0;
  bun := 0;
  pending := FALSE;

  tableFF := 0;

     (* Escseq(   "0m",         CM,     Pause    ); *)
        Escseq(   "[1;2A",      Shift,  Up       );
        Escseq(   "[1;2B",      Shift,  Down     );
        Escseq(   "[1;2C",      Shift,  Right    );
        Escseq(   "[1;2D",      Shift,  Left     );
        Escseq(   "[1;2H",      Shift,  Home     );
        Escseq(   "[1;2F",      Shift,  End      );

        Escseq(   "[1;3A",      Meta,   Up       );
        Escseq(   "[1;3B",      Meta,   Down     );
        Escseq(   "[1;3C",      Meta,   Right    );
        Escseq(   "[1;3D",      Meta,   Left     );
        Escseq(   "[1;3F",      Meta,   End      );
        Escseq(   "[1;3H",      Meta,   Home     );

        Escseq(   "[1;4A",      sM,     Up       );
        Escseq(   "[1;4B",      sM,     Down     );
        Escseq(   "[1;4C",      sM,     Right    );
        Escseq(   "[1;4D",      sM,     Left     );
        Escseq(   "[1;4F",      sM,     End      );
        Escseq(   "[1;4H",      sM,     Home     );

        Escseq(   "[1;5A",      Ctrl,   Up       );
        Escseq(   "[1;5B",      Ctrl,   Down     );
        Escseq(   "[1;5C",      Ctrl,   Right    );
        Escseq(   "[1;5D",      Ctrl,   Left     );
        Escseq(   "[1;5F",      Ctrl,   End      );
        Escseq(   "[1;5H",      Ctrl,   Home     );

        Escseq(   "[1;6A",      sC,     Up       );
        Escseq(   "[1;6B",      sC,     Down     );
        Escseq(   "[1;6C",      sC,     Right    );
        Escseq(   "[1;6D",      sC,     Left     );
        Escseq(   "[1;6H",      sC,     Home     );
        Escseq(   "[1;6F",      sC,     End      );

        Escseq(   "[1;7A",      CM,     Up       );
        Escseq(   "[1;7B",      CM,     Down     );
        Escseq(   "[1;7C",      CM,     Right    );
        Escseq(   "[1;7D",      CM,     Left     );
        Escseq(   "[1;7F",      CM,     End      );
        Escseq(   "[1;7H",      CM,     Home     );

        Escseq(   "[1;8A",     sCM,     Up       );
        Escseq(   "[1;8B",     sCM,     Down     );
        Escseq(   "[1;8C",     sCM,     Right    );
        Escseq(   "[1;8D",     sCM,     Left     );
        Escseq(   "[1;8H",     sCM,     Home     );
        Escseq(   "[1;8F",     sCM,     End      );

        Escseq(   "[2~",        0,      Insert   );
        Escseq(   "[2;3~",      Meta,   Insert   );
        Escseq(   "[2;5~",      Ctrl,   Insert   );
        Escseq(   "[2;2~",      Shift,  Insert   );
        Escseq(   "[2;4~",      sM,     Insert   );

     (* Escseq(   "28~",        CM,     Print    ); *)
     (* Escseq(   "29~",        CM,     Roll     ); *)

        Escseq(   "[3~",        0,      Delete   );
        Escseq(   "[3;2~",      Shift,  Delete   );
        Escseq(   "[3;3~",      Meta,   Delete   );
        Escseq(   "[3;4~",      sM,     Delete   );
        Escseq(   "[3;5~",      Ctrl,   Delete   );
        Escseq(   "[3;6~",      sC,     Delete   );
        Escseq(   "[3;7~",      CM,     Delete   );      (* xfce-logout *)
        Escseq(   "[3;8~",      sCM,    Delete   );      (* xfce-logout *)

        Escseq(   "[5~",        0,      PageUp   );
        Escseq(   "[5;2~",     Shift,   PageUp   );
        Escseq(   "[5;3~",      Meta,   PageUp   );
        Escseq(   "[5;4~",      sM,     PageUp   );
        Escseq(   "[5;5~",    Ctrl,     PageUp   );
        Escseq(   "[5;6~",      sC,     PageUp   );
        Escseq(   "[5;7~",      CM,     PageUp   );
        Escseq(   "[5;8~",     sCM,     PageUp   );

        Escseq(   "[6~",        0,      PageDown );
        Escseq(   "[6;2~",     Shift,   PageDown );
        Escseq(   "[6;3~",      Meta,   PageDown );
        Escseq(   "[6;4~",      sM,     PageDown );
        Escseq(   "[6;5~",    Ctrl,     PageDown );
        Escseq(   "[6;6~",      sC,     PageDown );
        Escseq(   "[6;7~",      CM,     PageDown );
        Escseq(   "[6;8~",     sCM,     PageDown );

        Escseq(   "[A",         0,      Up       );
        Escseq(   "[B",         0,      Down     );
        Escseq(   "[C",         0,      Right    );
        Escseq(   "[D",         0,      Left     );
        Escseq(   "[F",         0,      End      );
        Escseq(   "[H",         0,      Home     );
        Escseq(   "[Z",     Shift,      STab     );   (* tab is not a fun-key *)


END Kbd. (* :file: (c) sts-q 2022-Okt *)
