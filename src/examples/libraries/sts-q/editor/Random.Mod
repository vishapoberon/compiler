MODULE Random;   (* :file: Random.Mod  --  Random number generator. *)
(* VOC adaptation, 2026-10-16: fixed-width types and the VOC system adapter. *)
IMPORT ssqTypes, Sys := ssqSys, Int;

CONST
        a =      16807;
        m = 2147483647;
TYPE INTEGER = ssqTypes.Integer;

VAR
        seed: Int.T;

PROCEDURE Next*(): Int.T;
(** Return next random number. *)
VAR
   d: Int.T;
BEGIN
   Int.Muldivmod(d,seed, a,seed,m);
   RETURN seed
END Next;

PROCEDURE Roll*(n: INTEGER): INTEGER;
(** Return next random number in a range from 0 to (n-1). *)
BEGIN RETURN ssqTypes.Short (Next() MOD n) END Roll;

PROCEDURE Bool*(): BOOLEAN;
(** Return a random boolean value. *)
BEGIN RETURN ODD(Next()) END Bool;

PROCEDURE Init;
BEGIN seed := Sys.Time() END Init;


BEGIN

   Init;
   
END Random.   :file: (c) sts-q 2022-Okt  2024-Feb
