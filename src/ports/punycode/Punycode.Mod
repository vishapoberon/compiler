MODULE Punycode;

(* RFC 3492 scalar codec, extracted from agena's encoder and extended with
   checked arithmetic, decoding and explicit buffer lengths. See LICENSE. *)

CONST
  done* = 0; invalid* = 1; noRoom* = 2; overflow* = 3;
  maxScalars* = 1024;

PROCEDURE Scalar*(character: LONGINT): BOOLEAN;
BEGIN
  RETURN (character >= 0) & (character <= 10FFFFH) &
    ((character < 0D800H) OR (character > 0DFFFH))
END Scalar;

PROCEDURE Digit(value: LONGINT): CHAR;
BEGIN
  IF value < 26 THEN RETURN CHR(ORD("a") + value) END;
  RETURN CHR(ORD("0") + value - 26)
END Digit;

PROCEDURE Value(character: CHAR): LONGINT;
BEGIN
  IF (character >= "a") & (character <= "z") THEN RETURN ORD(character)-ORD("a") END;
  IF (character >= "A") & (character <= "Z") THEN RETURN ORD(character)-ORD("A") END;
  IF (character >= "0") & (character <= "9") THEN RETURN ORD(character)-ORD("0")+26 END;
  RETURN -1
END Value;

PROCEDURE Adapt(delta, points: LONGINT; first: BOOLEAN): LONGINT;
  VAR k: LONGINT;
BEGIN
  IF first THEN delta := delta DIV 700 ELSE delta := delta DIV 2 END;
  delta := delta + delta DIV points; k := 0;
  WHILE delta > 455 DO delta := delta DIV 35; INC(k, 36) END;
  RETURN k + 36 * delta DIV (delta + 38)
END Adapt;

PROCEDURE Threshold(k, bias: LONGINT): LONGINT;
BEGIN
  IF k <= bias THEN RETURN 1 END;
  IF k >= bias + 26 THEN RETURN 26 END;
  RETURN k-bias
END Threshold;

PROCEDURE Encode*(input: ARRAY OF LONGINT; count: LONGINT; VAR output: ARRAY OF CHAR;
                  VAR written, result: LONGINT);
  VAR i, basic, handled, character, minimum, delta, bias, q, k, t, length: LONGINT;

  PROCEDURE Put(byte: CHAR): BOOLEAN;
  BEGIN
    IF length >= LEN(output)-1 THEN RETURN FALSE END;
    output[length] := byte; INC(length); RETURN TRUE
  END Put;

BEGIN
  written := 0; result := invalid; length := 0;
  IF LEN(output) = 0 THEN result := noRoom; RETURN END;
  output[0] := 0X;
  IF (count < 0) OR (count > LEN(input)) OR (count > maxScalars) THEN RETURN END;
  FOR i := 0 TO count-1 DO IF ~Scalar(input[i]) THEN RETURN END END;
  basic := 0;
  FOR i := 0 TO count-1 DO
    IF input[i] < 128 THEN
      IF ~Put(CHR(input[i])) THEN result := noRoom; output[0] := 0X; RETURN END;
      INC(basic)
    END
  END;
  IF (basic > 0) & ~Put("-") THEN result := noRoom; output[0] := 0X; RETURN END;
  character := 128; delta := 0; bias := 72; handled := basic;
  WHILE handled < count DO
    minimum := MAX(LONGINT);
    FOR i := 0 TO count-1 DO
      IF (input[i] >= character) & (input[i] < minimum) THEN minimum := input[i] END
    END;
    IF minimum-character > (MAX(LONGINT)-delta) DIV (handled+1) THEN
      result := overflow; output[0] := 0X; RETURN
    END;
    INC(delta, (minimum-character)*(handled+1)); character := minimum;
    FOR i := 0 TO count-1 DO
      IF input[i] < character THEN
        IF delta = MAX(LONGINT) THEN result := overflow; output[0] := 0X; RETURN END;
        INC(delta)
      ELSIF input[i] = character THEN
        q := delta; k := 36;
        LOOP
          t := Threshold(k, bias);
          IF q < t THEN EXIT END;
          IF ~Put(Digit(t + (q-t) MOD (36-t))) THEN result := noRoom; output[0] := 0X; RETURN END;
          q := (q-t) DIV (36-t); INC(k, 36)
        END;
        IF ~Put(Digit(q)) THEN result := noRoom; output[0] := 0X; RETURN END;
        bias := Adapt(delta, handled+1, handled = basic); delta := 0; INC(handled)
      END
    END;
    IF delta = MAX(LONGINT) THEN result := overflow; output[0] := 0X; RETURN END;
    INC(delta); INC(character)
  END;
  output[length] := 0X; written := length; result := done
END Encode;

PROCEDURE Decode*(input: ARRAY OF CHAR; length: LONGINT; VAR output: ARRAY OF LONGINT;
                  VAR count, result: LONGINT);
  VAR values: ARRAY maxScalars OF LONGINT;
    i, delimiter, position, character, bias, old, index, weight, digit, k, t, size, j: LONGINT;
BEGIN
  count := 0; result := invalid;
  IF (length < 0) OR (length > LEN(input)) OR (length > 16*maxScalars) THEN RETURN END;
  delimiter := -1;
  FOR i := 0 TO length-1 DO
    IF ORD(input[i]) >= 128 THEN RETURN END;
    IF input[i] = "-" THEN delimiter := i END
  END;
  size := 0;
  IF delimiter >= 0 THEN
    IF delimiter > maxScalars THEN result := noRoom; RETURN END;
    FOR i := 0 TO delimiter-1 DO values[size] := ORD(input[i]); INC(size) END;
    position := delimiter+1
  ELSE position := 0
  END;
  character := 128; index := 0; bias := 72;
  WHILE position < length DO
    old := index; weight := 1; k := 36;
    LOOP
      IF position >= length THEN RETURN END;
      digit := Value(input[position]); INC(position);
      IF digit < 0 THEN RETURN END;
      IF digit > (MAX(LONGINT)-index) DIV weight THEN result := overflow; RETURN END;
      INC(index, digit*weight); t := Threshold(k, bias);
      IF digit < t THEN EXIT END;
      IF weight > MAX(LONGINT) DIV (36-t) THEN result := overflow; RETURN END;
      weight := weight*(36-t); INC(k, 36)
    END;
    IF size = maxScalars THEN result := noRoom; RETURN END;
    bias := Adapt(index-old, size+1, old = 0);
    IF index DIV (size+1) > 10FFFFH-character THEN RETURN END;
    INC(character, index DIV (size+1)); index := index MOD (size+1);
    IF ~Scalar(character) THEN RETURN END;
    j := size;
    WHILE j > index DO values[j] := values[j-1]; DEC(j) END;
    values[index] := character; INC(size); INC(index)
  END;
  IF size > LEN(output) THEN result := noRoom; RETURN END;
  FOR i := 0 TO size-1 DO output[i] := values[i] END;
  count := size; result := done
END Decode;

END Punycode.
