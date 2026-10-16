(* License: GPL-3.0 *)

MODULE MathE;
IMPORT MathL;

PROCEDURE FMod*(x, y: LONGREAL): LONGREAL;
BEGIN
    RETURN x - LONG(ENTIER(x/y)) * y;
END FMod;

(*  FCmp
    This function determines whether `x` and `y` are approximately equal to a relative accuracy `epsilon`.

    References:
    The implementation is based on the GNU Scientific Library (GSL).
    https://www.gnu.org/software/gsl/doc/html/math.html#approximate-comparison-of-floating-point-numbers
*)
PROCEDURE FCmp*(x, y, epsilon: LONGREAL): INTEGER;
VAR
    max, exponent, delta, difference: LONGREAL;
BEGIN
    IF ABS(x) > ABS(y) THEN
        max := x;
    ELSE
        max := y;
    END;

    exponent := MathL.exponent(max);
    delta := 2.0D0*epsilon*MathL.power(2.0D0, exponent);
    difference := x - y;

    IF difference > delta THEN
        RETURN 1;
    ELSIF difference < -delta THEN
        RETURN -1;
    ELSE
        RETURN 0; (* approximately equal *)
    END;
END FCmp;

END MathE.
