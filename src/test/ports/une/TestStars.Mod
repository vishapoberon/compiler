MODULE TestStars;
IMPORT Angle, MathE, Epoch, Coordinate, Precession, Nutation, JulianDay, Out;
VAR y: INTEGER; mo, d: SHORTINT; longitude, obliquity, ecliptic: LONGREAL;
  original, result: Coordinate.Equatorial;
  geo: Coordinate.Geographic; horizontal: Coordinate.Horizontal;
BEGIN
  ASSERT(ABS(Angle.Degrees(Angle.Radians(180)) - 180) < 0.000001);
  ASSERT(MathE.FMod(725, 360) = 5);
  ASSERT(JulianDay.DateToJD(1, 1, 1970) = 2440587.5D0);
  ASSERT(JulianDay.DateToJD(1, 1, 2000) + 0.5D0 = Epoch.J2000);
  JulianDay.JDToDate(Epoch.J2000, d, mo, y);
  ASSERT((y = 2000) & (mo = 1) & (d = 1));
  JulianDay.JDToDate(JulianDay.DateToJD(1, 1, 2040), d, mo, y);
  ASSERT((y = 2040) & (mo = 1) & (d = 1));
  original.ra := 88.792939D0; original.dec := 7.407064D0;
  Precession.Precess(original, Epoch.J2000, Epoch.J2000, result);
  ASSERT(ABS(result.ra - original.ra) < 0.000001);
  ASSERT(ABS(result.dec - original.dec) < 0.000001);
  Nutation.Compute(2446895.5D0, longitude, obliquity, ecliptic);
  (* The upstream approximation retains only the largest nutation terms. *)
  ASSERT(ABS(longitude + 0.0010522D0) < 0.00005);
  ASSERT(ABS(obliquity - 0.0026229D0) < 0.00005);
  ASSERT((ecliptic > 23) & (ecliptic < 24));
  Nutation.Nutate(original, Epoch.J2000, result);
  ASSERT(ABS(result.ra - original.ra) < 0.1);
  ASSERT(ABS(result.dec - original.dec) < 0.1);
  geo.lat := 51.5; geo.lon := 0.13;
  Coordinate.ToHorizontal(Epoch.J2000, geo, original, horizontal);
  ASSERT((horizontal.az >= 0) & (horizontal.az < 360));
  ASSERT((horizontal.alt >= -90) & (horizontal.alt <= 90));
  Out.String("star-coordinate and Julian-date checks passed"); Out.Ln
END TestStars.
