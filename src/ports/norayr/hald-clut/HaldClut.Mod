MODULE HaldClut;

TYPE Coordinate = RECORD low, high, fraction: LONGINT END;

PROCEDURE CubeRange*(width, height: LONGINT): LONGINT;
VAR count, range: LONGINT;
BEGIN
  IF (width <= 0) OR (height <= 0) OR (width > MAX(LONGINT) DIV height) THEN RETURN 0 END;
  count := width * height; range := 2;
  WHILE range <= count DIV range DIV range DO
    IF range * range * range = count THEN RETURN range END;
    INC(range)
  END;
  RETURN 0
END CubeRange;

PROCEDURE Apply*(source-, lut-: ARRAY OF CHAR; range: LONGINT; VAR target: ARRAY OF CHAR);
VAR coordinates: ARRAY 256 OF Coordinate; value, scaled, count: LONGINT;
BEGIN
  ASSERT((LEN(source) <= MAX(LONGINT)) & (LEN(lut) <= MAX(LONGINT)));
  ASSERT((range >= 2) & (range <= (LEN(lut) DIV 4) DIV range DIV range));
  ASSERT((LEN(lut) MOD 4 = 0) & (range * range * range = LEN(lut) DIV 4));
  ASSERT((LEN(source) MOD 4 = 0) & (LEN(target) >= LEN(source)));
  FOR value := 0 TO 255 DO
    scaled := value * (range-1);
    coordinates[value].low := scaled DIV 255;
    coordinates[value].fraction := scaled MOD 255;
    coordinates[value].high := coordinates[value].low;
    IF coordinates[value].high < range-1 THEN INC(coordinates[value].high) END
  END;
  count := LEN(source) DIV 4;
  ALL i = 0 .. count-1 WITH
    r, g, b, fr, fg, fb, rr, rg, rb: LONGINT;
    p000, p100, p010, p110, p001, p101, p011, p111: LONGINT;
    c00, c01, c10, c11, c0, c1: LONGINT
  DO
    r := ORD(source[4*i]); g := ORD(source[4*i+1]); b := ORD(source[4*i+2]);
    fr := coordinates[r].fraction; fg := coordinates[g].fraction; fb := coordinates[b].fraction;
    rr := 255-fr; rg := 255-fg; rb := 255-fb;
    p000 := 4 * (coordinates[r].low + range * (coordinates[g].low + range * coordinates[b].low));
    p100 := 4 * (coordinates[r].high + range * (coordinates[g].low + range * coordinates[b].low));
    p010 := 4 * (coordinates[r].low + range * (coordinates[g].high + range * coordinates[b].low));
    p110 := 4 * (coordinates[r].high + range * (coordinates[g].high + range * coordinates[b].low));
    p001 := 4 * (coordinates[r].low + range * (coordinates[g].low + range * coordinates[b].high));
    p101 := 4 * (coordinates[r].high + range * (coordinates[g].low + range * coordinates[b].high));
    p011 := 4 * (coordinates[r].low + range * (coordinates[g].high + range * coordinates[b].high));
    p111 := 4 * (coordinates[r].high + range * (coordinates[g].high + range * coordinates[b].high));
    c00 := (ORD(lut[p000])*rr + ORD(lut[p100])*fr + 127) DIV 255;
    c01 := (ORD(lut[p010])*rr + ORD(lut[p110])*fr + 127) DIV 255;
    c10 := (ORD(lut[p001])*rr + ORD(lut[p101])*fr + 127) DIV 255;
    c11 := (ORD(lut[p011])*rr + ORD(lut[p111])*fr + 127) DIV 255;
    c0 := (c00*rg + c01*fg + 127) DIV 255; c1 := (c10*rg + c11*fg + 127) DIV 255;
    target[4*i] := CHR((c0*rb + c1*fb + 127) DIV 255);
    c00 := (ORD(lut[p000+1])*rr + ORD(lut[p100+1])*fr + 127) DIV 255;
    c01 := (ORD(lut[p010+1])*rr + ORD(lut[p110+1])*fr + 127) DIV 255;
    c10 := (ORD(lut[p001+1])*rr + ORD(lut[p101+1])*fr + 127) DIV 255;
    c11 := (ORD(lut[p011+1])*rr + ORD(lut[p111+1])*fr + 127) DIV 255;
    c0 := (c00*rg + c01*fg + 127) DIV 255; c1 := (c10*rg + c11*fg + 127) DIV 255;
    target[4*i+1] := CHR((c0*rb + c1*fb + 127) DIV 255);
    c00 := (ORD(lut[p000+2])*rr + ORD(lut[p100+2])*fr + 127) DIV 255;
    c01 := (ORD(lut[p010+2])*rr + ORD(lut[p110+2])*fr + 127) DIV 255;
    c10 := (ORD(lut[p001+2])*rr + ORD(lut[p101+2])*fr + 127) DIV 255;
    c11 := (ORD(lut[p011+2])*rr + ORD(lut[p111+2])*fr + 127) DIV 255;
    c0 := (c00*rg + c01*fg + 127) DIV 255; c1 := (c10*rg + c11*fg + 127) DIV 255;
    target[4*i+2] := CHR((c0*rb + c1*fb + 127) DIV 255);
    target[4*i+3] := source[4*i+3]
  END
END Apply;

END HaldClut.
