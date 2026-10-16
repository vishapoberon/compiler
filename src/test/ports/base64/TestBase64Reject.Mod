MODULE TestBase64Reject;
IMPORT Base64 := StringBase64, Args;
VAR source: ARRAY 64 OF CHAR;
    destination: ARRAY 64 OF CHAR;
    small: ARRAY 1 OF CHAR;
BEGIN
  Args.Get(1, source);
  IF source = 'small-destination' THEN
    Base64.DecodeString('Zg==', small)
  ELSE Base64.DecodeString(source, destination)
  END
END TestBase64Reject.
