(* License: GPL-3.0 *)

MODULE Coordinate;
IMPORT Angle, MathE, Epoch, MathL;

TYPE
    Equatorial* = RECORD
        ra*, dec*: LONGREAL;
    END;

    Horizontal* = RECORD
        az*, alt*: LONGREAL;
    END;

    Geographic* = RECORD
        lat*, lon*: LONGREAL;
    END;

    Eclyptic* = RECORD
        lat, lon: LONGREAL;
    END;

    Galactic* = RECORD
        lat, lon: LONGREAL;
    END;

(*
    Mean sidereal time at Greenwich — GMST
    Reference: Meeus, J. — 'Astronomical Algorithms, 1991'
*)
PROCEDURE MeanSiderealTimeGMST(jd: LONGREAL): LONGREAL;
VAR
    T, r: LONGREAL;
BEGIN
    T := (jd - Epoch.J2000)/36525.0D0;
    r := MathE.FMod(280.46061837D0 + 360.98564736629D0 * (jd - Epoch.J2000) +
        (0.000387933D0*T*T) - (T*T*T)/38710000.0D0, 360.0D0);
    IF r < 0.0D0 THEN
        r := r + 360.0D0;
    END;
    RETURN r;
END MeanSiderealTimeGMST;

(*
    Compute horizontal coordinates (azimuth, altitude).
    Reference: Meeus, J. — 'Astronomical Algorithms, 1991'
*)
PROCEDURE ToHorizontal*(jd: LONGREAL; geo: Geographic; eq: Equatorial; VAR hz: Horizontal);
VAR
    mst, H, h, lat, delta, A, sinh: LONGREAL;
BEGIN
    mst := MeanSiderealTimeGMST(jd);
    H := Angle.Radians(mst + geo.lon - eq.ra);
    lat := Angle.Radians(geo.lat);
    delta := Angle.Radians(eq.dec);
    A := Angle.Degrees(MathL.arctan2(MathL.sin(H), MathL.cos(H)*MathL.sin(lat) - MathL.tan(delta)*MathL.cos(lat)));
    sinh := MathL.sin(lat)*MathL.sin(delta) + MathL.cos(lat)*MathL.cos(delta)*MathL.cos(H);
    h := Angle.Degrees(MathL.arcsin(sinh));
    A := MathE.FMod(A + 180.0D0, 360.0D0);
    hz.az := A;
    hz.alt := h;
END ToHorizontal;

END Coordinate.
