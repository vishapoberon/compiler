(* License: GPL-3.0 *)

MODULE Angle;
IMPORT MathL;

(* Convert the angle `a` from radians to degrees. *)
PROCEDURE Degrees*(a: LONGREAL): LONGREAL;
BEGIN
    RETURN a * 180.0D0/MathL.pi;
END Degrees;

(* Convert the angle `a` from degrees to radians. *)
PROCEDURE Radians*(a: LONGREAL): LONGREAL;
BEGIN
    RETURN a * MathL.pi/180.0D0;
END Radians;

END Angle.
