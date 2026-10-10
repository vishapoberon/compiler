MODULE HelloShared;
  IMPORT SharedConsumer, SharedProvider, Out, Heap;
BEGIN
  ASSERT(SharedConsumer.Function() = 17);
  ASSERT(SharedProvider.Next() = 1);
  SharedConsumer.Run;
  Heap.GC(TRUE);
  ASSERT(SharedConsumer.kept.n = 41);
  Out.String("modular main passed"); Out.Ln
END HelloShared.
