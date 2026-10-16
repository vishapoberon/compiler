(* License: GPL-3.0 *)

MODULE Star;
IMPORT Out, opts, Coordinate, Epoch, Precession, Nutation, ethStrings,
  JulianDay, Platform;

VAR
    jd: LONGREAL;
    seconds, microseconds: LONGINT;
    eq, eqPrec: Coordinate.Equatorial;
    geo: Coordinate.Geographic;
    hz: Coordinate.Horizontal;

(* Process command options *)
PROCEDURE processOptions(VAR geo: Coordinate.Geographic; VAR eq: Coordinate.Equatorial);
VAR
    options : opts.Options;
    foptions : opts.Options;
    opt : opts.Option;
    lat, lon, ra, dec: ARRAY 10 OF CHAR;
BEGIN
    options := opts.createOptions();
    foptions := opts.createOptions();

    opt := opts.createOpt();
    opts.setOptName(opt, "-l");
    opts.setOptHasVal(opt, TRUE);
    opts.setOptRequired(opt, TRUE);
    opts.setOptLName(opt, "--lat");
    opts.setOptDesc(opt, "Latitude");
    options.add(options, opt);

    opt := opts.createOpt();
    opts.setOptName(opt, "-o");
    opts.setOptHasVal(opt, TRUE);
    opts.setOptRequired(opt, TRUE);
    opts.setOptLName(opt, "--lon");
    opts.setOptDesc(opt, "Longitude");
    options.add(options, opt);

    opt := opts.createOpt();
    opts.setOptName(opt, "-r");
    opts.setOptHasVal(opt, TRUE);
    opts.setOptRequired(opt, TRUE);
    opts.setOptLName(opt, "--ra");
    opts.setOptDesc(opt, "Right ascension (J2000)");
    options.add(options, opt);

    opt := opts.createOpt();
    opts.setOptName(opt, "-d");
    opts.setOptHasVal(opt, TRUE);
    opts.setOptRequired(opt, TRUE);
    opts.setOptLName(opt, "--dec");
    opts.setOptDesc(opt, "Declination (J2000)");
    options.add(options, opt);

    foptions := opts.populateOptions(options);

    IF ~opts.reqsSatisfied(options, foptions) THEN
        Out.String("Required options not provided.");
        Out.Ln;
        HALT(1);
    END;

    opts.valOfOpt("-l", foptions, lat);
    opts.valOfOpt("-o", foptions, lon);
    opts.valOfOpt("-r", foptions, ra);
    opts.valOfOpt("-d", foptions, dec);

    ethStrings.StrToReal(lat, geo.lat);
    ethStrings.StrToReal(lon, geo.lon);
    ethStrings.StrToReal(ra, eq.ra);
    ethStrings.StrToReal(dec, eq.dec);
END processOptions;

BEGIN
    (* Read command line options *)
    processOptions(geo, eq);

    (* Compute *)
    Platform.GetTimeOfDay(seconds, microseconds);
    jd := JulianDay.DateToJD(1, 1, 1970) +
      (seconds + microseconds / 1000000.0D0) / 86400.0D0;
    Precession.Precess(eq, Epoch.J2000, jd, eqPrec);
    Nutation.Nutate(eqPrec, jd, eq);
    Coordinate.ToHorizontal(jd, geo, eq, hz);

    (* Display *)
    Out.String("Azimuth:");
    Out.Int(ENTIER(hz.az), 1);
    Out.String("° ±1°");
    Out.Ln;
    Out.String("Altitude:");
    Out.Int(ENTIER(hz.alt), 1);
    Out.String("° ±1°");
    Out.Ln;
END Star.
