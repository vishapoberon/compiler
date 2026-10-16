MODULE ssqTypes;
  (* VOC adaptation, 2026-10-16. Upstream uses -OC: retain its 32/64-bit
     scalar contract in both VOC type models. GPL-3.0; see LICENSE. *)
  IMPORT SYSTEM;
  TYPE Integer* = SYSTEM.INT32; Longint* = SYSTEM.INT64;
  PROCEDURE Short*(value: Longint): Integer;
  BEGIN
    ASSERT((value >= MIN(Integer)) & (value <= MAX(Integer)));
    RETURN SHORT(value)
  END Short;
END ssqTypes.
