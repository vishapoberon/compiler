# Oberon decimal conversion tests

These tests exercise the conversion routines in `Reals.Mod`, their use by
the compiler, and generated C constants. After a full build, run:

```sh
make -C src/test/reals test MODEL=2
make -C src/test/reals test MODEL=C
```

`VOC`, `VOCROOT`, `VOCLIBDIR`, `ONAME`, `CC`, `CFLAGS`, `LDFLAGS` and `BUILD`
select the staged compiler, libraries and test output. The conventional Unix
confidence suite runs both models automatically.

- `TestReals.Mod` uses known IEEE bit patterns and Oberon-only calls.
- `TestRealLiterals.Mod` checks parsing and emission of constants, including
  signed zero, midpoint rounding and the smallest subnormals.
- `check-literals.py` generates independently known constants and long inputs,
  compiles and runs them, and verifies rejection of out-of-range literals.
- `NativeOracle.c` uses libc solely as an independent differential test oracle
  for randomly sampled finite binary32/binary64 values and formatted output.
- `check-implementation.py` guards the audited Oberon numeric modules and
  saved bootstrap conversion paths against reintroducing native conversions.

The production scanner and compiler conversions are implemented in Oberon;
the native test oracle is not linked into those implementations.
