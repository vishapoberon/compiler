(* License: GPL-3.0 *)

MODULE Nutation;
IMPORT Angle, Coordinate, Epoch, MathL;

VAR
    cJD, clongitude, cobliquity, cecliptic: LONGREAL; (* Cache *)

(* Compute the nutation in longitude, the nutation in obliquity and the true
   obliquity of the ecliptic for the given Julian Date.
   References: Meeus, J. — 'Astronomical Algorithms, 1991' *)
PROCEDURE Compute*(jd: LONGREAL; VAR longitude, obliquity, ecliptic: LONGREAL);
VAR
    T, TT, TTT, Omega, Omega2, L2, Lp2, deltaPsi, deltaEpsilon, Epsilon0: LONGREAL;
BEGIN
    IF jd = cJD THEN
        (* Retrieve cache *)
        longitude := clongitude;
        obliquity := cobliquity;
        ecliptic := cecliptic;
        RETURN;
    END;

    T := (jd - Epoch.J2000)/36525.0D0;
    TT := T*T;
    TTT := TT*T;
    Omega := Angle.Radians(125.04452D0 - 1934.136261D0*T + 0.0020708D0*TT + TTT/450000.0D0);
    Omega2 := 2.0D0*Omega;
    L2 := 2.0D0*Angle.Radians(280.4665D0 + 36000.7698D0*T);
    Lp2 := 2.0D0*Angle.Radians(218.3165D0 + 481267.8813D0*T);

    (* Δψ := nutation in longitude *)
    (* Δψ := -17".20*sin(Ω) - 1".32*sin(2L) - 0".23*sin(2Lp) + 0".21*sin(2Ω); *)
    deltaPsi := -4.7777777777777775D-3 * MathL.sin(Omega)
    - 3.6666666666666667D-4 * MathL.sin(L2)
    - 6.38888888888889D-5 * MathL.sin(Lp2)
    + 5.833333333333333D-5 * MathL.sin(Omega2);

    (* Δε := nutation in obliquity *)
    (* Δε := 9".20*cos(Ω) + 0".57*cos(2L) + 0".1*cos(2Lp) - 0".09*cos(2Ω); *)
    deltaEpsilon := 2.5555555555555553D-3 * MathL.cos(Omega)
    + 1.5833333333333332D-4 * MathL.cos(L2)
    + 2.777777777777778D-5 * MathL.cos(Lp2)
    - 2.5D-5 * MathL.cos(Omega2);

    (* ε0 := mean obliquity of the ecliptic *)
    (* ε0 := 23°26'21".488 - 46".815*T - 0".00059*T² + 0".001813*T³; *)
    Epsilon0 := 23.43929111111111D0
    - 0.013004166666666666D0*T
    - 1.638888888888889D-7*TT
    + 5.036111111111111D-7*TTT;

    (* ε := true obliquity of the ecliptic *)
    (* ε := ε0 + Δε *)
    longitude := deltaPsi;
    obliquity := deltaEpsilon;
    ecliptic := Epsilon0 + deltaEpsilon;

    (* Save cache *)
    cJD := jd;
    clongitude := longitude;
    cobliquity := obliquity;
    cecliptic := ecliptic;
END Compute;

(* Apply the effects of nutation to the given equatorial coordinates.
   References: Meeus, J. — 'Astronomical Algorithms, 1991' *)
PROCEDURE Nutate*(in: Coordinate.Equatorial; jd: LONGREAL; VAR out: Coordinate.Equatorial);
VAR
    ra, dec, deltaPsi, deltaEpsilon, Epsilon, da, dd, longitude, obliquity, ecliptic: LONGREAL;
BEGIN
    Compute(jd, longitude, obliquity, ecliptic);
    ra := Angle.Radians(in.ra);
    dec := Angle.Radians(in.dec);
    deltaPsi := Angle.Radians(longitude);
    deltaEpsilon := Angle.Radians(obliquity);
    Epsilon := Angle.Radians(ecliptic);
    da := (MathL.cos(Epsilon)+MathL.sin(Epsilon)*MathL.sin(ra)*MathL.tan(dec))*deltaPsi - (MathL.cos(ra)*MathL.tan(dec))*deltaEpsilon;
    dd := (MathL.sin(Epsilon)*MathL.cos(ra))*deltaPsi + MathL.sin(ra)*deltaEpsilon;
    out.ra := Angle.Degrees(ra + da);
    out.dec := Angle.Degrees(dec + dd);
END Nutate;

END Nutation.
