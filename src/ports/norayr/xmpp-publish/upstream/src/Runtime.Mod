MODULE Runtime [INTERFACE "C"];
(*  Thin bindings to a few C standard library functions. *)

IMPORT C, SYSTEM;

PROCEDURE getenv* (name: C.string): C.string;
PROCEDURE atoi* (s: C.string): C.int;

(* time.h *)
PROCEDURE time* (tloc: SYSTEM.ADDRESS): HUGEINT;
PROCEDURE gmtime_r* (timep, result: SYSTEM.ADDRESS): SYSTEM.ADDRESS;

END Runtime.
