MODULE TestCKeywords;
  IMPORT Out;
  TYPE Keywords = RECORD
    bool, true, false, nullptr, alignas, alignof, constexpr, typeof,
    inline, restrict: LONGINT
  END;

  PROCEDURE Check(bool, true, false, nullptr, alignas, alignof, constexpr,
    typeof, inline, restrict: LONGINT);
    VAR value: Keywords;
  BEGIN
    value.bool := bool; value.true := true; value.false := false;
    value.nullptr := nullptr; value.alignas := alignas; value.alignof := alignof;
    value.constexpr := constexpr; value.typeof := typeof;
    value.inline := inline; value.restrict := restrict;
    ASSERT(value.bool + value.true + value.false + value.nullptr + value.alignas +
      value.alignof + value.constexpr + value.typeof + value.inline + value.restrict = 55)
  END Check;

BEGIN
  Check(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
  Out.String("C keyword tests passed"); Out.Ln
END TestCKeywords.
