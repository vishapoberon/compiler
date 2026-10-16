# ✴ oberon-stars ✴

Computing star positions in Oberon.

## Build
```
$ make get-deps check-deps
$ make
```

## Install
```
# To install it to /usr/local/bin
$ sudo make install
# To install it to $HOME/bin
$ make install DESTDIR=$HOME
```

## Run
```
$ Star --ra RA --dec DEC --lat LAT --lon LON
```

where `RA` is the star' right ascension, `DEC` is the star declination,
`LAT` is the observer latitude on earth and `LON` is the observer longitude.

### Examples
To see the position of Betelgeuse ≅(88.8, 7.4) (J2000) as viewed from London/GB (51.5, 0.13).
```
$ Star --ra 88.792939 --dec 7.407064 --lat 51.50 --lon 0.13
Azimuth:24° ±1°
Altitude:-29° ±1°
```

To see the position of Spica as viewed from São Paulo/BR.
```
$ Star --ra 201.298247 --dec -11.161319 --lat -23.6 --lon -46.6
Azimuth:279° ±1°
Altitude:47° ±1°
```

For convenience, you may want to create aliases to your favorite stars in your `.bashrc` file.
```
alias betelgeuse='Star --ra 88.792939 --dec 7.407064 --lat -23.6 --lon -46.6'
alias antares='Star --ra 247.351915 --dec -26.432003 --lat -23.6 --lon -46.6'
alias arcturus='Star --ra 213.915300 --dec 19.182409 --lat -23.6 --lon -46.6'
```

## References
- Meeus, J. — 'Astronomical Algorithms, 1991
