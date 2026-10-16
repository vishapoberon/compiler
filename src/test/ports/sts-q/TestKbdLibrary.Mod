MODULE TestKbdLibrary;
IMPORT SYSTEM, Kbd, Out;
VAR key, button, row, col: Kbd.KEY; a: ARRAY 64 OF CHAR;
BEGIN
  ASSERT(SIZE(Kbd.KEY) = 4); ASSERT(SIZE(Kbd.KEY) = SIZE(SYSTEM.INT32));
  ASSERT(Kbd.AKey(Kbd.Ctrl, 'A') = 1);
  ASSERT(Kbd.AKey(Kbd.CM, 'A') = Kbd.Meta + 1);
  key := Kbd.AKey(Kbd.Meta, 'z'); ASSERT(Kbd.IsAKey(key)); ASSERT(Kbd.Chr(key) = 'z');
  Kbd.ShowKey(a, key); ASSERT(a = '<M-z>');
  Kbd.ShowKey(a, Kbd.Enter); ASSERT(a = '<Enter>');
  Kbd.ShowKey(a, Kbd.Tab); ASSERT(a = '<Tab>');
  Kbd.ShowKey(a, Kbd.Backspace); ASSERT(a = '<Backspace>');
  Kbd.ShowKey(a, 1); ASSERT(a = '<C-A>');
  key := Kbd.FKey(Kbd.CM, Kbd.Up); ASSERT(Kbd.IsFKey(key));
  ASSERT(Kbd.Fun(key) = Kbd.Up); Kbd.ShowKey(a, key); ASSERT(a = '<CM-Up>');
  key := Kbd.MKey(Kbd.Ctrl, Kbd.B1, 12, 34);
  ASSERT(Kbd.IsMKey(key)); ASSERT(Kbd.MouseKey(key) = Kbd.B1);
  Kbd.Mouse(button, row, col, key);
  ASSERT((button = Kbd.B1) & (row = 12) & (col = 34));
  Kbd.ShowKey(a, key); ASSERT(a = '<C-B1-12-34>');
  key := Kbd.MKey(Kbd.sCM + Kbd.Drag, Kbd.B5up, 255, 255);
  Kbd.ShowKey(a, key); ASSERT(a = '<sCMD-B5up-255-255>');
  Out.String('standalone Kbd library tests passed'); Out.Ln
END TestKbdLibrary.
