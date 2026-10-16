(* License: GPL-3.0 *)

MODULE Precession;
IMPORT Angle, Coordinate, Epoch, MathL;

VAR
    cJD0, cJD, czeta, cz, ctheta: LONGREAL; (* Cache *)

PROCEDURE Compute*(JD0, JD: LONGREAL; VAR zeta, z, theta: LONGREAL);
CONST
    arcsecond = 2.7777777777777777777778D-4;
VAR
    T, TT, t, tt, ttt: LONGREAL;
BEGIN
    IF (JD0 = cJD0) & (JD = cJD) THEN
        (* Using cache *)
        zeta := czeta;
        z := cz;
        theta := ctheta;
        RETURN;
    END;

    T := (JD0 - Epoch.J2000)/36525.0D0;
    t := (JD - JD0)/36525.0D0;
    TT := T*T;
    tt := t*t;
    ttt := tt*t;

    zeta := (2306.2181D0 + 1.39656D0*T - 0.000139D0*TT)*t
    + (0.30188D0 - 0.000344D0*T)*tt
    + 0.017998D0*ttt;

    z := (2306.2181D0 + 1.39656D0*T - 0.000139D0*TT)*t
    + (1.09468D0 + 0.000066D0*T)*tt
    + 0.018203D0*ttt;

    theta := (2004.3109D0 - 0.85330D0*T - 0.000217D0*TT)*t
    - (0.42665D0 + 0.000217D0*T)*tt
    - 0.041833D0*ttt;

    zeta := zeta*arcsecond;
    z := z*arcsecond;
    theta := theta*arcsecond;

    (* Cache *)
    cJD0 := JD0;
    cJD := JD;
    czeta := zeta;
    cz := z;
    ctheta := theta;
END Compute;

(*  Precess equatorial coordinates (α, δ) from inital epoch JD0 to final epoch JD.
    The result is placed on (α1, δ1). All angles are expressed in decimal degrees.
    References: Meeus, J. — 'Astronomical Algorithms, 1991' *)
PROCEDURE Precess*(in: Coordinate.Equatorial; JD0, JD: LONGREAL; VAR out: Coordinate.Equatorial);
VAR
    alpha, delta, alpha1, delta1, zeta, z, theta, A, B, C, alpha2: LONGREAL;
BEGIN
    Compute(JD0, JD, zeta, z, theta);
    zeta := Angle.Radians(zeta);
    z := Angle.Radians(z);
    theta := Angle.Radians(theta);
    alpha := Angle.Radians(in.ra);
    delta := Angle.Radians(in.dec);
    A := MathL.cos(delta)*MathL.sin(alpha + zeta);
    B := MathL.cos(theta)*MathL.cos(delta)*MathL.cos(alpha + zeta) - MathL.sin(theta)*MathL.sin(delta);
    C := MathL.sin(theta)*MathL.cos(delta)*MathL.cos(alpha + zeta) + MathL.cos(theta)*MathL.sin(delta);
    alpha2 := Angle.Degrees(MathL.arctan2(A, B) + z);

    IF alpha2 < 0.0 THEN
        alpha2 := alpha2 + 360.0D0;
    END;

    out.ra := alpha2;
    out.dec := Angle.Degrees(MathL.arcsin(C));
END Precess;

END Precession.
