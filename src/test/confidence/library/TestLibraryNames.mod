MODULE TestLibraryNames;

IMPORT Types, Objects, Times, ulmSets, ethSets, Sets,
  RandomNumbers, oocRandomNumbers, Strings, ethStrings, ulmStrings, Out;

VAR object: Objects.Object; value: POINTER TO Times.TimeValueRec;
  us: ARRAY 2 OF Types.Set; es: ARRAY 2 OF SET; seed: LONGINT; x: REAL;

BEGIN
  NEW(value); object := value; ASSERT(object = value);
  ulmSets.InitSet(us); ulmSets.Incl(us, 35); ASSERT(ulmSets.In(us, 35));
  ethSets.Clear(es); ethSets.Incl(es, 35); ASSERT(ethSets.In(es, 35));
  RandomNumbers.InitSeed(1); x := RandomNumbers.Uniform();
  ASSERT((x > 0.0) & (x < 0.001));
  oocRandomNumbers.PutSeed(42); oocRandomNumbers.GetSeed(seed); ASSERT(seed = 42);
  ASSERT(Strings.Length("names") = 5);
  Out.String("library naming tests passed"); Out.Ln
END TestLibraryNames.
