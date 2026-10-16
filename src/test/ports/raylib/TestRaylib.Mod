MODULE TestRaylib;
IMPORT Raylib, Out;
VAR color: Raylib.TColor; first, value, i: LONGINT; varied: BOOLEAN;
BEGIN
  (* These raylib calls require no window, graphics context or input device. *)
  Raylib.GetColor({8, 9, 12, 13, 14, 17, 20, 21, 22, 24, 27, 28}, color);
  ASSERT((ORD(color.r) = 19H) & (ORD(color.g) = 72H));
  ASSERT((ORD(color.b) = 73H) & (ORD(color.a) = 0));
  Raylib.GetColor({}, color);
  ASSERT((ORD(color.r) = 0) & (ORD(color.g) = 0) & (ORD(color.b) = 0) & (ORD(color.a) = 0));
  Raylib.SetRandomSeed(1234); first := Raylib.GetRandomValue(0, 600);
  ASSERT((first >= 0) & (first <= 600));
  varied := FALSE;
  FOR i := 0 TO 100 DO
    value := Raylib.GetRandomValue(0, 600);
    ASSERT((value >= 0) & (value <= 600));
    IF value # first THEN varied := TRUE END
  END;
  ASSERT(varied);
  Raylib.SetRandomSeed(1234); ASSERT(Raylib.GetRandomValue(0, 600) = first);
  Out.String("headless raylib binding checks passed"); Out.Ln
END TestRaylib.
