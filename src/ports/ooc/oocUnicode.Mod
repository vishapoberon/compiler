MODULE oocUnicode;

TYPE
  (* VOC and standard Oberon-2 have no built-in LONGCHAR type, so we
     define it here. It represents one UTF-16 code unit (0..65535),
     stored in a LONGINT to preserve the entire unsigned 16-bit range
     under -O2. Supplementary characters use two surrogate code units.
     Character values must remain in this range despite the wider storage. *)
  LONGCHAR* = LONGINT;

END oocUnicode.
