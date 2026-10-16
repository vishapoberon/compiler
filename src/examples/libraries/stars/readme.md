# Star positions

Carlos Une's `Star` program estimates a star's azimuth and altitude for an
observer on Earth at the current time.

Build VOC with `make` at the repository root, then:

```sh
make -C src/examples/libraries/stars
make -C src/examples/libraries/stars run \
  ARGS='--ra 88.792939 --dec 7.407064 --lat 51.50 --lon 0.13'
```

`--ra` and `--dec` give the star's right ascension and declination at J2000;
`--lat` and `--lon` give the observer's location. All angles are in degrees.
The example above uses Betelgeuse and a location near London.

Results are approximate and change with the current time. The time API uses
signed 32-bit Unix seconds in model 2, limiting it to dates before 2038.

The astronomy modules are in
[`src/ports/une/oberon-stars`](../../../ports/une/oberon-stars/readme.md),
under [GPL-3.0](../../../ports/une/oberon-stars/COPYING). This version uses
VOC's `JulianDay` and `Platform` modules for dates and time.
