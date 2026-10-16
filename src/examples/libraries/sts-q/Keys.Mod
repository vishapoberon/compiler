MODULE Keys;
(* GPL-3.0. Demonstrating sts-q's terminal key and mouse decoder. *)
IMPORT Kbd, Sys := ssqSys;
VAR key: Kbd.KEY; description: ARRAY 64 OF CHAR;
BEGIN
  Sys.XtermAlt;
  Sys.Out('Press keys; Escape or q exits. Set PETMOUSE=true for mouse events.');
  Sys.OutChr(0AX);
  REPEAT
    key := Kbd.GetKey();
    Kbd.ShowKey(description, key); Sys.Out(description); Sys.OutChr(0AX)
  UNTIL (key = Kbd.Escape) OR (key = Kbd.AKey(0, 'q'));
  Sys.XtermStd
END Keys.
