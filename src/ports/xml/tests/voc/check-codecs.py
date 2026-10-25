"""Replay the preserved upstream codec hex vectors in a generated VOC program."""

import argparse
import ast
from pathlib import Path
import re
import shlex
import subprocess


HARNESS = '''MODULE TestCodecVectors;
IMPORT Out, UC := XMLUnicodeCodec, XMLUnicodeCodecImportAll;
VAR count: LONGINT;

PROCEDURE Hex(ch: CHAR): LONGINT;
BEGIN
  IF (ch >= "0") & (ch <= "9") THEN RETURN ORD(ch)-ORD("0") END;
  RETURN ORD(CAP(ch))-ORD("A")+10
END Hex;

PROCEDURE Check(encoding, source, expected: ARRAY OF CHAR; encode, bom: BOOLEAN; errors: LONGINT);
  VAR input, output, reference: ARRAY 256 OF CHAR;
    units, decoded, wanted: ARRAY 256 OF UC.Char;
    codec: UC.Codec; factory: UC.Factory;
    sourceLength, expectedLength, n, i, start, done, written, limit, window, pass: LONGINT;

  PROCEDURE Parse(text: ARRAY OF CHAR; width: LONGINT; source: BOOLEAN): LONGINT;
    VAR i, digits, value, n: LONGINT;
  BEGIN
    i := 0; digits := 0; value := 0; n := 0;
    WHILE text[i] # 0X DO
      IF text[i] # " " THEN
        value := value*16+Hex(text[i]); INC(digits);
        IF digits = width THEN
          IF source THEN
            IF encode THEN units[n] := value ELSE input[n] := CHR(value) END
          ELSE
            IF encode THEN reference[n] := CHR(value) ELSE wanted[n] := value END
          END;
          INC(n); value := 0; digits := 0
        END
      END;
      INC(i)
    END;
    ASSERT(digits = 0, 1); RETURN n
  END Parse;

BEGIN
  factory := UC.GetFactory(encoding); ASSERT(factory # NIL, 2);
  IF encode THEN sourceLength := Parse(source, 4, TRUE); expectedLength := Parse(expected, 2, FALSE)
  ELSE sourceLength := Parse(source, 2, TRUE); expectedLength := Parse(expected, 4, FALSE)
  END;
  FOR pass := 0 TO 1 DO
    start := 0; written := 0;
    IF encode THEN
      codec := factory.NewCodec();
      IF bom THEN codec.EncodeBOM(output, 0, LEN(output), written) END;
      window := UC.maxUTF8EncodingLength
    ELSE
      IF bom THEN codec := factory.NewCodecBOM(input, 0, sourceLength, start)
      ELSE codec := factory.NewCodec()
      END;
      window := UC.maxUCS2EncodingLength
    END;
    IF pass = 0 THEN window := 128 END;
    WHILE start < sourceLength DO
      limit := written+window;
      IF encode THEN
        codec.Encode(units, start, sourceLength, output, written, limit, done, n)
      ELSE
        codec.Decode(input, start, sourceLength, decoded, written, limit, done, n)
      END;
      ASSERT((done > start) & (done <= sourceLength) & (n > written) & (n <= limit), 3);
      start := done; written := n
    END;
    IF (written # expectedLength) OR (codec.invalidChars # errors) THEN
      Out.String(encoding); Out.String(" vector "); Out.Int(count, 0); Out.String(": ");
      Out.String(source); Out.Ln
    END;
    ASSERT((written = expectedLength) & (codec.invalidChars = errors), 4);
    FOR i := 0 TO expectedLength-1 DO
      IF encode THEN ASSERT(output[i] = reference[i], 5)
      ELSE ASSERT(decoded[i] = wanted[i], 6)
      END
    END
  END;
  INC(count)
END Check;

BEGIN
  count := 0;
@CASES@
  Out.Int(count, 0); Out.String(" original codec vectors passed (full and bounded output)"); Out.Ln
END TestCodecVectors.
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--voc", default="voc")
    parser.add_argument("--flags", default="-O2 -s -F")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    original = (root / "tests/upstream/TestCodecs.Mod").read_text().split("BEGIN\n  (* LATIN1 *)", 1)[1]
    constants = {"errorEncode": "3F", "errorDecode": "FFFD"}
    factories = {"Latin1.factory": "LATIN1", "ASCII.factory": "ASCII",
                 "UTF8.factory": "UTF-8", "UTF16.factory": "UTF-16",
                 "UTF16.factoryBE": "UTF-16BE", "UTF16.factoryLE": "UTF-16LE"}

    def expression(text):
        return ''.join(ast.literal_eval(part.strip()) if part.strip().startswith('"')
                       else constants[part.strip()] for part in text.split('+'))

    calls = []
    pattern = r'(Encode|Decode)\s*\((\w+\.factory(?:BE|LE)?),\s*(.*?),\s*(.*?),\s*(TRUE|FALSE),\s*(\d+)\)'
    for direction, factory, source, expected, bom, errors in re.findall(pattern, original, re.S):
        calls.append(f'  Check("{factories[factory]}", "{expression(source)}", '
                     f'"{expression(expected)}", {str(direction == "Encode").upper()}, {bom}, {errors});')
    assert len(calls) == 114 == len(re.findall(r'\b(?:Encode|Decode)\s*\(', original))
    build = args.build.resolve()
    build.mkdir(parents=True, exist_ok=True)
    source = build / "TestCodecVectors.Mod"
    source.write_text(HARNESS.replace("@CASES@", '\n'.join(calls)))
    subprocess.run([*shlex.split(args.voc), *shlex.split(args.flags), "-m", str(source)], cwd=build, check=True)
    subprocess.run([str(build / "TestCodecVectors")], cwd=build, check=True, timeout=10)


if __name__ == "__main__":
    main()
