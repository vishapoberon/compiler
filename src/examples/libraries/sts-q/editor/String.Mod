MODULE String;   (* :file: String.Mod  --  String: Pointer to array of char *)
(* VOC adaptation, 2026-10-16: retain upstream's 32-bit integer contract. *)
IMPORT ssqTypes, Int, Str, Dot;


TYPE    INTEGER = ssqTypes.Integer;
        T* = POINTER TO ARRAY OF CHAR;


(* ------------------------------------------------------------------------- *)
(* :chapter:    CREATE *)
PROCEDURE New* (VAR a: ARRAY OF CHAR): T;       (** return new string from AOC *)
VAR t : T;
BEGIN
   NEW  (t, Str.Length (a) + 1);
   COPY (a, t^);
   RETURN t
END New;

PROCEDURE Create* (a: ARRAY OF CHAR): T;        (** return new string from AOC or char constant *)
BEGIN RETURN New (a) END Create;

PROCEDURE Print* (str: T);                        (** print string *)
BEGIN Dot.Mess (str^) END Print;

PROCEDURE Length* (str: T): INTEGER;            (** RETURN Length of string *)
BEGIN RETURN Str.Length (str^) END Length;


(* ------------------------------------------------------------------------- *)
END String.
(* :file: END (c) sts-q 2024-Feb *)
