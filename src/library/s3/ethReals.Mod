(* ETH Oberon, Copyright 2001 ETH Zuerich Institut fuer Computersysteme, ETH Zentrum, CH-8092 Zuerich.
Refer to the "General ETH Oberon System Source License" contract available at: http://www.oberon.ethz.ch/ *)

MODULE ethReals;  (** portable *)

(** Implementation of the non-portable components of IEEE REAL and 
LONGREAL manipulation. The routines here are required to do conversion 
of reals to strings and back. 
Implemented by Bernd Moesli, Seminar for Applied Mathematics, 
Swiss Federal Institute of Technology Z…rich.
*)

IMPORT SYSTEM, Platform, Configuration;

(* Bernd Moesli
  Seminar for Applied Mathematics
  Swiss Federal Institute of Technology Zurich
  Copyright 1993

  Support module for IEEE floating-point numbers

  Please change constant definitions of H, L depending on byte ordering
  Use bm.TestReals.Do for testing the implementation.

  Expo, ExpoL return the shifted binary exponent (0 <= e < 256 (2048 resp.))
  SetExpo, SetExpoL set the shifted binary exponent
  Real, RealL convert hexadecimals to reals
  Int, IntL convert reals to hexadecimals
  Ten returns 10^e (e <= 308, 308 < e delivers NaN)

  1993.4.22  IEEE format only, 32-bits LONGINTs only
  30.8.1993  mh: changed RealX to avoid compiler warnings;
  7.11.1995  jt: dynamic endianess test
  22.01.97  pjm: NaN stuff (using quiet NaNs only to avoid traps)
  05.01.98  prk: NaN with INF support
  17.02.16  dcb: Adapt for 32 bit INTEGER and 64 bit LONGINT.
*)

VAR
  DefaultFCR*: SET;
  tene: ARRAY 23 OF LONGREAL; (* e = 0..22: exact values of 10^e *)
  ten: ARRAY 27 OF LONGREAL;
  eq, gr: ARRAY 20 OF SET;
  H, L: INTEGER;

(** Returns the shifted binary exponent (0 <= e < 256). *)
PROCEDURE Expo* (x: REAL): LONGINT;
BEGIN
  IF SIZE(INTEGER) = 4 THEN
    RETURN SHORT(ASH(SYSTEM.VAL(INTEGER, x), -23)) MOD 256
  ELSIF SIZE(LONGINT) = 4 THEN
    RETURN SHORT(ASH(SYSTEM.VAL(LONGINT, x), -23)) MOD 256
  ELSE Platform.Halt(-15);
  END
END Expo;

(** Returns the shifted binary exponent (0 <= e < 2048). *)
PROCEDURE ExpoL* (x: LONGREAL): LONGINT;
  VAR i: LONGINT;
BEGIN
  IF SIZE(LONGINT) = 8 THEN
    RETURN ASH(SYSTEM.VAL(LONGINT, x), -50) MOD 256
  ELSE
    SYSTEM.GET(SYSTEM.ADR(x) + H, i); RETURN ASH(i, -20) MOD 2048
  END
END ExpoL;

(** Sets the shifted binary exponent. *)
PROCEDURE SetExpo* (e: INTEGER; VAR x: REAL);
  VAR i: INTEGER; l: LONGINT;
BEGIN
  IF SIZE(LONGINT) = 4 THEN
    SYSTEM.GET(SYSTEM.ADR(x), l);
    l := ASH(ASH(ASH(l, -31), 8) + e MOD 256, 23) + l MOD ASH(1, 23);
    SYSTEM.PUT(SYSTEM.ADR(x), l)
  ELSIF SIZE(INTEGER) = 4 THEN
    SYSTEM.GET(SYSTEM.ADR(x), i);
    i := SHORT(ASH(ASH(ASH(i, -31), 8) + e MOD 256, 23) + i MOD ASH(1, 23));
    SYSTEM.PUT(SYSTEM.ADR(x), i)
  ELSE Platform.Halt(-15)
  END
END SetExpo;

(** Sets the shifted binary exponent. *)
PROCEDURE SetExpoL* (e: LONGINT; VAR x: LONGREAL);
  VAR i: INTEGER; l: LONGINT;
BEGIN
  IF SIZE(LONGINT) = 4 THEN
    SYSTEM.GET(SYSTEM.ADR(x) + H, l);
    l := ASH(ASH(ASH(l, -31), 11) + e MOD 2048, 20) + l MOD ASH(1, 20);
    SYSTEM.PUT(SYSTEM.ADR(x) + H, l)
  ELSIF SIZE(INTEGER) = 4 THEN
    SYSTEM.GET(SYSTEM.ADR(x) + H, i);
    i := SHORT(ASH(ASH(ASH(i, -31), 11) + e MOD 2048, 20) + i MOD ASH(1, 20));
    SYSTEM.PUT(SYSTEM.ADR(x) + H, i)
  ELSE Platform.Halt(-15)
  END
END SetExpoL;

(** Convert hexadecimal to REAL. *)
PROCEDURE Real* (h: LONGINT): REAL;
  VAR x: REAL;
BEGIN 
  IF SIZE(LONGINT) = 4 THEN
    SYSTEM.PUT(SYSTEM.ADR(x), h)
  ELSIF SIZE(INTEGER) = 4 THEN
    SYSTEM.PUT(SYSTEM.ADR(x), SYSTEM.VAL(INTEGER, h))
  ELSE Platform.Halt(-15)
  END;
  RETURN x
END Real;

(** Convert hexadecimal to LONGREAL. h and l are the high and low parts.*)
PROCEDURE RealL* (h, l: LONGINT): LONGREAL;
  VAR x: LONGREAL;
BEGIN 
  IF SIZE(LONGINT) = 4 THEN
    SYSTEM.PUT(SYSTEM.ADR(x) + H, h); 
    SYSTEM.PUT(SYSTEM.ADR(x) + L, l)
  ELSIF SIZE(INTEGER) = 4 THEN
    SYSTEM.PUT(SYSTEM.ADR(x) + H, SYSTEM.VAL(INTEGER, h)); 
    SYSTEM.PUT(SYSTEM.ADR(x) + L, SYSTEM.VAL(INTEGER, l))
  ELSE Platform.Halt(-15)
  END;
  RETURN x
END RealL;

(** Convert REAL to hexadecimal. *)
PROCEDURE Int* (x: REAL): LONGINT;
  VAR i: INTEGER; l: LONGINT;
BEGIN 
  IF SIZE(LONGINT) = 4 THEN
    SYSTEM.PUT(SYSTEM.ADR(l), x); RETURN l
  ELSIF SIZE(INTEGER) = 4 THEN
    SYSTEM.PUT(SYSTEM.ADR(i), x); RETURN i
  ELSE Platform.Halt(-15)
  END
END Int;

(** Convert LONGREAL to hexadecimal. h and l are the high and low parts. *)
PROCEDURE IntL* (x: LONGREAL; VAR h, l: LONGINT);
  VAR i: INTEGER;
BEGIN 
  IF SIZE(LONGINT) = 4 THEN
    SYSTEM.GET(SYSTEM.ADR(x) + H, h); 
    SYSTEM.GET(SYSTEM.ADR(x) + L, l)
  ELSIF SIZE(INTEGER) = 4 THEN
    SYSTEM.GET(SYSTEM.ADR(x) + H, i); h := i; 
    SYSTEM.GET(SYSTEM.ADR(x) + L, i); l := i
  ELSE Platform.Halt(-15)
  END
END IntL;

(** Returns 10^e (e <= 308, 308 < e delivers IEEE-code +INF). *)
PROCEDURE Ten* (e: LONGINT): LONGREAL;
  VAR E: LONGINT; r: LONGREAL;
BEGIN
  IF e < -307 THEN RETURN 0 ELSIF 308 < e THEN RETURN RealL(2146435072, 0) END;
  INC(e, 307); r:= ten[e DIV 23] * tene[e MOD 23];
  IF e MOD 32 IN eq[e DIV 32] THEN RETURN r
  ELSE
    E:= ExpoL(r); SetExpoL(1023+52, r);
    IF e MOD 32 IN gr[e DIV 32] THEN r:= r-1 ELSE r:= r+1 END;
    SetExpoL(E, r); RETURN r
  END
END Ten;

(** Returns the NaN code (0 <= c < 8399608) or -1 if not NaN/Infinite. *)
PROCEDURE NaNCode* (x: REAL): LONGINT;
  VAR e: LONGINT;
BEGIN
  IF Expo(x) = 255 THEN  (* Infinite or NaN *)
    RETURN SYSTEM.VAL(LONGINT, x) MOD 800000H  (* lowest 23 bits *)
  ELSE
    RETURN -1
  END
END NaNCode;

(** Returns the NaN code (0 <= h < 1048576, MIN(LONGINT) <= l <= MAX(LONGINT)) or (-1,-1) if not NaN/Infinite. *)
PROCEDURE NaNCodeL* (x: LONGREAL;  VAR h, l: LONGINT);
BEGIN
  IntL(x, h, l);
  IF ASH(h, -20) MOD 2048 = 2047 THEN  (* Infinite or NaN *)
    h := h MOD 100000H  (* lowest 20 bits *)
  ELSE
    h := -1;  l := -1
  END
END NaNCodeL;

(*
PROCEDURE fcr(): SET;
CODE {SYSTEM.i386, SYSTEM.FPU}
  PUSH 0
  FSTCW [ESP]
  FWAIT
  POP EAX
END fcr;
*) (* commented out -- noch *)
(** Return state of the floating-point control register. *)
(*PROCEDURE FCR*(): SET;
BEGIN
  IF Kernel.copro THEN
    RETURN fcr()
  ELSE
    RETURN DefaultFCR
  END
END FCR;
*)
(*PROCEDURE setfcr(s: SET);
CODE {SYSTEM.i386, SYSTEM.FPU}
  FLDCW s[EBP]
END setfcr;
*)
(** Set state of floating-point control register.  Traps reset this to the default & ENTIER resets the rounding mode. *)
(*PROCEDURE SetFCR*(s: SET);
BEGIN
  IF Kernel.copro THEN setfcr(s) END
END SetFCR;
*)

PROCEDURE RealX (h, l: LONGINT; adr: LONGINT);
BEGIN 
  IF SIZE(LONGINT) = 4 THEN
    SYSTEM.PUT(adr + H, h); SYSTEM.PUT(adr + L, l); 
  ELSIF SIZE(INTEGER) = 4 THEN
    SYSTEM.PUT(adr + H, SYSTEM.VAL(INTEGER, h)); 
    SYSTEM.PUT(adr + L, SYSTEM.VAL(INTEGER, l)); 
  ELSE Platform.Halt(-15)
  END
END RealX;

BEGIN
  RealX(03FF00000H, 000000000H, SYSTEM.ADR(tene[0]));
  RealX(040240000H, 000000000H, SYSTEM.ADR(tene[1]));  (*  1 *)
  RealX(040590000H, 000000000H, SYSTEM.ADR(tene[2]));  (*  2 *)
  RealX(0408F4000H, 000000000H, SYSTEM.ADR(tene[3]));  (*  3 *)
  RealX(040C38800H, 000000000H, SYSTEM.ADR(tene[4]));  (*  4 *)
  RealX(040F86A00H, 000000000H, SYSTEM.ADR(tene[5]));  (*  5 *)
  RealX(0412E8480H, 000000000H, SYSTEM.ADR(tene[6]));  (*  6 *)
  RealX(0416312D0H, 000000000H, SYSTEM.ADR(tene[7]));  (*  7 *)
  RealX(04197D784H, 000000000H, SYSTEM.ADR(tene[8]));  (*  8 *)
  RealX(041CDCD65H, 000000000H, SYSTEM.ADR(tene[9]));  (*  9 *)
  RealX(04202A05FH, 020000000H, SYSTEM.ADR(tene[10])); (* 10 *)
  RealX(042374876H, 0E8000000H, SYSTEM.ADR(tene[11])); (* 11 *)
  RealX(0426D1A94H, 0A2000000H, SYSTEM.ADR(tene[12])); (* 12 *)
  RealX(042A2309CH, 0E5400000H, SYSTEM.ADR(tene[13])); (* 13 *)
  RealX(042D6BCC4H, 01E900000H, SYSTEM.ADR(tene[14])); (* 14 *)
  RealX(0430C6BF5H, 026340000H, SYSTEM.ADR(tene[15])); (* 15 *)
  RealX(04341C379H, 037E08000H, SYSTEM.ADR(tene[16])); (* 16 *)
  RealX(043763457H, 085D8A000H, SYSTEM.ADR(tene[17])); (* 17 *)
  RealX(043ABC16DH, 0674EC800H, SYSTEM.ADR(tene[18])); (* 18 *)
  RealX(043E158E4H, 060913D00H, SYSTEM.ADR(tene[19])); (* 19 *)
  RealX(04415AF1DH, 078B58C40H, SYSTEM.ADR(tene[20])); (* 20 *)
  RealX(0444B1AE4H, 0D6E2EF50H, SYSTEM.ADR(tene[21])); (* 21 *)
  RealX(04480F0CFH, 0064DD592H, SYSTEM.ADR(tene[22])); (* 22 *)
  
  RealX(00031FA18H, 02C40C60DH, SYSTEM.ADR(ten[0]));  (* -307 *)
  RealX(004F7CAD2H, 03DE82D7BH, SYSTEM.ADR(ten[1]));  (* -284 *)
  RealX(009BF7D22H, 08322BAF5H, SYSTEM.ADR(ten[2]));  (* -261 *)
  RealX(00E84D669H, 05B193BF8H, SYSTEM.ADR(ten[3]));  (* -238 *)
  RealX(0134B9408H, 0EEFEA839H, SYSTEM.ADR(ten[4]));  (* -215 *)
  RealX(018123FF0H, 06EEA847AH, SYSTEM.ADR(ten[5]));  (* -192 *)
  RealX(01CD82742H, 091C6065BH, SYSTEM.ADR(ten[6]));  (* -169 *)
  RealX(0219FF779H, 0FD329CB9H, SYSTEM.ADR(ten[7]));  (* -146 *)
  RealX(02665275EH, 0D8D8F36CH, SYSTEM.ADR(ten[8]));  (* -123 *)
  RealX(02B2BFF2EH, 0E48E0530H, SYSTEM.ADR(ten[9]));  (* -100 *)
  RealX(02FF286D8H, 00EC190DCH, SYSTEM.ADR(ten[10])); (*  -77 *)
  RealX(034B8851AH, 00B548EA4H, SYSTEM.ADR(ten[11])); (*  -54 *)
  RealX(0398039D6H, 065896880H, SYSTEM.ADR(ten[12])); (*  -31 *)
  RealX(03E45798EH, 0E2308C3AH, SYSTEM.ADR(ten[13])); (*   -8 *)
  RealX(0430C6BF5H, 026340000H, SYSTEM.ADR(ten[14])); (*   15 *)
  RealX(047D2CED3H, 02A16A1B1H, SYSTEM.ADR(ten[15])); (*   38 *)
  RealX(04C98E45EH, 01DF3B015H, SYSTEM.ADR(ten[16])); (*   61 *)
  RealX(0516078E1H, 011C3556DH, SYSTEM.ADR(ten[17])); (*   84 *)
  RealX(05625CCFEH, 03D35D80EH, SYSTEM.ADR(ten[18])); (*  107 *)
  RealX(05AECDA62H, 0055B2D9EH, SYSTEM.ADR(ten[19])); (*  130 *)
  RealX(05FB317E5H, 0EF3AB327H, SYSTEM.ADR(ten[20])); (*  153 *)
  RealX(064794514H, 05230B378H, SYSTEM.ADR(ten[21])); (*  176 *)
  RealX(06940B8E0H, 0ACAC4EAFH, SYSTEM.ADR(ten[22])); (*  199 *)
  RealX(06E0621B1H, 0C28AC20CH, SYSTEM.ADR(ten[23])); (*  222 *)
  RealX(072CD4A7BH, 0EBFA31ABH, SYSTEM.ADR(ten[24])); (*  245 *)
  RealX(077936214H, 09CBD3226H, SYSTEM.ADR(ten[25])); (*  268 *)
  RealX(07C59A742H, 0461887F6H, SYSTEM.ADR(ten[26])); (*  291 *)

  eq[0]:= {0, 3, 4, 5, 9, 16, 23, 25, 26, 28, 31};
  eq[1]:= {2, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 23, 24, 25, 27, 28, 29, 30, 31};
  eq[2]:= {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28};
  eq[3]:= {0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 14, 15, 16, 17, 18, 19, 20, 22, 27, 28, 29, 30, 31};
  eq[4]:= {0, 6, 7, 10, 11, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31};
  eq[5]:= {0, 1, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31};
  eq[6]:= {0, 1, 4, 5, 7, 8, 10, 14, 15, 16, 18, 20, 21, 23, 24, 25, 26, 28, 29, 30, 31};
  eq[7]:= {0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19, 23, 24, 26, 28, 29, 30, 31};
  eq[8]:= {0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 14, 16, 17, 18, 19, 20, 21, 24, 25, 26, 29};
  eq[9]:= {1, 2, 4, 6, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31};
  eq[10]:= {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30};
  eq[11]:= {0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 14, 15, 16, 19, 20, 21, 22, 23, 27, 28, 29, 30};
  eq[12]:= {0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 12, 14, 15, 16, 17, 18, 19, 20, 21, 23, 26, 27, 29, 30, 31};
  eq[13]:= {0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 13, 14, 15, 16, 17, 18, 20, 21, 23, 24, 27, 28, 29, 30, 31};
  eq[14]:= {0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31};
  eq[15]:= {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 28};
  eq[16]:= {1, 2, 4, 11, 13, 16, 17, 18, 19, 22, 24, 25, 26, 27, 28, 29, 30, 31};
  eq[17]:= {1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 14, 15, 18, 19, 20, 21, 23, 25, 26, 27, 28, 29, 31};
  eq[18]:= {0, 2, 4, 5, 6, 8, 9, 11, 12, 13, 14, 16, 17, 19, 20, 22, 23, 24, 26, 27, 28, 29};
  eq[19]:= {2, 3, 4, 5, 6, 7};

  gr[0]:= {24, 27, 29, 30};
  gr[1]:= {0, 1, 3, 4, 7};
  gr[2]:= {29, 30, 31};
  gr[3]:= {4, 10, 12, 13, 21, 23, 24, 25, 26};
  gr[4]:= {1, 2, 3, 4, 5, 8, 9, 16, 17};
  gr[5]:= {2, 3, 4, 18};
  gr[6]:= {2, 3, 6, 9, 11, 12, 13, 17, 19, 22, 27};
  gr[7]:= {2};
  gr[8]:= {7, 12, 13, 15, 22, 23, 27, 28, 30, 31};
  gr[9]:= {0, 3, 5, 7, 8};
  gr[10]:= {};
  gr[11]:= {};
  gr[12]:= {11, 13, 22, 24, 25, 28};
  gr[13]:= {22, 25, 26};
  gr[14]:= {4, 5};
  gr[15]:= {10, 14, 27, 29, 30, 31};
  gr[16]:= {0, 3, 5, 6, 7, 8, 9, 10, 12, 14, 15, 20, 21, 23};
  gr[17]:= {0, 10, 12, 13, 16, 17, 22, 24, 30};
  gr[18]:= {};
  gr[19]:= {}
END ethReals.
